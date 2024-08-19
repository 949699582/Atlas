import serial
import time
import sys
import re
import os
from time_module import *
from upload_log import upload_log
class SendCommandToDut():
	def __init__(self,baudrate = '19200',timeout = 3,port_type= 'number',log_path='/vault/logs/log.txt'):
		# self.command = 'ft serial\r\n'
		logs_directory = '/vault/logs/'
		if not os.path.exists(logs_directory):
			os.makedirs(logs_directory)
		self.log_path = log_path
		self.port_type = port_type
		self.baudrate = baudrate
		self.timeout = timeout
		self.portUrl = '/dev/cu.usbserial-FTDZWACR'
		# self.portUrl = self.catchPortUrl(self.port_type)
		self.command_json = {
						'read_sn_R':{
							"command":'ft serial\r\n',
							"pattern":'Bud R FG: (\w+)',
							'delimiter':'> ft:ok'
						},
						'read_sn_L':{
							"command":'ft serial\r\n',
							"pattern":'Bud L FG: (\w+)',
							'delimiter':'> ft:ok'
						},
						'read_sn_case':{
							"command":'ft serial\r\n',
							"pattern":'Case FG  : (\w+)',
							'delimiter':'> ft:ok'
						}
					}

	def catchPortUrl(self,port_type):
		list_all_port = os.popen('ls /dev').read().split('\n')
		# print(list_all_port)
		for port in list_all_port: 
			match_serial_port_resutl = re.search(r'usbmodem(\w+)',port)
			if match_serial_port_resutl:
				if len(match_serial_port_resutl.group(1)) > 4 and 'cu.' in port:
					match_serial_ports = port

		
		# print(f'match_serial_ports:{match_serial_ports}')
		match_condition_ports = [port for port in list_all_port if '04' in port and 'cu.usbmodem' in port]
		print(f'match_condition_ports-->{match_condition_ports}')
		if port_type == 'number':
			return f'/dev/{match_condition_ports[0]}'
		else:
			return f'/dev/{match_serial_ports}'

	def openPort(self):
		serPort = serial.Serial(self.portUrl,self.baudrate,timeout=self.timeout)
		if serPort.is_open:
			print('the port opened')
			return serPort
		else:
			return False

		# try:
		# 	serPort = serial.Serial(self.portUrl,self.baudrate,timeout=self.timeout)
		# 	if serPort.is_open:
		# 		return serPort
		# 	else:
		# 		return False
		# except Exception as e:
		# 	print(e)
	def closePort(self,serPort):
		serPort.close()
		if serPort.is_open:
			return False
		else:
			print('serial port has been closed!')
			return True
	def sendCommand(self,command,delimiter,pattern):
		upload_log.txt_log(self.log_path,f'{get_time_now()} TX ==> {command}')
		port = self.openPort()
		port.write(command)
		time.sleep(0.1)
		# port.write('\r\n'.encode('utf-8'))
		response = ''
		start_time = get_time_now()
		while True:
			if port.in_waiting > 0:
				data = port.read(port.in_waiting)  # 读取所有可用数据
				data_decode = data.decode('utf-8', errors='ignore')
				print(f'data_decode --> {data_decode}')
				response += data_decode
				if delimiter in response:
					break
				time.sleep(0.1)
			if time_sub_with_now(start_time)>=self.timeout:
				break


		print(f'response-->{response}')
		print(f'pattern-->{pattern}')

        
		# 将返回值解码为字符串

		try:
			result = re.search(pattern,response)
			print(f'regex result-->{result}')
			if result:
				print(f'result.group(1)-->{result.group(1)}')
				self.closePort(port)
				return_value = result.group(1)	
			else:
				self.closePort(port)
				return_value = False
		except Exception as e:
			print(f'sendCommand {command} error {e}')
			return_value = False
		finally:
			upload_log.txt_log(self.log_path,f'{get_time_now()} RX ==> {response}')
			return return_value


	def test_item(self,item):
		cmd_list = self.command_json[item]
		command = cmd_list["command"]
		pattern = cmd_list["pattern"]
		delimiter = cmd_list["delimiter"]
		return self.sendCommand(command,delimiter,pattern)
		# return self.sendCommand(command,delimiter,pattern)



if __name__ == "__main__":
	sendcommandToDut = SendCommandToDut(baudrate = '230400')

	hex_data = bytearray([0x01, 0x01, 0x01, 0x54, 0x00, 0x01, 0xBD, 0xE6])  # 这里假设要发送的十六进制数据
	ft_reset_command = hex_data
	ft_delimiter = '48'
	ft_pattern = '(48)'
	cmdResult = sendcommandToDut.sendCommand(ft_reset_command,ft_delimiter,ft_pattern)

	# time.sleep(1)
	# command = "ft tunnel open left infinite\r\n"
	# delimiter = '> ft:ok'
	# pattern = '(> ft:ok)'
	
	# cmdResult = sendcommandToDut.sendCommand(command,delimiter,pattern)
	# time.sleep(0.5)


	# command = 'cb read 0x11\r\n'
	# delimiter = 'cb:ok'
	# pattern = '(P)'
	# sendcommandToDut = SendCommandToDut(baudrate = '230400',port_type = 'serial')
	# cmdResult = sendcommandToDut.sendCommand(command,delimiter,pattern)




	# print(f'cmdResult-->{cmdResult}')
	# sendcommandToDut.test_item('read_sn_case')









