-------------------------------------------------------------------
----***************************************************************
----    prmCal.lua provied calibration information
----***************************************************************
-------------------------------------------------------------------
local Log = require("Matchbox/logging")

local prmCal = {}

-- reserved index
prmCal["RESERVED"] = 0
-- diode index
prmCal["DIODE@PACK_NEG"] = 1
prmCal["DIODE@PP_VDD_MAIN"] = 2
prmCal["DIODE@ANALOG_AMP_OUT_N"] = 3
prmCal["DIODE@ANALOG_AMP_OUT_P"] = 4
prmCal["DIODE@ANALOG_PMU_CHG_SNS"] = 5
prmCal["DIODE@PP1V8_LSC_0"] = 6
prmCal["DIODE@IO_SOC_TO_FRONT_MIC_SEL_PERF"] = 7
prmCal["DIODE@IO_SOC_TO_TOP_MIC_SEL_PERF"] = 8
prmCal["DIODE@PP2V7_LDO2"] = 9
prmCal["DIODE@PP1V2_LSB_0"] = 10
prmCal["DIODE@PDM_AON_FROM_BOT_MIC_DATA"] = 11
prmCal["DIODE@PDM_AON_TO_BOT_MIC_CLK"] = 12
prmCal["DIODE@PDM_AUD_FROM_TOP_FRONT_MIC_DATA"] = 13
prmCal["DIODE@PDM_AUD_TO_TOP_MIC_CLK"] = 14
prmCal["DIODE@PDM_AUD_TO_FRONT_MIC_CLK"] = 15
prmCal["DIODE@I2C0_RTP_BI_KADABRA_SDA"] = 16
prmCal["DIODE@I2C0_RTP_TO_KADABRA_SCL"] = 17
prmCal["DIODE@IO_SOC_FROM_KADABRA_INT_L"] = 18
prmCal["DIODE@I2C1_RTP_TO_MANDO_SCL"] = 19
prmCal["DIODE@I2C1_RTP_TO_MANDO_SDA"] = 20
prmCal["DIODE@PMU_TO_PCM_UVP_TRIG"] = 21
prmCal["DIODE@PP1V8_LSC_0_KADABRA_TX"] = 22
prmCal["DIODE@GND_PIN37"] = 23
prmCal["DIODE@QSPI_SOC_TO_FLASH_CS_L"] = 24
prmCal["DIODE@QSPI_SOC_TO_FLASH_CLK_60M"] = 25
prmCal["DIODE@QSPI_SOC_BI_FLASH_DQ0"] = 26
prmCal["DIODE@QSPI_SOC_BI_FLASH_DQ1"] = 27
prmCal["DIODE@SWD_SOC_CLK"] = 28
prmCal["DIODE@SWD_SOC_DIO"] = 29
prmCal["DIODE@UART1_AP_RXD"] = 30
prmCal["DIODE@UART1_AP_TXD"] = 31
prmCal["DIODE@I2C_AON_BI_KESSEL_SDA"] = 32
prmCal["DIODE@GND_PIN36"] = 33
prmCal["DIODE@MADI_SOC_CLK_IN_125M"] = 34
prmCal["DIODE@MADI_SOC_RX"] = 35
prmCal["DIODE@MADI_SOC_TX"] = 36
prmCal["DIODE@MADI_SOC_TX0"] = 36
prmCal["DIODE@MADI_SOC_TX1"] = 37
prmCal["DIODE@MADI_SOC_TX2"] = 38
prmCal["DIODE@I2C_PMU_BI_LOCUST_SDA"] = 39
prmCal["DIODE@I2C_PMU_FROM_LOCUST_SCL"] = 40
prmCal["DIODE@ANALOG_PMU_AMUX_AX"] = 41
prmCal["DIODE@ANALOG_PMU_AMUX_AY"] = 42
prmCal["DIODE@PP7V5_PMU_VPP"] = 43
-- resistor index
prmCal["RESISTOR@I2C0_RTP_TO_KADABRA_SCL"] = 44
prmCal["RESISTOR@I2C0_RTP_BI_KADABRA_SDA"] = 45
prmCal["RESISTOR@I2C_AON_TO_KESSEL_MAGPIE_SCL"] = 46
prmCal["RESISTOR@I2C_AON_BI_KESSEL_MAGPIE_SDA"] = 47
prmCal["RESISTOR@BATTERY_CCS"] = 48
prmCal["RESISTOR@I2C1_RTP_TO_MANDO_SCL"] = 98
prmCal["RESISTOR@I2C1_RTP_TO_MANDO_SDA"] = 99
prmCal["RESISTOR@I2C_PMU_FROM_LOCUST_SCL"] = 96
prmCal["RESISTOR@I2C_PMU_BI_LOCUST_SDA"] = 97

