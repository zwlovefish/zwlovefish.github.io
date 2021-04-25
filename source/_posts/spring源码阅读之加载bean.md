---
title: spring源码阅读之加载bean
date: 2021-03-24 20:10:45
tags: spring源码 加载Bean
categories: spring源码阅读
---

# 思考
spring的2大特性是IOC和AOP，IoC的的作用是将bean的创建与销毁交给spring容器来管理。
那么spring的第一步是需要加载哪些bean呢？一般我们可以通过注解的方式和XML的方式，那么spring是如何识别呢？
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:context="http://www.springframework.org/schema/context" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	   xsi:schemaLocation="
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context.xsd
    http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd">

	<!-- 自动扫描web包 ,将带有注解的类 纳入spring容器管理 -->
	<context:component-scan base-package="com.zhou.beans"></context:component-scan>

	<bean id="a" class="com.zhou.beans.A">
	</bean>
</beans>
```

<!-- more -->
先来看看spring的生命周期
![bean生命周期](bean生命周期.jpeg)
# 准备工作
```java
// main函数中的内容
ApplicationContext ac1 = new ClassPathXmlApplicationContext("application.xml");
A a = ac1.getBean(A.class);
a.say();

// bean
package com.zhou.beans;

import org.springframework.stereotype.Component;

@Component
public class A {
	public A(){
		System.out.println("a constructor");
	}
	public void say() {
		System.out.println("hello world");
	}
}
```
由代码可知第一行就完成了所有的工作，下面就分析一下第一行代码做了哪些工作，以ClassPathXmlApplicationContext为例子
![AbstractApplicationContext](AbstractApplicationContext.png)
```java
public ClassPathXmlApplicationContext(
			String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
			throws BeansException {

		super(parent);
		setConfigLocations(configLocations);
		if (refresh) {
			refresh();
		}
	}

// org.springframework.context.support.AbstractRefreshableConfigApplicationContext#setConfigLocations
public void setConfigLocations(@Nullable String... locations) {
    if (locations != null) {
        Assert.noNullElements(locations, "Config locations must not be null");
        this.configLocations = new String[locations.length];
        for (int i = 0; i < locations.length; i++) {
            // 这里是用来解析locations的，因为locations是一个string类型的，可以使用占位符来运行时替换，所以需要解析一下，可以不用纠结
            // 这里执行完以后就是this.configLocations中的就是 ["application.xml"]
            this.configLocations[i] = resolvePath(locations[i]).trim(); 
        }
    }
    else {
        this.configLocations = null;
    }
}

// 接着就是经典的refresh()函数了,这是解析bean的经典，一共14个函数
// org.springframework.context.support.AbstractApplicationContext#refresh
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // Prepare this context for refreshing.
        prepareRefresh();
        // Tell the subclass to refresh the internal bean factory.
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
        // Prepare the bean factory for use in this context.
        prepareBeanFactory(beanFactory);
        try {
            // Allows post-processing of the bean factory in context subclasses.
            postProcessBeanFactory(beanFactory);
            // Invoke factory processors registered as beans in the context.
            invokeBeanFactoryPostProcessors(beanFactory);
            // Register bean processors that intercept bean creation.
            registerBeanPostProcessors(beanFactory);
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
        }
    }
}
```

# 详细阅读refresh
## prepareRefresh
prepareRefresh主要做了以下几件事：
1. 标识当前context环境close为false
2. 标识当前context环境active为true
3. 初始化context环境中的占位符属性${} <font color="red">默认没有处理</font>
4. 设置ApplicationListener，没有就新建，有的话删除老的，在添加新的
``` java
protected void prepareRefresh() {
    // Switch to active.
    this.startupDate = System.currentTimeMillis();
    // 原子boolean值，用来标识该context没有被关闭
    this.closed.set(false); 
    // 原子boolean值，用来标识该context已经激活了
    this.active.set(true);

    if (logger.isDebugEnabled()) {
        if (logger.isTraceEnabled()) {
            logger.trace("Refreshing " + this);
        }
        else {
            logger.debug("Refreshing " + getDisplayName());
        }
    }

    // 初始化context环境中的占位符属性${}
    initPropertySources();

    // Validate that all properties marked as required are resolvable:
    // see ConfigurablePropertyResolver#setRequiredProperties
    getEnvironment().validateRequiredProperties();

    // Store pre-refresh ApplicationListeners...
    if (this.earlyApplicationListeners == null) {
        this.earlyApplicationListeners = new LinkedHashSet<>(this.applicationListeners);
    }
    else {
        // Reset local application listeners to pre-refresh state.
        this.applicationListeners.clear();
        this.applicationListeners.addAll(this.earlyApplicationListeners);
    }

    // Allow for the collection of early ApplicationEvents,
    // to be published once the multicaster is available...
    this.earlyApplicationEvents = new LinkedHashSet<>();
}
```

## obtainFreshBeanFactory
获取beanFactory的时候就已经解析出我们自己写的bean的名字了。另外在阅读源码的时候发现只有2中方式来加载bean，一种是getConfigResources，另一种是getConfigLocations。
```java
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
    refreshBeanFactory();
    return getBeanFactory();
}

