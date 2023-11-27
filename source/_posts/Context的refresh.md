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
    // 在单例bean实例化前，实例化并调用所有注册的BeanFactoryPostProcessor
    // 该方法执行后，DefaultListableBeanFactory中的beanDefinitionMap就拥有了系统中的BeanDefinition
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
## BeanFactoryPostProcessor和BeanDefinitionRegistryPostProcessor
 BeanFactoryPostProcessor:是一个工厂钩子，允许自定义修改BeanDefinition并调整其属性值，BeanFactoryPostProcessor可以与BeanDefinition交互并对其进行修改，但是不能与bean实例进行交互。这样做可能会导致过早实例化bean，导致意外的副作用。如果需要bean实例交互，请考虑实现BeanPostProcessor

 BeanDefinitionRegistryPostProcessor继承自BeanFactoryPostProcessor提供了postProcessBeanDefinitionRegistry方法。其是对标准BeanFactoryPostProcessor SPI的扩展，允许在常规BeanFactoryPostProcessor检测开始之前<font color="red">注册进一步的bean定义</font>。postProcessBeanDefinitionRegistry方法允许在标准初始化之后修改应用程序上下文的内部bean定义注册表。这时已加载所有常规bean定义，但尚未实例化任何bean。允许在下一个后处理阶段开始之前添加更多的bean定义。比如MapperScannerConfigurer、ConfigurationClassPostProcessor均实现了BeanDefinitionRegistryPostProcessor接口

以下是BeanFactoryPostProcessor的定义
![BeanFactoryPostProcessor接口定义](BeanFactoryPostProcessor接口定义.png)

## PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors()
```java
	public static void invokeBeanFactoryPostProcessors(
			ConfigurableListableBeanFactory beanFactory, List<BeanFactoryPostProcessor> beanFactoryPostProcessors) {

		// Invoke BeanDefinitionRegistryPostProcessors first, if any.
        // 记录已经处理过的Bean
		Set<String> processedBeans = new HashSet<>();

		if (beanFactory instanceof BeanDefinitionRegistry) {
			BeanDefinitionRegistry registry = (BeanDefinitionRegistry) beanFactory;
			List<BeanFactoryPostProcessor> regularPostProcessors = new ArrayList<>();
			List<BeanDefinitionRegistryPostProcessor> registryProcessors = new ArrayList<>();

			for (BeanFactoryPostProcessor postProcessor : beanFactoryPostProcessors) {
				if (postProcessor instanceof BeanDefinitionRegistryPostProcessor) {
					BeanDefinitionRegistryPostProcessor registryProcessor =
							(BeanDefinitionRegistryPostProcessor) postProcessor;
					registryProcessor.postProcessBeanDefinitionRegistry(registry);
					registryProcessors.add(registryProcessor);
				}
				else {
					regularPostProcessors.add(postProcessor);
				}
			}

			// Do not initialize FactoryBeans here: We need to leave all regular beans
			// uninitialized to let the bean factory post-processors apply to them!
			// Separate between BeanDefinitionRegistryPostProcessors that implement
			// PriorityOrdered, Ordered, and the rest.
			List<BeanDefinitionRegistryPostProcessor> currentRegistryProcessors = new ArrayList<>();

			// First, invoke the BeanDefinitionRegistryPostProcessors that implement PriorityOrdered.
            // 先执行实现了 PriorityOrdered接口的，然后是 Ordered 接口的，最后执行剩下的
			String[] postProcessorNames =
					beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
			for (String ppName : postProcessorNames) {
				if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
					currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
					processedBeans.add(ppName);
				}
			}
			sortPostProcessors(currentRegistryProcessors, beanFactory);
			registryProcessors.addAll(currentRegistryProcessors);
			invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry, beanFactory.getApplicationStartup());
			currentRegistryProcessors.clear();

			// Next, invoke the BeanDefinitionRegistryPostProcessors that implement Ordered.
            // 再次检索BeanDefinitionRegistryPostProcessor，因为其本身可能引入新的BeanDefinitionRegistryPostProcessor
			postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
			for (String ppName : postProcessorNames) {
				if (!processedBeans.contains(ppName) && beanFactory.isTypeMatch(ppName, Ordered.class)) {
					currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
					processedBeans.add(ppName);
				}
			}
			sortPostProcessors(currentRegistryProcessors, beanFactory);
			registryProcessors.addAll(currentRegistryProcessors);
			invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry, beanFactory.getApplicationStartup());
			currentRegistryProcessors.clear();

			// Finally, invoke all other BeanDefinitionRegistryPostProcessors until no further ones appear.
			boolean reiterate = true;
			while (reiterate) {
				reiterate = false;
				postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
				for (String ppName : postProcessorNames) {
					if (!processedBeans.contains(ppName)) {
						currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
						processedBeans.add(ppName);
						reiterate = true;
					}
				}
				sortPostProcessors(currentRegistryProcessors, beanFactory);
				registryProcessors.addAll(currentRegistryProcessors);
				invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry, beanFactory.getApplicationStartup());
				currentRegistryProcessors.clear();
			}

			// Now, invoke the postProcessBeanFactory callback of all processors handled so far.
            // 上面处理的都是postProcessBeanDefinitionRegistry是在BeanDefinitionRegistryPostProcessor中
            // 下面开始处理postProcessBeanFactory是在 BeanFactoryPostProcessor 中
			invokeBeanFactoryPostProcessors(registryProcessors, beanFactory);
			invokeBeanFactoryPostProcessors(regularPostProcessors, beanFactory);
		}

		else {
			// Invoke factory processors registered with the context instance.
            // 不是BeanDefinitionRegistry则是普通 BeanFactory 直接执行 beanFactoryPostProcessors即可
			invokeBeanFactoryPostProcessors(beanFactoryPostProcessors, beanFactory);
		}

		// Do not initialize FactoryBeans here: We need to leave all regular beans
		// uninitialized to let the bean factory post-processors apply to them!
		String[] postProcessorNames =
				beanFactory.getBeanNamesForType(BeanFactoryPostProcessor.class, true, false);

		// Separate between BeanFactoryPostProcessors that implement PriorityOrdered,
		// Ordered, and the rest.
        // 分成三个部分 PriorityOrdered Ordered及其他
		List<BeanFactoryPostProcessor> priorityOrderedPostProcessors = new ArrayList<>();
		List<String> orderedPostProcessorNames = new ArrayList<>();
		List<String> nonOrderedPostProcessorNames = new ArrayList<>();
		for (String ppName : postProcessorNames) {
			if (processedBeans.contains(ppName)) {
				// skip - already processed in first phase above
			}
			else if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
				priorityOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanFactoryPostProcessor.class));
			}
			else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
				orderedPostProcessorNames.add(ppName);
			}
			else {
				nonOrderedPostProcessorNames.add(ppName);
			}
		}

		// First, invoke the BeanFactoryPostProcessors that implement PriorityOrdered.
		sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
		invokeBeanFactoryPostProcessors(priorityOrderedPostProcessors, beanFactory);

		// Next, invoke the BeanFactoryPostProcessors that implement Ordered.
		List<BeanFactoryPostProcessor> orderedPostProcessors = new ArrayList<>(orderedPostProcessorNames.size());
		for (String postProcessorName : orderedPostProcessorNames) {
			orderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
		}
		sortPostProcessors(orderedPostProcessors, beanFactory);
		invokeBeanFactoryPostProcessors(orderedPostProcessors, beanFactory);

		// Finally, invoke all other BeanFactoryPostProcessors.
		List<BeanFactoryPostProcessor> nonOrderedPostProcessors = new ArrayList<>(nonOrderedPostProcessorNames.size());
		for (String postProcessorName : nonOrderedPostProcessorNames) {
			nonOrderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
		}
		invokeBeanFactoryPostProcessors(nonOrderedPostProcessors, beanFactory);

		// Clear cached merged bean definitions since the post-processors might have
		// modified the original metadata, e.g. replacing placeholders in values...
		beanFactory.clearMetadataCache();
	}
```

