local MogulTable = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local String = require 'Tech/String'
local Mogul = require 'Tech/MogulCert'
local band = require 'Tech/MogulCert/Band'
local mix = require 'Tech/MogulCert/Mix'
local log = require 'Matchbox/logging'
function MogulTable.certifyMogulExt(paraTab)
    local result = false
    function excuteF()
        result = Mogul.certifyMogul(paraTab)
    end
    function errorF(err)
        print('Fail:',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result

end
function MogulTable.lockZoneExt(paraTab)
    local result = false
    function excuteF()
        result = Mogul.lockZone(paraTab)
    end
    function errorF(err)
        print('Fail:',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result

end
function MogulTable.isLocked(paraTab)
    local zones = paraTab.varSubAP()['zones'] or ''
    local side = paraTab.varSubAP()['side'] or ''
    if side ~= '' then
        mix.initialize(side)
    else
        return false
    end    
    if zones ~= '' then
        local zonesTable = String.split(zones,',')
        for k,v in pairs(zonesTable) do
            if not band.is_locked(tonumber(v)) then
                log.LogInfo("Zone " .. tonumber(v) .. " unlock")
                return false
            end
        end
    else
        return false
    end
    return true

end

function MogulTable.isLockedExt(paraTab)
    local result = false
    function excuteF()
        result = MogulTable.isLocked(paraTab)
    end
    function errorF(err)
        result = "error"
        print('Fail:',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result
end

return MogulTable


