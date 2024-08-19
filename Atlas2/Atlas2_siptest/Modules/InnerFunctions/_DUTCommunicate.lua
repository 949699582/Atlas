-------------------------------------------------------------------
----***************************************************************
----    _DUTCommunicate.lua provide functions to communciate with
----    DUT via virtural port and kis uart
----***************************************************************
-------------------------------------------------------------------
local _Utility = require("InnerFunctions/_Utility")
local CommonFunc = require("Matchbox/CommonFunc")
local DutUart = Device.getPlugin("DutUart")
local KisUart = Device.getPlugin("KisUart")
local Helper = require("SMTLoggingHelper")
local Utilities = Device.getPlugin("Utilities")
local PRMDelay = Device.getPlugin("PRMDelay")

local _DUTCommunicate = {}

local function _getUartInstance(uartType)
    if not uartType then
        uartType = "KISUART"
    else
        uartType = "KISUART"
    end
    if uartType == "KISUART" then
        return KisUart
    else
        return DutUart
    end
end

-- @Description: open DUT uart
-- @return boolean result
function _DUTCommunicate._open(uartType)
    local uartInstance = _getUartInstance(uartType)

    if uartInstance.isOpened() == 1 then
        return true
    end
    return uartInstance.open()
end

-- @Description: close DUT uart
-- @return boolean result
function _DUTCommunicate._close(uartType)
    local uartInstance = _getUartInstance(uartType)

    if uartInstance.isOpened() == 1 then
        return uartInstance.close()
    end

    return true
end

-- @Description: clear DUT response(read redundancy infomation to clear the Uart buffer)
-- @param timeout: number type
-- @return string result
function _DUTCommunicate._clear(timeout, uartType)
    if timeout == nil then
        error("timeout value is nil!")
    end

    local uartInstance = _getUartInstance(uartType)

    -- read data
    uartInstance.setTimeoutIsException(0)
    local _, response = pcall(uartInstance.readData, timeout)
    uartInstance.setTimeoutIsException(1)
    -- Helper.LogFlowDebug("_DUTCommunicate.clear: " .. tostring(response))

    return response
end

-- @Description: send DUT command with Uart.write
-- @param command: string type
-- @return boolean result
function _DUTCommunicate._send(command, uartType)
    local uartInstance = _getUartInstance(uartType)
    if uartType ~= "KISUART" then
        command = command .. "\n"
    end

    Helper.LogDutCommStart(command)
    uartInstance.write(command)

    return true
end

-- @Description: set delimiter with setDelimiter()
-- @param command: string type
-- @return boolean result
function _DUTCommunicate._setDelimiter(delimiter, uartType)
    local uartInstance = _getUartInstance(uartType)

    -- check the delimiter
    if delimiter and #delimiter > 0 then
        uartInstance.setDelimiter(delimiter)
    end

    return true
end

-- @Description: read DUT response by Uart.read and return the string by expectedKeyWord
-- @param delimiter: string type
-- @param timeout: number type
-- @param expectedKeyWord: string type
-- @return string result
function _DUTCommunicate._read(delimiter, timeout, expectedKeyWord, uartType)
    Helper.LogFlowDebug("_DUTCommunicate.read" .. ", delimiter=" .. tostring(delimiter) .. ", timeout=" ..
                            tostring(timeout) .. ", expectedKeyWord=" .. tostring(expectedKeyWord))

    if timeout == nil then
        error("timeout value is nil!")
    end

    local uartInstance = _getUartInstance(uartType)

    -- check the delimiter
    if delimiter and #delimiter > 0 then
        uartInstance.setDelimiter(delimiter)
    end

    -- read data
    local retVal = uartInstance.read(timeout)

    Helper.LogDutCommFinish(retVal)

    -- Judge if contain expected key word
    if expectedKeyWord then
        if string.find(retVal, expectedKeyWord) then
            Helper.LogFlowDebug("ok: find the expected key word")
            return tostring(retVal)
        else
            Helper.LogFlowDebug("error: can't find the expected key word")
            return false
        end
    else
        Helper.LogFlowDebug("no expected key, return value directly!")
        return tostring(retVal)
    end
end

-- @Description: read DUT response by Uart.readData
-- @param delimiter: string type
-- @param timeout: number type
-- @param expectedKeyWord: string type
-- @return string result
function _DUTCommunicate._readData(delimiter, timeout, expectedKeyWord, uartType)
    Helper.LogFlowDebug("_DUTCommunicate.readData" .. ", delimiter=" .. tostring(delimiter) .. ", timeout=" ..
                            tostring(timeout) .. ", expectedKeyWord=" .. tostring(expectedKeyWord))

    if timeout == nil then
        error("timeout value is nil!")
    end

    local uartInstance = _getUartInstance(uartType)

    if delimiter and #delimiter > 0 then
        uartInstance.setDelimiter(delimiter)
    end

    -- read Data
    uartInstance.setTimeoutIsException(0)
    local retValData = uartInstance.readData(timeout)
    uartInstance.setTimeoutIsException(1)

    local retVal = Utilities.dataToHexString(retValData)

    -- Judge if contain expected key word
    if expectedKeyWord then
        -- convert hex Data to ASCII
        retVal = _Utility._hexStrToASCII(tostring(retVal))
        Helper.LogDutCommFinish(tostring(retVal))

        if string.find(retVal, expectedKeyWord) then
            Helper.LogFlowDebug("ok: find the expected key word")
            return tostring(retVal)
        else
            Helper.LogFlowDebug("error: can't find the expected key word")
            return false
        end
    else
        Helper.LogDutCommFinish(tostring(retVal))
        Helper.LogFlowDebug("no expected key, return value directly!")
        return tostring(retVal)
    end
