local Log = require("Matchbox/logging")
local plist2lua = require("Matchbox/plist2lua")
local comFunc = require("Matchbox/CommonFunc")
function addRealDevice()
    for i=1,6 do 
        DutUrl = "uart:///dev/cu.usbserial-DUT"..i.."?baud=921600"          
        local pollDetect = Atlas.loadPlugin("PollDetectPlugin")
        detecter = pollDetect.createDetector(DutUrl,1)
        Detection.addDeviceDetector(detecter)
    end

    local routingCallback = function(DutUrl)
        local groups = Detection.groups()
        print(DutUrl)

        group_index = tonumber(string.match(DutUrl, 'DUT(%d+)'))
       -- group_index = 1
        slot_index = 1
        print('group_index: ' .. group_index)
        print('slot_index: ' .. slot_index)
        local groupName = groups[group_index]
        print('groupName:' .. groupName)
        slots = Detection.slots()
        return slots[slot_index], groups[group_index]
    end
    Detection.setDeviceRoutingCallback(routingCallback)
end

-- function addFakeDevice()
--     local json = require("Matchbox/json")
--     local comFunc = require("Matchbox/CommonFunc")
--     local file = require("Tech/DealWithFile")
--     local jsonfile = file.getConfigJson()
--     local configInfo = json.decode(comFunc.fileRead(jsonfile))
--     local IPInfo = configInfo.info.IPInfo
--     local IPAddress = IPInfo.IPAddress
--     local IPport = IPInfo.Port
--     local url = IPAddress .. ':'..IPport 
--     Detection.addDevice(url)
--     local routingCallback = function(url)
--         local groups = Detection.groups()
--         local groupName = groups[1]
--         print('groupName:' .. groupName)
--         print(url)
--         -- group_index = tonumber(string.sub(url, -1))
--         --group_index = tonumber(string.match(url, 'DUT(%d+)'))
--         group_index = 1
--         slot_index = 1
--         print('group_index: ' .. group_index)
--         print('slot_index: ' .. slot_index)
--         slots = Detection.slots()
--         return slots[slot_index], groups[group_index]
--     end

--     Detection.setDeviceRoutingCallback(routingCallback)
-- end
function fileExists(filename)
    local file = io.open(filename, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function addFakeDevice()
    -- local json = require("Matchbox/json")
    -- local comFunc = require("Matchbox/CommonFunc")
    -- local file = require("Tech/DealWithFile")
    -- local jsonfile = file.getConfigJson()
    -- local configInfo = json.decode(comFunc.fileRead(jsonfile))
    -- local IPInfo = configInfo.info.IPInfo
    -- local IPAddress = IPInfo.IPAddress
    -- local IPport = IPInfo.Port
    -- local url = IPAddress .. ':'..IPport 
    local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
    if comFunc.fileExists(configPath .. "/station.plist") then
        local stationConfig = plist2lua.read(configPath .. "/station.plist")
        Log.LogInfo('stationConfig.GroupConfig',stationConfig.GroupConfig)
        group_num = tonumber(stationConfig.GroupConfig.Instances)
        slot_num = #stationConfig.GroupConfig.SlotConfig
        station_name = stationConfig.StationName
        overlay_version = stationConfig.StationVersion
        print('station_name---overlay_version:',stationConfig.StationName..'---'..overlay_version)
        print(string.format('group_num:%d--slot_num:%d',group_num,slot_num))
    else
        error("*****The staition.plist file not found***")
    end


    --delete the group txt file when the atlas launch to init these groups test state
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")

    -- local python_version = io.popen('which python3')
    -- local python_version_return = python_version:read("*all")
    -- print('python_version:',python_version_return)
    -- print('userName:',userName)
    if userName == 'gdlocal' then 
        -- python_v = string.gsub(python_version_return, "%s+", "")
        python_v = "/usr/local/bin/python3"
    else
        --raplace python_version when the overlay roll in line
        python_v = "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3"
    end
    
    args = '-n '..station_name..' -v '..overlay_version
    command = python_v..' '..'/Users/'..userName..'/Documents/python/create_new_csv.py'..' '..args
    print('---command---:'..command)
    local run_python = io.popen(command)
    local run_python_result = run_python:read("*all")
    if string.match(run_python_result, '(successfully)') then
        print(run_python_result)
    else
        -- error('---crate new csv error---')
    end
    for i=1,group_num do
        local filePath = "/Users/"..userName.."/Documents/group"..i..".txt"
        os.execute('rm -f '..filePath)
        if fileExists(filePath) then
            error("*****detect.lua delete the filePath error",filePath)
        else
            print("*****detect.lua delete group txt success***")
        end
    end
 
    for i = 1,group_num do 
        for s = 1,slot_num do
           Detection.addDevice("uart://fake1-path-"..tostring(i)..'_'..tostring(s)) 
        end
    end

    local routingCallback = function(url)
        local groups = Detection.groups()
        local slots = Detection.slots()
        Log.LogInfo('groups:',groups)
        Log.LogInfo('slots:',slots)
    
        print('url....:'..url)
        local group_index = string.match(url, '.-(%d+)_')
        local slot_index = string.match(url, '.-_(%d+)')
        group_index = tonumber(group_index)
        slot_index = tonumber(slot_index)
        -- group_index = tonumber(string.sub(url, -1))
        --group_index = tonumber(string.match(url, 'DUT(%d+)'))
        print('group_index: ' .. group_index)
        print('slot_index: ' .. slot_index)
        local groupName = groups[1]
        print('groupName:' .. groupName)
        
        return slots[slot_index], groups[group_index]
    end

    Detection.setDeviceRoutingCallback(routingCallback)
end

function main()
    local realDut = false

    
    local sendSystemReset = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 serialPortSystemReset.py"
    os.execute(sendSystemReset)

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
    -- print("res111 ====",res)

    -- dut_Board.close(2)
    -- os.execute("sleep 1")
    
    os.execute('sleep 0.1')
    if realDut then 
        addRealDevice()        
    else
        addFakeDevice()
    end
end

