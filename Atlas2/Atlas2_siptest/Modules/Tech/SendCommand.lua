local sendFunc = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require 'Matchbox/json'
local Universal = require("Tech/Universal")

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

function sendFunc.moveFixture(paraTab)
    local inputs = paraTab.InputValues
    local group = inputs[1]
    local slot = inputs[2]
    print('moveFixture group,slot',group,slot)
    if tonumber(group) ~= 0 and tonumber(slot) == 1 then
        local fixture_command_table = {}
        fixture_command_table['1'] = 'motor_to p1 2'
        fixture_command_table['2'] = 'motor_to p2 2'
        fixture_command_table['3'] = 'motor_to p3 3'
        fixture_command_table['4'] = 'motor_to p3 4'
        fixture_command_table['5'] = 'motor_to p5 2'
        print('tostring(group+1):',tostring(math.floor(group+1)))
        local command = fixture_command_table[tostring(math.floor(group+1))]
        print("fixture_command:",fixture_command_table[tostring(math.floor(group+1))])

        local fixture = Device.getPlugin('fixture')
        local delimiter = paraTab.varSubAP()['delimiter'] or '\n'
        local lineTerminator = paraTab.varSubAP()['lineTerminator'] or '\r\n'
        print('fixture.isOpened():',fixture.isOpened())
        if fixture.isOpened()==0 then
            fixture.open(timeout) --load plugin已经初始化过插件配置，此处直接：open
        end   
        fixture.write(command)
        while true do
            local readResult = fixture.read(timeout,'\n')
            Log.LogInfo("readResultreadResult",readResult)
            local regexResult = string.match(readResult, '(pass)')
            Log.LogInfo("fixture_command_table regexResult:",regexResult)
            if regexResult then
                fixture.close()
                return true
            end
        end
    else
        return true
    end


end


function sendFunc.getUARTPlugin(uart)
    -- local uartPlugin = 'MCU1'
    -- if uart == 'MCU2' then
    --     uartPlugin = 'MCU2'
    -- elseif uart == 'Relay' then
    --     uartPlugin = 'Relay'   
    -- end        
    return Device.getPlugin(uart)
end 

function sendFunc.openPort(paraTab)
    function returnError()
        sendCommandAndResult = sendCommandAndResult .. os.date("%Y-%m-%d %H:%M:%S") .. "]( ==> Serial port opening failure"
        return false
    end
    function useFunction()
        return sendFunc.openUART(paraTab)
    end
    isOk,result = xpcall(useFunction,returnError)
    return result
end

function sendFunc.openUART(paraTab)
    print('kkkkkkkkkkRunning dut.openfixture')
    Log.LogInfo('Running dut.openfixture')
    -- print("")
    local uart = paraTab.varSubAP()['portName'] or 'dut'
    local timeout = paraTab.Timeout or 5       
    local dut = sendFunc.getUARTPlugin(uart)
    local delimiter = paraTab.varSubAP()['delimiter'] or '\n] \n] '
    local lineTerminator = paraTab.varSubAP()['lineTerminator'] or '\r\n'
    function useFunctionToOpen()
        if dut.isOpened()==0 then
            dut.open(3) --load plugin已经初始化过插件配置，此处直接：open
            if dut.isOpened()==1 then return true end
        else
            return true
        end
    end
    for i=1,tonumber(timeout) do
        local success, result = pcall(useFunctionToOpen)
        if success and result then
            break
        else
            print("Function encountered an error:", result)
        end
        os.execute('sleep 1')
    end    
    dut.setDelimiter(delimiter)
    dut.setLineTerminator(lineTerminator)
    local openResult=dut.isOpened()
    if openResult==1 then
        Log.LogInfo('Open serial port successfully')
        return true
    else
        Log.LogInfo('Open serial port failed')
        return false
    end
end

