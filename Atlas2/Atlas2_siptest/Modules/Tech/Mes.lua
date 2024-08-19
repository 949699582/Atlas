local Mes = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
function Mes.querySFCInter(paraTab)
    local sn = paraTab.Input
    local SFC = Device.getPlugin("SFC")
    local attributeName = paraTab.varSubAP()["attributeName"]
    Log.LogInfo("sn -->>> ",sn)
    Log.LogInfo("attribute -->>> ",attributeName)
    local queryResult = SFC.getAttributes(sn, {attributeName})[attributeName]
    Log.LogInfo("queryResult -->>> ",queryResult)
    Log.LogInfo("queryResult -->>>### ",#queryResult)

    if queryResult and #queryResult ~=0 then
        return queryResult
    else
        return false
    end
    
end
function Mes.querySFC(paraTab)
   local result = false
    function excuteF()
        result = Mes.querySFCInter(paraTab)
    end
    function errorF(err)
        print('Query SFC fail!!',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result

end
--only test before mes ok
function Mes.queryFromMes(paraTab)
    return 'MULAN/P2-BU/SUB/MULM06BG/00001/'
    
end

function Mes.AmIOK(paraTab)
    function processCheck()
        ProcessControl.amIOK()
    end
    function myerrorhandler( err )
        Log.LogInfo( "ERROR Here:", err )
    end
    bRet = xpcall(processCheck, myerrorhandler) 
    return bRet
end

function Mes.dataReportSetup(paraTab)
    local inputs = paraTab.InputValues
    -- check SN and upload attrbuite
    local result = true
    log.LogInfo('Running Common.dataReportSetup')
    local sn = inputs[1]
    local group = inputs[2]
    local slot = inputs[3]
    limitsVersion = paraTab.AdditionalParameters["limitsVersion"]
    log.LogInfo("Unit serial number: ".. sn)
    function reportCheck()
        DataReporting.primaryIdentity(sn)
    end
    function myerrorhandler( err )
        result = false
    end
    result = xpcall(reportCheck, myerrorhandler) 
    -- reportResult = DataReporting.primaryIdentity(sn)
    DataReporting.limitsVersion(limitsVersion)
    DataReporting.fixtureID(group, slot)
    log.LogInfo("Station reporter is ready.") 
    -- local testResult = DataReporting.createAttribute('limitsVersion', limitsVersion)
    -- DataReporting.submit(testResult)
    -- local stationPlist = string.gsub(Atlas.assetsPath, "Assets", "Config")
    -- local stationPlistFile = plist2lua.read(stationPlist .. "/station.plist")
    -- local stationVersion = stationPlistFile.StationVersion
    -- local stationName = stationPlistFile.StationName
    -- local testResult = DataReporting.createAttribute('StationVersion', stationVersion)
    -- DataReporting.submit(testResult)
    -- local testResult = DataReporting.createAttribute('StationName', stationName)
    -- DataReporting.submit(testResult)

    --Common.createRecord(paraTab,data)
    return result
end
function Mes.getOrPostWithMESInner(paraTab)
    local workingDirectory = Device.userDirectory
    Log.LogInfo("workingDirectory...",workingDirectory)
    local groupIndex = string.match(workingDirectory, "group(%d+)%-slot%d+")
    Log.LogInfo("Group index is:", groupIndex)
    local inputs = paraTab.InputValues
    local ghJson = json.decode(comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json"))
    local BobCatUrl = ghJson.ghinfo.SFC_URL
    local stationID = ghJson.ghinfo.STATION_ID
    local woNumber = paraTab.varSubAP()['WO']
    local opID = paraTab.varSubAP()['OPID']
    local SN = paraTab.varSubAP()['SN']
    local type = paraTab.varSubAP()['type']

    print("paraTab.varSubAP()['WO']",paraTab.varSubAP()['WO'])
    local cmd = ''
    if type == 'PA_CHECK_WO' then
        cmd = 'wo='..woNumber..'&p=PA_CHECK_WO&c=query_record&station_id='..stationID
    else
        cmd = 'wo='..woNumber..'&p=PA_CHANGE_WO&c=query_record&station_id='..stationID..'&SN='..SN..'&op='..opID
    end
    curl_cmd = "curl -d ".."\'"..cmd.."\'"..' '..BobCatUrl
    print('---Query MES curl cmd---:',curl_cmd)
    local queryResult = RunShellCommand.run(curl_cmd)
    local output = queryResult.output
    local popup = Device.getPlugin("Popup")
    print("---Response from MES---:",output)
    if string.match(output,"(NG)") ~= nil then
        
        -- popup.reset()
        local useAlert = popup.alert('Group ['..groupIndex..']: \n'..tostring(string.match(output,"(NG.+)")),'OK')
        while true 
            do
                os.execute("sleep 0.5")
                local alertStatus = popup.queryAlert()
                if alertStatus == 0 then
                    break
                end
        end
        return false
    else
        if type == 'PA_CHECK_WO' then 
            local input = string.match(output,"OK:(%d+)")
            popup.updateInput(input)
        end
        return true
    end

    -- uart = paraTab.varSubAP()['portName'] or 'dut'
    -- local type = paraTab.varSubCmd()
    -- local cmd = 'curl -d \"sn=' .. sn .. type ..'\" '..BobCatUrl
    -- print("Requests to MES command:"..cmd)
    -- local queryResult = RunShellCommand.run(cmd)
    -- print("Response from MES:",queryResult.output)
    -- local returnStatus = string.match(queryResult.output,"(0 SFC_OK)")
    -- if returnStatus ~= nil then
    --     return queryResult.output
    -- else
    --     return false
    -- end

    -- str = 'NG'
    -- local popup = Device.getPlugin("Popup")
    -- -- popup.reset()
    -- local useAlert = popup.alert(tostring(str),'OK')
    -- while true 
    --     do
    --         os.execute("sleep 0.5")
    --         local alertStatus = popup.queryAlert()
    --         if alertStatus == 0 then
    --             break
    --         end
    -- end
end
function Mes.getOrPostWithMES(paraTab)
    local result = false
    function excuteF()
        result = Mes.getOrPostWithMESInner(paraTab)
    end
    function errorF(err)
        print('getOrPostWithMES ERROR:',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

return Mes


