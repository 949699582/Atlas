-------------------------------------------------------------------
----***************************************************************
----CSV loading functions
----***************************************************************
-------------------------------------------------------------------

local CSVLoad = {}
local common = require("Matchbox/CommonFunc")
local ftcsv = require("Matchbox/ftcsv")
local CSVSyntax = require 'Matchbox/CheckCSVSyntax'
local log = require 'Matchbox/logging'

-- Load Main.csv.
-- Result will be an array containing item dictionaries.
-- String in the first row will be keys for each item dictionary.
-- Test name must be unique for indexing actions
-- @param mainCSVPath: the path of Main.csv, string type
-- @return Parsed CSV table
-- @param mainCSVPath: the path of Main/Init/Teardown.csv, string type
-- @return Parsed CSV table without Notes column
function CSVLoad.loadItems(mainCSVPath)
    local columns = common.clone(CSVSyntax.mainCSVColumns)

    -- keep every column except for Notes
    for i, column in ipairs(columns) do
        if column == 'Notes' then
            table.remove(columns, i)
            break
        end
    end
    return ftcsv.parse(mainCSVPath,",", {fieldsToKeep=columns})
end

-- filter all items by mode and disable flag.
-- Remove disabled items and needless mode items.
-- Result will be an array containing necessary item dictionaries.
-- e.g. for item "Enter_Diags", the dictionary may look like:
-- @param parsedCSVTable: table
-- @param testMode: string
-- @return Filtered CSV table
function CSVLoad.filterItems(parsedCSVTable,testMode)
    local filteredCSVTable = {}
    local isItemLoad = {}
    local newRowNum = 1

    for i,v in ipairs(parsedCSVTable) do
        isItemLoad[i] = true
        -- load test mode
        -- TODO: change Y/N to upper when loading CSV, not doing upper() here
        if testMode == "Production" and v.Production:upper() ~= 'Y' then
            isItemLoad[i] = false
        end
        if testMode == "Audit" and v.Audit:upper() ~= 'Y' then
            isItemLoad[i] = false
        end
        -- check disabled items
        if isItemLoad[i] and v.Disable:upper() == 'Y' then
            isItemLoad[i] = false
        end
        -- Load items
        if isItemLoad[i] then
            filteredCSVTable[newRowNum] = v
            newRowNum = newRowNum + 1
        end
    end
    return filteredCSVTable
end

-- load tech csv
-- Result will be a dictionary with test names as keys and action arrays as values
-- e.g. for item "Enter_Diags", the key-value pair may look like:
-- ["Enter_Diags"] =
-- {
--    {["TestName"] = "Enter_Diags", ["Tech"] = "DUTstatus",["Actions"] = "Lua:createCommandRecord",
--     ["Parameter"] = "",["Command"] = "diags",["Conditions"] = ""},
--    {["TestName"] = "Enter_Diags", ["Tech"] = "DUTstatus",["Actions"] = "Lua:createParametricRecord",
--     ["Parameter"] = "{"Input":"enter diag success"}",["Command"] = "",["Conditions"] = ""}
-- }
-- Test name must be unique for indexing actions
-- @param techPath: the path of tech file, string type
-- @return action table
function CSVLoad.loadTech(techPath)
    local actionTable = {}
    local techName = techPath:match("/([^/]-)%.csv")
    if techName == nil then
        error("Tech path should contain Tech/Failure/Init/Teardown")
    end
    local techCSVTable = ftcsv.parse(techPath,",",{["headers"] = false,})
    local techTitleRow = techCSVTable[1]
    local parsedTechCSVTable = {}
    for i in ipairs(techCSVTable) do
        if i ~= 1 then
            parsedTechCSVTable[i-1] = {}
        end
    end
    local tempTestName = ""
    for i,v in ipairs(parsedTechCSVTable) do
        for ii = 1,#techTitleRow do
            v[techTitleRow[ii]] = techCSVTable[i+1][ii]
            if v["TestName"] ~= "" then
                tempTestName = v["TestName"]
            else
                v["TestName"] = tempTestName
            end
            v["Technology"] = techName
            v["Notes"] = nil
        end
    end
    for _,v in ipairs(parsedTechCSVTable) do
        if actionTable[v["TestName"]] == nil then
            actionTable[v["TestName"]] = {}
        end

        if v.Disable == nil or string.upper(v.Disable) ~= 'Y' then
            table.insert(actionTable[v["TestName"]],v)
        end
    end
    return actionTable
end

-- load all limits
-- Result will be a dictionary with test names as keys and limit dictionaries as values
-- e.g. for item "SN", the key-value pair may look like:
-- ["SN"] =
--     { ["TestName"] = "SN",["Units"] = "string",["UpperLimit"] = "DLXX0000AAAA",
--       ["LowerLimit"] = "",["UpperCoF"] = "",["LowerCoF"] = "",["Conditions"] = ""}
-- @param limitsPath: the path of Limits.csv, string type
-- @return limits table
function CSVLoad.loadLimits(limitsPath)
    local limitsTable = {}
    local itemArr = ftcsv.parse(limitsPath,",")
    for _, v in ipairs(itemArr) do
        local TestName = v.TestName
        local Paraname = v.ParameterName
        if limitsTable[TestName] == nil then
            limitsTable[TestName] = {[Paraname] = v}
        else
            limitsTable[TestName][Paraname] = v
        end

        -- convert value to number
        if v.units ~= 'string' then
            v.upperLimit = tonumber(v.upperLimit)
            v.lowerLimit = tonumber(v.lowerLimit)
            v.relaxedUpperLimit = tonumber(v.relaxedUpperLimit)
            v.relaxedLowerLimit = tonumber(v.relaxedLowerLimit)
        end
    end

    return limitsTable
end

function CSVLoad.loadSamplingGroups(samplingCSVPath)
    local sampleTable = ftcsv.parse(samplingCSVPath, ",")
    -- table passed into plugin: {{name1, rate1}, {name2, rate2}}
    -- use array which has less serialization overhead than dictionary
    local ret = {}
    for i, sampleLine in ipairs(sampleTable) do
        local name = sampleLine.name
        local numRate = tonumber(sampleLine.proposedRate)
        assert(numRate ~= nil, name..' has non-number default sample rate')
        log.LogInfo('Sample group: '..name..', proposed rate: '..numRate)
        ret[i] = {name, numRate}
    end
    return ret
end

function CSVLoad.loadConditions()
    local conditionTable = {}
    local tempCSVTable = ftcsv.parse(Atlas.assetsPath .. "/Conditions.csv", ",")
    for _, row in ipairs(tempCSVTable) do
        if common.hasVal(reservedConditions, row.ConditionName) then
            error(row.ConditionName..' is a reserved condition; do not redefine it in Conditions.csv')
        end
        -- isDynamic is not likely to be nil unless we change csv parser.
        local isDynamic = row.Dynamic:upper() == 'Y'
        local values = common.parseValArr(row.Values)
        conditionTable[row.ConditionName] = {isDynamic=isDynamic, values=values}
    end

    -- hardcode allowed list and type only for "Hang"
    -- don't allow user to set other reserved condition.
    conditionTable['Hang'] = {isDynamic=true, values={'TRUE', 'FALSE'}}
    return conditionTable
end


return CSVLoad