方法大致我们分为两个部分，以String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanFactoryPostProcessor.class, true, false);语句为分割线，其上属于第一部分，其下属于第二部分。

第一部分分为两块，如果当前BeanFactory是BeanDefinitionRegistry实例则进行已经复杂的处理。否则直接调用invokeBeanFactoryPostProcessors。
BeanFactory是BeanDefinitionRegistry实例时流程:
1. 创建两个list，regularPostProcessors和registryProcessors；
2. 循环遍历beanFactoryPostProcessors，如果其是BeanDefinitionRegistryPostProcessor类型则调用postProcessBeanDefinitionRegistryf方法并放到registryProcessors中，否则放到regularPostProcessors中
3. 扫描容器中的BeanDefinitionRegistryPostProcessor，分成PriorityOrdered、Ordered和其他三个部分，对每一部分都进行排序然后触发每个实例的postProcessBeanDefinitionRegistry方法
4. 最后对registryProcessors和regularPostProcessors两个集合所有实例的postProcessBeanFactory方法进行执行

第一部分可以简单理解其是处理的BeanDefinitionRegistryPostProcessor实例的postProcessBeanDefinitionRegistry方法和postProcessBeanFactory方法。

第二部分则是处理其父接口BeanFactoryPostProcessor的postProcessBeanFactory方法。
从容器中扫描BeanFactoryPostProcessor然后分为三个部分：PriorityOrdered、Ordered和其他。对每一部分进行排序然后调用其postProcessBeanFactory方法。


## beanFactoryPostProcessors来源:
这三个方法均是在prepareContext方法中触发的:
```java
// SharedMetadataReaderFactoryContextInitializer的initialize方法。
@Override
public void initialize(ConfigurableApplicationContext applicationContext) {
	applicationContext.addBeanFactoryPostProcessor(new CachingMetadataReaderFactoryPostProcessor());
}
// ConfigurationWarningsApplicationContextInitializer的initialize方法。
@Override
public void initialize(ConfigurableApplicationContext context) {
	context.addBeanFactoryPostProcessor(new ConfigurationWarningsPostProcessor(getChecks()));
}
// ConfigFileApplicationListener的addPostProcessors方法。
protected void addPostProcessors(ConfigurableApplicationContext context) {
	context.addBeanFactoryPostProcessor(new PropertySourceOrderingPostProcessor(context));
}
```
## CachingMetadataReaderFactoryPostProcessor:
```java
static class CachingMetadataReaderFactoryPostProcessor implements BeanDefinitionRegistryPostProcessor, PriorityOrdered {
		private final ConfigurableApplicationContext context;

    CachingMetadataReaderFactoryPostProcessor(ConfigurableApplicationContext context) {
        this.context = context;
    }

    @Override
    public int getOrder() {
        // Must happen before the ConfigurationClassPostProcessor is created
        return Ordered.HIGHEST_PRECEDENCE;
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
    }

    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException {
        register(registry);
        configureConfigurationClassPostProcessor(registry);
    }

    private void register(BeanDefinitionRegistry registry) {
        // public static final String BEAN_NAME = "org.springframework.boot.autoconfigure.internalCachingMetadataReaderFactory";
        if (!registry.containsBeanDefinition(BEAN_NAME)) {
            BeanDefinition definition = BeanDefinitionBuilder
                .rootBeanDefinition(SharedMetadataReaderFactoryBean.class, SharedMetadataReaderFactoryBean::new)
                .getBeanDefinition();
            // 注册SharedMetadataReaderFactoryBean的BeanDefinition
            registry.registerBeanDefinition(BEAN_NAME, definition);
        }
    }

    private void configureConfigurationClassPostProcessor(BeanDefinitionRegistry registry) {
        try {
            // public static final String CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME = "org.springframework.context.annotation.internalConfigurationAnnotationProcessor"
            // 这里获取的internalConfigurationAnnotationProcessor的BeanDefinition是ConfigurationClassPostProcessor
            configureConfigurationClassPostProcessor(
                    registry.getBeanDefinition(AnnotationConfigUtils.CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME));
        }
        catch (NoSuchBeanDefinitionException ex) {
        }
    }

    // 这里的definition就是ConfigurationClassPostProcessor
    private void configureConfigurationClassPostProcessor(BeanDefinition definition) {
        if (definition instanceof AbstractBeanDefinition) {
            configureConfigurationClassPostProcessor((AbstractBeanDefinition) definition);
            return;
        }
        configureConfigurationClassPostProcessor(definition.getPropertyValues());
    }

    private void configureConfigurationClassPostProcessor(AbstractBeanDefinition definition) {
        Supplier<?> instanceSupplier = definition.getInstanceSupplier();
        if (instanceSupplier != null) {
            definition.setInstanceSupplier(
                    new ConfigurationClassPostProcessorCustomizingSupplier(this.context, instanceSupplier));
            return;
        }
        configureConfigurationClassPostProcessor(definition.getPropertyValues());
    }

    private void configureConfigurationClassPostProcessor(MutablePropertyValues propertyValues) {
        propertyValues.add("metadataReaderFactory", new RuntimeBeanReference(BEAN_NAME));
    }
}
```