-- function sendFunc.sendDutCommand(paraTab)
--     local timeout = paraTab.Timeout or 5
--     local responseResult = ''
--     function excuteF()
--         responseResult = sendFunc.sendDutCommandInter(paraTab)
--     end
--     function errorF(err)
--         Log.LogInfo("------------Here is sendDutCommand Error-----------")
--         Log.LogInfo(err)
--         Log.LogInfo("------------Here is sendDutCommand Error End-----------")
--         responseResult = err
--     end
--     for i=0,tonumber(timeout) do
--         local commResult,commandResult = xpcall(excuteF,errorF)
--         print('commResult,responseResult:',commResult,responseResult)
--         if commResult == false then
--             pcall(sendFunc.closePort(paraTab))
--             pcall(sendFunc.openUART(paraTab))
--             print('sendcomand Error response:',responseResult)
--         else
--             print('sendcomand successfully response:',responseResult)
--             return responseResult
--         end
--         os.execute('sleep 0.5')

--     end
    
-- end
function getSlotNum(paraTab)

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

    if slotnumIndex == 10 then 
        slotnumIndex = "A"
    end

    return slotnumIndex
end


function sendFunc.sendDutCommand(paraTab)
    local uart = paraTab.varSubAP()['portName'] or 'dut'
    local command = paraTab.varSubCmd()
    -- Log.LogInfo('Running sendFunc.sendDutCommand')
    -- local uart = paraTab.varSubAP()['portName'] or 'dut'
    -- local command = paraTab.varSubCmd()
    -- local timeout = paraTab.Timeout or 5
    -- local dut = sendFunc.getUARTPlugin(uart)
    -- local delimiter = paraTab.varSubAP()['delimiter'] or '\n] \n] '
    -- local lineTerminator = paraTab.varSubAP()['lineTerminator'] or '\r\n'
    -- print('delimiter,lineTerminator---->',delimiter,lineTerminator)
    -- dut.setDelimiter(delimiter)
    -- dut.setLineTerminator(lineTerminator)
    -- if dut.isOpened()==0 then
    --     dut.open(3) --load plugin已经初始化过插件配置，此处直接：open
    -- end
    -- local response  = nil
    function excuteF(paraTab,i)
        Log.LogInfo('Running sendFunc.sendDutCommand')
        local uart = paraTab.varSubAP()['portName'] or 'dut'
        local command = paraTab.varSubCmd()
        
        local timeout = paraTab.Timeout or 3
        local dut = sendFunc.getUARTPlugin(uart)
        local delimiter = paraTab.varSubAP()['delimiter'] or '\n] \n] '
        local lineTerminator = paraTab.varSubAP()['lineTerminator'] or '\r\n'
        print('delimiter,lineTerminator---->',delimiter,lineTerminator)
        dut.setDelimiter(delimiter)
        dut.setLineTerminator(lineTerminator)
        print("dut.isOpened()--->",dut.isOpened())
        if dut.isOpened()==0 then
            print("zhqzhq isOpen ======")
            dut.open()
        end
        local response  = ''      
        if command == 'version' then
            dut.write(command)
            while true do
                local readResult = dut.read(timeout,'\n')
                Log.LogInfo("readResultreadResult",readResult)
                if readResult == nil then
                    break
                end
                response = response .. readResult
            end
        else
            if i == 3 then 
                if string.find(command,"audio") then
                    local audioCommandTable = {
                        "allen configure zor",
                        "audio config mic2 memory record 16kHz 768kHz 10",
                        "audio start 0",
                        "audio stop"
                    }
                    for i,v in ipairs(audioCommandTable) do
                        if v == command then
                            
                             break
                        end
                        local res = dut.send(v,4)
                        return_value = string.format('TX == >%s  RX == >%s',v,res)
                        print(return_value)
                    end
                end
                  
            end
            
            print('start dut.send(command,3)',command)
            response = dut.send(command,5)
            print('dut.send(command,3) ---response---',response)
            if response then
                return response
            else 
                return false
            end
        end
    end
    function errorF(err)
         Log.LogInfo('read data done!',err)
    end
    local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    -- response=excuteF()
    for i=0,tonumber(3) do
        status,response = xpcall(excuteF,errorF,paraTab,i)

       
        if status  then
            break
        end
    
        -- local data = {
        --     launch = "0",
        --     time = os.time()
        -- }
        -- -- 输出一个知道Document下面,launch.txt 一启动时0
        -- local filePath = "/Users/gdlocal/Documents/launch.json"
        -- write_to_json(data,filePath)

        
        -- local lauchConfig = json.decode(comFunc.fileRead(filePath))
        -- -- local kisPort = dutConfig.kiePort["Unit1"]
        -- local time = lauchConfig.time
        if i == 2 then
            print("start deal error ========")
            local slot_IndexNum = getSlotNum()
            local launchTimeCmd = "cat /Users/gdlocal/Documents/StartFlag.txt"
            local launchTime = executeAndWait(launchTimeCmd)
            launchTime =  launchTime:gsub("[\n%s]+", "")
            print("launchTime ==",launchTime)

            local getStartTimeCmd = "cat /Users/gdlocal/Documents/launchTime.txt"
            local startTime = executeAndWait(getStartTimeCmd)
            startTime =  startTime:gsub("[\n%s]+", "")
            print("startTime =====",startTime)

            while true do

                local currentTime = os.time()
                
                local timeSub = tonumber(currentTime) - tonumber(startTime)
                print("timeSub:",timeSub)

                local finishFlagCmd = "cat /Users/gdlocal/Documents/FinishFlag.txt"
                finishFlag = executeAndWait(finishFlagCmd)
                finishFlag =  startTime:gsub("[\n%s]+", "")

                local launchTimeCmd1 = "cat /Users/gdlocal/Documents/StartFlag.txt"
                local launchTime1 = executeAndWait(launchTimeCmd1)
                launchTime1 =  launchTime1:gsub("[\n%s]+", "")

                
                if tonumber(launchTime1) == 0 then
                    local FlagCmd = "echo 1 > /Users/gdlocal/Documents/StartFlag.txt"
                    os.execute(FlagCmd)
                end
                
            
                if timeSub > 40 and tonumber(launchTime) == 0 then

                    -- 发送END_ReTEST && RF_START_TEST
                    local End_Cmd1 = "cd /Users/gdlocal/Library/Atlas2/ScriptFile;/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/serialPortEnd_ReStart.py"
                    print("End_Cmd1 =====",End_Cmd1)
                    local End_Cmd1Res = executeAndWait(End_Cmd1)
                    print("End_Cmd1Res =====",End_Cmd1Res)

                    local cmdRFFinishCmd = "echo 1 > /Users/gdlocal/Documents/FinishFlag.txt"
                    os.execute(cmdRFFinishCmd)

                    local runGN_enableCMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/grassninja.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0".." -s on"
                    print("runGN_enableCMD ==",runGN_enableCMD)
                    local runGN_enableCMDRes = executeAndWait(runGN_enableCMD)
                    print("runGN_enableCMDRes ===",runGN_enableCMDRes)

                    os.execute("sleep 3")

                    break
                -- elseif (timeSub > 40 and tonumber(launchTime) == 1) or tonumber(finishFlag) == 1 then
                elseif tonumber(finishFlag) == 1 then

                    local runGN_enableCMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/grassninja.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0".." -s on"
                    print("runGN_enableCMD ==",runGN_enableCMD)
                    local runGN_enableCMDRes = executeAndWait(runGN_enableCMD)
                    print("runGN_enableCMDRes ===",runGN_enableCMDRes)

                    os.execute("sleep 3")
                    break
                elseif tonumber(launchTime) == 1 then
                    break
                end

                os.execute('sleep 0.5')
            end

        end
        

        
        


  

        -- local runPowerCycle_CMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_powerCycle.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0"
        -- print("runPowerCycle_CMD ==",runPowerCycle_CMD)
        -- local runPowerCycle_CMDRES = executeAndWait(runPowerCycle_CMD)
        -- print("runPowerCycle_CMDRES ===",runPowerCycle_CMDRES)

        -- os.execute("sleep 5")

        -- local runKisFWDL_CMDxxxx = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_init.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0"
        -- print("runKisFWDL_CMDxxxx ==",runKisFWDL_CMDxxxx)
        -- local fwdlResxxxx = executeAndWait(runKisFWDL_CMDxxxx)
        -- print("fwdlRes ===",fwdlResxxxx)

        -- local runKisFWDL_CMDxxxx = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_link.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0"
        -- print("runKisFWDL_CMDxxxx ==",runKisFWDL_CMDxxxx)
        -- local fwdlResxxxx = executeAndWait(runKisFWDL_CMDxxxx)
        -- print("fwdlRes ===",fwdlResxxxx)

        -- local runKisFWDL_CMDxxxx = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_kis_fwdl.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0".." -s off"
        -- print("runKisFWDL_CMDxxxx ==",runKisFWDL_CMDxxxx)
        -- local fwdlResxxxx = executeAndWait(runKisFWDL_CMDxxxx)
        -- print("fwdlRes ===",fwdlResxxxx)

        -- os.execute("sleep 5")


        -- local runKisFWDL_CMDxxxx = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/grassninja.py -p /dev/cu.usbserial-DUT"..slot_IndexNum.."0".." -s on"
        -- print("runKisFWDL_CMDxxxx ==",runKisFWDL_CMDxxxx)
        -- local fwdlResxxxx = executeAndWait(runKisFWDL_CMDxxxx)
        -- print("fwdlRes ===",fwdlResxxxx)

        -- os.execute("sleep 5")

        -- print("zhqzhq +++++++++")

        -- dut.open()
     
    end
    
    print('response......-->',response)
    -- xpcall(excuteF,errorF)
    local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,'SerialPort',response)
    if command == 'version' then
        return string.gsub(response,"\r\n",";"):sub(1,-2)
    else
        return response    
    end
