-- Data Reporting utils
local DataReportingUtils = {}

local SystemUtils = require "ALE.SystemUtils"
local StringUtils = require "ALE.StringUtils"
local FileUtils   = require "ALE.FileUtils"


--! @brief              Helper function to convert integer priority to DataReporting priority type
--! @param priority     Integer value for a FOMs priority level
--! @returns            DataReporting priority type
local function getParametricPriority(priority)

    local paramPriority = nil

    if priority == 0 then
        paramPriority = DataReporting.priorityRealtimeWithAlarm()
    elseif priority == 1 then
        paramPriority = DataReporting.priorityRealtime()
    elseif priority == 2 then
        paramPriority = DataReporting.priorityDelayedWithDailyAlarm()
    elseif priority == 3 then
        paramPriority = DataReporting.priorityDelayedImport()
    elseif priority == 4 then
        paramPriority = DataReporting.priorityArchive()
    elseif priority == 5 then
        paramPriority = DataReporting.priorityInfoOnly()
    elseif priority == -2 then
        paramPriority = DataReporting.priorityStationCalibrationAudit()
    else
        error("(@getParametricPriority) Priority is invalid: " .. tostring(priority))
    end

    return paramPriority
end


--! @brief              Helper function to determine if a priority level is enabled
--! @param priority     Integer value for a FOMs priority level
--! @param prioritiesFilter   Dictionary of enabled FOM priority levels
--! @returns            true if FOM priority is enabled, false otherwise
local function checkPriorityEnabled(priority, prioritiesFilter)

    if prioritiesFilter ~= nil then
        return prioritiesFilter[tostring(priority)] == true
    end

    -- If no priority is specified, then all priority levels are uploaded
    return true

end

--! @brief Initialize data reporting
--! @param sw_name Software name for PDCA
--! @param sw_version Software version for PDCA
--! @param limits_version Limits version for PDCA
--! @param dut_sn DUT serial number for PDCA
function DataReportingUtils.InitDataReporting(sw_name, sw_version, limits_version, dut_sn)
    if DataReporting.getPrimaryReporter ~= nil then
        local reporter = DataReporting.getPrimaryReporter()
        reporter.primaryIdentity(dut_sn)
        reporter.softwareInfo(sw_name, sw_version, limits_version)
    else
        DataReporting.primaryIdentity(dut_sn)
        DataReporting.limitsVersion(limits_version)
    end
end

--! @brief Add binary record to PDCA report
--! @returns Record report
function DataReportingUtils.AddBinaryRecord(value, test, sub_test, sub_sub_test, failure_reason)
    local reporter = nil
    if DataReporting.getPrimaryReporter ~= nil then
        reporter = DataReporting.getPrimaryReporter()
    end

    test = StringUtils.AbbreviateMiddle(test, 64)
    sub_test = StringUtils.AbbreviateMiddle(sub_test, 64)
    sub_sub_test = StringUtils.AbbreviateMiddle(sub_sub_test, 64)

    local report = DataReporting.createBinaryRecord(value, test, sub_test, sub_sub_test)
    if failure_reason ~= nil then
        failure_reason = StringUtils.AbbreviateMiddle(failure_reason, 512)
        report.addFailureReason(failure_reason)
    end

    if reporter ~= nil then
        reporter.submit(report)
    else
        DataReporting.submit(report)
    end

    return report
end


--! @brief Add parametric record to PDCA report
--! @param priority Integer value for a FOMs priority level (optional)
--! @returns Parametric record report
--! @todo Needs to be tested with NULL limits
function DataReportingUtils.AddParametricRecord(value, units, u_limit, rlx_u_limit, l_limit,
                                                rlx_l_limit, test, sub_test, sub_sub_test, priority)
    local reporter = nil
    if DataReporting.getPrimaryReporter ~= nil then
        reporter = DataReporting.getPrimaryReporter()
    end
    local report = DataReporting.createParametricRecord(value, test, sub_test, sub_sub_test)

    if not (u_limit == nil and rlx_u_limit == nil and l_limit == nil and rlx_l_limit == nil) then
        report.applyLimit(rlx_l_limit, l_limit, u_limit, rlx_u_limit, units)
    end

    if priority ~= nil then
        local paramPriority = getParametricPriority(tonumber(priority))
        report.setPriority(paramPriority)
    end

    if reporter ~= nil then
        reporter.submit(report)
    else
        DataReporting.submit(report)
    end
    return report
