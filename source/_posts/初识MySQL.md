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
|:--:|:--:|:--:|
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

# InnoDB存储结构
## InnoDB页
内存与磁盘的读写速度差了几个数量级，因此InnoDB采取的方式是将数据分为若干个页，以页为单位进行读取，页的大小一般为16KB，一次最少从磁盘上读取16KB的内容到内存，一次最少把内存中的16KB内容刷到磁盘上。

系统变量innodb_page_size表明了InnoDB存储引擎的也大小，默认值为16384(16KB)。该变量只能在第一次初始化MySQL数据目录时指定，之后就不能更改了，通过命令mysqld --initialize来初始化数据目录。
## InnoDB行结构
有4中行格式：Compact、Redundant、Dynamic和Comprssed行格式
### 指定行结构语法
```shell
CREATE TABLE 表名 (列的信息) ROW_FORMAT=行格式名称
ALTER TABLE 表名 ROW_FORMAT=行格式名称
```
### COMPACT行格式
![Compact的行格式图](Compact的行格式图.png)
- **变长字段列表**
MySQL支持一些变长的数据类型，例如varchar,varbinary等，这些字段称为变长字段。这些变长字段存储的长度不是固定的，所以MySQL在存储时需要把这些字段存起来。也就是说变长字段存储的空间分为2部分，一部分是真实数据存储在记录的真实数据中，一部分是该数据的占用的字节数，存储在记录的额外信息的变长字段长度列表中。所有变长字段的真实数据所占用的字节数按照<font color='red'>逆序</font>记录在记录的额外信息中从而形成一个可变字段长度列表。例如记录'aaaa','bbb','cc','d'的可变长列表就是01 02 03 04。
如何确认是按照1字节还是2字节来表示一个变长字段的真实数据所占用的字节数呢？如果该变长字段允许的最大字节数超过255字节，则根据真实的长度(L)来计算，如果L超过127字节则使用2字节来表示，否则使用1字节
- **NULL值列表**
首先统计表中允许存储NULL的列有哪些，如果表中没有允许存储NULL的列，那么NULL值列表也就不存在了。否则的话，每个允许存储NULL的列也是按照<font color="red">逆序</font>对应一个比特位，1代表NULL，0代表有值。如果允许存储NULL值的列的个数必须使用整数个字节数表示，例如如果有9个允许存储NULL的列，就需要使用2字节来表示了
- **记录头信息**
记录头信息由固定的5个字节40个比特位组成，记录头信息的40个比特位也叫做info bit。具体如下表所示：

    |名称|大小(位)|描述|
    |:-:|:-:|:-:|
    |预留位 1|1|没有使用|
    |预留位 2|1|没有使用|
    |deleted_flag|1|标记该记录是否被删除|
    |min_rec_flag|1|B+数的每层非叶子节点中最小的目录项记录都会添加该标记|
    |n_owned|4|一个页面中的记录会被分成若干个小组，每个小组有一个记录是"带头大哥",其余的记录都是"小弟"，"带头大哥"记录的n_owned代表该组的所有记录条数，"小弟"的记录的o_owned为0|
    |heap_no|13|表示当前记录在页面堆中的相对位置|
    |record_type|3|表示记录的类型<br>0:普通记录<br>1:B+树非叶子节点的目录项记录<br>2:Infimum记录<br>3:Supremum记录
    |next_record|16|表示下一条记录的相对位置|
- 记录的真实数据
    MySQL会为每个记录默认的添加一些列，如下所示：
    |列名|是否必须|占用空间|描述|
    |:--:|:--:|:--|:--:|
    |row_id|否|6字节|行ID，唯一标识一条记录|
    |trx_id|是|6字节|事务ID|
    |roll_pointer|是|7字节|回滚指针|

    InnoDB的主键生成策略：优先使用用户自定义的主键，如果用户没有定义主键，则选取第一个不允许存储NULL值的UNIQUE键作为主键，如果以上都不满足，则InnoDB会为表添加一个默认的名为row_id的列作为主键。如果有满足的条件，它就不会被添加了。
- CHAR(M)列的存储格式
如果存储的编码集是固定长度的，则其属于可变长字段，否则属于可变长字段

