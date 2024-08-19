local logging = {}

LOG_LEVEL_ERROR = 0
LOG_LEVEL_INFO = 1
LOG_LEVEL_DEBUG = 2

local logging_level = LOG_LEVEL_INFO

local ERROR_PREFIX = "ERROR"
local DEBUG_PREFIX = "DEBUG"
local INFO_PREFIX = "INFO"

LOGGING_LEVEL = {
    INFO = LOG_LEVEL_INFO,
    DEBUG = LOG_LEVEL_DEBUG,
    ERROR = LOG_LEVEL_ERROR
}

local TEST_START_PREFIX_FORMAT = "[Test Start][%s-%d-%d][%s][<%s> <%s> <%s>]"
local TEST_PASS_PREFIX_FORMAT = "[Test Pass][%s-%d-%d][%s][<%s> <%s> <%s>]"
local TEST_FAIL_PREFIX_FORMAT = "[Test Fail][%s-%d-%d][%s][<%s> <%s> <%s>]"
local THREAD_LOGGING_PREFIX_FORMAT = "[%s-%d-%d][%s][%s][%s]" -- [identifier-mainIndex-techIndex][thread][file][level]
local LOGGING_PREFIX_FORMAT = "[%s][%s]" --[file][level]

local function print_r ( T )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(T)=="table") then
        print(tostring(T).." {")
        sub_print_r(T,"  ")
        print("}")
    else
        sub_print_r(T,"  ")
    end
    print()
end

function logging.setLogEnv(loggingTech, level, id, mainIndex, techIndex, threadID)
    LOGGING_THREAD = loggingTech or false
    logging_level = level or LOG_LEVEL_INFO
    MAIN_INDEX = mainIndex or 0
    TECH_INDEX = techIndex or 0
    THREAD_ID = threadID or nil
    TP_ID = id
end

local function _log(...)
    local logString = ""
    local logTable = {}
    for _, element in ipairs({...}) do
        if type(element) == "table" then
            table.insert(logTable, element)
        end
        logString = logString .. tostring(element) .. "  "
    end
    print(logString)
    for _, t in ipairs(logTable) do
        print_r(t)
    end
end

local function log(level, ...)
    local file = string.match(debug.getinfo(3, 'S').short_src, "/([^/]+%.lua)")
    if LOGGING_THREAD then
        _log(string.format(THREAD_LOGGING_PREFIX_FORMAT, TP_ID or "main", MAIN_INDEX or 0, TECH_INDEX or 0, THREAD_ID or "", file, level), ...)
    else
        _log(string.format(LOGGING_PREFIX_FORMAT, file, level), ...)
    end
end

function logging.LogDebug(...)
    if logging_level >= LOG_LEVEL_DEBUG then
        log(DEBUG_PREFIX, ...)
    end
end

function logging.LogError(...)
    if logging_level >= LOG_LEVEL_ERROR then
        log(ERROR_PREFIX, ...)
    end
end

function logging.LogInfo(...)
    if logging_level >= LOG_LEVEL_INFO then
        log(INFO_PREFIX, ...)
    end
end

function logging.LogTestStepStart(testname, subtestname, subsubtestname)
    _log(string.format(TEST_START_PREFIX_FORMAT, TP_ID or "main", MAIN_INDEX or 0, TECH_INDEX or 0, THREAD_ID or "", testname, subtestname, subsubtestname))
end

function logging.LogTestPass(testname, subtestname, subsubtestname)
    _log(string.format(TEST_PASS_PREFIX_FORMAT, TP_ID or "main", MAIN_INDEX or 0, TECH_INDEX or 0, THREAD_ID or "", testname, subtestname, subsubtestname))
end

function logging.LogTestFail(testname, subtestname, subsubtestname)
    _log(string.format(TEST_FAIL_PREFIX_FORMAT, TP_ID or "main", MAIN_INDEX or 0, TECH_INDEX or 0, THREAD_ID or "", testname, subtestname, subsubtestname))
end

return logging