end

--! @brief Add atribute to PDCA report
--! @returns Record report
function DataReportingUtils.AddAttribute(key, value)
    local reporter = nil
    if DataReporting.getPrimaryReporter ~= nil then
        reporter = DataReporting.getPrimaryReporter()
    end
    local report = DataReporting.createAttribute(key, value)

    if reporter ~= nil then
        reporter.submit(report)
    else
        DataReporting.submit(report)
    end

    return report
end

--! @brief Add fixtureID and headID to PDCA report
function DataReportingUtils.AddFixtureIDheadID(fixtureID, headID)
    if DataReporting.getPrimaryReporter ~= nil then
        local reporter = DataReporting.getPrimaryReporter()
        reporter.fixtureID(fixtureID, headID)
    else
        DataReporting.fixtureID(fixtureID, headID)
    end
end

--! @brief              Helper function to trace blob pre-registration in Group.createArchives
--! @details            Log blob runtime usage with Archive.addPathName in a dedicated csv file:
--!                     trace blob name, operation success, associated path
--!                     main use case is tracing runtime blob names, paths, and missed
--!                     pre-registrations to Group.createArchives
--!
--! @param blob_key     blob archive name supplied to Archive.addPathName
--! @param status       true if succeeded Archive.addPathName, false otherwise
--! @param dir_path     path to the blob supplied to Archive.addPathName
--!
--! @returns            true if success, false otherwise
function DataReportingUtils.HelperLogAddBlobToArchive(blob_key, status, dir_path)
    local func_title = "@DataReportingUtils.HelperLogAddBlobToArchive: "
    print(func_title .. "name =" .. tostring(blob_key) .. ", status =" .. tostring(status) ..
          ", path =" .. tostring(dir_path))
    local ret = false
    if (Device and Device.userDirectory) then  -- use the device spool
        csv_log_file_basename = "addedBlobs.csv"
        -- TBD: create in device system folder to ensure upload into Insight
        csv_log_file = FileUtils.joinPaths(Device.userDirectory,"../system",csv_log_file_basename)
        csv_line = tostring(blob_key) .. ',' .. tostring(status) .. ',' .. tostring(dir_path) .. '\n'
        print(func_title .. "csv_line =" .. tostring(csv_line))
        print(func_title .. "append to file " .. tostring(csv_log_file))
        FileUtils.WriteStringToFile(csv_log_file, csv_line, "a")
        ret = true -- assume successful
    else
        print(func_title .. "IE: ignored, no Device user directory")
    end
    return ret
end

--! @brief              Add blob to PDCA report via Archive hook
--!
--! @param dir_path     path to the blob
--! @param blob_key     blob archive base name (should pre-register in Group.createArchives, assuming .zip as suffix)
--!
--! @returns            true if success, false otherwise
function DataReportingUtils.AddBlobToArchive(dir_path, when, blob_key)
    local func_title = "@DataReportingUtils.AddBlobToArchive: "
    print(func_title .. "path =" .. tostring(dir_path) .. ", when =" .. tostring(when) ..
          ", name =" .. tostring(blob_key))
    local status = nil
    local ret = nil
    if Archive then  -- use Archive hook from Atlas2 2.31.x, DataReporting.createBlob() is obsolete
        -- assuming actual registered archive name ends with "*.zip"
        if (type(blob_key) == "string") then
            local suffix = ".zip"
            if not (StringUtils.EndsWith(blob_key, suffix)) then
                blob_key = blob_key .. suffix
                print(func_title .. "assuming zipped archive, modify archive name =" .. tostring(blob_key))
            end
        end
        if blob_key then  -- archive name supplied
            status, ret = pcall(Archive.addPathName, dir_path, when, blob_key)
            if not status then
                print(func_title .. "IE: " .. tostring(ret))
            end
            DataReportingUtils.HelperLogAddBlobToArchive(blob_key, status, dir_path)
        end
        if not status then  -- attempt default archive
            if blob_key then
                -- we should not get here, yet to salvage data reporting use default
                print(func_title .. "Warning: is \"" .. tostring(blob_key) ..
                      "\" registered by the Group.createArchives function?")
                print(func_title .. "to salvage data reporting, attempt fallback into default" ..
                      "system archive (failed name =" .. tostring(blob_key) .. ')')
            end
            status, ret = pcall(Archive.addPathName, dir_path, when)
            if not status then
                print(func_title .. "fallback IE: " .. tostring(ret))
            end
        end
    else
        print(func_title .. "IE: no Archive hook")
    end
    return ret
