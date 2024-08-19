local CreateRecord = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local Universal = require 'Tech/Universal'
local String = require("Tech/String")
testStartTime = Universal.getTimeMs()
FinalTestResult = ''
function CreateRecord.createRecord(paraTab)  
    local testResult = {}
    local subsubtestname = comFunc.trim(paraTab.varSubAP()["subsubtestname"])
    local result = paraTab.Input
    if result == nil or result == 'inf' then
        result =''
    elseif result == 'true' or result == 'false' then
        result = result == 'true'    
    end
    if subsubtestname == nil then subsubtestname = '' end
    Device.updateProgress(subsubtestname)
    local failMsg = comFunc.trim(paraTab.AdditionalParameters.failMsg)
    local limit = nil
    local testname = paraTab.Technology     
    local subtestname = paraTab.TestName .. paraTab.testNameSuffix
    if paraTab.isLimitApplied and paraTab.limit and paraTab.limit[subsubtestname] then
        limit = paraTab.limit[subsubtestname]        
    end 
    if (result == true or result == false) then
        createRecordResult = libRecord.createBinaryRecord(result, testname, subtestname, subsubtestname, nil)
    else
        createRecordResult = libRecord.createRecord(result, testname, subtestname, subsubtestname, limit, failMsg)
    end 
    local testEndTime = Universal.getTimeMs()
    testResult.Technology = paraTab.Technology
    print('testResult.testName-->',testResult.testName)
    testResult.testName = paraTab.TestName
    testResult.subsubtestname = subsubtestname
    testResult.status = 0
    testResult.failureMsg = ""
    local returnResultValue = true
    if result == true then
        testResult.value = "PASS"
        FinalTestResult = 'PASS'
    elseif result == false then
        testResult.failureMsg = failMsg or ""
        testResult.value = "FAIL"
        testResult.status = 1
        FinalTestResult = 'FAIL'
        returnResultValue = false
    else
        if createRecordResult then
            testResult.value = result
            FinalTestResult = 'PASS'
        else
            testResult.failureMsg = failMsg or ""
            testResult.value = result
            testResult.status = 1
            FinalTestResult = 'FAIL'
        end
    end
    if limit then
        if limit.upperLimit == "" then testResult.upLimit="NA" else testResult.upLimit=limit.upperLimit or "NA" end
        if limit.lowerLimit == "" then testResult.downLimit="NA" else testResult.downLimit=limit.lowerLimit or "NA" end
        if limit.units == "" then testResult.unit="NA" else testResult.unit = limit.units or "NA" end
        if limit.units == 'string' then 
            testResult.downLimit = 'No lowerLimit'
            testResult.upLimit = string.gsub(limit.upperLimit,';',' or ')
        end
    else
        testResult.upLimit="NA"
        testResult.downLimit="NA"
        testResult.unit="NA"
    end
    testResult.testTime = testEndTime - testStartTime
    testResult.sendCommandAndResult = sendCommandAndResult
    CreateRecord.createWriteLog(testResult)
    CreateRecord.writeCsv(testResult)
    sendCommandAndResult = ''
    testStartTime = Universal.getTimeMs()
    Device.updateProgress(subtestname)
    return returnResultValue
end

function CreateRecord.createWriteLog(_table)
    local uartLogPath = Device.userDirectory.."/test.txt"
    local itemCountPath = Device.userDirectory.."/ItemCount.txt"
    local ItemCount = 1
    local testName = _table.testName
    local subsubtestname = _table.subsubtestname
    local defName = ""
    if #subsubtestname ~= 0 and testName ~= subsubtestname then 
        defName = testName..'_'..subsubtestname
    else
        defName = testName
    end
    local downLimit = _table.downLimit
    local upLimit = _table.upLimit
    local UarttestResult = _table.value
    local testTime = _table.testTime
    local sendCommandAndResult = _table.sendCommandAndResult
    itemCountFile = io.open(itemCountPath, "r")
    if itemCountFile ~= nil then
        io.input(itemCountFile)
    -- 输出文件第一行
        readContent = String.split(io.read(),',')
        ItemCount = tonumber(readContent[1])
        if readContent[2] == 'FAIL' then
            FinalTestResult = 'FAIL'
        end
    end
    uargLogFile,err = io.open(uartLogPath,"a")
    uargLogFile:write("=========Item " .. ItemCount .. ": " .. defName .."==========================\n")
    uargLogFile:write(sendCommandAndResult .. "\n")
    uargLogFile:write("Test Name: [" .. testName .. "]".. "\n")
    uargLogFile:write("Test Spec: [" .. downLimit .."," .. upLimit .. "]".. "\n")

    uargLogFile:write("Test Value: [" .. UarttestResult .. "]".. "\n")
    uargLogFile:write("Overall Test Time: [" .. testTime .. "]".. "\n")
    uargLogFile:write("==================================================================================".. "\n")
    uargLogFile:close()
    itemCountFile = io.open(itemCountPath, "w")
    io.output(itemCountFile)
    io.write(tostring(ItemCount + 1)..','..FinalTestResult)
    itemCountFile:close()
end

