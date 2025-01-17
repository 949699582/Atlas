-------------------------------------------------------------------
----***************************************************************
----Matchbox Tech function offerings
----***************************************************************
-------------------------------------------------------------------

local M = {}
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local libRecord = require 'Matchbox/record'

-- show the command on the interface
-- @param paraTab : parameter table contains
--                  1) test info named as Main&Tech csv column
--                  2) variable generated by Matchbox: limit/testNameSuffix/isLimitApplied
-- @return true; the action will always pass
function M.createCommandRecord(paraTab)
    local tech = paraTab.Technology
    local subtestname = paraTab.TestName .. paraTab.testNameSuffix
    local subsubtestname = '[cmd]' .. paraTab.Commands
    libRecord.createBinaryRecord(true, tech, subtestname, subsubtestname)
end

-- Shark: previous createParametricRecord handles both string limit and p-record
--        which is handled by createRecord() function below;
--        Actually CSV could use createRecord() for both bin and p-record.
function M.createParametricRecord(paraTab)
    return M.createRecord(paraTab)
end

-- create record; record type is determined by limits definition and result type
-- no limit:
--     result is number: p-record
--     result is other: pass bin-record
-- @param paraTab : parameter table contains cmd/AdditionalParameters/limit/testname/tech/testNameSuffix/isLimitApplied
-- @Input: 2-item array
--       1: result
--       2: optional subsubtestname if it is a variable value
-- @return action pass/fail results determined by limits
function M.createRecord(paraTab)
    local input, subsubFromInput = table.unpack(paraTab.InputValues)

    local failMsg = comFunc.trim(paraTab.AdditionalParameters.failMsg)

    local limit = nil
    local testname = paraTab.Technology
    -- paraName: AP.paraName or AP.subsub or TestName
    local paraName = paraTab.AdditionalParameters.paraName or paraTab.AdditionalParameters.subsubtestname or paraTab.TestName
    local subsubtestname = comFunc.trim(paraTab.AdditionalParameters.subsubtestname) or comFunc.trim(paraTab.AdditionalParameters.paraName)
    if subsubFromInput then subsubtestname = subsubFromInput end
    -- paraName: testName, or paraName in AdditionalParameters if defined.
    -- testNameSuffix: for _Loop1 and _FA
    local subtestname = paraTab.TestName .. paraTab.testNameSuffix

    if paraTab.limit then limit = paraTab.limit[paraName] end

    -- return string "false" so it can be use in Condition.
    return tostring(libRecord.createRecord(input, testname, subtestname, subsubtestname, limit, failMsg))
end

-- create binary Record function
-- @param paraTab : parameter table contains cmd/AdditionalParameters/limit/testname/tech/testNameSuffix/isLimitApplied
-- @return action pass/fail results
function M.createBinaryRecord(paraTab)
    local result, subsubFromInput = table.unpack(paraTab.InputValues)

    if result == 'TRUE' then result = true end
    if result == 'FALSE' then result = false end

    local subsubtestname = comFunc.trim(paraTab.AdditionalParameters["subsubtestname"])
    if subsubFromInput ~= nil then subsubtestname = subsubFromInput end

    -- failMsg in records.csv:
    -- "" for PASS record, to avoid seeing "No user failure message was provided" in records.csv
    -- if Fail, use AdditionalParameters["failMsg"] if it has
    -- if Fail and no "failMsg" in AdditionalParameters, use fixed string.
    local failMsg = (result == true) and "" or (comFunc.trim(paraTab.AdditionalParameters["failMsg"]) or "Test fail; please check log.")

    local paraName = paraTab.AdditionalParameters.paraName or paraTab.TestName
    local testname = paraName .. paraTab.testNameSuffix
    libRecord.createBinaryRecord(result, paraTab.Technology, testname, subsubtestname, failMsg)
end

-- create a plugin record
-- @param paraTab : parameter table contains cmd/AdditionalParameters/limit/testname/tech/testNameSuffix/isLimitApplied
-- @param actionPlugin: string
-- @param actionFunc: string
-- @return true; the action will always pass
function M.createPluginRecord(paraTab,actionPlugin,actionFunc)

    local testname = paraTab.TestName.. paraTab.testNameSuffix
    local subsubtestname = "["..actionPlugin.."]"..paraTab.Commands
    libRecord.createBinaryRecord(true, paraTab.Technology, testname, subsubtestname)

    local timeout = paraTab.AdditionalParameters["Timeout"] or 20
    local pluginFunc = Device.getPlugin(actionPlugin)
    local cmdReturn = pluginFunc[actionFunc](paraTab.Commands, timeout)
    return cmdReturn
end

-- Upload attributes
function M.createAttribute(paraTab)
    local attributeKey = comFunc.trim(paraTab.AdditionalParameters["attributeKey"])
    local attributeValue = paraTab.Input
    local testResult = DataReporting.createAttribute(attributeKey, attributeValue)
    DataReporting.submit(testResult)
end

-- apply pattern regex on input and return captured groups as an array
function M.parse(paraTab)
    local Regex = Device.getPlugin("Regex")
    local inputStr = paraTab.Input
    if paraTab.AdditionalParameters["pattern"] == nil then
        error("lack parameter pattern")
    end
    local pattern = paraTab.AdditionalParameters["pattern"]
    local parseResult = Regex.groups(inputStr, pattern,1)
    Log.LogInfo("parse result: "..comFunc.dump(parseResult))
    if not parseResult then error('parse failed.') end
    return parseResult
