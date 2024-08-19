#!/bin/bash
#author = 'feng'

filename=$1
ip=$2

expect -c "  
set timeout -1;
spawn time scp $filename root@$ip:/mix/addon/test_function/map/;
expect {
	\"password: \" { send \"123456\r\" }
	\"yes/no\" { send \"yes\r\"; exp_continue }
};
expect 100%
expect eof
"