end

--! @brief              Add blob to PDCA report
--!
--! @param dir_path     path to the blob
--! @param blob_key     blob description name
--!
--! @returns            true if success, false otherwise
function DataReportingUtils.AddBlob(dir_path, blob_key)
    local func_title = "@DataReportingUtils.AddBlob: "

    -- for keeping backward compatible behavior for nil blob_key
    -- code section moved before potential redirection to Archive hook
    -- reimplemented, the only non-backward compatible is removing trailing '/' (from a directory)
    -- the '/' artifact anyway was replaced to '_' in Insight, and could cause mismatch to a registered archive name
    if blob_key == nil then
        blob_key = FileUtils.GetFileName(dir_path)
        local function __trim_to_char(str, char)
          local indx = string.find(str, "%" .. char)
          if indx then str = str:sub(1,indx-1) end
          return str
        end
        blob_key = __trim_to_char(blob_key, '.')  -- remove file suffix if exists
        blob_key = __trim_to_char(blob_key, '/')  -- remove trailing directoy '/' if exists
        print(func_title .. "replace nil blob_key =" .. tostring(blob_key))
    end

    if not DataReporting.createBlob then  -- use Archive hook from Atlas2 2.31.x, DataReporting.createBlob() is obsolete
        print(func_title .. "obsolete DataReporting.createBlob, redirect to Archive hosting hook (policy =now)")
        return DataReportingUtils.AddBlobToArchive(dir_path, Archive.when.now, blob_key)
    end

    local _, UUIDstdout = SystemUtils.RunCommandAndCheck('uuidgen')
    UUIDstdout = string.gsub(UUIDstdout, "\n", "")
    local zip_path = "/tmp/" .. UUIDstdout .. ".zip"

    SystemUtils.RunCommandAndCheck('ditto -c -k --sequesterRsrc --keepParent ' .. dir_path .. " " .. zip_path)

    local reporter = nil
    if DataReporting.getPrimaryReporter ~= nil then
        reporter = DataReporting.getPrimaryReporter()
    end

    local report = DataReporting.createBlob(blob_key, zip_path)
    if (report.setDefer) then     -- backward compatibility, setDefer not supported in older DataReporting legacy
        report.setDefer(false)    -- do not defer the report to end of test
    end

    if reporter ~= nil then
        reporter.submit(report)
    else
        DataReporting.submit(report)
    end

    SystemUtils.RunCommandAndCheck("rm " .. zip_path)
    return report
end

local function FlattenRecursive(arg, separator, prefix)
    local result = {}

    if type(arg) == "table" then
        for k, v in pairs(arg) do
            local final_prefix = ""

            if prefix ~= "" then
                final_prefix = prefix .. "_"
            end

            local flat = FlattenRecursive(v, separator, final_prefix .. tostring(k))
            for flat_key, flat_val in pairs(flat) do
                result[flat_key] = flat_val
            end
        end
    else
        result = {[prefix]=arg}
    end

    return result
end

--! @brief Flattens tree-like table into a single level table (key/value pairs)
--! @details The key name for a resulting table is built by concatenating parent node key name and child node key names
--!          separated by specified string
function DataReportingUtils.FlattenTable(tbl, separator)
    --Recursive local functions need to be assigned to a variable before calling
    local flattenRecursive = FlattenRecursive
    return flattenRecursive(tbl, separator, "")
