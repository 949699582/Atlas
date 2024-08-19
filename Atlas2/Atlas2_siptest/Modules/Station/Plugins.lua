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
local stationInfoDic = {inputCount = 0, passCount = 0, failCount = 0}
Plugins.loops_per_detection = tonumber(loops_number)
IS_FAKE_TEST= false

local user = io.popen('whoami')
local userName = user:read("*all")
userName = string.gsub(userName, "%s+", "")

local function getTestResults(deviceName)
    Log.LogInfo("--------get the test results-------")
    stationInfoDic.inputCount = 0
    stationInfoDic.passCount = 0
    stationInfoDic.failCount = 0

    local unitTestResult = Group.getDeviceOverallResult(deviceName)

    if unitTestResult >= 0 then
        stationInfoDic.inputCount = stationInfoDic.inputCount + 1
        Log.LogInfo("stationInfoDic.inputCount: ", stationInfoDic.inputCount)

        if unitTestResult == Group.overallResult.pass then
            stationInfoDic.passCount = stationInfoDic.passCount + 1
            Log.LogInfo("stationInfoDic.passCount: ", stationInfoDic.passCount)
        elseif unitTestResult == Group.overallResult.fail then
            stationInfoDic.failCount = stationInfoDic.failCount + 1
            Log.LogInfo("stationInfoDic.failCount: ", stationInfoDic.failCount)
        else
            Log.LogInfo("unitTestResult: ", unitTestResult)
        end
    end

    Group.updateInfo(stationInfoDic)

end


