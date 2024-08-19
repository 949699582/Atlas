local OQC = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'
local json = require("Matchbox/json")
local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
local CreateRecord = require 'Tech/CreateRecord'
local Universal = require 'Tech/Universal'
function OQC.testCount(paraTab)
    local ItemCount = 1
    local userName = Universal.getUserName()
    -- local itemCountPath = '/Users/'..userName..'/Documents/TestCount.txt'
    local itemCountPath = '/vault/TestCount.txt'
    local itemCountFile = io.open(itemCountPath, "r")
    if itemCountFile ~= nil then
        io.input(itemCountFile)
        ItemCount = io.read()
        itemCountFile = io.open(itemCountPath, "w")
        io.output(itemCountFile)
        io.write(ItemCount+1)
        itemCountFile:close()
    else
        itemCountFile = io.open(itemCountPath, "w")
        io.output(itemCountFile)
        io.write(ItemCount)
        itemCountFile:close()
    end
    return ItemCount
end

return OQC