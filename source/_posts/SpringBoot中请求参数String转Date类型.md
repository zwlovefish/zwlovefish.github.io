---
title: SpringBoot中请求参数String转Date类型
date: 2020-07-14 23:37:34
tags: SpringBoot请求参数类型转换
categories: SpringBoot
---

# 问题描述
SpringBoot中请求时，当参数类型为Integer,String，Long等时会自动绑定参数。当Controller中为一个Entity时，会将请求中的参数一一对应到Entity的相应参数。而当Controller中的入参为Date时，请求中的参数为String。这俩个类型会导致映射失败。
<!-- more -->

一般的请求的url如下图所示：
![请求API](请求API.png)

Controller的入参形式如下所示：
```java
@RestController
public class DateController {
    @GetMapping(value = "/getDate")
    public void getDate(@RequestParam(value = "date") Date date){
        System.out.println(date);
    }
}
```

如果不做任何操作的话会报错：
```java
Failed to convert value of type 'java.lang.String' to required type 'java.util.Date'
```

# 解决办法是：
```java
@Configuration
public class DateConverter implements Converter<String, Date> {
    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    @Override
    public Date convert(String s) {
        if(s == null || s.equals(""))
            return null;
        try {
            Date transDate = simpleDateFormat.parse(s);
            return transDate;
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return null;
    }
}
```
<font color="red">springBoot会自动配置给转换器(其实这里我也不是很懂为什么会自动配置了。。。。。感觉是@Configuration注解的作用)。</font>

另外的方式是继承WebMvcConfigureAdapter。
```java
@Configuration
public class WebMvcConfig extends WebMvcConfigurerAdapter {
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverter(new DateConverter());
    }
}
```
这样就不需要在DateConverter类上加@Configuration注解了。




