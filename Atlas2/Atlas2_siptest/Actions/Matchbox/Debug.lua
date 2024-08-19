-- Debug.lua: debug action that support run tech lines specified by external debugger.
local common = require("Matchbox/CommonFunc")
local seq = require("Matchbox/SequenceControl")
local log = require("Matchbox/logging")

function main(itemInfo, globals, conditions)
    log.LogInfo('Running Debug.lua.')
    -- usually nil globals/conditions is caused by unrecoverable error in previous test
    if globals == nil then error('globals is nil! Check error before this.') end
    if conditions == nil then error('conditions is nil! Check error before this.') end

    -- Debug.lua specific
    local locals = {}

    -- fake an tech index for logging.
    itemInfo.techIndex = 1

    local plist2lua = require("Matchbox/plist2lua")
    local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
    -- set log level as DEBUG by default for Debug action
    local logLevel = LOG_LEVEL_DEBUG

    -- Debug.lua specific
    local debugPortBase = 10000
    -- network port: port base + Device.systemIndex
    -- default port base is 10000

    if common.fileExists(configPath .. "/config.plist") then
        local customConfig = plist2lua.read(configPath .. "/config.plist")
        logLevel = LOGGING_LEVEL[customConfig.Log.LoggingLevel]
        -- Debug.lua specific
        if customConfig.Debug and customConfig.Debug.DebugPortBase then
            debugPortBase = customConfig.Debug.DebugPortBase
        end
    end
    log.setLogEnv(itemInfo.testTech,logLevel,itemInfo.logID,itemInfo.mainIndex,itemInfo.techIndex,itemInfo.thread)
    log.LogTestStepStart(itemInfo.testTech, itemInfo.testName, "")

    Device.updateProgress(itemInfo.testName)

    local isConditionPass = true

    -- check condition value
    if itemInfo.condition ~= "" then
        isConditionPass = common.calConditionVal(itemInfo.condition, conditions)
    end

    -- check condition before entering loop.
    -- changing condition value will not break from loop.
    -- Loop is to loop a certain times.
    -- user use Condition when want to loop until certain condition meets.
    if isConditionPass ~= true then
        return globals, conditions
    end

    local debugger = Atlas.loadPlugin('MatchboxCSVDebugger')
    debugger.init(debugPortBase + Device.systemIndex, locals, globals, conditions)

    local stepIndex = 1
    while true do
        log.LogDebug('Debugger: getNextStep')
        local instruction = debugger.getNextStep()
        log.LogDebug('Debugger: next step got: '..common.dump(instruction))
        if instruction.done then
            -- exit loop when incoming instruction say 'done'=true
            debugger.techStepFinished({globals={}, locals={}, conditions={}})
            break
        end

        local techFunctions = seq.initTechFunctionTable(instruction.Technology)
        -- set main index for logging
        instruction.index = stepIndex
        stepIndex = stepIndex + 1
        -- techFunctionReturns: delta table, like {locals={}, globals={}, conditions={}}
        local techStepCompleted, techStepPassed, techFunctionReturns = pcall(seq.executeTechStep, instruction, techFunctions, globals, locals, conditions)
        log.LogDebug('returns: '..common.dump(techFunctionReturns))
        if techStepCompleted then
            if techStepPassed then
                debugger.techStepFinished(techFunctionReturns)
            else
                -- techFunctionReturns is error msg when fail.
                debugger.techStepFinishedWithError(techFunctionReturns)
            end
        else
            -- error
            local msg = techStepPassed
            debugger.techStepFinishedWithError(msg)
        end
    end

    debugger.teardown()
    return globals, conditions
end
