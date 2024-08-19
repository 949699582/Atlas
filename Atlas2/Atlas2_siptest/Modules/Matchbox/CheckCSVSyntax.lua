-------------------------------------------------------------------
----***************************************************************
----CSV syntax check
----***************************************************************
-------------------------------------------------------------------

local CheckCSVSyntax = {}
local common = require "Matchbox/CommonFunc"
local ftcsv = require "Matchbox/ftcsv"
local log = require 'Matchbox/logging'
local conditionNameArr = {}
--- reserved conditions has predefined allowed values and type
--- shouldn't appear in Conditions.csv
reservedConditions = {'Hang', 'didSOF', 'didFail', 'Poison', 'testFail', 'enableSampling', 'Automation'}

CheckCSVSyntax.mainCSVColumns = {
    "TestName", "Technology", "Disable","Production", "Audit", "Thread",
    "Policy", "Loop", "Sample",  "SOF", "Condition", "Notes"
}
CheckCSVSyntax.techCSVColumns= {
    "TestName", "TestActions", "Disable","Input", "Output",
    "Timeout", "Retries", "AdditionalParameters", "ExitEarly",
    "SetPoison", "Commands", "FA", "Condition", "Notes"
}
CheckCSVSyntax.failureCSVColumns = {
    "TestName", "TestActions", "Disable","Input", "Output",
    "Timeout", "Retries", "AdditionalParameters", "Commands",
    "Condition", "Notes"
}