-- leakage_p index
prmCal["I_LEAKAGE_P0V2@PP_FUN_BUS"] = 50
prmCal["I_LEAKAGE_P0V2@PACK_NEG"] = 51
prmCal["I_LEAKAGE_P0V2@PP_VDD_MAIN"] = 52
prmCal["I_LEAKAGE_P0V2@ANALOG_PMU_CHG_SNS"] = 53
prmCal["I_LEAKAGE_P0V2@PP1V8_LSC_0"] = 54
prmCal["I_LEAKAGE_P0V2@IO_SOC_TO_FRONT_MIC_SEL_PERF"] = 55
prmCal["I_LEAKAGE_P0V2@IO_SOC_TO_TOP_MIC_SEL_PERF"] = 56
prmCal["I_LEAKAGE_P0V2@PP2V7_LDO2"] = 57
prmCal["I_LEAKAGE_P0V2@PP1V2_LSB_0"] = 58
prmCal["I_LEAKAGE_P0V2@PDM_AON_FROM_BOT_MIC_DATA"] = 59
prmCal["I_LEAKAGE_P0V2@PDM_AON_TO_BOT_MIC_CLK"] = 60
prmCal["I_LEAKAGE_P0V2@PDM_AUD_FROM_TOP_FRONT_MIC_DATA"] = 61
prmCal["I_LEAKAGE_P0V2@PDM_AUD_TO_TOP_MIC_CLK"] = 62
prmCal["I_LEAKAGE_P0V2@PDM_AUD_TO_FRONT_MIC_CLK"] = 63
prmCal["I_LEAKAGE_P0V2@I2C0_RTP_BI_KADABRA_SDA"] = 64
prmCal["I_LEAKAGE_P0V2@I2C0_RTP_TO_KADABRA_SCL"] = 65
prmCal["I_LEAKAGE_P0V2@IO_SOC_FROM_KADABRA_INT_L"] = 66
prmCal["I_LEAKAGE_P0V2@I2C1_RTP_TO_MANDO_SCL"] = 67
prmCal["I_LEAKAGE_P0V2@I2C1_RTP_TO_MANDO_SDA"] = 68
prmCal["I_LEAKAGE_P0V2@PMU_TO_PCM_UVP_TRIG"] = 69
prmCal["I_LEAKAGE_P0V2@PP1V8_LSC_0_KADABRA_TX"] = 70
prmCal["I_LEAKAGE_P0V2@IO_SOC_FROM_MAGPIE_INT_L"] = 71
prmCal["I_LEAKAGE_P0V2@QSPI_SOC_TO_FLASH_CS_L"] = 72
prmCal["I_LEAKAGE_P0V2@QSPI_SOC_TO_FLASH_CLK_60M"] = 73
prmCal["I_LEAKAGE_P0V2@QSPI_SOC_BI_FLASH_DQ0"] = 74
prmCal["I_LEAKAGE_P0V2@QSPI_SOC_BI_FLASH_DQ1"] = 75
prmCal["I_LEAKAGE_P0V2@SWD_SOC_CLK"] = 76
prmCal["I_LEAKAGE_P0V2@SWD_SOC_DIO"] = 77
prmCal["I_LEAKAGE_P0V2@UART1_AP_RXD"] = 78
prmCal["I_LEAKAGE_P0V2@UART1_AP_TXD"] = 79
prmCal["I_LEAKAGE_P0V2@I2C_AON_BI_KESSEL_MAGPIE_SDA"] = 80
prmCal["I_LEAKAGE_P0V2@I2C_AON_TO_KESSEL_MAGPIE_SCL"] = 81
prmCal["I_LEAKAGE_P0V2@MADI_SOC_CLK_IN_125M"] = 82
prmCal["I_LEAKAGE_P0V2@MADI_SOC_RX"] = 83
prmCal["I_LEAKAGE_P0V2@MADI_SOC_TX"] = 84
prmCal["I_LEAKAGE_P0V2@MADI_SOC_TX0"] = 84
prmCal["I_LEAKAGE_P0V2@MADI_SOC_TX1"] = 85
prmCal["I_LEAKAGE_P0V2@MADI_SOC_TX2"] = 86
prmCal["I_LEAKAGE_P0V2@I2C_PMU_BI_LOCUST_SDA"] = 87
prmCal["I_LEAKAGE_P0V2@I2C_PMU_FROM_LOCUST_SCL"] = 88
prmCal["I_LEAKAGE_P0V2@ANALOG_PMU_AMUX_AX"] = 89
prmCal["I_LEAKAGE_P0V2@ANALOG_PMU_AMUX_AY"] = 90
prmCal["I_LEAKAGE_P0V2@PP7V5_PMU_VPP"] = 91
prmCal["I_LEAKAGE_P0V8@ANALOG_AMP_OUT_N"] = 92
prmCal["I_LEAKAGE_P0V8@ANALOG_AMP_OUT_P"] = 93
prmCal["I_LEAKAGE_P0V2@ANALOG_AMP_OUT_N"] = 94
prmCal["I_LEAKAGE_P0V2@ANALOG_AMP_OUT_P"] = 95
-- lekage_n index
prmCal["I_LEAKAGE_N0V2@PP_FUN_BUS"] = 100
prmCal["I_LEAKAGE_N0V2@PACK_NEG"] = 101
prmCal["I_LEAKAGE_N0V2@PP_VDD_MAIN"] = 102
prmCal["I_LEAKAGE_N0V2@ANALOG_PMU_CHG_SNS"] = 103
prmCal["I_LEAKAGE_N0V2@PP1V8_LSC_0"] = 104
prmCal["I_LEAKAGE_N0V2@IO_SOC_TO_FRONT_MIC_SEL_PERF"] = 105
prmCal["I_LEAKAGE_N0V2@IO_SOC_TO_TOP_MIC_SEL_PERF"] = 106
prmCal["I_LEAKAGE_N0V2@PP2V7_LDO2"] = 107
prmCal["I_LEAKAGE_N0V2@PP1V2_LSB_0"] = 108
prmCal["I_LEAKAGE_N0V2@PDM_AON_FROM_BOT_MIC_DATA"] = 109
prmCal["I_LEAKAGE_N0V2@PDM_AON_TO_BOT_MIC_CLK"] = 110
prmCal["I_LEAKAGE_N0V2@PDM_AUD_FROM_TOP_FRONT_MIC_DATA"] = 111
prmCal["I_LEAKAGE_N0V2@PDM_AUD_TO_TOP_MIC_CLK"] = 112
prmCal["I_LEAKAGE_N0V2@PDM_AUD_TO_FRONT_MIC_CLK"] = 113
prmCal["I_LEAKAGE_N0V2@I2C0_RTP_BI_KADABRA_SDA"] = 114
prmCal["I_LEAKAGE_N0V2@I2C0_RTP_TO_KADABRA_SCL"] = 115
prmCal["I_LEAKAGE_N0V2@IO_SOC_FROM_KADABRA_INT_L"] = 116
prmCal["I_LEAKAGE_N0V2@I2C1_RTP_TO_MANDO_SCL"] = 117
prmCal["I_LEAKAGE_N0V2@I2C1_RTP_TO_MANDO_SDA"] = 118
prmCal["I_LEAKAGE_N0V2@PMU_TO_PCM_UVP_TRIG"] = 119
prmCal["I_LEAKAGE_N0V2@PP1V8_LSC_0_KADABRA_TX"] = 120
prmCal["I_LEAKAGE_N0V2@IO_SOC_FROM_MAGPIE_INT_L"] = 121
prmCal["I_LEAKAGE_N0V2@QSPI_SOC_TO_FLASH_CS_L"] = 122
prmCal["I_LEAKAGE_N0V2@QSPI_SOC_TO_FLASH_CLK_60M"] = 123
prmCal["I_LEAKAGE_N0V2@QSPI_SOC_BI_FLASH_DQ0"] = 124
prmCal["I_LEAKAGE_N0V2@QSPI_SOC_BI_FLASH_DQ1"] = 125
prmCal["I_LEAKAGE_N0V2@SWD_SOC_CLK"] = 126
prmCal["I_LEAKAGE_N0V2@SWD_SOC_DIO"] = 127
prmCal["I_LEAKAGE_N0V2@UART1_AP_RXD"] = 128
prmCal["I_LEAKAGE_N0V2@UART1_AP_TXD"] = 129
prmCal["I_LEAKAGE_N0V2@I2C_AON_BI_KESSEL_MAGPIE_SDA"] = 130
prmCal["I_LEAKAGE_N0V2@I2C_AON_TO_KESSEL_MAGPIE_SCL"] = 131
prmCal["I_LEAKAGE_N0V2@MADI_SOC_CLK_IN_125M"] = 132
prmCal["I_LEAKAGE_N0V2@MADI_SOC_RX"] = 133
prmCal["I_LEAKAGE_N0V2@MADI_SOC_TX0"] = 134
prmCal["I_LEAKAGE_N0V2@MADI_SOC_TX1"] = 135
prmCal["I_LEAKAGE_N0V2@MADI_SOC_TX2"] = 136
prmCal["I_LEAKAGE_N0V2@I2C_PMU_BI_LOCUST_SDA"] = 137
prmCal["I_LEAKAGE_N0V2@I2C_PMU_FROM_LOCUST_SCL"] = 138
prmCal["I_LEAKAGE_N0V2@ANALOG_PMU_AMUX_AX"] = 139
prmCal["I_LEAKAGE_N0V2@ANALOG_PMU_AMUX_AY"] = 140
prmCal["I_LEAKAGE_N0V2@PP7V5_PMU_VPP"] = 141
prmCal["I_LEAKAGE_N0V1@ANALOG_AMP_OUT_N"] = 142
prmCal["I_LEAKAGE_N0V1@ANALOG_AMP_OUT_P"] = 143
-- open short index
prmCal["OPENSHORT@OS_PP_VBAT_TO_GND"] = 160
prmCal["OPENSHORT@OS_GND_TO_PACK_NEG"] = 161
prmCal["OPENSHORT@OS_PP_FUN_BUS_TO_GND"] = 162
prmCal["OPENSHORT@OS_PP_FUN_BUS_TO_PACK_NEG"] = 163
-- system calibration index
prmCal["CHARGER_VOLTAGE_MEASUREMENT_INDEX"] = 250
prmCal["CHARGER_VOLTAGE_OUTPUT_INDEX"] = 275
prmCal["BATTERY_VOLTAGE_MEASUREMENT_INDEX"] = 300
prmCal["BATTERY_VOLTAGE_OUTPUT_INDEX"] = 325
prmCal["DMM_CH1_VOLTAGE_MEASUREMENT_INDEX"] = 350
prmCal["DMM_CH2_VOLTAGE_MEASUREMENT_INDEX"] = 375
prmCal["CHARGER_CURRENT_MEASUREMENT_INDEX"] = 400
prmCal["BATTERY_CURRENT_MEASUREMENT_INDEX"] = 420
prmCal["BATTERY_SMALL_CURRENT_MEASUREMENT_INDEX"] = 430
prmCal["BATTERY_CURRENT_DATALOGGER_MEASUREMENT_INDEX"] = 440
prmCal["BATTERY_SMALL_CURRENT_DATALOGGER_MEASUREMENT_INDEX"] = 450
prmCal["DMM_CURRENT_MEASUREMENT_INDEX"] = 460
prmCal["AUDIO_INDEX"] = 470
prmCal["CONSTANT_VOLTAGE_SOURCE_OUTPUT_INDEX"] = 480
prmCal["CONSTANT_CURRENT_SOURCE_OUTPUT_INDEX"] = 481
prmCal["LEAKAGE_P_ROUTE_INDEX"] = 482
prmCal["LEAKAGE_N_ROUTE_INDEX"] = 483
prmCal["DIODE_ROUTE_INDEX"] = 484
prmCal["CVS_CURRENT_P_INDEX"] = 485
prmCal["CVS_CURRENT_N_INDEX"] = 487
prmCal["CCS_I_SINK_8MA_INDEX"] = 488

