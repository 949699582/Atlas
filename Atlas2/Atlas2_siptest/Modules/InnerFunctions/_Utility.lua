local Helper = require("SMTLoggingHelper")
local ComFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")
local _Utility = {}

-- ===========================--
-- Unit exponents
-- ===========================--
local unit_exponents = {
    LENGTH = {NM = -9, UM = -6, MM = -3, CM = -2, M = 0},
    VOLTAGE = {NV = -9, UV = -6, MV = -3, V = 0},
    CURRENT = {NA = -9, UA = -6, MA = -3, A = 0},
    POWER = {UW = -6, MW = -3, W = 0},
    FREQUENCY = {HZ = 0, KHZ = 3, MHZ = 6, GHZ = 9},
    RESISTANCE = {MOHM = -3, OHM = 0, KOHM = 3},
    TIME = {S = 0, MS = -3, US = -6, NS = -9},
    PEAKVOLTAGE = {VPP = 0, MVPP = -3},
    BYTE = {B = 0, KB = 1, MB = 2, GB = 3, TB = 4}
}

-- @Description: Convert value from one unit to another.
-- Can be used to guarantee consistent units for a specific function.
-- Does not guarantee that volts are converted to volts, seconds to seconds, etc.
-- @param value: [float]  number to convert
-- @param from_units: [string]    units to convert from (e.g. mV).
-- @param to_units:   [string]    units to convert to (e.g. V).
-- @return:float, number converted from from_units -> to_units.
-- @Examples:3.23 A --> 3230 mA, value = Conmmon.convertUnits(3.23, "A", "mA")
function _Utility._convertUnits(value, from_units, to_units)
    if tonumber(value) == nil then
        return "--FAIL--"
    end
    if from_units == nil or to_units == nil then
        error("The value passed in is invalid")
    end

    local from_u, to_u = nil, nil
    for _, v in pairs(unit_exponents) do
        from_u = v[string.upper(from_units)]
        to_u = v[string.upper(to_units)]
        if from_u and to_u then
            break
        end
    end

    if from_u == nil or to_u == nil then
        error("The passed unit does not exist")
    end

    -- order of magnitude
    local delta_exponent = from_u - to_u
    return tonumber(value) * math.pow(10, delta_exponent)
end

-- Description: convert hex data to string
-- Param: imputStr --> rawdata
function _Utility._hexStrToASCII(inputStr)
    Helper.LogFlowDebug("inputStr type :", type(inputStr))
    if type(inputStr) ~= "string" then
        Helper.LogFlowDebug("please help to check the inputStr type!")
        return false
    end

    inputStr = string.gsub(inputStr, " ", "")
    inputStr = string.gsub(inputStr, "<", "")
    inputStr = string.gsub(inputStr, ">", "")
    -- Helper.LogFlowDebug("DealWithData: ",inputStr)

    -- filter unvisble characters and convert hex to string
    local retStr = ""
    if #inputStr % 2 ~= 0 then
        Helper.LogFlowDebug("The hex codes should all be two characters!")
        return false
    else
        for i = 1, #inputStr, 2 do
            local decVal = tonumber("0x" .. string.sub(inputStr, i, i + 1))
            if (decVal >= 32 and decVal <= 126) or decVal == 10 or decVal == 13 then
                local charVal = string.char(decVal)
                retStr = retStr .. tostring(charVal)
            end
        end
    end

    return retStr
end

-- @Description: convert decimal data to binary string
-- @param rawdata: decimal data
-- @return: binary string
function _Utility._dec2Bin(decData)
    assert(type(decData) == "number", "input decData type is not correct.")
    local binStrTable = {}

    while decData ~= 0 do
        table.insert(binStrTable, 1, decData % 2)
        decData = math.floor(decData / 2)
    end

    return table.concat(binStrTable)
end

-- @Description: convert binary to upper hex by byte
-- @param rawdata: binary data
-- @return: hex data
function _Utility._bin2Hex(binaryData)
    assert(binaryData ~= nil, "The binaryData is empty!")
    local retStr = ""

    for i = 1, string.len(binaryData) do
        if i == 1 then
            -- reserve ":" in font of every raw string
            retStr = retStr .. string.sub(binaryData, 1, 1)
        else
            local charStr = string.byte(binaryData, i, i)
            local hexStr = string.format("%02x", charStr)

            retStr = retStr .. string.upper(hexStr)
        end
    end

    return retStr
end

