--Version1.5.1
local Plugins = {}
local Log = require("Matchbox/logging")
-- uncomment the line below to enable loop per detection.
local json = require("Matchbox/json")
local comFunc = require("Matchbox/CommonFunc")
local file = require("Tech/DealWithFile")
local plist2lua = require("Matchbox/plist2lua")
local jsonfile = file.getConfigJson()
local configInfo = json.decode(comFunc.fileRead(jsonfile))
local loops_number = configInfo.info.Loops
Plugins.loops_per_detection = tonumber(loops_number)
IS_FAKE_TEST= false
-- To enable automation, Plugins.readyForAutomatedHandling must be assigned a user-implemented callback that takes
-- groupPluginTable as an argument.
--
-- The purpose of this callback is to determine if the fixture is in a safe position for automated DUT
-- handling (ex. robot arm can safely insert/remove DUT from fixture).
--
-- If the fixture is in a safe position for automated DUT handling, call automationPlugin.confirmReadyForAutomatedHandling()
--
-- If you wish, you can add retry mechanisms inside this callback by using a while loop and re-attempting
-- to move the fixture into a safe position until it is finally successful, at which point the function should return true.
--
-- Note that Matchbox is only compatible with AtlasAutomationBridge v2.1.0.2 and newer
-- Plugins.readyForAutomatedHandling = (function(groupPluginTable, automationPlugin)
    -- if fixture is in safe position, call API below
    -- automationPlugin.confirmReadyForAutomatedHandling(Group.index)
-- end)
-- functions to create and initialize plugin instances dedicated for each unit
-- groupPlugins can be used for fixture related initialization
-- function Plugins.initMix(...)
--     local jsonfile = file.getConfigJson()
--     local configInfo = json.decode(comFunc.fileRead(jsonfile))
--     local IPInfo = configInfo.info.IPInfo
--     local IPAddress = IPInfo.IPAddress
--     local IPport = tonumber(IPInfo.Port)
--     local MixRPC = Atlas.loadPlugin("MIXRPCClientPlugin")
--     Log.LogInfo('MixRPC:',table.unpack(MixRPC))
--     Log.LogInfo('IPAddress:',IPAddress)
--     Log.LogInfo('IPport:',IPport)
--     MixRPC.init(IPAddress,IPport)
--     return MixRPC
--     end
function Plugins.loadPlugins(deviceName, groupPlugins)
    local fixtureUrl = configInfo.info.FixturePort
    local barcodeUrl = configInfo.info.BarcodePort
    local thermometerUrl = configInfo.info.ThermometerPort
    print(string.format('fixtureUrl:%s\nbarcodeUrl:%s\nthermometerUrl:%s',fixtureUrl,barcodeUrl,thermometerUrl))
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local transport = Group.getDeviceTransport(deviceName)
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    CommBuilder.setLogFilePath(workingDirectory .. "/EFIDut.log", workingDirectory .. "/rawDut.log")
    --local dut = CommBuilder.createEFIPlugin(Group.getDeviceTransport(deviceName))
    Log.LogInfo('transport:'..transport)

    local dut = CommBuilder.createCommPlugin(transport)
    local fixture = CommBuilder.createCommPlugin(fixtureUrl)
    local barcode = CommBuilder.createCommPlugin(barcodeUrl)
    local thermometer = CommBuilder.createCommPlugin(thermometerUrl)
    
    local Conversion = Atlas.loadPlugin("Conversion")
    local Convert = Atlas.loadPlugin("Convert")
    local OCRegex = Atlas.loadPlugin("OCRegex")
    local MixRPC0 = Atlas.loadPlugin("MIXRPCClientPluginGTS")
    local MixRPC1 = Atlas.loadPlugin("MIXRPCClientPluginGTS")
    local MixRPC2 = Atlas.loadPlugin("MIXRPCClientPluginGTS")
    local MixRPC3 = Atlas.loadPlugin("MIXRPCClientPluginGTS")
    local SFC = Atlas.loadPlugin("SFC")
    local TestPlugin = Atlas.loadPlugin("Test")
    -- local SFC = Atlas.loadPlugin("Record")
    -- local MixRPC = Plugins.initMix()
    -- you can define those in external file
    return {
        SFC = SFC,
        MESRecord = MESRecord,
        Conversion = Conversion,
        dut = dut,
        fixture = fixture,
        barcode = barcode,
        thermometer = thermometer,
        Convert = Convert,
        OCRegex = OCRegex,
        EFIDut = Atlas.loadPlugin("dummyEFIDut"),
        MixRPC0 = MixRPC0,
        MixRPC1 = MixRPC1,
        MixRPC2 = MixRPC2,
        MixRPC3 = MixRPC3,
        TestPlugin = TestPlugin
    }