## ConfigurationClassPostProcessor
其核心是用来处理@Configuration标注的配置类。
```java
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
		PriorityOrdered, ResourceLoaderAware, ApplicationStartupAware, BeanClassLoaderAware, EnvironmentAware {

}
```
ConfigurationClassPostProcessor后处理器是按优先级排序的，<font color="red">因为在@Configuration配置类中声明的任何@Bean方法都必须在任何其他BeanFactoryPostProcessor执行之前注册相应的Bean定义，这一点很重要。</font>

```java
@Override
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
    int registryId = System.identityHashCode(registry);
    if (this.registriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
                "postProcessBeanDefinitionRegistry already called on this post-processor against " + registry);
    }
    if (this.factoriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
                "postProcessBeanFactory already called on this post-processor against " + registry);
    }
    this.registriesPostProcessed.add(registryId);
    // 处理配置bean定义
    processConfigBeanDefinitions(registry);
}
```
关于ConfigurationClassPostProcessor本文我们这里不做进一步分析，简单梳理其作用如下：
1. 对于候选配置类使用CGLIB Enhancer增强
2. 解析处理@PropertySource 注解
3. 解析@ComponentScan注解,扫描@Configuration、@Service、@Controller、@Repository和@Component注解并注册BeanDefinition
4. 解析@Import注解,然后进行实例化,并执行ImportBeanDefinitionRegistrar的registerBeanDefinitions逻辑,或者ImportSelector的selectImports逻辑
5. 解析@ImportResource注解,并加载相关配置信息
6. 解析方法级别@Bean注解并将返回值注册成BeanDefinition
7. 注册ImportAwareBeanPostProcessor到容器中,用于处理ImportAware

总结一点就是，经过ConfigurationClassPostProcessor和MapperScannerConfigurer的处理，我们的DefaultListableBeanFactory的beanDefinitionMap中已经拥有了应用程序中的静态BeanDefinition(可能不是全部，比如程序动态添加)。
>https://blog.csdn.net/J080624/article/details/54345467

# registerBeanPostProcessors(beanFactory)
本方法会注册所有的 BeanPostProcessor，将所有实现了 BeanPostProcessor 接口的类加载到 BeanFactory 中。

