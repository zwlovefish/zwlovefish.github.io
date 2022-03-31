---
title: mysql集群搭建
date: 2021-04-26 21:53:54
tags: Centos 7,开发环境
categories: 开发环境,MySQL
---
准备好mysql8，centos7以及三台主机 211、212、213。以211为主，212，213为从主机

<!-- more -->
# 主mysql配置
vi /etc/my.cnf

server_id=211

log-bin=mysql-bin

service mysqld restart

show variables like '%server_id%';

show master status;记住position，后面配置从机的时候会用到
![1](1.png)

# 从mysql配置
```shell
vi /etc/my.cnf
server_id=212
log-bin=mysql-bin
binlog_do_db=test 这个test就是要同步的数据库
service mysqld restart
```

master_host 主服务器地址

master_user 主服务器用户名

master_password 主服务器密码

master_log_file 主服务器配置文件

master_log_pos 主服务器读取配置文件的开始位置，也就是从第多少行开始读取。

change master to 
                master_host='192.168.31.211',
                master_user='root',
                master_password='123456',
                master_log_file='mysql-bin.000001',
                master_log_pos=156;
                
![2](2.png)

start slave
![3](3.png)

SHOW SLAVE STATUS
![3](3.png)

如果是克隆的，会导致server-uuid一致，从而导致Slave_IO_Running为No，是的集群搭建失败。这时候去/var/lib/mysql中，将auto.cnf删除，重启服务即可

# 如果主从不同步
先关闭从数据库 stop slave
在主mastar上flush logs，在重新show master status，查看file和pos，接着重新打开从数据库