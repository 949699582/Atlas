local log = require 'Matchbox/logging'
local mix = require 'Tech/MogulCert/Mix'
local util = require 'Tech/MogulCert/Utility'

local module = {}

local side

local addr_status = 0x05
local addr_proc_control = 0x10
local addr_signature_len = 0x11
local addr_signature = 0x12
local addr_challenge_data = 0x21
local addr_cert_len = 0x30
local addr_aid_passthrough = 0x60

function module.initialize(s)
    side = s
    log.LogInfo("Processing side " .. s)
    mix.initialize(s)
end

function module.initialize_TESTONLY(s)
    return mix.initialize_TESTONLY(s)
end

function module.shutdown_TESTONLY()
    mix.shutdown_TESTONLY()
end

function module.get_ids_for_challenge()
    local mogulIDSN = mix.aid_read(0, 262, 6) -- Mogul IDSN is Zone 0, address 262, length 6
    assert(mogulIDSN, "Unable to read Mogul IDSN")
    assert(#mogulIDSN == 6, "Invalid Mogul IDSN Length")
    -- log.LogInfo("Mogul IDSN" .. util.hexdump(mogulIDSN))

    return mogulIDSN, nil -- no Roswell ID for Band
end

function module.get_certificate_for_challenge()
    local fullCert = mix.read_zone(6) -- Attestation Certificate is in Zone 6
    -- log.LogInfo("Attestation Cert" .. util.hexdump(cert))

    if not mix.set_apple_identity() then
        return nil
    end

    local certLen = mix.get_cert_length()
    -- log.LogInfo("Cert Length ".. certLen)

    local cert = { table.unpack(fullCert, 1, certLen) }
    assert(cert, "Unable to read attestation certificate")
    -- log.LogInfo("Cert Length ".. #cert)

    return cert
end

function module.get_signature_for_challenge(challenge)
    proc_control_start_challenge_response = 0x01
    proc_control_challenge_response_success = 0x10
    expected_signature_len = 0x40

    if not mix.write(addr_challenge_data, challenge) then
        log.LogError("Writing challenge to Mogul failed")
        return nil
    end

    if not mix.write(addr_proc_control, { proc_control_start_challenge_response }) then
        log.LogError("Starting challenge response failed")
        return nil
    end

    local ret = mix.read(addr_proc_control, 1)
    if ret[1] ~= proc_control_challenge_response_success then
        log.LogError("Challenge response generation failed")
        return nil
    end

    local sl = mix.read(addr_signature_len, 2)
    if #sl ~= 2 then
        log.LogError("Signature Length read failed")
        return nil
    end

    local signatureLen = sl[1] * 256 + sl[2]
    if signatureLen ~= expected_signature_len then
        log.LogError(string.format("Signature Length check failed -- got %d expected %d", signatureLen, expected_signature_len))
        return nil
    end

    return mix.read(addr_signature, expected_signature_len)
end

local function _verify_partnumber(partNumber)
    local readPartNumber = mix.aid_read(1, 30, 30)
    log.LogInfo("Part Number" .. util.hexdump(readPartNumber))
    return (util.table_to_string(readPartNumber) == partNumber)
end

local function _get_partnumber_for_side()
    if side == "LEFT" then
        return "A2740"
    elseif side == "RIGHT" then
        return "A2741"
    elseif side == "AGNES" then
        return "A2776"
    else
        return nil
    end
end

function module.get_partnumber()
    local partNumber = _get_partnumber_for_side()
    if _verify_partnumber(partNumber) then
        return partNumber
    else
        error("Invalid Part Number!")
    end
end

function module.is_locked(zone)
    assert(zone > 0 and zone < 9, "Unknown zone specified ".. tonumber(zone))

    local locks = mix.aid_read(1, 166 + 2 * (zone - 1), 2)
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

function module.write_verify_lock_certificate(certificate)
    assert(mix.write_zone(6, certificate), "Error writing certificate to zone 6")
    local read_cert = mix.read_zone(6)
    assert(read_cert, "Error reading certificate after write from zone 6")

    if util.compare(certificate, read_cert) then
        assert(mix.lock_zone(6), "Error locking zone 6")
    else 
        error("Written and read certificates do not match")
    end

    return true
end

function module.erase_lock_zones()
    if module.is_locked(8) then
        log.LogInfo("Zone 8 is already locked")
        return
    end

    if not module.zero_zone(8) then
        error("Error erasing zone 8")
    end

    local z8 = module.read_zone(8)
    -- log.LogInfo("Zone 8 - post erase" .. util.hexdump(z8))
    local zeros = util.make_zeros(8)
    if not util.compare(z8, zeros) then
        error("Error -- Zone 8 is not all zeros")
    end

    if not module.lock_zone(8) then
        error("Error locking zone 8")
    end

    log.LogInfo("Successfully erased and locked zone 8")
end

function module.read_zone(zone)
    return mix.read_zone(zone)
end

function module.lock_zone(zone)
    return mix.lock_zone(zone)
end

function module.zero_zone(zone)
    return mix.zero_zone(zone)
end

return module