---
title: Context的refresh
date: 2023-11-08 11:32:22
tags: SpringBoot启动流程
categories: SpringBoot
---
主要阅读分析SpringBoot的启动主流程中refreshContext(context)：
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
```
<!--more-->

这里因为webApplicationType以及从spring.factories中创建的是AnnotationConfigServletWebServerApplicationContext。

在具体分析前先看一下AnnotationConfigServletWebServerApplicationContext的类图
![AnnotationConfigServletWebServerApplicationContext继承关系图](AnnotationConfigServletWebServerApplicationContext继承关系图.png)

因为AnnotationConfigServletWebServerApplicationContext继承自ServletWebServerApplicationContext，所以调用的是ServletWebServerApplicationContext中的refresh方法：
该context的refresh方法如下：
```java
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
这个super.fresh()最终调用的方法是AbstractApplicationContext中的refresh方法。
```java
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        StartupStep contextRefresh = this.applicationStartup.start("spring.context.refresh");

        // Prepare this context for refreshing.
        prepareRefresh();

        // Tell the subclass to refresh the internal bean factory.
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // Prepare the bean factory for use in this context.
        prepareBeanFactory(beanFactory);

        try {
            // Allows post-processing of the bean factory in context subclasses.
            postProcessBeanFactory(beanFactory);

            StartupStep beanPostProcess = this.applicationStartup.start("spring.context.beans.post-process");
            // Invoke factory processors registered as beans in the context.
            invokeBeanFactoryPostProcessors(beanFactory);

            // Register bean processors that intercept bean creation.
            registerBeanPostProcessors(beanFactory);
            beanPostProcess.end();

            // Initialize message source for this context.
            initMessageSource();

            // Initialize event multicaster for this context.
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
            onRefresh();

            // Check for listener beans and register them.
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
            finishRefresh();
        }

        catch (BeansException ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Exception encountered during context initialization - " +
                        "cancelling refresh attempt: " + ex);
            }

            // Destroy already created singletons to avoid dangling resources.
            destroyBeans();

            // Reset 'active' flag.
            cancelRefresh(ex);

            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
            contextRefresh.end();
        }
    }
}
```
# prepareRefresh()
这里设置启动的时间，设置状态标记位，初始化属性源、earlyApplicationListeners和applicationListeners
```java
// 这里首先调用的是AnnotationConfigServletWebServerApplicationContext，清除scanner的缓存，在调用super.prepareRefresh
protected void prepareRefresh() {
    this.scanner.clearCache();
    super.prepareRefresh();
}

// 这里是AbstractApplicationContext中的prepareRefresh方法

// 设置容器启动的时间
this.startupDate = System.currentTimeMillis();
// 容器的关闭标志位
this.closed.set(false);
// 容器的激活标志位
this.active.set(true);

// initPropertySources方法符合Spring的开放式结构设计，给用户增加扩展Spring的能力。
// 用户可以根据自身的需要重写initPropertySourece方法，并在方法中进行个性化设计及其业务处理。
initPropertySources();
// 这里调用的是GenericWebApplicationContext中的initPropertySources方法
protected void initPropertySources() {
    ConfigurableEnvironment env = getEnvironment();
    if (env instanceof ConfigurableWebEnvironment configurableWebEnv) {
        configurableWebEnv.initPropertySources(this.servletContext, null);
    }
}

// 1、检查是否存在环境变量如果存在直接用,不存在重更新获取
// 2、创建并获取环境对象、验证需要的属性文件是否符合
getEnvironment().validateRequiredProperties();

// 判断刷新前的应用程序监听器集合是否为空，如果为空，则将监听器添加到此集合中
if (this.earlyApplicationListeners == null) {
    this.earlyApplicationListeners = new LinkedHashSet<>(this.applicationListeners);
} else {
    this.applicationListeners.clear();
    this.applicationListeners.addAll(this.earlyApplicationListeners);
}
this.earlyApplicationEvents = new LinkedHashSet<>();
```
上处initPropertySources是spring提供的一个扩展的能力，例如：
```java
public class MyClassPathXmlApplicationContext extends ClassPathXmlApplicationContext {


    public MyClassPathXmlApplicationContext(String... configLocations){
        super(configLocations);
    }

    @Override
    protected void initPropertySources() {
        System.out.println("扩展initPropertySource");
        //这里添加了一个name属性到Environment里面，以方便我们在后面用到
        getEnvironment().getSystemProperties().put("name","bobo");
        //这里要求Environment中必须包含username属性，如果不包含，则抛出异常
        getEnvironment().setRequiredProperties("username");
    }
}
```
# obtainFreshBeanFactory()
```java
ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
    refreshBeanFactory();
    return getBeanFactory();
}
```
## refreshBeanFactory
refreshBeanFactory在AbstractApplicationContext中是一个抽象方法，具体的是其子类GenericApplicationContext实现，且不让GenericApplicationContext的子类重写