end

--for debug which is use tcp servie code by python3, lani--
-- function Plugins.loadPluginsFake(deviceName, groupPlugins)
--     Log.LogInfo("==》 程序启动，加载插件,for fake...")
--     local CommBuilder = Atlas.loadPlugin("CommBuilder")
--     local workingDirectory = Group.getDeviceUserDirectory(deviceName)
--     CommBuilder.setLogFilePath(workingDirectory .. "/EFIDut.log", workingDirectory .. "/rawDut.log")
--     CommBuilder.setLineTerminator("\r\n")
--     -- tcp 通信， 使用soc站tcp服务模拟通信，需要在SZ_Gerrit服务上启动模拟器
--     local MCU1 = CommBuilder.createCommPlugin("tcp://127.0.0.1:8501")
--     local MCU2 = CommBuilder.createCommPlugin("tcp://127.0.0.1:8500")
--     MCU1.open()
--     MCU1.write("CONNECT TEST")
--     status, cmdReturn = pcall(MCU1.read)
--     Log.LogInfo("==》TCP服务启动，并检查通信 ， cmdReturn"..cmdReturn)
--     MCU1.close()
--     local transport = Group.getDeviceTransport(deviceName)
--     Log.LogInfo('transport:'..transport)
--     local SFC = Atlas.loadPlugin("SFC")
--     local MixRPC = Atlas.loadPlugin("MIXRPCClientPlugin")
--     return {
--         SFC = SFC,
--         MCU1 = MCU1,
--         MCU2 = MCU2,
--         MixRPC = MixRPC
--     }
-- end
-- uncomment this function to customize unit detection and test start.
--[[
-- allow users to control which slots to run.
-- @param groupPlugins: group plugins {name:instance}
-- return: slot names to test in a table
-- use cases:
--     1. retest selected slots of a panel
--     2. call fixture plugin to determine whether duts are ready to test
--     3. wait for start button action before start testing
--     4. popup ui for sn scan before fixture engage
function Plugins.getSlots(groupPlugins)
    -- add code here to wait for start button before testing.

    -- pseudo code for calling fixture plugin
    -- fixture = groupPlugins.fixture
    -- fixture.isReady()   -- block wait until duts are ready to test

    -- demo code to not test slot1
    local slotsToStart = {}
    local allSlots = Group.getSlots()
    for _, slot in ipairs(allSlots) do
        if slot ~= 'slot1' then table.insert(slotsToStart, slot) end
    end
    return slotsToStart
end
--]]
function fileExists(filename)
    local file = io.open(filename, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end
function openPort(portName)
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    local logFilePath = "/Users/"..userName.."/Documents/fixtureUrl.log"
    local logFilePathRaw = "/Users/"..userName.."/Documents/fixtureUrlraw.log"
    local lineTerminator = "\r\n"
    local delimiter = ""
    local timeout = 5
    local serialPortUrl = configInfo.info[portName]
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    CommBuilder.setLogFilePath(logFilePath,logFilePathRaw)
    local serialPort = CommBuilder.createCommPlugin(serialPortUrl)
    Log.LogInfo('serialPort:',serialPort)
    Log.LogInfo('serialPort.isOpened():',serialPort.isOpened())
    if serialPort.isOpened() == 0 then
        serialPort.open(timeout)
    elseif serialPort.isOpened() == 1 then
        Log.LogInfo('Open serial port successfully')
    else
        error('error in open serialPort progress')
    end
    serialPort.setDelimiter(delimiter)
    serialPort.setLineTerminator(lineTerminator)

    return serialPort
    -- local serialPort = Device.getPlugin(portName)
end

function sendCommand(portName,command,regex)
    local serialPort = openPort(portName)
    local response = serialPort.send(command,timeout)
    if string.match(response, regex) then
        serialPort.close()
        return true 
    end
    return false
end

function readCommand(portName,regex)
    local timeout = 1
    local serialPort = openPort(portName)
    while true do
        local readResult = serialPort.read(timeout,'\n')
        Log.LogInfo("readResult:",readResult)
        local regexResult = string.match(readResult, regex)
        Log.LogInfo("regexResult:",regexResult)
        if regexResult then
            serialPort.close()
            return regexResult
        end
        io.popen('sleep 0.1')
    end
    return false

end
--example
--readCommand('FixturePort','')



function Plugins.getSlots(groupPlugins)
    os.execute("sleep 0.3")
    local groupIndex = Group.index
    print('groupIndex:',groupIndex)
    local slotsToStart = {}
    local allSlots = Group.getSlots()
    local dir = {}
    local dir = json.decode(comFunc.fileRead("/System/Volumes/Data/vault/statistics/Count.json"))
    Log.LogInfo("dir 0803843048",dir)
    Group.updateInfo(dir)
    local popup = groupPlugins["Popup"]
    local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
    if comFunc.fileExists(configPath .. "/station.plist") then
        local stationConfig = plist2lua.read(configPath .. "/station.plist")
        Log.LogInfo('stationConfig.GroupConfig',stationConfig.GroupConfig)
        group_num = tonumber(stationConfig.GroupConfig.Instances)
        slot_num = #stationConfig.GroupConfig.SlotConfig
        print(string.format('Plugins.getSlots group_num:%d--slot_num:%d',group_num,slot_num))
    else
        error("*****Plugins.getSlots The staition.plist file not found***")
    end
    -- for _, slot in ipairs(allSlots) do
    --     if slot ~= 'slot1' then table.insert(slotsToStart, slot) end
    -- end

    for _, slot in ipairs(allSlots) do
        local slot_number = string.match(slot, '.-(%d+)')
        local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
        print('Group index ==,',groupIndex)
        print('Slot index ==,',slot_number)
        print('checkBoxState',checkBoxState)
        if checkBoxState == '1' then 
            table.insert(slotsToStart, slot)
        end
    end
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    local filePath = "/Users/"..userName.."/Documents/group"..groupIndex..".txt"


    local fixture_command_table = {}
    fixture_command_table['1'] = ''
    fixture_command_table['2'] = ''
    fixture_command_table['3'] = ''
    fixture_command_table['4'] = ''
    -- local fixture_detect = true
    -- if fixture_detect then
    --     if tonumber(groupIndex) == group_num then
    --         for i=1,group_num do
    --             local filePath = "/Users/"..userName.."/Documents/group"..i..".txt"
    --             os.execute('rm -f '..filePath)
    --             if fileExists(filePath) then
    --                 error("*****processGroupTxt delete the filePath error",filePath)
    --             else
    --                 print("*****processGroupTxt delete group txt success***")
    --             end

    --         end
    --     end
    -- end
    if tonumber(groupIndex) == 1 then
         -- detecting fixture button 
        local fixture_detect = true
        
        if not fileExists(filePath) and fixture_detect then
            -- local command = fixture_command_table[groupIndex]
            --added fixture command of move handle
            --added scan sn action to here
            -- sn = readCommand()

            Log.LogInfo('kkk000slotsToStart:',slotsToStart)
            Log.LogInfo('kkk000#slotsToStart:',#slotsToStart)
            if #slotsToStart ~=0 then 
                return slotsToStart
            else
                print('kkk000')
                os.execute('echo Testing'..' > '..filePath)
            end
        end
    else
        local lastGroupIndex = groupIndex-1
        local lastFilePath = "/Users/"..userName.."/Documents/group"..lastGroupIndex..".txt"
        if fileExists(lastFilePath) and not fileExists(filePath)then
            -- local command = fixture_command_table[groupIndex]

            --added fixture command of move handle
            Log.LogInfo('kkk111slotsToStart:',slotsToStart)
            Log.LogInfo('kkk111#slotsToStart:',#slotsToStart)
            if #slotsToStart ~=0 then
                return slotsToStart
            else
                os.execute('echo Testing'..' > '..filePath)
                if tonumber(groupIndex) == group_num then
                    for i=1,group_num do
                        local filePath = "/Users/"..userName.."/Documents/group"..i..".txt"
                        os.execute('rm -f '..filePath)
                        if fileExists(filePath) then
                            error("*****processGroupTxt delete the filePath error",filePath)
                        else
                            print("*****processGroupTxt delete group txt success***")
                        end

                    end
                end
            end
        end
    end

end

-- function Plugins.getSlots(groupPlugins)
--     --get station name from station.plist
--     local stationName = nil
--     local configPath = string.gsub(Atlas.assetsPath,"Assets","Config")
--     if comFunc.fileExists(configPath .. "/station.plist") then
--         local stationConfig = plist2lua.read(configPath .. "/station.plist")
--         stationName = stationConfig.StationName
--         print('****Station Name***',stationName)
--     else
--         error("*****The staition.plist file not found***")
--     end
--     Log.LogInfo("⛰⛰⛰⛰⛰getSlots⛰⛰⛰⛰⛰")
--     local popup = groupPlugins["Popup"]
--     popup.reset()
--     local indexGroup = Group.index
--     Log.LogInfo("Group.index:",Group.index)
--       --lanuch on start scan SN mode,don't forget to replace Popup.bundle
--     if stationName == nil then
--         local stationInfo = Atlas.loadPlugin("StationInfo")
--         local stationId = stationInfo.station_id()
--         stationName = string.match(stationId,".*%_(.*)")
--         print('**** stationName***', stationName)
--     end  
--     if string.find(stationName,"SA%-") or string.find(stationName,"OQC") then
--         while true do
--             local result = popup.getField()
--             local sn = popup.getFieldSN()
--             Log.LogInfo("Execute OC getField function result:",result)
--             Log.LogInfo("Execute OC getFieldSN function to get the SN is:",sn)
--             if result == tostring(indexGroup) then
--                 Log.LogInfo("start test ",result)
--                 break
--             end
--             os.execute('sleep 1')
--         end
--     else
--         --lanuch on start buntton mode, don't forget to replace Popup.bundle
--         while true do
--             local result = popup.queryStart()
--             if result==1 then
--                 break    --Start被点击了
--             end
--             Log.LogInfo("⛰⛰⛰⛰⛰sleep 1 sec⛰⛰⛰⛰⛰")
--             os.execute('sleep 1')
--         end
--     end
--         return  Group.getSlots()
-- end

function Plugins.shutdownPlugins(devicePlugins)

end

function Plugins.loadGroupPlugins(resources)
    Log.LogInfo("--------loading group plugins-------")
    return {Popup=Remote.loadRemotePlugin(resources["Popup"])}
end

function Plugins.shutdownGroupPlugins(groupPlugins)
    Log.LogInfo("--------loading group plugins-------",groupPlugins)



end

-- uncomment the function below to define customize group exit function
--[[
-- group exit function runs at end of each test cycle
-- if return true, Matchbox will exit from current group script after teardown group plugins,
-- and Atlas2 will start group script again.
-- if return false, Matchbox will loop inside current group script to next device detection,
-- reusing existing group plugin.
-- @param groupPlugins: group plugin table, key: name, value: plugin instance
-- @return: bool, true if station want to exit current group script, false if not
function Plugins.groupShouldExit(groupPlugins)
    print('exiting current group script')
    return true
end
--]]

--[[
-- group start; run before each test cycle
-- @param groupPlugins: group plugin table
-- @return: no return
function Plugins.groupStart(groupPlugins)
    print('group starting')
    local mix = require("Tech/Mix")
    local DMM = require("Tech/DMM")

end
--]]

--[[
-- group stop; run after each test cycle when all slots finish testing
-- @param groupPlugins: group plugin table
-- @return: no return
function Plugins.groupStop(groupPlugins)
    print('group stopped')
end
--]]

return Plugins