```java
// BeanPostProcessor接口定义
interface BeanPostProcessor {

	@Nullable
	default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}

	@Nullable
	default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}
}

// 调用函数开始
protected void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.registerBeanPostProcessors(beanFactory, this);
}

public static void registerBeanPostProcessors(
        ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {

    // 找到BeanPostProcessor，然后按照PriorityOrdered、Ordered、其他常规的BeanPostProcessor、内部BeanPostProcessor顺序依次注册
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);

    // Register BeanPostProcessorChecker that logs an info message when
    // a bean is created during BeanPostProcessor instantiation, i.e. when
    // a bean is not eligible for getting processed by all BeanPostProcessors.
    int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
    
    beanFactory.addBeanPostProcessor(new BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));

    List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList<>();
    List<BeanPostProcessor> internalPostProcessors = new ArrayList<>();
    List<String> orderedPostProcessorNames = new ArrayList<>();
    List<String> nonOrderedPostProcessorNames = new ArrayList<>();
    for (String ppName : postProcessorNames) {
        if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
            priorityOrderedPostProcessors.add(pp);
            if (pp instanceof MergedBeanDefinitionPostProcessor) {
                internalPostProcessors.add(pp);
            }
        }
        else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            orderedPostProcessorNames.add(ppName);
        }
        else {
            nonOrderedPostProcessorNames.add(ppName);
        }
    }

    // First, register the BeanPostProcessors that implement PriorityOrdered.
    sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, priorityOrderedPostProcessors);

    // Next, register the BeanPostProcessors that implement Ordered.
    List<BeanPostProcessor> orderedPostProcessors = new ArrayList<>(orderedPostProcessorNames.size());
    for (String ppName : orderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        orderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    sortPostProcessors(orderedPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, orderedPostProcessors);

    // Now, register all regular BeanPostProcessors.
    List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList<>(nonOrderedPostProcessorNames.size());
    for (String ppName : nonOrderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        nonOrderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    registerBeanPostProcessors(beanFactory, nonOrderedPostProcessors);

    // Finally, re-register all internal BeanPostProcessors.
    sortPostProcessors(internalPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, internalPostProcessors);

    // Re-register post-processor for detecting inner beans as ApplicationListeners,
    // moving it to the end of the processor chain (for picking up proxies etc).
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
}

// 将BeanPostProcessors添加到beanFacotry中
private static void registerBeanPostProcessors(
        ConfigurableListableBeanFactory beanFactory, List<BeanPostProcessor> postProcessors) {

    if (beanFactory instanceof AbstractBeanFactory) {
        // Bulk addition is more efficient against our CopyOnWriteArrayList there
        ((AbstractBeanFactory) beanFactory).addBeanPostProcessors(postProcessors);
    }
    else {
        for (BeanPostProcessor postProcessor : postProcessors) {
            beanFactory.addBeanPostProcessor(postProcessor);
        }
    }
}
```
# initMessageSource()
MessageSource 是用来处理国际化的，该方法将会初始化MessageSource并尝试设置parentMessageSource，然后作为单例bean注册到容器中

