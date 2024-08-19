local DealWithFile = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
function DealWithFile.fileExists(name)
    if name then
        local f=io.open(name,"r")
        if f~=nil then io.close(f) return true else return false end
    else
        return false
    end
end

function DealWithFile.getConfigJson(...)
    local user = io.popen('whoami')
    local userName = user:read("*all")
    userName = string.gsub(userName, "%s+", "")
    -- local jsonfile = "/Users/"..userName.."/Documents/ConfigInfo.json"
    local jsonfile = "/vault/Documents/ConfigInfo.json"
    if DealWithFile.fileExists(jsonfile) == false then
        error("The file of path not found."..jsonfile)
    end
    return jsonfile
end


return DealWithFile


