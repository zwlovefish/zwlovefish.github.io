---
title: SpringBoot介绍
date: 2020-05-13 19:33:54
tags: springboot介绍
categories: SpringBoot
---
Spring Framework已有十余年的历史了，已成为Java应用程序开发框架的事实标准。
<!--- more -->
Spring的生态圈里正在出现很多让人激动的新鲜事物，涉及的领域涵盖云计算、大数据、无模式的数据持久化、响应式编程以及客户端应用程序开发。 

Spring Boot提供了一种新的编程范式，能在小的阻力下开发Spring应用程序。有了它，你可以更加敏捷地开发Spring应用程序，专注于应用程序的功能，不用在Spring的配置上多花功夫，甚至完全不用配置。

- 一开始，Spring用XML配置
- Spring 2.5引入了基于注解的组件扫描
- Spring 3.0引入了基于Java的配置

所有这些配置都代表了开发时的损耗。因为在思考Spring特性配置和解决业务问题之间需要 进行思维切换，所以写配置挤占了写应用程序逻辑的时间。<font color = "red">这一句话真的是说的太好了！！！！</font>

# SpringBoot精要
Spring Boot将很多魔法带入了Spring应用程序的开发之中，其中重要的是以下四个核心:

- 自动配置：针对很多Spring应用程序常见的应用功能，Spring Boot能自动提供相关配置。
-  起步依赖：告诉Spring Boot需要什么功能，它就能引入需要的库。
- 命令行界面：这是Spring Boot的**可选特性**，借此你只需写代码就能完成完整的应用程序， 无需传统项目构建。
- Actuator：让你能够深入运行中的Spring Boot应用程序，一探究竟。

每一个特性都在通过自己的方式简化Spring应用程序的开发。

# 安装SpringBoot CLI
## Unix安装SpringBoot CLI
1. 下载SpringBoot CLI
2. 解压
3. 将它的bin目录添加到系统环境中

安装SpringBoot CLI的下载地址是：

1. http://repo.spring.io/release/org/springframework/boot/spring-boot-cli/1.3.0.RELEASE/springboot-cli-1.3.0.RELEASE-bin.zip
2. http://repo.spring.io/release/org/springframework/boot/spring-boot-cli/1.3.0.RELEASE/springboot-cli-1.3.0.RELEASE-bin.tar.gz

## Mac OX安装SpringBoot CLI
```bash
$ brew tap pivotal/tap
$ brew install springboot
```

检测是否安装成功，使用
```bash
$ spring --version
```

如果使用homebrew安装SpringBoot CLI，则命令行补全已经安装完毕

如果手动安装：

每次开启一个窗口都需要使用
```bash
$ . ~/.sdkman/springboot/current/shell-completion/bash/spring 
```
你也可以把这个脚本复制到你的个人或系统脚本目录里

如果你在Windows上进行开发，或者没有用BASH或zsh，那就无缘使用这些命令行补全脚本了。   
<font color = "red">Windows是真jb捞比</font>