而AnnotationConfigServletWebServerApplicationContext继承了GenericApplicationContext，因此调用的是GenericApplicationContext中的refreshBeanFactory方法
```java
protected final void refreshBeanFactory() throws IllegalStateException {
    if (!this.refreshed.compareAndSet(false, true)) {
        throw new IllegalStateException(
                "GenericApplicationContext does not support multiple refresh attempts: just call 'refresh' once");
    }
    this.beanFactory.setSerializationId(getId());
}
```
## getBeanFactory
getBeanFactory在AbstractApplicationContext中是一个抽象方法，具体的是其子类GenericApplicationContext实现，且不让GenericApplicationContext的子类重写
而AnnotationConfigServletWebServerApplicationContext继承了GenericApplicationContext，因此调用的是GenericApplicationContext中的getBeanFactory方法
```java
public final ConfigurableListableBeanFactory getBeanFactory() {
    return this.beanFactory;
}
```
有个Java的基础值得一提：假如有3个类，class TestA, class TestB, class TestC,其中，c继承b，b继承a，在执行TestC c = new TestC时，会依次执行a的构造器，b的构造器以及c的构造器。
在创建AnnotationConfigServletWebServerApplicationContext时，会依次执行其父类的构造器，其中GenericApplicationContext会初始化一个beanFactory。
```java
public GenericApplicationContext() {
    this.beanFactory = new DefaultListableBeanFactory();
}
```
因此这里获取的beanFactory是DefaultListableBeanFactory
# prepareBeanFactory(beanFactory)
```java
prepareBeanFactory(beanFactory);

protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    // 设置bean的类加载器
    beanFactory.setBeanClassLoader(getClassLoader());
    // 设置支持表达式解析器
    beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
    beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));

    // 添加部分addBeanPostProcessor
    beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
    // 设置忽略的自动装配的接口，因为在ApplicationContextAwareProcessor#invokeAwareInterfaces已经把这7个接口的实现工作做了
    beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
    beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
    beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
    beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationStartupAware.class);

    // 注册可以解析的自动装配，我们能直接在任何组件中自动注入，其他组件可以通过@Autowired直接注册使用
    beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
    beanFactory.registerResolvableDependency(ResourceLoader.class, this);
    beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
    beanFactory.registerResolvableDependency(ApplicationContext.class, this);

    // 添加部分addBeanPostProcessor
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

    // Detect a LoadTimeWeaver and prepare for weaving, if found.
    if (!NativeDetector.inNativeImage() && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        // Set a temporary ClassLoader for type matching.
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }

    // 注册一些环境bean
    if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
    }
    if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
    }
    if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
    }
    if (!beanFactory.containsLocalBean(APPLICATION_STARTUP_BEAN_NAME)) {
        beanFactory.registerSingleton(APPLICATION_STARTUP_BEAN_NAME, getApplicationStartup());
    }
}
```
# postProcessBeanFactory(beanFactory)
从类图中可以看出，AnnotationConfigServletWebServerApplicationContext、ServletWebServerApplicationContext、GenericWebApplicationContext以及AbstractApplicationContext都实现了postProcessBeanFactory方法，也就是说不同的context实现了不同的postProcessBeanFactory

本文以AnnotationConfigServletWebServerApplicationContext为例：
```java
// ServletWebServerApplicationContext中
protected void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    // 添加beanFactory的后置处理器
    beanFactory.addBeanPostProcessor(new WebApplicationContextServletContextAwareProcessor(this));、
    // 设置忽略的自动装配的接口
    beanFactory.ignoreDependencyInterface(ServletContextAware.class);
    // 注册WebApplicationScopes
    registerWebApplicationScopes();
}
// AnnotationConfigServletWebServerApplicationContext中
protected void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    super.postProcessBeanFactory(beanFactory);
    if (this.basePackages != null && this.basePackages.length > 0) {
        this.scanner.scan(this.basePackages);
    }
    if (!this.annotatedClasses.isEmpty()) {
        this.reader.register(ClassUtils.toClassArray(this.annotatedClasses));
    }
}
```
有个Java的基础值得一提：假如有3个类，class TestA, class TestB, class TestC,其中，c继承b，b继承a，3个都实现了hello的方法，在c中的hello方法中<font color="red">首先</font>调用super.hello()，执行c的hello方法时，最后先执行b中的hello，在执行c中的hello。
# invokeBeanFactoryPostProcessors(beanFactory);
```java
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());

    // Detect a LoadTimeWeaver and prepare for weaving, if found in the meantime
    // (e.g. through an @Bean method registered by ConfigurationClassPostProcessor)
    if (!NativeDetector.inNativeImage() && beanFactory.getTempClassLoader() == null &&
            beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
}
```