---
title: 初识MySQL
date: 2022-03-29 23:00:13
tags: 初识MySQL MySQL文件
categories: MySQL
---
MySQL使用TCP作为MySQL服务器程序和客户端程序之间的网络通信协议。
# MySQL服务器启动脚本
**mysqld** 执行mysqld可以打开一个MySQL进程
**mysqld_safe** 执行mysqld_safe会间接调用mysqld，并监控其状态， 如果MySQL服务器出现错误，会重新启动服务器程序，并将出错信息打印到日志
**mysql.server** 间接调用mysqld_safe，执行**mysql.server start/stop**即可开启和关闭MySQL服务器程序。
**mysql_mysqld_muti** 可以在一台机器上启动多个MySQL服务器示例
![查询请求执行过程](查询请求执行过程.png)

