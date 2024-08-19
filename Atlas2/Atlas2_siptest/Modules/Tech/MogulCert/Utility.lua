local TypeUtils = require 'ALE/TypeUtils'
local log = require 'Matchbox/logging'

local module = {}

function module.zone_size(zone)
    local zone_sizes = { [0] = 316, [1] = 182, [2] = 8, [3] = 20, [4] = 20, [5] = 20, [6] = 1280, [7] = 1824, [8] = 448 }
    return zone_sizes[zone]
end

function module.zone_read_zone(zone)
    local zone_sizes = { [0] = 0, [1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 6, [7] = 7, [8] = 8 }
    return zone_sizes[zone]
end

function module.zone_offset(zone)
    local zone_sizes = { [0] = 0, [1] = 0, [2] = 98, [3] = 106, [4] = 126, [5] = 146, [6] = 0, [7] = 0, [8] = 0 }
    return zone_sizes[zone]
end

function module.write_zone_size(zone)
    local zone_sizes = { [0] = 316, [1] = 98, [2] = 8, [3] = 20, [4] = 20, [5] = 20, [6] = 1280, [7] = 1824, [8] = 448 }
    return zone_sizes[zone]
end

function module.make_zeros(zone)
    local zeros = {}
    for i = 1, module.write_zone_size(zone) do
        zeros[i] = 0
    end
    return zeros
end

function module.hexdump(o)
    assert(o, "Table being dumped is nil")
    if type(o) == 'table' then
        local offset = 0
        local t = '  |'
        local s = '\n00000000 '
        if #o < 16 then
            s = '\n'
        end
        for i = 1, #o do
            offset = offset + 1
            s = s .. string.format("%02X ", o[i])
            if o[i] >= 32 and o[i] <= 126 then
                t = t .. string.format("%c", o[i])
            else 
                t = t .. "."
            end
            if i % 8 == 0 then
                s = s .. " "
            end
            if i % 16 == 0 then
                s = s .. t .. "|\n" .. string.format("%08X ", offset)
                t = '  |'
            end
        end
        return s
    else
        return "Not a table! Object is " .. type(o)
    end
end

function module.compare(t1, t2)
    TypeUtils.assertType(t1, "table")
    TypeUtils.assertType(t2, "table")

    if #t1 ~= #t2 then
        return false
    end

    for i = 1, #t1 do
        if t1[i] ~= t2[i] then
            return false
        end
    end

    return true
end

function module.table_to_string(t)
    TypeUtils.assertType(t, "table")

    local s = ""
    for i = 1, #t do 
        if t[i] == 0 then
            break
        end
        s = s .. string.format("%c", t[i])
    end
    return s
end

function module.table_to_hex_string(t)
    TypeUtils.assertType(t, "table")

    local s = ""
    for i = 1, #t do
        s = s .. string.format("%02X", t[i])
    end
    return s
end

return module
