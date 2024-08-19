-------------------------------------------------------------------
----***************************************************************
----    instrumentDeamon.lua provied functions for _Instrument.lua
----***************************************************************
-------------------------------------------------------------------
local ComFunc = require 'Matchbox/CommonFunc'
local Log = require("Matchbox/logging")
local prmLib = require("InnerFunctions/PRM/Functions/Lib/prmLib")
local _RPC = require "InnerFunctions/_RPC"
local Time = require("Tech/Time")

local instrumentDeamon = {}
local timeout = 10000

local mutex = require("mutex")
local mutexPlugin = Device.getPlugin("Mutex")
local variablePlugin = Device.getPlugin("VariableTable")

-- call rpc function
-- @param command: string type
-- @param timeout: number type
-- @param ...: string type
-- @return string of command response
function instrumentDeamon.callRPCFunc(command, m_rpcTimeout, ...)
    local param = {}
    for _, v in ipairs {...} do
        table.insert(param, v)
    end
    local ret = _RPC._callRPCFunc(command, param, m_rpcTimeout)
    if ret ~= nil then
        if type(ret) == "string" and #ret > 0 then
            if string.find(ret, "RPCError") then
                return false
            elseif string.upper(ret) == "DONE" then
                return true
            else
                return ret
            end
        elseif type(ret) == "table" and prmLib.validTable(ret) then
            return ret
        elseif type(ret) == "boolean" or type(ret) == "number" then
            return ret
        else
            Log.LogInfo(" mixRPC.callRPCFunc reponse unknow type=" .. type(ret))
            return false
        end
    else
        return false
    end
end

-- call rpc function
-- @param command: string type
-- @param timeout: number type
-- @param ...: string type
-- @return string of command response
function instrumentDeamon.callSPKRPCFunc(command, m_rpcTimeout, ...)
    local param = {}
    for _, v in ipairs {...} do
        table.insert(param, v)
    end
    local ret = _RPC._callSPKRPCFunc(command, param, m_rpcTimeout)
    if ret ~= nil then
        if type(ret) == "string" and #ret > 0 then
            if string.find(ret, "RPCError") then
                return false
            elseif string.upper(ret) == "DONE" then
                return true
            else
                return ret
            end
        elseif type(ret) == "table" and prmLib.validTable(ret) then
            return ret
        elseif type(ret) == "boolean" or type(ret) == "number" then
            return ret
        else
            Log.LogInfo(" mixRPC.callRPCFunc reponse unknow type=" .. type(ret))
            return false
        end
    else
        return false
    end
end

-- read fixture info
-- @param keyWord: string type, "VENDOR_ID"|"FIXTURE_ID"|"MIX_FW_VERSION|GN_PORT"
-- @return string result
function instrumentDeamon.fixtureInfo(keyWord)
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.fixtureInfo", timeout)
    Log.LogInfo("[InstrumentDeamon][PRM] func=fixtureInfo, return=" .. keyWord .. tostring(retVal))
    return retVal
end

