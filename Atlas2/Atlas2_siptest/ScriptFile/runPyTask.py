import argparse
import os
import signal
import subprocess
import sys
import time
from subprocess import Popen, PIPE
from threading import Timer

 
def kill_all(child_process):
    try:
        print("Task running timeout!!!")
        c_pid = child_process.pid
        os.killpg(c_pid, signal.SIGKILL)
    except Exception as e:
        print(e)


if __name__ == '__main__':
    print("666")
    parser = argparse.ArgumentParser(description='Python task with timeout.')
    parser.add_argument('-c', '--command', help='command', type=str, required=True)
    parser.add_argument('-t', '--timeout', help='timeout in seconds.', type=float, required=True)
    args = parser.parse_args()
    child_timeout = args.timeout
    print("Task timeout: " + str(child_timeout) + '\n')
    paramString = args.command
    child = Popen(paramString, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, preexec_fn=os.setpgrp)
    child_timer = Timer(child_timeout, kill_all, [child])
    result = ''
    try:
        child_timer.start()

        if child is None or child.stdout.fileno() == -1:
            print("run cmd fail: {}".format(paramString))
        else:
            while child.poll() is None:
                print(child.stdout.readline())
                time.sleep(0.001)
    except Exception as e:
        raise e
    finally:
        result += str(child.stdout.read())
        temp = str(child.stderr.read())
        if len(temp) > 0:
            result += temp
        child_timer.cancel()
        print(result)
