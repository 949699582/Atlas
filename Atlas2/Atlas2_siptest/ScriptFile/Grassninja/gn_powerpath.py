#python3
# GrassNinja python driver
# HWTE Yan Li, 2020/10/10
# yan.li@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PART

import serial
import time
import argparse
from grassninja import grassNinjaHost


DEBUG_FLAG = True


if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-s', '--switch', help='Switch GN power path [on|off|2p8].', type=str, default=False, required=True)
    parser.add_argument('-n', '--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)

    args = parser.parse_args()
    state = args.switch

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

    gnTest.locustI2C.clearFault()


    if 'on' in state: 
        print('gn host: enable 4.5V funbus')
        gnTest.ioexp.locustVin(True)
        gnTest.enableCharging(True)
    if 'off' in state: 
        print('gn host: enable 1.8V pullup on funbus')
        gnTest.enableCharging(False)
    if '2p8' in state: 
        print('gn host: enable 2.8V funbus, this works for Grassninja V4 and later versions')
        gnTest.enableCharging(True)
        gnTest.ioexp.locustVin(False)

    # Close the FTDI ports
    gnTest.closePorts()
