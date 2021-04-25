---
title: SpringBoot自动化配置
date: 2020-05-19 17:07:56
tags: pringBoot自动化配置
categories: SpringBoot
---
# 创建自定义的安全配置
覆盖自动配置很简单，就当自动配置不存在，直接显式地写一段配置。这段显式配置的形式不限，Spring支持的XML和Groovy形式配置都可以。

在Spring Security的场景下，这意味着写一个扩展了WebSecurityConfigurerAdapter的配置类。

# 通过属性文件外置配置
SpringBoot的自动配置的Bean提供了300多个用于微调的属性。当你调整设置时，只要在环境变量、Java系统属性，JNDI、命令行参数或者属性文件里进行指定即可。

SpringBoot能从多种属性源获得属性：

1. 命令行参数
2. java:comp/env
3. JVM系统属性
4. 操作系统环境变量
5. 随机生成的带random.*前缀的属性(在设置其他属性时，可以引用它们，比如${random.long})
6. 应用程序以外的application.properties或application.yml文件
7. 打包在应用程序内的application.properties或application.yml文件
8. 通过@PropertySource标注的属性源
9. 默认属性

这个列表按照优先级排序。任何在高优先级属性源里设置的属性都会覆盖低优先级的相同属性。

application.properties或application.yml文件能放在一下四个文件夹中：

1. 外置，在相对于应用程序运行目录的/config子目录里
2. 外置，在应用程序的运行目录
3. 内置，在config包中
4. 内置，在Classpath根目录

这个列表也是按照优先级的。

<font color="red">注意的是：如果在同一优先级位置同时有application.properties或application.yml文件，application.yml文件里的属性会覆盖application.properties里的文件属性</font>

