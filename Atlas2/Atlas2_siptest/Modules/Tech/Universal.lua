local Universal = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local file = require("Tech/DealWithFile")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
local plist2lua = require("Matchbox/plist2lua")
local String = require("Tech/String")
function Universal.getSlotIndex(paraTab)
    url = Device.transport
    Log.LogInfo("**************",url)
    local workingDirectory = Device.userDirectory
    Log.LogInfo("workingDirectory...",workingDirectory)
    local resp = string.match(workingDirectory, "group%d+%-(%d+)")
    Log.LogInfo("Slot index is:", resp)
    if resp then
        return resp
    else
        return false
    end
end
function Universal.getGroupIndex(paraTab)
    -- os.execute('sleep 50')
    url = Device.transport
    Log.LogInfo("**************",url)
    local workingDirectory = Device.userDirectory
    Log.LogInfo("workingDirectory...",workingDirectory)
    local resp = string.match(workingDirectory, "group(%d+)%-%d+")
    Log.LogInfo("Group index is:", resp)
    if resp then
        return resp
    else
        return false
    end
end
function fileExists(filename)
    local file = io.open(filename, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function Universal.processGroupTxt(paraTab)
    
    local configPath = string.gsub(Atlas.assetsPath, "Assets", "Config")
    if comFunc.fileExists(configPath .. "/station.plist") then
        local stationConfig = plist2lua.read(configPath .. "/station.plist")
        group_num = tonumber(stationConfig.GroupConfig.Instances)
        slot_num = #stationConfig.GroupConfig.SlotConfig
        print(string.format('processGroupTxt group_num:%d--slot_num:%d',group_num,slot_num))
    else
        error("*****processGroupTxt The staition.plist file not found***")
    end

    local groupIndex = tostring(tonumber(paraTab.Input)+1)
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
function Universal.getTempInter(paraTab)
    local temp = Atlas.loadPlugin("Temp")
    local dev = io.popen('ls /dev')
    local devstr = dev:read("*all")
    local temperature = string.match(devstr,"cu%.usbserial%-%w+")
    local initPortResult = temp.initPort("/dev/"..temperature,"9600")
    local pvTemp = string.match(initPortResult,"pvFloat%s=%s(.-),")
    if pvTemp == nil then
        pvTemp = false
    end    
    print('The temperature is: ',pvTemp)
    return pvTemp
end
function Universal.getTemp(paraTab)
   local result = false
    function excuteF()
        result = Universal.getTempInter(paraTab)
    end
    function errorF(err)
        print('getTempInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end
function Universal.changeValueFailOrPass(paraTab)
    local inputs = paraTab.InputValues
    local result = true
    if #inputs == 0 then
        result = false
    end
    for key,value in pairs(inputs) do
        print('Enter value one of them is:',value)
        result = result and value
    end
    print('the test result is:',result)
    return result
end

function Universal.getStationNameAndVersion(paraTab)
    local stationPlist = string.gsub(Atlas.assetsPath, "Assets", "Config")
    local stationPlistFile = plist2lua.read(stationPlist .. "/station.plist")
    local stationVersion = stationPlistFile.StationVersion
    local stationName = stationPlistFile.StationName
    return stationVersion,stationName
end

function Universal.getStationID(paraTab)
	local StationInfo = Atlas.loadPlugin("StationInfo")
    local stationId = StationInfo.station_id()
    print("stationId --> ",stationId)
    local lineName = string.match(stationId,".+%-(%a+)")
    if lineName == nil then return 'MAIN' end
    return lineName
end

function Universal.runPython(paraTab)
    local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    local audioName = paraTab.varSubAP()['audioName'] or 'None'
    local version = paraTab.varSubAP()['pyVersion']
    local filePath = paraTab.varSubAP()['pyPath']
    local command = version..' '..filePath..' '..audioName
    print('cmd****',command)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local runResult = RunShellCommand.run(command)
    local outputPy = runResult.output
    Log.LogInfo("runResult****",runResult)
    Log.LogInfo("outputPy****",outputPy)
    Log.LogInfo("runResult.error****",runResult.error)
    local result = ""
    if tostring(runResult.returnCode) ~= '0' then
        result = false
    else
        result = outputPy
    end
    local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,'MixPRC',result)
    return result  
end

function Universal.sleep(paraTab)
    local time = paraTab.varSubCmd()
    local command = "sleep " .. tonumber(time)
    local cmd_start_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    local response = os.execute(command)
    local cmd_end_time = os.date("%Y-%m-%d %H:%M:%S").."("..Universal.getTimeMs()..")"
    Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,'MixPRC',response)  
