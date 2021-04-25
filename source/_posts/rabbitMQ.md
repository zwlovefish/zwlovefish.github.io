---
title: rabbitMQ
date: 2020-12-28 22:29:25
tags: rabbitMQ
categories: 分布式
---
消息队列中间件 (Message Queue Middleware，简称为 MQ) 是指利用高效可靠的消息传递 机制进行与平台无关的数据交流，并基于数据通信来进行分布式系统的集成。通过提供消息传 递和消息排队模型，它可以在分布式环境下扩展进程间的通信。
<!-- more-->
消息队列中间件，也可以称为消息队列或者消息中间件。它一般有两种传递模式：点对点
(P2P, Point-to-Point)模式和发布/订阅(Pub/Sub)模式。点对点模式是基于队列的，消息生产者发送消息到队列，消息消费者从队列中接收消息，队列的存在使得消息的异步传输成为可能。 发布订阅模式定义了如何向一个内容节点发布和订阅消息，这个内容节点称为主题 (topic)，主 题可以认为是消息传递的中介，消息发布者将消息发布到某个主题，而消息订阅者则从主题中 订阅消息。主题使得消息的订阅者与消息的发布者互相保持独立，不需要进行接触即可保证消 息的传递，发布/订阅模式在消息的一对多广播时采用。

# 消息中间件的作用
- **解辑** 在项目启动之初来预测将来会碰到什么需求是极其困难的。消息中间件在处理过程中间插入了一个隐含的、基于数据的接口层，两边的处理过程都要实现这一接口，这允许你独立地扩展或修改两边的处理过程，只要确保它 们遵守同样的接口约束即可。
- **冗余(存储)** 有些情况下，处理数据的过程会失败。消息中间件可以把数据进行持久化直到它们已经被完全处理，通过这一方式规避了数据丢失风险。在把一个消息从消息中间件中删除之前，需要你的处理系统明确地指出该消息己经被处理完成，从而确保你的数据被安全地保存直到你使用完毕。
- **扩展性** 因为消息中间件解捐了应用的处理过程，所以提高消息入队和处理的效率是很容易的，只要另外增加处理过程即可，不需要改变代码，也不需要调节参数。
- **削峰** 在访问量剧增的情况下，应用仍然需要继续发挥作用，但是这样的突发流量并不常见。如果以能处理这类峰值为标准而投入资源，无疑是巨大的浪费。使用消息中间件能够使关键组件支撑突发访问压力，不会因为突发的超负荷请求而完全崩惯。
- **可恢复性** 当系统一部分组件失效时，不会影响到整个系统。消息中间件降低了进程间的稿合度，所以即使一个处理消息的进程挂掉，加入消息中间件中的消息仍然可以在系统恢复后进行处理。
- **顺序保证** 在大多数使用场景下，数据处理的顺序很重要，大部分消息中间件支持一定程度上的顺序性。
- **缓冲** 在任何重要的系统中，都会存在需要不同处理时间的元素。消息中间件通过 一个缓 冲层来帮助任务最高效率地执行，写入消息中间件的处理会尽可能快速。该缓冲层有助于控制和优化数据流经过系统的速度。
- **异步通信** 在很多时候应用不想也不需要立即处理消息。消息中间件提供了异步处理机制，允许应用把一些消息放入消息中间件中，但并不立即处理它，在之后需要的时候再慢慢处理。

