---
title: 利用frp实现内网穿透
date: 2024-01-25 14:38:18
tags: frp 内网穿透
categories: 随笔
---
# 准备工作
1. frpc
2. 拥有公网ip地址的ECS
3. 一台安装有openwrt的路由器
4. 内网主机

<!-- more -->
frp分为frps和frpc，frps用于服务器，frpc用于客户端，本实例将公网ecs作为frp的服务器，openwrt路由器作为frp的客户端

# 公网设置
下载frps到公网ecs，在frps所在目录下创建一个frps.ini用于配置frps。
其中frps.ini的内容为：
```shell
[common]
bind_port = #和客户端通信的端口
token = #用户端连接的密码
dashboard_port = #监控面板的端口
dashboard_user = #监控面板的用户名
dashboard_pwd = #监控面板的密码
enable_prometheus = true # 建议默认为true
log_file = /var/log/frps.log #日志
log_level = info #日志级别，建议info
log_max_days = 3 #保存日志最大天数，建议3天或者7天
```
其中，bind_port和token用于和openwrt路由器上安装的frpc保持一致，有dashboard_port、dashboard_user以及dashboard_pwd用于在这台ecs上查看frps的状态

# openwrt设置
## fprc设置
![openwrt配置](openwrt配置.png)
## 远程开机设置
windows远程开机的话，百度一下就可以了。
流程就是，在手机上下载一个wake on lan，通过这个app的远程开机端口连接到公网ecs的远程开机端口，然后公网ecs的这个远程开机端口连接到openwrt的frpc的远程开机端口，通过广播唤醒windows主机
![wol](wol.png)
## 远程桌面映射设置
![rdp](rdp.png)
注意的是这里要在公网ecs上放开bind_port，dashboard_port, 远程开机以及远程桌面的端口。
本地windows主机需要放开3389的端口，建立入站规则