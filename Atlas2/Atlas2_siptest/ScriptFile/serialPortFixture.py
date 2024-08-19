import serial
import time
import json
def sendCommand(port,baud,delimiter,command,timeout = 3):
	command = command+'\n\n'
	serPort = serial.Serial(port,baud,timeout = timeout)
	serPort.write(command.encode('utf-8'))
	# time.sleep(2)
	response = ''
	start_time = time.time()
	while True:
		if serPort.in_waiting > 0:
			data = serPort.read(serPort.in_waiting)  # 读取所有可用数据
			data_decode = data.decode('utf-8', errors='ignore')
			# print(f'data_decode --> {data_decode}')
			response += data_decode
			if delimiter in response:
				break
			time.sleep(0.01)
		if time.time() - start_time >= timeout:
			break

	print(f'***\ncommand--->{command}response--->{response}\n***')
	return response
def main():
	json_path = '/Users/gdlocal/Documents/fixture_command.json'
	port = '/dev/cu.usbserial-A50285BI'
	baud = 115200
	delimiter = 'DATA_FINISH'
	command_list = ['DIODE_START_TEST=1,2,3,4,5,6,7,8,9,10']
	command_json_dic = {}
	for command in command_list:
		command_result = sendCommand(port,baud,delimiter,command,timeout = 5)
		command_json_dic[command] = command_result
	with open(json_path,'w') as json_file:
		json.dump(command_json_dic,json_file,indent = 4)
	print("write command data to json done!!")



if __name__ == '__main__':
	main()
	# port = '/dev/cu.usbserial-A50285BI'
	# baud = 115200
	# delimiter = '*_*'
	# command_list = ['RF_START_TEST','GET_PCB_VER','GET_FW_VER','READ_COEF3','READ_OFFSET3']
	# command_json_dic = 
	# for command in command_list:
	# 	sendCommand(port,baud,delimiter,command,timeout = 0.2)

