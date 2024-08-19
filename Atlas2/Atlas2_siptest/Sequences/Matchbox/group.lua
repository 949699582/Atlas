local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")
local seqFunc = require("Matchbox/SequenceControl")
local userPluginModule = require("Station/Plugins")
require("GroupStateMachine")

-- global vars shared within the file across functions
local enabledMainTests, enabledInitTests, enabledTeardownTests, limits
local useNyquist
-- tables for current test cycles; modified during test and shouldn't impact
-- next test cycle
local currentMainTests, currentInitTests, currentTeardownTests
-- store test names appeared, to handle lines with same TestName in Main.csv
local testNames = {}

-- run tests in Init, Main or Teardown CSV; similar to burgundy's dag runner
function runTests(testsFromCSV, limit, globals, conditions, logID, dag, deviceName, existingTests, mergedPluginTable)
    -- return early for empty CSV
    if next(testsFromCSV) == nil then return nil end

    -- run test table: expand tests from csv into runnable test items
    -- and feed to executeItems()
    local tests = {}
    for index, test in ipairs(testsFromCSV)
    do
        test.mainIndex = index
        -- get limits for current main item
        test.limits = limit
        test.testName = test.TestName
        test.condition = test.Condition
        test.loopTimes = 1
        test.loopTurn = 1
        test.logID = logID
        -- allow duplicate test in Main.csv
        if existingTests[test.TestName] == nil then
            existingTests[test.TestName] = 1
            test.nameSuffix = ""
        else
            existingTests[test.TestName] = existingTests[test.TestName] + 1
            test.nameSuffix = "_"..existingTests[test.TestName]
        end

        if test.Thread == "" then test.Thread = nil end
        if test.Loop ~= "" then
            test.loopTimes = tonumber(test.Loop)
        end

        tests[index] = test
    end

    local resolvable = executeItems(tests, globals, conditions, dag, deviceName, mergedPluginTable)
    return resolvable
end

function executeItems(tests, globals, conditions, dag, deviceName, pluginStore)
    local lastResolvables = {}

    -- remove Atlas threadpool size limit to support 4+ parallel actions
    dag.clearThreads()

    -- unmanage all plugins to run in parallel.
    -- Matchbox pass all plugins to every test and here any test can run in parallel
    -- as long as every plugins are thread safe when they are used in parallel test
    -- we are good here.
    for pluginName, _ in pairs(pluginStore) do
        dag.unmanage(pluginName)
    end

    local plugins = comFunc.tableKeys(pluginStore)
    lastResolvables[deviceName] = seqFunc.scheduleTests(dag, tests, globals, conditions, plugins)

    return lastResolvables[deviceName]
end

local loopsLeft = 0
local additionalGlobals = {}
-- return slots to test, allow user to filter units or control test start
-- for example, selected units to retest in a panel, or start with a start button.
-- optionally each slots can have SN from barcode scanner.
-- @param groupPlugins: group plugin instances, possibly used during unit detection.
-- @return: array of slots to start.
-- user overrided getSlots() needs to call Group.getSlots() inside and return slots to test.
function unitDetection(groupPlugins, interarrivalTimeout, globalTimeout)
    local slotMap = {}
    -- re-init initial global/condition for current test cycle

    -- Wait for new unit to start the device
    if userPluginModule.getSlots then
        additionalGlobals = {}
        local slots = userPluginModule.getSlots(groupPlugins, interarrivalTimeout, globalTimeout)
        for k, v in pairs(slots) do
            if type(k) == 'number' then
                -- no initial globals from getSlots()
                table.insert(slotMap, v)
            elseif type(k) == 'string' then
                -- user provides SN.
                table.insert(slotMap, k)
                local deviceName = "G=" .. Group.index .. ":S=" .. k
                additionalGlobals[deviceName] = {SN=v}
            end
        end
    else
        slotMap = Group.getSlots(interarrivalTimeout, globalTimeout)
    end

    local loops_per_detection = userPluginModule.loops_per_detection or 1
    -- loops_per_detection should be an integer.
    -- check if number here; ignore the case when user input float like 3.5... user shouldn't do that.
    -- if really to ensure integer, need to add `math.floor(i) == i`
    -- which involes `math` lib that is used nowhere but here.
    if type(loops_per_detection) ~= 'number' then
      error("loops_per_detection must be a number")
    end
    loopsLeft = loops_per_detection

    return slotMap
