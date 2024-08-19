local MCU = {}
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require 'Matchbox/json'
local dealWithFile = require 'Tech/DealWithFile'
local String = require 'Tech/String'

function MCU.calculateResult(paraTab)
    local par1,par2,par3,par4 = table.unpack(paraTab.InputValues)
    local result = false
    local wrapper = function()
        if paraTab.AdditionalParameters.expression == "A*B" then
            result = tonumber(par1)*tonumber(par2)
            sendCommandAndResult = sendCommandAndResult .. par1 .. " * " .. par2 .. " = " .. result .. "\n"
        end
        if paraTab.AdditionalParameters.expression == "A/B" then
            result = tonumber(par1)/tonumber(par2)
            sendCommandAndResult = sendCommandAndResult .. par1 .. " / " .. par2 .. " = " .. result .. "\n"
        end
        if paraTab.AdditionalParameters.expression == "A-B" then
            result =tonumber(par1) - tonumber(par2)
            sendCommandAndResult = sendCommandAndResult .. par1 .. " - " .. par2 .. " = " .. result .. "\n"
        end
        if paraTab.AdditionalParameters.expression == "(A-B)/(C-D)" then
            local ab =tonumber(par1) - tonumber(par2)
            local cd =tonumber(par3) - tonumber(par4)
            result = ab/cd
            sendCommandAndResult = sendCommandAndResult .. "( " .. par1 .. " - " .. par2 .. " ) / ( " .. par3 .. " - " .. par4 .." ) = " .. result .. "\n"
        end
        return result
    end
    local status , ret = xpcall(wrapper,debug.traceback)
    return result
end

function MCU.openCurrentFix(paraTab)
    local inputValue = paraTab.Input
    local result = false

    function excuteF()
        if tonumber(inputValue) < 0.000001 then
            sendCommandAndResult = sendCommandAndResult .. "inputValue: " .. inputValue .. "\n"
            result = "0.000001"
            sendCommandAndResult = sendCommandAndResult .. "inputValue Change To: " .. result .. "\n"
        else
            result = inputValue
        end
    end

    function errorF(err)
        result = false
        Log.LogInfo(err)
    end
    
    local rRe = xpcall(excuteF,errorF)

    return result
end

--todo ： From opto , par1 par2电压/电流前后的值，
-- @param:    par3是-1/-2，par4是原来的result
-- @return:   -1 代表分子是负数
--                  -2 代表分母是负数
--                 par4 原来的值
function MCU.returnDcrResult(paraTab)
    local par1,par2,par3,par4 = table.unpack(paraTab.InputValues)

    function excuteF()
        if(tonumber(par1)-tonumber(par2)<=0) then
            par4 = par3
        end
    end
    function errorF(err)
        par4 = false
        Log.LogInfo(err)
    end
    local rRe = xpcall(excuteF,errorF)

    return par4
end

function MCU.createConfigJson(jsonPath)
    local STDInfoTb = {
        itemResult = { 0, 100, 0 }
    }
    STDInfoTb = json.encode(STDInfoTb)
    dealWithFile.writefile(jsonPath, STDInfoTb, nil)
end

--标准差计算，用于预防扫A测试B
function MCU.calculateSTD()
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    local jsonPath = "/Users/"..userName.."/Documents/STD_Value.json"
    
    -- local jsonPath = "/Vault/ConfigInfo/STD_Value.json"
    if dealWithFile.fileExists(jsonPath) == false then
        MCU.createConfigJson(jsonPath)
    end

    local jsonInfo = dealWithFile.getJsonContent(jsonPath)
    local itemResult = jsonInfo.itemResult
    local aidSum = 0
    for i = 1, #itemResult do
        sendCommandAndResult = sendCommandAndResult .. "aidSum " .. i .. ": " .. aidSum
        aidSum = aidSum + tonumber(itemResult[i])
        sendCommandAndResult = sendCommandAndResult .. " + " .. itemResult[i] .. " = " .. aidSum .. "\n"
    end
    local aidAverage = aidSum / #itemResult
    sendCommandAndResult = sendCommandAndResult .. "aidAverage: " .. aidSum .. " + " .. #itemResult .. " = " .. aidAverage .. "\n"
    local aidVarianceSum = 0
    for i = 1, #itemResult do
        sendCommandAndResult = sendCommandAndResult .. "aidVarianceSum " .. i .. ": " .. aidVarianceSum
        aidVarianceSum = aidVarianceSum + (itemResult[i] - aidAverage) ^ 2
        sendCommandAndResult = sendCommandAndResult .. " + (" .. itemResult[i] .. "-" .. aidAverage .. ") ^ 2 = " .. aidVarianceSum .. "\n"
    end
    local aidStd = (aidVarianceSum / (#itemResult - 1)) ^ (1 / 2)
    sendCommandAndResult = sendCommandAndResult .. "aidStd: (" .. aidVarianceSum .. " / " .. #itemResult .. ")^ (1/2)" .. " = " .. aidStd .. "\n"
    if aidStd == 0 then
        return true
    else
        return aidStd
    end
end

function MCU.updateStdJson(paraTab)
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    local jsonPath = "/Users/"..userName.."/Documents/STD_Value.json"

    local newAidValue,SN = table.unpack(paraTab.InputValues)
    -- local jsonPath = "/Vault/ConfigInfo/STD_Value.json"
    local jsonInfo = dealWithFile.getJsonContent(jsonPath)
    if #SN == 17 or #SN == 18 then
        if newAidValue ~= -1 and newAidValue ~= -2 and newAidValue ~= -9999 and tostring(newAidValue) ~= "inf" and newAidValue ~= nil then
            table.remove(jsonInfo.itemResult,1)
            table.insert(jsonInfo.itemResult,newAidValue)
            local STDInfoTb = {
                itemResult = jsonInfo.itemResult
            }
            local STDInfoTb = json.encode(STDInfoTb)
            dealWithFile.writefile(jsonPath,STDInfoTb,nil)
        end
    end
end

return MCU