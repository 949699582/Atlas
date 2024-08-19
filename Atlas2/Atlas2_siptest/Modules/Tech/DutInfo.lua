local DutInfo = {}
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require 'Matchbox/json'
local dealWithFile = require 'Tech/DealWithFile'
local String = require 'Tech/String'
local _Utility = require("InnerFunctions/_Utility")



function DutInfo.zhqCalVbatt(paraTab)
    local inputVar = paraTab.Input
    print("run zhqCalVbatt ====",inputVar)

    local result = 0
    if inputVar ~= nil and #inputVar ~= 0 then
        result = tonumber(inputVar) / 1000
        return result
    end
   
    return false
end


function DutInfo.zhqCalLenth(paraTab)
    local inputVar = paraTab.Input
    print("run zhqCalLenth ====",inputVar)

    local result = 0
    if inputVar ~= nil and #inputVar ~= 0 then
        result = #inputVar
        return result
    end
   
    return false
end

function DutInfo.zhqCalkadabra(paraTab)
    
    local retVal = paraTab.Input

    print("run zhqCalkadabra ====",inputVar)

    local LIGHT_25_MEAN, DARK_25_MEAN, LIGHT_25_STD, DARK_25_STD, LD_25_MEAN,LD_25_STD, KADABRA_TEMP_MEAN
    local TS0Light1Tab ={}
    local TS0Dark1Tab ={}
    local tmpTab = {}
    local LDTab = {}
    local iedSplitTab
    local iedDataTab
    local opticalSensorTab = {}

    local function _calSTDForOIED(t)
        local m
        local vm
        local sum = 0
        local count = 0
        local result
        m = _Utility._calAvg(t)
        for _,v in pairs(t) do
            if tonumber(v) ~= nil then
                vm = v - m
                sum = sum + (vm*vm)
                count = count + 1
            end
        end
        result = math.sqrt(sum / (count-1))
        return result
    end
    

    iedData = string.match(retVal, "nA\n(.*)")
    iedDataTab = comFunc.splitString(iedData,"\n")
    
    for i=1,32 do
      iedSplitTab = comFunc.splitString(iedDataTab[i],"|")
      table.insert(TS0Light1Tab,iedSplitTab[5])
      table.insert(TS0Dark1Tab,iedSplitTab[6])
      table.insert(LDTab,iedSplitTab[13])
      table.insert(tmpTab,iedSplitTab[3])
    end

    LIGHT_25_MEAN = _Utility._calAvg(TS0Light1Tab)
    DARK_25_MEAN = _Utility._calAvg(TS0Dark1Tab)
    LIGHT_25_STD = _calSTDForOIED(TS0Light1Tab)
    DARK_25_STD = _calSTDForOIED(TS0Dark1Tab)
    LD_25_MEAN =  _Utility._calAvg(LDTab)
    LD_25_STD = _calSTDForOIED(LDTab)
    KADABRA_TEMP_MEAN = _Utility._calAvg(tmpTab)
    opticalSensorTab["LIGHT_25_MEAN"] = LIGHT_25_MEAN * 1.5006
    opticalSensorTab["DARK_25_MEAN"] = DARK_25_MEAN * 1.5006
    opticalSensorTab["LIGHT_25_STD"] = LIGHT_25_STD * 1.5006
    opticalSensorTab["DARK_25_STD"] = DARK_25_STD * 1.5006
    opticalSensorTab["LD_25_MEAN"] = LD_25_MEAN
    opticalSensorTab["LD_25_STD"] = LD_25_STD
    opticalSensorTab["KADABRA_TEMP_MEAN"] = KADABRA_TEMP_MEAN - 87

    print("opticalSensorTab =====",opticalSensorTab['LIGHT_25_MEAN'])
    if opticalSensorTab ~= nil and opticalSensorTab ~= {} then
        return opticalSensorTab
    end
    
    return false

end


function DutInfo.getValueForKey(paraTab)
    local keyName = paraTab.AdditionalParameters["keyName"]
    local inputTable = paraTab.Input
    Log.LogInfo("result ===000000",keyName)

    if inputTable == {} or inputTable == nil then 
        print("inputTable === kong")
        return false
    end

    local result = inputTable[keyName]
    Log.LogInfo("result ===",result)

    if result == nil then 
        return false
    end

    return result
end

function DutInfo.kadabraPdvf(paraTab)
    local opticalSensorPdvfTab = {}
    
    local retVal = paraTab.Input

    iedPdvfData = string.match(retVal, "nA\n(.*)")
    iedSplitTab = comFunc.splitString(iedPdvfData,"|")
    kadabraPdvfMean = (iedSplitTab[7]) * (1.4/8192)

    opticalSensorPdvfTab["PD_VF"] = kadabraPdvfMean
    return opticalSensorPdvfTab
end


function DutInfo.kadabraVcselTest(paraTab)
    print("start kadabraVcselTest ===")
    local failureMsg, iedDataTs0Light, TS0_LIGHT_MEAN, VCSEL_VF
    local TS0LightTab ={}
    local iedSplitTab
    local iedDataTs0LightTab
    local opticalSensorVscelTab = {}
    
    local retVal = paraTab.Input
    if retVal == nil then 
        return false
    end

    print("=============0",retVal)
 
    iedDataTs0Light = string.match(retVal, "nA\n(.*)")
    iedDataTs0LightTab = comFunc.splitString(iedDataTs0Light,"\n")
    for i=1,10 do
      iedSplitTab = comFunc.splitString(iedDataTs0LightTab[i],"|")
      table.insert(TS0LightTab,iedSplitTab[5])
    end

    print("=============1")

    TS0_LIGHT_MEAN = _Utility._calAvg(TS0LightTab)
    print("=============2")


    VCSEL_VF = 3 - TS0_LIGHT_MEAN * 0.000256
    opticalSensorVscelTab["VCSEL_VF"] = VCSEL_VF

    if opticalSensorVscelTab == nil then 
        return false 
    end


    return opticalSensorVscelTab
end

function DutInfo.checkDumpData(paraTab)
    print("start checkDumpData ===")

    local retVal = paraTab.Input

    

    if retVal == nil or string.find(retVal,"fail") then 
        return false
    end

    audioDumpRawData = string.match(retVal, "begin sending %d- samples\n(.*)\n> audio:ok done")
    print("==========000",audioDumpRawData)
    audioDumpRawData_Tab = comFunc.splitString(audioDumpRawData, ":")
    print("==========111",audioDumpRawData_Tab)
    print("111111 ====",string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab - 2], "\n", ""))
    print("222222 ====",string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab], "\n", ""))
    print("333333 ====",string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab - 1], "\n", ""))
    if string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab - 2], "\n", "") ==
        string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab], "\n", "") or
        string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab - 2], "\n", "") ==
        string.gsub(audioDumpRawData_Tab[#audioDumpRawData_Tab - 1], "\n", "") then
        print("==========222")
            return false
    end

    print("==========333")

    return true

end

return DutInfo