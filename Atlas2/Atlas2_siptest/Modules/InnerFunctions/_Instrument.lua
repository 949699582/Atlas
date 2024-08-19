-------------------------------------------------------------------
----***************************************************************
----    _Instrument.lua provider inner instrument lua functions
----***************************************************************
-------------------------------------------------------------------
local Plist2Lua = require("Matchbox/plist2lua")

-- get vendor name from the set file
local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
local topology = Plist2Lua.read(configPath .. "/StationTopology.plist")
local vendorNameFilePath = topology["groups"][1]["VendorName"]
local readVendorFile = io.open(vendorNameFilePath, "r")
local readVendorName = readVendorFile:read("*a")
readVendorFile:close()

-- call vendor API by vendor name
local InstrumentDeamon = {}
local vendorName = string.upper(readVendorName)
if vendorName == "PRM" then
    InstrumentDeamon = require("InnerFunctions/PRM/instrumentDeamon")
elseif vendorName == "CYG" then
    InstrumentDeamon = require("InnerFunctions/CYG/instrumentDeamon")
else
    assert(false, "unknow vendor name")
end

local _Instrument = {}

-- @Description: read fixture info
-- @param keyWord: string type, "VENDOR_ID"|"FIXTURE_ID"|"MIX_FW_VERSION|GN_PORT"
-- @return string result
function _Instrument._fixtureInfo(keyWord)
    return InstrumentDeamon.fixtureInfo(keyWord)
end

-- @Description: get pcb config
-- @param value: string type
-- @return boolean result
function _Instrument._getConfigLSB(value)
    return InstrumentDeamon.getConfigLSB(value)
end

-- @Description: discharge VDD_MAIN
-- @return boolean result
function _Instrument._dischargeVDDMAIN()
    return InstrumentDeamon.dischargeVDDMAIN()
end

-- @Description: set DAC ISink current
-- @param current: string type
-- @param netName: string type
-- @param switch: string type, "CONNECT"|"DISCONNECT"
-- @return boolean result
function _Instrument._setISink(current, netName, switch)
    return InstrumentDeamon.setISink(current, netName, switch)
end

-- @Description: relay netName
-- @param netName: string type
-- @param switch: string type, "CONNECT"|"DISCONNECT"
-- @return string result
function _Instrument._relay(netName, switch)
    return InstrumentDeamon.relay(netName, switch)
end

-- @Description: open PDM
-- @param fs: number type, [0.0-0.999], the unit is mV, PDM output signal Vpp.
-- @param sampleRate: number type, [1000~125000000], the unit is Hz, IPCore sampling rate configure, default 1600000Hz.
-- @param frequency: number type, unit is Hz
-- @return boolean result
function _Instrument._openPDM(sampleRate, fs, frequency)
    return InstrumentDeamon.openPDM(sampleRate, fs, frequency)
end

-- @Description: close PDM
-- @return boolean result
function _Instrument._closePDM()
    return InstrumentDeamon.closePDM()
end

-- @Description: measure temperature
-- @return string result
function _Instrument._measureTemperature()
    return InstrumentDeamon.measureTemperature()
end

-- @Description: measure frequency
-- @param scope: string type
-- @param netName: string type
-- @return string result
function _Instrument._measureFrequency(scope, netName)
    return InstrumentDeamon.measureFrequency(scope, netName)
end

-- measure voltage by datalogger
-- @param scope: string type
-- @param duration: number type, units are seconds, about 62 data can be read in 0.1s.
-- @return list result
function _Instrument._measureVoltageByDatalogger(scope, netName, duration)
    return InstrumentDeamon.measureVoltageByDatalogger(scope, netName, duration)
end

-- @Description: measure voltage and get raw data
-- @param netName: string type
-- @param scope: string type
-- @return list result
function _Instrument._measureVoltageRawData(netName, scope, count)
    return InstrumentDeamon.measureVoltageRawData(netName, scope, count)
end

-- @Description: measure voltage with filter
-- @param netName: string type
-- @param scope: string type
-- @return string result
function _Instrument._measureVoltage(netName, scope)
    return InstrumentDeamon.measureVoltage(netName, scope)
end

