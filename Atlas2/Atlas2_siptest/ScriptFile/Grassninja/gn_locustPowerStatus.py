#python3
# GrassNinja python driver
# HWTE Yan Li, 2020/10/10
# yan.li@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PART

# This script is used to enumerate all KIS ports, after upload firmware updater app to Durant
# This is required for provenance app

import serial
import time
import argparse
from grassninja import grassNinjaHost


if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-s', '--switch', help='Switch KIS FWDL on or off.', type=str, default='on', required=False)
    parser.add_argument('-n', '--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)

    args = parser.parse_args()
    switch = args.switch # 'on'|'off'

    GNH_UART ={ 
            'portname': args.serialport,
            'baudrate': 905600, # DON'T TOUCH BAUDRATE!
            'timeout':0.2
            }
    FTDISerialNumber = GNH_UART['portname'].split('-')[1][:-1]
    if args.not_programmed:
        from grassninja import get_unprogrammed_sn
        i2cPortName = get_unprogrammed_sn()
    else:
        i2cPortName = 'ftdi://ftdi:2232:'+FTDISerialNumber+'/2'
    b2pUart = serial.Serial(GNH_UART['portname'],baudrate=GNH_UART['baudrate'],timeout=GNH_UART['timeout']) 
    gnTest = grassNinjaHost(b2pUart,i2cPortName)


    gnTest.locustB2P.sendReset("DeviceLocust", reset_mode=0x01) # reset has to be done before ping to setup linkstate; Otherwise b2p path to device doesn't work
    gnTest.locustB2P.sendPing(destination="DeviceLocust")
    val = gnTest.locustB2P.readLocustReg(0x41,target='device',addDum=True)[0]
    print("GN host - Locust device power status: VDDIO_PG %d, VID_LDO_PG %d, VDDMAIN_PG %d, VDD_INT_PG %d" %((val>>7)&0b1, (val>>6)&0b1, (val>>5)&0b1, (val>>4)&0b1))

    # Close the FTDI ports
    gnTest.closePorts()