end

--! @brief Compare measurement values against limits, and add each measurement to Insight as a parametric record
--! @param measurements                 Array of measurements
--! @param limits                       Array of limits
--! @param test                         Test name in Insight (optional)
--! @param subtest                      Subtest name in Insight (optional)
--! @param priorities_filter            Dictionary of enabled FOM priority levels (optional)
--! @param only_metrics_with_limits     Boolean, tells whether to add metrics with limits or not, true means add
--!                                     only the metrics which has limits  (optional)
--! @returns                            missing_metrics_based_on_limits_table -
--!                                     list of metrics which were missing in measurements (input table)
--! @returns                            added_reports - table of reports actually submitted
function DataReportingUtils.AddTestRecords(measurements,
                                            limits,
                                            test,
                                            sub_test,
                                            priorities_filter,
                                            only_metrics_with_limits)
    only_metrics_with_limits = only_metrics_with_limits or false

    local added_reports = {}
    local missing_metrics_based_on_limits_table = {}
    for key, value in pairs(limits) do
        if priorities_filter == nil then
            missing_metrics_based_on_limits_table[key] = value
        elseif checkPriorityEnabled(tonumber(value.priority), priorities_filter) then
            missing_metrics_based_on_limits_table[key] = value
        end
    end

    for key, value in pairs(measurements) do
        local tmp_test = test
        local tmp_sub_test = sub_test
        local tmp_sub_sub_test = nil
        local limit = limits[key]
        local upper_limit = nil
        local lower_limit = nil
        local relaxed_upper_limit = nil
        local relaxed_lower_limit = nil
        local units = nil
        local priority

        local number_val = tonumber(value)
        -- check the value for being nil or NaN
        if number_val ~= nil then
            if tmp_test == nil and tmp_sub_test == nil then
                tmp_test = key
                tmp_sub_sub_test = nil
            elseif tmp_test ~= nil and tmp_sub_test == nil then
                tmp_sub_test = key
                tmp_sub_sub_test = nil
            elseif tmp_test ~= nil and tmp_sub_test ~= nil then
                tmp_sub_sub_test = key
            else
                error("tmp_test must be != nil if tmp_sub_test != nil")
            end

            if limit ~= nil then
                units = limit.units
                upper_limit = limit.upperLimit
                lower_limit = limit.lowerLimit
                relaxed_upper_limit = limit.relaxedUpperLimit
                relaxed_lower_limit = limit.relaxedLowerLimit

                -- Support for condition where spec sheet does not have priority column
                if limit.priority == nil then
                    -- Default priority value is 0
                    priority = 0
                else
                    priority = limit.priority
                end
            else
                -- Default priority value is 0
                priority = 0
                print("No limit for: " .. tostring(tmp_test) .. " " .. tostring(tmp_sub_test) .. " " ..
                      tostring(tmp_sub_sub_test))
            end
            if limit == nil and only_metrics_with_limits then
                print("Warning: skipping key " .. key
                 .. " - since it doesn't have limits but required [only_metrics_with_limits = "
                 .. tostring(only_metrics_with_limits) .. "]")
            else
                local report = nil
                if priorities_filter == nil then
                    -- If the user does not provide any filtering dictionary,
                    -- then call AddParametricRecord without priorities
                    report = DataReportingUtils.AddParametricRecord(number_val, units, upper_limit, relaxed_upper_limit,
                                                        lower_limit, relaxed_lower_limit, tmp_test, tmp_sub_test,
                                                        tmp_sub_sub_test)
                    missing_metrics_based_on_limits_table[key] = nil
                elseif checkPriorityEnabled(tonumber(priority), priorities_filter) then
                    -- If the user does provide a filtering dictionary, then call checkPriorityEnabled()
                    -- to perform the filtering
                    report = DataReportingUtils.AddParametricRecord(number_val, units, upper_limit, relaxed_upper_limit,
                                                        lower_limit, relaxed_lower_limit, tmp_test, tmp_sub_test,
                                                        tmp_sub_sub_test, priority)
                    missing_metrics_based_on_limits_table[key] = nil
                end
                table.insert(added_reports, report)
            end
        else
            print("Warning: skipping key " .. key .. " value is not a number: " .. tostring(value))
        end
    end
    return missing_metrics_based_on_limits_table, added_reports