-- get PCB config
-- @param value
-- @return string result
function instrumentDeamon.getConfigLSB(value)
    local retVal = string.sub(value, #value, #value)
    Log.LogInfo("[InstrumentDeamon][PRM] func=getConfigLSB, return=" .. tostring(retVal))
    return retVal
end

-- @Description: discharge VDD_MAIN
-- @return boolean result
function instrumentDeamon.dischargeVDDMAIN(netName)
    netName = netName or 'RELAY@DISCHARGE_PP_VDD_MAIN'
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.disCharge", timeout, netName, 100)
    Log.LogInfo("[InstrumentDeamon][PRM] func=dischargeVDDMAIN, return=" .. tostring(retVal))
    return retVal
end

-- @Description: set DAC ISink current
-- @param current: string type
-- @param netName: string type
-- @param switch: string type, "CONNECT"|"DISCONNECT"
-- @return boolean result
function instrumentDeamon.setISink(current, netName, switch)
    assert(current ~= nil, "setISink: given current is nil")
    assert(netName ~= nil, "setISink: given netName is nil")
    assert(string.upper(switch) == "CONNECT" or string.upper(switch) == "DISCONNECT",
           "parameter is invalid, switch= " .. switch)
    netName = string.upper(netName)
    switch = string.upper(switch)
    local currentValue, _ = string.match(current, "([%d\\.]+)([%S]+)")
    local retVal = instrumentDeamon.relay(netName, switch)
    retVal = retVal and instrumentDeamon.selectDACMode('MODE_I_SINK', currentValue)
    Log.LogInfo("[InstrumentDeamon][PRM] func=setDACISinkCurrent, return=" .. tostring(retVal))
    if retVal then
        return true
    else
        return false
    end
end

-- relay netName
-- @param netName: string type
-- @param switch: string type, "CONNECT"|"DISCONNECT"
-- @return string result
function instrumentDeamon.relay(netName, switch)
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.relay", timeout, netName, switch)
    Log.LogInfo("[InstrumentDeamon][PRM] func=relay, return=" .. tostring(retVal))
    return retVal
end

-- select DAC ad5667 mode
-- @param mode: string type
-- @param outputValue: number type
-- @return boolean result
function instrumentDeamon.setDACMode(mode, outputValue)
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.setDACMode", timeout, mode, outputValue)
    Log.LogInfo("[InstrumentDeamon][PRM] func=selectDACMode, return=" .. tostring(retVal))
    return retVal
end

-- select DAC ad5667 mode
-- @param mode: string type
-- @param outputValue: number type
-- @return boolean result
function instrumentDeamon.setDACOutput(DACType, channel, outputValue)
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.setDACOutput", timeout, DACType, channel, outputValue)
    Log.LogInfo("[InstrumentDeamon][PRM] func=setDACOutput, return=" .. tostring(retVal))
    return retVal
end

-- open PDM
-- @param fs: number type, [0.0-0.999], the unit is mV, PDM output signal Vpp.
-- @param sampleRate: number type, [1000~125000000], the unit is Hz, IPCore sampling rate configure, default 1600000Hz.
-- @param frequency: number type, unit is Hz
-- @return boolean result
function instrumentDeamon.openPDM(sampleRate, fs, frequency, edge)
    sampleRate = sampleRate and sampleRate or 3072000
    fs = fs and fs or 0.3
    edge = edge and string.lower(edge) or "negative"
    local retVal = instrumentDeamon.callRPCFunc("pdm.open", timeout, sampleRate, fs, frequency, edge)
    -- wait 300ms for pdm open
    Time.__delay(300)
    Log.LogInfo("[InstrumentDeamon][PRM] func=openPDM, return=" .. tostring(retVal))
    return retVal
end

-- close PDM
-- @return boolean result
function instrumentDeamon.closePDM()
    local retVal = instrumentDeamon.callRPCFunc("pdm.close", timeout)
    Log.LogInfo("[InstrumentDeamon][PRM] func=closePDM, return=" .. tostring(retVal))
    return retVal
end

-- measure temperature
-- @return string result
function instrumentDeamon.measureTemperature()
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.readFixtureTemperature", timeout)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureTemperature, return=" .. tostring(retVal))
    return retVal
end

-- measure frequency
-- @param scope: string type
-- @param netName: string type
-- @return string result
function instrumentDeamon.measureFrequency(scope, netName)
    scope = scope and string.upper(scope) or "L"
    if scope == "900" then
        scope = "L"
    end
    assert(netName ~= nil, "measureFrequency: given netName is nil")
    local retVal = instrumentDeamon.selectDACMode('MODE_FREQ_L')
    retVal = retVal and instrumentDeamon.relay(netName, "CONNECT")
    if retVal then
        -- wait 50ms after relay before frequency measurement
        Time.__delay(50)
    end
    retVal = instrumentDeamon.callRPCFunc("freq" .. string.lower(scope) .. ".measure_frequency", timeout, 100)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureFrequency, return=" .. tostring(retVal))
    return retVal['freq']
end

