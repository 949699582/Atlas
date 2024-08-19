--! @file StatsUtils.lua
local TypeUtils = require("ALE.TypeUtils")

local StatsUtils = {}

--! @brief Get the mean value of a table
function StatsUtils.Mean(tab)
    local sum = 0
    local c = 0.0

    TypeUtils.assertTable(tab)
    assert(#tab > 0, "No elements in the input array")

    -- Using Kahan summation algorithm
    -- See https://en.wikipedia.org/wiki/Kahan_summation_algorithm for details.
    for _, v in pairs(tab) do
        TypeUtils.assertNumber(v)
        local y = v - c
        local t = sum + y
        c = (t - sum) - y
        sum = t
    end
    return (sum / #tab)
end

--! @brief Get the mode of a table (the most commonly observed value in a set of data)
--! @returns Table of values
function StatsUtils.Mode(t)
    local counts={}

    for _, v in pairs(t) do
        counts[v] = counts[v] and counts[v] + 1 or 1
    end

    local biggestCount  = 0
    local biggestValues = {}

    for k, v in pairs(counts) do
        if v > biggestCount then
            biggestCount  = v
            biggestValues = {k}
        elseif v == biggestCount then
            table.insert(biggestValues, k)
        end
    end

    return biggestValues
end

--! @brief Get the median of a table.
function StatsUtils.Median(t)

    TypeUtils.assertTable(t)
    assert(#t > 0, "No elements in the input array")

    local temp={}
    -- deep copy table so that when we sort it, the original is unchanged
    -- also weed out any non numbers
    for _,v in pairs(t) do
        TypeUtils.assertNumber(v)
        table.insert( temp, v )
    end

    table.sort( temp )

    -- If we have an even number of table elements or odd.
    if math.fmod(#temp,2) == 0 then
      -- return mean value of middle two elements
      return ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
    else
      -- return middle element
      return temp[math.ceil(#temp/2)]
    end
end

--! @brief Get the standard deviation of a table
function StatsUtils.StandardDeviation(t)
    local m
    local vm
    local sum = 0
    local count = 0
    local result

    m = StatsUtils.Mean( t )

    for _,v in pairs(t) do
        vm = v - m
        sum = sum + (vm * vm)
        count = count + 1
    end

    result = math.sqrt(sum / count)

    return result
end

--! @brief Get the min and max for a table
--! @returns Two values for min and max
function StatsUtils.Minmax(t)

    TypeUtils.assertTable(t)
    assert(#t > 0, "No elements in the input array")

    local max = -math.huge
    local min = math.huge

    for _,v in pairs( t ) do
        TypeUtils.assertNumber(v)
        max = math.max( max, v )
        min = math.min( min, v )
    end

    return min, max
end

  --! @brief Get R2 Score (Coefficient of Determination)
function StatsUtils.R2Score(x, y)
    local Xm = StatsUtils.Mean(x)
    local Ym = StatsUtils.Mean(y)
    local sum1 = 0  -- (X - Xm)^2
    local sum2 = 0  -- (Y - Ym)^2
    local sum3 = 0  -- (X-Xm)*(Y-Ym)

    for k,v in pairs(x) do
        TypeUtils.assertNumber(v)
        local x1 = v - Xm
        local y1 = y[k] - Ym
        sum1 = sum1 + (x1 * x1)
        sum2 = sum2 + (y1 * y1)
        sum3 = sum3 + (x1 * y1)
    end

    return ((sum3 / math.sqrt(sum1 * sum2)) * (sum3 / math.sqrt(sum1 * sum2)))
end

return StatsUtils