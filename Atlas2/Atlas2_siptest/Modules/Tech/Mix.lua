local Mix = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local file = require("Tech/DealWithFile")
local Universal = require("Tech/Universal")
local String = require("Tech/String")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
sendCommandAndResult = ""
function Mix.ping(paraTab)
    local pingIP = io.popen('ping -c 1 169.254.1.32') 
    local pingResult = pingIP:read("*all")
    conState = string.match(pingResult,'(%d)%s+packets received')
    if tostring(conState) == '0' then
        print("****** Can't ping to 169.254.1.32, please check the MIX contact status!******")
        return false
    else
        return true
    end
end

function Mix.initMix(paraTab)
    local IPAddress = "169.254.1.32"
    local IPport = 7801
    local MixRPC = Device.getPlugin("MixRPC")
    Log.LogInfo('IPAddress:',IPAddress)
    Log.LogInfo('IPport:',IPport)
    MixRPC.init(IPAddress,IPport)
    return true
end

function Mix.callRPCFunc(paraTab)
    local timeout = paraTab.Timeout or 5000
    local cmd = paraTab.varSubCmd()
    Log.LogInfo("***cmd***",cmd)
    local args = paraTab.varSubAP()['args'] or ''
    local paramList = nil
    if args ~='' then
        paramList = String.split(args,' ')
    end
    Log.LogInfo("***paramList***",paramList)
    local mixRPC = Device.getPlugin("MixRPC")
    assert(mixRPC ~= nil,"rpc_client not init")
    local realParamList = paramList or {}
    if #realParamList <= 0 then realParamList = nil end
    local realParamDic = {}
    if timeout == nil then error("timeout value is nil!") end
    realParamDic['timeout_ms'] = timeout
    Log.LogInfo('timeout******',realParamDic)
    local command = cmd .. ' '..args

    --get if excute the aid condition
    local aid = paraTab.varSubAP()['AID'] or ''  
    local response  = ''
    
    function sendCommandToMix(cmd,realParamList,realParamDic)
        response = mixRPC.rpc(cmd, realParamList, realParamDic)
    end
    function feedback(err)
        print('send command to mix error!!',err)
        response = err
    end

    --execute AID test item that repeat 3 times if get none value of AID
    if aid == "YES" then
        local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
        local commResult = xpcall(sendCommandToMix,feedback,"prmrelay.relay",{"AID_PATH","ENABLE_HSD1"},realParamDic)
        local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
        Universal.getCommandAndResult(cmd_start_time,cmd_end_time,"prmrelay.relay AID_PATH ENABLE_HSD1",'MixPRC',response)
        for i=1,3,1 do
            print("AID test repeat.."..tostring(i))
            local paramList = {
                -- ["prmrelay.relay-connect"]={"AID_PATH","ENABLE_HSD1"},
                ["aid_master_1.reset"]={},
                ["aid_master_1.disable_wake_detect"] = {},
                ["aid_master_1.send_ID"] = {"0xab;0xcd","6"}
                -- ,["prmrelay.relay-disconnect"]={"AID_PATH","DISCONNECT"}
            }
            local commandList = {
                -- "prmrelay.relay-connect",
                "aid_master_1.reset","aid_master_1.disable_wake_detect","aid_master_1.send_ID"
                -- ,"prmrelay.relay-disconnect"
            }
            for key in pairs(commandList) do
                cmd = commandList[key]
                print("commandList[key]"..cmd)
                if cmd == "prmrelay.relay-connect" or cmd == "prmrelay.relay-disconnect" then
                    cmd = "prmrelay.relay"
                end               
                args = " "
                for keyPara in pairs(paramList[commandList[key]]) do
                    args = args.." "..paramList[commandList[key]][keyPara]
                end
                realParamList = paramList[commandList[key]]
                command = cmd .. ' '..args
                local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
                local commResult = xpcall(sendCommandToMix,feedback,cmd,realParamList,realParamDic)
                local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
                Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,'MixPRC',response)
                --if got the value of aid
                if response == "0x75,0x00,0x02,0x00,0x00,0x00,0x00,0x9f" then
                    isGetAid = response 
                end
                os.execute('sleep 0.1')
            end
            if isGetAid then 
                local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
                local commResult = xpcall(sendCommandToMix,feedback,"prmrelay.relay",{"AID_PATH","DISCONNECT"},realParamDic)
                local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
                Universal.getCommandAndResult(cmd_start_time,cmd_end_time,"prmrelay.relay AID_PATH DISCONNECT",'MixPRC',response)
                return isGetAid
             end
        end
        local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
        local commResult = xpcall(sendCommandToMix,feedback,"prmrelay.relay",{"AID_PATH","DISCONNECT"},realParamDic)
        local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
        Universal.getCommandAndResult(cmd_start_time,cmd_end_time,"prmrelay.relay AID_PATH DISCONNECT",'MixPRC',response)
        return false

    end
    
    local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    local commResult = xpcall(sendCommandToMix,feedback,cmd,realParamList,realParamDic)
    local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,'MixPRC',response)


    if commResult == false or string.match(response,'missing') or string.match(response,'--FAIL--') or response == nil then
        return false
    end
    return response 
end


function Mix.close(paraTab)
    print('Test end!')
end
function Mix.start(paraTab)
    print('Test start!')
end

return Mix


