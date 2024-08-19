local Process = {}
local Log = require 'Matchbox/logging'
local Record = require 'Matchbox/record'

function Process.popupExample(paraTab)
	local Popup = Device.getPlugin("Popup")
	local buttonClicked = Popup.displayTextConfig("Start display test", "OK")
    Record.createBinaryRecord(true, "Display Test", "Start", "OK")

    buttonClicked = Popup.displayTextConfig("Is there any display problem?", "Yes", "No")
    local result
    if buttonClicked == 1 then
    	result = false
    elseif buttonClicked == 2 then
    	result = true
    end
    Record.createBinaryRecord(result, "Display Test")

    local textInput = Popup.barcodeScanTextConfig("Input SerialNumber", "OK")
    Record.createBinaryRecord(true, "Display Test","SerialNumber",textInput)
end

function Process.regexExample(paraTab)

    local Regex = Device.getPlugin("Regex")
    local comFunc = require("Matchbox/CommonFunc")
    local inputString = "Power=1.1W:Voltage=11.11V\nPower=2.2W:Voltage=22.22V"
    local pattern = "Power=([\\d.]+)W:Voltage=([\\d.]+)V"
    local matchesResult = Regex.matches(inputString,pattern,1)
    Log.LogInfo("matches results:")
    Log.LogInfo(comFunc.dump(matchesResult))
    if type(matchesResult) == "table" and #matchesResult > 0 then
        local testname = paraTab.Technology
        local subtestname = paraTab.TestName..paraTab.testNameSuffix
        local subsubtestname = matchesResult[1]
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    local groupsResult = Regex.groups(inputString,pattern,1)
    Log.LogInfo("groups results:")
    Log.LogInfo(comFunc.dump(groupsResult))
    if type(groupsResult) == "table" and #groupsResult[1] > 0 then
        local result = tonumber(groupsResult[1][2])
        local testname = paraTab.Technology
        local subtestname = paraTab.TestName..paraTab.testNameSuffix
        Record.createRecord(result, testname, subtestname)
    end
end

return Process
