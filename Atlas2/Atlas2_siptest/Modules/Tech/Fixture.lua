local Log = require("Matchbox/logging")
local Record = require("Matchbox/record")
local comFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")


Fixture = {}

function createRecordCommon(paraTab, result, value, failMsg)
    local subsubtestname = comFunc.trim(paraTab.AdditionalParameters.paraName)
    if (subsubtestname == nil) then
        return
    end
    local limit = nil
    local testname = paraTab.Technology
    local paraName = paraTab.AdditionalParameters.paraName or paraTab.TestName
    local subsubtestname = comFunc.trim(paraTab.AdditionalParameters.paraName)

    local type = comFunc.trim(paraTab.AdditionalParameters.type)
    print("type ====", type)

    if subsubFromInput then subsubtestname = subsubFromInput end
    local subtestname = paraTab.TestName .. paraTab.testNameSuffix


    if paraTab.isLimitApplied and paraTab.limit and paraTab.limit[paraName] and result == true then
        limit = paraTab.limit[paraName]
        --   Record.createRecord(value, testname, subtestname, subsubtestname, limit,failMsg)
        -- Pass/Fail 是否显示 1/0
        if type ~= nil then
            if result == true then
                Record.createRecord(value, testname, subtestname, subsubtestname, limit, failMsg)
            else
                Record.createRecord(value, testname, subtestname, subsubtestname, limit, failMsg)
            end
        else
            -- 正常显示
            Record.createRecord(value, testname, subtestname, subsubtestname, limit, failMsg)
        end
    else
        Record.createBinaryRecord(result, testname, subtestname, subsubtestname, failMsg)
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