end

-- @Description: sendCmdWithInterCharacterDelay
-- @param command: string type
-- @param characterSize: number type
-- @param delay: number type
-- @param timeout: number type
-- @return string result
function _DUTCommunicate._sendCmdWithInterCharacterDelay(command, characterSize, delay, timeout, delimiter)
    command = command .. "\n"
    if #command <= characterSize then
        DutUart.write(command)
    else
        for i = 1, #command, characterSize do
            DutUart.write(string.sub(command, i, i + characterSize - 1))
            PRMDelay.delay(delay)
        end
    end
    if delimiter and #delimiter > 0 then
        return DutUart.read(timeout, delimiter)
    else
        return DutUart.read(timeout)
    end
end

-- @Description: send DUT command and read DUT response with Uart.send
-- @param command: string type
-- @param delimiter: string type
-- @param timeout: number type
-- @param expectedKeyWord: string type
-- @param needParser: boolean type, MDParse only catch one value
-- @return string result
function _DUTCommunicate._sendReadStr(command, timeout, expectedKeyWord, delimiter, needParser, uartType)
    Helper.LogFlowDebug("_DUTCommunicate.sendReadStr" .. ", command=" .. tostring(command) .. ", delimiter=" ..
                            tostring(delimiter) .. ", timeout=" .. tostring(timeout) .. ", expectedKeyWord=" ..
                            tostring(expectedKeyWord) .. ", needParser=" .. tostring(needParser))

    if timeout == nil then
        error("timeout value is nil!")
    end
    if command == nil then
        error("command string is nil!")
    end

    local uartInstance = _getUartInstance(uartType)

    local bReult = true
    if delimiter and #delimiter > 0 then
        uartInstance.setDelimiter(delimiter)
    end

    local _, retVal
    Helper.LogDutCommStart(command)
    if uartType == "KISUART" then
        _, retVal = pcall(uartInstance.send, command, timeout)
    else
        _, retVal = pcall(_DUTCommunicate._sendCmdWithInterCharacterDelay, command, 6, 0.0002, timeout, delimiter)
    end
    Helper.LogDutCommFinish(retVal)

    -- when the read action "Timed out" or the read info is nil, then resend "\n" and read the DUT buffer again.
    if retVal == nil or string.find(tostring(retVal), "Timed out") then
        if uartType == "KISUART" then
            _, retVal = pcall(uartInstance.send, "", timeout)
        else
            _, retVal = pcall(_DUTCommunicate._sendCmdWithInterCharacterDelay, "", 6, 0.0002, timeout, delimiter)
        end
        Helper.LogFlowDebug("resend \\n and read the DUT buffer again:" .. retVal)
        _DUTCommunicate._clear(0.005, uartType)
    end

    -- when the read action "unknown subcommand" or "bad params" then resend command and read the DUT buffer again.
    if string.find(tostring(retVal), "unknown subcommand") or string.find(tostring(retVal), "bad params") then
        if uartType == "KISUART" then
            _, retVal = pcall(uartInstance.send, command, timeout)
        else
            _, retVal = pcall(_DUTCommunicate._sendCmdWithInterCharacterDelay, command, 6, 0.0002, timeout, delimiter)
        end

        Helper.LogFlowDebug(
            "Because of 'unknown subcommand' or 'bad params' issue, resend command and read the DUT buffer again: " ..
                retVal)
        _DUTCommunicate._clear(0.005, uartType)
    end

    -- parse the value with expectedKeyWord
    if expectedKeyWord then
        if string.find(retVal, expectedKeyWord) then
            Helper.LogFlowDebug("ok: find the expected key word")
        else
            bReult = false
            Helper.LogFlowDebug("error: can't find the expected key word")
        end

    end

    -- parse and return one value with MDParser
    if needParser then
        local MDParser = Device.getPlugin("MDParser")
        -- execute parse function
        local result, pData = xpcall(MDParser.parse, debug.traceback, command, retVal)
        if not result then
            error("MDParser response failed: " .. tostring(command))
        end
        for _, v in pairs(pData) do
            if v ~= nil then
                retVal = CommonFunc.trim(v)
            else
                bReult = false
                Helper.LogFlowDebug("parse failed!")
            end
        end
    end
    if bReult then
        return retVal, bReult
    else
        return false
    end
end

return _DUTCommunicate
