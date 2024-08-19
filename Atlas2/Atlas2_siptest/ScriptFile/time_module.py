import datetime
import pytz
# import time

def time_sub_with_now(time_a):
	# time_now = datetime.datetime.now()
	# # 创建北京时区对象
	# beijing_tz = pytz.timezone('Asia/Shanghai')

	# # 将当前时间转换为北京时间
	# time_now = time_now.astimezone(beijing_tz)

	# time_now = time_now.strftime('%Y-%m-%d %H:%M:%S')
	time_now = get_time_now()

	str_time_b = datetime.datetime.strptime(time_now, "%Y-%m-%d %H:%M:%S")

	str_time_a = datetime.datetime.strptime(time_a, "%Y-%m-%d %H:%M:%S")
	# print(f'time_now:{time_now}--str_time_a:{str_time_a}')
	return (str_time_b-str_time_a).seconds

def get_time_now():
	time_now = datetime.datetime.now()
	# # 创建北京时区对象
	# beijing_tz = pytz.timezone('Asia/Shanghai')

	# # 将当前时间转换为北京时间
	# time_now = time_now.astimezone(beijing_tz)

	time_now = time_now.strftime('%Y-%m-%d %H:%M:%S')
	return time_now

def main():
	time_now = get_time_now()
	# time.sleep(3)
	return time_sub_with_now(time_now)

if __name__ == '__main__':
	main()