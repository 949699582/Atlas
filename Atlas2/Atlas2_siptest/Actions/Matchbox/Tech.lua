-- Tech.lua
local comFunc = require("Matchbox/CommonFunc")
local seqFunc = require("Matchbox/SequenceControl")
local log = require("Matchbox/logging")
local samplingEnabled

function main(itemInfo, globals, conditions)
    -- usually nil globals/conditions is caused by unrecoverable error in previous test
    if globals == nil then error('globals is nil! Check error before this.') end
    if conditions == nil then error('conditions is nil! Check error before this.') end
    if conditions.didSOF == "TRUE" then
        -- skip this test if a previous test
        --  1. request stop on fail by having SOF = Y
        --  2. failed
        return globals, conditions
    end

    local executeTech = seqFunc.executeTech
    -- if Init.csv, call executeInit to set static condition values.
    if itemInfo.logID == 'Init' then executeTech = seqFunc.executeInit end

    -- TODO: move to group.lua to only load once.
    --
    local plist2lua = require("Matchbox/plist2lua")
    local configPath = string.gsub(Atlas.assetsPath,"Assets","Config")
    -- set log level as INFO by default
    local logLevel = LOG_LEVEL_INFO
    if comFunc.fileExists(configPath .. "/config.plist") then
        local customConfig = plist2lua.read(configPath .. "/config.plist")
        logLevel = LOGGING_LEVEL[customConfig.Log.LoggingLevel]
    end
    log.setLogEnv(itemInfo.Technology,logLevel,itemInfo.logID,itemInfo.mainIndex,1,itemInfo.thread)
    log.LogTestStepStart(itemInfo.Technology, itemInfo.testName, "")

    Device.updateProgress(itemInfo.testName)

    local isConditionPass = true
    local updatedGlobals, updatedConditions

    -- check condition value
    if itemInfo.condition ~= "" then
        isConditionPass = comFunc.calConditionVal(itemInfo.condition,conditions)
    end

    -- check condition before entering loop.
    -- changing condition value will not break from loop.
    -- Loop is to loop a certain times.
    -- user use Condition when want to loop until certain condition meets.
    if isConditionPass ~= true then
        return globals, conditions
    end

    -- check if sampling
    samplingEnabled = conditions.enableSampling
    isSamplingTest = comFunc.notNILOrEmpty(itemInfo.Sample)
    -- nil: not enabled or disabled;
    if samplingEnabled == nil and isSamplingTest then
        msg = 'Cannot running sampling test without enabling or disabling sampling. Use one of "M:startCB", "M:forceEnableSampling" or "M:forceDisableSampling" before any sampling test.'
        error(msg)
    end

    local nyquistDUT = nil
    if samplingEnabled == true and isSamplingTest then
        nyquistDUT = Device.getPlugin('NyquistDUT')
        local shouldRunBasedOnSampleRate = nyquistDUT.shouldRun(itemInfo.Sample)
        log.LogDebug('shouldRunBasedOnSampleRate: '..tostring(shouldRunBasedOnSampleRate))

        -- check Sample shouldRun flag before item execution
        if shouldRunBasedOnSampleRate ~= true then
            return globals, conditions
        end
    end

    for loopTurn = 1, itemInfo.loopTimes do
        itemInfo.process = "normal"
        itemInfo.loopTurn = loopTurn
        updatedGlobals, updatedConditions = executeTech(itemInfo, globals, conditions)
        -- executeTech error() should be all Matchbox internal error or usage error
        -- which should block test from running further.
        -- executeTech capture lua error() internally.
        local localResult = DataReporting.getLocalResult()
        local testResult = localResult == DataReporting.localResult.pass or
                                localResult == DataReporting.localResult.relaxedPass
        if samplingEnabled == true and isSamplingTest then
            local sampleResult = testResult and nyquistDUT.result.pass or nyquistDUT.result.fail
            nyquistDUT.addResult(itemInfo.Sample, sampleResult)
        end

        -- execute FA for test failure.
        if not testResult then
            log.LogTestFail(itemInfo.Technology, itemInfo.testName,"")
            itemInfo.process = "FA"
            -- ignore globals & conditions generated by FA sequence
            -- do not allow FA sequence to
            -- 1) update existing globals and conditions
            -- 2) create new global and conditions
            local msg = 'Not allowed to modify local/global/condition table in FA sequence'
            local readOnlyGlobals = comFunc.readOnly(updatedGlobals, msg)
            local readOnlyConditions = comFunc.readOnly(updatedConditions, msg)
            seqFunc.executeTech(itemInfo, readOnlyGlobals, readOnlyConditions)

            updatedConditions.didFail = "TRUE"
            -- set SOF flag if item fail and has SOF to skip the rest tests
            -- when SOF is empty, take it as Continue-on-fail.
            if itemInfo.SOF and itemInfo.SOF:upper() == "Y" then
                -- potential problem: since Matchbox's parallel test groups have isolated conditions, 1 threads's SOF will not affect another thread.
                -- for example, 2 parallel test groups
                -- A --> B --> C, D --> E
                -- when A fails and has SOF, B and C will be skipped
                -- but D and E will still run through finish
                -- because current implementaion does not support
                -- condition shared by parallel threads.
                conditions.didSOF = "TRUE"
                -- skip the reset loop/tech items to achieve SOF
                return updatedGlobals, updatedConditions
            end
        else
            log.LogTestPass(itemInfo.Technology, itemInfo.testName, "")
        end
    end

    return updatedGlobals, updatedConditions
end
