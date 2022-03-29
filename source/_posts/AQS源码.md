---
title: AQS源码
date: 2022-03-07 21:58:04
tags: AbstractQueuedSynchronizer
categories:  JDK源码
---

wait queue node class:

有几个状态值：
SIGNAL(-1)：表示线程已经准备好了，就等资源释放了
CANCELLED(1): 表示线程获取锁的请求已经取消了
CONDITION(-2)：表示节点在等待队列中，节点线程等待唤醒
PROPAGATE(-3)：当前线程处在SHARED情况下，该字段才会使用

<!-- more -->
![AQS框架](AQS框架.png)