function CreateRecord.writeCsv(_table)
    local technology = _table.Technology
    local testName = _table.testName
    local subsubtestname = _table.subsubtestname
    local defName = ""
    -- if #subsubtestname ~= 0 and testName ~= subsubtestname then 
    if #subsubtestname ~= 0 then 
        defName = technology..'@'..testName..'_'..subsubtestname
    else
        defName = technology..'@'..testName
    end
    local status = _table.status
    local value = _table.value
    local downLimit = _table.downLimit
    local upLimit = _table.upLimit
    local unit = _table.unit
    local testTime = _table.testTime
    local failureMsg = _table.failureMsg
    local StationInfo = Atlas.loadPlugin("StationInfo")
    stationVersion,stationName = Universal.getStationNameAndVersion()
    local uartLogPath = Device.userDirectory.."/test.csv"
    local file = io.open(uartLogPath, "r")
    if file ~= nil then
        file:close()
        local uartLogCSV = io.open(uartLogPath, "a")
        local cmd = '\"'..defName..'\"'..","..status..","..'\"'..value..'\"'..","..downLimit..","..upLimit..","..unit..","..testTime..","..'\"'..failureMsg..'\"'
        uartLogCSV:write(cmd..'\n')
        uartLogCSV:close()
    else
        local uartLogCSV = io.open(uartLogPath, "a")
        local title = 'TestName'..','..'Status'..','..'Value'..','..'DownLimit'..','..'Uplimit'..','..'Unit'..','..'TestTime'..','..'FailedSubItem'
        local tsp = 'TSP'..','..'0'..','..StationInfo.station_id()
        local overlay = 'Overlay_version'..','..'0'..','..stationVersion
        uartLogCSV:write(title..'\n')
        uartLogCSV:write(tsp..'\n')
        uartLogCSV:write(overlay..'\n')
        local cmd = '\"'..defName..'\"'..","..status..","..'\"'..value..'\"'..","..downLimit..","..upLimit..","..unit..","..testTime..","..'\"'..failureMsg..'\"'
        uartLogCSV:write(cmd..'\n')
        uartLogCSV:close()
    end
end
function CreateRecord.renameLog(paraTab)
    local dutSN =  paraTab.Input or 'None'
    local oldUartFileName = Device.userDirectory.."/test.txt"
    local oldCsvFileName = Device.userDirectory.."/test.csv"
    local itemCountFile = io.open(Device.userDirectory.."/ItemCount.txt", "r")
    local testResult = ''
    if itemCountFile ~= nil then
        io.input(itemCountFile)
        readContent = String.split(io.read(),',')
        testResult = readContent[2]
    end
    local newUartFileName = Device.userDirectory.."/"..testResult..'_'..dutSN.."_"..os.date("%Y%m%d%H%M%S")..".txt"
    local newCsvFileName = Device.userDirectory.."/"..testResult..'_'..dutSN.."_"..os.date("%Y%m%d%H%M%S")..".csv"

    os.rename(oldUartFileName,newUartFileName)
    os.rename(oldCsvFileName,newCsvFileName)
    os.execute('rm -f ' ..Device.userDirectory.."/ItemCount.txt")
    --os.execute('cp -rf '..'/Users/Shared/work/b443/RDC_processing/wav '..Device.userDirectory)
    print("start upload log to insight ======")
    Archive.addPathName(Device.userDirectory,Archive.when.deviceFinish)
    print('Device.userDirectory----:'..Device.userDirectory)
    device_path = string.gsub(Device.userDirectory, "user", "system")

    print("end upload log to insight ======")

    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")

    -- local python_version = io.popen('which python3')
    -- python_version = python_version:read("*all")
    if userName == 'gdlocal' then 
        python_version = '/usr/local/bin/python3'
    else
        --raplace python_version when the overlay roll in line
        python_version = "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3"
    end
    args = '-path '..device_path..' -sn '..dutSN..' -userPath '..newCsvFileName
    command = python_version..' '..'/Users/'..userName..'/Documents/python/create_new_csv.py'..' '..args
    print('---command---:'..command)
    local run_python = io.popen(command)
    local run_python_result = run_python:read("*all")
    print(run_python_result)
    if string.match(run_python_result, '(successfully)') then
        print('update single log to summary log successfully!!')
    else
        -- error('---crate new csv error---')
    end

    -- local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    -- local ghJson = json.decode(comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json"))
    -- local BobCatUrl = ghJson.ghinfo.SFC_URL
    -- local stationId = ghJson.ghinfo.STATION_ID
    -- local queryConfig = "curl -d \"c=QUERY_RECORD&tsid="..stationId.."&p=sbuild&sn="..dutSN.."\" "..BobCatUrl
    -- local configReturn = RunShellCommand.run(queryConfig)
    -- local config = string.match(configReturn.output,"B448.*")

    -- local scriptPath = string.gsub(Atlas.assetsPath,"Assets","Script")
    -- local creSummary = scriptPath..'/create_summary_log.sh'..' '..newCsvFileName..' '..config
    -- local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    -- local runResult = RunShellCommand.run(creSummary)
    -- local groupIndex = string.match(workingDirectory, "group(%d+)")
    -- local popup = Device.getPlugin("Popup")
    -- -- sn = popup.scan("1",tips,"OK","SN")
    -- popup.reset(tostring(groupIndex))
end

return CreateRecord


