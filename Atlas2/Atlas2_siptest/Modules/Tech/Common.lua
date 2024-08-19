local Log = require("Matchbox/logging")
local Record = require("Matchbox/record")
local comFunc = require("Matchbox/CommonFunc")
local json = require("Matchbox/json")

Common = {}





local SKIP_FILE_LIST = {"Common.lua"}
local techPath = string.gsub(Atlas.assetsPath, "Assets", "Modules/Tech")
local techFiles = comFunc.runShellCmd("ls ".. techPath .. " | grep -i .lua$").output
-- Log.LogInfo("Lua file list: ", techFiles)
local techFileList = comFunc.splitBySeveralDelimiter(techFiles,'\n\r')

for i, file in ipairs(techFileList) do
    if not comFunc.hasVal(SKIP_FILE_LIST, file) then
        -- Log.LogInfo("Lua file: ", file)
        local requirePath = "Tech/"..file:match("(.*)%.lua")
        -- Log.LogInfo("kkkrequirePath file: ", requirePath)
        local lib = require(requirePath)
        for name, func in pairs(lib) do
            Common[name] = func
        end
    end
end








return Common
