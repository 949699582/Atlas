local Test = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
local CreateRecord = require 'Tech/CreateRecord'
function Test.printInfo(paraTab)
    local workingDirectory = Device.userDirectory
    Log.LogInfo("DeworkingDirectory...",workingDirectory)
    Log.LogInfo("Device.identifier...",Device.identifier)
    Log.LogInfo("Device.systemIndex...",Device.systemIndex)
    resp = string.match(workingDirectory, "(group%d+%-slot%d+)")
    Log.LogInfo("resp is", resp)
    print("**funcation 'printInfo' is be executed! **")
    CreateRecord.createRecord(paraTab)
    return 100,200,300

end
function Test.testMutiArgs(paraTab)
    local inputs = paraTab.InputValues
    local result = true
    for key,value in ipairs(inputs) do
        result = result and value
    end
    return result
end


return Test