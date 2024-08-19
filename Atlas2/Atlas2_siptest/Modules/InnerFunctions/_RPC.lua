local ComFunc = require("Matchbox/CommonFunc")
local Helper = require("SMTLoggingHelper")
local Log = require("Matchbox/logging")

local _RPC = {}

-- @Description: call or execute xavier function and get return value
-- @param cmd: string
-- @param paramList: table
-- @param timeout: number type, get it from csv
-- return: string
function _RPC._callRPCFunc(cmd, paramList, timeout)
    local mixRPC = Device.getPlugin("MixRPC")
    assert(mixRPC ~= nil, "rpc_client not init")
    local realParamList = paramList or {}
    if #realParamList <= 0 then
        realParamList = nil
    end
    local realParamDic = {}
    if timeout == nil then
        error("timeout value is nil!")
    end
    realParamDic['timeout_ms'] = timeout
    Log.LogInfo(
        "[MixPRC] [SEND] cmd=" .. cmd .. ", realParamList=" .. ComFunc.dump(realParamList) .. ", realParamDic=" ..
            ComFunc.dump(realParamDic))

    Helper.LogFixtureControlStart(cmd, ComFunc.dump(realParamList), timeout)

    local bRet, response = pcall(mixRPC.rpc, cmd, realParamList, realParamDic)

    if not bRet then
        Helper.LogFixtureControlFinish(string.gsub(tostring(response), '[\r\n]', ''))
        return false
    end

    if type(response) == "table" then
        Helper.LogFixtureControlFinish(ComFunc.dump(response))
    else
        Helper.LogFixtureControlFinish(tostring(response))
    end

    return response
end

function _RPC._callSPKRPCFunc(cmd, paramList, timeout)
    local mixRPC = Device.getPlugin("SPKRPC")
    assert(mixRPC ~= nil, "rpc_client not init")
    local realParamList = paramList or {}
    if #realParamList <= 0 then
        realParamList = nil
    end
    local realParamDic = {}
    if timeout == nil then
        error("timeout value is nil!")
    end
    realParamDic['timeout_ms'] = timeout
    Log.LogInfo(
        "[MixPRC] [SEND] cmd=" .. cmd .. ", realParamList=" .. ComFunc.dump(realParamList) .. ", realParamDic=" ..
            ComFunc.dump(realParamDic))

    Helper.LogFixtureControlStart(cmd, ComFunc.dump(realParamList), timeout)

    local response = mixRPC.rpc(cmd, realParamList, realParamDic)
    if type(response) == "table" then
        Helper.LogFixtureControlFinish(ComFunc.dump(response))
    else
        Helper.LogFixtureControlFinish(tostring(response))
    end

    return response
end

return _RPC
