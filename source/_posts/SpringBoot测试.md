---
title: SpringBoot测试
date: 2020-05-25 14:14:41
tags: SpringBoot单元测试
categories: SpringBoot
---
在编写应用程序时，明确目标的最佳方法就是写测试，确定应用程序的行为是否符合预期。究竟是在编写业务代码之前还是之后写测试，这并不重要。重要的是，写测试不仅仅是为了验证代码的准确性，还要确认它符合预期。测试也是一道保障，确认应用程序在改进的同时不会破坏已有的东西。

测试是开发高质量软件的重要一环。没有好的测试，你永远无法保证应用程序能像期望的那样运行。

单元测试专注于单一组件或组件中的一个方法，此处并不一定要使用Spring。Spring提供了一些优势和技术——松耦合、依赖注入和接口驱动设计。这些都简化了单元测试的编写。但Spring不用直接涉足单元测试。

集成测试会涉及众多组件，这时就需要Spring帮忙了。实际上，如果Spring在运行时负责拼装那些组件，那么Spring在集成测试里同样应该肩负这一职责。Spring Framework以JUnit类运行器的方式提供了集成测试支持，JUnit类运行器会加载Spring应用程序上下文，把上下文里的Bean注入测试。SpringBoot在Spring的集成测试之上又增加了配置加载器，以SpringBoot的方式加载应用程序上下文，包括了对外置属性的支持和SpringBoot日志。SpringBoot还支持容器内测试Web应用程序，让你能用和生产环境一样的容器启动应用程序。这样一来，测试在验证应用程序行为的时候，会更加接近真实的运行环境。
<!-- more -->

在编写单元测试的时候，Spring通常不需要介入。Spring鼓励松耦合、接口驱动的设计，这些都能让你很轻松地编写单元测试。但是在写单元测试时并不需要用到Spring。集成测试需要用到Spring。如果生产应用程序使用Spring来配置并组装组件，那么测试就需要 用它来配置并组装那些组件。

Spring的SpringJUnit4ClassRunner可以在基于JUnit的应用程序测试里加载Spring应用程序上下文。在测试SpringBoot应用程序时，SpringBoot除了拥有Spring的集成测试支持，还开启了自动配置和Web服务器，并提供了不少实用的测试辅助工具。

Spring Framework的核心工作是将所有组件编织在一起，构成一个应用程序。整个过程就是读取配置说明(可以是XML、基于Java的配置、基于Groovy的配置或其他类型的配置)，在应用程序上下文里初始化Bean，将Bean注入依赖它们的其他Bean中。

对Spring应用程序进行集成测试时，让Spring遵照生产环境来组装测试目标Bean是非常重要的一点。Spring自1.1.1版就向集成测试提供了极佳的支持。自Spring2.5开始，集成测试支持的形式就编程了SpringJUnit4ClassRunner。这是一个JUnit类运行器，会为JUnit测试加载Spring应用程序上下文，并未测试类自动织入所需的Bean。

# 测试Web应用程序
SpringMVC有一个优点：它的编程模型是围绕POJO展开的，在POJO上添加注解，声明如何处理Web请求。这种编程模型不仅简单，还让你能像对待应用程序中的其他组件一样对待这些控制器。你还可以针对这些控制器编写测试，就像POJO一样。

要恰当的测试一个Web应用程序，你需要投入一些实际的HTTP请求，确认它能正确地处理那些请求。幸运的是，SpringBoot开发者有俩个可选的方案能实现这类测试

1. Spring Mock MVC：能在一个近似真实的模拟Servlet容器里测试控制器，而不用实际启动应用服务器。
2. Web集成测试：在嵌入式Servlet容器(比如Tomcat或Jetty)里启动应用程序，在真正的应用服务器里执行测试。

<font color="red">这俩种方法各有利弊。启动一个应用服务器会比模拟Servlet容器要慢一点，但毫无疑问基于服务器的测试会更接近真实环境，更接近部署到生产环境运行的情况。</font>

## 模拟Spring MVC
Spring的Mock MVC框架模拟了Spring MVC的很多功能。它几乎和运行在Servlet容器里的应用程序一样，尽管实际情况并非如此。要在测试里设置Mock MVC，可以使用MockMvcBuilders，该类提供了俩个静态方法。

- standaloneSetup()：构建一个Mock MVC，提供一个或多个手工创建并配置的控制器。
- webAppContextSetup()：使用Spring应用程序上下文来构建Mock MVC，该上下文里可以包含一个或多个配置好的控制器。

俩者的主要区别在于，standaloneSetup()希望你手工初始化并注入你要测试的控制器，而webAppContextSetup()则基于一个WebApplicationContext的实例，通常由Spring加载。前者同单元测试更加接近，你可能只想让它专注于单一控制器的测试，而后者让Spring加载控制器及其依赖，以便进行完整的集成测试。

## 测试运行中的应用程序
在测试类上添加@WebIntegrationTest注解，可以声明你不仅希望SpringBoot为测试创建应用程序上下文，还要启动一个嵌入式的Servlet容器。一旦应用程序运行在嵌入式容器里，你就可以发起真实的HTTP请求，断言结果了。
## 用随机端口启动服务器
让SpringBoot在随机选择的端口上启动服务器很方便。

一种方法是将server.port属性设置为0，让SpringBoot选择一个随机的可用端口。@WebIntegrationTest的value属性接受一个String数组，数组中的每项都是键值对，形如name=value，用来设置测试中使用的属性。要设置server.port，你可以这样做：@WebIntegrationTest(value={"server.port=0"}),另外，因为只要设置一个属性，所以还能有更简单的形式@WebIntegrationTest("server.port=0")

通过value属性来设置属性通常还算方便。但@WebIntegrationTest还提供了一个randomPort属性 ，更明确地表示让服务器在随机端口上启动。你可以将randomPort设置为true，启用随机端口。@WebIntegrationTest(randomPort = true)

既然我呢在随机端口上启动了服务器，就需要在发起Web请求时确保使用正确的端口。此时getForObject()方法在URL里硬编码了8080端口.如果端口是随机选择的,那在构造请求时又该怎么确定正确的端口呢?

首先,我们需要以实例变量的形式注入选中的端口。为了方便，SpringBoot将local.server.port的值设置为了选中的端口。我们只需要使用Spring的@Value注解将其注入即可：
```JAVA
@Value("${local.server.port}")
private int port;
```
有了端口之后，只需对getForObject()稍作修改，使用这个port就好了：
```java
rest.getForObject("http://localhost:{port}/bogusPage",String.class,port);//这里的rest是RestTemplate rest = new RestTemplate
```
这里我们在URL里把硬编码的8080改为{port}占位符。在getForObject()调用里把port属性作为最后一个参数传入，就能确保该占位符被替换为注入的port的值了。
