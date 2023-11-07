---
title: SpringBoot学习
date: 2023-11-07 15:24:29
tags: SpringBoot
---

# 应用程序入口
```java
SpringApplication.run(DrawingBedOSSApplication.class, args);
```
# run函数流程
public ConfigurableApplicationContext run(String... args);

<!--more-->
## 创建createBootstrapContext
```java
DefaultBootstrapContext bootstrapContext = createBootstrapContext();

// 这里会执行一次实现了BootstrapRegistryInitializer接口的方法
private DefaultBootstrapContext createBootstrapContext() {
    DefaultBootstrapContext bootstrapContext = new DefaultBootstrapContext();
    this.bootstrapRegistryInitializers.forEach((initializer) -> initializer.initialize(bootstrapContext));
    return bootstrapContext;
}
```

## 配置java.awt.headless属性为TRUE
```java
configureHeadlessProperty();
```
## 获取SpringApplicationRunListener
作用：用来在整个启动流程中接受不同执行点事件通知的监听者，SpringApplicationRunListener接口规定了SpringBoot的生命周期，在各个生命周期广播相应的事件，调用实际的ApplicationListener类
```java
SpringApplicationRunListeners listeners = getRunListeners(args);

private SpringApplicationRunListeners getRunListeners(String[] args) {
    ArgumentResolver argumentResolver = ArgumentResolver.of(SpringApplication.class, this);
    argumentResolver = argumentResolver.and(String[].class, args);
    // 利用spring的spi机制从spring.factories中获取所有的SpringApplicationRunListener
    List<SpringApplicationRunListener> listeners = getSpringFactoriesInstances(SpringApplicationRunListener.class,argumentResolver);
    SpringApplicationHook hook = applicationHook.get();
    SpringApplicationRunListener hookListener = (hook != null) ? hook.getRunListener(this) : null;
    if (hookListener != null) {
        listeners = new ArrayList<>(listeners);
        listeners.add(hookListener);
    }
    return new SpringApplicationRunListeners(logger, listeners, this.applicationStartup);
}
```
## 将args包装成ApplicationArguments
```java
ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
```
## 创建environment
```java
ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);

private ConfigurableEnvironment prepareEnvironment(SpringApplicationRunListeners listeners,
        DefaultBootstrapContext bootstrapContext, ApplicationArguments applicationArguments) {
    // Create and configure the environment
    ConfigurableEnvironment environment = getOrCreateEnvironment();
    configureEnvironment(environment, applicationArguments.getSourceArgs());
    ConfigurationPropertySources.attach(environment);
    listeners.environmentPrepared(bootstrapContext, environment);
    DefaultPropertiesPropertySource.moveToEnd(environment);
    Assert.state(!environment.containsProperty("spring.main.environment-prefix"), "Environment prefix cannot be set via properties.");
    bindToSpringApplication(environment);
    if (!this.isCustomEnvironment) {
        EnvironmentConverter environmentConverter = new EnvironmentConverter(getClassLoader());
        environment = environmentConverter.convertEnvironmentIfNecessary(environment, deduceEnvironmentClass());
    }
    ConfigurationPropertySources.attach(environment);
    return environment;
}
```
### 调用getOrCreateEnvironment
```java
ConfigurableEnvironment environment = getOrCreateEnvironment();

private ConfigurableEnvironment getOrCreateEnvironment() {
    if (this.environment != null) {
        return this.environment;
    }
    ConfigurableEnvironment environment = this.applicationContextFactory.createEnvironment(this.webApplicationType);
    if (environment == null && this.applicationContextFactory != ApplicationContextFactory.DEFAULT) {
        environment = ApplicationContextFactory.DEFAULT.createEnvironment(this.webApplicationType);
    }
    return (environment != null) ? environment : new ApplicationEnvironment();
}

```
### this.applicationContextFactory来源
```java
// 在SpringApplication中
SpringApplication中applicationContextFactory = ApplicationContextFactory.DEFAULT;
ApplicationContextFactory DEFAULT = new DefaultApplicationContextFactory();
```
### DEFAULT中createEnvironment函数
```java
// DEFAULT中createEnvironment函数是根据Spring的SPI机制从spring.factories中获取ApplicationContextFactory
// 这个ApplicationContextFactory有两个：
// ServletWebServerApplicationContextFactory
// ReactiveWebServerApplicationContextFactory
public ConfigurableEnvironment createEnvironment(WebApplicationType webApplicationType) {
    return getFromSpringFactories(webApplicationType, ApplicationContextFactory::createEnvironment, null);
}
```
### getFromSpringFactories获取environment
```java
// 根据webApplicationType类型是SERVLET返回的是ServletWebServerApplicationContextFactory中的创建环境
private <T> T getFromSpringFactories(WebApplicationType webApplicationType,
        BiFunction<ApplicationContextFactory, WebApplicationType, T> action, Supplier<T> defaultResult) {
    for (ApplicationContextFactory candidate : SpringFactoriesLoader.loadFactories(ApplicationContextFactory.class,
            getClass().getClassLoader())) {
        T result = action.apply(candidate, webApplicationType);
        if (result != null) {
            return result;
        }
    }
    return (defaultResult != null) ? defaultResult.get() : null;
}
```
### apply函数
```java
// 调用的是ServletWebServerApplicationContextFactory中createEnvironment：
public ConfigurableEnvironment createEnvironment(WebApplicationType webApplicationType) {
    return (webApplicationType != WebApplicationType.SERVLET) ? null : new ApplicationServletEnvironment();
}
```

