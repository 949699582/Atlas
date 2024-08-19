#python3
# GrassNinja python driver
# EE Calvin Ryan
# coyote@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PARTY

import serial
import time
import argparse
from grassninja import grassNinjaHost


if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-c', '--commsmode', help='ASK or DPM.', type=str, default=False, required=True)
    parser.add_argument('--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)

    args = parser.parse_args()

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

    timeBegin = time.time()

    FSM0 = gnTest.locustB2P.readLocustReg(0x45,target='host',n=1)[0]
    FSM1 = 0
#    FSM1 = gnTest.locustB2P.readLocustReg(0x45,target='device',n=1)[0]
    print("GN host: state machine check, host %d, device %d" %(FSM0>>2, FSM1>>2))
    
    gnTest.setCommsMode(mode=args.commsmode)
    FSM0 = gnTest.locustB2P.readLocustReg(0x45,target='host',n=1)[0]
    FSM1 = gnTest.locustB2P.readLocustReg(0x45,target='device',n=1)[0]
    FSM2 = gnTest.locustB2P.readLocustReg(0x42,target='device',n=1)[0]
    print("GN host: state machine check, host fsm %d, device fsm %d, device comms mode %d" %(FSM0>>2, FSM1>>2, (FSM2>>2) & 0b11))

    print("\nScript complete in %fs" %(time.time()-timeBegin))
    # Close the FTDI ports
    gnTest.closePorts()
