#!/usr/bin/env bash


# ------------------------- 
# SOC LINUX SYSLOG  远程配置脚本
# SOC Version: all
# Author: xs zhou 
# Version: V1.0 
# Time: 2021-03-07
# ------------------------- 


# 预定义变量
# 运行命令
RUNBAK="if \[ -f /etc/rsyslog.conf \];then echo '*.* @$2:514' >> /etc/rsyslog.conf && systemctl rsyslog restart && echo 'syslogok';else echo '*.* @$2:514' >> /etc/syslog.conf && service syslog restart && echo 'syslogok';fi;"
RUN="echo '*.* @$2:514' >> /etc/rsyslog.conf"
RUN1="systemctl restart rsyslog"
# 当前路径
SCRIPT_PATH=`pwd`
# 输出日志
INSTALL_LOG="${SCRIPT_PATH}/SyslogInstall.log"
# 安装日志
MAIN_LOG="${SCRIPT_PATH}/SyslogMain.log"
# 是否密码登录
ISA=$3
# IP列表文件（绝对路径或相对路径）
AGENTLIST=$1

#help
help(){
	cat << EOF
Desc: SOC LINUX SYSLOG 远程配置脚本
Usage: socsyslog.sh [clientiplist.txt] [socip] [isa]
    clientiplist.txt: 客户端IP列表
    socip: 日志审计IP
    isa: 密码或密钥登录，密钥输入1，密码输入0
EOF
}

# 检测网络连通性
# 
# 检测端口是否开放
CHECK_PORT(){
    nc -w2 -z $1 $2 &>/dev/null
    if [ $? -ne 0 ];then
        return 1
    fi
    return 0        
}
# 检查网络
CHECK_NETWORK(){
        while read line
        do      
                # Info[0]=ip Info[1]=port Info[2]=password
                info=($line)
                CHECK_PORT ${info[0]} ${info[1]}
                if [ $? -eq 0 ];then
                        echo "${info[@]}" >> alive.log
                        echo -e "[\033[40;32mINFO\033[0m] ${info[0]} 网络连接成功!" |tee -a $INSTALL_LOG
                else
                        echo -e "[\033[40;31mWARN\033[0m] ${info[0]} 网络连接超时!" |tee -a $INSTALL_LOG
                fi
        done < $AGENTLIST
}


# 远程执行命令
SSH(){
        ip=$1
        password=$2
        port=$3
        run=${RUN}
        run1=${RUN1}
        expect <<-EOF
        	spawn ssh -p $port root@$ip 
       		set timeout 6
        	expect {
                	"yes/no" { send "yes\r"; exp_continue }
                	"password:" { send "$password\r" }
			}	
			expect 	"password" { exit 4 }
			expect  "~]#" { send "$run\r" }
            expect  "~]#" { send "$run1\r" }
            expect  "~]#" { send "exit\r" }
			# expect 	 "syslogok" {exit 0}
        	# expect timeout { puts " timeout...";exit 1}
        	expect eof
EOF
}
# 远程执行命令
SSHISA(){
        ip=$1
        port=$2
        run=${RUN}
        expect <<-EOF
            spawn ssh -i trs -p $port root@$ip 
            set timeout 6 
            expect "yes/no" { send "yes\r"; exp_continue }
            expect  "~]#" { send "$run\r" }
            expect 	 "syslogok" {exit 0}
            expect timeout { puts " timeout...";exit 1}
            expect eof
EOF
}

# 循环执行
RUN_COMD(){
        while read line
        do      
                info=($line)
                if [ $ISA -eq 1 ];then
                    SSHISA ${info[0]} ${info[1]} >> $MAIN_LOG
                elif [ $ISA -eq 0 ]; then
                    SSH ${info[0]} ${info[2]} ${info[1]} >> $MAIN_LOG
                fi
                flag1=$?
                if [ $flag1 -eq 4 ];then
                        echo -e "[\033[40;31mWARN\033[0m] ${info[0]} 密码错误!" |tee -a $INSTALL_LOG
                elif [ $flag1 -eq 0 ];then
                        echo -e "[\033[40;32mINFO\033[0m] ${info[0]} syslog配置成功" |tee -a $INSTALL_LOG
                else
                        echo -e "[\033[40;31mWARN\033[0m] ${info[0]} 执行超时,请查看SyslogMain.log" |tee -a $INSTALL_LOG
                fi                                      
        done < alive.log
}

# 安装对应的程序,expect nc 
INSTALL(){
    which expect &>/dev/null
    if [  $? -ne 0 ];then
        rpm -ivh tcl-8.5.13-8.el7.x86_64.rpm
        rpm -ivh expect-5.45-14.el7_1.x86_64.rpm
    fi
    which nc &>/dev/null
    if [  $? -ne 0 ];then
        rpm -ivh libpcap-1.5.3-11.el7.x86_64.rpm
        rpm -ivh nmap-ncat-6.40-13.el7.x86_64.rpm
        rpm -ivh nmap-6.40-13.el7.x86_64.rpm
    fi
}

# 脚本开始
# INSTALL
case $1 in
    -h)
        help
        exit 0
        ;;
    --help)
        help
        exit 0
        ;;
esac

if [ ! -f $1 ];then
    echo -e "[\033[40;31mWARN\033[0m] ${AGENTLIST}文件不存在，请检查!" |tee -a $INSTALL_LOG
    exit 1
fi
if [ -z "${SCRIPT_PATH}/alive.log" ];then
    rm -rf alive.log
fi
CHECK_NETWORK
echo -e "[\033[40;31mWARN\033[0m] 正在进行批量操作!" |tee -a $INSTALL_LOG
RUN_COMD

rm -rf alive.log

exit 0
