-------------------------------------------------------------------
----***************************************************************
----    prmIOTable.lua provied functions to load io map and get
----    io list with net name
----***************************************************************
-------------------------------------------------------------------
local m_currentPath = debug.getinfo(1, "S").source
m_currentPath = string.sub(m_currentPath, 2, -1)
local m_parentPath = string.match(m_currentPath, "^(.*)/.*/.*/.*")
local js = require("InnerFunctions/PRM/Functions/Lib/json")
local Log = require("Matchbox/logging")

local m_innerMapPath = m_parentPath .. "/Functions/ioMap/io_map.json"
local _sh = m_parentPath .. "/Functions/ioMap/upload_io_map.sh"
local prmIOTable = {innerIOTable = nil, exposedIOTable = nil, _sh = _sh, m_innerMapPath = m_innerMapPath}

-- load io table
-- @param path: string type
function prmIOTable.load(path)
    local currentPath = path or m_innerMapPath
    local fileInner = io.open(currentPath, 'r')
    local contentsInner = fileInner:read("*a");
    fileInner:close()
    prmIOTable.innerIOTable = js.decode(contentsInner)
    return contentsInner
end

-- load io table
-- @param path: string type
function prmIOTable.checkSum()
    local shellOut = io.popen(string.format('md5 %s', m_innerMapPath))
    local md5String = shellOut:read("*a")
    local md5 = string.match(md5String, '= (%w*)')
    return md5
end

-- get io list with net name
-- @param net: string type
-- @param net: string type
-- @return string type of io list
function prmIOTable.getByNetName(net, subnet)
    subnet = subnet or "CONNECT"
    net = string.upper(net)
    subnet = string.upper(subnet)

    local tmp = prmIOTable.exposedIOTable[net]
    if (tmp == nil or #tmp == 0) then
        tmp = tmp or {}
        table.insert(tmp, net)
        Log.LogInfo("finding net: " .. net .. ", subnet: " .. subnet .. " in IOMapping.json")
    else
        Log.LogInfo("finding net: " .. net .. ", subnet: " .. subnet .. " in _IOMapping.json")
    end

    local ioList = {}
    for i = 1, #(tmp) do
        local items = prmIOTable.innerIOTable[tmp[i]]
        if items then
            for _, v1 in pairs(items[subnet]) do
                table.insert(ioList, v1)
            end
        else
            error("net: " .. tmp[i] .. " not found")
        end
    end
    Log.LogInfo("prmIOTable.getByNetName: name=" .. net .. ", subnet=" .. subnet)
    Log.LogInfo("prmIOTable.getByNetName: iolist=" .. prmIOTable.ioListToString(ioList))
    return ioList
end

-- convert io list to string
-- @param ioList: list type
-- @return string of io list
function prmIOTable.ioListToString(ioList)
    local ioString = "["
    for _, v in pairs(ioList) do
        ioString = ioString .. "["
        for _, v1 in pairs(v) do
            ioString = ioString .. v1
            ioString = ioString .. ','
        end
        ioString = ioString .. "],"
    end
    ioString = ioString .. "]"
    ioString = string.gsub(ioString, ',]', ']')
    return ioString
end

return prmIOTable
