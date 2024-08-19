#python3
# GrassNinja python driver
# Jingqian Wang, 2022/03/30
# jingqian_wang@apple.com
# DO NOT DISTRIBUTE THE CODE TO THE 3RD PART

import serial
import time
import argparse
import threading
from grassninja import grassNinjaHost
import os, sys

class HiddenPrints:
    def __enter__(self):
        self._original_stdout = sys.stdout
        sys.stdout = open(os.devnull, 'w')

    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout.close()
        sys.stdout = self._original_stdout


DEBUG_FLAG = True

global gCommad
global gTunnelOpen

def b2pTunnelExecute(cmd=None): #Execute the command remotely through the tunnel
    data[0] = 0 # session id
    data[1] = 1 # data_session_status_ok
    if cmd != None:
        data[2:] = [ord(c) for c in cmd]
    else:
        del data[2:]
    print("data: ", data)
    
    # B2P_CMD_DS_DATA: 0x0012
    return gnTest.b2pTransfer(opcode=0x12, data=data)

def b2pTunnelSync():
    global gCommad
    global gTunnelOpen
    rsp = bytearray()
    while gTunnelOpen:
        time.sleep(0.05)
        with HiddenPrints():
            rsp = b2pTunnelExecute(gCommad)
            gCommad = None
        # Check it the connect is timeout or closed
        if rsp == b'\x00\x00':
            gTunnelOpen = False
        msg = rsp[2:].decode()
        if msg != "":
            print(msg, end='')
            msg = ""

if __name__ == '__main__':
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-n', '--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)

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

    # Ping SoC
    data = [0x0, 0x2]
    # B2P_CMD_PING: 0x0000
    rsp = gnTest.b2pTransfer(opcode=0x0, data=data)
    print(rsp)
    if rsp != b'\x02\x03':
        print("Error: SoC is not in FT mode!")
        sys.exit(1)
   
    # Data session connect
    data = [0x0, 0x1] # DATA_SESSION_ID_TEST, DATA_SESSION_STATUS_CONNECTION_OPEN
    # B2P_CMD_DS_CONNECT: 0x0010
    rsp = gnTest.b2pTransfer(opcode=0x10, data=data)

    if rsp != b'\x00\x01':
        print("Error: Data session is not connected!")
        sys.exit(1)
            
    gCommad = None
    b2pThread = threading.Thread(target=b2pTunnelSync)

    print("====== Tunnel is open ======")
    gTunnelOpen = True
    b2pThread.setDaemon(True)
    b2pThread.start()
    
    
    while True:
        try:
            strIn = input("] ")
            if strIn != "":
                gCommad =strIn + "\n"
            if gTunnelOpen == False:
                print("====== Tunnel is closed ======")
                # Close the FTDI ports
                gnTest.closePorts()
                sys.exit(0)
        except Exception as e:
            print(e)
            break

    # Close the FTDI ports
    gnTest.closePorts()
