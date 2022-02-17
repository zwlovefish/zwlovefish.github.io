---
title: Sprigboot使用探秘
date: 2020-05-17 13:01:26
tags: 初始化SpringBoot项目
categories: SpringBoot
---

通过SpringBoot的起步依赖和自动配置,可以更加快速、便捷的开发Spring应用程序。起步依赖帮助你专注于应用程序需要的功能类型，而非提供该功能的具体库和版本。与此同时，自动配置把你从样板式的配置中解放了出来。这些配置在SpringBoot的Spring应用程序里非常常见。

利用Spring Initializr创建的项目，其结构遵循传统maven或Gradle项目的布局。下面是SpringBoot的项目结构
<!-- more -->
![SpringBoot项目结构](项目结构.png)
# 启动引导Spring
![ReadingApplication](ReadinglistApplication.png)
ReadingListApplication在SpringBoot应用程序里有俩个作用：配置和启动引导。

@SpringBootApplication开启了Spring的组件扫描和SpringBoot的自动配置功能。实际上，@SpringBootApplication将三个有用的注解组合在了一起：

- Spring的@Configuration：标明该类使用Spring基于Java的配置。
- Spring的@ComponentScan：启用组件扫描，这样写的Web控制器类和其他组件才能被自动发现并注册为Spring应用程序上下文里的Bean。
- SpringBoot的@EnableAutoConfiguration：这一行配置开启了SpringBoot自动配置的魔力。

# 测试SpringBoot应用程序
![ReadingApplicationTests](ReadinglistApplicationTests.png)
Initializr还提供了一个测试类的骨架，可以基于它为你的应用程序编写测试。但ReadingListApplicationTests不止是个用于测试的占位符，他还是一个例子，告诉你如何为SpringBoot应用程序编写测试。

一个典型的Spring集成测试会使用@ContextConfiguration注解标识如何加载Spring的应用程序上下文。但是，为了充分发挥SpringBoot的魔力，这里使用@SpringApplicationnConfiguration注解.ReadinglistApplicationTests使用@SpringApplicationConfiguration注解从ReadingListApplicationn配置类里加载Spring应用程序上下文。

ReadingListApplicationTests里还有一个简单的测试方法，即contextLoads()。实际上它就是一个孔方法，但是它足以证明应用程序上下文加载没有问题。

# 配置应用程序属性
Initializr生成的application.properties文件是一个空文件。该文件可以很方便的帮你细粒度的调整SpringBoot的自动配置。你还可以用他来指定应用程序代码所需的配置项。另外，你可以不用告诉SpringBoot为你加载application.properties，只要它存在就会被加载。

# SpringBoot加载配置
在向应用程序加入SpringBoot时，有个名为spring-boot-autoconfigure的JAR文件，其中包含了很多配置类。每个配置类都在应用程序需的Classpath里。这些配置类里有用于Thymeleaf的配置，有用于Spring Data JPA的配置，有用于Spring MVC的配置，还有很多其他东西的配置。

SpringBoot定义了很多更有趣的条件，并把它们运用到了配置类上，<font color="red">这些配置类构成了SpringBoot的自动配置。SpringBoot运用条件化配置的方法是，定义多个特殊的条件化注解，并将他们用到配置类上。</font>
![自动配置中使用的条件化注解](自动配置中使用的条件化注解.png)

以H2为例，SpringBoot自动配置会做出以下配置决策：

1. 因为Classpath里有H2，所以会常见一个嵌入式的H2数据库Bean，它的类型是javax.sql.DataSource，JPA实现(Hibernate)需要它来访问数据库。
2. 因为Classpath里有Hibernate(Spring Data JPA传递引用的)的实体管理器，所以自动配置会配置与Hibernate相关的Bean，包括Spring的LocalContainerEntityManagerFactoryBean和JpaVendorAdapter。
3. 因为Classpath里有Spring Data JPA，所以它会自动配置为根据仓库的接口创建仓库实现。
4. 因为Classpath里有Thymeleaf，所以Thymeleaf会配置为Spring MVC的视图，包括一个Thymeleaf的模板解析器、模板引擎及视图解析器。视图解析器会解析相对于Classpath根目录的/templates目录里的模板。
5. 因为Classpath里有Spring MVC(归功于Web起步依赖)，所以会配置Spring的DispatcherServlet并请用Spring MVC。
6. 因为这是一个Spring MVC Web应用程序，所以会注册一个资源处理器，把相对于Classpath根目录的/static目录里的静态内容提供出来(这个资源处理器还能处理/public、/resources和/META-INF/resources的静态内容)。
7. 因为Classpath里有Tomcat(通过Web起步依赖传递引用)，所以会启动一个嵌入式的Tomcat容器，监听8080端口。

由此可见，SpringBoot自动配置承担起了配置Spring的重任，因此你能专注于编写自己的应用程序。

# 注意
## 1. Spring Security跨站防护
![POSTT403](POSTT403.png)
由于第四版中springboot版本较低，没有出现post 403的问题。新版本springBoot中Spring Security的CRSF默认是开启的。所以会出现post 403请求错误的问题。

解决方法如下：
在采用Thymeleaf的情况下：在form表单中，\<form method="POST" th:action="@{|/readingList|}"\>

## 2. 在启动SpringBoot时，由于Spring Security会有登录操作
账号：user

密码：在idea的控制台中会生成密码
