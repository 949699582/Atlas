-------------------------------------------------------------------
----***************************************************************
----    prmLib.lua provied common functions for lua
----***************************************************************
-------------------------------------------------------------------
local json = require("InnerFunctions/PRM/Functions/Lib/json")

local prmLib = {}

-- split string with specific string
-- @param str: string type
-- @param reps: string type
-- @return list after split
function prmLib.split(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

-- check value is in table or not
-- @param val: string type
-- @param tbl: list type
-- @return boolean result
function prmLib.valueInTable(val, tbl)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

-- binary to hex string
-- @param binVal: binary type
-- @return hex result
function prmLib.bin2hex(binVal)
    return string.gsub(binVal, "(.)", function(x)
        return string.format("%02X ", string.byte(x))
    end)
end

-- sum values in table
-- @param tbl: list type
-- @return sum of list
function prmLib.sumTable(tbl)
    local ret = 0
    for _, v in pairs(tbl) do
        ret = ret + v
    end
    return ret
end

-- slice table from start index to end index
-- @param tbl: list type
-- @param startIndex: number type
-- @param endIndex: number type
-- @param step: number type
-- @return list after sliced
function prmLib.sliceTable(tbl, startIndex, endIndex, step)
    local ret = {}
    for i = startIndex or 1, endIndex or #tbl, step or 1 do
        ret[#ret + 1] = tbl[i]
    end
    return ret
end

-- strip string
-- @param str: string type
-- @return string after strip
function prmLib.stripString(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

-- strip string
-- @param str: string type
-- @return string after strip
function prmLib.indexOfTable(val, tbl)
    for k, v in pairs(tbl) do
        if val == v then
            return k - 1
        end
    end
    return nil
end

-- system sleep
-- @param time_ms: number type
-- @return true always
function prmLib.mSleep(time_ms)
    os.execute("sleep " .. tonumber(time_ms / 1000.0))
    return true
end

-- convert json string to list
-- @param jsString: string type
-- @return list result, if convert fail, return original string
function prmLib.jsonStringToList(jsString)
    -- local str = "{\"rms\": [152.6251650267, \"mVrms\"], \"thdn\": [-69.7009406264, \"dB\"]}"
    local result, jsList = pcall(json.decode, jsString)
    if result and type(jsList) == "table" then
        return jsList
    else
        return jsString
    end
end

-- check table if contain valid data
-- @param tbl: table type
-- @return boolean result, return false if table is nil/emoty or only contains nil
function prmLib.validTable(tbl)
    if tbl == nil or next(tbl) == nil then
        return false
    end
    return true
end

return prmLib