-- get voltage calibration index
-- @param baseIndex: number type, start index
-- @param voltage: number type, raw value
-- @return number result of index
function prmCal.getVoltageCalIndex(baseIndex, voltage)
    if not baseIndex then
        Log.LogInfo("baseIndex is nil, return baseIndex=0")
        return 0
    end
    voltage = tonumber(voltage)
    if voltage <= 500 then
        baseIndex = baseIndex
    elseif 500 < voltage and voltage <= 1000 then
        baseIndex = baseIndex + 1
    elseif 1000 < voltage and voltage <= 1500 then
        baseIndex = baseIndex + 2
    elseif 1500 < voltage and voltage <= 2000 then
        baseIndex = baseIndex + 3
    elseif 2000 < voltage and voltage <= 2500 then
        baseIndex = baseIndex + 4
    elseif 2500 < voltage and voltage <= 3000 then
        baseIndex = baseIndex + 5
    elseif 3000 < voltage and voltage <= 3500 then
        baseIndex = baseIndex + 6
    elseif 3500 < voltage and voltage <= 4000 then
        baseIndex = baseIndex + 7
    elseif 4000 < voltage and voltage <= 4500 then
        baseIndex = baseIndex + 8
    elseif 4500 < voltage and voltage <= 5000 then
        baseIndex = baseIndex + 9
    end
    return baseIndex
