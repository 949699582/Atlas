-------------------------------------------------------------------
----***************************************************************
----common functions
----***************************************************************
-------------------------------------------------------------------

local CommonFunc = {}
-- special string used to store nil value
-- to distinguish a variable that is not defined.
CommonFunc.NIL = 'NIL_VARIABLE_VALUE'

-- string split by a single delimiter.
-- Delimiter ",,," will be treated as ",,,".
-- Empty element between delimiters will be treated as empty string.
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitString("a,b,,,c,d",",") => {"a","b","","","c","d"}
function CommonFunc.splitString(input, delimiter)
    if not input or not delimiter then return nil end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if delimiter=='' then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- string split by a mixed delimiter.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitBySeveralDelimiter("a&&b||c&&d","&|") => {"a","b","c","d"}
function CommonFunc.splitBySeveralDelimiter(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'[^'..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- gain delimiter sequence in a string.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return delimiter array in a string
-- e.g. gainDelimiterSequence("a&&b||c&&d","&|") => {"&&","||","&&"}
function CommonFunc.gainDelimiterSequence(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'['..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- remove extra spaces at begin and end
-- @param str: input string
-- @return string after trimmed
-- e.g. trim(" a == b  ") => "a == b"
function CommonFunc.trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- present table as key-value string format
-- @param o: input table
-- @return key-value string format
-- e.g. dump({"a","b","c",["d"] = 4, ["e"] = 5,}) => { [1] = a,[2] = b,[3] = c,["d"] = 4,["e"] = 5,}
function CommonFunc.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. CommonFunc.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- deepCompare if 2 object are the same, support table recursively value compare
-- @param t1: a table to compare
-- @param t2: a table to compare against t1.
function CommonFunc.deepCompare(t1, t2)
    local type1 = type(t1)
    local type2 = type(t2)
    if type1 ~= type2 then return false end
    if type(t1) ~= 'table' and type(t2) ~= 'table' then return t1 == t2 end

    -- keys that has been compared
    local compared = {}
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not CommonFunc.deepCompare(v1, v2) then return false end
        compared[k1] = true
    end

    for k2 in pairs(t2) do
        if not compared[k2] then return false end
    end
    return true
end

-- return true if given table1 and table2 are identical: same length, same values.
-- return false and the different node index.
-- used to check if CSV title row is expected.
-- only works for array; do not support dictionary with key-value pairs.
function CommonFunc.arrayCmp(t1, t2)
    local i = 1
    while true do
        if t1[i] == nil and t2[i] == nil then
            return true
        end
        if t1[i] ~= t2[i] then
            return false, i
        end
        i = i + 1
    end
end

-- check if file exists at designated path
-- @param path: string type
-- @return whether the file exists
-- e.g. fileExists("/Users/gdlocal/Library/Atlas2/Assets/Main.csv") => true
function CommonFunc.fileExists(path)
  if not path then return nil end
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

-- read file contents
-- @param path: string type
-- @return file contents, string type
function CommonFunc.fileRead(path)
  if not path then return nil end
  local file = io.open(path, "r")
  if file then
    data = file:read("*all")
    file:close()
    return data
  end
  return ""
end

-- check if key exists in a dictionary
-- e.g. hasKey({["d"] = 4, ["e"] = 5,},"d") => true
function CommonFunc.hasKey(tab, key)
  if not tab or not key then return nil end
  for k in pairs(tab) do
      if k == key then
          return true
      end
  end
  return false
end

-- check if value exists in an array
-- e.g. hasVal({"d", "e",},"d") => true
function CommonFunc.hasVal(valueArr,valueStr)
    for _,value in ipairs(valueArr) do
        if value == valueStr then
            return true
        end
    end
    return false
end

-- return keys of a table
-- e.g. tableKeys({4,5,["a"]="44",}) => {1,2,"a",}
function CommonFunc.tableKeys(input_table)
    if not input_table then return nil end
    local output_keys = {}
    for k in pairs(input_table) do
        table.insert(output_keys, k)
    end
    return output_keys
end

-- system sleep
function CommonFunc.sleep(n)
    os.execute("sleep " .. tonumber(n))
end

-- run function catch_f if function f throws any exception
function CommonFunc.try(f, catch_f)
    local status, exception = xpcall(f,debug.traceback)
    if not status
    then
        catch_f(exception)
    end
end

-- parse given conditions string to table
-- {
--     {'left':left, 'right':right, 'operator':'!='}
--     {'left':left, 'right':right, 'operator':'==', 'relationToLeft':'&&'}
-- }
function CommonFunc.parseCondition(str)
    local conditions = CommonFunc.splitBySeveralDelimiter(CommonFunc.trim(str),"&|")
    local relations = CommonFunc.gainDelimiterSequence(CommonFunc.trim(str),"&|")
    local ret = {}
    for i, condition in ipairs(conditions) do
        local groups = CommonFunc.splitBySeveralDelimiter(condition, "!=")
        local operator = CommonFunc.gainDelimiterSequence(condition, "!=")[1]
        local left = CommonFunc.trim(groups[1])
        local right = CommonFunc.trim(groups[2])
        -- record && or || to its left
        ret[i] = {left=left, right=right, operator=operator, relationToLeft=relations[i-1]}
    end

    return ret
end

-- calculate boolean logic for condition column
-- @param str: input condition string
-- @return boolean value
-- e.g. calConditionVal(" sn == 2 && ver != 4",{["sn"] = "2",["ver"] = "4",["boardid"] = "C"}) => false
function CommonFunc.calConditionVal(str,conditionValueTable)
    if type(str) ~= "string" then
        error("Invalid condition ("..tostring(str).."); expect a string equation")
    end

    local conditions = CommonFunc.parseCondition(str)
    local conditionResult = nil
    for index, condition in ipairs(conditions) do
        -- values
        local left = condition.left
        local right = condition.right
        -- == != ~= within one condition
        local operator = condition.operator
        -- && || between conditions equations
        local relationToLeft = condition.relationToLeft
        local leftValue
        local rightValue
        if conditionValueTable[left] == nil and conditionValueTable[right] == nil then
            error('Condition ' .. left .. ' or ' .. right .. ' value not set')
        end

        if conditionValueTable[left] then
            leftValue = conditionValueTable[left]
        else
            leftValue = tostring(left)
        end

        if conditionValueTable[right] then
            rightValue = conditionValueTable[right]
        else
            rightValue = tostring(right)
        end

        local currentResult = nil
        if operator == '==' then
            currentResult = leftValue == rightValue
        elseif operator == '!=' or operator == '~=' then
            -- support both !=(existing) and ~= (lua) style -ne
            currentResult = leftValue ~= rightValue
        else
            -- other valid boolean logics can be expanded here
            error(string.format('Invalid operator : %s', operator))
        end

        -- accumulating result
        if relationToLeft == nil then
            -- first item
            assert(index == 1, 'condition.relationToLeft is nil but is not the 1st item')
            conditionResult = currentResult
        elseif relationToLeft == '&&' then
            conditionResult = conditionResult and currentResult
        elseif relationToLeft == '||' then
            conditionResult = conditionResult or currentResult
        else
            error(string.format('Invalid relationship between condition: %s', relationToLeft))
        end
    end

    return conditionResult
end

-- parse and return parameter list for further indexing, support dictionaries and arrays
-- @param paraStr: input parameter string
-- @return parameter dictionary or array
-- e.g. parseParameter("{\"Input\":\"success\",\"Output\":\"SN\",\"timeout\": 50}")
--      => { ["Input"] = "success",["Output"] = "SN",["timeout"] = "50",}
--      parseParameter("[a,b,c,1,2,3]")
--      => {"a","b","c","1","2","3"}
function CommonFunc.parseParameter(paraStr)
    local paraList = {}
    local json = require("Matchbox/json")
    if paraStr == "" then
        return paraList
    else
        return json.decode(paraStr)
    end
end

-- parse static conditions and store in an array
-- @param allowValStr: allowable value string, seperate by ";"
-- @return condition array
-- e.g. parseValArr("00011a;00011b;000111") => {"00011a","00011b","000111",}
function CommonFunc.parseValArr(allowValStr)
    local allowValArr
    allowValStr = CommonFunc.trim(allowValStr)
    allowValArr = CommonFunc.splitBySeveralDelimiter(allowValStr,";")
    for i in ipairs(allowValArr) do
        allowValArr[i] = CommonFunc.trim(allowValArr[i])
    end
    return allowValArr
end

-- run shell commands
function CommonFunc.runShellCmd(cmd)
    local RunShellCommand = Device.getPlugin("RunShellCommand")
    return RunShellCommand.run(cmd)
end

-- create extra log
function CommonFunc.exLog(...)
  local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
  local homePath = RunShellCommand.run("echo ~")
  homePath = homePath.output
  homePath = CommonFunc.trim(homePath)
  local file = io.open(homePath .. "/Desktop/extra.log", "a+")
  if file then
    for _,v in ipairs({...}) do
        file:write(tostring(v))
    end
    file:close()
    return nil
  end
  return nil
end

-- return tech sequence from tech csv for indexing
function CommonFunc.techSequence(techPath)
    local ftcsv = require("Matchbox/ftcsv")
    local techCsvTab = ftcsv.parse(techPath,",")
    local techSequence = {}
    for _,rowContent in ipairs(techCsvTab) do
        if rowContent.TestName ~= "" then
            techSequence[#techSequence+1] = rowContent.TestName
        end
    end
    return techSequence
end

-- return a cloned table.
function CommonFunc.clone(org)
    local function copy(orgs, res)
        for k,v in pairs(orgs) do
            if type(v) ~= "table" then
                res[k] = v;
            else
                res[k] = {};
                copy(v, res[k])
            end
        end
    end
    local res = {}
    copy(org, res)
    return res
end

-- create a read-only reference of a given table.
-- caller specify what error msg to report
-- when table write is attempted.
function CommonFunc.readOnly(t, msg)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function()
            local message = msg or 'Not allowed to modify local/global/condition table; use tech csv Output column to set values.'
            error(message, 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- the "map" operation: generate a new array by calling given function
-- to every item in current array
function CommonFunc.map(func, t)
    local ret = {}
    for i=1, #t, 1 do
        ret[i] = func(t[i])
    end
    return ret
end

-- process message to fit in failure reason:
-- 1. remove line returns
-- 2. trim to 512 bytes
function CommonFunc.trimFailureMsg(msg)
    --remove all \r and \n so this does not corrupt records.csv
    msg = string.gsub(msg, '[\r\n]', '; ')

    -- insight does not allows error message > 512 bytes.
    if (#msg > 512) then
        msg = string.sub(msg, 1, 509) .. '...'
    end

    return msg
end

-- check if given string is boolean Y/N/y/n
function CommonFunc.isCharBooleanOrEmpty(c)
    return c ~= nil and CommonFunc.hasVal({'', 'Y', 'N'}, c:upper())
end

-- check if given item is nil or empty, for csv cell.
function CommonFunc.notNILOrEmpty(c)
    return c ~= nil and c ~= ''
end

-- return if given number has no fractional part
-- used to check if sampling rate is valid
-- sampling rate accept only uint 1-100.
function CommonFunc.isInt(i)
    return i % 1 == 0
end

-- Check Atlas minimum allowable running version
function CommonFunc.checkAtlasVersion(userVersion)
    local result = Atlas.compareVersionTo(userVersion)
    if result == Atlas.versionComparisonResult.lessThan then error("Atlas version "..Atlas.version.." is lower then expected version("..userVersion..")")
    end
end

-- remove new line
-- @param str: input string
-- @return string after trimmed
function CommonFunc.trimNewLine(str)
  return string.gsub(str, '\n', '')
end

return CommonFunc