end


-- globals and conditions from previous dag
-- when test action get cancelled in Main.csv, Teardown use this as input
-- so it can use var initialized in Init.csv
-- this should be better than using empty globals/conditions in Teardown.csv.
local initGlobals = {
    TRUE=true,
    FALSE=false
}
local initConditions = {
    didSOF="FALSE",
    didFail="FALSE",
    Poison="FALSE",
    Automation="NO",
    -- using nil/bool intendedly; user cannot use in Condition column.
    -- initialized as nil: not enabled; error out when get a sampling test
    -- set to true by "M:startCB" or "M:forceEnableSampling"
    -- set to false by "M:forceDisableSampling":
    --      previous sampling result will be cleared
    --      sampling test after it will 100% run
    enableSampling=nil
}
-- globals/conditions from previous DAG, to be used by
--     1. next DAG
--     2. Teardown DAG when Main didn't finish.
--        when Main.csv error out, Teardown.csv still can access
--        globals/conditions generated by Init.csv
local prevGlobals = {}
local prevConditions = {}
-- key: device name; value: k-v pairs as globals var.
-- from getSlots(). SMT DFU 4-up station has barcode scanner in each slot,
-- and it will scan DUT SN in getSlot() and start test if SN is successfully scanned.
-- to be merged in global variable table.


-- return bool about whether tests has sampling test
-- non empty "Sample" column.
local function hasSamplingTest(tests)
    for _, test in ipairs(tests) do
        if comFunc.notNILOrEmpty(test.Sample) then return true end
    end
    return false
end

function groupSetup(resourcesURLs)
    Log.LogInfo("Checking Atlas minimum version")
    local userVersion = comFunc.fileRead(Atlas.assetsPath.."/minimumAtlasVersion")
    comFunc.checkAtlasVersion(comFunc.trimNewLine(userVersion))
    Log.LogInfo("Checking CSV syntax..")
    local syntaxCheck, CSVLoad
    syntaxCheck = require("Matchbox/CheckCSVSyntax")
    syntaxCheck.checkCSVSyntax(Atlas.assetsPath)
    CSVLoad = require("Matchbox/CSVLoad")
    local mainCSVTable = CSVLoad.loadItems(Atlas.assetsPath.."/Main.csv")
    local initCSVTable = CSVLoad.loadItems(Atlas.assetsPath.."/Init.csv")
    local teardownCSVTable = CSVLoad.loadItems(Atlas.assetsPath.."/Teardown.csv")

    -- filter tests for test modes
    local testMode = Group.isAudit() and "Audit" or "Production"

    enabledInitTests = CSVLoad.filterItems(initCSVTable, testMode)
    -- do not support Sampling test in Init.csv
    if hasSamplingTest(enabledInitTests) then error('Sampling test in Init.csv is not supported.') end

    enabledMainTests = CSVLoad.filterItems(mainCSVTable, testMode)
    useNyquist = hasSamplingTest(enabledMainTests)

    enabledTeardownTests = CSVLoad.filterItems(teardownCSVTable, testMode)
    local samplingGroup = CSVLoad.loadSamplingGroups(Atlas.assetsPath.."/Sampling.csv")

    limits = CSVLoad.loadLimits(Atlas.assetsPath.."/Limits.csv")

    local groupPlugins = loadGroupPlugins(resourcesURLs)
    if useNyquist then
        groupPlugins.NyquistPlugin.setDefaultSamplingRate(samplingGroup)
    end
    return groupPlugins
end


