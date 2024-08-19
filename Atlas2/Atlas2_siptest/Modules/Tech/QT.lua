local QT = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local file = require("Tech/DealWithFile")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
local plist2lua = require("Matchbox/plist2lua")
local String = require("Tech/String")
function QT.splitConfigInter(paraTab)
    local config = paraTab.Input or ''
    local key = paraTab.varSubAP()['Key']
    local attrList = {}
    local splitList = String.split(config,'_')
    local BUILD_EVENT = splitList[1]
    local BUILD_MATRIX_CONFIG = splitList[2]
    local S_BUILD = config
    attrList['BUILD_EVENT'] = BUILD_EVENT
    attrList['BUILD_MATRIX_CONFIG'] = BUILD_MATRIX_CONFIG
    attrList['S_BUILD'] = S_BUILD
    if attrList[key] and attrList[key] ~= "" then
        return attrList[key]
    else
        return false
    end
end

function QT.splitConfig(paraTab)
   local result = false
    function excuteF()
        result = QT.splitConfigInter(paraTab)
    end
    function errorF(err)
        print('QsplitConfigInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function QT.getUnitnumInter(paraTab)
    local unitnum_mes = paraTab.Input or ''
    local splitList = String.split(unitnum_mes,'_')
    local UNIT_NUMBER = splitList[2]
    if UNIT_NUMBER and UNIT_NUMBER ~= "" then
        return UNIT_NUMBER
    else
        return false
    end
end

function QT.getUnitnum(paraTab)
   local result = false
    function excuteF()
        result = QT.getUnitnumInter(paraTab)
    end
    function errorF(err)
        print('GetUnitnumInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function QT.splitAudioModuleInter(paraTab)
    local audio_module = paraTab.Input or ''
    local key = paraTab.varSubAP()['Key']
    local attrList = {}
    local tw_wo_List = String.split(audio_module,'<>')
    local tw_list = String.split(tw_wo_List[1],'+')
    local wo_list = String.split(tw_wo_List[2],'+')
    attrList['TWEETER_SN'] = tw_list[1]
    attrList['TWEETER_EXT'] = tw_list[2]
    attrList['WOOFER_SN'] = wo_list[1]
    attrList['WOOFER_EXT'] = wo_list[2]
    if attrList[key] and attrList[key] ~= "" then
        return attrList[key]
    else
        return false
    end
end

function QT.splitAudioModule(paraTab)
    local result = false
    function excuteF()
        result = QT.splitAudioModuleInter(paraTab)
    end
    function errorF(err)
        print('QsplitAudioModuleInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end
-- function QT.mapColorInter(paraTab)
--     local str = paraTab.Input
--     local pattern = '.*/.*/.*/(%w+)/%w'
--     local re = string.match(str,pattern)
--     new_c = string.sub(re,-1,-1)
--     map_table = {'S','G','B'}
--     -- if str == nil then
--     --     return false
--     -- end
--     for key,value in ipairs(map_table) do
--         if value == new_c then
--             return key
--         end
--     end
--     if not key then
--         return 0

--     end

-- end
function QT.mapColorInter(paraTab)
    local sn = paraTab.Input
    if (#sn == 17) then
        eeeeCode = string.sub(sn,-6,-3)
    elseif (#sn == 18) then  
        eeeeCode = string.sub(sn,-7,-1)
    end    
    --local defaultCode = "00"
    if sn == nil then
         return false
    end
    print("eeeeCode ",eeeeCode)
   local colorTable = paraTab.AdditionalParameters["colorTable"]
    for k,v in pairs(colorTable) do
      if type(v)=="table" then
        for m,n in pairs(v) do
            if eeeeCode==n then
                return k  
            end
        end
      
      end
    end
    return false
end

function QT.mapColor(paraTab)
   local result = false
    function excuteF()
        result = QT.mapColorInter(paraTab)
    end
    function errorF(err)
        print('mapColorInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function QT.compareColorInter(paraTab)
    local result = false
    local inputs = paraTab.InputValues
    if (#inputs[1] == 17) then
        eeeeCode = string.sub(inputs[1],-6,-3)
    elseif (#inputs[1] == 18) then  
        eeeeCode = string.sub(inputs[1],-7,-1)
    end 
    if inputs[1] == nil then
         return false
    end
    local colorTable = paraTab.AdditionalParameters["colorTable"]
    for k,v in pairs(colorTable) do
      if type(v) == "table" then
        for index,config in pairs(v) do
            if eeeeCode == config then
                if '0x'..k == inputs[2] then
                    return '0x'..k
                end    
            end
        end
      end
    end
    return result
end

function QT.compareColor(paraTab)
   local result = false
    function excuteF()
        result = QT.compareColorInter(paraTab)
    end
    function errorF(err)
        print('compareColorInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function QT.getFWFromSFCInter(paraTab)
    local stage = paraTab.Input
    local phaseTable = paraTab.AdditionalParameters["fwVerTable"]
    if phaseTable[string.upper(stage)] then 
        return phaseTable[string.upper(stage)] 
    else 
        return false
    end 
end

function QT.getFWFromSFC(paraTab)
   local result = false
    function excuteF()
        result = QT.getFWFromSFCInter(paraTab)
    end
    function errorF(err)
        print('getFWFromSFC fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function QT.compareFWInter(paraTab)
    local inputs = paraTab.InputValues
    local result = false
    print('Uint FW vaule:',inputs[2])
    print('SFC FW vaule:',inputs[1])
    if tonumber(inputs[1]) == tonumber(inputs[2]) then
        result = inputs[1]
    end
    return result
end

function QT.compareFW(paraTab)
   local result = false
    function excuteF()
        result = QT.compareFWInter(paraTab)
    end
    function errorF(err)
        print('compareFW fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

return QT