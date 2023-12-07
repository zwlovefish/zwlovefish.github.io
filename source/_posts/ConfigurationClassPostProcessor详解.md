---
title: ConfigurationClassPostProcessor详解
date: 2023-12-06 15:30:39
tags: SpringBoot启动流程
categories: SpringBoot
---
关于ConfigurationClassPostProcessor梳理其作用如下：
1. 对于候选配置类使用CGLIB Enhancer增强
2. 解析处理@PropertySource 注解
3. 解析@ComponentScan注解,扫描@Configuration、@Service、@Controller、@Repository和@Component注解并注册BeanDefinition
4. 解析@Import注解,然后进行实例化,并执行ImportBeanDefinitionRegistrar的registerBeanDefinitions逻辑,或者ImportSelector的selectImports逻辑
5. 解析@ImportResource注解,并加载相关配置信息
6. 解析方法级别@Bean注解并将返回值注册成BeanDefinition
7. 注册ImportAwareBeanPostProcessor到容器中,用于处理ImportAware

预先了解一下ConfigurationClassPostProcessor是怎么来的：
在SpringBoot学习一文中提到创建ApplicationContext中，这里首先在BeanFactory中register了6个类类型，然后在prepareContext的load中添加应用类的类型共7个类型：
- org.springframework.context.annotation.internalConfigurationAnnotationProcessor：ConfigurationClassPostProcessor
- org.springframework.context.annotation.internalAutowiredAnnotationProcessor： AutowiredAnnotationBeanPostProcessor
- org.springframework.context.annotation.internalCommonAnnotationProcessor： CommonAnnotationBeanPostProcessor
- org.springframework.context.annotation.internalPersistenceAnnotationProcessor： PersistenceAnnotationBeanPostProcessor（一般不会添加这条记录）
- org.springframework.context.event.internalEventListenerProcessor： EventListenerMethodProcessor
- org.springframework.context.event.internalEventListenerFactory： DefaultEventListenerFactory
- SpringBootDemo: SpringBootDemo(SpringBoot项目的入口类)

<!-- more -->

```java
// 创建的是AnnotationConfigServletWebServerApplicationContext
private ConfigurableApplicationContext createContext() {
    if (!AotDetector.useGeneratedArtifacts()) {
        // 走的这个分支
        return new AnnotationConfigServletWebServerApplicationContext();
    }
    return new ServletWebServerApplicationContext();
}

public AnnotationConfigServletWebServerApplicationContext() {
    this.reader = new AnnotatedBeanDefinitionReader(this);
    this.scanner = new ClassPathBeanDefinitionScanner(this);
}

public AnnotatedBeanDefinitionReader(BeanDefinitionRegistry registry) {
    this(registry, getOrCreateEnvironment(registry));
}

public AnnotatedBeanDefinitionReader(BeanDefinitionRegistry registry, Environment environment) {
    Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
    Assert.notNull(environment, "Environment must not be null");
    this.registry = registry;
    this.conditionEvaluator = new ConditionEvaluator(registry, environment, null);
    AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
}

public static void registerAnnotationConfigProcessors(BeanDefinitionRegistry registry) {
    registerAnnotationConfigProcessors(registry, null);
}

public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
        BeanDefinitionRegistry registry, @Nullable Object source) {

    DefaultListableBeanFactory beanFactory = unwrapDefaultListableBeanFactory(registry);
    if (beanFactory != null) {
        if (!(beanFactory.getDependencyComparator() instanceof AnnotationAwareOrderComparator)) {
            beanFactory.setDependencyComparator(AnnotationAwareOrderComparator.INSTANCE);
        }
        if (!(beanFactory.getAutowireCandidateResolver() instanceof ContextAnnotationAutowireCandidateResolver)) {
            beanFactory.setAutowireCandidateResolver(new ContextAnnotationAutowireCandidateResolver());
        }
    }

    Set<BeanDefinitionHolder> beanDefs = new LinkedHashSet<>(8);

    // registerPostProcessor就是将后面的BEAN_NAME作为key，RootBeanDefinition作为value存入到BeanFactory的this.beanDefinitionMap中
    if (!registry.containsBeanDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(ConfigurationClassPostProcessor.class);
        def.setSource(source);
        // =======================================================================================
        // key: org.springframework.context.annotation.internalConfigurationAnnotationProcessor
        // value: ConfigurationClassPostProcessor
        // =======================================================================================
        beanDefs.add(registerPostProcessor(registry, def, CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(AutowiredAnnotationBeanPostProcessor.class);
        def.setSource(source);
        // key: org.springframework.context.annotation.internalAutowiredAnnotationProcessor
        // value: AutowiredAnnotationBeanPostProcessor
        beanDefs.add(registerPostProcessor(registry, def, AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    // Check for JSR-250 support, and if present add the CommonAnnotationBeanPostProcessor.
    if (jsr250Present && !registry.containsBeanDefinition(COMMON_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(CommonAnnotationBeanPostProcessor.class);
        def.setSource(source);
        // key: org.springframework.context.annotation.internalCommonAnnotationProcessor
        // value: CommonAnnotationBeanPostProcessor
        beanDefs.add(registerPostProcessor(registry, def, COMMON_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    // Check for JPA support, and if present add the PersistenceAnnotationBeanPostProcessor(一般走不到这里)
    if (jpaPresent && !registry.containsBeanDefinition(PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition();
        try {
            def.setBeanClass(ClassUtils.forName(PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME,
                    AnnotationConfigUtils.class.getClassLoader()));
        }
        catch (ClassNotFoundException ex) {
            throw new IllegalStateException(
                    "Cannot load optional framework class: " + PERSISTENCE_ANNOTATION_PROCESSOR_CLASS_NAME, ex);
        }
        def.setSource(source);
        // key: org.springframework.context.annotation.internalPersistenceAnnotationProcessor
        // value: org.springframework.orm.jpa.support.PersistenceAnnotationBeanPostProcessor
        beanDefs.add(registerPostProcessor(registry, def, PERSISTENCE_ANNOTATION_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(EVENT_LISTENER_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(EventListenerMethodProcessor.class);
        def.setSource(source);
        // key: org.springframework.context.event.internalEventListenerProcessor
        // value: EventListenerMethodProcessor
        beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_PROCESSOR_BEAN_NAME));
    }

    if (!registry.containsBeanDefinition(EVENT_LISTENER_FACTORY_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(DefaultEventListenerFactory.class);
        def.setSource(source);
        // key: org.springframework.context.event.internalEventListenerFactory
        // value: DefaultEventListenerFactory
        beanDefs.add(registerPostProcessor(registry, def, EVENT_LISTENER_FACTORY_BEAN_NAME));
    }

    return beanDefs;
}
```
在context的refresh阶段中调用invokeBeanFactoryPostProcessors函数时首先执行接口BeanDefinitionRegistryPostProcessor#postProcessBeanDefinitionRegistry，在执行其父接口BeanFactoryPostProcessor中的postProcessBeanFactory方法。