function loadGroupPlugins(resourceURLs)
    -- load group plugins
    local groupPlugins = {}
    if userPluginModule["loadGroupPlugins"] ~= nil then
        groupPlugins = userPluginModule["loadGroupPlugins"](resourceURLs)
    end
    groupPlugins["Regex"] = Atlas.loadPlugin("Regex")
    groupPlugins["RunShellCommand"] = Atlas.loadPlugin("RunShellCommand")

    if useNyquist then
        groupPlugins['NyquistPlugin'] = Atlas.loadPlugin("NyquistPlugin")
    end
    return groupPlugins
end

function groupStart(groupPluginTable)
    currentMainTests = comFunc.clone(enabledMainTests)
    currentInitTests = comFunc.clone(enabledInitTests)
    currentTeardownTests = comFunc.clone(enabledTeardownTests)

    local userGroupStartFunction = userPluginModule.groupStart
    if userGroupStartFunction then
        userGroupStartFunction(groupPluginTable)
    end
end

function groupStop(groupPluginTable)
  local userGroupStopFunction = userPluginModule.groupStop
  if userGroupStopFunction then
    userGroupStopFunction(groupPluginTable)
  end
end


function teardownGroupPlugins(groupPluginTable)
  if userPluginModule["shutdownGroupPlugins"] ~= nil then
    userPluginModule["shutdownGroupPlugins"](groupPluginTable)
  end
end


local lastResolvableByDevice = {} --  Make sure this get's set to empty for each device
function deviceStart(deviceName, groupPluginTable)
  local devicePlugins = userPluginModule.loadPlugins(deviceName, groupPluginTable)
    if useNyquist then
        devicePlugins['NyquistDUT'] = groupPluginTable.NyquistPlugin.createNyquistDUT()
    end

  testNames[deviceName] = {}
  lastResolvableByDevice[deviceName] = nil
  return devicePlugins
end

function deviceTeardown(deviceName, devicePluginTable)
    -- TODO: change to parallel in final dag
    if useNyquist then
        devicePluginTable.NyquistDUT.finish()
    end
    userPluginModule.shutdownPlugins(deviceName, devicePluginTable)
end

-- check result of previous dag
-- fail device for 1) failed dag due to un-recoverable error 2) cancelled task for amiok failure
-- @param dagName: string, for logging
-- @param deviceName: string, device name
-- @param prevDAGResults: resolvable of previous DAG group.execute()
-- @return: bool, false if test failed or cancelled, true if test
--          finished normally.
local function checkDAGSuccessful(dagName, deviceName, prevDAGResults)
    local lastResolvable = lastResolvableByDevice[deviceName]
    -- if previous DAG run 0 test, like empty Init.csv, take it as pass
    if lastResolvable == nil then return true end

    local exitEarly = lastResolvable.isCancelled()
    local prevDAGSuccessful = prevDAGResults.checkSuccessful(deviceName)
    Log.LogInfo(dagName..': exit early: '..tostring(exitEarly))
    Log.LogInfo(dagName..': completed successful: '..tostring(prevDAGSuccessful))
    if exitEarly == true and prevDAGSuccessful == true then
        -- dag didn't finish, probably exit early due to amiok failure
        -- somehow I don't know how to get detailed amIOK failure message here
        local msg = 'DAG exit early due to amIOK failure. Check log for detail.'
        Log.LogError(msg)
        Group.failDevice(deviceName, msg)
        return false
    elseif prevDAGResults.checkSuccessful(deviceName) == false then
        -- dag failed due to unrecoverable error, like error in Tech.lua
        -- this is not error in user test function.
        local failMsg = prevDAGResults.deviceError(deviceName)
        Log.LogError('executeItems: tests interrupted by error; msg=' .. failMsg)
        Group.failDevice(deviceName, comFunc.trimFailureMsg(failMsg))
        return false
    else
        -- dag completed without error.
        local globals, conditions = lastResolvableByDevice[deviceName].returnValue()
        -- setting globals and conditions for next dag.
        prevGlobals[deviceName] = globals
        prevConditions[deviceName] = conditions
        return true
    end