end

-- return all groups from all matches with lua's gmatch
function M.match(paraTab)
    local inputStr = paraTab.Input

    local pattern = paraTab.AdditionalParameters.pattern
    if pattern == nil then
        error("lack parameter pattern")
    end
    local matchResult = {}
    local iter = inputStr:gmatch(pattern)
    local tmpTable

    repeat
        -- tmpTable: store all captured groups (captures)
        tmpTable = {}
        for _, v in ipairs({iter()}) do
        table.insert(tmpTable, v)
        end

        if #tmpTable ~= 0 then
            table.insert(matchResult, tmpTable)
        end
        -- finish when nothing is parsed out.
    until #tmpTable == 0

    Log.LogInfo("match result: "..comFunc.dump(matchResult))
    local bResult = matchResult and true or false
    if not bResult then error('No match found.') end
    return matchResult
end

-- demo send efi command function
-- Shark: Should this be part of Matchbox standard offering?
local cnt = 1
function M.sendEFICmd(paraTab)
    local command = paraTab.Commands
    local expect = paraTab.AdditionalParameters["expect"]
    local timeout = paraTab.Timeout or 20
    local pattern = paraTab.AdditionalParameters["pattern"]
    local sendEFICmdResult = true
    local dut = Device.getPlugin("EFIDut")
    local cmdReturn = dut.sendCommand(command,timeout)
    if expect ~= nil then
        sendEFICmdResult = string.find(cmdReturn or "", expect) and true or false
        if not sendEFICmdResult then
            local testname = paraTab.TestName .. paraTab.testNameSuffix
            local subsubtestname = 'sendEFICmd ' .. tostring(cnt) .. ':' .. command .. ' Expect not found'
            libRecord.createBinaryRecord(false, paraTab.Technology, testname, subsubtestname)
        end
            cnt = cnt + 1
    end
    if pattern ~= nil then
      cmdReturn = cmdReturn:match(pattern)
    end
    if cmdReturn == nil or not sendEFICmdResult then
        error('sendEFICmd failed.')
    end
    Log.LogInfo('Command "' .. command.. '" sent successfully')
    return cmdReturn
end

-- startCB using given dut plugin name
-- @param param.Input: dut plugin instance name
-- @param param.AdditionalParameters.category: (optional) category to use for ControlBits
-- @param param.AdditionalParameters.cbOffsets: (optional) array of cboffset to check to determine sampling;
--        if provided, will check before start process control and disable sampling if any status is not untested.
-- @return: bool, whether sampling is enabled.
function M.startCB(param)
    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(dutPluginName)..' not found.') end
    local category = param.AdditionalParameters.category

    local cbStatusBeforeStart = {}
    local dut1stRun = true
    local cbOffsets = param.AdditionalParameters.cbOffsets
    if cbOffsets and type(cbOffsets) == 'table' and next(cbOffsets) ~= nil then
        for _, offset in ipairs(cbOffsets) do
            local status = dut.readCBStatus(offset)
            -- 3: untested
            if status ~= 3 then dut1stRun = false end

            cbStatusBeforeStart[tostring(offset)] = status
        end
    end

    Log.LogInfo('Starting process control')

    local cbOffsetsStarted
    if category ~= nil and category ~= '' then
        cbOffsetsStarted = ProcessControl.start(dut, category)
    else
        cbOffsetsStarted = ProcessControl.start(dut)
    end

    for _, offset in ipairs(cbOffsetsStarted) do
        local strOffset = tostring(offset)
        if cbOffsets and next(cbOffsets) ~= nil then
            local beforeStart = cbStatusBeforeStart[strOffset]
            if beforeStart == nil then
                error('CB offset '..strOffset..' written by station so must be included in AdditionalParameters.cbOffsets')
            end
        end
        dut1stRun = dut1stRun and dut.readCBFailCount(offset) == 0
    end
    -- enable sampling when dut 1st run on this station, disable sampling otherwise
    return dut1stRun
end

-- finishCB using given dut plugin name; poison if requested.
-- @param param.Input: {Poison}
-- @param param.AdditionalParameters.dutPluginName: dut plugin instance name
function M.finishCB(param)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo('Process control finished or not started; skip finishCB.')
        return
    end

    local dutPluginName = param.AdditionalParameters.dutPluginName
    if dutPluginName == nil then error('dutPluginName missing in AdditionalParameters') end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then error('DUT plugin '..tostring(param.Input)..' not found.') end

    -- read Poison flag from Input
    local Poison = param.Input
    if Poison == 'TRUE' then
        Log.LogInfo('Poison requested; poisoning CB.')
        ProcessControl.poison(dut)
    end
    Log.LogInfo('Finishing process control')
    ProcessControl.finish(dut)
end

function M.setVariable(paraTab)
    return paraTab.Input
end

function M.reportFailure(paraTab)
    local msg = paraTab.AdditionalParameters.subsubtestname or ''
    error(msg)
end

-- should not be called in parallel with a sampling test or itself.
function M.forceEnableSampling()
end

-- should not be called in parallel with a sampling test or itself.
function M.forceDisableSampling()
    Log.LogInfo('M:disableSampling: clearing exsiting sampling results.')
    local nyquistDUT = Device.getPlugin('NyquistDUT')
    nyquistDUT.clearResults()
end


return M