```java
protected void initMessageSource() {
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    if (beanFactory.containsLocalBean(MESSAGE_SOURCE_BEAN_NAME)) {
        this.messageSource = beanFactory.getBean(MESSAGE_SOURCE_BEAN_NAME, MessageSource.class);
        // Make MessageSource aware of parent MessageSource.
        if (this.parent != null && this.messageSource instanceof HierarchicalMessageSource) {
            HierarchicalMessageSource hms = (HierarchicalMessageSource) this.messageSource;
            if (hms.getParentMessageSource() == null) {
                // Only set parent context as parent MessageSource if no parent MessageSource
                // registered already.
                hms.setParentMessageSource(getInternalParentMessageSource());
            }
        }
        if (logger.isTraceEnabled()) {
            logger.trace("Using MessageSource [" + this.messageSource + "]");
        }
    }
    else {
        // Use empty MessageSource to be able to accept getMessage calls.
        // 默认设置的国际化MessageSource就是走的这里
        DelegatingMessageSource dms = new DelegatingMessageSource();
        dms.setParentMessageSource(getInternalParentMessageSource());
        this.messageSource = dms;
        // public static final String MESSAGE_SOURCE_BEAN_NAME = "messageSource";
        beanFactory.registerSingleton(MESSAGE_SOURCE_BEAN_NAME, this.messageSource);
        if (logger.isTraceEnabled()) {
            logger.trace("No '" + MESSAGE_SOURCE_BEAN_NAME + "' bean, using [" + this.messageSource + "]");
        }
    }
}
```
# initApplicationEventMulticaster()
初始化事件监听多路广播器
```java
protected void initApplicationEventMulticaster() {
    // public static final String APPLICATION_EVENT_MULTICASTER_BEAN_NAME = "applicationEventMulticaster";
    // //获取Bean工厂，一般为DefaultListBeanFactory
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    // beanFactory中如果有applicationEventMulticaster的则获取该实例
    if (beanFactory.containsLocalBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME)) {
        this.applicationEventMulticaster =
                beanFactory.getBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
        if (logger.isTraceEnabled()) {
            logger.trace("Using ApplicationEventMulticaster [" + this.applicationEventMulticaster + "]");
        }
    }
    else {
        // BeanFactory中如果没有applicationEventMulticaster，则新建一个SimpleApplicationEventMulticaster
        // 然后将其注册到BeanFactory中
        // 其中SimpleApplicationEventMulticaster继承了AbstractApplicationEventMulticaster抽象类，而这个抽象类实现了aplicationEventMulticaster接口
        this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
        beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this.applicationEventMulticaster);
        if (logger.isTraceEnabled()) {
            logger.trace("No '" + APPLICATION_EVENT_MULTICASTER_BEAN_NAME + "' bean, using " +
                    "[" + this.applicationEventMulticaster.getClass().getSimpleName() + "]");
        }
    }
}
```
# onRefresh()
这个方法是模板方法，具体的子类可以在这里初始化一些特殊的 Bean（在初始化 singleton beans 之前）
```java
// AbstractApplicationContext.java
protected void onRefresh() throws BeansException {
    // For subclasses: do nothing by default.
}

// ServletWebServerApplicationContext.java
@Override
protected void onRefresh() {
    super.onRefresh();
    try {
        createWebServer();
    }
    catch (Throwable ex) {
        throw new ApplicationContextException("Unable to start web server", ex);
    }
}

// GenericWebApplicationContext.java
protected void onRefresh() {
    this.themeSource = UiApplicationContextUtils.initThemeSource(this);
}
```
可以看出在ServletWebServerApplicationContext中首先调用了其父类GenericWebApplicationContext的onRefresh方法，然后调用自身的onRefresh方法。
先走父类的initThemeSource方法，然后执行创建webserver
```java
public static ThemeSource initThemeSource(ApplicationContext context) {
    // public static final String THEME_SOURCE_BEAN_NAME = "themeSource";
    // 如果有themeSource的话则获取该bean
    if (context.containsLocalBean(THEME_SOURCE_BEAN_NAME)) {
        ThemeSource themeSource = context.getBean(THEME_SOURCE_BEAN_NAME, ThemeSource.class);
        // Make ThemeSource aware of parent ThemeSource.
        if (context.getParent() instanceof ThemeSource && themeSource instanceof HierarchicalThemeSource) {
            HierarchicalThemeSource hts = (HierarchicalThemeSource) themeSource;
            if (hts.getParentThemeSource() == null) {
                // Only set parent context as parent ThemeSource if no parent ThemeSource
                // registered already.
                hts.setParentThemeSource((ThemeSource) context.getParent());
            }
        }
        if (logger.isDebugEnabled()) {
            logger.debug("Using ThemeSource [" + themeSource + "]");
        }
        return themeSource;
    }
    else {
        // Use default ThemeSource to be able to accept getTheme calls, either
        // delegating to parent context's default or to local ResourceBundleThemeSource.
        // 新建一个themeSource
        HierarchicalThemeSource themeSource = null;
        if (context.getParent() instanceof ThemeSource) {
            themeSource = new DelegatingThemeSource();
            themeSource.setParentThemeSource((ThemeSource) context.getParent());
        }
        else {
            themeSource = new ResourceBundleThemeSource();
        }
        if (logger.isDebugEnabled()) {
            logger.debug("Unable to locate ThemeSource with name '" + THEME_SOURCE_BEAN_NAME +
                    "': using default [" + themeSource + "]");
        }
        return themeSource;
    }
}

private void createWebServer() {
    WebServer webServer = this.webServer;
    ServletContext servletContext = getServletContext();
    if (webServer == null && servletContext == null) {
        // springboot启动时在这里创建webserver
        StartupStep createWebServer = this.getApplicationStartup().start("spring.boot.webserver.create");
        // 从BeanFactory中获取ServletWebServerFactory
        ServletWebServerFactory factory = getWebServerFactory();
        createWebServer.tag("factory", factory.getClass().toString());
        // 本文以TomcatServletWebServerFactory为例：调用TomcatServletWebServerFactory中的getWebServer创建tomcat服务器
        this.webServer = factory.getWebServer(getSelfInitializer());
        createWebServer.end();
        // 向BeanFactory注册webserver的生命周期的类
        getBeanFactory().registerSingleton("webServerGracefulShutdown", new WebServerGracefulShutdownLifecycle(this.webServer));
        getBeanFactory().registerSingleton("webServerStartStop", new WebServerStartStopLifecycle(this, this.webServer));
    }
    else if (servletContext != null) {
        try {
            getSelfInitializer().onStartup(servletContext);
        }
        catch (ServletException ex) {
            throw new ApplicationContextException("Cannot initialize servlet context", ex);
        }
    }
    // 这里，tomcat开始已经运行
    initPropertySources();
}

// 从BeanFactory中获取ServletWebServerFactory
protected ServletWebServerFactory getWebServerFactory() {
    // Use bean names so that we don't consider the hierarchy
    String[] beanNames = getBeanFactory().getBeanNamesForType(ServletWebServerFactory.class);
    if (beanNames.length == 0) {
        throw new MissingWebServerFactoryBeanException(getClass(), ServletWebServerFactory.class,
                WebApplicationType.SERVLET);
    }
    if (beanNames.length > 1) {
        throw new ApplicationContextException("Unable to start ServletWebServerApplicationContext due to multiple "
                + "ServletWebServerFactory beans : " + StringUtils.arrayToCommaDelimitedString(beanNames));
    }
    return getBeanFactory().getBean(beanNames[0], ServletWebServerFactory.class);
}
```
ServletWebServerFactory类图：
![WebServerFactory](WebServerFactory.png)
以下为上文的TomcatServletWebServerFactory中的getWebServer
```java
public WebServer getWebServer(ServletContextInitializer... initializers) {
    if (this.disableMBeanRegistry) {
        Registry.disableRegistry();
    }
    // 创建Tomcat类
    Tomcat tomcat = new Tomcat();
    // 设置baseDir
    File baseDir = (this.baseDirectory != null) ? this.baseDirectory : createTempDir("tomcat");
    tomcat.setBaseDir(baseDir.getAbsolutePath());
    for (LifecycleListener listener : this.serverLifecycleListeners) {
        tomcat.getServer().addLifecycleListener(listener);
    }
    // public static final String DEFAULT_PROTOCOL = "org.apache.coyote.http11.Http11NioProtocol";
    // private String protocol = DEFAULT_PROTOCOL
    // 这里的protocol就是org.apache.coyote.http11.Http11NioProtocol
    // =================================设置Connector开始=============================================
    Connector connector = new Connector(this.protocol);
    connector.setThrowOnFailure(true);
    tomcat.getService().addConnector(connector);
    // 
    customizeConnector(connector);
    // =================================设置Connector结束=============================================
    tomcat.setConnector(connector);
    tomcat.getHost().setAutoDeploy(false);
    configureEngine(tomcat.getEngine());
    for (Connector additionalConnector : this.additionalTomcatConnectors) {
        tomcat.getService().addConnector(additionalConnector);
    }
    // 准备tomcat的context，这里不细说了，后面再看
    prepareContext(tomcat.getHost(), initializers);
    // 这里面创建TomcatWebServer时，会启动tomcat
    return getTomcatWebServer(tomcat);
}

protected TomcatWebServer getTomcatWebServer(Tomcat tomcat) {
    return new TomcatWebServer(tomcat, getPort() >= 0, getShutdown());
}

public TomcatWebServer(Tomcat tomcat, boolean autoStart, Shutdown shutdown) {
    Assert.notNull(tomcat, "Tomcat Server must not be null");
    this.tomcat = tomcat;
    this.autoStart = autoStart;
    this.gracefulShutdown = (shutdown == Shutdown.GRACEFUL) ? new GracefulShutdown(tomcat) : null;
    initialize();
}

private void initialize() throws WebServerException {
    logger.info("Tomcat initialized with port(s): " + getPortsDescription(false));
    synchronized (this.monitor) {
        try {
            addInstanceIdToEngineName();

            Context context = findContext();
            context.addLifecycleListener((event) -> {
                if (context.equals(event.getSource()) && Lifecycle.START_EVENT.equals(event.getType())) {
                    // Remove service connectors so that protocol binding doesn't
                    // happen when the service is started.
                    removeServiceConnectors();
                }
            });

            // Start the server to trigger initialization listeners
            // 启动tomcat
            this.tomcat.start();

            // We can re-throw failure exception directly in the main thread
            rethrowDeferredStartupExceptions();

            try {
                ContextBindings.bindClassLoader(context, context.getNamingToken(), getClass().getClassLoader());
            }
            catch (NamingException ex) {
                // Naming is not enabled. Continue
            }

            // Unlike Jetty, all Tomcat threads are daemon threads. We create a
            // blocking non-daemon to stop immediate shutdown
            startDaemonAwaitThread();
        }
        catch (Exception ex) {
            stopSilently();
            destroySilently();
            throw new WebServerException("Unable to start embedded Tomcat", ex);
        }
    }
}
```
# registerListeners()
将会获取AbstractApplicationContext的applicationListeners和容器中的ApplicationListener进行注册，最后会尝试将earlyApplicationEvents广播出去。
```java
protected void registerListeners() {
    // Register statically specified listeners first.
    // 获取的是成员applicationListeners
    // 这里getApplicationListeners()获取的applicationListeners是在refresh方法前的prepareContext方法中注册进来的
    for (ApplicationListener<?> listener : getApplicationListeners()) {
        // 获取SimpleApplicationEventMulticaster触发其方法
        getApplicationEventMulticaster().addApplicationListener(listener);
    }

    // Do not initialize FactoryBeans here: We need to leave all regular beans
    // uninitialized to let post-processors apply to them!
    // // 从容器中获取ApplicationListener
    String[] listenerBeanNames = getBeanNamesForType(ApplicationListener.class, true, false);
    for (String listenerBeanName : listenerBeanNames) {
        // 获取SimpleApplicationEventMulticaster触发其方法-这里放的是beanName
        getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
    }

    // Publish early application events now that we finally have a multicaster...
    // earlyApplicationEvents赋予earlyEventsToProcess 然后重新将置为null。如果earlyEventsToProcess不为空则进行遍历挨个进行事件广播。
    Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
    this.earlyApplicationEvents = null;
    // 如果早期/渴望的事件存在，则将其广播出去
    if (!CollectionUtils.isEmpty(earlyEventsToProcess)) {
        for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
            getApplicationEventMulticaster().multicastEvent(earlyEvent);
        }
    }
}
```
# finishBeanFactoryInitialization(beanFactory)

# finishRefresh()

# destroyBeans()

# cancelRefresh()

# resetCommonCaches()