#python3
# GrassNinja python driver
# HWTE Yan Li, 2020/10/10
# yan.li@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PART

import serial
import time
import argparse
from grassninja import grassNinjaHost

def averageList(a=[]):
        total = 0
        n = 0
        for x in a: 
             total += x
             n += 1
        return float(total/n)

if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default='/dev/cu.usbserial', required=True)

    args = parser.parse_args()

    GNH_UART ={ 
            'portname': args.serialport,
            'baudrate': 905600, # DON'T TOUCH BAUDRATE!
            'timeout':0.2
            }
    FTDISerialNumber = GNH_UART['portname'].split('-')[1][:-1]
    i2cPortName = 'ftdi://ftdi:2232:'+FTDISerialNumber+'/2'

    b2pUart = serial.Serial(GNH_UART['portname'],baudrate=GNH_UART['baudrate'],timeout=GNH_UART['timeout']) 

    gnTest = grassNinjaHost(b2pUart,i2cPortName)

    tempV = []
    tempI = []

    [v,i] = gnTest.ccadcRead(addDum=True)

    print('gn host: battery voltage=%fV, current=%fmA' %(v, i))
    # Close the FTDI ports
    gnTest.closePorts()
