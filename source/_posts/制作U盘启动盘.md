---
title: 制作U盘启动盘
date: 2026-04-13 13:43:37
tags: 工具
---
本篇文章使用命令行工具制作U盘启动
![制作linux镜像](制作linux镜像.jpg)
<!--more-->
# 下载linux镜像
# 准备U盘
插入U盘，执行以下命令列出所有磁盘设备：
```shell
diskutil list
```
重点关注带有**extern**的标识的设备
U盘的设备路径为/dev/diskX（X是数字，如disk2）。务必确认这是 U 盘，而非Mac的内置硬盘（如disk0），否则后续操作可能擦除Mac数据
# 卸载U盘(但是不拔出)
只有处于`未挂载`状态的U盘才能写入
```shell
diskutil unmountDisk /dev/diskX
```
成功会提示`Unmount of all volumes on diskX was successful`。
# 使用命令行工具
```shell
sudo dd if=~/Downloads/ubuntu-22.04.3-desktop-amd64.iso of=/dev/rdiskX bs=4m status=progress
```
- if=~/Downloads/ubuntu-22.04.3-desktop-amd64.iso，if是input file，指定iso文件。
- of=/dev/rdiskX，（r代表`raw`，原始设备）而非`diskX`，可大幅提升写入速度。
- bs=4m， bs(block size)指定块大小为4MB，平衡速度与稳定性（可选值：2m、4m、8m）。
- status=progress，实时显示写入进度（macOS 10.13+ 支持）。

完成后，终端会输出类似`X+Yrecords in X+Y records out`的信息
# 等待写入完成并弹出U盘
```shell
diskutil eject /dev/diskX
```

此时 U 盘已制作完成，可用于启动 Linux。