-- 定义函数以手动将Lua表格转换为JSON字符串
local function encode_to_json(value)
    local json_str = ""
    local value_type = type(value)

    if value_type == "table" then
        local is_array = (#value > 0)
        if is_array then
            json_str = json_str .. "["
            for i, v in ipairs(value) do
                if i > 1 then
                    json_str = json_str .. ","
                end
                json_str = json_str .. encode_to_json(v)
            end
            json_str = json_str .. "]"
        else
            json_str = json_str .. "{"
            local first = true
            for k, v in pairs(value) do
                if not first then
                    json_str = json_str .. ","
                end
                first = false
                json_str = json_str .. "\"" .. tostring(k) .. "\":" .. encode_to_json(v)
            end
            json_str = json_str .. "}"
        end
    elseif value_type == "string" then
        json_str = json_str .. "\"" .. value .. "\""
    elseif value_type == "number" or value_type == "boolean" then
        json_str = json_str .. tostring(value)
    else
        error("Unsupported data type: " .. value_type)
    end

    return json_str
end
local function write_to_json(data,pth)
    -- 示例Lua表格

    -- 将Lua表格编码为JSON字符串
    local jsonString = encode_to_json(data)

    -- 将JSON字符串写入文件
    local file = io.open(path, "w")
    if file then
        file:write(jsonString)
        file:close()
        print("JSON data has been written to output.json")
    else
        print("Error: Unable to open file for writing")
    end
end

function executeAndWait(cmd)
    local temp = os.tmpname()
    os.execute(cmd .. " > " .. temp .. " 2>&1")
    local data = ""
    for line in io.lines(temp) do
      data = data .. line .. "\n"
    end
    os.remove(temp)
    return data
 end
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
-- local workingDirectory = ""

function getPortURL(slotIndex)

    local jsonFile="/vault/Config.json"
    local dutConfig = json.decode(comFunc.fileRead(jsonFile))
    -- local kisPort = dutConfig.kiePort["Unit1"]
    local kisPort = dutConfig.kiePort[tonumber(slotIndex)]["Unit"]
    print("getPortURL ============ ",kisPort)

    return "uart://"..kisPort.."?baud=921600&mode=8N1"
end

function getFixtureURL()
    local jsonFile="/vault/Config.json"
    local dutConfig = json.decode(comFunc.fileRead(jsonFile))
    -- local kisPort = dutConfig.kiePort["Unit1"]
    local transport = dutConfig.fixturePort[1]["Unit"]
    print("getFixturetURL ============ ",transport)

    return transport
end



function Plugins.loadPlugins(deviceName, groupPlugins)

    Group.clearStoppedDevices()
    
    -- local fixtureUrl = configInfo.info.FixturePort
    -- local barcodeUrl = configInfo.info.BarcodePort
    -- local thermometerUrl = configInfo.info.ThermometerPort
    --print(string.format('fixtureUrl:%s\nbarcodeUrl:%s\nthermometerUrl:%s',fixtureUrl,barcodeUrl,thermometerUrl))
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    -- local transport = Group.getDeviceTransport(deviceName)
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    CommBuilder.setLogFilePath(workingDirectory .. "/EFIDut.log", workingDirectory .. "/rawDut.log")
    --local dut = CommBuilder.createEFIPlugin(Group.getDeviceTransport(deviceName))
    
    -- Group.clearStoppedDevices()
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    print("WorkingDirectory is:"..tostring(workingDirectory))
    local index = string.find(workingDirectory,"user")
    local mainpath = string.sub(workingDirectory,1,index-1)
    local systemPath = mainpath..'system'
    print("systemPath is:"..tostring(systemPath))

    print("main_path ===",mainpath)
    -- 使用正则表达式匹配
    -- local prefix, number = mainpath:match("(group[01]-)(%w+)")
    local number = string.match(mainpath,"-(%d+)")
    print("number ===",number)

    local transport = getPortURL(number)
    
    -- local unitIndex = tonumber(Group.index)-1
    -- local transport = configInfo.info['Unit'..unitIndex]
    print("slot"..number.."         transport ====",transport)

    Log.LogInfo('transport:'..transport)
    local dut = CommBuilder.createCommPlugin(transport)

    -- fixtureURL
    local fixtureTransport = getFixtureURL()
    print("fixtureTransport ===",fixtureTransport)
    local fixture = CommBuilder.createCommPlugin(fixtureTransport)
    local SFC = Atlas.loadPlugin("SFC")
    -- local SFC = Atlas.loadPlugin("Record")
    -- local MixRPC = Plugins.initMix()
    -- you can define those in external file
    return {
        SFC = SFC,
        -- MESRecord = MESRecord,
        -- Conversion = Conversion,
        dut = dut,
        fixture = fixture,
        -- barcode = barcode,
        -- thermometer = thermometer,
        -- Convert = Convert,
        -- OCRegex = OCRegex,
        -- MixRPC = MixRPC
    }
end

-- 模拟通过扫码枪获取panel code
function getPanelCodeFromScanner()
    local scanSN = getScanInfo()
    print("scanSN =============",scanSN)
    return scanSN
    -- return "DK324010220105244030X69"
    -- return "GKK2410189030524604A957"
    
end

-- run scan gun
function getScanInfo()
    print("getScanInfo =========")
    
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    -- TCP通信
    local scanningGun = CommBuilder.createCommPlugin("tcp://192.168.1.10:9102")
    scanningGun.open(10)
    
    scanningGun.write("TRIGGER")
    
    status, cmdReturn = xpcall(scanningGun.read, debug.traceback,3)
    print("getScanInfo ====", cmdReturn)

    -- if  cmdReturn == nil  then
    scanningGun.write("RELEASE")
    -- end
    -- delete  \n & space
    local cleanedString = cmdReturn:gsub("[\n%s]+", "")
    return cleanedString
end


-- getDataFromMES
function getDataFromMES(groupPlugins)
  local panelSN = ""

  local popup = groupPlugins["Popup"]
  local inputString = popup.getInputSN("zhq")
  print("inputString ===>",inputString)
  inputString = inputString:gsub("[\n%s]+", "")
  if inputString ~= nil and #inputString > 0 then
    panelSN = inputString
  else
    panelSN = getPanelCodeFromScanner()
  end
   

  
  local cmd = "cd /Users/"..userName.."/Library/Atlas2/ScriptFile;/usr/bin/python2.7 /Users/"..userName.."/Library/Atlas2/ScriptFile/SipTest.py -sn "..panelSN
  local snsData = executeAndWait(cmd)
  print("snsData ===", snsData)
  
    
-- 使用正则表达式获取 QUERY_PANEL= 后面的内容
  local panel_value = string.match(snsData, 'QUERY_PANEL=(.*)')
  -- panel_value = "" 
  -- 输出匹配结果
  if panel_value == nil or #panel_value == 0 then
    print("zhqzhqzhq =============")
    local popup = groupPlugins["Popup"]
    popup.showAlert("一个码都没绑定","YES","NO")
    return {},{}

  end
  
  local array = {}
  for token in panel_value:gmatch("[^;]+") do
    table.insert(array, token)
  end


    local numbers = {}
    local strings = {}

   -- 遍历原始数组
    for _, str in ipairs(array) do
        -- 使用字符串的 gmatch 方法和模式匹配逗号分割
        local letter, number = str:match("([^,]+),(%d+)")
        if letter and number then
            -- 将匹配到的字符串部分和数字部分存放到相应的数组中
            table.insert(strings, letter)
            table.insert(numbers, tonumber(number))

            print("letter ====",letter)
            print("number ====",number)

            local slotNumer = tonumber(number)

            local echoLittleSN = "echo "..letter.."> /Users/gdlocal/Documents/slot"..tostring(slotNumer)..".txt"
            os.execute(echoLittleSN)
        end
    end
    
    os.execute("sleep 0.1")

    -- 输出数组内容
    -- print("Strings array:")
    -- for i, str in ipairs(strings) do
    --     print(i, str)
    -- end


    -- -- 输出数组内容
    -- for i, num in ipairs(numbers) do
    --     print("====================")
    --     print(i, num)
    --     print("====================")
    -- end

    return numbers,strings

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
-- function openPort(portName)
--     local user = io.popen('whoami')
--     local userName = user:read("*all")
--     userName = string.gsub(userName, "%s+", "")
--     local logFilePath = "/Users/"..userName.."/Documents/fixtureUrl.log"
--     local logFilePathRaw = "/Users/"..userName.."/Documents/fixtureUrlraw.log"
--     local lineTerminator = "\r\n"
--     local delimiter = "\n"
--     local timeout = 2
--     local serialPortUrl = configInfo.info[portName]
--     local CommBuilder = Atlas.loadPlugin("CommBuilder")
--     CommBuilder.setLogFilePath(workingDirectory .. "/fixtureUrl.log", workingDirectory .. "/fixtureUrlRaw.log")
--     local serialPort = CommBuilder.createCommPlugin(serialPortUrl)
--     Log.LogInfo('serialPort.isOpened():',serialPort.isOpened())
--     for i = 0,20 do
--          Log.LogInfo('for i = 0,20 do serialPort.isOpened()',serialPort.isOpened()) 
--         if serialPort.isOpened() == 0 then 
--             print('open00000')
--             serialPort.open(timeout) 
--             print('open111')
--             break
--         else
--             io.popen('sleep 0.5')
           
--         end
--     end
--     serialPort.setDelimiter(delimiter)
--     serialPort.setLineTerminator(lineTerminator)

--     return serialPort
--     -- local serialPort = Device.getPlugin(portName)
-- end

-- function sendCommand(portName,command,regex)
--     local serialPort = openPort(portName)
--     local response = serialPort.send(command,timeout)
--     if string.match(response, regex) then
--         serialPort.close()
--         return true 
--     end
--     return false
-- end

-- -- function readCommand(portName,regex)
-- --     local timeout = 0.1
-- --     local serialPort = openPort(portName)
-- --     while true do
-- --         local readResult = serialPort.read(timeout,'\n')
-- --         Log.LogInfo("readResult:",readResult)
-- --         local regexResult = string.match(readResult, regex)
-- --         Log.LogInfo("regexResult:",regexResult)
-- --         if regexResult then
-- --             serialPort.close()
-- --             return regexResult
-- --         end
-- --         io.popen('sleep 0.1')
-- --     end
-- --     return false

-- -- end
-- --example
-- --readCommand('FixturePort','')



-- function Plugins.getSlots(groupPlugins)
--     io.popen('sleep 0.5')
--     local groupIndex = Group.index
--     print('groupIndex:',groupIndex)
--     local slotsToStart = {}
--     local allSlots = Group.getSlots()
--     local popup = groupPlugins["Popup"]
--     local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
--     if comFunc.fileExists(configPath .. "/station.plist") then
--         local stationConfig = plist2lua.read(configPath .. "/station.plist")
--         Log.LogInfo('stationConfig.GroupConfig',stationConfig.GroupConfig)
--         group_num = tonumber(stationConfig.GroupConfig.Instances)
--         slot_num = #stationConfig.GroupConfig.SlotConfig
--         print(string.format('Plugins.getSlots group_num:%d--slot_num:%d',group_num,slot_num))
--     else
--         error("*****Plugins.getSlots The staition.plist file not found***")
--     end
--     -- for _, slot in ipairs(allSlots) do
--     --     if slot ~= 'slot1' then table.insert(slotsToStart, slot) end
--     -- end
--     -- for _, slot in ipairs(allSlots) do
--     --     local slot_number = string.match(slot, '.-(%d+)')
--     --     local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
--     --     print('Group index ==,',groupIndex)
--     --     print('Slot index ==,',slot_number)
--     --     print('checkBoxState',checkBoxState)
--     --     if checkBoxState == '1' then 
--     --         table.insert(slotsToStart, slot)
--     --     end
--     -- end
--     local user = io.popen('whoami')
--     local userName = user:read("*all")
--     userName = string.gsub(userName, "%s+", "")
--     local filePath = "/Users/"..userName.."/Documents/group"..groupIndex..".txt"


--     local fixture_command_table = {}
--     fixture_command_table['1'] = 'motor_to p1 2'
--     fixture_command_table['2'] = 'motor_to p2 2'
--     fixture_command_table['3'] = 'motor_to p3 3'
--     fixture_command_table['4'] = 'motor_to p4 4'
--     fixture_command_table['5'] = 'motor_to p5 2'
--     if tonumber(groupIndex) == 1 then
--         if not fileExists(filePath) then
--             local serialPort = openPort('FixturePort')
--             local fixture_detect = false
--             while true do
--                 print('groupIndex1111...',groupIndex)
--                 local readResult = serialPort.read(0.5,'\n')
--                 Log.LogInfo("readResult:",readResult)
--                 local regexResult = string.match(readResult, '(scanning)')
--                 Log.LogInfo("regexResult:",regexResult)
--                 if regexResult then
--                     serialPort.close()
--                     fixture_detect = true
--                     break
--                 end
--                 io.popen('sleep 0.1')
--             end
--             if fixture_detect then
--                 for _, slot in ipairs(allSlots) do
--                     local slot_number = string.match(slot, '.-(%d+)')
--                     local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
--                     print('Group index ==,',groupIndex)
--                     print('Slot index ==,',slot_number)
--                     print('checkBoxState',checkBoxState)
--                     if checkBoxState == '1' then 
--                         table.insert(slotsToStart, slot)
--                     end
--                 end
--                 print('#slotsToStart',#slotsToStart)
--                 if #slotsToStart ~=0 then
                    
--                     local serialPort = openPort('FixturePort')
--                     print('fixture_command_table["1"]',fixture_command_table["1"])
--                     local command = fixture_command_table[tostring(groupIndex)]..'\r\n'
--                     print('fixture_command_table[tostring(groupIndex)]',command)
--                     serialPort.write(command)
--                     while true do
--                         print('fixture_command_table while true',command)
--                         local readResult = serialPort.read(0.5,'\n')
--                         Log.LogInfo(" readResult:",readResult)
--                         local regexResult = string.match(readResult, '(pass)')
--                         Log.LogInfo("fixture_command_table regexResult:",regexResult)
--                         io.popen('sleep 0.1')
--                         if regexResult then
--                             serialPort.close()
--                             return slotsToStart
--                         end
--                         io.popen('sleep 0.1')
--                     end
--                 else
--                     os.execute('echo Testing'..' > '..filePath)
                  
--                 end

--             end
--         end
--     else
--         local lastGroupIndex = groupIndex-1
--         local lastFilePath = "/Users/"..userName.."/Documents/group"..lastGroupIndex..".txt"
--         print(string.format('lastGroupIndex:%d groupIndex:%d command:%s fileExists(lastFilePath):%s fileExists(filePath):%s',lastGroupIndex,groupIndex,fixture_command_table[tostring(groupIndex)],fileExists(lastFilePath),fileExists(filePath)))
--         if fileExists(lastFilePath) and not fileExists(filePath)then
--             for _, slot in ipairs(allSlots) do
--                 local slot_number = string.match(slot, '.-(%d+)')
--                 local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
--                 print('Group index ==,',groupIndex)
--                 print('Slot index ==,',slot_number)
--                 print('checkBoxState',checkBoxState)
--                 if checkBoxState == '1' then 
--                     table.insert(slotsToStart, slot)
--                 end
--             end
--             if #slotsToStart ~=0 then
--                 local serialPort = openPort('FixturePort')
--                 local command = fixture_command_table[tostring(groupIndex)]..'\r\n'
--                 print('fixture_command_table[tostring(groupIndex)]',command)
--                 serialPort.write(command)
--                 while true do
--                     print('fixture_command_table while true',command)
--                     local readResult = serialPort.read(0.5,'\n')
--                     Log.LogInfo(" readResult:",readResult)
--                     local regexResult = string.match(readResult, '(pass)')
--                     Log.LogInfo("fixture_command_table regexResult:",regexResult)
--                     if regexResult then
--                         serialPort.close()
--                         return slotsToStart
--                     else 
--                         io.popen('sleep 0.1')
--                     end
--                 end
--             else
--                 os.execute('echo Testing'..' > '..filePath)
--                 if tonumber(groupIndex) == group_num then
--                     for i=1,group_num do
--                         local filePath = "/Users/"..userName.."/Documents/group"..i..".txt"
--                         os.execute('rm -f '..filePath)
--                         if fileExists(filePath) then
--                             error("*****processGroupTxt delete the filePath error",filePath)
--                         else
--                             print("*****processGroupTxt delete group txt success***")
--                         end

--                     end
--                 end

--             end
--         end
--     end
-- end

-- function Plugins.getSlots(groupPlugins)
--     os.execute('sleep 1')
--     local allSlots = Group.getSlots()
--     local groupIndex = Group.index

--     -- local indexGroup = Group.index
--     -- Log.LogInfo("indexGroup-1:",tostring(indexGroup-1))
--     local popup = groupPlugins["Popup"]

    
--     popup.reset()
--     local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
--     if comFunc.fileExists(configPath .. "/station.plist") then
--         local stationConfig = plist2lua.read(configPath .. "/station.plist")
--         Log.LogInfo('stationConfig.GroupConfig',stationConfig.GroupConfig)
--         group_num = tonumber(stationConfig.GroupConfig.Instances)
--         slot_num = #stationConfig.GroupConfig.SlotConfig
--         print(string.format('Plugins.getSlots group_num:%d--slot_num:%d',group_num,slot_num))
--     else
--         error("*****Plugins.getSlots The staition.plist file not found***")
--     end

--     -- while true do

--     --     local clickStatus = popup.getStartClickStatus("11")
            
--     --     if tonumber(clickStatus) == 1 then
--     --         print("11111clickStatus =====",clickStatus)
--     --         break
--     --     else
--     --     print("000000clickStatus =====",clickStatus)
--     --     os.execute("sleep 1.5")
--     --     end

--     -- end

    
--     while true do
--         local clickStatus = popup.getStartClickStatus("1")
--         local clickStatus2 = popup.getStartClickStatus("2")
       

--             local slotsToStart = {}
--             for _, slot in ipairs(allSlots) do
--                 local slot_number = string.match(slot, '.-(%d+)')
--                 local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
--                 print('Group index ==,',groupIndex)
--                 print('Slot index ==,',slot_number)
--                 print('checkBoxState',checkBoxState)
--                 if checkBoxState == '1' then 
--                     table.insert(slotsToStart, slot)
--                 end
--             end
--             local user = io.popen('whoami')
--             local userName = user:read("*all")
--             userName = string.gsub(userName, "%s+", "")
--             local filePath = "/Users/"..userName.."/Documents/group"..groupIndex..".txt"
--             -- if tonumber(groupIndex) == 1 then
--              -- detecting fixture button 
--             local fixture_detect = true
--                 if tonumber(groupIndex) == 1 and tonumber(clickStatus) == 1 then
--                     if not fileExists(filePath) and fixture_detect then
--                         -- local command = fixture_command_table[groupIndex]
--                         --added fixture command of move handle
--                         --added scan sn action to here
--                         -- sn = readCommand()
        
--                         Log.LogInfo('kkk000slotsToStart:',slotsToStart)
--                         Log.LogInfo('kkk000#slotsToStart:',#slotsToStart)
--                         if #slotsToStart ~=0 then 
--                             return slotsToStart
--                         else
--                             print('kkk000')
--                             os.execute('echo Testing'..' > '..filePath)
--                         end
--                     end
--                 else
                    

--                     local lastGroupIndex = groupIndex-1
--                     local lastFilePath = "/Users/"..userName.."/Documents/group"..lastGroupIndex..".txt"
--                     if fileExists(lastFilePath) and not fileExists(filePath) and tonumber(clickStatus2) == 1 then
--                         -- local command = fixture_command_table[groupIndex]
        
--                         --added fixture command of move handle
--                         Log.LogInfo('kkk111slotsToStart:',slotsToStart)
--                         Log.LogInfo('kkk111#slotsToStart:',#slotsToStart)
--                         if #slotsToStart ~=0 then
--                             return slotsToStart
--                         else
--                             os.execute('echo Testing'..' > '..filePath)
--                             if tonumber(groupIndex) == group_num then
--                                 for i=1,group_num do
--                                     local filePath = "/Users/"..userName.."/Documents/group"..i..".txt"
--                                     os.execute('rm -f '..filePath)
--                                     if fileExists(filePath) then
--                                         error("*****processGroupTxt delete the filePath error",filePath)
--                                     else
--                                         print("*****processGroupTxt delete group txt success***")
--                                     end
--                                 end
--                             end
--                         end
--                     end
--                 end
--     end


--     --     Log.LogInfo(string.format("loop when group is....'%s'", indexGroup))
--     --     -- popup.reset(tostring(Group.index-1))
--     --     local result = popup.getField()
--     --     if result ~= "" then 
--     --         result = result+1 
--     --         Log.LogInfo("Execute OC getField function result:",result)
--     --     end
        
--     --     -- local sn = popup.getFieldSN()
--     --     -- Log.LogInfo("Execute OC getField function result:",result)
--     --     -- Log.LogInfo("Execute OC getFieldSN function to get the SN is:",sn)
--     --     if tonumber(result) == tonumber(indexGroup) then
--     --         -- os.execute('sleep 0.5')
--     --         popup.resetID()
--     --         Log.LogInfo("start test ",result)
--     --         break
--     --     end
--     --     os.execute('sleep 0.2')
--     -- end
    
    
--     -- return  Group.getSlots()
-- end

-- 判断数组中是否包含某个数字
local function containsNumber(array, number)
    print("zhqzhqzhq ===",number)
    for _, value in ipairs(array) do
        print("value =====",value)
        if value == number then
            return true
        end
    end
    return false
end

-- 
function stringContains(longString, shortString)
    return string.find(longString, shortString, 1, true) ~= nil
end

function fixturePowerOn()

    local CommBuilder = Atlas.loadPlugin("CommBuilder")

    local transport_Board = "uart:///dev/cu.usbserial-A50285BI?baud=115200&mode=8N1"

    print("transport_Board is:" .. tostring(transport_Board))
    
    -- CommBuilder.sendData(" ")
    CommBuilder.setLineTerminator("\r\n")
  
    -- Setup DUT UART Communication
    local dut_Board = CommBuilder.createCommPlugin(transport_Board)
    if dut_Board.isOpened()==0 then
        dut_Board.open(5)
        dut_Board.setDelimiter("\n")
    end
    
    local tableCMD = {
        "RF_START_TEST",
        "GET_PCB_VER",
        "GET_FW_VER",
        "READ_COEF3",
        "READ_OFFSET3"

    }
    print("==========0")
    local flag = 0
    for i,value in ipairs(tableCMD) do
        print("==========",i)
        print("cmdValue ===",value)
        -- dut_Board.send('\n')
        -- local res = dut_Board.send(value)
        os.execute("sleep 0.1")
        -- dut_Board.send('\n')
        -- res = dut_Board.read()
        -- print("res =====",res)
        

        local startTime = os.time()
        local res = ""
        local cmdRes = ""
        dut_Board.write(value)
        while true do 
            
            local currentTime = os.time() - startTime
            cmdRes = dut_Board.read()
            res = res..cmdRes
            if currentTime > 1.5 then 

                break
            end
            os.execute("sleep 0.1")

        end

        print("res =====",res)

        -- if res ~= nil and #res ~= 0 then
        flag = 1
            
        -- else
        --     flag = 0
        --     -- break
        -- end


        
    end
  


    
    
    if dut_Board.isOpened()== 1  then
        dut_Board.close()
    end

    
    os.execute("sleep 0.5")
    return flag

end

function Plugins.getSlots(groupPlugins)
    local popup = groupPlugins["Popup"]
    popup.reset()
    local groupIndex = Group.index
    print('groupIndex-->',groupIndex)


    while true do 

        local clickStatus = popup.getStartClickStatus("1")
        local clickStatus2 = popup.getStartClickStatus1("2")
        
        print(string.format('clickStatus-->%s',clickStatus))
        print(string.format('clickStatus2-->%s',clickStatus2))
        print('clickStatus2-->',clickStatus2)
        if (tonumber(groupIndex) == 1  and tonumber(clickStatus) == 1) or  (tonumber(groupIndex) == 2 and tonumber(clickStatus2) == 1) then

                -- check plate cover status 
            
            -- if(tonumber(groupIndex) == 1) then
            --     local controlShowAlertTimes = 0
            --     while true do
            --         local coverPlate_Status_Cmd1 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/CoverPlateStatus1.py"
            --         local coverPlate_Status_res1 = executeAndWait(coverPlate_Status_Cmd1)
            --         print("coverPlate_Status_res ===",coverPlate_Status_res1)
    
                    
            --         if stringContains(coverPlate_Status_res1, "01 01 01 01 90 48") then
            --             print("container ============")
            --             break
            --         else
                        
            --             controlShowAlertTimes = controlShowAlertTimes + 1
            --             if controlShowAlertTimes == 3 then
            --                 print("no container ==========",coverPlate_Status_res1)
            --                 local useAlert = popup.alert("Please cover the plate1","OK")
            --                 while true do
            --                         os.execute("sleep 0.5")
            --                         local alertStatus = popup.queryAlert()
            --                         if alertStatus == 0 then
            --                             break
            --                         end
            --                 end
            --             end
                        
            --         end
            --         os.execute("sleep 1")
            --     end
            -- end

            -- if(tonumber(groupIndex) == 2) then
            --     controlShowAlertTimes = 0
            --     while true do
            --         local coverPlate_Status_Cmd2 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/CoverPlateStatus2.py"
            --         local coverPlate_Status_res2 = executeAndWait(coverPlate_Status_Cmd2)
            --         print("coverPlate_Status_res ===",coverPlate_Status_res2)
            --         if stringContains(coverPlate_Status_res2, "01 01 01 01 90 48") then
            --             print("container ============")
            --             -- startBtnGlobal.showTipMessage("")
            --             break
            --         else
            --             -- startBtnGlobal.showTipMessage("Please cover the plate")
            --             controlShowAlertTimes = controlShowAlertTimes + 1
            --             if controlShowAlertTimes == 3 then
            --                 print("no coverPlate_Status_res2 ==========",coverPlate_Status_res2)
            --                 local useAlert = popup.alert("Please cover the plate2","OK")
            --                 while true do
            --                         os.execute("sleep 0.5")
            --                         local alertStatus = popup.queryAlert()
            --                         if alertStatus == 0 then
            --                             break
            --                         end
            --                 end
                            
            --                 print("no container =======")
            --             end
                        
            --         end
            --     end

            -- end

            local arrayFromMES,snFromMes = getDataFromMES(groupPlugins)
            Log.LogInfo("arrayFromMES =====",arrayFromMES)
            if arrayFromMES == {} or #arrayFromMES == 0 then
                -- body
                print("zhqzhqzhq +++++++++")
                if tonumber(clickStatus) == 1 then
                    -- body
                    popup.resetWithButtonIndex("1")
                end

                if tonumber(clickStatus2) == 1 then
                    -- body
                    popup.resetWithButtonIndex("2")
                end

                return;
            end

            -- 发送END_ReTEST
            local End_Cmd1 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/serialPortEnd.py"
            print("End_Cmd1 =====",End_Cmd1)
            local End_Cmd1Res = executeAndWait(End_Cmd1)
            print("End_Cmd1Res =====",End_Cmd1Res)

            if (tonumber(groupIndex) == 1  and tonumber(clickStatus) == 1) then
                -- send xuanzhuan cmd
                local xuanzhuan_Cmd1 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlXuanZhuan1.py"
                print("xuanzhuan_Cmd1 =====",xuanzhuan_Cmd1)
                local xuanzhuan_res1 = executeAndWait(xuanzhuan_Cmd1)
                print("xuanzhuan_res1 =====",xuanzhuan_res1)
                if stringContains(xuanzhuan_res1, "01 05 01 2C FF 00 4C 0F") then
                    print("start detect11111111")
                
                else

                    os.execute("sleep 0.1")
                    -- local useAlert = popup.alert("xuanzhuan not ok","OK")
                    -- while true do
                    --     os.execute("sleep 0.5")
                    --     local alertStatus = popup.queryAlert()
                    --     if alertStatus == 0 then
                    --         break
                    --     end
                    -- end
                end

                while true do                 
                    local needleDownOK_Cmd = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/CheckNeedleDown1OK.py"
                    local needleDownOK_res = executeAndWait(needleDownOK_Cmd)

                    if stringContains(needleDownOK_res, "01 01 01 01 90 48") then
                        os.execute("sleep 0.3")
                        break
                    end
                    os.execute("sleep 0.5")
                end
            elseif  (tonumber(groupIndex) == 2 and tonumber(clickStatus2) == 1) then
                -- send xuanzhuan cmd
                local xuanzhuan_Cmd2 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlXuanZhuan2.py"
                print("xuanzhuan_Cm2 ===",xuanzhuan_Cmd2)
                local xuanzhuan_res2 = executeAndWait(xuanzhuan_Cmd2)
                print("xuanzhuan_res2 ===",xuanzhuan_res2)
                -- if stringContains(xuanzhuan_res2, "01 05 01 2E FF 00 ED CF") then
                --     print("start detect22222222")
                
                    
                -- else
                --     break
                --     -- local useAlert = popup.alert("xuanzhuan not ok","OK")
                --     -- while true do
                --     --     os.execute("sleep 0.5")
                --     --     local alertStatus = popup.queryAlert()
                --     --     if alertStatus == 0 then
                --     --         break
                --     --     end
                --     -- end
                -- end

                local rmCmd = "rm /Users/gdlocal/Documents/need2OK.txt"
                os.execute(rmCmd)
                os.execute("sleep 0.1")

                while true do                 
                    local needleDownOK_Cmd = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/CheckNeedleDown2OK.py"
                    local needleDownOK_res = executeAndWait(needleDownOK_Cmd)
                    print("needleDownOK_res ====",needleDownOK_res)


                    if stringContains(needleDownOK_res, "01 01 01 01 90 48") then
                        local down2OKcmd = "echo down2OK > /Users/gdlocal/Documents/need2OK.txt"
                        os.execute(down2OKcmd)
                        os.execute("sleep 0.3")
                        break
                    end
                    os.execute("sleep 0.1")
                end
            end

     
        

            
            
        local slotsToStart = {}
        local allSlots = Group.getSlots()
        for _, slot in ipairs(allSlots) do
            local slot_number = string.match(slot, '.-(%d+)')
            local checkBoxState = popup.getcheckBoxState(tostring(groupIndex-1),tostring(slot_number-1))
            print('Group index ==,',groupIndex)
            print('Slot index ==,',slot_number)
            print('checkBoxState',checkBoxState)
            -- if checkBoxState == '1' then 
            --     table.insert(slotsToStart, slot)
            -- end
            -- local checkSlotNum = tonumber(slot_number) + 1
            if checkBoxState == '1' and containsNumber(arrayFromMES,tonumber(slot_number)) then 
                
                table.insert(slotsToStart, slot)
            end
        end

        print("start run test plan")
                -- delete file
                local runFixtureInitPY = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 serialPort.py"
                os.execute(runFixtureInitPY)
                os.execute("sleep 0.1")

            -- local runFixtureResult = fixturePowerOn()
            -- if runFixtureResult == 1 then 
                print("000group ====",groupIndex)
                print("000clickStatus ====",clickStatus)
                print("000clickStatus2 ====",clickStatus2)
                return slotsToStart
            -- else
            --     print("runFixture Fail ====")
            -- end

         

        -- elseif tonumber(groupIndex) == 2 and tonumber(clickStatus2) == 1 then
        --     print("111group ====",groupIndex)
        --     print("111clickStatus ====",clickStatus)
        --     print("111clickStatus2 ====",clickStatus2)
            
        end

        -- local CommBuilder = Atlas.loadPlugin("CommBuilder")

        -- local transport_Board = "uart:///dev/cu.usbserial-A50285BI?baud=115200&mode=8N1"
    
        -- print("transport_Board is:" .. tostring(transport_Board))
        
        -- -- CommBuilder.sendData(" ")
        -- CommBuilder.setLineTerminator("\r\n")
      
        -- -- Setup DUT UART Communication
        -- local dut_Board = CommBuilder.createCommPlugin(transport_Board)
        -- if dut_Board.isOpened()==0 then
            
        -- end
        
        -- local res = dut_Board.send("RF_START_TEST")
        -- print("res ====",res)
    
        -- dut_Board.close(2)
        -- os.execute("sleep 1")
        
        -- os.execute('sleep 0.1')
    end



    

end


function getLastElement(t)
    local lastKey = nil
    for k, _ in pairs(t) do
        lastKey = k
    end
    return t[lastKey]
end

function resetFixture(groupIndex,group_num,slot_num,groupPlugins)
    local popup = groupPlugins["Popup"]
    local groupSlectedTable = {}
    for g = 0,group_num-1 do
        for s = 0, slot_num-1 do
            local checkBoxState = popup.getcheckBoxState(tostring(g),tostring(s))
            if checkBoxState == '1' then
                table.insert(groupSlectedTable, g)
            end
        end
    end
    Log.LogInfo("groupSlectedTable:",groupSlectedTable)
    Log.LogInfo("getLastElement(groupSlectedTable) groupSlectedTable:",getLastElement(groupSlectedTable))
    return getLastElement(groupSlectedTable)

end
function processGroupTxt(groupIndex,groupPlugins)
    
    local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
    if comFunc.fileExists(configPath .. "/station.plist") then
        local stationConfig = plist2lua.read(configPath .. "/station.plist")
        group_num = tonumber(stationConfig.GroupConfig.Instances)
        slot_num = #stationConfig.GroupConfig.SlotConfig
        print(string.format('processGroupTxt group_num:%d--slot_num:%d',group_num,slot_num))
    else
        error("*****processGroupTxt The staition.plist file not found***")
    end

    local groupIndex = groupIndex
    local lastGroupIndex = resetFixture(groupIndex,group_num,slot_num,groupPlugins)
    print("In processGroupTxt groupIndex is:",groupIndex)
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    local filePath = "/Users/"..userName.."/Documents/group"..groupIndex..".txt"
    -- os.execute('sleep 10')
    os.execute('echo Testing'..' > '..filePath)
    if fileExists(filePath) then
        print("*****processGroupTxt The filePath created",filePath)
    else
        error("*****processGroupTxt file group txt error***")
    end
  
    -- return lastGroupIndex
    if tonumber(lastGroupIndex) == tonumber(groupIndex-1) then
        print('tonumber(lastGroupIndex) == tonumber(groupIndex-1)')
        -- command = 'fix open\r\n'
        -- local serialPort = openPort('FixturePort')
        -- serialPort.write(command)
        -- while true do
        --     print('fixture_command_table while true',command)
        --     local readResult = serialPort.read(0.5,'\n')
        --     Log.LogInfo(" readResult:",readResult)
        --     local regexResult = string.match(readResult, '(pass)')
        --     Log.LogInfo("fixture_command_table regexResult:",regexResult)
        --     if regexResult then
        --         serialPort.close()
        --         break
        --     end
        --     io.popen('sleep 0.1')
        -- end
        -- serialPort.close()
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

function Plugins.shutdownPlugins(deviceName, devicePlugins)
    getTestResults(deviceName)
    Log.LogInfo("shutdownGroupPluginsgroupIndex0000:devicePlugins",devicePlugins)
    -- print('shutdownGroupPluginsgroupIndex0000:devicePlugins',devicePlugins)
    
    local groupIndex = Group.index
    -- print('shutdownGroupPluginsgroupIndex:',groupIndex)
    -- print('shutdownPlugins Device.userDirectory----:'..Device.userDirectory)


end

function Plugins.loadGroupPlugins(resources)
    Log.LogInfo("--------loading group plugins-------")
    return {Popup=Remote.loadRemotePlugin(resources["Popup"])}
end

function Plugins.shutdownGroupPlugins(groupPlugins)
    
    
    print('shutdownGroupPlugins stopped')

    
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
end
--]]

function Plugins.groupStart(groupPlugins)
    print('group starting')

    local timeStart = os.time()
    local echoTimeCMD = "echo "..timeStart.." > /Users/gdlocal/Documents/launchTime.txt"
    os.execute(echoTimeCMD)

    
    local StartFlagCmd = "echo 0 > /Users/gdlocal/Documents/StartFlag.txt"
    os.execute(StartFlagCmd)

    local FinishFlagCmd = "echo 0 > /Users/gdlocal/Documents/FinishFlag.txt"
    os.execute(FinishFlagCmd)
end

function Plugins.groupStop(groupPlugins)

    -- stationInfoDic.inputCount = 0
    -- stationInfoDic.passCount = 0
    -- stationInfoDic.failCount = 0
    -- Group.updateInfo(stationInfoDic)



    local popup = groupPlugins["Popup"]
    popup.resetWithGroupIndex(tostring(Group.index))
    print('Plugins.groupStop....')
    -- local popup = groupPlugins["Popup"]
    Log.LogInfo("Plugins.groupStop groupPlugins",groupPlugins)
    processGroupTxt(Group.index,groupPlugins)
    print("Group.index ====",Group.index)
    -- popup.reset(tostring(Group.index-1))
    -- Log.LogInfo("Plugins.groupStop groupPlugins",groupPlugins)
    -- processGroupTxt(Group.index,groupPlugins)
    -- needle board up
    -- os.execute("sleep 0.1")

    local runFixtureEndPY = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 serialPortEnd.py"
    
    -- local runFixtureEndPYRes = executeAndWait(runFixtureEndPY)
    
    local timeoutPY = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/bin/python runPyTask.py -c '"..runFixtureEndPY.."' -t 3 "
    local data = executeAndWait(timeoutPY)
    Log.LogInfo("dataRes ====",data)

    

    if(Group.index == 1) then
        
        local control_needleUpCMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlNeedleUp1.py"
        local control_needleUpRES = executeAndWait(control_needleUpCMD)

        if stringContains(control_needleUpRES, "01 05 01 2D 00 00 5C 3F") then
            print("up ==========")
        else
            print("no up ==========")
        end

    end

    if(Group.index == 2) then

        local control_needleUpCMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlNeedleUp2.py"
        local control_needleUpRES = executeAndWait(control_needleUpCMD)

        if stringContains(control_needleUpRES, "01 05 01 30 00 00 CC 39") then
            print("up ==========")
        else
            print("no up ==========")
        end

    end
    -- os.execute("sleep 0.5")
    
    print('group stopped')
end


return Plugins