-- measure voltage
-- @param netName: string type
-- @param scope: string type
-- @return list result
function instrumentDeamon.measureVoltageRawData(netName, scope, count)
    local sampleRate = 1000

    local retVal = instrumentDeamon.callRPCFunc("mixdevice.measureVoltageDMM", timeout, "list", scope, sampleRate,
                                                count, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureVoltageRawData, return=" .. tostring(retVal))
    return retVal
end

-- measure voltage by datalogger
-- @param scope: string type
-- @param duration: number type, units are seconds, about 62 data can be read in 0.1s.
-- @return list result
function instrumentDeamon.measureVoltageByDatalogger(scope, netName, duration)
    local sampleRate = 1000
    -- local duration_ms = duration*1000
    local count = 100
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.measureVoltageDMM", timeout, 'datalogger', scope, sampleRate,
                                                count, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureVoltageByDatalogger, return=" .. duration .. tostring(retVal))
    return retVal
end

-- measure voltage and return average value of filter data
-- @param netName: string type
-- @param scope: string type
-- @return string result
function instrumentDeamon.measureVoltage(netName, scope)
    local sampleRate = 1000
    local count = 5
    local dataList = instrumentDeamon.callRPCFunc("mixdevice.measureVoltageDMM", timeout, 'list', scope, sampleRate,
                                                  count, netName)
    table.sort(dataList)
    dataList = prmLib.sliceTable(dataList, tonumber(#dataList * 0.2) + 1, tonumber(#dataList * 0.8))
    local retVal = prmLib.sumTable(dataList) * 1.0 / #dataList
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureVoltage, return=" .. tostring(retVal))
    return retVal
end

-- measureVoltageContinuousSampling
-- @param netName: string type
-- @param scope: string type
-- @param sampleRate: number type
-- @param count: number type
-- @param target: result type
-- @return float result
function instrumentDeamon.measureVoltageContinuousSampling(netName, scope, sampleRate, count, target)
    assert(netName ~= nil, "measureVoltageContinuousSampling: given netName is nil")
    scope = scope and string.upper(scope) or "5V"
    sampleRate = sampleRate and tonumber(sampleRate) or 1000
    count = count and tonumber(count) or 10
    target = target and target or "avg_v2"
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.measureVoltageDMM", timeout, 'statistics', scope, sampleRate,
                                                count, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureVoltageContinuousSampling, return=" .. target .. tostring(retVal))
    return retVal
end

-- set measure current scope
-- @param scope: number type
-- @return boolean result
function instrumentDeamon.setMeasureCurrentRange(scope)
    scope = string.match(scope, "([%d\\.]+)([%S]+)")
    scope = scope and tonumber(scope) or 1000
    local retVal = instrumentDeamon.callRPCFunc("odin.configure_input_channel", timeout, 2, "battery", 5, scope)
    Log.LogInfo("[InstrumentDeamon][PRM] func=setMeasureCurrentScope, return=" .. tostring(retVal))
    return retVal
end

-- measure current
-- @param netName: string type
-- @param scope: string type
-- @return string result
function instrumentDeamon.measureCurrent(netName, scope)
    local _ = netName and string.upper(netName) or nil
    scope = string.match(scope, "([%d\\.]+)([%S]+)")
    scope = scope and tonumber(scope) or 1000
    local sample_rate = 100
    local retVal = instrumentDeamon.callRPCFunc("mixdevice.measureCurrentOdin", timeout, "battery", sample_rate, scope)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureCurrent, return=" .. tostring(retVal))
    return retVal
end

-- measure resistor
-- @param netName: string type
-- @return string result
function instrumentDeamon.measureResistor(netName)
    assert(netName ~= nil, "measureResistor: given netName is nil")
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.measureResistor", timeout, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureResistor, return=" .. tostring(retVal))
    return retVal
end

-- reset all
-- @return boolean result
function instrumentDeamon.resetAll()
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.resetAll", timeout)
    Log.LogInfo("[InstrumentDeamon][PRM] func=resetAll, return=" .. tostring(retVal))
    return retVal
end

-- measure starlord
-- @param bandwidth: number type
-- @param scope: string type
-- @param channel: string type
-- @param decimationType: string type
-- @param samplingRate: number type
-- @return boolean result
-- @return list result, return nil if execute fail
function instrumentDeamon.measureStarlord(bandwidth, scope, channel, decimationType, samplingRate)
    local retVal = {}
    if scope == "20mV" then
        local ret = instrumentDeamon.callRPCFunc("starlord.get_noisefloor", timeout, channel, scope, bandwidth,
                                                 decimationType, samplingRate)
        retVal["rms"] = tonumber(ret)
    else
        channel = channel and string.lower(channel) or "right"
        retVal = instrumentDeamon.callRPCFunc("mixdevice.measureAudioByStarlord", timeout, channel, scope, bandwidth,
                                              decimationType, samplingRate)
        for k, v in pairs(retVal) do
            retVal[k] = tonumber(v[1])
        end
    end
    Log.LogInfo("[InstrumentDeamon][PRM] func=measureStarlord, return=" .. ComFunc.dump(retVal))
    return retVal
end

-- apply voltage
-- @param targetVoltage: number type
-- @param netName: string type
-- @param currentLimitValue: string type
-- @param sourceType: string type
-- @param step: number type
-- @return boolean result
function instrumentDeamon.applyVoltage(startVoltage, targetVoltage, netName, sourceType, currentLimitValue, step)

    startVoltage = startVoltage and startVoltage or 0
    local ret = instrumentDeamon.callRPCFunc("mixdevice.applyVoltage", timeout, startVoltage, targetVoltage, sourceType,
                                             currentLimitValue, step, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=applyVoltage, return=" .. tostring(ret))

    local retVal
    if type(ret) == "table" then
        if #ret == 2 then
            if ret[1] == true then
                retVal = true
            else
                retVal = false
            end
        else
            retVal = true
        end
    elseif type(ret) == "boolean" then
        if ret == true then
            retVal = true
        else
            retVal = false
        end
    else
        retVal = false
    end

    return retVal
end

-- revoke Voltage
-- @param netName: string type
-- @param sourceType: string type
-- @return boolean result
function instrumentDeamon.revokeVoltage(netName, sourceType)
    local retVal
    local bRet = instrumentDeamon.callRPCFunc("mixdevice.revokeVoltageByOdin", timeout, sourceType, netName)
    if bRet then
        local highLimit = 10
        local lowLimit = -10
        bRet, retVal = instrumentDeamon.waitVoltageStable(sourceType, highLimit, lowLimit)
        if bRet == false then
            error("Odin output abnormal!")
        end
        Log.LogInfo("[InstrumentDeamon][PRM] func=revokeVoltage, return=" .. tostring(retVal))
        return retVal
    end
end

-- measure resistor
-- @param sourceType: string type, "BATTERY"|"CHARGE"
-- @param highLimit: number type
-- @param lowLimit: number type
-- @return boolean result
function instrumentDeamon.waitVoltageStable(sourceType, highLimit, lowLimit)
    assert(sourceType ~= nil, "waitVoltageStable: given sourceType is nil")
    sourceType = string.upper(sourceType)
    -- wait 10ms before read back voltage
    Time.__delay(10)
    local voltage = instrumentDeamon.callRPCFunc("mixdevice.measureVoltageByOdin", timeout, sourceType, 1000)
    Log.LogInfo("waitVoltageStable: sourceType=" .. tostring(sourceType) .. ", voltage=" .. tostring(voltage) ..
                    ", highLimit=" .. tostring(highLimit) .. ", lowLimit=" .. tostring(lowLimit))
    if voltage and highLimit and lowLimit then
        if lowLimit <= voltage and voltage <= highLimit then
            return true, voltage
        end
    elseif voltage and not highLimit and lowLimit then
        if voltage >= lowLimit then
            return true, voltage
        end
    elseif voltage and not lowLimit and highLimit then
        if voltage <= highLimit then
            return true, voltage
        end
    else
        return false, voltage
    end
    return false, voltage
end

-- check diode
-- @param CCS: string type
-- @param netName: string type
-- @param delay: number type
-- @return list result
function instrumentDeamon.checkDiode(CCS, netName, delay, DACMode, DACModeOff)
    CCS = CCS and CCS or "0.1MA"
    local val = string.match(CCS, "([%d\\.]+)([%S]+)")
    CCS = tonumber(val)
    delay = tonumber(delay)
    assert(0 <= CCS and CCS <= 1, "checkDiode: target voltage out of range [0, 1] mA")
    -- gain = 2500 for DAC output
    local DACVoltage = CCS * 2500
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.checkDiode", timeout, netName, DACVoltage, delay, DACMode,
                                                DACModeOff)
    Log.LogInfo("[InstrumentDeamon][PRM] func=checkDiode, return=" .. tostring(retVal))
    return math.abs(retVal[2])
end

-- check open short
-- @param netName: string type
-- @param sourceType: string type
-- @return number result
function instrumentDeamon.checkOpenShort(netName, sourceType)
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.checkOpenShort", timeout, sourceType, netName)
    Log.LogInfo("[InstrumentDeamon][PRM] func=checkOpenShort, return=" .. tostring(retVal))
    return retVal
end

-- check leakage
-- @param netName: string type
-- @param delay: number type
-- @return list result
function instrumentDeamon.checkLeakage(netName, CVS, delay, DACMode, DACModeOff)
    delay = delay and delay or 100
    CVS = CVS and CVS or 200
    local retVal = instrumentDeamon.callRPCFunc("mixspecific.checkLeakage", timeout, netName, CVS, delay, DACMode,
                                                DACModeOff)
    Log.LogInfo("[InstrumentDeamon][PRM] func=checkLeakage, return=" .. tostring(retVal))
    return retVal[1]
end

-- @Description: write laguna reg
-- @param address: string type
-- @param vaule: number type
-- @return boolean result
function instrumentDeamon.writeLagunaReg(address, value)
    return instrumentDeamon.callRPCFunc("laguna.write", timeout, tonumber(address), tonumber(value))
end

-- @Description: set delimiter with setDelimiter()
-- @param command: string type
-- @return boolean result
function instrumentDeamon.setDelimiter(delimiter)
    return instrumentDeamon.callRPCFunc("rpcuart.setDelimiter", timeout, delimiter)
end

-- @Description: send DUT command and read DUT response with Uart.send then get the return value by expectedKeyWord
-- @param command: string type
-- @param timeout: number type
-- @param byByte: boolean type
-- @param binFormat: boolean type
-- @param retry: int type retry times
-- @return string result
function instrumentDeamon.sendReadWithRetry(command, rpcuarttimeout, byByte, binFormat, retry)
    return instrumentDeamon.callRPCFunc("rpcuart.sendReadWithRetry", timeout, command, rpcuarttimeout, byByte,
                                        binFormat, retry)
end

-- @Description: send DUT command and read DUT response with Uart.send then get the return value by expectedKeyWord
-- @param command: string type
-- @param timeout: number type
-- @param byByte: boolean type
-- @param binFormat: boolean type
-- @return string result
function instrumentDeamon.sendRead(command, rpcuarttimeout, byByte, binFormat)
    return instrumentDeamon.callRPCFunc("rpcuart.sendRead", timeout, command, rpcuarttimeout, byByte, binFormat)
end

-- @Description: send DUT command with Uart.write by byte
-- @param command: string type
-- @param n: int type
-- @param delay: float type
-- @return boolean result
function instrumentDeamon.sendCmdByBytes(command, n, delay)
    return instrumentDeamon.callRPCFunc("rpcuart.sendCmdByBytes", timeout, command, n, delay)
end

-- @Description: send DUT command with Uart.write
-- @param command: string type
-- @return boolean result
function instrumentDeamon.sendCmd(command)
    return instrumentDeamon.callRPCFunc("rpcuart.sendCmd", timeout, command)
end

-- @Description: read DUT response by Uart.read and return the string by expectedKeyWord
-- @param timeout: number type
-- @param binFormat: boolean type
-- @return string result
function instrumentDeamon.readResponse(rpcuarttimeout, binFormat)
    return instrumentDeamon.callRPCFunc("rpcuart.readResponse", timeout, rpcuarttimeout, binFormat)
end

-- @Description: read DUT response by Uart.read
-- @param timeout: number type
-- @return string result
function instrumentDeamon.readDump(rpcuarttimeout)
    return instrumentDeamon.callRPCFunc("rpcuart.readDump", timeout, rpcuarttimeout)
end

-- @Description: read DUT response by Uart.read and return the string by expectedKeyWord
-- @param timeout: number type
-- @param binFormat: boolean type
-- @return string result
function instrumentDeamon.readUntil(delimiter, rpcuarttimeout, decode)
    return instrumentDeamon.callRPCFunc("rpcuart.readUntil", timeout, delimiter, rpcuarttimeout, decode)

end
-- @Description: send DUT command from txt file, and read DUT response with Uart.send then get the return value
-- @param file: string type
-- @return string result
function instrumentDeamon.readRunSequence(file)
    return instrumentDeamon.callRPCFunc("rpcuart.readRunSequence", timeout, file)
end

-- @Description: speaker enable
-- @param speakerType: string type, speaker type
-- @param freq: number type, frequency
-- @param sweepVolt: string type, sweep voltage
-- @param resistor: number type, resistor
-- @return string type, enable status
function instrumentDeamon.enableSpeaker(speakerType, freq, sweepVolt, resistor)
    local function checkStatus()
        local status = variablePlugin.getVar("SpeakerStatus")
        local resp

        if status ~= "enable" then
            variablePlugin.setVar("SpeakerStatus", "enable")
            resp = instrumentDeamon.callSPKRPCFunc("mixspecific.speakerEnable", timeout, speakerType, freq, sweepVolt,
                                                   resistor)
        else
            resp = "speaker already enable"
        end

        return resp
    end

    local id = "check-speaker-status"
    local retVal = mutex.runWithLock(mutexPlugin, id, checkStatus)
    Log.LogInfo("[InstrumentDeamon][PRM] func=speakerEnable, return=" .. tostring(retVal))

    return retVal
end

-- @Description: speaker disable
-- @return string type, disable status
function instrumentDeamon.disableSpeaker()
    local function checkStatus()
        local status = variablePlugin.getVar("SpeakerStatus")
        local resp

        if status ~= "disable" then
            resp = instrumentDeamon.callSPKRPCFunc("mixspecific.speakerDisable", timeout)
            variablePlugin.setVar("SpeakerStatus", "disable")
        else
            resp = "speaker already disable"
        end

        return resp
    end

    local id = "check-speaker-status"
    local retVal = mutex.runWithLock(mutexPlugin, id, checkStatus)
    Log.LogInfo("[InstrumentDeamon][PRM] func=speakerDisable, return=" .. tostring(retVal))

    return retVal
end

return instrumentDeamon
