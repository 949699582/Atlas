local MixUtils = require 'Tech/MogulCert/MixUtils'
local SystemUtils = require 'ALE/SystemUtils'
local TableUtils = require 'ALE/TableUtils'
local util = require 'Tech/MogulCert/Utility'
local log = require 'Matchbox/logging'

local module = {}

local addr_status = 0x05
local addr_proc_control = 0x10
local addr_signature_len = 0x11
local addr_signature = 0x12
local addr_challenge_data = 0x21
local addr_cert_len = 0x30
local addr_aid_passthrough = 0x60

local rpc_client
local trinary

local rpc_timeout_ms = 6000

function module.initialize(side)
    if rpc_client == nil then
        rpc_client = Device.getPlugin("MixRPC")
        assert(rpc_client, "Cannot get MixRPC plugin")
    end

    trinary = MixUtils.get_trinary_for_side(side)
    assert(trinary, "Invalid side specified")
end

function module.initialize_TESTONLY(side)
    rpc_client = Atlas.loadPlugin("MIXRPCClientPlugin")
    rpc_client.init("localhost", 7801)

    trinary = MixUtils.get_trinary_for_side(side)
    
    local ret = rpc_client.rpc("i2sdma.i2s_open")
    if not MixUtils.is_pass(ret) then
        log.LogError("i2sdma.i2s_open failed")
        return false
    end
    ret = rpc_client.rpc(trinary .. "trinary_init", {"S0"})
    if not MixUtils.is_pass(ret) then
        log.LogError(trinary .. "trinary_init failed")
        return false
    end

    local s = string.lower(side)
    if s == "agnes" then
        s = "right"
    end
    ret = rpc_client.rpc(trinary .. "one_key_all", { s })
    if not MixUtils.is_pass(ret) then
        log.LogError(trinary .. "one_key_all failed")
        return false
    end
    log.LogInfo("TESTONLY MIX Initialization success")
    return true
end

function module.shutdown_TESTONLY()
    rpc_client.shutdown()
    log.LogInfo("TESTONLY MIX Shutdown")
end

function module.get_version()
    log.LogInfo(MixUtils.mix_dict_to_table(rpc_client.rpc("base_board.fw_version")))
end

function module.aid_read(zone, address, length)
    assert(length <= 64, "Cannot AID read more than 64 bytes at a time")

    local ret = rpc_client.rpc(trinary .. "read_cfg", { zone, address, length }, { timeout_ms = rpc_timeout_ms })
    local t =  MixUtils.mix_array_to_table(ret)
    table.remove(t, 1) -- first element is always the AID reply byte, we discard it
    return t
end

function module.aid_write(zone, address, value)
    assert(#value <= 32, "Cannot AID write more than 32 bytes at a time")

    local ret = rpc_client.rpc(trinary .. "write_cfg", { zone, address, table.unpack(value) }, { timeout_ms = rpc_timeout_ms })
    if not MixUtils.is_pass(ret) then
        log.LogError("Error in _aid_write")
        log.LogError(ret)
        return false
    end

    return true
end

-- do not use these functions directly, they should be invoked via module.read/module.write
local function _i2c_read(address, length)
    assert(length <= 128, "Cannot i2c read more than 64 bytes at a time")

    local ret = rpc_client.rpc(trinary .. "write_read", { 0x20, 8, { address }, length, 1 }, { timeout_ms = rpc_timeout_ms })
    return MixUtils.mix_array_to_table(ret)
end

-- do not use these functions directly, they should be invoked via module.read/module.write
local function _i2c_write(address, value) 
    assert(#value <= 128, "Cannot i2c write more than 64 bytes at a time")

    local ret = rpc_client.rpc(trinary .. "write", { 0x20, 8, { address, table.unpack(value) }, 0 }, { timeout_ms = rpc_timeout_ms })
    if not MixUtils.is_pass(ret) then
        log.LogError("Error in _i2c_write")
        log.LogError(ret)
        return false
    end

    return true
end

local function _check_status() 
    local ret = _i2c_read(addr_status, 1)
    if ret[1] ~= 0 then
        log.LogError("Unexpected status: " .. string.format("0x%02X", ret[1]))
        return false
    else
        return true
    end
end

function module.read(address, length)
    local ret = _i2c_read(address, length)
    SystemUtils.SleepSeconds(1)
    if _check_status() then
        return ret
    else
        log.LogError(string.format("Unexpected error reading 0x%02X bytes from address 0x%02X", length, address))
        return nil
    end
end

function module.write(address, value)
    if _i2c_write(address, value) then
        SystemUtils.SleepSeconds(1)
        return _check_status()
    else
        log.LogError(string.format("Unexpected error writing 0x%02X bytes from address 0x%02X", #value, address))
        return false
    end
end

local function _set_identity(pc_write, pc_read)
    local ret = module.write(addr_proc_control, { pc_write })
    if not ret then
        log.LogError("Error setting identity")
        return false
    end

    local id = module.read(addr_proc_control, 1)
    if id[1] ~= pc_read then
        log.LogError(string.format("Unexpected identity -- expected 0x%02X got 0x%02X", pc_read, id[1]))
        return false
    else
        return true
    end
end

function module.set_apple_identity()
    proc_control_apple_write = 0x02
    proc_control_apple_read = 0x20
    return _set_identity(proc_control_apple_write, proc_control_apple_read)
end

function module.get_cert_length()
    local lb = module.read(addr_cert_len, 2)
    local certLen = lb[1] * 256 + lb[2]
    return certLen
end

function module.read_zone(zone)
    local step = 64
    local d = {}
    local size = util.zone_size(zone)

    for i = 0, size, step do
        if size - i < step then
            step = size - i
        end
        if step > 0 then
            local c = module.aid_read(zone, i, step)
            d = TableUtils.MergeArrays(d, c)
        end
    end
    return d
end

function module.write_zone(zone, data)
    assert(#data == util.zone_size(zone), string.format("Error: Data size does not match zone size (%02X vs %02X", #data, util.zone_size(zone)))

    local step = 32
    for i = 0, util.zone_size(zone), step do
        if util.zone_size(zone) - i < step then
            step = util.zone_size(zone) - i
        end

        local d = {table.unpack(data, i + 1, i + step)}
        if #d == 0 then
            return true
        end

        local ret = module.aid_write(zone, i, d)
        if not ret then
            log.LogError("Error in _aid_write")
            return false
        end
    end

    return true
end

function module.zero_zone(zone)
    assert(zone == 8, "Error: Only zone 8 can be erased")

    return module.write_zone(zone, util.make_zeros(zone))
end

function module.lock_zone(zone)
    local pkt = 0xEA
    local pkt_response = 0xEB
    local vid = 0x02
    local pid = 0x01
    local zero = 0
    local crc = 0

    local ret = module.write(addr_aid_passthrough, { pkt, vid, pid, zone, zero, crc })
    if not ret then
        log.LogError("Error: Cannot lock zone " .. tonumber(zone))
        return false
    end

    local response = module.read(addr_aid_passthrough, 1)
    if response[1] ~= pkt_response then
        log.LogError("Error: Cannot verify zone " .. tonumber(zone) .. " locked")
        return false
    end

    return true
end

return module