-- check main/site csv syntax
function CheckCSVSyntax.checkMainCSVSyntax(folder, fileName)
    local mainCSVPath = folder..'/'..fileName
    log.LogInfo('Checking CSV syntax for '..mainCSVPath)
    local isCSVValid
    local reportStr1 = fileName
    local reportStr2 = ""
    local reportStr3 = ""

    local csvTable = ftcsv.parse(mainCSVPath,",",{["headers"] = false,})
    local titleRow = csvTable[1]
    local tempThreadFlag,tempSampFlag
    local threadFlagArr,sampFlagArr = {},{}

    local row
    local expectedColumns = CheckCSVSyntax.mainCSVColumns
    isCSVValid, row = common.arrayCmp(expectedColumns, titleRow)

    if not isCSVValid then
        reportStr2 = 'Title row invalid: Column['..row..'] is '..tostring(titleRow[row] or 'empty')..', expecting '..tostring(expectedColumns[row] or 'empty')

    else
        for i, v in ipairs(csvTable) do
        if i ~= 1 then
            local TestName = v[1]
            local Disable = v[3]:upper()
            if Disable ~= '' and Disable ~= 'Y' and Disable ~= 'N' then
                reportStr2 = TestName
                reportStr3 = 'Disable flag invalid; expecting Y/N/empty'
                isCSVValid = false
            end

            local Production = v[4]:upper()
            if Production ~= '' and Production ~= 'Y' and Production ~= 'N' then
                reportStr2 = TestName
                reportStr3 = 'Production flag invalid; expecting Y/N/empty'
                isCSVValid = false
            end

            local Audit = v[5]:upper()
            if Audit ~= '' and Audit ~= 'Y' and Audit ~= 'N' then
                reportStr2 = TestName
                reportStr3 = "Audit flag invalid; expecting Y/N/empty"
                isCSVValid = false
            end

            local Thread = v[6]
            if Thread ~= "" then
                if Thread ~= tempThreadFlag then
                    if common.hasVal(threadFlagArr, Thread) then
                        reportStr2 = TestName
                        reportStr3 = "Put same thread flags together"
                        isCSVValid = false
                    else
                        tempThreadFlag = Thread
                        threadFlagArr[#threadFlagArr+1] = Thread
                    end
                end
            end

            -- Policy is case-insensitive
            local Policy = string.upper(v[7])
            -- R: rendezvous; E: exclusion
            -- exclusion has an issue now (rdar://73337238);
            -- only enable rendezvous for now.
            if Policy ~= '' and Policy ~= 'R' then
                reportStr2 = TestName
                reportStr3 = "Policy Invalid: expecting R/empty; exclusion not enabled for the moment (rdar://73337272)"
                isCSVValid = false
            end

            local Loop = v[8]
            if Loop ~= "" then
                local numLoop = tonumber(Loop)
                if numLoop == nil then
                    reportStr2 = TestName
                    reportStr3 = "Loop flag invalid; expecting a positive integer"
                    isCSVValid = false
                elseif numLoop <= 0 or math.floor(numLoop) < numLoop then
                    reportStr2 = TestName
                    reportStr3 = "Loop flag invalid; expecting a positive integer"
                    isCSVValid = false
                end
            end

            -- a Main row having both Policy and Loop is ambiguous.
            if Policy ~= '' and Loop ~= '' then
                reportStr2 = TestName
                reportStr3 = 'A test cannot have both Loop and Policy.'
                isCSVValid = false
            end

            local Sample = v[9]
            if Sample ~= "" then
                if Sample ~= tempSampFlag then
                    if common.hasVal(sampFlagArr, Sample) then
                        reportStr2 = TestName
                        reportStr3 = "Put same sampling flags together"
                        isCSVValid = false
                    else
                        tempSampFlag = Sample
                        sampFlagArr[#sampFlagArr+1] = Sample
                    end
                end
            end
            local SOF = v[10]:upper()
            if SOF ~= "" and SOF ~= "Y" and SOF ~= "N" then
                reportStr2 = TestName
                reportStr3 = "SOF flag invalid; expecting Y/N/empty"
                isCSVValid = false
            end
            local Condition = v[11]
            local conditionModule = require 'Matchbox/Condition'
            conditionModule.checkConditionExpression(Condition,conditionNameArr,reportStr1,TestName)
        end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2..", "..reportStr3)
    end

    return isCSVValid
end

-- check sampling csv syntax
function CheckCSVSyntax.checkSamplingCSVSyntax(samplingCSVPath)

    local isCSVValid = true
    local reportStr1 = "Sampling.csv"
    local reportStr2 = ""
    local csvTable = ftcsv.parse(samplingCSVPath,",",{["headers"] = false,})

    local titleRow = csvTable[1]
    local isTitleValid = true
    if titleRow[1] ~= "name" or titleRow[2] ~= "proposedRate" then
        isTitleValid = false
    end

    if isTitleValid == false then
        isCSVValid = false
        reportStr2 = "title row invalid"
    else
        for i,v in ipairs(csvTable) do
            if i ~= 1 then
                local numRate = tonumber(v[2])
                if numRate == nil or numRate <= 0 or numRate > 100  or
                   common.isInt(numRate) == false then
                    reportStr2 = "Sampling group " .. v[1] .. " has invalid default sampling rate"
                    reportStr2 = reportStr2 .. ": " .. tostring(numRate) .. "; expecting integer in (0, 100]"
                    isCSVValid = false
                end
            end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2)
    end

    return isCSVValid
end

-- check condition csv syntax
function CheckCSVSyntax.checkConditionCSVSyntax(ConditionCSVPath)
    local isCSVValid = true
    local reportStr1 = "Conditions.csv"
    local reportStr2 = ""
    local csvTable = ftcsv.parse(ConditionCSVPath,",",{["headers"] = false,})
    conditionNameArr = common.clone(reservedConditions)

    local titleRow = csvTable[1]
    local isTitleValid = true
    if titleRow[1] ~= "ConditionName" or titleRow[2] ~= "Values" or titleRow[3] ~= "Dynamic" then
        isTitleValid = false
    end

    if isTitleValid == false then
        isCSVValid = false
        reportStr2 = "title row invalid"
    else
        for i, v in ipairs(csvTable) do
            if i ~= 1 then
                local conditionName = v[1]
                table.insert(conditionNameArr,conditionName)
                local conditionValues = v[2]
                if conditionValues == nil or conditionValues == '' then
                    reportStr2 = "ConditionName " .. v[1] .. " has no allowed values."
                    isCSVValid = false
                end
                local isDynamic = v[3]:upper()
                if isDynamic ~= '' and isDynamic ~= 'Y' and isDynamic ~= 'N' then
                    reportStr2 = reportStr2..' Condition '..v[1]..' type ('..isDynamic..') invalid; expecting Y/N/empty in Dynamic column;'
                    isCSVValid = false
                end
            end
        end

    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2)
    end
end

