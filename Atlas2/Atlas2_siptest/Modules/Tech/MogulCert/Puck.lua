local log = require 'Matchbox/logging'
local util = require 'Tech/MogulCert/Utility'
local TableUtils = require 'ALE/TableUtils'

local module = {}

local dut

function module.initialize()
    if dut == nil then
        dut = Device.getPlugin("dut")
    end

    -- send a dummy command that wakes up mogul
    local reply = dut.send("auth read 0")

end

function module.initialize_TESTONLY()
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    CommBuilder.setLogFilePath("/tmp/dut.log", "/tmp/rawDut.log")
    CommBuilder.setDelimiter("> ")
    CommBuilder.setLineTerminator("\n")
    dut = CommBuilder.createCommPlugin("uart:///tmp/CheetahD/dev/cu.chimp-30B34B_ecli0")
    dut.open()
    return true
end

function module.initialize_MOCK()
    local functions = {
        { name = "send" }
    }

    local proxy = Atlas.loadPlugin("AtlasMockProxyPlugin")
    dut = proxy.createMockPlugin("PuckMock", functions)
end

function module.shutdown_TESTONLY()
    dut.close()
end

local function _parse_fw_reply(s, expected_len, first, last)
    local t = {}
    for k in string.gmatch(s, "(0x%x*)") do
        table.insert(t, tonumber(k))
    end

    if expected_len then 
        if #t ~= expected_len then
            log.LogError(string.format("Invalid length read. Read %d, expected %d.", #t, expected_len))
            log.LogInfo(s)
            return nil
        end
    end
    if first then
        local i = table.remove(t, 1)
        if i ~= first then
            log.LogError(string.format("Error processing command, got %02X expected %02X", i, first))
            log.LogInfo(s)
            return nil
        end
    end
    if last then
        local i = table.remove(t)
        if i ~= last then
            log.LogError(string.format("Error processing command, got %02X expected %02X", i, first))
            log.LogInfo(s)
            return nil
        end 
    end

    return t
end

local function _read_roswell_sn()
    local resp = dut.send("auth sn 1")
    return _parse_fw_reply(resp, 32)
end

local function _read_attestation_cert()
    local resp = dut.send("auth cert 0")
    return _parse_fw_reply(resp)
end

local function _read(zone, address, length)
    assert(length <= 16, string.format("Cannot read more than 16 bytes at a time. Trying %d", length))

    local resp = dut.send(string.format("auth mread 0 %d %d %d", zone, address, length))
    return _parse_fw_reply(resp, length + 2, zone, 0) -- expect status byte to be zero
end

local function _write(zone, address, data)
    assert(#data <= 16, "Cannot write more than 16 bytes at a time")

    local s = string.format("auth mwrite 0 %d %d ", tonumber(zone), tonumber(address))
    for i = 1, #data do
        s = s .. string.format("%02X ", data[i])
    end

    local resp = dut.send(s)

    return (_parse_fw_reply(resp, #data + 2, zone, 0) ~= nil)
end

local function _write_zone(zone, data)
    assert(#data == util.write_zone_size(zone), string.format("Error: Data size does not match zone size (%02X vs %02X)", #data, util.write_zone_size(zone)))

    local step = 16
    for i = 0, util.write_zone_size(zone), step do
        if util.write_zone_size(zone) - i < step then
            step = util.write_zone_size(zone) - i
        end

        local d = {table.unpack(data, i + 1, i + step)}
        if #d == 0 then
            return true
        end

        local ret = _write(zone, i, d)
        if not ret then
            log.LogError("Error in _write")
            return false
        end
    end

    return true
end

function module.get_ids_for_challenge()
    local mogulIDSN = _read(0, 262, 6) -- Mogul IDSN is Zone 0, address 262, length 6
    assert(mogulIDSN, "Unable to read Mogul IDSN")
    assert(#mogulIDSN == 6, "Invalid Mogul IDSN Length")

    --    log.LogInfo("Mogul IDSN" .. util.hexdump(mogulIDSN))

    local roswellSN = _read_roswell_sn()
    assert(roswellSN, "Unable to read Roswell SN")
    assert(#roswellSN == 32, "Invalid Roswell SN Length")
    --    log.LogInfo("Roswell SN" .. util.hexdump(roswellSN))

    return mogulIDSN, roswellSN
end

function module.get_certificate_for_challenge()
    local cert = _read_attestation_cert()
    assert(cert, "Unable to read attestation certificate")
    --    log.LogInfo("Attestation Cert" .. util.hexdump(cert))

    return cert
end

local function _verify_partnumber(partNumber)
    local resp = dut.send("ds get -s MODEL")

    local count = 0
    local read_partnumber
    for k in string.gmatch(resp, "(%u%d%d%d%d)") do
        read_partnumber = k
        count = count + 1
        assert(count == 1, "Found multiple matches in model number output")
    end

    return (read_partnumber == partNumber)
end

function module.get_partnumber()
    local partNumber = "A2781"
    if _verify_partnumber(partNumber) then
        return partNumber
    else
        error("Invalid Part Number!")
    end
end

function module.get_signature_for_challenge(challenge)
    assert(#challenge == 32, "Challenge length unexpected " .. tonumber(#challenge))

    local c1 = "auth challenge 0 0 "
    for i = 1, 16 do
        c1 = c1 .. string.format("%02X ", challenge[i])
    end
    local c2 = "auth challenge 0 16 "
    for i = 17, 32 do
        c2 = c2 .. string.format("%02X ", challenge[i])
    end

    local r1 = dut.send(c1)
    local t1 = {}
    for k in string.gmatch(r1, "(0x%x*)") do
        table.insert(t1, tonumber(k))
    end

    assert(#t1 == 16, "Invalid write of challenge data 1")
    assert(util.compare(t1, {table.unpack(challenge, 1, 16)}), "Written data does not match read data")

    local r2 = dut.send(c2)
    local t2 = {}
    for k in string.gmatch(r2, "(0x%x*)") do
        table.insert(t2, tonumber(k))
    end

    assert(#t2 == 16 + 64, "Invalid write of challenge data 2")
    assert(util.compare({table.unpack(t2, 1, 16)}, {table.unpack(challenge, 17, 32)}), "Written data does not match read data")

    return {table.unpack(t2, 17, 16 + 64)}
end

function module.write_verify_lock_certificate(certificate)
    assert(_write_zone(6, certificate), "Error writing certificate to zone 6")
    local read_cert = module.read_zone(6)
    assert(read_cert, "Error reading certificate after write from zone 6")

    if util.compare(certificate, read_cert) then
        assert(module.lock_zone(6), "Error locking zone 6")
    else 
        error("Written and read certificates do not match")
    end

    return true
end

function module.is_locked(zone)
    assert(zone > 0 and zone < 9, "Unknown zone specified ".. tonumber(zone))

    local locks = _read(1, 166 + 2 * (zone - 1), 2)
    if #locks ~= 2 then
        log.LogError("Lock data read is invalid")
        log.LogError(locks)
        return false
    end

    if locks[1] == 0xAA and locks[2] == 0xAA then
        log.LogInfo("Zone " .. tonumber(zone) .. " is locked")
        return true
    elseif locks[1] == 0x55 and locks[2] == 0x55 then
        log.LogInfo("Zone " .. tonumber(zone) .. " is unlocked")
        return false
    else 
        log.LogError(string.format("Unexpected value in lock registers 0x%02X 0x%02X", locks[1], locks[2]))
        return false
    end
end

function module.lock_zone(zone)
    assert(zone > 0 and zone < 9, "Unknown zone specified ".. tonumber(zone))
    local resp = dut.send("auth lock 0 " .. tonumber(zone))

    local t = _parse_fw_reply(resp, 1)
    assert(t, "Didn't get valid reply")

    if t[1] ~= 0 then
        log.LogError("Error: Cannot lock zone " .. tonumber(zone))
        return false
    end

    return true
end

function module.read_zone(zone)
    local step = 16
    local d = {}

    local offset = util.zone_offset(zone)
    local size = util.zone_size(zone)
    local realZone = util.zone_read_zone(zone)

    for i = offset, (offset + size), step do
        if offset + size - i < step then
            step = offset + size - i
        end
        if step > 0 then
            local c = _read(realZone, i, step)
            d = TableUtils.MergeArrays(d, c)
        end
    end

    return d
end

function module.zero_zone(zone)
    return _write_zone(zone, util.make_zeros(zone))
end

function _erase_and_lock(zone)
    if module.is_locked(zone) then
        log.LogInfo("Zone " .. tonumber(zone) .. " is already locked")
        return
    end

    if not module.zero_zone(zone) then
        error("Error erasing zone ".. tonumber(zone))
    end

    local zr = { table.unpack(module.read_zone(zone), 1, util.write_zone_size(zone)) }
    -- log.LogInfo("Zone " .. zone .. " - post erase" .. util.hexdump(zr))
    local zeros = util.make_zeros(zone)
    if not util.compare(zr, zeros) then
        error("Error -- Zone " .. tonumber(zone) .. " is not all zeros")
    end
    log.LogInfo("Successfully erased " .. tonumber(zone))

    if not module.lock_zone(zone) then
        error("Error locking zone " .. tonumber(zone))
    end

    log.LogInfo("Successfully locked zone " .. tonumber(zone))
end

function module.erase_lock_zones()

    for _, zone in next, {1,2,3,4,5,7,8} do
        _erase_and_lock(zone)
    end

end

return module
