'''
locustRegDump.py
This dumps all the registers from the GN host
Brandon Beckham, 7/19/23
'''

from grassninja import *

locustRegMap = {
    "DeviceID0Reg": 0x0,
    "DeviceID1Reg": 0x1,
    "DeviceRevReg": 0x2,
    "TraceID0Reg": 0x3,
    "TraceID1Reg": 0x4,
    "TraceID2Reg": 0x5,
    "TraceID3Reg": 0x6,
    "Trim0Reg": 0x7,
    "Trim1Reg": 0x8,
    "Trim2Reg": 0x9,
    "Trim3Reg": 0xA,
    "Trim4Reg": 0xB,
    "Trim5Reg": 0xC,
    "Trim6Reg": 0xD,
    "Trim7Reg": 0xE,
    "Trim8Reg": 0xF,
    "Trim9Reg": 0x10,
    "Trim10Reg": 0x11,
    "Trim11Reg": 0x12,
    "Trim12Reg": 0x13,
    "Trim13Reg": 0x14,
    "Trim14Reg": 0x15,
    "Trim15Reg": 0x16,
    "Trim16Reg": 0x17,
    "Trim17Reg": 0x18,
    "Trim18Reg": 0x19,
    "Trim19Reg": 0x1A,
    "Trim20Reg": 0x1B,
    "Trim21Reg": 0x1C,
    "TrimLockReg": 0x1D,
    "TrimCRC0Reg": 0x1E,
    "TrimCRC1Reg": 0x1F,
    "Config0Reg": 0x20,
    "Config1Reg": 0x21,
    "Config2Reg": 0x22,
    "Config3Reg": 0x23,
    "Config4Reg": 0x24,
    "Config5Reg": 0x25,
    "Config6Reg": 0x26,
    "Config7Reg": 0x27,
    "Config8Reg": 0x28,
    "Config9Reg": 0x29,
    "Config10Reg": 0x2A,
    "Config11Reg": 0x2B,
    "Config12Reg": 0x2C,
    "Config13Reg": 0x2D,
    "Config14Reg": 0x2E,
    "Config15Reg": 0x2F,
    "Config16Reg": 0x30,
    "Config17Reg": 0x31,
    "Config18Reg": 0x32,
    "Config19Reg": 0x33,
    "Config20Reg": 0x34,
    "Config21Reg": 0x35,
    "Config22Reg": 0x36,
    "Config23Reg": 0x37,
    "ConfigLockReg": 0x38,
    "ConfigCRC0Reg": 0x39,
    "ConfigCRC1Reg": 0x3A,
    "FaultStatus0Reg": 0x40,
    "FaultStatus1Reg": 0x41,
    "FaultStatus2Reg": 0x42,
    "FaultStatus3Reg": 0x43,
    "FaultStatus4Reg": 0x44,
    "FaultStatus5Reg": 0x45,
    "FaultStatus6Reg": 0x46,
    "FaultMask0Reg": 0x47,
    "FaultMask1Reg": 0x48,
    "FaultMask2Reg": 0x49,
    "FaultMask3Reg": 0x4A,
    "FaultMask4Reg": 0x4B,
    "FaultMask5Reg": 0x4C,
    "FaultMask6Reg": 0x4D,
    "Control0Reg": 0x4E,
    "Control1Reg": 0x4F,
    "Control2Reg": 0x50,
    "Control3Reg": 0x51,
    "Control4Reg": 0x52,
    "Control5Reg": 0x53,
    "Control6Reg": 0x54,
    "Control7Reg": 0x55,
    "Control8Reg": 0x56,
    "Control9Reg": 0x57,
    "Control10Reg": 0x58,
    "Control11Reg": 0x59,
    "Control12Reg": 0x5A,
    "Control13Reg": 0x5B,
    "Control14Reg": 0x5C,
    "Control15Reg": 0x5D,
    "Control16Reg": 0x5E,
    "Control17Reg": 0x5F,
    "Control18Reg": 0x60,
    "Control19Reg": 0x61,
    "Control20Reg": 0x62,
    "Control21Reg": 0x63,
    "Control22Reg": 0x64,
    "Control23Reg": 0x65,
    "Control24Reg": 0x66,
    "Control25Reg": 0x67,
    "Control26Reg": 0x68,
    "Control27Reg": 0x69,
    "Control28Reg": 0x6A,
    "Control29Reg": 0x6B,
    "ControlScratch0": 0x6C,
    "ControlScratch1": 0x6D,
    "ControlScratch2": 0x6E,
    "ControlScratch3": 0x6F,
    "ControlScratch4": 0x70,
    "ControlScratch5": 0x71,
    "ControlScratch6": 0x72,
    "ControlScratch7": 0x73,
    "ControlPP0Reg": 0x74,
    "Control30Reg": 0x75}


def locustRegDump(gnTest, locustRegMap, target="HostLocust"):
    regDump=[]

    for key, addr in locustRegMap.items():
        result = gnTest.locustB2P.readI2CRegs(bus=0x00, slave_addr=0x33, read_len=0x1, register=addr, rtype="reg8",
                                              destination=target, addDum=True)
        print(f'{key} Addr: 0x{addr:02x} Data: 0x{result[0]:02x}')
        regDump.append([key, addr, result[0]])
    return regDump

if __name__ == '__main__':
    print('Locust Reg Dump')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 2.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default='/dev/cu.usbserial-gnhost0', required=True)
    parser.add_argument('-n', '--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)
    parser.add_argument('-e', '--export', help='Dump File Name', type=str, default='locustRegDump.csv')
    parser.add_argument('-t', '--target', help='target can be host or device', type=str, default='host')
    args = parser.parse_args()

    if 'host' in args.target:
        target = 'HostLocust'
    else:
        target = 'DeviceLocust'

    GNH_UART ={
            'portname': args.serialport,
            'baudrate': 905600, # DON'T TOUCH BAUDRATE!
            'timeout':0.2
            }
    FTDISerialNumber = GNH_UART['portname'].split('-')[1][:-1]
    if args.not_programmed:
        i2cPortName = get_unprogrammed_sn()
    else:
        i2cPortName = 'ftdi://ftdi:2232:'+FTDISerialNumber+'/2'

    b2pUart = serial.Serial(GNH_UART['portname'],baudrate=GNH_UART['baudrate'],timeout=GNH_UART['timeout'])
    gnTest = grassNinjaHost(b2pUart,i2cPortName)
    timeBegin = time.time()

    regDump=locustRegDump(gnTest, locustRegMap, target)

    with open(args.export, 'w') as f:
        f.write('Locust Host Dump GrassNinja\n')
        for val in regDump:
            f.write(f'{val[0]},{val[1]:02x},{val[2]:02x}\n')
