local StringUtils = require "ALE.StringUtils"
local TypeUtils = require "ALE.TypeUtils"

local ADCDUT = {}

--! @brief Sets the URL used to connect to the DUT
--! @param adcPlugin The instance of ADCDUT plugin
--! @param deviceName. Name of DUT in Atlas System.
function ADCDUT.SetUrlByName(adcPlugin, deviceName)
    print("Device Name: " .. deviceName)

    local transport = Group.getDeviceTransport(deviceName)
    print("DUT URL: " .. transport)

    adcPlugin.setURL(transport)
end

--! @brief Start a new task.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full path to the command to run (use e.g. /bin/ls instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @return Dictionary of: {"task":"", "stdio":"", "stderr":""}.
function ADCDUT.StartTask(adcPlugin, command, arguments)
    assert(type(command) == "string", "Command must be a string")
    assert(type(arguments) == "table", "Arguments must be a table")

    local commBuilder

    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local task = {}
    task["task"] = adcPlugin.createRemoteTask()
    task["task"].setExecutablePath(command)
    task["task"].setArguments(arguments)

    local stdio = commBuilder.createCommPlugin(task["task"].standardInputOutputChannel())
    task["stdio"] = stdio
    local stderr = commBuilder.createCommPlugin(task["task"].standardErrorChannel())
    task["stderr"] = stderr

    task["task"].launch()

    -- Call open() is mandatory in Atlas 2.33
    -- In Atlas less than 2.33, after remote task launch, stdio/stderr already opened.
    -- reopen stdio/stderr will cause error
    if (Atlas.compareVersionTo("2.33") ~= Atlas.versionComparisonResult.lessThan) then
        stdio.open()
        stderr.open()
    end

    --TODO: check status
    -- There is no way of checking if the task started succesfully,
    -- because createRemoteTask always return a taskKey.
    -- And task.launch() returns nothing.

    return task
end

--! @brief Write to stdin of a task.
--! @param commPlugin the communication Plugin created in StartTask
--! @param str String to be written.
--! @param lineTerminator character appended to str, can be nil.
function ADCDUT.WriteToStdIn(commPlugin, str, lineTerminator)
    assert(type(str) == "string", "str must be a string")

    -- Need to append line terminator to str following the request of remote side
    if (lineTerminator ~= nil) then
        commPlugin.setLineTerminator(lineTerminator)
    end

    commPlugin.write(str)
end

--! @brief Keep reading from stdout of a task until the contents match the string in waitfor param.
--! @param commPlugin the communication Plugin created in StartTask
--! @param waitfor string to match in output. If nil, this is skipped.
--! @param timeout How many seconds to keep waiting for the waitfor match.
function ADCDUT.ReadFromStdOut(commPlugin, waitfor, waitfor_timeout)

    local timeout = waitfor_timeout or 1
    local resp
    local status

    -- "waitfor" here means expected delimiter send from remote side
    if (waitfor == nil) then
        status, resp = pcall(commPlugin.read, timeout)

        if not status then
            print("Failed to read stdio")
            resp = ""
        end
    else
        commPlugin.setDelimiter(waitfor)
        status, resp = pcall(commPlugin.read, timeout)

        -- ADC Plugin fails when waitfor match fails
        -- Try to get the whole output from stdout if waitfor match failed
        if not status then
            print("ADCDUT- Failed to match: " .. waitfor)
            -- resp here maybe only some debug info
            -- maybe we can drop this "print"
            print("Error: " .. resp)
            status, resp = pcall(commPlugin.read, timeout, "")
            if status then
                local errString = "Wait for [" .. waitfor .. "] failed with output '" .. resp .. "'"
                error(errString)
            end

            local errString = "Wait for [" .. waitfor .. "] failed"
            error(errString)
        end
    end

    return resp
end

--! @brief Keep reading from stderr of a task until the contents match string in waitfor param.
--! @param commPlugin the communication Plugin created in StartTask
--! @param waitfor Regular expression string to search for. If nil, this is skipped.
--! @param waitfor_timeout How many seconds to keep waiting for the waitfor match.
--! @return Stderr contents as a string. Throws exception if waitfor match is not found by timeout.
function ADCDUT.ReadFromStdErr(commPlugin, waitfor, waitfor_timeout)

    local resp
    local timeout = waitfor_timeout or 1

    if (waitfor == nil) then
        status, resp = pcall(commPlugin.read, timeout)
        if not status then
            print("Failed to read stderr")
            resp = ""
        end
    else
        commPlugin.setDelimiter(waitfor)
        resp = commPlugin.read(timeout)

        --Currently ADC Plugin returns an empty string if waitfor match fails
        assert(resp ~= "", "Failed to match waitfor: " .. waitfor)
    end

    return resp
end

--! @brief Attempt to terminate a task by sending SIGTERM.
--! @param task Task to terminate.
--! @param timeout Optional timeout (in seconds) to wait for the task to exit
--! @return nil.
--! @throws Lua error if task has not ended by exitTimeout
function ADCDUT.TerminateTask(task, timeout)
    local sigTerm = 15
    local exitTimeout = timeout or 3

    task.sendSignal(sigTerm)
    print(string.format("waitUntilExit(%.1f)...", exitTimeout))
    task.waitUntilExit(exitTimeout) -- will throw an error if task has not ended by exitTimeout
end

--! @brief Kill a remote task by sending SIGKILL.
--! @param task Task to kill.
--! @return nil.
function ADCDUT.KillTask(task)
    local sigKill = 9
    task.sendSignal(sigKill)
end

--! @brief Execute a sequence of shell commands
--! @details The sequence is an array of command definitions where
--! each command definition is an array of the following elements:
--! [1]: string representing command to be executed including all arguments space separated
--! [2]: regex to extract the individual fields from the response or nil to return the entire response
--! [3]: timeout value for this command in seconds
--! [4]: string key name for this command output in the resulting sequence execution output
--!
--! Commands might contain a placeholder in the following format: ${placeholder_name}
--! The parameters arg of this function must contain dictionary entries to resolve
--! all placeholders mentioned in all commands.
--!
--! The output of the function is a dictionary where each entry represents individual command
--! output. If key name for the result is not provided - the individual command result won't be included into the output
--!
--! Example:
--!	sequence = {
--!		{"/usr/local/bin/diagstool lcdmura --p3 ${r},${g},${b}", "", 5, ""},
--!		{"/usr/local/bin/OSDToolbox version 2>&1", "", 5, "SWBundleVersion"},
--!	}
--!	result = dut.ExecuteSequence(sequence, {["r"] = 1023, ["g"] = 0, ["b"] = 0})
--!
--! result is: {["SWBundleVersion"] = { [1] = "BuildVersion	FFFFF"} }
--!
--! @param adcPlugin The instance of ADCDUT plugin
--! @param sequence Array of command definitions
--! @param parameters Dictionary with parameters to be interpolated into the commands
--!
--! @returns Dictionary with individual command responses
function ADCDUT.ExecuteSequence(adcPlugin, sequence, parameters)

    local sequence_result = {}

    for _, item in ipairs(sequence) do
        local command       = StringUtils.InterpolateString(item[1], parameters)
        local expected_resp = item[2]
        local timeout       = item[3]
        local name          = item[4]

        -- For debugging
        print("Run cmd " .. command)

        local result = ADCDUT.ExecuteTask(adcPlugin, "/bin/sh", {"-c", command}, timeout)

        -- Only store result if there's a name for the result provided
        if (name ~= "") and (name ~= nil) then
            -- Create an empty array for this command response items
            sequence_result[name] = {}

            local command_output = result["stdout"]
            if expected_resp ~= "" then
                if string.gmatch(command_output, expected_resp)() == nil then
                    print("CMD output: " .. command_output)
                    error(string.format("Didn't catch expected output: %s", expected_resp))
                end

                local match = string.gmatch(command_output, expected_resp)
                for m in match do
                    table.insert(sequence_result[name], m)
                end
            else
                table.insert(sequence_result[name], command_output)
            end
        end
    end

    return sequence_result
end

local function ExecuteRemoteTask(task, timeout)

    task.launch()

    --If timeout was triggered, status will be false
    local status, retVal = pcall(task.waitUntilExit, timeout)
    --Looks like statusStdOut/statusStdErr is always true in Atlas2.33
    local statusStdOut, stdout = pcall(task.readStdoutBuffer)
    local statusStdErr, stderr = pcall(task.readStderrBuffer)

    if not status then
        ADCDUT.KillTask(task)
        error("TIMEOUT executing command")
    end

    return {["stderrSts"] = statusStdErr, ["stderr"] = stderr,
            ["stdoutSts"] = statusStdOut, ["stdout"] = stdout,
            ["exitcode"] = retVal}
end

--! @brief Executes a shell command, and waits for it to finish.
--! @note Exception will be thrown if the command exist code is not 0.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full command string including the executable and arguments
--! @param timeout How many seconds to wait for the task to finish
--! @return See \ref ADCDUT.ExecuteTask() return value
function ADCDUT.ExecuteShellCommand(adcPlugin, command, timeout)
    -- Apply default values if needed
    timeout = timeout or -1 -- use the default timeout if needed

    assert(type(command) == "string", "Command must be a string")
    assert(type(timeout) == "number", "Timeout must be a number")

    local task = adcPlugin.createRemoteTask()
    task.setShellCommand(command)

    return ExecuteRemoteTask(task, timeout)
end

--! @brief Start a new task, and wait for it to finish.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full path to the command to run (use e.g. /bin/ls instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @param timeout How many seconds to wait for the task to finish
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}.
function ADCDUT.ExecuteTask(adcPlugin, command, arguments, timeout)
    -- Apply default values if needed
    timeout = timeout or -1 -- use the default timeout if needed

    assert(type(command) == "string", "Command must be a string")
    assert(type(arguments) == "table", "Arguments must be a table")
    assert(type(timeout) == "number", "Timeout must be a number")

    local task = adcPlugin.createRemoteTask()
    task.setExecutablePath(command)
    task.setArguments(arguments)

    return ExecuteRemoteTask(task, timeout)
end

-- - - - - - -
-- Copy files
-- - - - - - -

--! The function doesn't work for now.
--! Radar rdar://76044612 opened to track.
--! @brief Copy a file or directory to DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param src Path to source file or directory in Mac.
--! @param dst Path to destination directory in DUT.
--! For copying a file, the destination path must end with the exact same
--! filename as the fileame in Mac.
--! src and dst must be absolute path.
function ADCDUT.CopyToDUT(adcPlugin, src, dst)
    local paramTbl = {}

    print("Copy to DUT")
    print("HOST: " .. src)
    print(" DUT: " .. dst)

    paramTbl[src] = dst

    adcPlugin.copyToDevice(paramTbl)
end

--! @brief Copy a file or directory from DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param src Path to source file or directory in DUT.
--! @param dst Path to destination directory in Mac.
--! For copying a file, the destination path must end with the exact same
--! filename as the fileame in DUT.
--! src and dst must be absolute path.
function ADCDUT.CopyFromDUT(adcPlugin, src, dst)
    local paramTbl = {}

    print("Copy from DUT:")
    print(" DUT: " .. src)
    print("HOST: " .. dst)

    paramTbl[src] = dst

    adcPlugin.copyToHost(paramTbl)
end

-- - - - - - -
-- Create/remove dirs / file
-- - - - - - -

--! @brief Create a directory in DUT (also create sub-directories if needed).
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the directory to create in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
function ADCDUT.CreateDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.ExecuteTask(adcPlugin, "/bin/mkdir", {"-p", path}, 1)
end

--! @brief Remove a directory in DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the directory to remove in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
function ADCDUT.RemoveDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.ExecuteTask(adcPlugin, "/bin/rm", {"-rf", path}, 1)
end

--! @brief Remove a file in DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the file to remove in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
function ADCDUT.RemoveFile(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.ExecuteTask(adcPlugin, "/bin/rm", {"-f", path}, 1)
end

function ADCDUT.ListDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.ExecuteTask(adcPlugin, "/bin/ls", {"-l", path}, 1)
end

function ADCDUT.GetDutTime(adcPlugin)
    return ADCDUT.ExecuteTask(adcPlugin, "/bin/date", {}, 1)
end

function ADCDUT.PathExists(adcPlugin, path)
    TypeUtils.assertString(path)

    print("Search path: " .. path)

    local result = ADCDUT.ExecuteTask(adcPlugin, "/usr/bin/find", {"-f", path}, 1)

    if result["exitcode"] == 0 then
        print(result["stdout"])
        return true
    end

    print(result["stderr"])
    return false
end

return ADCDUT
