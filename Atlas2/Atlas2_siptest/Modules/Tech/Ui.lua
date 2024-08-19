local Ui = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
local String = require("Tech/String")
function Ui.reset(paraTab)
    local groupIndex = string.match(workingDirectory, "group(%d+)")
    local popup = Device.getPlugin("Popup")
    -- sn = popup.scan("1",tips,"OK","SN")
    popup.reset(tostring(groupIndex))

end
function Ui.alert(paraTab)
    Log.LogInfo('paraTab...',paraTab)
    local str = paraTab.AdditionalParameters["Tips"]
    local buttonName = paraTab.AdditionalParameters["ButtonName"] or 'OK'
    local popup = Device.getPlugin("Popup")
    -- popup.reset()
    local useAlert = popup.alert(tostring(str),buttonName)
    while true 
        do
            os.execute("sleep 0.5")
            local alertStatus = popup.queryAlert()
            if alertStatus == 0 then
                break
            end
    end
end

function Ui.scanSN(paraTab)
    local tips = paraTab.AdditionalParameters["Tips"]
    local popup = Device.getPlugin("Popup")
    sn = popup.scan("1",tips,"OK","SN")
    print("*******SN",sn)
    if sn ~= nil then
        return sn
    end
end

function Ui.getSN(paraTab)
    local workingDirectory = Device.userDirectory
    local groupIndex = string.match(workingDirectory, "group(%d+)")
    local popup = Device.getPlugin("Popup")
    sn = popup.getSNs(tostring(groupIndex))
    Log.LogInfo("--sn is--:",sn)
    if #sn ~= 12 and #sn ~= 17 and #sn ~= 18 and #sn ~= 10 then
       -- error('SN is not a legal string!') 
       return false
    end
    return sn
end
function Ui.getWO(paraTab)
    local popup = Device.getPlugin("Popup")
    local wo = popup.getWO()
    Log.LogInfo("WO is:",wo)
    if #wo == 0 then
       return false
    end
    return wo
end
function Ui.getOPID(paraTab)
    local popup = Device.getPlugin("Popup")
    local opID = popup.getOP()
    Log.LogInfo("opID is:",opID)
    if #opID == 0 then
       return false
    end
    return opID
end

function Ui.getID(paraTab)
    local workingDirectory = Device.userDirectory
    local groupIndex = string.match(workingDirectory, "group(%d+)")
    local popup = Device.getPlugin("Popup")
    sn = popup.getSNs(groupIndex)
    Log.LogInfo("****ID is",sn)
    if #sn == 0 or sn == nil then
       -- error('SN is not a legal string!') 
       return false
    end
    return sn
end

function Ui.askAlert(paraTab)
    print('enter askAlert function')
    local tips = paraTab.AdditionalParameters["Tips"] or 'Tips'
    local buttonFalse = paraTab.AdditionalParameters["ButtonN"] or 'NO'
    local buttonTrue = paraTab.AdditionalParameters["ButtonY"] or 'Yes'
    local popup = Device.getPlugin('Popup')
    -- popup.reset()
    local askInfo = popup.showAlert(tips,buttonTrue,buttonFalse)
    while true
        do
            os.execute("sleep 0.5")
            local click = popup.isTip()
            if tostring(click) == "1" then
                result = true
                break
            elseif (tostring(click) == "0") then
                result = false
                break
            end
        end
    return result
   end
function Ui.selectBox(paraTab)
    print('Enter selectBox function')
    local tips = paraTab.AdditionalParameters["Tips"] or 'Tips'
    local noiseLevelA = paraTab.AdditionalParameters["NoiseLevelA"] or 'Pass'
    local noiseLevelB = paraTab.AdditionalParameters["NoiseLevelB"] or '轻度噪声'
    local noiseLevelC = paraTab.AdditionalParameters["NoiseLevelC"] or '中度噪声'
    local noiseLevelD = paraTab.AdditionalParameters["NoiseLevelD"] or '重度噪声'
    local popup = Device.getPlugin("Popup")
    local selectBoxPopup = popup.selectBox(tips,noiseLevelA,noiseLevelB,noiseLevelC,noiseLevelD)
    while true
        do
            click = popup.selectResult()
            if tostring(click) == "0" then
                return 0
            elseif tostring(click) == "1" then
                return 1  
            elseif tostring(click) == "2" then
                return 2
            elseif tostring(click) == "3" then
                return 3
            end
        end
    end

return Ui


