import csv
import os
class upload_log:
	def csv_write(path,line_content,headline_list=['item','status']):
		if os.path.exists(path):
			with open(path,mode = 'a',encoding = "utf-8-sig",newline="") as f:
				write = csv.writer(f)
				write.writerow(line_content)
		else:
			with open(path,mode = 'w',encoding = "utf-8-sig",newline="") as f:
				write = csv.writer(f)
				write.writerow(headline_list)
				write.writerow(line_content)
	def move_log(orignal_path,goal_path):
		print(f'orignal_path-->{orignal_path} goal_path-->{goal_path}')
		os.popen('cp '+orignal_path+' '+ goal_path)
	def txt_log(path,content):

		# 打开文件以追加模式，如果文件不存在则创建它
		with open(path, 'a', encoding='utf-8') as file:
		    file.write(content+'\n')
		print("文本内容已成功追加写入到文件。")

