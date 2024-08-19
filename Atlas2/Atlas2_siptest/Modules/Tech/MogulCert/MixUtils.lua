local TypeUtils = require 'ALE/TypeUtils'

local module = {}

function module.is_pass(s)
    TypeUtils.assertType(s, "string")

    if string.find(s, "PASS") then
        return true
    else 
        return false
    end
end

function module.mix_dict_to_table(reply)
    TypeUtils.assertType(reply, "string")

    local t = {}
    for k, v in string.gmatch(reply, "u'([%a%p%d]*)': u'([%a%p%d]*)'") do
        t[k] = v
    end
    return t
end

function module.mix_array_to_table(reply)
    TypeUtils.assertType(reply, "string")

    local t = {}
    for k in string.gmatch(reply, "'(0x%x*)'") do 
        table.insert(t, tonumber(k))
    end
    return t
end

function module.get_trinary_for_side(side)
    if side == "LEFT" then
        return "trinary1."
    elseif side == "RIGHT" then
        return "trinary2."
    elseif side == "AGNES" then
        return "trinary2."
    else
        return nil
    end
end

return module