end

-- get charger current calibration index
-- @param baseIndex: number type, start index
-- @param current: number type, raw value
-- @return number result of index
function prmCal.getChargerCurrentCalIndex(baseIndex, current)
    if not baseIndex then
        Log.LogInfo("baseIndex is nil, return baseIndex=0")
        return 0
    end
    current = tonumber(current)
    if current <= 10 then
        baseIndex = baseIndex
    elseif 10 < current and current <= 50 then
        baseIndex = baseIndex + 1
    elseif 50 < current and current <= 100 then
        baseIndex = baseIndex + 2
    elseif 100 < current and current <= 250 then
        baseIndex = baseIndex + 3
    end
    return baseIndex
end

-- get battery current calibration index
-- @param baseIndex: number type, start index
-- @param current: number type, raw value
-- @return number result of index
function prmCal.getBatteryCurrentCalIndex(baseIndex, current)
    if not baseIndex then
        Log.LogInfo("baseIndex is nil, return baseIndex=0")
        return 0
    end
    current = tonumber(current)
    if current <= -100 then
        baseIndex = baseIndex
    elseif -100 < current and current <= -50 then
        baseIndex = baseIndex + 1
    elseif -50 < current and current <= -10 then
        baseIndex = baseIndex + 2
    elseif -10 < current and current <= 0 then
        baseIndex = baseIndex + 3
    elseif 0 < current and current <= 10 then
        baseIndex = baseIndex + 4
    elseif 10 < current and current <= 50 then
        baseIndex = baseIndex + 5
    elseif 50 < current and current <= 100 then
        baseIndex = baseIndex + 6
    elseif 100 < current and current <= 250 then
        baseIndex = baseIndex + 7
    end
    return baseIndex
end

-- get battery small current calibration index
-- @param baseIndex: number type, start index
-- @param smallCurrent: number type, raw value
-- @return number result of index
function prmCal.getBatterySmallCurrentCalIndex(baseIndex, smallCurrent)
    if not baseIndex then
        Log.LogInfo("baseIndex is nil, return baseIndex=0")
        return 0
    end
    smallCurrent = tonumber(smallCurrent)
    if smallCurrent <= 0.001 then
        baseIndex = baseIndex
    end
    return baseIndex
end

-- get DMM current calibration index
-- @param baseIndex: number type, start index
-- @param current: number type, raw value
-- @return number result of index
function prmCal.getDMMCurrentCalIndex(baseIndex, current)
    if not baseIndex then
        Log.LogInfo("baseIndex is nil, return baseIndex=0")
        return 0
    end
    current = tonumber(current)
    if current <= -10 then
        baseIndex = baseIndex
    elseif -10 < current and current <= 0 then
        baseIndex = baseIndex + 1
    elseif 0 < current and current <= 10 then
        baseIndex = baseIndex + 2
    elseif 10 < current and current <= 50 then
        baseIndex = baseIndex + 3
    end
    return baseIndex
end

return prmCal