ConfigurationClassPostProcessor的类信息是：class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor
所以在invokeBeanFactoryPostProcessors时会先执行ConfigurationClassPostProcessor中的postProcessBeanDefinitionRegistry，在执行其postProcessBeanFactory

```java
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

    processConfigBeanDefinitions(registry);
}

public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    int factoryId = System.identityHashCode(beanFactory);
    if (this.factoriesPostProcessed.contains(factoryId)) {
        throw new IllegalStateException(
                "postProcessBeanFactory already called on this post-processor against " + beanFactory);
    }
    this.factoriesPostProcessed.add(factoryId);
    if (!this.registriesPostProcessed.contains(factoryId)) {
        // BeanDefinitionRegistryPostProcessor hook apparently not supported...
        // Simply call processConfigurationClasses lazily at this point then.
        processConfigBeanDefinitions((BeanDefinitionRegistry) beanFactory);
    }

    enhanceConfigurationClasses(beanFactory);
    beanFactory.addBeanPostProcessor(new ImportAwareBeanPostProcessor(beanFactory));
}
```

# postProcessBeanDefinitionRegistry
```java
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
    // 主要是这一行函数
    processConfigBeanDefinitions(registry);
}

public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
    List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
    String[] candidateNames = registry.getBeanDefinitionNames();
    /**
     * 
     * org.springframework.context.annotation.internalConfigurationAnnotationProcessor：ConfigurationClassPostProcessor
     * org.springframework.context.annotation.internalAutowiredAnnotationProcessor： AutowiredAnnotationBeanPostProcessor
     * org.springframework.context.annotation.internalCommonAnnotationProcessor： CommonAnnotationBeanPostProcessor
     * org.springframework.context.annotation.internalPersistenceAnnotationProcessor： PersistenceAnnotationBeanPostProcessor（一般不会添加这条记录）
     * org.springframework.context.event.internalEventListenerProcessor： EventListenerMethodProcessor
     * org.springframework.context.event.internalEventListenerFactory： DefaultEventListenerFactory
     * SpringBootDemo: SpringBootDemo(SpringBoot项目的入口类)
     * 
     * 
    */
    for (String beanName : candidateNames) {
        BeanDefinition beanDef = registry.getBeanDefinition(beanName);
        // 如果有这个属性则不处理
        if (beanDef.getAttribute(ConfigurationClassUtils.CONFIGURATION_CLASS_ATTRIBUTE) != null) {
            if (logger.isDebugEnabled()) {
                logger.debug("Bean definition has already been processed as a configuration class: " + beanDef);
            }
        }
        // 检查给定的 bean 定义是否是配置类（或在配置组件类中声明的嵌套组件类，也将自动注册）的候选者，并相应地对其进行标记
        // 主要是就是获取bean definition信息中的元数据metadata，判断元数据中是否有Configuration注解
        // Map<String, Object> config = metadata.getAnnotationAttributes(Configuration.class.getName());
		// if (config != null && !Boolean.FALSE.equals(config.get("proxyBeanMethods"))) {
		// 	beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_FULL);
		// }
		// else if (config != null || isConfigurationCandidate(metadata)) {
		// 	beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_LITE);
		// }
		// else {
		// 	return false;
		// }
        // 其他情况返回true
        // 
        // 一般情况只有SpringBootDemo这个类会被添加到configCandidates中
        // 校验当前beanDef是否符合config候选条件. 具体如下:
        // 1.如果有@Configuration注解,则为deanDef添加属性 CONFIGURATION_CLASS_FULL,表示是一个完全配置类.
        // 2.如果没有@Configuration但是有@Bean/@Import等注解,则为beanDef添加属性 CONFIGURATION_CLASS_LITE,表示是一个简单的配置类.
        // 3.以上两点只要满足一点,就会返回true,如果二者都没有,则返回false
        else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
            configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
        }
    }

    // Return immediately if no @Configuration classes were found
    if (configCandidates.isEmpty()) {
        return;
    }

    // 根据@Order注解排序
    configCandidates.sort((bd1, bd2) -> {
        int i1 = ConfigurationClassUtils.getOrder(bd1.getBeanDefinition());
        int i2 = ConfigurationClassUtils.getOrder(bd2.getBeanDefinition());
        return Integer.compare(i1, i2);
    });

    // 这里设置BeanName的生成器
    SingletonBeanRegistry sbr = null;
    if (registry instanceof SingletonBeanRegistry) {
        sbr = (SingletonBeanRegistry) registry;
        if (!this.localBeanNameGeneratorSet) {
            // CONFIGURATION_BEAN_NAME_GENERATOR值是org.springframework.context.annotation.internalConfigurationBeanNameGenerator
            // 一般为空，不走这里 
            BeanNameGenerator generator = (BeanNameGenerator) sbr.getSingleton(
                    AnnotationConfigUtils.CONFIGURATION_BEAN_NAME_GENERATOR);
            if (generator != null) {
                this.componentScanBeanNameGenerator = generator;
                this.importBeanNameGenerator = generator;
            }
        }
    }

    // 这里一般web应用不为空
    if (this.environment == null) {
        this.environment = new StandardEnvironment();
    }

    /**========================================这里高能===========================================================*/
    // 新建一个Configuration类的解析器ConfigurationClassParser
    ConfigurationClassParser parser = new ConfigurationClassParser(
            this.metadataReaderFactory, this.problemReporter, this.environment,
            this.resourceLoader, this.componentScanBeanNameGenerator, registry);
    // 设置需要解析的类，如上一般初始化为SpringBootDemo
    Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
    // 可能有循环import的情况
    Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
    // 递归解析 重要!!!
    // 采用do...while的方式, 因为在解析的过程中,可能会发现新的需要解析的@Configuration class.
    // 比如在解析出来的bean当中也有打上@Configuration注解的.这时需要重新比较所有的beanDef和已解析的beanDef来筛选出
    // 新发现的Configuration class,并将其添加到候选集合中, 这样while的判断成立,将会进行新的一轮解析.
    // 周而复始,直到将所有的@Configuration class解析完.
    // 完成这一切的关键就在于解析器的parse方法
    do {
        StartupStep processConfig = this.applicationStartup.start("spring.context.config-classes.parse");
        // 具体解析过程
        parser.parse(candidates);
        parser.validate();
        // 上面是将解析过的@Configuration类放一个map中，这里全部取出来
        Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
        // 移除掉已经解析过的类
        configClasses.removeAll(alreadyParsed);

        // Read the model and create bean definitions based on its content
        if (this.reader == null) {
            this.reader = new ConfigurationClassBeanDefinitionReader(
                    registry, this.sourceExtractor, this.resourceLoader, this.environment,
                    this.importBeanNameGenerator, parser.getImportRegistry());
        }
        /**
		* 这里值得注意的是扫描出来的bean当中可能包含了特殊类
		* 比如ImportBeanDefinitionRegistrar那么也在这个方法里面处理
		* 但是并不是包含在configClasses当中
		* configClasses当中主要包含的是importSelector
		* 因为ImportBeanDefinitionRegistrar在扫描出来的时候已经被添加到一个list当中去了
		* bd 到 map 除去普通
        * 此处会把Import方式导入的Bean放到bdMap中!!!!
        * import导入的ImportBeanDefinitionRegistrar会在这里调用其registerBeanDefinitions()方法
        * ImportBeanDefinitionRegistrar的实例化在processImports()方法时已经通过BeanUtils.instantiateClass(candidateClass, ImportBeanDefinitionRegistrar.class);进行了创建
        */
        this.reader.loadBeanDefinitions(configClasses);
        alreadyParsed.addAll(configClasses);
        processConfig.tag("classCount", () -> String.valueOf(configClasses.size())).end();

        candidates.clear();
        // 新发现的Configuration class,并将其添加到候选集合中, 这样while的判断成立,将会进行新的一轮解析.
        if (registry.getBeanDefinitionCount() > candidateNames.length) {
            String[] newCandidateNames = registry.getBeanDefinitionNames();
            Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
            Set<String> alreadyParsedClasses = new HashSet<>();
            for (ConfigurationClass configurationClass : alreadyParsed) {
                alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
            }
            for (String candidateName : newCandidateNames) {
                if (!oldCandidateNames.contains(candidateName)) {
                    BeanDefinition bd = registry.getBeanDefinition(candidateName);
                    if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
                            !alreadyParsedClasses.contains(bd.getBeanClassName())) {
                        candidates.add(new BeanDefinitionHolder(bd, candidateName));
                    }
                }
            }
            candidateNames = newCandidateNames;
        }
    }
    while (!candidates.isEmpty());
    /**========================================以上高能===========================================================*/

    // Register the ImportRegistry as a bean in order to support ImportAware @Configuration classes
    if (sbr != null && !sbr.containsSingleton(IMPORT_REGISTRY_BEAN_NAME)) {
        sbr.registerSingleton(IMPORT_REGISTRY_BEAN_NAME, parser.getImportRegistry());
    }

    if (this.metadataReaderFactory instanceof CachingMetadataReaderFactory) {
        // Clear cache in externally provided MetadataReaderFactory; this is a no-op
        // for a shared cache since it'll be cleared by the ApplicationContext.
        ((CachingMetadataReaderFactory) this.metadataReaderFactory).clearCache();
    }
}
```
## ConfigurationClassParser
```java
public void parse(Set<BeanDefinitionHolder> configCandidates) {
    // 初始化进来时configCandidates只有SpringBootDemo
    for (BeanDefinitionHolder holder : configCandidates) {
        BeanDefinition bd = holder.getBeanDefinition();
        try {
            if (bd instanceof AnnotatedBeanDefinition) {
                parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
            }
            else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
                parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
            }
            else {
                parse(bd.getBeanClassName(), holder.getBeanName());
            }
        }
        catch (BeanDefinitionStoreException ex) {
            throw ex;
        }
        catch (Throwable ex) {
            throw new BeanDefinitionStoreException(
                    "Failed to parse configuration class [" + bd.getBeanClassName() + "]", ex);
        }
    }

    // 延期importSelector处理
    this.deferredImportSelectorHandler.process();
}

public void process() {
    List<DeferredImportSelectorHolder> deferredImports = this.deferredImportSelectors;
    this.deferredImportSelectors = null;
    try {
        if (deferredImports != null) {
            DeferredImportSelectorGroupingHandler handler = new DeferredImportSelectorGroupingHandler();
            // deferredImport排序
            deferredImports.sort(DEFERRED_IMPORT_COMPARATOR);
            deferredImports.forEach(handler::register);
            handler.processGroupImports();
        }
    }
    finally {
        this.deferredImportSelectors = new ArrayList<>();
    }
}

protected final void parse(@Nullable String className, String beanName) throws IOException {
    Assert.notNull(className, "No bean class name for configuration class bean definition");
    MetadataReader reader = this.metadataReaderFactory.getMetadataReader(className);
    processConfigurationClass(new ConfigurationClass(reader, beanName), DEFAULT_EXCLUSION_FILTER);
}

protected final void parse(Class<?> clazz, String beanName) throws IOException {
    processConfigurationClass(new ConfigurationClass(clazz, beanName), DEFAULT_EXCLUSION_FILTER);
}

protected final void parse(AnnotationMetadata metadata, String beanName) throws IOException {
    processConfigurationClass(new ConfigurationClass(metadata, beanName), DEFAULT_EXCLUSION_FILTER);
}

// 所以parse中调用的都是processConfigurationClass
protected void processConfigurationClass(ConfigurationClass configClass, Predicate<String> filter) throws IOException {
    if (this.conditionEvaluator.shouldSkip(configClass.getMetadata(), ConfigurationPhase.PARSE_CONFIGURATION)) {
        return;
    }

    // 第一次进来时configClass是SpringBootDemo
    // 判断正在解析的config class是否已经解析过, 如果是,则直接返回
    ConfigurationClass existingClass = this.configurationClasses.get(configClass);
    if (existingClass != null) {
        if (configClass.isImported()) {
            if (existingClass.isImported()) {
                existingClass.mergeImportedBy(configClass);
            }
            // Otherwise ignore new imported config class; existing non-imported class overrides it.
            return;
        }
        else {
            // Explicit bean definition found, probably replacing an import.
            // Let's remove the old one and go with the new one.
            this.configurationClasses.remove(configClass);
            this.knownSuperclasses.values().removeIf(configClass::equals);
        }
    }

    // Recursively process the configuration class and its superclass hierarchy.
    // 递归解析configuration类和他的超类
    SourceClass sourceClass = asSourceClass(configClass, filter);
    do {
        // 处理配置类
        sourceClass = doProcessConfigurationClass(configClass, sourceClass, filter);
    }
    while (sourceClass != null);

    this.configurationClasses.put(configClass, configClass);
}
protected final SourceClass doProcessConfigurationClass(
        ConfigurationClass configClass, SourceClass sourceClass, Predicate<String> filter)
        throws IOException {
    // 首先递归地处理任何成员(嵌套)类
    if (configClass.getMetadata().isAnnotated(Component.class.getName())) {
        // Recursively process any member (nested) classes first
        processMemberClasses(configClass, sourceClass, filter);
    }

    // 处理 @PropertySource注解
    for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
            sourceClass.getMetadata(), PropertySources.class,
            org.springframework.context.annotation.PropertySource.class)) {
        if (this.environment instanceof ConfigurableEnvironment) {
            processPropertySource(propertySource);
        }
        else {
            logger.info("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
                    "]. Reason: Environment must implement ConfigurableEnvironment");
        }
    }

    // 处理@ComponentScan注解
    // 此处或扫描到@ComponentScan注解包下面的所有加了@Component、@Service等注解的类
    // 注意的是，每扫描到一个符合条件的类，都要进行递归扫描，重新调用doProcessConfigurationClass()方法
    // 扫描到的类，转化为bd，然后放入到bdMap中
    Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
            sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
    if (!componentScans.isEmpty() &&
            !this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
        for (AnnotationAttributes componentScan : componentScans) {
            // 扫描解析在这里
            // 第一次进入这里是SpringBootDemo，其basepackage就是com.zhou
            // 扫描普通类，componentScan=com.zhou
            // 这里扫描出来所有@Component，并且把扫描的出来的普通bean放到bdMap当中
            Set<BeanDefinitionHolder> scannedBeanDefinitions =
                    this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
            // 检查扫描的定义集是否有任何进一步的配置类，并在需要时进行递归解析
            // 检查扫描出来的类当中是否还有configuration
            for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
                BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
                if (bdCand == null) {
                    bdCand = holder.getBeanDefinition();
                }
                if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
                    // 检查扫描出来的配置类有没有配置类，进行再次解析，递归调用
                    parse(bdCand.getBeanClassName(), holder.getBeanName());
                }
            }
        }
    }
    // 上面的代码就是扫描普通类----@Component，并且将扫描到的class转化为bd,并放到了bdMap当中

    // Process any @Import annotations
    /**
    *  下面这个方法是处理@Import  imports导入类的3种情况
    *  1.ImportSelector
    *  2.普通类
    *  3.ImportBeanDefinitionRegistrar
    * 这里处理的import是需要判断我们的配置类有@Import注解
    * 如果有这把@Import当中的值拿出来，是一个类，
    * 比如@Import(xxxxx.class)，那么这里便把xxxxx传进去进行解析
    * 在解析的过程中如果发觉是一个importSelector那么就回调selector()的方法
    * 返回一个字符串（类名），通过这个字符串得到一个类
    * 继而在递归调用本方法来处理这个类
    * 判断一组类是不是imports（3种import）
    * 此处import导入的类并不会立刻转化为bd放入到bdMap中
    */
    processImports(configClass, sourceClass, getImports(sourceClass), filter, true);

    // Process any @ImportResource annotations
    // 处理 @ImportResource注解
    AnnotationAttributes importResource =
            AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
    if (importResource != null) {
        String[] resources = importResource.getStringArray("locations");
        Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
        for (String resource : resources) {
            String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
            configClass.addImportedResource(resolvedResource, readerClass);
        }
    }

    // 处理单个的@Bean方法
    Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
    for (MethodMetadata methodMetadata : beanMethods) {
        configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
    }

    // 处理接口上的默认方法
    processInterfaces(configClass, sourceClass);

    // 处理超类(如果有的话)
    if (sourceClass.getMetadata().hasSuperClass()) {
        String superclass = sourceClass.getMetadata().getSuperClassName();
        if (superclass != null && !superclass.startsWith("java") &&
                !this.knownSuperclasses.containsKey(superclass)) {
            this.knownSuperclasses.put(superclass, configClass);
            // Superclass found, return its annotation metadata and recurse
            return sourceClass.getSuperClass();
        }
    }

    // No superclass -> processing is complete,在最外层导致因为sourceClass为null，退出解析
    SourceClass sourceClass = asSourceClass(configClass, filter);
    // do {
    //     // 处理配置类
    //     sourceClass = doProcessConfigurationClass(configClass, sourceClass, filter);
    // }
    // while (sourceClass != null);
    return null;
}

// 收集@import注解的类
private Set<SourceClass> getImports(SourceClass sourceClass) throws IOException {
    Set<SourceClass> imports = new LinkedHashSet<>();
    Set<SourceClass> visited = new LinkedHashSet<>();
    collectImports(sourceClass, imports, visited);
    return imports;
}

private void collectImports(SourceClass sourceClass, Set<SourceClass> imports, Set<SourceClass> visited)
        throws IOException {
    // 现将当前类放入visited，用来标记当前类已经收集
    if (visited.add(sourceClass)) {
        for (SourceClass annotation : sourceClass.getAnnotations()) {
            String annName = annotation.getMetadata().getClassName();
            if (!annName.equals(Import.class.getName())) {
                // 递归调用
                collectImports(annotation, imports, visited);
            }
        }
        imports.addAll(sourceClass.getAnnotationAttributes(Import.class.getName(), "value"));
    }
}

private void processImports(ConfigurationClass configClass, SourceClass currentSourceClass,
			Collection<SourceClass> importCandidates, Predicate<String> exclusionFilter,
			boolean checkForCircularImports) {

    if (importCandidates.isEmpty()) {
        return;
    }

    
    if (checkForCircularImports && isChainedImportOnStack(configClass)) {
        this.problemReporter.error(new CircularImportProblem(configClass, this.importStack));
    }
    else {
        this.importStack.push(configClass);
        try {
            for (SourceClass candidate : importCandidates) {
                /**1. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportSelector类型且是DeferredImportSelector类型：
                 *    表示推迟的ImportSelector，它会在当前配置类所属的批次中所有配置类都解析完了之后执行。
                 * 2. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportSelector类型且是普通ImportSelector类型：
                 *    把selectImports()方法所返回的类再次调用processImports()进行递归处理。
                 * 3. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportBeanDefinitionRegistrar类型：
                 *    将ImportBeanDefinitionRegistrar实例对象添加到当前配置类的importBeanDefinitionRegistrars属性中。
                 * */
                if (candidate.isAssignable(ImportSelector.class)) {
                    // Candidate class is an ImportSelector -> delegate to it to determine imports
                    Class<?> candidateClass = candidate.loadClass();
                    ImportSelector selector = ParserStrategyUtils.instantiateClass(candidateClass, ImportSelector.class,
                            this.environment, this.resourceLoader, this.registry);
                    Predicate<String> selectorFilter = selector.getExclusionFilter();
                    if (selectorFilter != null) {
                        exclusionFilter = exclusionFilter.or(selectorFilter);
                    }
                    // SpringBootDemo中使用的是@SpringBootApplication，该注解包含@EnableAutoConfiguration，
                    // @EnableAutoConfiguration中有@Import(AutoConfigurationImportSelector.class)
                    if (selector instanceof DeferredImportSelector) {
                    // 这一步实际上是将 configClass 和 selector 保存到了一个集合(deferredImportSelectors)中，集合(deferredImportSelectors)标记着待处理的selector
                        this.deferredImportSelectorHandler.handle(configClass, (DeferredImportSelector) selector);
                    }
                    else {
                        String[] importClassNames = selector.selectImports(currentSourceClass.getMetadata());
                        Collection<SourceClass> importSourceClasses = asSourceClasses(importClassNames, exclusionFilter);
                        processImports(configClass, currentSourceClass, importSourceClasses, exclusionFilter, false);
                    }
                }
                else if (candidate.isAssignable(ImportBeanDefinitionRegistrar.class)) {
                    // Candidate class is an ImportBeanDefinitionRegistrar ->
                    // delegate to it to register additional bean definitions
                    Class<?> candidateClass = candidate.loadClass();
                    ImportBeanDefinitionRegistrar registrar =
                            ParserStrategyUtils.instantiateClass(candidateClass, ImportBeanDefinitionRegistrar.class,
                                    this.environment, this.resourceLoader, this.registry);
                    configClass.addImportBeanDefinitionRegistrar(registrar, currentSourceClass.getMetadata());
                }
                else {
                    // Candidate class not an ImportSelector or ImportBeanDefinitionRegistrar ->
                    // process it as an @Configuration class
                    this.importStack.registerImport(
                            currentSourceClass.getMetadata(), candidate.getMetadata().getClassName());
                    processConfigurationClass(candidate.asConfigClass(configClass), exclusionFilter);
                }
            }
        }
        catch (BeanDefinitionStoreException ex) {
            throw ex;
        }
        catch (Throwable ex) {
            throw new BeanDefinitionStoreException(
                    "Failed to process import candidates for configuration class [" +
                    configClass.getMetadata().getClassName() + "]", ex);
        }
        finally {
            this.importStack.pop();
        }
    }
}

// 上述 this.deferredImportSelectorHandler.handle(configClass, (DeferredImportSelector) selector);
// 调用的就是：DeferredImportSelectorHandler#handle方法
// configClass 是持有该@Import注解的配置类，importSelector是引入的DeferredImportSelector
// 具体到这里就是configClass就是SpringBootDemo类，importSelector就是AutoConfigurationImportSelector类
public void handle(ConfigurationClass configClass, DeferredImportSelector importSelector) {
    // 将 DeferredImportSelector和其引入的配置类保存起来。
    DeferredImportSelectorHolder holder = new DeferredImportSelectorHolder(configClass, importSelector);
    // 如果deferredImportSelectors 为空，则重新注册
    if (this.deferredImportSelectors == null) {
        DeferredImportSelectorGroupingHandler handler = new DeferredImportSelectorGroupingHandler();
        handler.register(holder);
        handler.processGroupImports();
    }
    else {
        // 将当前的 config 和 Selector 的持有者保存起来
        this.deferredImportSelectors.add(holder);
    }
}

private class DeferredImportSelectorGroupingHandler {

    private final Map<Object, DeferredImportSelectorGrouping> groupings = new LinkedHashMap<>();

    private final Map<AnnotationMetadata, ConfigurationClass> configurationClasses = new HashMap<>();

    // 这个deferredImport就是AutoConfigurationImportSelector
    public void register(DeferredImportSelectorHolder deferredImport) {
        // 这里group就是AutoConfigurationGroup.class
        Class<? extends Group> group = deferredImport.getImportSelector().getImportGroup();
        DeferredImportSelectorGrouping grouping = this.groupings.computeIfAbsent(
                (group != null ? group : deferredImport),
                key -> new DeferredImportSelectorGrouping(createGroup(group)));
        grouping.add(deferredImport);
        this.configurationClasses.put(deferredImport.getConfigurationClass().getMetadata(),
                deferredImport.getConfigurationClass());
    }

    public void processGroupImports() {
        for (DeferredImportSelectorGrouping grouping : this.groupings.values()) {
            Predicate<String> exclusionFilter = grouping.getCandidateFilter();
            grouping.getImports().forEach(entry -> {
                ConfigurationClass configurationClass = this.configurationClasses.get(entry.getMetadata());
                try {
                    processImports(configurationClass, asSourceClass(configurationClass, exclusionFilter),
                            Collections.singleton(asSourceClass(entry.getImportClassName(), exclusionFilter)),
                            exclusionFilter, false);
                }
                catch (BeanDefinitionStoreException ex) {
                    throw ex;
                }
                catch (Throwable ex) {
                    throw new BeanDefinitionStoreException(
                            "Failed to process import candidates for configuration class [" +
                                    configurationClass.getMetadata().getClassName() + "]", ex);
                }
            });
        }
    }

    private Group createGroup(@Nullable Class<? extends Group> type) {
        Class<? extends Group> effectiveType = (type != null ? type : DefaultDeferredImportSelectorGroup.class);
        return ParserStrategyUtils.instantiateClass(effectiveType, Group.class,
                ConfigurationClassParser.this.environment,
                ConfigurationClassParser.this.resourceLoader,
                ConfigurationClassParser.this.registry);
    }
}
```

