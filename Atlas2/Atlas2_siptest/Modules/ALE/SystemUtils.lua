local SystemUtils = {}

--! @brief Sleep for specified amount of seconds
function SystemUtils.SleepSeconds(seconds)
    os.execute("sleep " .. tonumber(seconds))
end

--! @brief Run specified system command
--! @returns exit_code, stdout, stderr, exit_status, success
function SystemUtils.RunCommand(cmd)
    local stderr_path = os.tmpname()
    local stdout_path = os.tmpname()
    local success, exit_status, exit_code = os.execute(cmd .. ' > ' .. stdout_path .. ' 2> ' .. stderr_path)

    local stdout_file = io.open(stdout_path)
    local stdout = stdout_file:read("*all")
    stdout_file:close()

    local stderr_file = io.open(stderr_path)
    local stderr = stderr_file:read("*all")
    stderr_file:close()

    os.remove(stdout_path)
    os.remove(stderr_path)

    return exit_code, stdout, stderr, exit_status, success
end

--! @brief Similar to function above, but additionally asserts that exit_code is 0 and fails automatically otherwise
--! @todo Think of a better name for this function
function SystemUtils.RunCommandAndCheck(cmd)
    local exit_code, stdout, stderr, exit_status, success = SystemUtils.RunCommand(cmd)
    local err_msg = string.format("Failed command: %s, exit code: %s, stdout: %s, stderr: %s",
                    tostring(cmd), tostring(exit_code), stdout, stderr)
    assert(exit_code == 0, err_msg)
    return exit_code, stdout, stderr, exit_status, success
end

--! @brief              Build a shell command string separated by spaces using input var args.
--!
--! @param ...          arguments to be used to build the command string
--!
--! @return             (string) built sh command
--!
function SystemUtils.BuildShellCommand(...)
    local cmdstr = ""
    local args   = {...}
    for i = 0, #args do
        if args[i] then
            cmdstr = cmdstr .. " " .. args[i]
        end
    end
    return string.sub(cmdstr, 2)
end

return SystemUtils
