---
title: 初识MySQL
date: 2022-03-29 23:00:13
tags: 初识MySQL,MySQL文件
categories: MySQL
---
MySQL使用TCP作为MySQL服务器程序和客户端程序之间的网络通信协议。

# MySQL服务器启动脚本

**mysqld** 执行mysqld可以打开一个MySQL进程
**mysqld_safe** 执行mysqld_safe会间接调用mysqld，并监控其状态， 如果MySQL服务器出现错误，会重新启动服务器程序，并将出错信息打印到日志
**mysql.server** 间接调用mysqld_safe，执行**mysql.server start/stop**即可开启和关闭MySQL服务器程序。
**mysql_mysqld_muti** 可以在一台机器上启动多个MySQL服务器示例
![查询请求执行过程](查询请求执行过程.png)
<!--more-->

# 配置文件

配置文件位置，类Unix会按照如表1所示路径查找配置文件
表1：
|路径名|备注
|:--:|:--:|
|/etc/my.cnf||
|/etc/mysql/my.cnf||
|SYSCONFDIR/my.cnf||
|$MYSQL_HOME/my.cnf|特定与服务器的选项(仅限于服务器
|defaults-extra-file|命令行指定的额外配置文件路径|
|~/.my.cnf|特定于用户的选项|
|~/.mylogin.cnf|特定于用户的登录路径选项(仅限于客户端)|

**注意：**
1. SYSCONFDIR表示在使用CMake构建MySQL时使用SYSCONFDIR选项指定的目录
2. .mylogin.cnf不是一个纯文本文件，只能使用mysql_config_editor实用程序处理

## 配置文件的内容

配置文件中的等号左右可以有空白符，而命令行不行，命令行不能有空白符。
可以在选项组的名称后加上特定的版本号，这样只能由该版本的程序使用该选项组的选项。eg.[mysqld-5.7]这样，只有版本为5.7的mysqld才能使用该选项组的选项
[server]
(具体的启动选项)
eg. 
option1             #该选项不需要选项值
option2 = value2    #该选项需要选项值
[mysqld]
(具体的启动选项)
[mysqld_safe]
(具体的启动选项)
[client]
(具体的启动选项)
[mysql]
(具体的启动选项)
[mysqladmin]
(具体的启动选项)

[server]组里面的配置适用于所有的MySQL服务器程序
[client]组里面的配置适用于所有的client客户端程序

|程序名|类别|能读取的组|
|:--:|:--:|:--|
|mysqld|启动服务器|[mysqld]、[server]|
|mysqld_safe|启动服务器|[mysqld]、[server]、[mysqld_safe]|
|mysql.server|启动服务器|[mysqld]、[server]、[mysql.server]|
|mysql|启动客户端|[mysql]、[client]|
|mysqladmin|启动客户端|[mysqladmin]、[client]|
|mysqldump|启动客户端|[mysqldump]、[client]|

## 配置文件的优先级

**配置文件的优先级**:会按照表1的顺序依次读取各个配置文件。如果多个路径下的配置文件中含有相同的属性，以最后一个为准。eg.在/etc/my.cnf中配置了default-storage-engine=InnoDB，在~/.my.cnf中配置default-storage-engine=MyISAM。则以MyISAM为准。
**同配置文件多个组的优先级**:以最后一个组中的启动选项为准。eg.在/etc/my.cnf中出现
"配置文件与命令行的优先级":如果同一个选项出现在配置文件中和命令行中，则以命令行中的选项为准。
[server]
default-storeage-engine=InnDB
[client]
default-storeage-engine=MyISAM
则以MyISAM为准

<font color='red'>
default-extra-file和default-fifle分表表示额外配置和默认配置选项，只能用于命令行中
</font>

# 系统变量

1. 作用范围
    多个客户端程序可以连接同一个MySQL服务器程序。对于同一个系统变量，想让不同的客户端有不同的值，eg.客户端A想把default_storage_engine设置为MyISAM，客户端B想把default_storage_engine设置为InnoDB。MySQL有作用范围的概念——GLOBAL和SESSION。
    **GLOBAL**:影响MySQL服务器的整体操作
    **SESSION**:影响某个客户端连接的操作
    服务器启动时，会将每个全局系统变量初始化为其默认值。服务器还为每个客户端维护一组会话系统变量。客户端的会话变量在连接时使用相应全局系统变量的当前值进行初始化。
    eg.以default_storage_engine为例，MySQL服务器启动时会初始化一个名为default_storage_engine，作用范围为GLOBAL的系统变量，之后每当有客户端连接服务器时，服务器都会单独为该客户端分配一个名为default_storage_engine，作用范围为SESSION的系统变量，这个作用范围为SESSION的系统变量值按照当前作用范围为GLOBAL的同名系统变量值初始化而来。
2. 查看系统变量
    ```shell
    SHOW VARIABLES [LIKE 匹配模式]
    SHOW [GLOBAL|SESSION] VARIABLES [LIKE 匹配模式]
    ```

3. 设置方式
- 启动项设置
- 服务器程序运行时设置
    ```shell
    SET [GLOBAL|SESSION] 系统变量名 = 值。
    SET [@@(GLOBAL|SESSION).]系统变量名 = 值。
    ```
    eg.
    设置全局系统变量名
    SET GLOBAL default_storage_engine=InnoDB
    SET @@GLOBAL.default_storage_engine=InnoDB
    设置会话系统变量名
    SET SESSION default_storage_engine=InnoDB
    SET @@SESSION.default_storage_engine=InnoDB
    SET default_storage_engine=InnoDB # 由此可见默认的作用范围是SESSION

# 状态变量

MySQL服务器程序中维护了关于程序运行状态的变量，称为状态变量。比如Threads_connected等，由于状态变量是用来显示服务器程序运行状态的，所以他们的值只能由服务器程序自己设置，不能认为设置。与系统变量类似，状态变量也有GLOBAL和SESSION之分。
查看状态变量
```shell
SHOW [GLOBAL|SESSION] STATUS [LIKE 匹配模式]
```
如果不加修饰符，默认作用范围为SESSION

# 字符集和比较规则

## 查看和比较规则
```mysql
SHOW [CHARACTER SET|CHARSET] [LIKE 匹配规则] #字符集的查看
SHOW COLLATION [LIKE 匹配规则] #比较规则的查看
```
![比较规则名称后缀英文释义及描述](比较规则名称后缀英文释义及描述.png)
## MySQL的字符集与比较规则
每种字符集对应着若干比较规则。且每种字符集都有一种默认的比较规则
MySQL有4种级别的字符集和比较规则：
1. 服务器级别
character_set_server：表示服务器级别的字符集
collation_server:表示服务器级别的字符集
2. 数据库级别
character_set_database: 表示数据库级别的字符集
collation_database: 表示数据库级别的字符集
3. 表级别
    ```mysql
    # 创建时指定字符集和比较规则
    CREATE TABLE 表名 (
        列的信息
    ) [[DEFAULT] CHARACTER SET 字符集名称][COLLATION 比较规则名称]

    # 修改时指定字符集和比较规则
    ALTER TABLE 表名 [[DEFAULT] CHARACTER SET 字符集名称][COLLATION 比较规则]
    ```
4. 列级别
    ```mysql
    # 创建时指定字符集和比较规则
    CREATE TABLE 表名 (
        列名 字符串类型 [CHARACTER SET 字符集名称][COLLATION 比较规则]
    )

    # 修改时指定字符集和比较规则
    ALTER TABLE 表名 MODIFY 列名 字符串类型 [CHARACTER SET 字符集名称][COLLATION 比较规则]
    ```
    
如果查到的字符是乱码，可以查看**字符集**
如果ORDER BY 列名 排序的结果不是自己想要的，可以查看**比较规则**

**小结**
- 只修改字符集，则比较规则变为修改后字符集的默认比较规则
- 只修改规则，则字符集将变为修改后的比较规则对应的字符集
- 如果创建列时没有显示的指定字符集和比较规则，默认使用表的字符集和比较规则
- 如果创建表时没有显示的指定字符集和比较规则，默认使用数据库的字符集和比较规则
- 如果创建数据库时没有显示的指定字符集和比较规则，默认使用数据MySQL服务器程序的字符集和比较规则

## 客户端与服务器通信过程中使用的字符集
![client与server通信过程中使用的字符集](client与server通信过程中使用的字符集.png)

**补充说明**
- 1中默认是以操作系统的字符集对请求的字符串编码，在windows中如果指定default-character-set启动项，则以该启动项对请求编码，如果客户端不支持操作系统的字符集则按照mysql默认的字符集编码
- <font color='red'>3-4在书中没看懂啊。。。</font>
- character_set_client、character_set_connection、character_set_results均是session级别的，针对每个客户端的连接，服务器都会为该连接维护这三个变量