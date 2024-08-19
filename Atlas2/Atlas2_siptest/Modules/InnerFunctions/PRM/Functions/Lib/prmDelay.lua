-------------------------------------------------------------------
----***************************************************************
----    delay.lua provied delay information
----***************************************************************
-------------------------------------------------------------------
local prmDelay = {}
local CommonFunc = require 'Matchbox/CommonFunc'
local DELAY_TABLE = {
    DELAY_AFTER_OPEN_PDM = 300, -- wait 300ms after relay before frequency measurement
    DELAY_BEFORE_MEAS_FREQUENCYE = 50, -- wait 50ms after relay before frequency measurement
    DELAY_BEFORE_MEAS_ODIN_VOLATAGE = 10, -- wait 10ms before read back voltage
    DELAY_DIODE_BEFORE_MEAS_PP_VDD_MAIN = 200, -- wait 200ms befor PP_VDD_MAIN measurement
    DELAY_OPENSHORT_AFTER_SET_DAC = 500, -- wait 500ms for dac output stable
    DELAY_OPENSHORT_AFTER_RELAY = 2000, -- wait 2000ms after relay
    DELAY_OPENSHORT_BEFORE_MEAS_CURRENT = 200, -- wait 200ms between measure voltage and current
    DELAY_RESISTOR_AFTER_RELAY = 100, -- wait 100ms after relay before current measurement
    DELAY_LEAKAGE_AFTER_RELAY_PP2V7_LDO2 = 500, -- wait 500ms for PP2V7_LDO2, I2C0_RTP_BI_KADABRA_SDA,
    -- I2C0_RTP_TO_KADABRA_SCL, ANALOG_AMP_OUT_P
    DELAY_LEAKAGE_AFTER_RELAY_ANALOG_AMP_OUT_N = 1000, -- wait 500ms for ANALOG_AMP_OUT_N
    DELAY_LEAKAGE_AFTER_RELAY_PP1V2_LSB_0 = 3000, -- wait 3000ms for PP1V2_LSB_0
    DELAY_AFTER_CONFIG_ODIN = 50, -- wait 50ms after configured odin for odin.read
    DELAY_POWER_CYCLE = 500, -- set interval time as 500ms for power cycle
    DELAY_FOR_DISCHARGE_VDD_MAIN = 50, -- wait 50ms for dischage VDD_MAIN
    DELAY_FOR_I2C1_RTP_TO_MANDO_SDA = 500, -- wait 500ms for "I_LEAKAGE_P0V2@I2C1_RTP_TO_MANDO_SDA",
    -- "I_LEAKAGE_P0V2@I2C_AON_TO_KESSEL_MAGPIE_SCL","I_LEAKAGE_P0V2@I2C1_RTP_TO_MANDO_SCL",
    -- "I_LEAKAGE_P0V2@I2C_AON_BI_KESSEL_MAGPIE_SDA","I_LEAKAGE_P0V2@I2C0_RTP_TO_KADABRA_SCL"
    DELAY_FOR_I2C0_RTP_BI_KADABRA_SDA = 2500 -- wait 2500ms for I_LEAKAGE_P0V2@I2C0_RTP_BI_KADABRA_SDA

}

function prmDelay.delayFromKey(keyWord)
    if CommonFunc.hasKey(DELAY_TABLE, keyWord) then
        os.execute("sleep " .. tonumber(DELAY_TABLE[keyWord] / 1000.0))
    else
        error("keyWord is invalid.")
    end
    return true
end

return prmDelay