-- measureVoltageContinuousSampling
-- @param netName: string type
-- @param scope: string type
-- @param sampleRate: number type
-- @param count: number type
-- @param target: result type
-- @return float result
function _Instrument._measureVoltageContinuousSampling(netName, scope, sampleRate, count, target)
    return InstrumentDeamon.measureVoltageContinuousSampling(netName, scope, sampleRate, count, target)
end

-- @Description: measure current
-- @param netName: string type
-- @param scope: string type
-- @return string result
function _Instrument._measureCurrent(netName, scope)
    return InstrumentDeamon.measureCurrent(netName, scope)
end

-- set measure current scope
-- @param scope: number type
-- @return boolean result
function _Instrument._setMeasureCurrentRange(scope)
    return InstrumentDeamon.setMeasureCurrentRange(scope)
end

-- @Description: measure resistor
-- @param netName: string type
-- @param voltScope: string type
-- @param currScope: string type
-- @return string result
function _Instrument._measureResistor(netName, voltScope, currScope)
    return InstrumentDeamon.measureResistor(netName, voltScope, currScope)
end

-- @Description: power off
-- @return boolean result
function _Instrument._powerOff()
    return InstrumentDeamon.powerOff()
end

-- @Description: reset all
-- @return boolean result
function _Instrument._resetAll()
    return InstrumentDeamon.resetAll()
end

-- @Description: measure starlord
-- @param bandwidth: number type
-- @param scope: string type
-- @param channel: string type
-- @param decimationType: string type
-- @param samplingRate: number type
-- @return boolean result
-- @return list result, return nil if execute fail
function _Instrument._measAudioWave(bandwidth, scope, channel, decimationType, samplingRate)
    return InstrumentDeamon.measAudioWave(bandwidth, scope, channel, decimationType, samplingRate)
end

-- @Description: apply voltage
-- @param targetVoltage: number type
-- @param netName: string type
-- @param currentLimitValue: number type
-- @param sourceType: string type
-- @param step: string type
-- @return boolean result
function _Instrument._applyVoltage(startVoltage, targetVoltage, netName, sourceType, currentLimitValue, step)
    return InstrumentDeamon.applyVoltage(startVoltage, targetVoltage, netName, sourceType, currentLimitValue, step)
end

-- @Description: revoke Voltage
-- @param netName: string type
-- @param sourceType: string type
-- @return boolean result
function _Instrument.revokeVoltage(netName, sourceType)
    return InstrumentDeamon.revokeVoltage(netName, sourceType)
end

-- @Description: check diode
-- @param CCS: number type
-- @param netName: string type
-- @param delay: number type
-- @return number result
function _Instrument._checkDiode(CCS, netName, delay)
    return InstrumentDeamon.checkDiode(CCS, netName, delay)
end

-- @Description: check open short
-- @param voltScope: string type
-- @param currScope: string type
-- @param netName: string type
-- @param sourceType: string type
-- @return number result
function _Instrument._checkOpenShort(voltScope, currScope, netName, sourceType)
    return InstrumentDeamon.checkOpenShort(voltScope, currScope, netName, sourceType)
end

-- @Description: check leakage
-- @param netName: string type
-- @param delay: number type
-- @return number result
function _Instrument._checkLeakage(netName, delay)
    return InstrumentDeamon.checkLeakage(netName, delay)
end

-- @Description: write laguna reg
-- @param address: string type
-- @param vaule: number type
-- @return boolean result
function _Instrument._writeLagunaReg(timeout, address, value)
    return InstrumentDeamon.writeLagunaReg(timeout, address, value)
end

-- @Description: speaker enable
-- @param speakerType: string type, speaker type
-- @param freq: number type, frequency
-- @param sweepVolt: string type, sweep voltage
-- @param resistor: number type, resistor
-- @return string type, enable status
function _Instrument._enableSpeaker(speakerType, freq, sweepVolt, resistor)
    return InstrumentDeamon.enableSpeaker(speakerType, freq, sweepVolt, resistor)
end

-- @Description: speaker disable
-- @return string type, disable status
function _Instrument._disableSpeaker()
    return InstrumentDeamon.disableSpeaker()
end

return _Instrument
