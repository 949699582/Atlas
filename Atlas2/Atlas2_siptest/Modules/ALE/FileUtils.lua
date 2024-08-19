local FileUtils = {}

local SystemUtils = require "ALE.SystemUtils"
local StringUtils = require "ALE.StringUtils"
local TypeUtils = require "ALE.TypeUtils"


--! @brief Extract directory from the path to a file
function FileUtils.GetPath(path)
    local handle = io.popen(string.format("dirname '%s'", path))
    local result_str = handle:read("*a")
    handle:close()

    return StringUtils.TrimWhitespace(result_str)
end

--! @brief Get current user home directory
function FileUtils.GetCurrentUserHomeDir()
    local home = os.getenv("HOME")
    if home ~= nil then
        return home
    end

    local f     = assert (io.popen ("echo ~"))
    local f_itr = f:lines()
    home        = f_itr(1)
    if home == nil then
        error("Could not find home directory path.")
    end

    return home
end

--! @brief Get current user home directory
function FileUtils.GetAtlasHomeDir()
    local assets_path = (Atlas and Atlas.assetsPath) or (Device and Device.assetsPath)
    if assets_path then
        return FileUtils.GetDirectoryName(assets_path)
    else
        error("couldn't get assets path")
    end
end

--! @brief Returns Atlas2 Resources directory path
--! @note The function is obsolete.
--!       Use either `Group.assetsPath` or `Device.assetsPath` instead
function FileUtils.PathForResource(name)
    return FileUtils.GetAtlasHomeDir() .. "/Resources/" .. name
end

--! @brief Returns Atlas2 Assets directory path
function FileUtils.PathForAsset(name)
    local assets_path = (Atlas and Atlas.assetsPath) or (Device and Device.assetsPath)
    if assets_path then
        return FileUtils.joinPaths(assets_path, name)
    end
    return FileUtils.GetAtlasHomeDir() .. "/Assets/" .. name
end

--! @brief Extract directory name from a full file path
function FileUtils.GetDirectoryName(path)
    return path:match("(.*" .. "/" .. ")")
end

--! @brief Extract file name from full path
function FileUtils.GetFileName(path)
    return path:match("^.+/(.+)$")
end

--! @brief Extract file extension from file path
function FileUtils.GetFileExtension(path)
    return path:match("^.+(%..+)$")
end

--! @brief Write string to file
--! @param path Target file path
--! @param str String to Write
--! @param mode Write mode: "a" - append, "w" - create new file
function FileUtils.WriteStringToFile(path, str, mode)
    if mode then
        assert(mode == "w" or mode == "a")
    else
        mode = "w"
    end

    local f = assert(io.open(path, mode))
    success, err = pcall(f.write, f, str)
    assert(f:close())

    if not success then
        error(err)
    end
end

--! @brief Returns true if specified file exists
function FileUtils.FileExists(path)
    local f = io.open(path, "r")

    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

--! @brief Read the entire file as a single string
function FileUtils.ReadFileAsString(path)
    local f = assert(io.open(path, "r"))
    status, res = pcall(f.read, f, "*all")
    assert(f:close())

    if not status then
        error(res)
    end

    return res
end

--! @brief Create full directory path
function FileUtils.CreateDirectoryPath(path)
    SystemUtils.RunCommandAndCheck("mkdir -p " .. path)
end

--! @brief Remove file or directory with all files and subdirs
function FileUtils.RemovePath(path)
    SystemUtils.RunCommandAndCheck("rm -rf " .. path)
end

--! @brief Returns the list of files and dirs in specified directory as an array of strings
function FileUtils.ListDirectory(path)
    local _, stdout = SystemUtils.RunCommandAndCheck("ls -A " .. path)
    local res = {}

    for i, filename in ipairs(StringUtils.Tokenize(stdout, "\n")) do
        res[i] = filename
    end

    return res
end

--! @brief Test if a file is writable, readable, or executable by current user
--! @param file_path Target file path
--! @option file_path Access to test: "r" - readable, "w" - writable, "x" - executable
--! @returns true of false
function FileUtils.TestFileAccess(file_path, option)
    assert(option == "r" or option == "w" or option == "x", "Bad option: " .. tostring(option))
    local command = "test " .. "-" .. option .. " " .. file_path
    exit_code = SystemUtils.RunCommand(command)
    return exit_code == 0
end

--! @brief          Join one or more paths using the Posix path syntax. If the second or a later argument is an absolute
--!                 path, it will discard the previous paths.
--!
--! @param path1    file path
--! @param path2    file path
--! @param ...      additional paths
--!
--! returns         resulting combined paths from input
--!
function FileUtils.joinPaths(path1, path2, ...)
    TypeUtils.assertString(path1)
    TypeUtils.assertString(path2)

    if select("#", ...) > 0 then
        local partial_path = FileUtils.joinPaths(path1,path2)
        local args = {...}
        for i = 1, #args do
            TypeUtils.assertString(args[i])
            partial_path = FileUtils.joinPaths(partial_path, args[i])
        end
        return partial_path
    end

    if string.sub(path2, 1, 1) == "/" then
        return path2
    end

    local last_char = string.sub(path1, #path1, #path1)
    if last_char ~= "/" and last_char ~= ":" and last_char ~= "" then
        path1 = path1 .. "/"
    end

    return path1 .. path2
end

function FileUtils.RemoveFileExtension(filepath)
    local file_no_extension = string.gsub(filepath, FileUtils.GetFileExtension(filepath), "")

    return file_no_extension
end

return FileUtils