总结：
从processConfigBeanDefinitions()方法执行开始说起：
- 首先把配置类SpringBootDemo.class类转化后的的BeanDefinition标记为Full还是Lite
- 然后第一次进入到parser.parse()方法时，参数只有一个配置类SpringBootDemo.class
- 接着调用parser.parse(SpringBootDemo.class)开始扫描，此处是个循环
- 接着调用doProcessConfigurationClass()方法，被递归调用
- 在这个方法中，先处理@PropertySource注解
- 接着处理@ComponentScan注解，把扫描到的类符合条件的放入到集合中，遍历这个结合，再次调用parse()扫描方法。此处扫描出来的类，会被转化为BeanDefinition，然后放入到bdMap中
- 接着处理@Import注解，分4种情况：
    1. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportSelector类型且是DeferredImportSelector类型：表示推迟的ImportSelector，它会在当前配置类所属的批次中所有配置类都解析完了之后执行。
    2. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportSelector类型且是普通ImportSelector类型：把selectImports()方法所返回的类再次调用processImports()进行递归处理。
    3. 配置类上是否有@Import、调用processImports()处理所导入的类、是ImportBeanDefinitionRegistrar类型：将ImportBeanDefinitionRegistrar实例对象添加到当前配置类的importBeanDefinitionRegistrars属性中。
    4. 配置类上是否有@Import、调用processImports()处理所导入的类不是以上三种类型，作为普通的configuration类处理，调用processConfigurationClass