end

--! @brief Compare measurement values against limits, and add each measurement to Insight as a parametric record
--! @details uploads parameters only if measurement are mentioned in the limits unlike AddTestRecords that uploads
--!          regardless of parameter is mentioened in limits or not
--! @param measurements         Array of measurements
--! @param limits               Array of limits
--! @param test                 Test name in Insight (optional)
--! @param subtest              Subtest name in Insight (optional)
--! @param priorities_filter    Dictionary of enabled FOM priority levels (optional)
--! @returns                            missing_metrics_based_on_limits_table -
--!                                     list of metrics which were missing in measurements (input table)
function DataReportingUtils.AddTestRecordsHavingLimitKeys(measurements, limits, test, sub_test, priorities_filter)
    return DataReportingUtils.AddTestRecords(measurements, limits, test, sub_test, priorities_filter, true)
end

--! @brief Similar to AddTestRecords() function.
--! @details Treats 'test' as a concatenation
--!        of 'test', 'subtest' and 'subsubtest' separated by a specified separator.
--!        E.g. 'color_test' -> test:'color', subtest:'test'
--!        if 'test' value is not provided, measurement key names will treated as a concatenation above

--! @param measurements    Array of measurements
--! @param limits          Array of limits
--! @param test            Test name in Insight (optional)
--! @param seprator        Separator string to use when splitting test names, e.g. "_"
function DataReportingUtils.AddSeparatedRecords(measurements, limits, test, separator)
    for key, value in pairs(measurements) do
        local tmp_test = test
        local tmp_sub_test = nil
        local tmp_sub_sub_test = nil
        local limit = limits[key]
        local upper_limit = nil
        local lower_limit = nil
        local relaxed_upper_limit = nil
        local relaxed_lower_limit = nil
        local units = nil

        local number_val = tonumber(value)

        if number_val ~= nil then
            local split_test = StringUtils.Tokenize(key, separator)

            if #split_test < 2 then
                if tmp_test == nil then
                    tmp_test = key
                else
                    tmp_sub_test = key
                end
            elseif #split_test == 2 then
                if tmp_test == nil then
                    tmp_test = split_test[1]
                    tmp_sub_test = split_test[2]
                else
                    tmp_sub_test = split_test[1]
                    tmp_sub_sub_test = split_test[2]
                end
            elseif #split_test == 3 then
                if tmp_test == nil then
                    tmp_test = split_test[1]
                    tmp_sub_test = split_test[2]
                    tmp_sub_sub_test = split_test[3]
                else
                    tmp_sub_test = split_test[1]
                    tmp_sub_sub_test = split_test[2] .. separator .. split_test[3]
                end
            elseif #split_test > 3 then
                if tmp_test == nil then
                    tmp_test = split_test[1]
                    tmp_sub_test = split_test[2]
                    --Put remaining text into the last item
                    local start = #(tmp_test .. separator .. tmp_sub_test .. separator)
                    local remaining_text = string.sub(key, start + 1)
                    tmp_sub_sub_test = remaining_text
                else
                    tmp_sub_test = split_test[1]
                    local start = #(tmp_sub_test .. separator)
                    local remaining_text = string.sub(key, start + 1)
                    tmp_sub_sub_test = remaining_text
                end
            end

            if limit ~= nil then
                upper_limit = limit.upperLimit
                lower_limit = limit.lowerLimit
                relaxed_upper_limit = limit.relaxedUpperLimit
                relaxed_lower_limit = limit.relaxedLowerLimit
                units = limit.units
            else
                print("No limit for: " .. tostring(tmp_test) .. " " .. tostring(tmp_sub_test) .. " " ..
                      tostring(tmp_sub_sub_test))
            end

            DataReportingUtils.AddParametricRecord(number_val, units, upper_limit, relaxed_upper_limit,
                                                   lower_limit, relaxed_lower_limit, tmp_test, tmp_sub_test,
                                                   tmp_sub_sub_test)
        else
            print("Warning: skipping key " .. key .. " value is not a number: " .. tostring(value))
        end
    end
