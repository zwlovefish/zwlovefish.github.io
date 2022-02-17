---
title: centos7安装nginx
date: 2021-03-29 23:57:51
tags: Centos 7, 开发环境
categories: 开发环境
---

# 安装编译的依赖软件
yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel

<!-- more -->
# 安装nginx
```shell
下载nginx
# wget http://nginx.org/download/nginx-1.18.0.tar.gz
解压nginx 
# tar -zxvf nginx-1.18.0.tar.gz
编译nginx
# ./configure 
# make
# make install
切换到/usr/local/nginx安装目录
启动nginx
./nginx
```

# 查看是否启动成功
ps -ef | grep nginx

# 开启80端口
```shell
#firewall-cmd --zone=public --add-port=80/tcp --permanent
#firewall-cmd --reload
```
# 访问服务器的ip