## 打印springboot图标
```java
Banner printedBanner = printBanner(environment);
```
## 创建context
```java
context = createApplicationContext();

protected ConfigurableApplicationContext createApplicationContext() {
    return this.applicationContextFactory.create(this.webApplicationType);
}
```

### this.applicationContextFactory来源
```java
// 在SpringApplication中
SpringApplication中applicationContextFactory = ApplicationContextFactory.DEFAULT;
ApplicationContextFactory DEFAULT = new DefaultApplicationContextFactory();
```
### DEFAULT中create函数
```java
// DEFAULT中create函数是根据Spring的SPI机制从spring.factories中获取ApplicationContextFactory
// 这个找到的ApplicationContextFactory有两个：
// ServletWebServerApplicationContextFactory
// ReactiveWebServerApplicationContextFactory
public ConfigurableApplicationContext create(WebApplicationType webApplicationType) {
    try {
        return getFromSpringFactories(webApplicationType, ApplicationContextFactory::create,
                this::createDefaultApplicationContext);
    }
    catch (Exception ex) {
        throw new IllegalStateException("Unable create a default ApplicationContext instance, "
                + "you may need a custom ApplicationContextFactory", ex);
    }
}
```
### getFromSpringFactories
```java
// 根据webApplicationType类型是SERVLET返回的是在ServletWebServerApplicationContextFactory中创建的context
// 所以这里走的是上文的ApplicationContextFactory::create
// 如果在spi中没有找到ApplicationContextFactory的话，就走this::createDefaultApplicationContext流程
private <T> T getFromSpringFactories(WebApplicationType webApplicationType,
        BiFunction<ApplicationContextFactory, WebApplicationType, T> action, Supplier<T> defaultResult) {
    for (ApplicationContextFactory candidate : SpringFactoriesLoader.loadFactories(ApplicationContextFactory.class,
            getClass().getClassLoader())) {
        T result = action.apply(candidate, webApplicationType);
        if (result != null) {
            return result;
        }
    }
    return (defaultResult != null) ? defaultResult.get() : null;
}
```
### ServletWebServerApplicationContextFactory中的create
```java
public ConfigurableApplicationContext create(WebApplicationType webApplicationType) {
    return (webApplicationType != WebApplicationType.SERVLET) ? null : createContext();
}
// 创建的是AnnotationConfigServletWebServerApplicationContext
private ConfigurableApplicationContext createContext() {
    if (!AotDetector.useGeneratedArtifacts()) {
        // 走的这个分支
        return new AnnotationConfigServletWebServerApplicationContext();
    }
    return new ServletWebServerApplicationContext();
}
```
## 准备context
```java
prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);

private void prepareContext(DefaultBootstrapContext bootstrapContext, ConfigurableApplicationContext context,
			ConfigurableEnvironment environment, SpringApplicationRunListeners listeners,
			ApplicationArguments applicationArguments, Banner printedBanner) {
    context.setEnvironment(environment);
    postProcessApplicationContext(context);
    addAotGeneratedInitializerIfNecessary(this.initializers);
    applyInitializers(context);
    listeners.contextPrepared(context);
    bootstrapContext.close(context);
    if (this.logStartupInfo) {
        logStartupInfo(context.getParent() == null);
        logStartupProfileInfo(context);
    }
    // Add boot specific singleton beans
    ConfigurableListableBeanFactory beanFactory = context.getBeanFactory();
    beanFactory.registerSingleton("springApplicationArguments", applicationArguments);
    if (printedBanner != null) {
        beanFactory.registerSingleton("springBootBanner", printedBanner);
    }
    if (beanFactory instanceof AbstractAutowireCapableBeanFactory autowireCapableBeanFactory) {
        autowireCapableBeanFactory.setAllowCircularReferences(this.allowCircularReferences);
        if (beanFactory instanceof DefaultListableBeanFactory listableBeanFactory) {
            listableBeanFactory.setAllowBeanDefinitionOverriding(this.allowBeanDefinitionOverriding);
        }
    }
    if (this.lazyInitialization) {
        context.addBeanFactoryPostProcessor(new LazyInitializationBeanFactoryPostProcessor());
    }
    context.addBeanFactoryPostProcessor(new PropertySourceOrderingBeanFactoryPostProcessor(context));
    if (!AotDetector.useGeneratedArtifacts()) {
        // Load the sources
        Set<Object> sources = getAllSources();
        Assert.notEmpty(sources, "Sources must not be empty");
        load(context, sources.toArray(new Object[0]));
    }
    listeners.contextLoaded(context);
}
```
这个函数里面主要做了四件事：
1. context.setEnvironment(environment);
2. applyInitializers(context);这里执行实现了ApplicationContextInitializer接口的方法
3. 如果启用了懒加载的话，设置懒加载的beanfactory后置处理器：
context.addBeanFactoryPostProcessor(new LazyInitializationBeanFactoryPostProcessor());
4. 设置BeanFactory的后置处理器：
context.addBeanFactoryPostProcessor(new PropertySourceOrderingBeanFactoryPostProcessor(context));

