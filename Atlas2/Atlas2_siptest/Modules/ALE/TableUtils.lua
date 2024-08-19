--! @file Lua Table Utils

local TypeUtils = require "ALE.TypeUtils"

local TableUtils = {}

--! @brief Convert a table to a single string
function TableUtils.StringifyTable(tab)
    local printTable_cache = {}
    local string_table = {}

    local function sub_printTable( subtab, indent )

        if ( printTable_cache[tostring(subtab)] ) then
            table.insert(string_table, (indent .. "*" .. tostring(subtab) .. "\n"))
        else
            printTable_cache[tostring(subtab)] = true
            if ( type( subtab ) == "table" ) then
                for pos,val in pairs( subtab ) do
                    if ( type(val) == "table" ) then
                        table.insert(string_table, indent .. "[" .. pos .. "] => " .. tostring( subtab ) .. " {\n")
                        sub_printTable( val, indent .. string.rep( " ", string.len(pos)+8 ) )
                        table.insert(string_table, indent .. string.rep( " ", string.len(pos)+6 ) .. "}\n")
                    elseif ( type(val) == "string" ) then
                        table.insert(string_table, indent .. "[" .. pos .. '] => "' .. val .. '"' .. "\n")
                    else
                        table.insert(string_table, indent .. "[" .. pos .. '] => ' .. tostring(val) .. "\n")
                    end
                end
            else
                table.insert(string_table, tostring(subtab) .. "\n")
            end
        end
    end

    if ( type(tab) == "table" ) then
        table.insert(string_table, tostring(tab) .. " {\n")
        sub_printTable( tab, "  " )
        table.insert(string_table, "}\n")
    else
        sub_printTable( tab, "  " )
    end

    return table.concat(string_table)
end

--! @brief Print table with pretty format
function TableUtils.PrettyPrintTable(tab)
    print(TableUtils.StringifyTable(tab))
end

--! @brief Returns true if array has speficied value
--! @note Only first level values are checked
function TableUtils.ArrayHasValue(tab, val)
  for _, value in ipairs(tab) do
      if value == val then
          return true
      end
  end

  return false
end

--! @brief Returns true is table has speficied key
--! @note Only first level keys are checked
function TableUtils.TableHasKey(tab, val)
    return tab[val] ~= nil
end

--! @brief          Merge two tables with numeric keys (arrays) and returns a new array.
--!
--! @param t1       (table) array
--! @param t2       (table) array
--!
--! returns         resulting merged arrays
--!
function TableUtils.MergeArrays(t1, t2)

    TypeUtils.assertType(t1, "table")
    TypeUtils.assertType(t2, "table")

    local t = TypeUtils.DeepCopy(t1)
    for _, v in pairs(t2) do
        table.insert(t, v)
    end

    return t
end

--! @brief          Merge two tables and returns a new table.
--!
--! @param t1       table
--! @param t2       table
--!
--! returns         resulting merged tables
--!
function TableUtils.MergeTables(t1, t2)

    TypeUtils.assertType(t1, "table")
    TypeUtils.assertType(t2, "table")

    local t = TypeUtils.DeepCopy(t1)
    for k, v in pairs(t2) do
        t[k] = v
    end

    return t
end

--! @brief          Return first value found in table for a given key.
--!
--! @param t        table
--! @param key      key
--!
--! returns         value if key exists, nil otherwise
--!
function TableUtils.FindFirstValueForKey(t, key)

    if ( type(t) == "table" ) then
        for k, v in pairs(t) do
            if ( k == key ) then
                return v
            else
                local t_aux = TableUtils.FindFirstValueForKey(v, key)
                if t_aux then return t_aux end
            end
        end
    end
end

--! @brief Returns new array containing the dictionary’s keys, or an empty array if the dictionary has no entries
function TableUtils.AllKeys(t)
    TypeUtils.assertTable(t)

    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

--! @brief Returns new array containing the dictionary’s values, or an empty array if the dictionary has no entries
function TableUtils.AllValues(t)
    TypeUtils.assertTable(t)

    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

--! @brief Checks if a table is empty or not
function TableUtils.IsEmpty(t)
    return next(t) == nil
end

return TableUtils
