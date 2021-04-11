# autosyslog
自动化批量配置syslog发送，脚本基于：CentOS7.6开发。

## 脚本依赖
本脚本所需依赖：`expect-5.45-14.el7_1.x86_64`、`libpcap-1.5.3-11.el7.x86_64`、`nmap-6.40-13.el7.x86_64`、`nmap-ncat-6.40-13.el7.x86_64`、`tcl-8.5.13-8.el7.x86_64`

安装依赖：`yum -y install expect nmap nmap-nact libpcap tcl`

## 使用帮助
添加执行权限：`chmod +x socsyslog.sh`

Help: 
```
test ~]# ./socsyslog.sh [--help|-h]
	Desc: SOC LINUX SYSLOG 远程配置脚本
	Usage: socsyslog.sh [clientiplist.txt] [socip] [isa]
    clientiplist.txt: 客户端IP列表
    socip: 日志审计IP
    isa: 密码或密钥登录，密钥输入1，密码输入0
```

clientiplist.txt文本要求:
	```
	192.168.1.100 22 password
	```

## 使用案例
密码登录：`./socsyslog.sh clientiplist.txt 192.168.1.243 0`