- 接着处理@ImportResource注解，将所导入的xml文件路径添加到当前配置类的importedResources属性中。
- 接着处理处理单个的@Bean方法， 将@Bean修饰的方法封装为BeanMethod对象，并添加到当前配置类的beanMethods属性中。
- 把配置类的父类当作配置类进行解析

DeferredImportSelector接口是ImportSelector接口的一个扩展；
- ImportSelector实例的selectImports方法的执行时机，是在@Configguration注解中的其他逻辑被处理之前，所谓的其他逻辑，包括对@ImportResource、@Bean这些注解的处理（注意，这里只是对@Bean修饰的方法的处理，并不是立即调用@Bean修饰的方法，这个区别很重要！）；
- DeferredImportSelector实例的selectImports方法的执行时机，是在@Configguration注解中的其他逻辑被处理完毕之后，所谓的其他逻辑，包括对@ImportResource、@Bean这些注解的处理；
- DeferredImportSelector的实现类可以用Order注解，或者实现Ordered接口来对selectImports的执行顺序排序

# postProcessBeanFactory
```java
public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    int factoryId = System.identityHashCode(beanFactory);
    if (this.factoriesPostProcessed.contains(factoryId)) {
        throw new IllegalStateException(
                "postProcessBeanFactory already called on this post-processor against " + beanFactory);
    }
    this.factoriesPostProcessed.add(factoryId);
    if (!this.registriesPostProcessed.contains(factoryId)) {
        // BeanDefinitionRegistryPostProcessor hook apparently not supported...
        // Simply call processConfigurationClasses lazily at this point then.
        processConfigBeanDefinitions((BeanDefinitionRegistry) beanFactory);
    }

    enhanceConfigurationClasses(beanFactory);
    // 添加BeanPostProcessor
    beanFactory.addBeanPostProcessor(new ImportAwareBeanPostProcessor(beanFactory));
}

// Spring会对Full Configuration进行代理，拦截@Bean方法，以确保正确处理@Bean语义。
// 这个增强的代理类就是在enhanceConfigurationClasses(beanFactory)方法中产生的，源码如下：
public void enhanceConfigurationClasses(ConfigurableListableBeanFactory beanFactory) {
    StartupStep enhanceConfigClasses = this.applicationStartup.start("spring.context.config-classes.enhance");
    Map<String, AbstractBeanDefinition> configBeanDefs = new LinkedHashMap<>();
    //获取所有的BeanDefinitionName,之前已经完成了bean的扫描,这里会获取到所有的beanName
    for (String beanName : beanFactory.getBeanDefinitionNames()) {
        BeanDefinition beanDef = beanFactory.getBeanDefinition(beanName);
        Object configClassAttr = beanDef.getAttribute(ConfigurationClassUtils.CONFIGURATION_CLASS_ATTRIBUTE);
        AnnotationMetadata annotationMetadata = null;
        MethodMetadata methodMetadata = null;
        if (beanDef instanceof AnnotatedBeanDefinition) {
            AnnotatedBeanDefinition annotatedBeanDefinition = (AnnotatedBeanDefinition) beanDef;
            annotationMetadata = annotatedBeanDefinition.getMetadata();
            methodMetadata = annotatedBeanDefinition.getFactoryMethodMetadata();
        }
        if ((configClassAttr != null || methodMetadata != null) && beanDef instanceof AbstractBeanDefinition) {
            // Configuration class (full or lite) or a configuration-derived @Bean method
            // -> eagerly resolve bean class at this point, unless it's a 'lite' configuration
            // or component class without @Bean methods.
            AbstractBeanDefinition abd = (AbstractBeanDefinition) beanDef;
            if (!abd.hasBeanClass()) {
                boolean liteConfigurationCandidateWithoutBeanMethods =
                        (ConfigurationClassUtils.CONFIGURATION_CLASS_LITE.equals(configClassAttr) &&
                            annotationMetadata != null && !ConfigurationClassUtils.hasBeanMethods(annotationMetadata));
                if (!liteConfigurationCandidateWithoutBeanMethods) {
                    try {
                        abd.resolveBeanClass(this.beanClassLoader);
                    }
                    catch (Throwable ex) {
                        throw new IllegalStateException(
                                "Cannot load configuration class: " + beanDef.getBeanClassName(), ex);
                    }
                }
            }
        }
        // 校验是否为FullConfigurationClass,也就是是否被标记了 @Configuration
        if (ConfigurationClassUtils.CONFIGURATION_CLASS_FULL.equals(configClassAttr)) {
            if (!(beanDef instanceof AbstractBeanDefinition)) {
                throw new BeanDefinitionStoreException("Cannot enhance @Configuration bean definition '" +
                        beanName + "' since it is not stored in an AbstractBeanDefinition subclass");
            }
            else if (logger.isInfoEnabled() && beanFactory.containsSingleton(beanName)) {
                logger.info("Cannot enhance @Configuration bean definition '" + beanName +
                        "' since its singleton instance has been created too early. The typical cause " +
                        "is a non-static @Bean method with a BeanDefinitionRegistryPostProcessor " +
                        "return type: Consider declaring such methods as 'static'.");
            }
            //如果是FullConfigurationClass,则放到变量configBeanDefs中
            configBeanDefs.put(beanName, (AbstractBeanDefinition) beanDef);
        }
    }
    if (configBeanDefs.isEmpty() || NativeDetector.inNativeImage()) {
        // nothing to enhance -> return immediately
        enhanceConfigClasses.end();
        return;
    }

    ConfigurationClassEnhancer enhancer = new ConfigurationClassEnhancer();
    for (Map.Entry<String, AbstractBeanDefinition> entry : configBeanDefs.entrySet()) {
        AbstractBeanDefinition beanDef = entry.getValue();
        // If a @Configuration class gets proxied, always proxy the target class
        beanDef.setAttribute(AutoProxyUtils.PRESERVE_TARGET_CLASS_ATTRIBUTE, Boolean.TRUE);
        // Set enhanced subclass of the user-specified bean class
        Class<?> configClass = beanDef.getBeanClass();
        // 对 FullConfigurationClass 进行增强
        Class<?> enhancedClass = enhancer.enhance(configClass, this.beanClassLoader);
        if (configClass != enhancedClass) {
            if (logger.isTraceEnabled()) {
                logger.trace(String.format("Replacing bean definition '%s' existing class '%s' with " +
                        "enhanced class '%s'", entry.getKey(), configClass.getName(), enhancedClass.getName()));
            }
            // 将增强的class设置到BeanDefinition中
            beanDef.setBeanClass(enhancedClass);
        }
    }
    enhanceConfigClasses.tag("classCount", () -> String.valueOf(configBeanDefs.keySet().size())).end();
}

public Class<?> enhance(Class<?> configClass, @Nullable ClassLoader classLoader) {
    if (EnhancedConfiguration.class.isAssignableFrom(configClass)) {
        if (logger.isDebugEnabled()) {
            logger.debug(String.format("Ignoring request to enhance %s as it has " +
                    "already been enhanced. This usually indicates that more than one " +
                    "ConfigurationClassPostProcessor has been registered (e.g. via " +
                    "<context:annotation-config>). This is harmless, but you may " +
                    "want check your configuration and remove one CCPP if possible",
                    configClass.getName()));
        }
        return configClass;
    }
    Class<?> enhancedClass = createClass(newEnhancer(configClass, classLoader));
    if (logger.isTraceEnabled()) {
        logger.trace(String.format("Successfully enhanced %s; enhanced class name is: %s",
                configClass.getName(), enhancedClass.getName()));
    }
    return enhancedClass;
}
// 这里的Enhancer对象是org.springframework.cglib.proxy.Enhancer，那它和cglib是什么关系呢？
// Spring重新打包了CGLIB（使用Spring专用补丁，仅供内部使用） ，这样可避免在应用程序级别或第三方库和框架上与CGLIB的依赖性发生任何潜在冲突。
// 那具体做了哪些增强呢:
// 1. 实现EnhancedConfiguration接口。这是一个空的标志接口，仅由Spring框架内部使用，并且由所有@ConfigurationCGLIB子类实现，该接口继承了BeanFactoryAware接口。
// 2. 设置了命名策略
// 3. 设置生成器创建字节码的策略。BeanFactoryAwareGeneratorStrategy继承了cglib的DefaultGeneratorStrategy，其主要作用是为了让子类引入BeanFactory字段和设置ClassLoader
// 4. 设置增强Callback
private Enhancer newEnhancer(Class<?> configSuperClass, @Nullable ClassLoader classLoader) {
	// Spring重新打包了CGLIB（使用Spring专用补丁;仅供内部使用）
	// 这样可避免在应用程序级别或第三方库和框架上与CGLIB的依赖性发生任何潜在冲突
	// https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/cglib/package-summary.html
	Enhancer enhancer = new Enhancer();
	enhancer.setSuperclass(configSuperClass);
	// 设置需要实现的接口,也就是说,我们的配置类的cglib代理还实现的 EnhancedConfiguration 接口
	enhancer.setInterfaces(new Class<?>[]{EnhancedConfiguration.class});
	enhancer.setUseFactory(false);
	// 设置命名策略
	enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
	// 设置生成器创建字节码策略
	// BeanFactoryAwareGeneratorStrategy 是 CGLIB的DefaultGeneratorStrategy的自定义扩展，主要为了引入BeanFactory字段
	enhancer.setStrategy(new BeanFactoryAwareGeneratorStrategy(classLoader));
	// 设置增强
    // private static final ConditionalCallbackFilter CALLBACK_FILTER = new ConditionalCallbackFilter(CALLBACKS);
	enhancer.setCallbackFilter(CALLBACK_FILTER);
	enhancer.setCallbackTypes(CALLBACK_FILTER.getCallbackTypes());
	return enhancer;
}

private static final Callback[] CALLBACKS = new Callback[]{
		// 拦截 @Bean 方法的调用,以确保正确处理@Bean语义
        // 负责拦截@Bean方法的调用，以确保正确处理@Bean语义。
		new BeanMethodInterceptor(),
		// 拦截 BeanFactoryAware#setBeanFactory 的调用
        // 负责拦截 BeanFactoryAware#setBeanFactory方法的调用，因为增强的配置类实现了EnhancedConfiguration接口（也就是实现了BeanFactoryAwar接口）。
		new BeanFactoryAwareMethodInterceptor(),
		NoOp.INSTANCE
};

//BeanMethodInterceptor#intercept源码:作用：
// 1. enhancedConfigInstance是配置类的增强对象。从增强对象中获取beanFactory和beanName。举个例子：当Spring调用name()方法时，beanName就是name。
// 2. 检查容器中是否存在对应的FactoryBean，如果存在，则创建一个增强类，来代理getObject()的调用。在本示例中，如果读者将name()方法注释删掉之后程序并不会执行到这一步。因为Spring调用getUserBean()方法时，容器中并没有存在对应的FactoryBean。因为只有第二次调用getUserBean()方法容器中才会存在对应的FactoryBean。
// 3. 判断当时执行的方法是否为@Bean方法本身，如果是，则直接调用该方法，不做增强拦截；否则，则尝试从容器中获取该Bean对象。
public Object intercept(Object enhancedConfigInstance, Method beanMethod, Object[] beanMethodArgs,
                    MethodProxy cglibMethodProxy) throws Throwable {

// enhancedConfigInstance 已经是配置类的增强对象了,在增强对象中,有beanFactory字段的
// 获取增强对象中的beanFactory
ConfigurableBeanFactory beanFactory = getBeanFactory(enhancedConfigInstance);
// 获取beanName
String beanName = BeanAnnotationHelper.determineBeanNameFor(beanMethod);

// Determine whether this bean is a scoped-proxy
if (BeanAnnotationHelper.isScopedProxy(beanMethod)) {
    String scopedBeanName = ScopedProxyCreator.getTargetBeanName(beanName);
    if (beanFactory.isCurrentlyInCreation(scopedBeanName)) {
        beanName = scopedBeanName;
    }
}

// To handle the case of an inter-bean method reference, we must explicitly check the
// container for already cached instances.

// First, check to see if the requested bean is a FactoryBean. If so, create a subclass
// proxy that intercepts calls to getObject() and returns any cached bean instance.
// This ensures that the semantics of calling a FactoryBean from within @Bean methods
// is the same as that of referring to a FactoryBean within XML. See SPR-6602.

// 检查容器中是否存在对应的 FactoryBean 如果存在,则创建一个增强类
// 通过创建增强类来代理拦截 getObject（）的调用 , 以确保了FactoryBean的语义
if (factoryContainsBean(beanFactory, BeanFactory.FACTORY_BEAN_PREFIX + beanName) &&
        factoryContainsBean(beanFactory, beanName)) {
    Object factoryBean = beanFactory.getBean(BeanFactory.FACTORY_BEAN_PREFIX + beanName);
    if (factoryBean instanceof ScopedProxyFactoryBean) {
        // Scoped proxy factory beans are a special case and should not be further proxied
    } else {
        // It is a candidate FactoryBean - go ahead with enhancement
        // 创建增强类,来代理 getObject（）的调用
        // 有两种可选代理方式,cglib 和 jdk
        // Proxy.newProxyInstance(
        //					factoryBean.getClass().getClassLoader(), new Class<?>[]{interfaceType},
        //					(proxy, method, args) -> {
        //						if (method.getName().equals("getObject") && args == null) {
        //							return beanFactory.getBean(beanName);
        //						}
        //						return ReflectionUtils.invokeMethod(method, factoryBean, args);
        //					});
        return enhanceFactoryBean(factoryBean, beanMethod.getReturnType(), beanFactory, beanName);
    }
}

// 判断当时执行的方法是否为@Bean方法本身
// 举个例子 : 如果是直接调用@Bean方法,也就是Spring来调用我们的@Bean方法,则返回true
// 如果是在别的方法内部,我们自己的程序调用 @Bean方法,则返回false
if (isCurrentlyInvokedFactoryMethod(beanMethod)) {
    // The factory is calling the bean method in order to instantiate and register the bean
    // (i.e. via a getBean() call) -> invoke the super implementation of the method to actually
    // create the bean instance.
    // 如果返回true,也就是Spring在调用这个方法,那么就去真正执行该方法
    return cglibMethodProxy.invokeSuper(enhancedConfigInstance, beanMethodArgs);
}

//否则,则尝试从容器中获取该 Bean 对象
// 怎么获取呢? 通过调用 beanFactory.getBean 方法
// 而这个getBean 方法,如果对象已经创建则直接返回,如果还没有创建,则创建,然后放入容器中,然后返回
return resolveBeanReference(beanMethod, beanMethodArgs, beanFactory, beanName);
}

// BeanFactoryAwareMethodInterceptor#intercept源码:作用：
// BeanFactoryAwareMethodInterceptor方法就比较简单，其作用为拦截 BeanFactoryAware#setBeanFactory的调用，用于获取BeanFactory对象。
public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
    Field field = ReflectionUtils.findField(obj.getClass(), BEAN_FACTORY_FIELD);
    Assert.state(field != null, "Unable to find generated BeanFactory field");
    field.set(obj, args[0]);

    // Does the actual (non-CGLIB) superclass implement BeanFactoryAware?
    // If so, call its setBeanFactory() method. If not, just exit.
    if (BeanFactoryAware.class.isAssignableFrom(ClassUtils.getUserClass(obj.getClass().getSuperclass()))) {
        return proxy.invokeSuper(obj, args);
    }
    return null;
}

private Class<?> createClass(Enhancer enhancer) {
    Class<?> subclass = enhancer.createClass();
    // Registering callbacks statically (as opposed to thread-local)
    // is critical for usage in an OSGi environment (SPR-5932)...
    Enhancer.registerStaticCallbacks(subclass, CALLBACKS);
    return subclass;
}

public Class createClass() {
    classOnly = true;
    return (Class) createHelper();
}

private Object createHelper() {
    preValidate();
    Object key = KEY_FACTORY.newInstance((superclass != null) ? superclass.getName() : null,
            ReflectUtils.getNames(interfaces),
            filter == ALL_ZERO ? null : new WeakCacheKey<CallbackFilter>(filter),
            callbackTypes,
            useFactory,
            interceptDuringConstruction,
            serialVersionUID);
    this.currentKey = key;
    Object result = super.create(key);
    return result;
}

protected Object create(Object key) {
    try {
        ClassLoader loader = getClassLoader();
        Map<ClassLoader, ClassLoaderData> cache = CACHE;
        ClassLoaderData data = cache.get(loader);
        if (data == null) {
            synchronized (AbstractClassGenerator.class) {
                cache = CACHE;
                data = cache.get(loader);
                if (data == null) {
                    Map<ClassLoader, ClassLoaderData> newCache = new WeakHashMap<ClassLoader, ClassLoaderData>(cache);
                    data = new ClassLoaderData(loader);
                    newCache.put(loader, data);
                    CACHE = newCache;
                }
            }
        }
        this.key = key;
        Object obj = data.get(this, getUseCache());
        if (obj instanceof Class) {
            return firstInstance((Class) obj);
        }
        return nextInstance(obj);
    }
    catch (RuntimeException | Error ex) {
        throw ex;
    }
    catch (Exception ex) {
        throw new CodeGenerationException(ex);
    }
}
```
> https://cloud.tencent.com/developer/article/1555438