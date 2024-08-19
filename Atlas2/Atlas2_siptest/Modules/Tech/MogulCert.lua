local TableUtils = require 'ALE/TableUtils'
local SystemUtils = require 'ALE/SystemUtils'
local TypeUtils = require 'ALE/TypeUtils'
local FileUtils = require 'ALE/FileUtils'
local log = require 'Matchbox/logging'
local util = require 'Tech/MogulCert/Utility'
local band = require 'Tech/MogulCert/Band'
local puck = require 'Tech/MogulCert/Puck'

local module = {}

local testonly = false
local duttype
local device
local fdr
local data_utils
local utility

local function _initialize(param)
    local p = param.InputValues

    assert(#p > 0, "Must have at least one argument -- type")

    duttype = p[1]
    if duttype == "PUCK" then
        log.LogInfo("Initializing Puck")
        puck.initialize()
        device = puck
        if #p == 2 then
            return p[2]
        else
            return
        end
    elseif duttype == "BAND" then
        log.LogInfo("Initializing Band")
        assert(#p > 1, "Must have at least two arguments -- type and side")
        band.initialize(p[2])
        device = band
        if #p == 3 then
            return p[3]
        else
            return
        end
    else
        error("Invalid DUT type or invalid number of arguments (2/3)")
    end

end

local function _get_challenge(mogulIDSN, partNumber, roswell, certificate)
    local _mogulIDSN = data_utils.dataFromByteTable(mogulIDSN)
    local _certificate = data_utils.dataFromByteTable(certificate)
    local _roswell = nil
    if roswell then
        _roswell = data_utils.dataFromByteTable(roswell)
    end

    local mogul = fdr.initMogulCertification(_mogulIDSN, partNumber, _roswell, _certificate)
    assert(mogul, "initMogulCertification failed")

    local _challenge = fdr.copyChallenge(mogul)
    assert(_challenge, "copyChallenge failed")

    return mogul, data_utils.dataToByteTable(_challenge)
end

local function _get_certificate(mogul, signature)
    _signature = data_utils.dataFromByteTable(signature)

    local _certificate = fdr.copyCertificate(mogul, _signature)
    fdr.finishMogulCertification(mogul)
    assert(_certificate, "copyCertificate failed")

    return data_utils.dataToByteTable(_certificate)
end

function _get_path_for_mogul_cert_cache()
    return FileUtils.joinPaths(FileUtils.GetCurrentUserHomeDir(), "Library", "MogulCertCache")
end

function _get_path_for_mogul_cert(mogulIDSN)
    local s = util.table_to_hex_string(mogulIDSN) .. ".bin"
    return FileUtils.joinPaths(_get_path_for_mogul_cert_cache(), s)
end

function _read_cert_from_local_cache(mogulIDSN)
    local path = _get_path_for_mogul_cert(mogulIDSN)
    if FileUtils.FileExists(path) then
        log.LogInfo("Found " .. path .. " in local cache")
        local _certificate = utility.readDataFromFile(path)
        return data_utils.dataToByteTable(_certificate)
    else
        log.LogInfo(path .. " NOT found in local cache")
        return nil
    end
end

function _save_cert_to_local_cache(mogulIDSN, attestCert)
    FileUtils.CreateDirectoryPath(_get_path_for_mogul_cert_cache())
    local _certificate = data_utils.dataFromByteTable(attestCert)
    local path = _get_path_for_mogul_cert(mogulIDSN)
    log.LogInfo("Saving cert to local cache " .. path)
    utility.writeDataToFile(path, _certificate)
end

function _remove_cert_from_local_cache(mogulIDSN)
    local path = _get_path_for_mogul_cert(mogulIDSN)
    log.LogInfo("Removing " .. path .. " from local cache ")
    SystemUtils.RunCommandAndCheck("rm " .. path)
end

function module.initialize_TESTONLY(type, side)
    testonly = true

    fdr = Atlas.loadPlugin("FDR")
    assert(fdr, "Cannot load FDR plugin")

    if type == "PUCK" then
        return puck.initialize_TESTONLY()
    end
    if type == "BAND" then
        fdr.setDebugServer() -- needed only for BAND when accessing off GH network
        return band.initialize_TESTONLY(side)
    end
end

function module.initialize_MOCK(type, side)
    testonly = true

    fdr = Atlas.loadPlugin("FDR")
    assert(fdr, "Cannot load FDR plugin")

    if type == "PUCK" then
        return puck.initialize_MOCK()
    end
    if type == "BAND" then
        -- fdr.setDebugServer() -- needed only for BAND when accessing off GH network
        -- return band.initialize_TESTONLY(side)
        return false
    end
end

function module.shutdown_TESTONLY()
    if duttype == "PUCK" then
    end
    if duttype == "BAND" then
        band.shutdown_TESTONLY()
    end
end

function module.certifyMogul(param)

    _initialize(param)

    if fdr == nil then
        fdr = Atlas.loadPlugin("FDR")
        assert(fdr, "Cannot load FDR plugin")
    end

    if not device.is_locked(6) then

        data_utils = Atlas.loadPlugin("DataUtils")
        assert(data_utils, "Cannot load dataUtils plugin")
        utility = Atlas.loadPlugin("Utilities")
        assert(utility, "Cannot load Utilities plugin")

        local mogulIDSN, roswell = device.get_ids_for_challenge()
        assert(mogulIDSN, "Cannot get Mogul IDSN")
        log.LogInfo("MogulIDSN" .. util.hexdump(mogulIDSN))
        if roswell then
            log.LogInfo("Roswell SN" .. util.hexdump(roswell))
        end

        local attestCert = _read_cert_from_local_cache(mogulIDSN)
        if not attestCert then
            attestCert = device.get_certificate_for_challenge()
        end

        assert(attestCert, "Cannot get Attestation certificate")
        log.LogInfo("Attestation Cert" .. util.hexdump(attestCert))
        _save_cert_to_local_cache(mogulIDSN, attestCert)

        local partNumber = device.get_partnumber()
        assert(partNumber, "Read part number does not match expected part number")
        log.LogInfo("Part Number " .. partNumber)

        local mogul, challenge = _get_challenge(mogulIDSN, partNumber, roswell, attestCert)
        assert(mogul, "Mogul handle is invalid")
        assert(challenge, "Challenge is invalid")
        log.LogInfo("Challenge" .. util.hexdump(challenge))

        local signature = device.get_signature_for_challenge(challenge)
        assert(signature, "Cannot get signature")
        log.LogInfo("Signature" .. util.hexdump(signature))

        local certificate = _get_certificate(mogul, signature)
        assert(certificate, "Cannot get certificate")
        log.LogInfo("Certificate" .. util.hexdump(certificate))

        if not testonly then
            assert(device.write_verify_lock_certificate(certificate), "Error writing certificate")
            _remove_cert_from_local_cache(mogulIDSN)
            log.LogInfo("Successfully wrote certificate")
        else
            log.LogInfo("Skipping writing certificate to device in test mode")
        end
    else
        log.LogInfo("Zone 6 is already locked -- Mogul provisioned previously")
    end

    device.erase_lock_zones()
    
    return true
end

function module.readZone(param)

    local zone = _initialize(param)
    log.LogInfo("Reading zone " .. tonumber(zone))

    local z = device.read_zone(tonumber(zone))
    assert(z, "Cannot read zone " .. tonumber(zone))
    log.LogInfo(util.hexdump(z))

end

function module.lockZone(param)

    local zone = _initialize(param)
    log.LogInfo("Locking zone " .. tonumber(zone))

    assert(duttype == "BAND", "Manual zone locking is only supported for Band")
    assert(not (zone == 6 or zone == 8), "Zones 6 and 8 cannot be locked directly")

    log.LogInfo("Zone " .. tonumber(zone) .. " to be locked")
    if not device.is_locked(tonumber(zone)) then
        if device.lock_zone(tonumber(zone)) then
            log.LogInfo("Zone " .. tonumber(zone) .. " locked successfully")
        else
            error("Error locking zone " .. tonumber(zone))
            return false
        end
    else
        log.LogInfo("Zone " .. tonumber(zone) .. " already locked")
    end

    return true
end

return module
