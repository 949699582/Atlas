import serial
import json
# 定义 JSON 文件的路径
file_path = '/vault/Config.json'
# 读取 JSON 文件
value = ""
with open(file_path, 'r') as file:
    # 加载 JSON 数据
    data = json.load(file)

    # 获取键为 "TTT" 的值
    value = data.get('FixtureControl', '键 TTT 不存在')

    # 输出值
    print(f'键 "fixturePort" 的值是: {value}')

# 串口配置 expect:01 01 01 01 90 48  fail:01 01 01 00 51 88
port_name = value  # 串口设备名，根据实际情况修改
baud_rate = 19200  # 波特率
# data_bits = 8  # 数据位
# stop_bits = 1  # 停止位
# parity = serial.PARITY_NONE  # 校验位，这里设为无校验位

# 打开串口
ser = serial.Serial(port_name, baud_rate, timeout=0)

# 010101540001BDE6
try:
    print("=============1")
    # 准备要发送的十六进制数据（以字节形式）
    hex_data = bytearray([0x01, 0x01, 0x01, 0x30, 0x00, 0x01, 0xFC, 0x39])  # 这里假设要发送的十六进制数据
    print("=============2")
    # 发送数据
    ser.write(hex_data)
    print("=============3")
    # 读取返回数据
    response = ser.read(100)  # 假设读取最多10个字节的返回数据
    print("=============4")
    # 输出返回数据的十六进制表示
    # print("接收到返回数据的十六进制表示:",response)
    # for byte in response:
    #     print(f"{byte:02X} ", end='')
    # print()  # 换行

    # 在循环中读取数据
    while True:
        response = ser.read(1000)
        if response:
            print("Data: =============")
            for byte in response:
                print(f"{byte:02X} ", end='')
            print()  # 换行
            break  # 读取成功后跳出循环
        else:
            print("NO Accept=============")

finally:
    # 关闭串口
    ser.close()