## refreshContext(context);
```java
private void refreshContext(ConfigurableApplicationContext context) {
    if (this.registerShutdownHook) {
        shutdownHook.registerApplicationContext(context);
    }
    refresh(context);
}
protected void refresh(ConfigurableApplicationContext applicationContext) {
    applicationContext.refresh();
}
/**由上文可知，创建的是AnnotationConfigServletWebServerApplicationContext，
 * 该context继承了ServletWebServerApplicationContext
 * 所以实际执行的是ServletWebServerApplicationContext中的reshresh方法
 */
public final void refresh() throws BeansException, IllegalStateException {
    try {
        super.refresh();
    }
    catch (RuntimeException ex) {
        WebServer webServer = this.webServer;
        if (webServer != null) {
            webServer.stop();
        }
        throw ex;
    }
}
```
## 执行refresh之后的事
```java
afterRefresh(context, applicationArguments);
```
## 调用Runners
```java
callRunners(context, applicationArguments)
// 执行Runners,先执行ApplicationRunner，后执行CommandLineRunner
private void callRunners(ApplicationContext context, ApplicationArguments args) {
    context.getBeanProvider(Runner.class).orderedStream().forEach((runner) -> {
        if (runner instanceof ApplicationRunner applicationRunner) {
            callRunner(applicationRunner, args);
        }
        if (runner instanceof CommandLineRunner commandLineRunner) {
            callRunner(commandLineRunner, args);
        }
    });
}
```
## 返回context

# 结束
因为在run中启动了其他的线程，所以这里的应用程序的主main函数完成了之后，程序并没有停止。