### REDUNDANT行格式
![Redundant的行格式图](Redundant的行格式图.png)
- **字段长度偏移列表**
把一条记录的所有列(包括隐藏列)的长度信息按照<font color="red">逆序</font>存储到字段长度列表。长度信息是利用2个相邻偏移量的差值来计算各个列值的长度。例如25 24 1A 17 13 0C 06，因为它是按照逆序排放的，所以按照列的长度排列就是06 0C 13 17 1A 24 25,第一列6个字节，第二列0C-06=6个字节，第三列13-0C=7个字节，第四列17-13=4个字节，第五列1A-17=3个字节，第六列24-1A=10个字节，第七列25-25=1个字节
- **记录头信息**
    记录头信息占用6字节，共使用48个比特位
    |名称|大小(位)|描述|
    |:--:|:--:|:--:|
    |预留位 1|1|没有使用|
    |预留位 2|2|没有使用|
    |deleted_flag|1|标记该记录是否被删除|
    |min_rec_flag|1|B+树的每层非叶子节点中的最小的目录项记录都会添加该标记|
    |n_owned|4|一个页面中的记录会被分成若干个小组，每个小组有一个记录是"带头大哥",其余的记录都是"小弟"，"带头大哥"记录的n_owned代表该组的所有记录条数，"小弟"的记录的o_owned为0|
    |heap_no|13|表示当前记录在页面堆中的相对位置|
    |n_field|10|表示记录中列的数量|
    |1byte_offs_flag|1|标记字段长度偏移表中每个列对应的偏移量是使用1字节还是2字节表示的|
    |next_record|16|表示下一条记录的相对位置|

    1byte_offs_flag取值表示：1表示1字节存储偏移量，0表示2字节存储偏移量。当记录的真实数据占用的字节数不大于127时，1byte_offs_flag表示1字节；当记录的真实数据占用的字节数大于127(0x7f)，但是不大于32767(0x7fff)时，1byte_offs_flag表示2字节；当记录的真实数据大于32767(0x7fff)，此时记录的一部分已经存放到溢出页了，在本页中只保留前768字节和20字节的溢出页面地址，这种情况下使用2个字节来存储每个列对应的偏移量就够了。
- NULL值处理
将列偏移量的第一个比特位作为是否是NULL的依据。该比特位也被称为NULL比特位，如果为1，该列就是NULL，否则就不是NULL。就这是为什么大于127时使用2字节表示一个列对应的偏移量。如果NULL值的列时<font color="red">定长类型</font>，NULL值也将占用记录的真实数据部分例如C3列类型是VARCHAR(10)，1A A4，其对应的偏移量为A4，二进制为1010 0100，1代表NULL值，010 0100转为十进制就是36，1A转为十进制就是26,36-26=10；如果NULL值对应的列是<font color="red">变长类型</font>，则不在记录的真实数据部分占用任何存储空间，例如C4的类型为varchar,列的偏移量1A A4 A4,c4对应的偏移量为A4, A4-A4=0
- CHAR(M)列的存储格式
不管该列使用的字符集是啥，只要使用CHAR(M)类型，该列的真实数据占用的存储空间大小就是该字符集表示一个字符最多需要的字节数和M的乘积，例如CHAR(10),采用的编码是UTF8，则其真实数据占用的字节数就是3*10=30个字节
### 溢出列
![溢出列](溢出列.png)

在Compact和Redundant行格式中，对于占用存储空间非常多的列，在记录的真实数据处理只会存储该列的一部分数据，而把剩余的数据分散存储在几个其他的页中，然后在记录的真实数据处使用20字节存储这些页的地址，从而可以找到剩余数据所在的页。如果需要使用溢出页存储真实数据的列称为溢出列。

页空间的使用：
1. 每个页除了存放记录之外，还要存放一些其他额外的信息，这些信息加起来一共132个字节的空间
2. 每个记录需要的额外信息是27字节，这27个字节包括2个字节用于存储真实数据的长度，1个字节用于存储列是否是NULL值，5字节大小的头信息，6字节的row_id列，6字节的trx_id列，7字节的roll_pointer列。 
3. 存放正常记录的页和溢出页是2种不同类型的页面，对于溢出页来说就没有规定溢出页最少存放2个记录了
<font color="red">MySQL规定一个页中至少存储2行记录</font>。因此如果一个列不发生溢出，就需要满足如下等式：
132+2*(27+n) < 16384(16K)

### DYNAMIC行格式和COMPRESSED行格式
Dynamic行格式和Compressed行格式与Compact行格式很像，只不过在处理溢出列的数据时不同，他们不会在记录的真实数据处存储该溢出列真实数据的前768字节，而是把该列的所有真实数据存储到溢出页中。只在记录的真实数据处存储20字节大小的指向溢出页的地址。Compressed行格式与Dynamic行格式不同的地方在于Compressed行格式会采用压缩算法对页面进行压缩以节省空间。

