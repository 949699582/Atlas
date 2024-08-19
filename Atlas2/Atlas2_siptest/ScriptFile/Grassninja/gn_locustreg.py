#python3
# GrassNinja python driver
# HWTE Yan Li, 2020/10/10
# yan.li@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PART

import serial
import time
import argparse
from grassninja import grassNinjaHost


if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-i', '--rw', help='Read or write the reg.', type=str, default=False, required=True)
    parser.add_argument('-r', '--register', help='Register', type=str, default=False, required=True)
    parser.add_argument('-d', '--data', help='Write data', type=str, default=False, required=False)

    args = parser.parse_args()
    reg = int(args.register,16) # register in hex, e.g, 0x71
    rw = args.rw # enum [r|w]

    GNH_UART ={ 
            'portname': args.serialport,
            'baudrate': 905600, # DON'T TOUCH BAUDRATE!
            'timeout':0.2
            }
    FTDISerialNumber = GNH_UART['portname'].split('-')[1][:-1]
    i2cPortName = 'ftdi://ftdi:2232:'+FTDISerialNumber+'/2'
    b2pUart = serial.Serial(GNH_UART['portname'],baudrate=GNH_UART['baudrate'],timeout=GNH_UART['timeout']) 
    gnTest = grassNinjaHost(b2pUart,i2cPortName)

    if 'r' == rw: 
        data = gnTest.locustB2P.readLocustReg(register=reg,target='device')
        print('GN host: locust device reg %s, data %s' %(hex(reg),hex(data[0])))
    if 'w' == rw:
        data = int(args.data,16) # data in hex, e.g, 0x32
        gnTest.locustB2P.writeLocustReg(register=reg,data=data,target='device')
        data = gnTest.locustB2P.readLocustReg(register=reg,target='device')
        print('GN host: locust device reg %s, data %s' %(hex(reg),hex(data[0])))


    # Close the FTDI ports
    gnTest.closePorts()