function Fixture.startTest(paraTab)
    
    print("startTest ==========")

    local workingDirectory = Device.userDirectory
    resp = string.match(workingDirectory, "group(%d+)")
    print("Group.index11111111" .. resp)

    url = Device.transport
    print("**************", url)

    local last_underscore_idx = url:find("_[^_]*$")
    local slotnumIndex = 9999
    if last_underscore_idx then
        -- 获取最后一个下划线后面的部分
        local num_str = url:sub(last_underscore_idx + 1)

        -- 将提取的部分转换为数字
        slotnumIndex = tonumber(num_str)
        -- 输出结果
        if slotnumIndex then
            print("Extracted number:", slotnumIndex)
        else
            print("No number found after the last underscore")
        end
    else
        print("No underscore found in the string")
    end

    local getSNFromLocalFileCMD = "cat /Users/gdlocal/Documents/slot" .. slotnumIndex .. ".txt"
    local content = executeAndWait(getSNFromLocalFileCMD)
    print("content ======", content)
    print("content length ======", #content)

    local cleanedString = content:gsub("[\n%s]+", "")

    print("cleanedString ======", cleanedString)
    print("cleanedString length ======", #cleanedString)

    if cleanedString ~= nil then 
        DataReporting.primaryIdentity(cleanedString)
        return cleanedString
    end
    return false

    -- 

end

function getPortKisURL(slotIndex)

    local jsonFile="/vault/Config.json"
    local dutConfig = json.decode(comFunc.fileRead(jsonFile))
    -- local kisPort = dutConfig.kiePort["Unit1"]
    local kisPort = dutConfig.kiePort[tonumber(slotIndex)]["Unit"]
    print("getPortURL ============ ",kisPort)

    return kisPort
end


function Fixture.initGNMethod(paraTab)

    -- local GN_plugin = Device.getPlugin("GN_plugin")

    local workingDirectory = Device.userDirectory
    resp = string.match(workingDirectory, "group(%d+)")
    print("Group.index11111111" .. resp)

    url = Device.transport
    print("**************", url)

    local last_underscore_idx = url:find("_[^_]*$")
    local slotnumIndex = 9999
    local slotnumKis = 9999
    if last_underscore_idx then
        -- 获取最后一个下划线后面的部分
        local num_str = url:sub(last_underscore_idx + 1)

        -- 将提取的部分转换为数字
        slotnumIndex = tonumber(num_str)
        -- 输出结果
        if slotnumIndex then
            print("Extracted number:", slotnumIndex)
        else
            print("No number found after the last underscore")
        end
    else
        print("No underscore found in the string")
    end
    slotnumKis = slotnumIndex
    if slotnumIndex == 10 then 
        slotnumIndex = "A"
    end

    local kisPort = getPortKisURL(slotnumKis)
    print("zhq_kisPort +++++",kisPort)

    -- 初始化随机种子
    math.randomseed(os.time())

    -- 生成随机小数
    local random_number = math.random() * 2

    print("random_number ===",random_number)
    local sleepCMD = "sleep "..tostring(random_number)
    print("random_number ===",sleepCMD)
    os.execute(sleepCMD)



    local runGN_CMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/grassninja.py -p /dev/cu.usbserial-DUT"..slotnumIndex.."0".." -s on"
    print("runGN_CMD ==",runGN_CMD)

    local time = 0

    while time < 3 do

        local status, res = xpcall(executeAndWait, debug.traceback, runGN_CMD)
        print("res ==xxxxxxx",res)

        os.execute("sleep 3")

        local kisPort = getPortKisURL(slotnumKis)
        print("kisPort +++++",kisPort)
        print("kisPort ++++++",#kisPort)

        local echoAllKisCmd = "ls /dev/cu.*"
        local allKisRes = executeAndWait(echoAllKisCmd)

        print("allkis +++++",allKisRes)


        kisPort = kisPort:gsub("[\n%s]+", "")
        kisPort = string.match(kisPort,"kis%-(%d+)%-")
        print("kisPort +++++======",kisPort)
        print("kisPort +++++++++",#kisPort)

        if string.find(allKisRes, kisPort) or string.match(allKisRes,kisPort) ~= nil then
            print("FindKisPort ====",allKisRes)
            -- print("找到了!!!!")
            break
        end
        
        local powerCycle_CMDXXX = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_powerCycle.py -p /dev/cu.usbserial-DUT"..slotnumIndex.."0"
        print("powerCycle_CMDXXX ==",powerCycle_CMDXXX)
        local powerCycle_CMDXXXRes = executeAndWait(powerCycle_CMDXXX)
        print("powerCycle_CMDXXXRes ===",powerCycle_CMDXXXRes)

        os.execute("sleep 4")

        -- local status, res = xpcall(executeAndWait, debug.traceback, runGN_CMD)
        -- print("res ==xxxxxxx",res)
        -- os.execute("sleep 5")
        
       
        time = time + 1
    end

  


    print("initGNMethod ========")
    local result = true
    local failMsg = ""
    -- createRecordCommon(paraTab, result, "", failMsg)
    return true
end

function Fixture.parseFixtureCMD(paraTab)

    -- local GN_plugin = Device.getPlugin("GN_plugin")
    local fixtureCMD = paraTab.AdditionalParameters.cmd
    print("fixtureCMD ===",fixtureCMD)

    if fixtureCMD == "GET_PCB_VER" or fixtureCMD == "GET_FW_VER"  or fixtureCMD == "READ_COEF3" or fixtureCMD == "READ_OFFSET3"  then
        return true
    end
    
    local jsonFile = "/Users/gdlocal/Documents/fixture_command.json"
    local fixtureConfigInfo = json.decode(comFunc.fileRead(jsonFile))
    local resFromJson = fixtureConfigInfo[fixtureCMD]

    if resFromJson == nil or #resFromJson == 0 then 
        print("no res")
        return false
    else
        print("resFromJson ===",resFromJson)
        
        return resFromJson
    end
    
end

function getPortURL(slotIndex)

    local jsonFile="/vault/Config.json"
    local dutConfig = json.decode(comFunc.fileRead(jsonFile))
    -- local kisPort = dutConfig.kiePort["Unit1"]
    local kisPort = dutConfig.kiePort[tonumber(slotIndex)]["Unit"]
    print("getPortURL ============ ",kisPort)

    return "uart://"..kisPort.."?baud=921600&mode=8N1"
    
end

function Fixture.openDUT(paraTab)
    
    print("start run opneDUT")
    -- local GN_plugin = Device.getPlugin("GN_plugin")
    
    local dut = nil
    local pluginVar = paraTab.AdditionalParameters
    if pluginVar ~= nil then
        
        dut = Device.getPlugin(tostring(pluginVar))
        
        dut.setLineTerminator("\r\n")
        dut.setDelimiter("\n] \n] ")
        dut.open(5)
        

        dut.write(" ")
        dut.read()
    end
    
    local res = dut.send("ft version")
    print("res ===",res)


    local res = dut.send("ft fw_info")
    print("res ===fw_info==",res)
    
    
    return true
end

function Fixture.addLogToInsight(param)
    Log.LogInfo('adding user/ log folder to insight')
    os.execute("sleep 0.1")
    Archive.addPathName(Device.userDirectory, Archive.when.deviceFinish)

    Log.LogInfo('end addLogToInsight ====')

end


function calTimeAction(paraTab)
    local time = os.time()
    print("every slot start time ====")

    return time
end


-- local SKIP_FILE_LIST = {"Common.lua"}
-- local techPath = string.gsub(Atlas.assetsPath, "Assets", "Modules/Tech")
-- local techFiles = comFunc.runShellCmd("ls ".. techPath .. " | grep -i .lua$").output
-- -- Log.LogInfo("Lua file list: ", techFiles)
-- local techFileList = comFunc.splitBySeveralDelimiter(techFiles,'\n\r')

-- for i, file in ipairs(techFileList) do
--     if not comFunc.hasVal(SKIP_FILE_LIST, file) then
--         -- Log.LogInfo("Lua file: ", file)
--         local requirePath = "Tech/"..file:match("(.*)%.lua")
--         local lib = require(requirePath)
--         for name, func in pairs(lib) do
--             Common[name] = func
--         end
--     end
-- end








return Fixture