// 此实现实现了一个真正的当前context的refresh操作
// 关闭之前的bean factory，并为context的下一个阶段初始化一个bean factory
@Override
protected final void refreshBeanFactory() throws BeansException {
    if (hasBeanFactory()) {
        destroyBeans();
        closeBeanFactory();
    }
    try {
        DefaultListableBeanFactory beanFactory = createBeanFactory();
        beanFactory.setSerializationId(getId());
        customizeBeanFactory(beanFactory);
        loadBeanDefinitions(beanFactory);
        this.beanFactory = beanFactory;
    }
    catch (IOException ex) {
        throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
    }
}

// 这个函数加载了我们自己创建的Bean A
@Override
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
    // Create a new XmlBeanDefinitionReader for the given BeanFactory.
    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

    // Configure the bean definition reader with this context's
    // resource loading environment.
    beanDefinitionReader.setEnvironment(this.getEnvironment());
    beanDefinitionReader.setResourceLoader(this);
    beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));

    // Allow a subclass to provide custom initialization of the reader,
    // then proceed with actually loading the bean definitions.
    initBeanDefinitionReader(beanDefinitionReader);
    loadBeanDefinitions(beanDefinitionReader);
}

// 有2中方式来加载bean，一种是通过getConfig(注解)，一种是Resources的方式
protected void loadBeanDefinitions(XmlBeanDefinitionReader reader) throws BeansException, IOException {
    Resource[] configResources = getConfigResources();
    if (configResources != null) {
        reader.loadBeanDefinitions(configResources);
    }
    String[] configLocations = getConfigLocations();
    if (configLocations != null) {
        reader.loadBeanDefinitions(configLocations);
    }
}

// 这里就是解析xml的地方，找到了，给自己加个鸡腿
@Override
public int loadBeanDefinitions(String... locations) throws BeanDefinitionStoreException {
    Assert.notNull(locations, "Location array must not be null");
    int count = 0;
    for (String location : locations) {
        count += loadBeanDefinitions(location);  // loadBeanDefinitions =====> loadBeanDefinitions(location, null);
    }
    return count;
}

