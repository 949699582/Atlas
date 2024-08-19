-- substitue variable in a given string to its value.
-- usage:
--     local pattern                    = '$(varname)'
--     local valuesForPattern           = {a=1, b=2, c=3}
--     local anotherPattern             ='[[varname]]'
--     local valuesForAnotherPattern    = {x=1, y=2, c=5}
--     local strWithPattern             = 'hello! $(a) == [[x]].'
--     local ret = sub.sub(strWithPattern, {{pattern, valuesForPattern},
--                                          {anotherPattern, valuesForAnotherpattern}})
--     -- ret will be 'hello! 1 == 1'
--
-- pattern: symbols wrapping string "varname".
-- escape: by default '\' (backslash) is escape char; any pattern prefixed with 1 \ will be escaped.
--         double '\' before pattern is considered a normal \ char.
--         \ in other places is not used as escape char.
--         user can specify other escape char by adding it after values in each pattern, like
--         sub.sub(s, {{pattern, values, customEscapeChar}})


local sub = {}
-- patterns processed are cached.
local __cache = {}

local defaultEscapeChar = '\\'


-- create a pattern from given string, like
-- $(varname) --> [escape]*$%(varname%)
-- 1. prepend pattern that can capture all consequent escape char before pattern
-- 2. escape lua regex magic chars: ().%+-*?[^$
-- cache result.
local function mkpattern(p, escape)
    assert(p~=nil, 'mkpattern: given pattern is nil.')
    if p:find('varname') == nil then
        error('pattern should include string "varname" as variable name placeholder but not found.')
    end
    local prepend = '['..escape..']*'
    if __cache[p] then return prepend..__cache[p] end

    -- capture pattern along any escape char before it
    local ret = p:gsub('%%', '%%%%')
    ret = ret:gsub('%(', '%%(')
    ret = ret:gsub('%)', '%%)')
    ret = ret:gsub('%.', '%%.')
    ret = ret:gsub('%+', '%%+')
    ret = ret:gsub('%-', '%%-')
    ret = ret:gsub('%*', '%%*')
    ret = ret:gsub('%?', '%%?')
    ret = ret:gsub('%[', '%%[')
    ret = ret:gsub('%^', '%%^')
    ret = ret:gsub('%$', '%%$')
    __cache[p] = ret

    return prepend..ret
end


-- search and replace patterns in given string.
-- @param s: string including patterns to be replaced (or not)
-- @param pattern: array of {pattern, values, escape}.
--                 pattern: pattern for variable, like "$(varname)"
--                 values: key-value pairs used for replacement
--                 escape: optional escape char, '\' by default
-- @param invalidValues: optional additonal values table to report as error besides nil.
--                       Format: key-value table.
--                               key: value to report error
--                               value: anything but nil or false; typically true
--                       Use case is Matchbox use "NIL_VARIABLE_VALUE" to store
--                       an variable with nil value; so sub.sub() is expected to
--                       error out when var has this special string as value.
-- @return: substituted string.
-- raise error when variable found without an value or have a value in invalidValues.
function sub.sub(s, patterns, invalidValues)
    if s == nil then return s end
    if invalidValues == nil then invalidValues = {} end

    local ret = s
    for _, pattern in ipairs(patterns) do
        local p, values, escape = table.unpack(pattern)
        if escape == nil then escape = defaultEscapeChar end
        -- convert pattern from user to real lua regex pattern
        -- like $(varname) --> $%((.-)%)
        p = mkpattern(p, escape)
        pVarname = p:gsub('varname', '(.-)')
        local varnameDone = {}
        for varname in s:gmatch(pVarname) do
            -- $(var)$(var), when same var name appear multiple times, only need to do it once
            if varnameDone[varname] == nil then
                varnameDone[varname] = true
                value = values[varname]

                if value == nil then
                    error('variable '..varname..' value not found.')
                elseif invalidValues[value] then
                    error('variable '..varname..' value is invalid: '..value)
                end

                value = tostring(value)
                local pCurrentVariable = p:gsub('varname', varname)
                ret = ret:gsub(pCurrentVariable, function(capture)
                    -- count how many escape char is there before pattern
                    local _, count = capture:gsub(escape, '')
                    if count % 2 == 1 then
                        -- odd: with escape, \$ or \\\$
                        -- remove one from head
                        return capture:gsub('^'..escape, ''):gsub(escape..escape, escape)
                    else
                        -- even: \\$ or \\\\$, pattern not escaped
                        -- reassemble: escap chars + value
                        for i=1, count/2, 1 do
                            value = escape..value
                        end
                        return value
                    end
                end)
            end
        end
    end

    return ret
end

return sub
