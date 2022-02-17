---
title: centos7安装nacos
date: 2021-03-22 21:24:22
tags: Centos 7, 开发环境
categories: 开发环境
---
# 解压nacos
```shell
#tar -zxvf nacos-server-2.0.0-BETA.tar.gz
```

# 备份当前配置
```shell
#cd /root/nacos/conf
#cp application.properties application.properties.backup
```
<!-- more -->
# 编辑配置
```shell
#vi application.properties
修改
spring.datasource.platform=mysql 取消注释
db.num=1
db.url.0=jdbc:mysql://127.0.0.1:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai 取消注释并修改serverTimezone=Asia/Shanghai
db.user.0=root 取消注释，修改为mysql用户名
db.password.0=123456 取消注释，修改为mysql密码
自定nacos系统服务并设置开机自启
#vim /lib/systemd/system/nacos.service
[Unit]
Description=nacos
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nacos/bin/startup.sh -m standalone (转到自己的脚本的地方nacos/bin里面)
ExecReload=
ExecStop=/usr/local/nacos/bin/shutdown.sh  (转到自己的脚本的地方nacos/bin里面)
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
# 重新加载nacos.service
```shell
#systemctl daemon-reload
```
# 设置自动开机启动：
```shell
#systemctl enable nacos.service
```
# 启动nacos
```shell
#systemctl start nacos.service
如果失败
#systemctl status nacos.service(缺少java的javac，报错信息which：no javac in (/usr/lcoal/sbin:/usr/local/bin:/usr/sbin:/usr/bin))
#ln -s /opt/jdk1.8.0_281/bin/javac /usr/bin/
```

# 如果改动了mysql平台，需要将nacos的数据导入到mysql中，执行脚本nacos-mysql.sql(在nacos/conf中)

# 开放端口
```shell
#firewall-cmd --zone=public --add-port=8848/tcp --permanent
#firewall-cmd --reload

#firewall-cmd --zone=public --add-port=7848/tcp --permanent
#firewall-cmd --reload
```
<font color="red">一定要开放7848这个端口，集群是通过7848端口保持心跳的，tmd，搞了劳资好长时间</font>