//真正解析的地方，从注释上来看，location可以是一个具体的位置，也可以是一个位置模式，如果是位置模式的话，这个 bean definition reader的资源加载器必须是ResourcePatternResolver
public int loadBeanDefinitions(String location, @Nullable Set<Resource> actualResources) throws BeanDefinitionStoreException {
    ResourceLoader resourceLoader = getResourceLoader();
    if (resourceLoader == null) {
        throw new BeanDefinitionStoreException(
                "Cannot load bean definitions from location [" + location + "]: no ResourceLoader available");
    }

    if (resourceLoader instanceof ResourcePatternResolver) {
        // 没有使用绝对路径，走的是这里的分支
        // Resource pattern matching available.
        try {
            Resource[] resources = ((ResourcePatternResolver) resourceLoader).getResources(location);
            int count = loadBeanDefinitions(resources);
            if (actualResources != null) {
                Collections.addAll(actualResources, resources);
            }
            if (logger.isTraceEnabled()) {
                logger.trace("Loaded " + count + " bean definitions from location pattern [" + location + "]");
            }
            return count;
        }
        catch (IOException ex) {
            throw new BeanDefinitionStoreException(
                    "Could not resolve bean definition resource pattern [" + location + "]", ex);
        }
    }
    else {
        // Can only load single resources by absolute URL.
        Resource resource = resourceLoader.getResource(location);
        int count = loadBeanDefinitions(resource);
        if (actualResources != null) {
            actualResources.add(resource);
        }
        if (logger.isTraceEnabled()) {
            logger.trace("Loaded " + count + " bean definitions from location [" + location + "]");
        }
        return count;
    }
}

// 在这个loadBeanDefinitions中，将application.xml包装秤一个document来进行解析的
@Override
public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
    Assert.notNull(resources, "Resource array must not be null");
    int count = 0;
    for (Resource resource : resources) {
        count += loadBeanDefinitions(resource);
    }
    return count;
}

public int loadBeanDefinitions(EncodedResource encodedResource) throws BeanDefinitionStoreException {
    Assert.notNull(encodedResource, "EncodedResource must not be null");
    if (logger.isTraceEnabled()) {
        logger.trace("Loading XML bean definitions from " + encodedResource);
    }

    Set<EncodedResource> currentResources = this.resourcesCurrentlyBeingLoaded.get();

    if (!currentResources.add(encodedResource)) {
        throw new BeanDefinitionStoreException(
                "Detected cyclic loading of " + encodedResource + " - check your import definitions!");
    }

    try (InputStream inputStream = encodedResource.getResource().getInputStream()) {
        InputSource inputSource = new InputSource(inputStream);
        if (encodedResource.getEncoding() != null) {
            inputSource.setEncoding(encodedResource.getEncoding());
        }
        return doLoadBeanDefinitions(inputSource, encodedResource.getResource());
    }
    catch (IOException ex) {
        throw new BeanDefinitionStoreException(
                "IOException parsing XML document from " + encodedResource.getResource(), ex);
    }
    finally {
        currentResources.remove(encodedResource);
        if (currentResources.isEmpty()) {
            this.resourcesCurrentlyBeingLoaded.remove();
        }
    }
}
// org.springframework.beans.factory.xml.XmlBeanDefinitionReader进行具体的解析了
// 另外每个在xml中定义的结构，在org.springframework.beans.factory.xml.DefaultBeanDefinitionDocumentReader中
protected void doRegisterBeanDefinitions(Element root) {
    // Any nested <beans> elements will cause recursion in this method. In
    // order to propagate and preserve <beans> default-* attributes correctly,
    // keep track of the current (parent) delegate, which may be null. Create
    // the new (child) delegate with a reference to the parent for fallback purposes,
    // then ultimately reset this.delegate back to its original (parent) reference.
    // this behavior emulates a stack of delegates without actually necessitating one.
    BeanDefinitionParserDelegate parent = this.delegate;
    this.delegate = createDelegate(getReaderContext(), root, parent);

    if (this.delegate.isDefaultNamespace(root)) {
        String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
        if (StringUtils.hasText(profileSpec)) {
            String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
                    profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
            // We cannot use Profiles.of(...) since profile expressions are not supported
            // in XML config. See SPR-12458 for details.
            if (!getReaderContext().getEnvironment().acceptsProfiles(specifiedProfiles)) {
                if (logger.isDebugEnabled()) {
                    logger.debug("Skipped XML bean definition file due to specified profiles [" + profileSpec +
                            "] not matching: " + getReaderContext().getResource());
                }
                return;
            }
        }
    }

    preProcessXml(root);
    parseBeanDefinitions(root, this.delegate);
    postProcessXml(root);

    this.delegate = parent;
}
```
beanFactory中成功解析到我们所需要的bean了
![beanFactory](beanFactory.jpg)

## prepareBeanFactory
在prepareBeanFactory中设置一些属性
```java
beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

