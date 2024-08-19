#python3

# HWEE Haoran Qi, 2023/09/11
# HWTE Yan Li, 2023/12/22
# Update script to add locust device reset to avoid triggering locust device fault during testing


import serial
import time
import argparse
from grassninja import grassNinjaHost


LAGUNA_I2C_7BIT_ADDR = 0x11
DEBUG_FLAG = True

def setASKTimeouts(): 
    gnTest.locustB2P.writeLocustReg(0x36,[0x3f,0x5f],target='host')
    gnTest.locustB2P.writeLocustReg(0x55,[0x1f,0xbf],target='host')
    gnTest.locustB2P.writeLocustReg(0x36,[0x3f,0x5f],target='device')
    gnTest.locustB2P.writeLocustReg(0x55,[0x1f,0xbf],target='device')
    gnTest.locustB2P.writeLocustReg(0x59,0xE7,target='device')
    gnTest.locustB2P.writeLocustReg(0x51,0x01,target='device')
    gnTest.locustB2P.writeLocustReg(0x51,0x00,target='device')
    return


def setSLPPowerRails():
    destination="DeviceLocust"
    #gnTest.locustB2P.writeI2C(bus=0x01, slave_addr=LAGUNA_I2C_7BIT_ADDR, data=0x01, wtype="reg16", register=0x480e, destination = destination, addDum=True) # maybe unnecessary
    gnTest.locustB2P.writeI2C(bus=0x01, slave_addr=LAGUNA_I2C_7BIT_ADDR, data=0x01, wtype="reg16", register=0x24ae, destination = destination, addDum=True)
    #gnTest.locustB2P.writeI2C(bus=0x01, slave_addr=LAGUNA_I2C_7BIT_ADDR, data=0x01, wtype="reg16", register=0x24b0, destination = destination, addDum=True)
    gnTest.locustB2P.writeI2C(bus=0x01, slave_addr=LAGUNA_I2C_7BIT_ADDR, data=0x01, wtype="reg16", register=0x24b2, destination = destination, addDum=True)
    gnTest.locustB2P.writeI2C(bus=0x01, slave_addr=LAGUNA_I2C_7BIT_ADDR, data=0x01, wtype="reg16", register=0x24b3, destination = destination, addDum=True)


def _averageList(a=[]):
        total = 0
        n = 0
        for x in a: 
             total += x
             n += 1
        return float(total/n)

if __name__ == '__main__': 
    print('GrassNinjaHost test: P1')
    parser = argparse.ArgumentParser(description='GrassNinja Host Application, ver 1.0')
    parser.add_argument('-p', '--serialport', help='Serial port name.', type=str, default=False, required=True)
    parser.add_argument('-m', '--not_programmed', help='Use if serial# is not programmed.', action='store_true', default=False)
    parser.add_argument('-n', '--samples', help='Number of samples to calculate current', type=int, default=20)

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

    gnTest.enableCharging(True)
    gnTest.eUSBDurant(on=False,dfu=False)
    gnTest.locustB2P.sendReset("DeviceLocust",reset_mode=0x01)
    gnTest.locustB2P.writeLocustReg(0x52,0x45,target='host')
    gnTest.locustB2P.sendPing(destination="DeviceLocust")
    setASKTimeouts()
    gnTest.enableCharging(False)
    gnTest.locustB2P.getState(destination="DeviceLocust")
    gnTest.locustB2P.writeLagunaReg(0x24ae,0x01)
    gnTest.locustB2P.writeLagunaReg(0x24b2,[0x01,0x01])
    gnTest.forceLagunaPowerState(state = "SLP")
    time.sleep(1)
    print("gn host: *** PMU in SLP mode now ***")
    [v,i] = gnTest.ccadcRead(addDum=True)
    print('gn host: battery voltage=%fV, current=%fmA' %(v, i))
    gnTest.closePorts()
