-------------------------------------------------------------------
----***************************************************************
----Condition plugins and conditions
----***************************************************************
-------------------------------------------------------------------

local Condition = {}
local common = require("Matchbox/CommonFunc")
local CSVLoad = require 'Matchbox/CSVLoad'

local allowedConditionTable = nil


function Condition.setCondition(name, value, allowStatic, conditions)
    if name == nil or name == "" then
        error('condition name (' .. tostring(name) .. ') cannot be nil or empty string.')
    end
    if value == nil then
        error('condition ' .. tostring(name) .. ' value cannot be nil.')
    end

    if allowedConditionTable == nil then
        allowedConditionTable = CSVLoad.loadConditions()
    end
    local condition = allowedConditionTable[name]

    -- hardcode allowed list and type only for "Hang"
    -- don't allow user to set other reserved condition.
    allowedConditionTable['Hang'] = {isDynamic=true, values={'TRUE', 'FALSE'}}

    if condition == nil then
        error("Condition " .. name .. " not specified in Conditions.csv")
    end
    if condition.isDynamic == false and not allowStatic then
        error("Not allowed to set static condition " .. name)
    end
    if not common.hasVal(condition.values, value) then
        error("Condition value " .. tostring(value) .. " not allowed for condition " .. name)
    end
    conditions[name] = value
end

function Condition.checkConditionExpression(Condition,conditionNameArr,reportStr1,reportStr2)
    local ret = common.parseCondition(Condition)
    for ii=1,#ret do
        if ret[ii].operator ~= "==" and ret[ii].operator ~= "!=" then
            reportStr3 = "Condition " .. Condition .. " operator '==' or '!=' not found."
            error(reportStr1 .. ", " .. reportStr2 .. ", " .. reportStr3)
        elseif not common.hasVal(conditionNameArr,ret[ii].left) and not common.hasVal(conditionNameArr,ret[ii].right) then 
            reportStr3 = "Neither condition left value " .. ret[ii].left .. " nor right value " .. ret[ii].right .. " is defined in Conditions.csv"
            error(reportStr1 .. ", " .. reportStr2 .. ", " .. reportStr3)
        end
    end
end

return Condition