// 然后设置environment、systemProperties、systemEnvironment到bean中
```

## postProcessBeanFactory
在标准初始化之后，用来修改应用程序上下文的内部Bean工厂。所有bean定义都将被加载，但尚未实例化任何bean。这允许在某些ApplicationContext实现中注册特殊的BeanPostProcessor等。

## invokeBeanFactoryPostProcessors
Instantiate(实例化) and invoke all registered <font color="red">BeanFactoryPostProcessor</font> beans，respecting explicit order if given.
实例化并调用所有注册的<font color= "red">BeanFactoryPostProcessor</font> beans，如果有顺序的话，按照明确的顺序来

## registerBeanPostProcessors
Instantiate and register all <font color="red">BeanPostProcessor</font> beans, respecting explicit order if given.
实例化并调用所有注册的<font color="red">BeanPostProcessor</font> beans，如果有顺序的话，按照明确的顺序来

## initMessageSource
如果beanFactory中含有messageSource， 使用HierarchicalMessageSource作为MessageSource，否则使用DelegatingMessageSource作为MessageSource

## initApplicationEventMulticaster
如果beanFactory中含有applicationEventMulticaster，使用ApplicationEventMulticaster， 否则使用SimpleApplicationEventMulticaster

## onRefresh
可以重写的模板方法以添加特定于上下文的刷新工作

## registerListeners
Add beans that implement ApplicationListener as listeners. Doesn't affect other listeners, which can be added without being beans.
添加实现了ApplicationListener的bean，不会影响其他的listeners
有一个特殊的地方就是
```java
protected void registerListeners() {
    // Register statically specified listeners first.
    for (ApplicationListener<?> listener : getApplicationListeners()) {
        getApplicationEventMulticaster().addApplicationListener(listener);
    }

    // Do not initialize FactoryBeans here: We need to leave all regular beans
    // uninitialized to let post-processors apply to them!
    String[] listenerBeanNames = getBeanNamesForType(ApplicationListener.class, true, false);
    for (String listenerBeanName : listenerBeanNames) {
        getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
    }

    // 处理之后会将this.earlyApplicationEvents置为null
    Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
    this.earlyApplicationEvents = null;
    if (!CollectionUtils.isEmpty(earlyEventsToProcess)) {
        for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
            getApplicationEventMulticaster().multicastEvent(earlyEvent);
        }
    }
}

// 可以通过application.setApplicationListeners来增加自己的listener
public Collection<ApplicationListener<?>> getApplicationListeners() {
    return this.applicationListeners;
}
```

## finishRefresh
```java
protected void finishRefresh() {
    // Clear context-level resource caches (such as ASM metadata from scanning).
    clearResourceCaches();

    // Initialize lifecycle processor for this context.
    // 如果beanFactory中包含有lifecycleProcessor，则使用该lifecycleProcessor，如果没有则使用DefaultLifecycleProcessor
    initLifecycleProcessor();


    // Propagate refresh to lifecycle processor first.
    // 调用上个函数获取到的lifecycleProcessor中的onRefresh()方法
    getLifecycleProcessor().onRefresh();

    // Publish the final event.
    publishEvent(new ContextRefreshedEvent(this));

    // Participate in LiveBeansView MBean, if active.
    // 在LiveBeansView设置当前ApplicationContext
    LiveBeansView.registerApplicationContext(this);


}
```

## resetCommonCaches清空数据
```java
protected void resetCommonCaches() {
    ReflectionUtils.clearCache();
    AnnotationUtils.clearCache();
    ResolvableType.clearCache();
    CachedIntrospectionResults.clearClassLoader(getClassLoader());
}
```