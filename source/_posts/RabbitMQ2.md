---
title: RabbitMQ入门
date: 2020-12-29 21:43:32
tags: rabbitMQ
categories: 分布式
---

RabbitMQ整体上是一个生产者和消费者模型，主要负责接收，存储和转发消息。
<!-- more -->
RabbitMQ的整体模型架构如图1所示：

![RabbitMQ的模型架构](RabbitMQ的模型架构.jpg)
<center>图1 RabbitMQ的模型架构</center>

# Producer
生产者创建消息，然后发布到RabbitMQ中。消息一般可以包含2个部分：消息体和标签(Label)。消息体也称之为payload，在实际应用中，消息体一般是一个带有业务逻辑结构的数据，比如一个JSON字符串。当然可以进一步对这个消息体进行序列化操作。消息的标签用来表述这条消息，比如一个交换器的名称和一个路由键。生产者把消息交由RabbitMQ，RabbitMQ之后会根据标签把消息发送给感兴趣的消费者

# Consumer
消费者连接到RabbitMQ服务器，并订阅到队列上。当消费者消费一条消息时，知识消费消息的消息体(payload)。在消息路由的过程中，消息的标签会被丢弃，存入到队列中的消息只有消息体，也就不知道消息的生产者是谁，当然消费者也不需要知道。

# Broker
对于RabbitMQ来说，一个RabbitMQ Broker可以简单地看做一个RabbitMQ服务节点或者RabbitMQ服务实例。大多数情况下也可以将一个RabbitMQ Broker看作一台RabbitMQ服务器。

# 

# 消息队列运转的过程
![消息队列的运转过程](消息队列运转的过程.jpg)

# 队列、绑定键、路由键、交换器之间的关系
![交换器路由键和绑定键以及队列](交换器路由键和绑定键以及队列.jpg)

# 交换器的类型
## fanout
它会把所有发送到该交换器的消息路由到所有与该交换器绑定的队列中

## direct
direct类型的交换器路由规则也很简单，它会把消息路由到那些BindingKey和RoutingKey完全匹配的队列中

## topic
direct类型的交换器是完全匹配BindingKey和RoutingKey，但是这种严格的匹配方式在很多情况下不能满足实际业务的需求。topic类型的交换器在匹配规则上进行了扩展，它与direct类型的交换器相似，也是将消息路由到BindingKey和RoutingKey相匹配的队列中，但是这里的匹配规则有些不同
- RoutingKey为一个”.“分隔的字符串，被”."分隔的字符叫单词，如 ”com.rabbitmq.client“
- BindingKey和RoutingKey一样也是”.“分隔的字符串
- BindingKey中可以存在2中特殊字符串"*"和"#"，用于做模糊匹配，其中"#"用于匹配一个单词，"#"用于匹配多规格单词(可以是0个)

# AMQP生产者流转过程
![AMQP生产者流转过程](AMQP生产者流转过程.jpg)
<center>图2 AMQP生产者流转过程</center>
当客户端与Broker建立连接时，会调用factory.newConnection方法，该方法会进一步封装成Protecol Header 0-9-1的报文头发送给Broker,以此通知Broker本次交互采用的是AMQP 0-9-1协议。

当客户端调用connection.createChannel方法准备开启信道的时候，其包装Channel.Open命令发送给Broker，等待Channel.Open-Ok命令

# AMQP消费者流转过程
![AMQP消费者流转过程](AMQP消费者流转过程.jpg)
<center>图3 AMQP消费者流转过程</center>
如果在消费之前调用了channel.basicQos(int prefetchCount)的方法来设置消费者客户端最大能”保持“的未确认的消息数，那么协议流转会涉及Basic.Qos/Basic.QOS-Ok这俩个AMPQ命令。

在真正消费之前，消费者客户端需要向Broker发送Basic.Consume命令(即调用channel.basicConsume方法)将Channel置位接收模式，之后Broker回执Basic.Consume-Ok以告诉消费者客户端准备好消费消息。紧接着Broker向消费者客户端推送(Push)消息，即Basic.Deliver命令，这个和Basic.Publish命令一样会携带Content Header和Content Body。

消费者接收到消息并正确消费之后，向Broker发送确认，即Basic.Ack命令


# API
<center>
```javascript
                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            佛祖保佑       永无BUG
```
</center>
fa fa-angle-left

