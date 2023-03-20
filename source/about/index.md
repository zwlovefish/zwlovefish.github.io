---
title: about me
date: 2022-02-17 20:29:30
---

 <!-- <center>
     <h1>简历</h1>
 </center> -->

 <!-- ## <img src="assets/info-circle-solid.svg" width="20px">  -->
 ## 个人信息
 - 基本信息：周健伟，男，1994 年出生
 - 求职意向：Java 研发工程师
 - 电话： 17798545442
 - 邮件： 1149610059@qq.com

<!-- ## <img src="assets/graduation-cap-solid.svg" width="20px"> -->
## 教育经历

- 硕士，南京邮电大学，计算机技术，2017.9~2020.7
- 学士，山东交通学院，计算机科学与技术，2013.9~2017.7
- 通过了 CET4/6 英语等级考试

<!-- ## <img src="assets/briefcase-solid.svg" width="20px"> -->
## 工作经历

- **新华三集团，数据中心与运维产品开发部，JAVA 工程师，2020.9至今**

 1. 负责新华三数据中心SDN控制器Telemetry模块的研发。
 2. 负责新华三数据中心SDN控制器RoCE模块的研发。
 3. 维护新华三数据中心SDN控制器代码。


<!-- ## <img src="assets/project-diagram-solid.svg" width="20px"> -->
## 项目经历

- **Telemetrystream**

  使用到的技术有：**OSGI**，**PostgreSQL**，**Zookeeper**，**JVM缓存**

  Telemetry是一个实现对数据中心全网实现端到端的流量管理与故障监控的模块，服务器对设备的监控的配置通过本模块下发。在本模块中，主要负责：
  1. 数据存入JVM缓存并将其写入Zookeeper，以供多机集群内存数据一致以及主备倒换时，直接从zookeeper中获取数据，提高恢复速率
  2. 处理所有机器上通过zookeeper传过来的消息
  3. Netconf解析器，将消息转成netconf识别的XML格式的数据，在Master机器上通过rpc分发给设备，完成设备的自动配置以实现负载均衡
  4. 对设备埋点，采集设备上的数据并分析设备行为，与控制器产生的差异数据及时告警。
  5. 负责该模块的部分管理端页面的实现
  该模块可以实现**至少1000**台网元并发下发配置
- **RoCE网络**
  使用到的技术有：**OSGI**、**MySQL**，**Mybatis**，**Zookeper**，**JVM缓存**
  RoCE是基于以太网的远端内存直接访问，设备之间组成RoCE网络的配置通过本模块下发。在本模块中，主要负责：
  1. 数据存入JVM缓存并将其写入Zookeeper，以供多机集群内存数据一致以及主备倒换时，直接从zookeeper中获取数据，提高恢复速率
  2. 搭建MySQL的PXC服务器
  3. 与上个项目需要将Rest数据存入每个机器的Postgre SQL不同之处在于，本项目通过MyBatis仅在Leader上将数据存入MySQL数据库，MySQL数据库是以PXC形式提供服务的。
  4.  Netconf解析器，将消息转成netconf识别的XML格式的数据，在Master机器上通过rpc分发给设备，完成设备的自动配置以实现负载均衡
  5. 基于RoCE配置将其解析成对应的RoCE调优数据，让用户可以通过机器学习的算法动态调整当前RoCE网络配置
  6. 负责该模块的部分管理端页面的实现
  该模块可以实现**至少1000**台网元并发下发配置，通过泰尔测试，并已经在至少**2个局点运行1年**无网上问题发生

<!-- ## <img src="assets/tools-solid.svg" width="20px">  -->
## 技能清单

- 熟练 Java基础语法，集合和JUC包的使用，JVM等
- 熟练 MySQL, Mybatis等相关数据库技术
- 熟悉 Redis
- 熟悉 ZooKeeper
- 熟悉 OSGI、Spring、SpringBoot
- 了解 JavaScript，Angular
- 了解 docker，k8s