-- @Description: method for calculate average of a table
-- @para: (input)or [input]
-- @return: number(if wrong return false)
-- param write in column of "Input"
-- eg:(table) or [table]   {1,2,3,4,5}  => avg value is: 3
function _Utility._calAvg(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end

    local sum = 0
    for _, v in pairs(dataTable) do
        sum = sum + v
    end
    Helper.LogFlowDebug("SUM is: " .. sum .. " Avg is: " .. sum / len)

    return sum / len
end

-- @Description: method for calculate rms of a table
-- @para: (input)or [input]
-- @return: number(if wrong return false)
-- param write in column of "Input"
-- eg:(table) or [table]   {1,2,3,4,5}  => rms value is: 3
function _Utility._calRMS(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end

    local sum = 0
    local rms
    for _, v in pairs(dataTable) do
        sum = sum + math.pow(v, 2)
    end
    rms = math.sqrt(sum / len)
    Helper.LogFlowDebug("SUM is: " .. sum .. " RMS is: " .. rms)

    return rms
end

-- @Description: method for calculate std of a table
-- @para: (input)or [input]
-- @return: number(if wrong return false)
-- param write in column of "Input"
-- eg:(table) or [table]   {1,2,3,4,5}  => std value is:
function _Utility._calSTD(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end
    local sum = 0
    for _, v in pairs(dataTable) do
        sum = sum + v
    end

    local avg = sum / len
    local sum2 = 0
    for _, v in pairs(dataTable) do
        sum2 = sum2 + math.pow((v - avg), 2)
    end

    return math.sqrt(sum2 / len)
end

-- @Description: string.unpack
-- @param [string]
-- @return: vdata table
-- @Author: liang.liu
function _Utility._unpackString(str)
    local ret = string.gsub(str, "(.)(.)", function(h, l)
        return string.char(tonumber("0x" .. h .. l))
    end)
    local nextLocation = 1
    local dataTable = {}

    while (nextLocation < (#str / 2)) do
        local data
        data, nextLocation = string.unpack("<h", ret, nextLocation)
        table.insert(dataTable, data)
    end

    return dataTable
end

-- @Description: convert to fixed length hexadecimal format string
-- @param hexStr: string type
-- @param length: number type
-- @return: string type
function _Utility._setHexStrWidth(hexStr, length)
    assert(type(hexStr) == "string", "setHexStrWidth: hexStr is not string type")
    assert(type(length) == "number", "setHexStrWidth: length is not number type")
    hexStr = string.gsub(hexStr, "0x", "")
    assert(#hexStr <= length, "setHexStrWidth: hexStr's length out target")
    for _ = 1, length - #hexStr do
        hexStr = "0" .. hexStr
    end
    hexStr = "0x" .. hexStr
    return hexStr
end

-- @Description: convert to Dec data
-- @param data: string type
-- @param dataType: string type
-- @return: number type
function _Utility._str2Dec(data, dataType)
    assert(data ~= nil and data ~= "", "parameter is invalid, data= " .. data)
    assert(dataType == "BIN" or dataType == "DEC" or dataType == "HEX", "parameter is invalid, dataType= " .. dataType)
    if dataType == "BIN" then
        return tonumber(data, 2)
    elseif dataType == "DEC" then
        return tonumber(data, 10)
    elseif dataType == "HEX" then
        return tonumber(data, 16)
    else
        return false
    end
end

-- @Description: reverse hexadecimal data by byte
-- @param data: string type
-- @return: string type
function _Utility._reverseEndian(data)
    assert(type(data) == "string" and data ~= "" and #data % 2 ~= 1, "parameter is invalid, data= " .. data)
    local reverseData = ""
    for i = #data, 2, -2 do
        reverseData = reverseData .. string.sub(data, i - 1, i)
    end
    return reverseData
end

-- ! @brief calculate the length of bin value
-- ! @details concert datat to binary and calculate the length
-- ! @param, input data, type should be number of dec
-- ! @returns length
function _Utility._bitLength(data)
    assert(type(data) == "number", "input data type is not correct.")
    -- use data to divide to get the length
    local bitLen = 0
    local tmp = data

    while tmp >= 1 do
        tmp = tmp >> 1
        bitLen = bitLen + 1
    end

    return bitLen
end

-- ! @brief slice table from start index to end index
-- ! @details slice the table to get expect
-- ! @param, tbl: source, start, end, and step
-- ! @returns sub table
function _Utility._sliceTable(tbl, startIndex, endIndex, step)
    assert(type(tbl) == "table", "tbl is not a table")
    local newTable = {}
    for i = startIndex or 1, endIndex or #tbl, step or 1 do
        newTable[#newTable + 1] = tbl[i]
    end
    return newTable
end

-- ! @brief concatenate table
-- ! @details concat two table as one table
-- ! @param, table A and B are the source
-- ! @returns sum table
function _Utility._concatTable(tableA, tableB)
    assert(type(tableA) == "table", "tableA is not a table")
    assert(type(tableB) == "table", "tableB is not a table")
    local newTable = tableA
    for index, value in ipairs(tableB) do
        newTable[index] = value
    end
    return newTable
end

-- ! @brief compare two table
-- ! @details compare length and each table contents
-- ! @param, table A and B are the source
-- ! @returns pass/fail
function _Utility._compareTable(tableA, tableB)
    assert(type(tableA) == "table", "tableA is not a table")
    assert(type(tableB) == "table", "tableB is not a table")
    for index, _ in ipairs(tableA) do
        if #tableA ~= #tableB then
            Helper.LogFlowDebug("Table size are not same.")
            return false
        end

        if tableA[index] ~= tableB[index] then
            Helper.LogFlowDebug("Table value are not same, inex: " .. tostring(index) .. " tableA[index]:" ..
                                    tostring(tableA[index]) .. " tableB[index]:" .. tostring(tableB[index]))
            return false
        end
    end

    return true
end

-- Description: get version infomation from setting file and then show it on UI.
-- return: string type， return limitVersion
function _Utility._getGoatOverlayVersion()
    local limitFilePath = "/private/etc/config/goat/station_overlay_version.json"
    local jsonContent = ComFunc.fileRead(limitFilePath)
    local limitJson = json.decode(jsonContent)
    local limitVersion = limitJson["overlay_version"]
    Helper.LogFlowDebug("limitVersion by getGoatOverlayVersionByRunshellcmd: ", limitVersion)
    if not limitVersion then
        error("parser the LIMITS_VERSION fail")
    end

    return limitVersion
end

-- ! @brief intercept the long string length at 512 char and replace '[\r\n,]'with' '
-- ! @param str: input string
-- ! @return string after trimmed
function _Utility.trimValueStr(str)
    local msg = ComFunc.dump(str)
    if (#msg > 512) then
        msg = string.sub(msg, 1, 509) .. '...'
    end
    return string.gsub(msg, '[\r\n,]', ' ')
end

-- ! @brief remove the max and min value in list
-- ! @param table, list
-- ! @return table, list
function _Utility.filterMaxMinValInTable(rawDataList)
    assert(type(rawDataList) == "table", "input data is not table type")
    assert(#rawDataList >= 2, "there is not enough item in table")
    if #rawDataList < 2 then
        return rawDataList
    end

    local filteredDataList = {table.unpack(rawDataList)}
    local maxVal = math.max(table.unpack(filteredDataList))
    local maxValKey, minValKey = 1, 1

    for k, v in pairs(filteredDataList) do
        if v == maxVal then
            maxValKey = k
            break
        end
    end
    table.remove(filteredDataList, maxValKey)

    local minVal = math.min(table.unpack(filteredDataList))
    for k, v in pairs(filteredDataList) do
        if v == minVal then
            minValKey = k
            break
        end
    end
    table.remove(filteredDataList, minValKey)

    return filteredDataList
end

-- @Description: convert hex to Bin data
-- @param data: hexString type
-- @param dataType: binTable type
-- @return: binTable
function _Utility.hexStr2Bin(hexString)
    local binTable = {}
    local hexNumber = tonumber(hexString, 16)
    for i = (#hexString * 4 - 1), 0, -1 do
        binTable[#binTable + 1] = math.floor(hexNumber / 2 ^ i)
        hexNumber = hexNumber % 2 ^ i
    end
    local binString = table.concat(binTable)
    Helper.LogFlowDebug(binString)
    return binTable
end

-- @Description: verify value
-- @param value: number type, verify value
-- @param target: number type, target value
-- @param comType: string type, compare type
-- @return boolean type, verify result
function _Utility.compareVal(value, target, comType)
    local bRet
    bRet = false
    if tonumber(value) == nil or tonumber(target) == nil then
        bRet = false
    elseif comType == "<" then
        if tonumber(value) < tonumber(target) then
            bRet = true
        end
    elseif comType == "<=" then
        if tonumber(value) <= tonumber(target) then
            bRet = true
        end
    elseif comType == ">" then
        if tonumber(value) > tonumber(target) then
            bRet = true
        end
    elseif comType == ">=" then
        if tonumber(value) >= tonumber(target) then
            bRet = true
        end
    else
        bRet = false
    end

    local info = string.format("[Verify Value] %s %s %s = %s", value, comType, target, bRet)
    Helper.LogFlowDebug(info)

    return bRet
end

-- @Description: dump data to csv
-- @param filePath: string type
-- @param dataTab: table type
-- @return boolean type, true/false
function _Utility.dumpToCSV(filePath, dataTab, header)
    local bRet = true
    local contents = header or "Data"

    if type(dataTab) ~= "table" then
        return false
    end

    local csvFD = io.open(filePath, "a+")
    if csvFD ~= nil then
        csvFD:write(contents .. "\r\n" .. table.concat(dataTab, "\r\n"))
        csvFD:close()
    else
        csvFD = nil
        bRet = false
    end

    local info = string.format("[Dump data path] " .. csvFD .. filePath)
    Helper.LogFlowDebug(info)

    return bRet
end

return _Utility
