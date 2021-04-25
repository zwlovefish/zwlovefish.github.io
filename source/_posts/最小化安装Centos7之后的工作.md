---
title: 最小化安装Centos7之后的工作
date: 2021-03-22 20:39:27
tags: Centos 7, 开发环境
categories: 开发环境
---
# 设置vmware为桥接网络
# 配置静态ip地址
```shell
#cd /etc/sysconfig/network-scripts
```
修改ifcfg-ens33内容，修改<font color="blue">BOOTPROTO=static ONBOOT=yes</font>
添加：
```shell
IPADDR=192.168.31.10
GATEWAY=192.168.31.1
NETMASK=255.255.255.0
```
<!-- more -->
# 重启网络
```shell
#systemctl restart network
```
# 安装net-tools使用ifconfig
```shell
#yum search ifconfig =====>查找软件包
#yum install net-tools.x86_64
```
# 安装wget用来更换源
```shell
#yun install wget.x86.64
```
# 更换为阿里云源
```shell
备份
#mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
下载新的CentOS-Base.repo到/etc/yum.repos.d中
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-{5,6,7,8}.repo
比如centos7
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
生成缓存
yum makecache
```
# 配置java
```shell
解压jdk到/opt下
#tar zxvf jdk-8u281-linux-x64.tar.gz -C /opt
设置java环境变量
#vi .bashrc
export JAVA_HOME=/opt/jdk1.8.0_281
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
```
# 配置maven3.6
```shell
解压到/opt目录下
#tar -zxvf apache-maven-3.6.3-bin.tar.gz -C /opt
配置本地仓库地址
<localRepository>/root/.repos</localRepository>
配置阿里云镜像
<mirror>
    <id>aliyunmaven</id>
    <mirrorOf>*</mirrorOf>
    <name>阿里云公共仓库</name>
    <url>https://maven.aliyun.com/repository/public</url>
</mirror>
设置maven环境变量
export MAVEN_HOME=/opt/apache-maven-3.6.3
export PATH=$MAVEN_HOME/bin:$PATH
#source .bashrc
```
# 安装mysql
```shell
解压到/opt/mysql中
#tar -zxvf mysql-8.0.23-1.el7.x86_64.rpm-bundle.tar -C /opt/mysql
查看是否安装有mariadb
#rpm -qa | grep mariadb
卸载mariadb
#rpm e mariadb-libs-5.5.68-1.el7.x86_64.rpm --nodeps --force
安装common
#rpm -ivh mysql-community-common-8.0.23-1.el7.x86_64.rpm --nodeps --force
安装libs
#rpm -ivh mysql-community-libs-8.0.23-1.el7x86_64.rpm --nodeps --force
安装client
#rpm -ivh mysql-community-client-8.0.23-1.el7.x86_64.rpm --nodeps --force
安装server
#rpm -ivh mysql-community-server-8.0.23-1.el7.x86_64.rpm --nodeps --force
查看mysql是否安装完全
#rpm -qa | grep mysql
mysql初始化
#mysqld --initialize
#chown mysql:mysql /var/lib/mysql -R
#systemctl start mysqld.service
#systemctl enable mysqld
查看数据库密码
#cat /var/log/mysqld.log | grep password
登录数据库
#mysql -uroot -p (如果克隆的话，需要mysql -uroot -proot登录修改一下密码即可)
修改密码
mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123456';
退出
mysql> exit
重新登录
#mysql -uroot -p123456
远程登录
mysql> create user 'root'@'%' identified with mysql_native_password by '123456';
mysql> grant all privileges on *.* to 'root'@'%' with grant option;
mysql> flush privileges;
命令修改加密规则，MySql8.0版本和5.0的加密规则不一样，而现在的可视化工具只支持旧的加密方式。
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'root' PASSWORD EXPIRE NEVER;
刷新
mysql> flush privileges;
永久开启3306端口
#firewall-cmd --zone=public --add-port=3306/tcp --permanent
#firewall-cmd --zone=public --add-port=3306/udp --permanent
#firewall-cmd --reload
```