-- check tech csv syntax.
-- Failure, Init and Teardown does not have FA;
-- Tech CSV has FA.
-- Failure CSV does not have ExitEarly, SetPoison and FA column;
function CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, fileName, isFailureCSV)
    local isCSVValid
    local reportStr1
    local reportStr2 = ""
    local reportStr3 = ""
    local expectedColumns
    local conditionModule = require 'Matchbox/Condition'

    if isFailureCSV then
        expectedColumns = CheckCSVSyntax.failureCSVColumns
    else
        expectedColumns = CheckCSVSyntax.techCSVColumns
    end

    TechCSVPath = resourcesPath .. "/" .. fileName
    local techCSVPathArr
    if common.fileRead(TechCSVPath) == nil then
        local techCSVTab = {}
        local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
        local techCSVPathStr = RunShellCommand.run("ls ".. TechCSVPath)
        techCSVPathStr = techCSVPathStr.output
        techCSVPathArr = common.splitBySeveralDelimiter(techCSVPathStr,'\n\r')

        for i, _ in ipairs(techCSVPathArr) do
            if techCSVPathArr[i]:match(".+%.([cC][sS][vV])$") then
                table.insert(techCSVTab,TechCSVPath .. "/" .. techCSVPathArr[i])
            end
        end
        techCSVPathArr = techCSVTab
    else
        techCSVPathArr = {TechCSVPath}
    end

    local testNameArr = {}

    for csvIndex in ipairs(techCSVPathArr) do
        if fileName:match("Tech") ~= nil then
            reportStr1 = techCSVPathArr[csvIndex]:match(fileName .."/(.+%.[cC][sS][vV])$")
        else
            reportStr1 = fileName
        end

        log.LogInfo('Checking CSV syntax for '..techCSVPathArr[csvIndex])
        local csvTable = ftcsv.parse(techCSVPathArr[csvIndex],",",{["headers"] = false,})

        local titleRow = csvTable[1]
        local row
        -- check if the Tech CSV title row strictly matches expectation.
        isCSVValid, row = common.arrayCmp(expectedColumns, titleRow)

        if not isCSVValid then
            reportStr2 = 'Title row invalid: Column['..row..'] is '..tostring(titleRow[row] or 'empty')..', expecting '..tostring(expectedColumns[row] or 'empty')
        else
            for i, v in ipairs(csvTable) do
                if i ~= 1 then
                    -- why TestName not testName here: using var name same as column name.
                    -- TODO: store in a key-value table instead of index table.
                    local TestName = v[1]
                    if TestName ~="" then
                        if common.hasVal(testNameArr, TestName) then
                            reportStr2 = TestName
                            reportStr3 = "item name duplicate"
                            isCSVValid = false
                        else
                            testNameArr[#testNameArr+1] = TestName
                        end
                    end
                    local TestActions = v[2]
                    local actionPlugin, actionFunc = string.match(TestActions, "^([_%a][_%a%d]*)%:([_%a][_%a%d]*)$")
                    if not actionPlugin or not actionFunc then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Action " .. TestActions .. " invalid"
                        isCSVValid = false
                    end

                    -- ensure "Disable" column has one of the following allowed value:
                    -- 1. empty 2. Y 3. N
                    local Disable = v[3]
                    if common.isCharBooleanOrEmpty(Disable) == false then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Parameter Disable " .. Disable .. " invalid; expecting Y, N or empty"
                        isCSVValid = false
                    end

                    -- ensure AdditionalParameters is a valid json string.
                    local AdditionalParameters = v[8]
                    if AdditionalParameters ~= "" and xpcall(common.parseParameter,debug.traceback, AdditionalParameters) == false then
                        reportStr2 = "Row " .. i
                        reportStr3 = "Parameter " .. AdditionalParameters .. " invalid; expecting valid json string."
                        isCSVValid = false
                    end

                    if not isFailureCSV then
                        local ExitEarly = v[9]
                        if common.isCharBooleanOrEmpty(ExitEarly) == false then
                            reportStr2 = "Row " .. i
                            reportStr3 = "Parameter ExitEarly" .. ExitEarly.. " invalid; expecting Y/N/empty."
                            isCSVValid = false
                        end

                        -- Poison: should be Y/y, N/n or empty.
                        local SetPoison = v[10]
                        if common.isCharBooleanOrEmpty(SetPoison) == false then
                            reportStr2 = "Row " .. i
                            reportStr3 = "Parameter SetPoison " .. SetPoison .. " invalid; expecting Y/N/empty."
                            isCSVValid = false
                        end
                        local Condition = v[13]
                        local reportRow = "Row " .. i
                        conditionModule.checkConditionExpression(Condition,conditionNameArr,reportStr1,reportRow)
                    else
                        local Condition = v[10]
                        local reportRow = "Row " .. i
                        conditionModule.checkConditionExpression(Condition,conditionNameArr,reportStr1,reportRow)
                    end
                end
            end
        end

        if isCSVValid == false then
            error(reportStr1..", "..reportStr2..", "..reportStr3)
        end
    end
end

-- check limit csv syntax
function CheckCSVSyntax.checkLimitCSVSyntax(LimitCSVPath)
    local reportStr1 = "Limits.csv"
    local reportStr2 = ""
    local reportStr3 = ""

    local csvTable = ftcsv.parse(LimitCSVPath,",",{["headers"] = false,})
    local titleRow = csvTable[1]
    local expectedColumns = {
        "TestName", "ParameterName", "units", "upperLimit", "lowerLimit",
         "relaxedUpperLimit", "relaxedLowerLimit", "Condition"
    }
    local isCSVValid, row = common.arrayCmp(expectedColumns, titleRow)

    if not isCSVValid then
        reportStr2 = 'Title row invalid: Column['..row..'] is '..tostring(titleRow[row] or 'empty')..', expecting '..tostring(expectedColumns[row] or 'empty')
    else
        for i,v in ipairs(csvTable) do
            if i ~= 1 then
                reportStr2 = v[1]
                local condition = v[8]
                if condition ~= nil and condition ~= '' then
                    reportStr3 = "Condition cell should be empty"
                    isCSVValid = false
                end
                if v[3] == "string" then
                    if v[5] ~= "" then
                        reportStr3 = "lowerLimit invalid"
                        isCSVValid = false
                    end
                    if v[6] ~= "" then
                        reportStr3 = "relaxedUpperLimit invalid"
                        isCSVValid = false
                    end
                    if v[7] ~= "" then
                        reportStr3 = "relaxedLowerLimit invalid"
                        isCSVValid = false
                    end
                else
                    if v[4] ~= "" and tonumber(v[4]) == nil then
                        reportStr3 = "upperLimit invalid"
                        isCSVValid = false
                    end
                    if v[5] ~= "" and tonumber(v[5]) == nil then
                        reportStr3 = "lowerLimit invalid"
                        isCSVValid = false
                    end
                    if v[6] ~= "" and tonumber(v[6]) == nil then
                        reportStr3 = "relaxedUpperLimit invalid"
                        isCSVValid = false
                    end
                    if v[7] ~= "" and tonumber(v[7]) == nil then
                        reportStr3 = "relaxedLowerLimit invalid"
                        isCSVValid = false
                    end
                end
            end
        end
    end

    if isCSVValid == false then
        error(reportStr1..", "..reportStr2..", "..reportStr3)
    end
end


-- check csv sanitary
function CheckCSVSyntax.checkCSVSyntax(resourcesPath)

    ConditionCSVPath = resourcesPath .. "/Conditions.csv"
    if common.fileExists(ConditionCSVPath) then
        CheckCSVSyntax.checkConditionCSVSyntax(ConditionCSVPath)
    end
    
    CheckCSVSyntax.checkMainCSVSyntax(resourcesPath, "Main.csv")

    local samplingCSVPath = resourcesPath .. "/Sampling.csv"
    if common.fileExists(samplingCSVPath) then
        CheckCSVSyntax.checkSamplingCSVSyntax(samplingCSVPath)
    end

    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Tech")
    CheckCSVSyntax.checkTechCSVSyntax(resourcesPath, "Failure.csv", true)
    CheckCSVSyntax.checkMainCSVSyntax(resourcesPath, "Init.csv")
    CheckCSVSyntax.checkMainCSVSyntax(resourcesPath, "Teardown.csv")
    CheckCSVSyntax.checkLimitCSVSyntax(resourcesPath .. "/Limits.csv")
end

return CheckCSVSyntax