end

function scheduleDAG(iter, dag, deviceName, mergedPluginTable, prevDAGResults)
  -- enable amiok check for Init and Main.csv, but not Teardown.csv.
  if iter == 1 then
    -- enable amiok for Init.csv
    -- dag.enableExitOnAmIOkay()
    -- initialize for current test cycle
    prevGlobals[deviceName] = comFunc.clone(initGlobals)
    prevConditions[deviceName] = comFunc.clone(initConditions)

    if additionalGlobals[deviceName] then
        for k, v in pairs(additionalGlobals[deviceName]) do
            prevGlobals[deviceName][k] = v
        end
    end

    local globals = prevGlobals[deviceName]
    local conditions = prevConditions[deviceName]
    lastResolvableByDevice[deviceName] = runTests(currentInitTests, limits, globals,
                                                  conditions, 'Init', dag, deviceName,
                                                  testNames[deviceName], mergedPluginTable)

    return true
  elseif iter == 2 then
    -- enable amiok for Main.csv
    -- dag.enableExitOnAmIOkay()
    -- check result for Init.csv
    local prevDAGFinished = checkDAGSuccessful('Init', deviceName, prevDAGResults)
    if prevDAGFinished == true then
        local lastResolvable = lastResolvableByDevice[deviceName]
        if lastResolvable then
            local result = lastResolvable.overallResult()
            if result == Group.overallResult.fail then
                Log.LogError('Init.csv fails; skipping Main.csv and running Teardown.csv')
                -- do not run Main.csv if Init.csv fails.
                return true
            end
        end

        local globals = prevGlobals[deviceName]
        local conditions = prevConditions[deviceName]
        lastResolvableByDevice[deviceName] = runTests(currentMainTests, limits, globals,
                                                      conditions, 'Main', dag, deviceName,
                                                      testNames[deviceName], mergedPluginTable)
        return true
    else
        -- do nothing here; already handled in checkDAGSuccessful
        -- skip Main.csv, so return false to go to Teardown.csv
        return false
    end
  else
    -- Do not enable amiok for Teardown.csv
    -- check result for Main.csv
    checkDAGSuccessful('Main', deviceName, prevDAGResults)

    return false
  end
end

function scheduleFinalDAG(dag, deviceName, mergedPluginTable)
    local globals = prevGlobals[deviceName]
    local conditions = prevConditions[deviceName]

    -- clear didSOF so Teardown could run even when SOF happened in Main/Init
    conditions.didSOF = 'FALSE'

    -- treating relaxed pass as pass
    if Group.getDeviceOverallResult(deviceName) == Group.overallResult.fail then
        conditions.testFail = 'TRUE'
    else
        conditions.testFail = 'FALSE'
    end

    runTests(currentTeardownTests, limits, globals, conditions, 'Teardown',
             dag, deviceName, testNames[deviceName], mergedPluginTable)
end

function loopAgain()
  loopsLeft = loopsLeft - 1
  return loopsLeft > 0
end

function groupShouldExit(groupPluginTable)
  if userPluginModule["groupShouldExit"] ~= nil then
    return userPluginModule["groupShouldExit"](groupPluginTable)
  end
  return false
end

GSM.registerGroupFunctionTable({
    setup=groupSetup,
    getSlots=unitDetection,
    start=groupStart,
    stop=groupStop,
    loopAgain=loopAgain,
    groupShouldExit=groupShouldExit,
    teardown=teardownGroupPlugins
})
GSM.registerDeviceFunctionTable({
    setup=deviceStart,
    scheduleDAG=scheduleDAG,
    scheduleFinalDAG=scheduleFinalDAG,
    teardown=deviceTeardown
})

if userPluginModule.readyForAutomatedHandling then
    initConditions.Automation = "YES"
    GSM.registerAutomatedHandlingCallback(userPluginModule.readyForAutomatedHandling)
end
