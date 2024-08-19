local TypeUtils = require "ALE.TypeUtils"

local StringUtils = {}

--! @brief Returns an iterator splitting a string on the delimiter
local function gsplit(str, delimiter)
    assert(delimiter)
    if str:sub(-#delimiter) ~= delimiter then
        str = str .. delimiter
    end

    return string.gmatch(str, '(.-)' .. StringUtils.EscapeSpecialChars(delimiter))
end

--! @brief Escape special pattern characters in string to be treated as simple characters
--! @details Read gsub documentaiton for a list of special characters
function StringUtils.EscapeSpecialChars(s)
    assert(s)
    local MAGIC_CHARS = '[()%%.[^$%]*+%-?]'
    return (s:gsub(MAGIC_CHARS,'%%%1'))
end

--! @brief Tokenizes a string on the given delimiter
--! @returns Array of resulting tokens
function StringUtils.Tokenize(str, delimiter)
    local ans = {}

    for item in gsplit(str, delimiter) do
        ans[ #ans+1 ] = item
    end

    return ans
end

--! @brief Returns True if a string starts with specified prefix
function StringUtils.StartsWith(str, start)
   return str:sub(1, #start) == start
end

--! @brief Returns True if a string ends with specified suffix
function StringUtils.EndsWith(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

--! @brief Returns string contained between specified tags
function StringUtils.GetStringBetweenTags(str, start_tag, end_tag)
    start_tag = StringUtils.EscapeSpecialChars(start_tag)
    end_tag = StringUtils.EscapeSpecialChars(end_tag)
    local start_s, start_e = string.find(str, start_tag)
    assert(start_s, "Cannot find start_tag: " .. start_tag .. " from string: " .. str)
    assert(start_e)
    local end_s, end_e = string.find(str, end_tag, start_e + 1)
    assert(end_s, "Cannot find end_tag: " .. end_tag .. " from string: " .. str)
    assert(end_e)
    local ret = str:sub(start_e + 1, end_s - 1)
    assert(ret and (ret ~= ""),
        string.format("Cannot find any characters between tags '%s' and '%s' in '%s'",
                    start_tag, end_tag, str))
    return ret
end

function StringUtils.TrimWhitespace(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function StringUtils.RemoveAllWhiteSpaces(str)
    return str:gsub("%s+", "")
end

--! @brief Trims all non-printable characters from a string
function StringUtils.TrimControlChars(str)
    return (str:gsub("^%c*(.-)%c*$", "%1"))
end

--! @brief Abbreviates a String to the length passed, replacing the middle characters with elipsis.
function StringUtils.AbbreviateMiddle(str, maxLength)
    if not str then
        return str
    end

    local middle = "..."

    local strlen = str:len()
    if strlen <= maxLength then
        return str
    end

    if strlen <= maxLength + middle:len() then
        return str:sub(1, maxLength)
    end

    local pos1 = math.floor((maxLength - 3) / 2)
    local pos2 = strlen - pos1
    return str:sub(1, pos1) .. middle .. str:sub(pos2, strlen)
end

--! @brief              Replace a substring in a string with a string.
--!
--! @param string       the string where the replacement will be done
--! @param substring    the substring to be replaced
--! @param replacement  the string to replace the substring with
--!
--! @return             the output string
--!
function StringUtils.ReplaceSubstring(string, substring, replacement)
    TypeUtils.assertString(string)
    TypeUtils.assertString(substring)
    TypeUtils.assertString(replacement)
    return (string:gsub(substring, replacement))
end

--! @brief Interpolate string using provided parameters using `${param_name}` as a a placeholder format
--! @details The function can be used to replace parameter placeholders in a string
--! with actual values: "The name is ${name}" + {['name'] = 'John'} --> "The name is John"
--!
--! @param str Inout string containing placeholders
--! @param params Table with key-value pairs for parameter values
--! @returns Interpolated string
function StringUtils.InterpolateString(str, params)
	local function interpolate(n)
		return params[n:sub(2,-2)]
	end
	return str:gsub("$(%b{})", interpolate)
end

return StringUtils