end
function Universal.getUserName(paraTab)
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    return userName
end
function Universal.getTimeMs(paraTab)
    local popup = Device.getPlugin("Popup")
    local timeNow = popup.getTime()
    return timeNow
end

function Universal.Compare(paraTab)
    local inputs = paraTab.InputValues
    if inputs[1] == inputs[2] then
        return true
    else
        print(#(inputs[1]),#(inputs[2]))
        print("IMSN --> ",inputs[1])
        print("audio_board -->",inputs[2])
        return false
    end
end

function Universal.andCalInter(paraTab)
    local tmp1 = paraTab.Input
    local tmp2 = 191
    local str = ""
    repeat
        local s1 = tmp1 % 2
        local s2 = tmp2 % 2
        if s1 == s2 then
            if s1 == 1 then
                str = "1"..str
            else
                str = "0"..str
            end
        else
            str = "0"..str
        end
        tmp1 = math.modf(tmp1/2)
        tmp2 = math.modf(tmp2/2)
    until(tmp1 == 0 and tmp2 == 0)
    return tonumber(str,2)
end

function Universal.andCal(paraTab)
   local result = false
    function excuteF()
        result = Universal.andCalInter(paraTab)
    end
    function errorF(err)
        print('andCal fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function Universal.zeroOutInter(paraTab)
    local mixRPC = Device.getPlugin("MixRPC")
    local realParamList = {}
    local zone = tonumber(paraTab.varSubAP()["zone"]) or "7"
    local startAddress = tonumber(paraTab.varSubAP()["startAddress"])
    local endAddress = tonumber(paraTab.varSubAP()["endAddress"])
    local num = tonumber(string.match((endAddress-startAddress)/64,"%w+"))
    local remainder = (endAddress-startAddress)%64+1
    local readCmd = nil
    local args = nil
    local side = paraTab.Input  
    if side:upper() == 'LEFT' then
        readCmd = 'trinary1.read_zone_7'
        if tonumber(endAddress) > 383 then readCmd = 'trinary1.read_cfg' end
    elseif side:upper() == 'RIGHT' then
        readCmd = 'trinary2.read_zone_7'
        if tonumber(endAddress) > 383 then readCmd = 'trinary2.read_cfg' end
    else
        print("Error:Can't get the side info of RIGHT or LEFT, so can't choose the trinary1.read_cfg or trinary2.read_cfg command!!")
        return false    
    end
    local realParamDic = {}
    realParamDic['timeout_ms'] = 15000
    Log.LogInfo('timeout******',realParamDic)
    local result = true
    if endAddress-startAddress >= 64 then
        for i=0,num-1 do
            args = zone.." "..(tonumber(startAddress)+(64*i)).." 64"
            if sendCommandAndResult then
                sendCommandAndResult = sendCommandAndResult..'\n'..os.date("%Y-%m-%d %H:%M:%S") .. "](TX ==> " .. readCmd .." "..args.."\n"
            else
                sendCommandAndResult = sendCommandAndResult..os.date("%Y-%m-%d %H:%M:%S") .. "](TX ==> " .. readCmd .." "..args.."\n"
            end
            readResponse = mixRPC.rpc(readCmd, {tonumber(zone),(tonumber(startAddress)+(64*i)),64}, realParamDic)
            Log.LogInfo("[MixPRC] [Read] cmd="..readCmd..", response="..tostring(readResponse)..", i="..tostring(i))
            sendCommandAndResult = sendCommandAndResult..os.date("%Y-%m-%d %H:%M:%S") .. "](RX ==> " .. "startAddress: " .. (tonumber(startAddress)+(64*i)).. " endAddress: "  .. (tonumber(startAddress)+(64*(i+1)-1)).." ".. readResponse .."\n"
            if #(String.gmatch(readResponse,"0x00")) ~= 64 then 
                return false
            end
        end
    end
    if remainder ~= 0  then
        args = zone.." "..(tonumber(startAddress)+(64*num)).." "..remainder
        if sendCommandAndResult then
            sendCommandAndResult = sendCommandAndResult..'\n'..os.date("%Y-%m-%d %H:%M:%S") .. "](TX ==> " .. readCmd .." "..args.."\n"
        else
            sendCommandAndResult = sendCommandAndResult..os.date("%Y-%m-%d %H:%M:%S") .. "](TX ==> " .. readCmd .." "..args.."\n"
        end
        readResponse = mixRPC.rpc(readCmd, {tonumber(zone),(tonumber(startAddress)+(64*num)),remainder}, realParamDic)
        sendCommandAndResult = sendCommandAndResult..os.date("%Y-%m-%d %H:%M:%S") .. "](RX ==> " .. "startAddress: " .. (tonumber(startAddress)+(64*num)).. " endAddress: "  .. (tonumber(startAddress)+(64*(num)+remainder-1)).." ".. readResponse .."\n"
        Log.LogInfo("[MixPRC] [Read] cmd="..readCmd..", response="..tostring(readResponse)..", num="..tostring(num))
        if #(String.gmatch(readResponse,"0x00")) ~= remainder then 
            return false
        end
    end
    return result
end
function Universal.zeroOut(paraTab)
   local result = false
    function excuteF()
        result = Universal.zeroOutInter(paraTab)
    end
    function errorF(err)
        print('zeroOutInter fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function Universal.switch_bool_to_YES_NO(paraTab)
    local input = paraTab.Input 
    local result = "NO"
    if input == "PASS" or input == true then
        result = "YES"
    elseif input == "error" then
        result = "FALSE"
    end
    return result
end

function Universal.switch_bool_to_PASS_FAIL(paraTab)
    local input = paraTab.Input 
    local result = "FAIL"
    if input == "PASS" or input == true then
        result = "PASS"
    else
        result = "FAIL"
    end
    return result
end

function Universal.checkRecord(paraTab)
    local input = paraTab.Input
    local testname = paraTab.TestName or ' '
    if input == false then
        error("perform "..testname.." error")
    end
end

function Universal.judgeLimitType(paraTab)
    local config = paraTab.Input
    local result = "Normal"
    if config == "G-DFM02-L" or config == "G-DFM03-L" then
        return config
    end
    return result
end

function Universal.checkTestCountResult(paraTab)
    local result = paraTab.Input
    if result then
        print('Test pass')
    else
        local str = 'Please change the A301 cable!'
        local buttonName = paraTab.AdditionalParameters["ButtonName"] or 'OK'
        local popup = Device.getPlugin("Popup")
        local useAlert = popup.alert(tostring(str),buttonName)
        while true 
            do
                os.execute("sleep 0.5")
                alertStatus = popup.queryAlert()
                if alertStatus == 0 then
                    break
                end
        end
        error('Need to change the A301 cable!')
    end
end

function Universal.checkUOP(paraTab)
    log.LogInfo("******Start checkUOP******")
    local sn = paraTab.Input
    local ghJson = json.decode(comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json"))
    local UopStatus = ghJson.ghinfo.SFC_QUERY_UNIT_ON_OFF
    local BobCatUrl = ghJson.ghinfo.SFC_URL
    local stationId = ghJson.ghinfo.STATION_ID
    local cmd = "curl -d \"c=QUERY_RECORD&tsid="..stationId.."&p=unit_process_check&sn="..sn.."\" "..BobCatUrl
    if UopStatus == "ON" then
        local uopReturn = RunShellCommand.run(cmd)
        log.LogInfo("***********uopReturn",uopReturn)
        local returnStatus = string.match(uopReturn.output,".-unit_process_check=(OK)")
        log.LogInfo("***********returnStatus",returnStatus)
        if returnStatus == "OK" then
            return true
            -- libRecord.createRecord(true, testname, subtestname, subsubtestname, limit, failMsg)
        else
            returnStatus,rebackStation = string.match(uopReturn.output,".*unit_process_check=([%w%s]+)%[.*(PLEASE.*)")
            if returnStatus ==nil then
                returnStatus,rebackStation = string.match(uopReturn.output,".-unit_process_check=([%w%s]+)(.+)")
            end
            -- returnStatus,rebackStation = string.match(uopReturn.output,".-unit_process_check=([%w%s]+)(.+)")
            log.LogInfo("***********returnStatus,rebackStation",returnStatus,rebackStation)
            local str = returnStatus..rebackStation
            log.LogInfo("***********returnStatus++++++rebackStation",str)
            local popup = Device.getPlugin("Popup")
            local useAlert = popup.alert(tostring(str),"OK")
            while true
                do
                    os.execute("sleep 0.5")
                    alertStatus = popup.queryAlert()
                    if alertStatus == 0 then
                        break
                    end
            end
            print("*******UOP fail ********"..tostring(str))
            -- DataReporting.primaryIdentity(sn)
            return false
        end
    else
        log.LogInfo('********UOP status is OFF skip the test.**********')
        return true

    end

end
function Universal.check(path)
    file,err=io.open(path)
    new_path = path
    if err == nil then
        -- path = string.sub(path,1,-2)..(tostring(string.sub(path,-1,-1)+1))
        new_path = Universal.check(string.sub(path,1,-2)..(tostring(tonumber(string.sub(path,-1,-1))+1))) 
    end
    return new_path
end
function Universal.removeWav(paraTab)
    local user = os.execute('rm -rf '..'/Users/gdlocal/Documents/Python/wav')
end
function Universal.writeTem(paraTab)
    local tmp = paraTab.Input
    local fileName = paraTab.varSubAP()['fileName']
    os.execute('mkdir '..'/Users/gdlocal/Documents/Python/wav')
    local checkPath = '/Users/gdlocal/Documents/Python/wav/'..fileName
    print(checkPath)
    local path = Universal.check(checkPath)
    print('echo '..tostring(tmp) ..'>>' ..path)
    os.execute('echo '..tostring(tmp) ..'>>' ..path)
end
function Universal.getStationName()
    local StationInfo = Atlas.loadPlugin("StationInfo")
    local stationID = StationInfo.station_id()
    local stationName = stationID:match(".+_([%w%-]+)")
    print('stationName****',stationName)
    return stationName
    end
function Universal.moveWav(paraTab)
    local stationName = Universal.getStationName()
    local side = nil
    if stationName == 'QT1' or stationName == 'SA-QT1' then
        side = 'LEFT'
    else
        side = 'RIGHT'
    end
    local LuaFilePath = string.gsub(Atlas.assetsPath, "Assets", "Lua")
    local RDCLuaPath = LuaFilePath ..'/Main_RDC_Cal_NEW.lua'
    os.execute('rm -rf '..'/Users/Shared/work/b443/RDC_processing/wav')
    os.execute('cp -rf '..'/Users/gdlocal/Documents/Python/wav '..'/Users/Shared/work/b443/RDC_processing')
    os.execute('/Users/Shared/torch/install/bin/th '..RDCLuaPath.. ' /Users/Shared/work/b443/RDC_processing/wav '..side)
end
function Universal.getJson(path)
    local file = io.open(path,'r')
    if file == nil then
        return false
    end    
    local con = file:read("*a")
    local json_content_list = String.split(con,'},')
    local table_items = {}
    for key,value in pairs(json_content_list) do
        local value = string.gsub(value,'%[%{','')
        value = string.gsub(value,'%{','')  
        value = string.gsub(value,'%}%]','')
        value = string.gsub(value,'%}','')
        table_items[key] = value
    end
    return table_items
end
function Universal.writeLog(testname,subsubtestname,units,result,limit,sendCommandAndResult)
    local CreateRecord = require("Tech/CreateRecord")
    local _table = {}
    local testEndTime = Universal.getTimeMs()
    _table.sendCommandAndResult = sendCommandAndResult
    _table.testName = testname
    _table.subsubtestname = subsubtestname
    _table.units = units
    _table.status = 0
    if result == true then
        _table.value = "PASS"
    elseif result == false then
        _table.value = "FAIL"
        _table.status = 1
    else
        if result then
            _table.value = result
        else
            _table.value = result
            _table.status = 1
        end
    end
    if limit then
        if limit.upperLimit == "" or limit.upperLimit == nil then _table.upLimit="NA" else _table.upLimit=limit.upperLimit or "NA" end
        if limit.lowerLimit == "" or limit.lowerLimit == nil then _table.downLimit="NA" else _table.downLimit=limit.lowerLimit or "NA" end
        if limit.units == "" or limit.units == nil then _table.unit="NA" else _table.unit = limit.units or "NA" end
    else
        _table.upLimit="NA"
        _table.downLimit="NA"
        _table.unit="NA"
    end
    _table.failureMsg = failMsg or ""
    _table.testTime = testEndTime - testStartTime
    CreateRecord.createWriteLog(_table)
    CreateRecord.writeCsv(_table)
    testStartTime = Universal.getTimeMs()
end
function Universal.createJsonRecordInter(paraTab)
    local path = '/Users/Shared/work/b443/RDC_processing/wav/records.json'
    local items_table = Universal.getJson(path)
    if items_table == false then
        return false
    end    
    local testname = paraTab.Technology
    local subtestname = paraTab.TestName
    local result = true
    for key,value in pairs(items_table) do
        -- local testStartTime = Universal.getTimeMs()
        local limit = {}
        local units = value:match('%"units%"%:%"(.-)%"')
        local result = value:match('%"measurement%"%:(.-)%,')
        local subsubtestname = value:match('%"name%"%:%"(.-)%"')
        limit.units = units
        limit.ParameterName = subsubtestname
        limit.TestName = subtestname
        if subsubtestname:match("(RDCCAL_TWEETER_ITER%d_RDC)") or subsubtestname:match("(RDCCAL_TWEETER_RDC_avg)") then
            limit.lowerLimit = 6
            limit.upperLimit = 10
        elseif subsubtestname:match("(RDCCAL_WOOFER_ITER%d_RDC)") or subsubtestname:match("(RDCCAL_WOOFER_RDC_avg)") then
            limit.lowerLimit = 6.5
            limit.upperLimit = 10
        end
        if units == nil or result == nil or subtestname == nil then result = false end
        if (result == true or result == false) then
            createRecordResult = libRecord.createBinaryRecord(result, testname, subtestname, subsubtestname, nil)
        else
            createRecordResult = libRecord.createRecord(result, testname, subtestname, subsubtestname, limit, failMsg)
        end
        local sendCommandAndResult = ''
        Universal.writeLog(testname,subsubtestname,units,result,limit,sendCommandAndResult)
    end
    return result
end

function Universal.createJsonRecord(paraTab)
    local result = false
    function excuteF()
        result = Universal.createJsonRecordInter(paraTab)
    end
    function errorF(err)
        print('createJsonRecord fail',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function Universal.getSyscfgInter(paraTab)
    local sysCfgPath = '/Users/Shared/work/b443/RDC_processing/wav/syscfg.log'
    Log.LogInfo('sysCfgPath******',sysCfgPath)
    local file = io.open(sysCfgPath,'r')
    if file == nil then
        return false
    end    
    local con = file:read("*a")
    local sysCfgList = String.split(con,' ')
    local sysCfg = ''
    
    for i=1,50 do
        if i == 50 then
            sysCfg = sysCfg..'0x'..sysCfgList[i]
        else
            sysCfg = sysCfg..'0x'..sysCfgList[i]..' '
        end
    end
    Log.LogInfo('sysCfg******',sysCfg)

    return sysCfg
end
function Universal.getSyscfg(paraTab)
    local result = false
    function excuteF()
        result = Universal.getSyscfgInter(paraTab)
    end
    function errorF(err)
        print('getSyscfg fail',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end
function Universal.compare_syscfg_to_readzone7Inter(paraTab)
    local inputs = paraTab.InputValues
    local result = false
    local sysCfg = inputs[1]
    local readZone7 = inputs[2]
    local readZone7String = ''
    local temptab = {}
    temptab = String.gmatch(readZone7,"%w+")
    for i,v in ipairs(temptab) do
        if i == 50 then
            readZone7String = readZone7String..v
        else
            readZone7String = readZone7String..v..' '
        end
    end
    Log.LogInfo('compare_syscfg_to_readzone7Inter****** ',sysCfg)
    Log.LogInfo('compare_syscfg_to_readzone7Inter****** ',readZone7String)
    
    if sysCfg == readZone7String then 
        return true
    end

    return result
end
function Universal.compare_syscfg_to_readzone7(paraTab)
    local result = false
    function excuteF()
        result = Universal.compare_syscfg_to_readzone7Inter(paraTab)
    end
    function errorF(err)
        print('compare_syscfg_to_readzone7 fail',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function Universal.moveWavToUser(paraTab)
    function checkPath(path)
        file,err=io.open(path)
        new_path = path
        if err == nil then
            -- path = string.sub(path,1,-2)..(tostring(string.sub(path,-1,-1)+1))
            new_path = checkPath(string.sub(path,1,-5)..(tostring(tonumber(string.sub(path,-4,-3))+5))..'Hz') 
        end
        return new_path
    end
    local goalPath = checkPath(Device.userDirectory ..'/wav_20Hz')
    -- local suffixHzTable = {'_20Hz','_25Hz','_30Hz','_35Hz','_40Hz','_45Hz','_50Hz'}
    -- local index = string.sub(goalPath,-1,#goalPath)
    -- local suffixHz = suffixHzTable[tonumber(index)]
    -- local goalPath = string.sub(goalPath,1,#goalPath-1)..suffixHz
    os.execute('cp -rf '..'/Users/Shared/work/b443/RDC_processing/wav '..goalPath)
end
function Universal.GetCheckSumHexString(InputString)
    local sum = 0
    print('InputString: ' .. InputString)
    for byteHex in string.gmatch(InputString, "0x(%S+)") do
        print("byteHex: " .. byteHex)
        sum = sum + tonumber(byteHex, 16)
        -- PrintString("sum: " .. sum)
    end
    local checkSumString = string.format("%04X", 65536 - (sum % 65536))
    return string.format("%s %s", string.sub(checkSumString, 3, 4), string.sub(checkSumString, 1, 2))
end

function Universal.readAudioCalInter(paraTab)
    local readZone7String = ""
    local inputs = paraTab.InputValues
    if inputs[2] then 
        readZone7String = inputs[1] .. " " .. inputs[2] 
    else
        readZone7String = paraTab.Input
    end
    -- readZone7String = paraTab.Input
    checkSumTable = {}
    checkSumTable = String.gmatch(readZone7String,'%w+')
    for i,v in ipairs(checkSumTable) do
        print("The value of checkSumTable is: "..v)
    end
    checkSumString = table.concat(checkSumTable, " ", 1, #checkSumTable-2)
    print('The values without cal value checkSumString is: ',checkSumString)
    checksum = Universal.GetCheckSumHexString(checkSumString)
    print('Calculate checksum result is: '..checksum)
    checksumResultRead = table.concat(checkSumTable, " ", #checkSumTable-1, #checkSumTable)
    deleteHead = {}
    for hex in string.gmatch(checksumResultRead, "0x(%S+)") do 
        table.insert(deleteHead,hex)
    end
    checksumResult = table.concat(deleteHead,' ')
    print('The checksumResult from unit is: '..checksumResult)
    if checksum ~= checksumResult then checksumResult = false end
    return checksumResult
end
function Universal.readAudioCal(paraTab)
    local result = false
    function excuteF()
        result = Universal.readAudioCalInter(paraTab)
    end
    function errorF(err)
        print('readAudioCal fail',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

function Universal.getCommandAndResult(cmd_start_time,cmd_end_time,command,typeTrans,response)
        if sendCommandAndResult then
            sendCommandAndResult = sendCommandAndResult..'\n'..cmd_start_time .. "](TX ==> " .. command .."\n"
        else
            sendCommandAndResult = sendCommandAndResult..cmd_start_time .. "](TX ==> " .. command .."\n"
        end
        if type(response) == "table" then
            Log.LogInfo(string.format("[%s] [READ] cmd="..command..", response="..ComFunc.dump(response),typeTrans))
            sendCommandAndResult = sendCommandAndResult .. cmd_end_time .. "](RX ==> " .. ComFunc.dump(response) 
        else
            Log.LogInfo(string.format("[%s] [READ] cmd="..command..", response="..tostring(response),typeTrans))
            sendCommandAndResult = sendCommandAndResult .. cmd_end_time .. "](RX ==> " .. tostring(response)
        end   
end

function Universal.calculateRDC(paraTab)
    local inputs = paraTab.InputValues
    local imon_dBFS = inputs[1]
    local vmon_dBFS = inputs[2]
    local IMON_LEVEL = (10^(imon_dBFS/20))
    local VMON_LEVEL = (10^(vmon_dBFS/20))
    local Irms = 3.75*IMON_LEVEL/math.sqrt(2)
    local Vrms = 14*VMON_LEVEL/math.sqrt(2)
    local RDC = Vrms/Irms
    return RDC
end

return Universal