end



function sendFunc.closePort(paraTab)
    print("start run closePort")
    function returnError()
        print("closePort ==========0")
        sendCommandAndResult = sendCommandAndResult .. os.date("%Y-%m-%d %H:%M:%S") .. "]( ==> Serial port close failure"
        return false
    end
    function useFunction()
        return sendFunc.closeUART(paraTab)
    end
    isOk,result = xpcall(useFunction,returnError)
    return result
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

function sendFunc.closeUART(paraTab)
    -- Log.LogInfo("closePort ==========1")
    -- local uart = paraTab.varSubAP()['portName'] or 'dut'
    -- local dut = sendFunc.getUARTPlugin(uart)
    -- Log.LogInfo("closePort ==========2",dut)
    -- if dut.isOpened()==1 then
    --     Log.LogInfo("closePort ==========3")
    --     dut.close()
        
    -- end 
    -- Log.LogInfo("closePort ==========5")
    -- -- dut.close()   
    -- return true
    local inputStr = paraTab.Input


    Log.LogInfo("closePort ==========1",inputStr)
    local uart = paraTab.varSubAP()['portName'] or 'dut'
    local dut = sendFunc.getUARTPlugin(uart)
    dut.setDelimiter("\n] \n] ")
    -- local status, ret = xpcall(dut.send, debug.traceback,"ft version",3)

    -- Log.LogInfo("closePort ==========2",ret)

    Log.LogInfo("closePort ==========3",dut)
    if dut.isOpened()==1 then
        Log.LogInfo("closePort ==========4")
        dut.close()
    else
        Log.LogInfo("closePort ==========5",inputStr)

        if tostring(inputStr) == "10" then
            inputStr = "A"
        end

        local runGN_CMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/grassninja.py -p /dev/cu.usbserial-DUT"..inputStr.."0".." -s off"
        print("runGN_CMD ==",runGN_CMD)
        -- os.execute(runGN_CMD)
        local res = executeAndWait(runGN_CMD)
        print("runGN_CMD ===",res)

    end 
    Log.LogInfo("closePort ==========6")
    local runGN_CMD = "cd /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja;/usr/local/bin/python3  /Users/gdlocal/Library/Atlas2/ScriptFile/Grassninja/gn_powerCycle.py -p /dev/cu.usbserial-DUT"..inputStr.."0"
    print("runGN_CMD ==",runGN_CMD)
    local res = executeAndWait(runGN_CMD)
    print("runGN_CMDRESSSS ===",res)
    -- dut.close()   
    return true
end

return sendFunc