end

--! @brief Parses the limits table read from csv file into a dictionary.
--! @details Column headers are used as key names in the resulting dictionary:
--!          The following input: {{"ulimit", "llimit"}, {100, 0}}
--!          will be converted into {"ulimit" : "100", "llimit" : "0"}
--! @param limitsTableWithHeader    Table read from limits csv file. Includes the first row of header
function DataReportingUtils.ParseLimitsTable(limitsTableWithHeader)
    local header = limitsTableWithHeader[1]
    local dict = {}

    for i, v in pairs(limitsTableWithHeader) do
        if i > 1 then
            local dict1 = {}

            for j, w in pairs(v) do
                if j > 2 then
                    local keyname = StringUtils.TrimControlChars(header[j])
                    dict1[keyname] = StringUtils.TrimControlChars(w)
                end
            end

            --Convert all limits to either number or nil
            if dict1.upperLimit == "" then
                dict1.upperLimit = nil
            end
            if dict1.upperLimit then
                dict1.upperLimit = tonumber(dict1.upperLimit)
            end

            if dict1.lowerLimit == "" then
                dict1.lowerLimit = nil
            end
            if dict1.lowerLimit then
                dict1.lowerLimit = tonumber(dict1.lowerLimit)
            end

            if dict1.relaxedUpperLimit == "" then
                dict1.relaxedUpperLimit = nil
            end
            if dict1.relaxedUpperLimit then
                dict1.relaxedUpperLimit = tonumber(dict1.relaxedUpperLimit)
            end

            if dict1.relaxedLowerLimit == "" then
                dict1.relaxedLowerLimit = nil
            end
            if dict1.relaxedLowerLimit then
                dict1.relaxedLowerLimit = tonumber(dict1.relaxedLowerLimit)
            end

            if dict1.priority == "" then
                dict1.priority = nil
            end
            if dict1.priority then
                dict1.priority = tonumber(dict1.priority)
            end

            local groupname = v[1]
            if dict[groupname] == nil then
                dict[groupname] = {}
            end

            local testname = v[2]
            dict[groupname][testname] = dict1
        end
    end

    return dict
end


local function ErrorHandler(err)
    local retErr = {}
    if type(err) == "table" then
        retErr = err
        retErr.stacktrace = debug.traceback(nil, nil, 0)
    elseif type(err) == "string" then
        retErr.message = err
        retErr.stacktrace = debug.traceback(nil, nil, 0)
    else
        print("unhandled error object raised type " .. type(err))
    end
    return retErr
end

--! @brief This is a convenience function that catches exception and creates a record using the name
--!         To throw errors that map to subtestname and subsubtestname and error message create an
--!         error table with keys subtestname, subsubtestname and message. This function handles 2 types
--!         of errors raised - standard error message ie. error("message"),
--!         or custom table ie error({name = {"name1", "name2"}, message = "errMsg"})
--!
--! @param f function to call
--! @param ... args to the function separated by commas
--! returns status, resp value from the original function otherwise throw original exception message string
function DataReportingUtils.CallAndReportError(name, f,...)
  local status, resp = xpcall(f, ErrorHandler, ...)
  if not status and resp ~= nil then
    print(resp.stacktrace)
    local subtestname = ""
    local subsubtestname = ""
    local message = ""
    if resp.name and resp.name[1]  then
        subtestname = resp.name[1]
    end
    if resp.name and resp.name[2] then
        subsubtestname = resp.name[2]
    end
    if resp.message then
        message = resp.message
    end
    DataReportingUtils.AddBinaryRecord(false, name, subtestname, subsubtestname, message)
    error(resp.message)
  end
  return status, resp
end



return DataReportingUtils