# RabbitMQ的特点
- **可靠性** RabbitMQ使用一些机制来保证可靠性，如持久化、传输确认及发布确认等。
- **灵活的路由** 在消息进入队列之前，通过交换器来路由消息。对于典型的路由功能，RabbitMQ己经提供了一些内置的交换器来实现。针对更复杂的路由功能，可以将多个交换器绑定在一起， 也可以通过插件机制来实现自己的交换器。
- **扩展性** 多个RabbitMQ节点可以组成一个集群，也可以根据实际业务情况动态地扩展集群中节点。
- **高可用性** 队列可以在集群中的机器上设置镜像，使得在部分节点出现问题的情况下队列仍然可用。
- **多种协议** RabbitMQ除了原生支持AMQP协议，还支持STOMP，MQTT等多种消息中间件协议。
- **多语言客户端** RabbitMQ几乎支持所有常用语言，比如 Java、 Python、 Ruby、 PHP、 C#、 JavaScript 等。
- **管理界面** RabbitMQ提供了一个易用的用户界面，使得用户可以监控和管理消息、集群中的节点等。
- **插件机制** RabbitMQ 提供了许多插件，以实现从多方面进行扩展，当然也可以编写自 己的插件。

# 安装自行百度
要说明的是RabbitMQ的默认的guest无法进行远程登录，所以需要添加其他用户，这里我用user = root, password = root
```SHELL
//添加新用户，账号和密码都是root
# rabbitmqctl add_user root root 
//为root用户设置所有权限
# rabbitmqctl set_permissions -p / root ".*" ".*" ".*"
//设置root用户为管理员角色
# rabbitmqctl set_user_tags root administrator
```

# 生产者代码
```java
package com.zhou;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.MessageProperties;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

public class RabbitProducer {
    private static final String EXCHANGE_NAME = "exchange_demo";
    private static final String ROUTING_KEY = "routingkey_demo";
    private static final String QUEUE_NAME = "queue_demo";
    private static final String IP_ADDRESS = "127.0.0.1";
    // RabbitMQ服务端默认端口为5672
    private static final int PORT = 5672;

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost(IP_ADDRESS);
        factory.setPort(PORT);
        factory.setUsername("root");
        factory.setPassword("root");

        // 创建连接
        Connection connection = factory.newConnection();
        // 创建信道
        Channel channel = connection.createChannel();
        // 创建一个type为direct，持久化的，非自动删除的交换器
        channel.exchangeDeclare(EXCHANGE_NAME,"direct",true,false,null);
        // 创建一个持久化，非排他的，非自动删除的队列
        channel.queueDeclare(QUEUE_NAME,true,false,false,null);
        // 将交换器与队列通过路由键绑定
        channel.queueBind(QUEUE_NAME,EXCHANGE_NAME,ROUTING_KEY);
        // 发送一条持久化的消息:hello world
        String message = "hello world";
        channel.basicPublish(EXCHANGE_NAME,ROUTING_KEY,
                MessageProperties.PERSISTENT_TEXT_PLAIN,message.getBytes());

        // 关闭资源
        channel.close();
        connection.close();


    }
}

```

# 消费者代码
```java
package com.zhou;

import com.rabbitmq.client.*;

import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class RabbitConsumer {
    private static final String QUEUE_NAME = "queue_demo";
    private static final String IP_ADDRESS = "127.0.0.1";
    private static final int PORT = 5672;

    public static void main(String[] args) throws IOException, TimeoutException, InterruptedException {
        Address[] addresses = new Address[]{
                new Address(IP_ADDRESS,PORT)
        };
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUsername("root");
        factory.setPassword("root");
        // 这里连接方式与生产者的demo略有不同,注意辨别区别
        // 创建连接
        Connection connection = factory.newConnection(addresses);
        // 创建信道
        final Channel channel = connection.createChannel();
        // 设置客户端最多接收未被ack的消息的个数
        channel.basicQos(64);
        Consumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope,
                                       AMQP.BasicProperties properties, byte[] body)
                    throws IOException{
                System.out.println("recv Message: "+new String(body));
                try {
                    TimeUnit.SECONDS.sleep(1);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                channel.basicAck(envelope.getDeliveryTag(),false);
            }
        };
        channel.basicConsume(QUEUE_NAME,consumer);
        // 等待回调函数执行完毕之后，关闭资源
        TimeUnit.SECONDS.sleep(5);
        connection.close();
    }
}
```


