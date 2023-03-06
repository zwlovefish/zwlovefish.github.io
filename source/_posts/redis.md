---
title: redis
date: 2023-03-06 12:49:13
tags: 面试 Redis
---

# redis的过期策略
1. 定时过期：每个设置过期时间的key都需要创建一个定时器，到过期时间就会立即清除
2. 惰性过期：只有当访问一个key时，才会判断该key是否已过期，过期则清除
3. 定期过期：每隔一定的时间，会扫描一定数量的数据库的expires字典中一定数量的key，并清除其中已过期的key

Redis 使用的过期删除策略是「惰性删除+定期删除」这两种策略配和使用。

# redis的淘汰策略
1. no-eviction：当内存不足以容纳新写入数据时，新写入操作会报错。
2. allkeys-lru：当内存不足以容纳新写入数据时，在键空间中，移除最近最少使用的key。
3. allkeys-random：当内存不足以容纳新写入数据时，在键空间中，随机移除某个key。
4. volatile-lru：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，移除最近最少使用的key。
5. volatile-random：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，随机移除某个key。
6. volatile-ttl：当内存不足以容纳新写入数据时，在设置了过期时间的键空间中，有更早过期时间的key优先移除。
7. volatile-lfu：淘汰所有设置了过期时间的键值中，最少使用的键值；

# Redis的持久化
AoF和RDB
## AOF
redis每执行一次写操作，就将其写入AOF文件。具体的就是：

1. redis每执行一次写命令，就将其写入aof_buf缓冲区，
2. 然后通过write()将其写入内核缓冲区，此时数据还没有写入硬盘
3. 具体什么时候写入硬盘由操作系统调用

redis提供了3种回写硬盘的机制：
1. always： 每次执行写操作，都会调用fsync将该写作写入硬盘
2. everysec： 每次执行写操作，redis服务器将内从写入aof_buf缓冲区，每秒调用fsync将内容写入硬盘
3. no：redis不控制写入硬盘的时机，又内核决定回写的时机

aof文件过大会触发重写机制：读取当前数据库中所有的键值对，然后使用一条命令将这些键值对写入新的aof文件，全部记录完时，就用新的aof文件替换掉老的aof文件。重写是通过创建子进程bgrewriteaof来完成的。这样做有2个好处
- 主进程可以继续处理命令，不用阻塞
- 使用子进程而不是线程的好处是，使用多线程，写数据到共享内存时需要加锁，降低性能，使用父子进程，父子进程的任何一方修改了内存，都会触发写时复制，于是父子进程间就会有各自独立的副本，不用加锁来保证安全。

以上redis通过设置一个aof重写缓冲区，这个缓冲区在重写子进程创建后创建，当redis执行完一个写操作，会将该操作同时写入aof_buf和aof重写缓冲区。当redis完成aof重写工作后会向主进程发送一个信号，主进程会将重写缓冲区的内容添加到新的aof文件中，使得新旧aof保存的数据库数据一致，将新的aof文件改名覆盖老的aof文件
<!-- more -->
## RDB
rdb记录的事某一时刻redis内存的数据。redis提供了2个命令来生成rdb文件，一个是save，一个是bgsave，使用save是在主进程中完成，会造成阻塞，使用bgsave，redis会创建一个子进程来将数据写入到rdb文件。

redis在执行bgsave时也是可以执行写操作的，通过写时复制(copy-on-wirte)技术
**写时复制技术**：在linux中，当fork一个子进程时，不会将父进程的内存页复制一份，而是父子进程共用同一个内存分页，只有当父子进程其中一个修改了内存数据，才会复制。
不同进程通过虚拟内存将物理内存的地址映射为同一个就实现了共享内存的原理。

创建子进程时，会复制父进程的虚拟内存和物理内存的映射，并将内存设置为只读，当父子进程修改内存时，将原来的内存复制一份新的，并重新设置其内存映射，然后将父子进程的内存读写设置为可读写。

# Redis 持久化时，对过期键会如何处理的？
## rdb持久化
1. rdb生成时会检测key是否过期，过期的话就不会写入rdb文件
2. rdb文件加载时，如果是主服务器，不会加载过期的key，如果是从服务器的话，都会加载，但是主从服务器同步时，会清空从服务器的数据

## aof持久化
1. aof写入时，如果key没有过期则写入aof文件，当key过期后会追加一条del的命令写入到aof文件
2. aof重写时，会检测key是否过期，如果key过期的话就不会将其写入aof文件

redis主从模式下，从库不会处理过期键，从库的过期键由主库来控制，当主库的key过期后，主库执行删除操作，并将其同步给从库，然后从库执行删除操作。
混合持久化，AOF 文件的前半部分是 RDB 格式的全量数据，后半部分是 AOF 格式的增量数据。

# Redis数据结构底层实现吗
## 字符串处理(string)
我们都知道redis是用C语言写，但是C语言处理字符串和数组的成本是很高的，下面我分别说几个例子

没有数据结构支撑的几个问题

1. 极其容易造成缓冲区溢出问题，比如用strcat()，在用这个函数之前必须要先给目标变量分配足够的空间，否则就会溢出。
2. 如果要获取字符串的长度，没有数据结构的支撑，可能就需要遍历，它的复杂度是O(N)
3. 内存重分配。C字符串的每次变更(曾长或缩短)都会对数组作内存重分配。同样，如果是缩短，没有处理好多余的空间，也会造成内存泄漏。

Redis自己构建了一种名叫Simple dynamic string(SDS)的数据结构，他分别对这几个问题作了处理。我们先来看看它的结构源码：
```C
struct sdshdr{
     //记录buf数组中已使用字节的数量
     //等于 SDS 保存字符串的长度
     int len;
     //记录 buf 数组中未使用字节的数量
     int free;
     //字节数组，用于保存字符串
     char buf[];
}
```

再来说说它的优点：

1. 开发者不用担心字符串变更造成的内存溢出问题。
2. 常数时间复杂度获取字符串长度len字段。
3. 空间预分配free字段，会默认留够一定的空间防止多次重分配内存。

这就是string的底层实现，更是redis对所有字符串数据的处理方式(SDS会被嵌套到别的数据结构里使用)

## 链表
Redis的链表在双向链表上扩展了头、尾节点、元素数等属性。
![redis_list](redis_list.jpg)
__源码__
ListNode节点数据结构：
```C
typedef  struct listNode{
       //前置节点
       struct listNode *prev;
       //后置节点
       struct listNode *next;
       //节点的值
       void *value;  
}listNode
```
链表数据结构：
```C
typedef struct list{
     //表头节点
     listNode *head;
     //表尾节点
     listNode *tail;
     //链表所包含的节点数量
     unsigned long len;
     //节点值复制函数
     void (*free) (void *ptr);
     //节点值释放函数
     void (*free) (void *ptr);
     //节点值对比函数
     int (*match) (void *ptr,void *key);
}list;
```

从上面可以看到，Redis的链表有这几个特点：
1. 可以直接获得头、尾节点。
2. 常数时间复杂度得到链表长度。
3. 是双向链表。

## 字典(Hash)
Redis的Hash，就是在数组+链表的基础上，进行了一些rehash优化等。
![redis_hash](redis_hash.jpg)
__数据结构源码__
哈希表：
```C
typedef struct dictht {
    // 哈希表数组
    dictEntry **table;
    // 哈希表大小
    unsigned long size;
    // 哈希表大小掩码，用于计算索引值
    // 总是等于 size - 1
    unsigned long sizemask;
    // 该哈希表已有节点的数量
    unsigned long used;
} dictht;
```
Hash表节点：
```C
typedef struct dictEntry {
    // 键
    void *key;
    // 值
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
    } v;
    // 指向下个哈希表节点，形成链表
    struct dictEntry *next;  // 单链表结构
} dictEntry;
```
字典：
```C
typedef struct dict {
    // 类型特定函数
    dictType *type;
    // 私有数据
    void *privdata;
    // 哈希表
    dictht ht[2];
    // rehash 索引
    // 当 rehash 不在进行时，值为 -1
    int rehashidx; /* rehashing not in progress if rehashidx == -1 */
} dict;
```
可以看出：

1. Reids的Hash采用链地址法来处理冲突，然后它没有使用红黑树优化。
2. 哈希表节点采用单链表结构。
3. rehash优化。

__它的rehash优化。__     
当哈希表的键对太多或者太少，就需要对哈希表的大小进行调整，redis是如何调整的呢?

1. 我们仔细可以看到dict结构里有个字段dictht ht[2]代表有两个dictht数组。第一步就是为ht[1]哈希表分配空间，大小取决于ht[0]当前使用的情况。
2. 将保存在ht[0]中的数据rehash(重新计算哈希值)到ht[1]上。
3. 当ht[0]中所有键值对都迁移到ht[1]后，释放ht[0]，将ht[1]设置为ht[0]，并ht[1]初始化，为下一次rehash做准备。

__渐进式rehash__
redis处理rehash的流程，但是更细一点的讲，它如何进行数据迁的呢？

这就涉及到了渐进式rehash，redis考虑到大量数据迁移带来的cpu繁忙(可能导致一段时间内停止服务)，所以采用了渐进式rehash的方案。步骤如下：

1. 为ht[1]分配空间，同时持有两个哈希表(一个空表、一个有数据)。
2. 维持一个技术器rehashidx，初始值0。
3. 每次对字典增删改查，会顺带将ht[0]中的数据迁移到ht[1],rehashidx++(注意：ht[0]中的数据是只减不增的)。
4. 直到rehash操作完成，rehashidx值设为-1。

它的好处：采用分而治之的思想，将庞大的迁移工作量划分到每一次CURD中，避免了服务繁忙。

## 跳跃表
这个数据结构是我面试中见过最多的，它其实特别简单。学过的人可能都知道，它和平衡树性能很相似，但为什么不用平衡树而用skipList呢?
![跳跃表](跳跃表.png)
__skipList & AVL 之间的选择__

1. 从算法实现难度上来比较，skiplist比平衡树要简单得多。
2. 平衡树的插入和删除操作可能引发子树的调整，逻辑复杂，而skiplist的插入和删除只需要修改相邻节点的指针，操作简单又快速。
3. 查找单个key，skiplist和平衡树的时间复杂度都为O(log n)，大体相当。
4. 在做范围查找的时候，平衡树比skiplist操作要复杂。
5. skiplist和各种平衡树（如AVL、红黑树等）的元素是有序排列的。

可以看到，skipList中的元素是有序的，所以跳跃表在redis中用在有序集合键、集群节点内部数据结构

__源码__

跳跃表节点：
```C
typedef struct zskiplistNode {
    // 后退指针
    struct zskiplistNode *backward;
    // 分值
    double score;
    // 成员对象
    robj *obj;
    // 层
    struct zskiplistLevel {
        // 前进指针
        struct zskiplistNode *forward;
        // 跨度
        unsigned int span;
    } level[];
} zskiplistNode;
```

跳跃表：
```C
typedef struct zskiplist {
    // 表头节点和表尾节点
    struct zskiplistNode *header, *tail;
    // 表中节点的数量
    unsigned long length;
    // 表中层数最大的节点的层数
    int level;
} zskiplist;
```

层(level[]):层，也就是level[]字段，层的数量越多，访问节点速度越快。(因为它相当于是索引，层数越多，它索引就越细，就能很快找到索引值)

前进指针(forward):层中有一个forward字段，用于从表头向表尾方向访问。

跨度(span):用于记录两个节点之间的距离

后退指针(backward):用于从表尾向表头方向访问。

__案例__
```
level0    1---------->5
level1    1---->3---->5
level2    1->2->3->4->5->6->7->8
```
比如我要找键为6的元素，在level0中直接定位到5，然后再往后走一个元素就找到了。

## 整数集合(intset)
Reids对整数存储专门作了优化，intset就是redis用于保存整数值的集合数据结构。当一个结合中只包含整数元素，redis就会用这个来存储。
```C
127.0.0.1:6379[2]> sadd number 1 2 3 4 5 6
(integer) 6
127.0.0.1:6379[2]> object encoding number
"intset"
```

__源码__

intset数据结构：
```C
typedef struct intset {
    // 编码方式
    uint32_t encoding;
    // 集合包含的元素数量
    uint32_t length;
    // 保存元素的数组
    int8_t contents[];
} intset;
```
编码方式(encoding)字段是干嘛用的呢？

- 如果 encoding 属性的值为 INTSET_ENC_INT16 ， 那么 contents 就是一个 int16_t 类型的数组， 数组里的每个项都是一个 int16_t 类型的整数值 （最小值为 -32,768 ，最大值为 32,767 ）。
- 如果 encoding 属性的值为 INTSET_ENC_INT32 ， 那么 contents 就是一个 int32_t 类型的数组， 数组里的每个项都是一个 int32_t 类型的整数值 （最小值为 -2,147,483,648 ，最大值为 2,147,483,647 ）。
- 如果 encoding 属性的值为 INTSET_ENC_INT64 ， 那么 contents 就是一个 int64_t 类型的数组， 数组里的每个项都是一个 int64_t 类型的整数值 （最小值为 -9,223,372,036,854,775,808 ，最大值为 9,223,372,036,854,775,807 ）。

说白了就是根据contents字段来判断用哪个int类型更好，也就是对int存储作了优化。

说到优化，那redis如何作的呢？就涉及到了升级。

__encoding升级__

如果我们有个Int16类型的整数集合，现在要将65535(int32)加进这个集合，int16是存储不下的，所以就要对整数集合进行升级。

它是怎么升级的呢(过程)？

假如现在有2个int16的元素:1和2，新加入1个int32位的元素65535。

- 内存重分配，新加入后应该是3个元素，所以分配3*32-1=95位。
- 选择最大的数65535, 放到(95-32+1, 95)位这个内存段中，然后2放到(95-32-32+1+1, 95-32)位...依次类推。

升级的好处是什么呢？

1. 提高了整数集合的灵活性。
2. 尽可能节约内存(能用小的就不用大的)。

不支持降级

按照上面的例子，如果我把65535又删掉，encoding会不会又回到Int16呢，答案是不会的。官方没有给出理由，我觉得应该是降低性能消耗吧，毕竟调整一次是O(N)的时间复杂度。

## 压缩列表(ziplist)
ziplist是redis为了节约内存而开发的顺序型数据结构。它被用在列表键和哈希键中。一般用于小数据存储。
![压缩列表1](压缩列表1.jpg)
![压缩列表2](压缩列表2.jpg)

__源码__

ziplist没有明确定义结构体，这里只作大概的演示。
```C
typedef struct entry {
     /*前一个元素长度需要空间和前一个元素长度*/
    unsigned int prevlengh;
     /*元素内容编码*/
    unsigned char encoding;
     /*元素实际内容*/
    unsigned char *data;
}zlentry;

typedef struct ziplist{
     /*ziplist分配的内存大小*/
     uint32_t zlbytes;
     /*达到尾部的偏移量*/
     uint32_t zltail;
     /*存储元素实体个数*/
     uint16_t zllen;
     /*存储内容实体元素*/
     unsigned char* entry[];
     /*尾部标识*/
     unsigned char zlend;
}ziplist;
```

Entry的分析

entry结构体里面有三个重要的字段：

1. previous_entry_length: 这个字段记录了ziplist中前一个节点的长度，什么意思？就是说通过该属性可以进行指针运算达到表尾向表头遍历，这个字段还有一个大问题下面会讲。
2. encoding:记录了数据类型(int16? string?)和长度。
3. data/content: 记录数据。

连锁更新

previous_entry_length字段的分析

上面有说到，previous_entry_length这个字段存放上个节点的长度，那默认长度给分配多少呢?redis是这样分的，如果前节点长度小于254,就分配1字节，大于的话分配5字节，那问题就来了。

如果前一个节点的长度刚开始小于254字节，后来大于254,那不就存放不下了吗？ 这就涉及到previous_entry_length的更新，但是改一个肯定不行阿，后面的节点内存信息都需要改。所以就需要重新分配内存，然后连锁更新包括该受影响节点后面的所有节点。

除了增加新节点会引发连锁更新、删除节点也会触发。

## 快速列表(quicklist)
一个由ziplist组成的双向链表。但是一个quicklist可以有多个quicklist节点，它很像B树的存储方式。是在redis3.2版本中新加的数据结构，用在列表的底层实现。
表头结构：
```C
typedef struct quicklist {
    //指向头部(最左边)quicklist节点的指针
    quicklistNode *head;
    //指向尾部(最右边)quicklist节点的指针
    quicklistNode *tail;
    //ziplist中的entry节点计数器
    unsigned long count;        /* total count of all entries in all ziplists*/
    //quicklist的quicklistNode节点计数器
    unsigned int len;           /* number of quicklistNodes */
    //保存ziplist的大小，配置文件设定，占16bits
    int fill : 16;              /* fill factor for individual nodes */
    //保存压缩程度值，配置文件设定，占16bits，0表示不压缩
    unsigned int compress : 16; /* depth of end nodes not to compress;0=off */
} quicklist;
```
quicklist节点结构
```C
typedef struct quicklistNode {
    struct quicklistNode *prev;     //前驱节点指针
    struct quicklistNode *next;     //后继节点指针
    //不设置压缩数据参数recompress时指向一个ziplist结构
    //设置压缩数据参数recompress指向quicklistLZF结构
    unsigned char *zl;
    //压缩列表ziplist的总长度
    unsigned int sz;                  /* ziplist size in bytes */
    //ziplist中包的节点数，占16 bits长度
    unsigned int count : 16;          /* count of items in ziplist */
    //表示是否采用了LZF压缩算法压缩quicklist节点，1表示压缩过，2表示没压缩，占2 bits长度
    unsigned int encoding : 2;        /* RAW==1 or LZF==2 */
    //表示一个quicklistNode节点是否采用ziplist结构保存数据，2表示压缩了，1表示没压缩，默认是2，占2bits长度
    unsigned int container : 2;       /* NONE==1 or ZIPLIST==2 */
    //标记quicklist节点的ziplist之前是否被解压缩过，占1bit长度
    //如果recompress为1，则等待被再次压缩
    unsigned int recompress : 1; /* was this node previous compressed? */
    //测试时使用
    unsigned int attempted_compress : 1; /* node can't compress; too small */
    //额外扩展位，占10bits长度
    unsigned int extra : 10; /* more bits to steal for future usage */
} quicklistNode;
```

__相关配置__

在redis.conf中的ADVANCED CONFIG部分：
```
list-max-ziplist-size -2
list-compress-depth 0
```

list-max-ziplist-size参数:

我们来详细解释一下list-max-ziplist-size这个参数的含义。它可以取正值，也可以取负值。

当取正值的时候，表示按照数据项个数来限定每个quicklist节点上的ziplist长度。比如，当这个参数配置成5的时候，表示每个quicklist节点的ziplist最多包含5个数据项。

当取负值的时候，表示按照占用字节数来限定每个quicklist节点上的ziplist长度。这时，它只能取-1到-5这五个值，每个值含义如下：

- -5: 每个quicklist节点上的ziplist大小不能超过64 Kb。（注：1kb => 1024 bytes)
- -4: 每个quicklist节点上的ziplist大小不能超过32 Kb。
- -3: 每个quicklist节点上的ziplist大小不能超过16 Kb。
- -2: 每个quicklist节点上的ziplist大小不能超过8 Kb。（-2是Redis给出的默认值）

list-compress-depth参数:

这个参数表示一个quicklist两端不被压缩的节点个数。注：这里的节点个数是指quicklist双向链表的节点个数，而不是指ziplist里面的数据项个数。实际上，一个quicklist节点上的ziplist，如果被压缩，就是整体被压缩的。

参数list-compress-depth的取值含义如下：

- 0: 是个特殊值，表示都不压缩。这是Redis的默认值。 
- 1: 表示quicklist两端各有1个节点不压缩，中间的节点压缩。 
- 2: 表示quicklist两端各有2个节点不压缩，中间的节点压缩。 
- 3: 表示quicklist两端各有3个节点不压缩，中间的节点压缩。 
- 依此类推…

1. String 类型的应用场景：缓存对象、常规计数、分布式锁、共享 session 信息等。
2. List 类型的应用场景：消息队列（但是有两个问题：1. 生产者需要自行实现全局唯一 ID；2. 不能以消费组形式消费数据）等。
3. Hash 类型：缓存对象、购物车等。
4. Set 类型：聚合计算（并集、交集、差集）场景，比如点赞、共同关注、抽奖活动等。
5. Zset 类型：排序场景，比如排行榜、电话和姓名排序等。
Redis 后续版本又支持四种数据类型，它们的应用场景如下：
1. BitMap（2.2 版新增）：二值状态统计的场景，比如签到、判断用户登陆状态、连续签到用户总数等；
2. HyperLogLog（2.8 版新增）：海量数据基数统计的场景，比如百万级网页 UV 计数等；
3. GEO（3.2 版新增）：存储地理位置信息的场景，比如滴滴叫车；
4. Stream（5.0 版新增）：消息队列，相比于基于 List 类型实现的消息队列，有这两个特有的特性：自动生成全局唯一消息ID，支持以消费组形式消费数据。

# 常见的缓存策略有哪些
1. Cache Aside(旁路缓存)策略：写：先更新数据库，在删除缓存，读：先读缓存，如果有的话直接返回，如果缓存没有的话，在读数据库，将读出来的数据写入缓存，在返回
2. Read/Write Through(读穿 / 写穿)策略：写：先查询缓存，如果缓存中有数据，则更新缓存，由缓存组件更新数据库，如果缓存没有，则直接更新数据库。读：先查缓存，如果缓存有数据，则直接返回。如果没有，则由缓存组件去查数据库，然后返回给用户
3. Write Back(写回)策略：策略在更新时，只更新缓存，同时将缓存设置为脏数据，然后立马返回，并不会更新数据库，对于数据库的更新，由缓存组件批量处理。

# redis是单线程还是多线程的
![redis多线程工作](redis多线程工作.png)
全部流程分为以下 4 阶段：
- 阶段一：服务端和客⼾端建立 Socket 连接，并分配处理线程。当有客⼾端请求和实例建立 Socket 连接时，主线程会创建和客户端的连接，并把 Socket 放入全局等待队列中。然后主线程通过轮询方法把 Socket 连接分配给 IO 线程。
- 阶段二：IO 线程读取并解析请求。主线程把 Socket 分配给 IO 线程后，会进⼊阻塞状态等待 IO 线程完成客户端请求读取和解析。
- 阶段三：主线程执⾏请求操作。IO 线程解析完请求后，主线程以单线程的⽅式执⾏这些命令操作。
- 阶段四：IO 线程回写 Socket 和主线程清空全局队。主线程执行完请求操作后，会把需要返回的结果写入缓冲区。然后，主线程会阻塞等待 IO 线程把这些结果回写到 Socket 中，并返回给客户端。等到 IO 线程回写 Socket 完毕，主线程会清空全局队列，等待客户端的后续请求。

# redis的主从复制原理
分为三个阶段: 1. 连接阶段 2. 数据同步阶段 3. 命令传播阶段
## 连接阶段
从服务器向主服务器发送psync命令表示要进行同步，psync命令包含2个参数，主服务器的id和复制进度offset，因为不知道主服务器的id是多少，因此使用?，又因为是第一次复制，所以offset是-1。主服务器发送fullresync命令，该命令带上主服务器自己的runId和复制进度-1给从服务器，fullresync响应命令的意图是全量复制。
## 数据同步阶段
1. 主服务器同步数据给从服务器
主服务器生成执行bgsave生成rdb文件，并发送给从服务器，从服务器收到rdb文件后会清空当前的数据，然后载入rdb文件。主服务器生成rdb文件的同时是不会阻塞主进程的，这时，主服务器在下面这三个时间间隙中将收到的写操作命令，写入到 replication buffer 缓冲区里。
- 主服务器生成RDB文件期间
- 主服务器发送RDB文件给从服务器期间
- 从服务器加载 RDB 文件期间
2. 主服务器发送新写操作命令给从服务器
在主服务器生成的 RDB 文件发送完，从服务器收到 RDB 文件后，丢弃所有旧数据，将 RDB 数据载入到内存。完成 RDB 的载入后，会回复一个确认消息给主服务器。接着，主服务器将 replication buffer 缓冲区里所记录的写操作命令发送给从服务器，从服务器执行来自主服务器 replication buffer 缓冲区里发来的命令，这时主从服务器的数据就一致了。
## 命令传播阶段
主从服务器在完成第一次同步后，双方之间就会维护一个 TCP 连接。后续主服务器可以通过这个连接继续将写操作命令传播给从服务器，然后从服务器执行该命令，使得与主服务器的数据库状态相同。而且这个连接是长连接的，目的是避免频繁的 TCP 连接和断开带来的性能开销。
![主从复制数据原理](主从复制数据原理.PNG)

## 增量复制
如果主从服务器间的网络连接断开了，那么就无法进行命令传播了，这时从服务器的数据就没办法和主服务器保持一致了，客户端就可能从从服务器读到旧的数据。如果此时断开的网络，又恢复正常了，要怎么继续保证主从服务器的数据一致性呢？网络断开又恢复后，从主从服务器会采用增量复制的方式继续同步，也就是只会把网络断开期间主服务器接收到的写操作命令，同步给从服务器。
1. 从服务器在恢复网络后，会发送 psync 命令给主服务器，此时的 psync 命令里的 offset 参数不是 -1；
2. 主服务器收到该命令后，然后用 CONTINUE 响应命令告诉从服务器接下来采用增量复制的方式同步数据；
3. 然后主服务将主从服务器断线期间，所执行的写命令发送给从服务器，然后从服务器执行这些命令

### 主服务器怎么知道要将哪些增量数据发送给从服务器呢
- repl_backlog_buffer: 是一个「环形」缓冲区，用于主从服务器断连后，从中找到差异的数据；
- replication offset: 标记上面那个缓冲区的同步进度，主从服务器都有各自的偏移量，主服务器使用 master_repl_offset 来记录自己写到的位置，从服务器使用 slave_repl_offset 来记录自己读到的位置。

在主服务器进行命令传播时，不仅会将写命令发送给从服务器，还会将写命令写入到 repl_backlog_buffer 缓冲区里，因此 这个缓冲区里会保存着最近传播的写命令。网络断开后，当从服务器重新连上主服务器时，从服务器会通过 psync 命令将自己的复制偏移量 slave_repl_offset 发送给主服务器，主服务器根据自己的 master_repl_offset 和 slave_repl_offset 之间的差距，然后来决定对从服务器执行哪种同步操作:1. 如果判断出从服务器要读取的数据还在 repl_backlog_buffer 缓冲区里，那么主服务器将采用增量同步的方式；2. 相反，如果判断出从服务器要读取的数据已经不存在 repl_backlog_buffer 缓冲区里，那么主服务器将采用全量同步的方式。当主服务器在 repl_backlog_buffer 中找到主从服务器差异（增量）的数据后，就会将增量的数据写入到 replication buffer 缓冲区，这个缓冲区我们前面也提到过，它是缓存将要传播给从服务器的命令。
![redis断点续传原理](redis断点续传原理.PNG)

# 哨兵机制
Sentinel(哨兵)是Redis 的高可用性解决方案：由一个或多个Sentinel实例组成的Sentinel 系统可以监视任意多个主服务器，以及这些主服务器属下的所有从服务器，并在被监视的主服务器进入下线状态时，自动将下线主服务器属下的某个从服务器升级为新的主服务器。哨兵(sentinel)是一个分布式系统，用于对主从结构中的每台服务器进行监控，当出现故障时通过投票机制选择新的master并将所有slave连接到新的master。

## 哨兵的作用
- 监控(Monitoring)：哨兵(sentinel) 会不断地检查你的 Master 和 Slave 是否运作正常
- 提醒(Notification)：当被监控的某个Redis节点出现问题时, 哨兵(sentinel) 可以通过 API 向管理员或者其他应用程序发送通知。（使用较少）
- 自动故障迁移(Automatic failover)：当一个 Master 不能正常工作时，哨兵(sentinel) 会开始一次自动故障迁移操作。1. 它会将失效 Master 的其中一个 Slave 升级为新的 Master, 并让失效 Master 的其他Slave 改为复制新的 Master。2. 它会将失效 Master 的其中一个 Slave 升级为新的 Master, 并让失效 Master 的其他Slave 改为复制新的 Master。3. Master 和 Slave 服务器切换后，Master 的 redis.conf、Slave 的 redis.conf 和sentinel.conf 的配置文件的内容都会发生相应的改变，即 Master 主服务器的 redis.conf 配置文件中会多一行 slaveof 的配置，sentinel.conf 的监控目标会随之调换。

## 哨兵的工作方式
1. 每个 Sentinel（哨兵）进程以每秒钟一次的频率向整个集群中的 Master 主服务器，Slave 从服务器以及其他 Sentinel（哨兵）进程发送一个 PING 命令。
2.  如果一个实例（instance）距离最后一次有效回复 PING 命令的时间超过 down-after-milliseconds 选项所指定的值， 则这个实例会被 Sentinel（哨兵）进程标记为主观下线（SDOWN）。
3. 如果一个 Master 主服务器被标记为主观下线（SDOWN），则正在监视这个 Master 主服务器的所有 Sentinel（哨兵）进程要以每秒一次的频率确认 Master 主服务器的确进入了主观下线状态。
4. 当有足够数量的 Sentinel（哨兵）进程（大于等于配置文件指定的值，即quorum）在指定的时间范围内确认 Master 主服务器进入了主观下线状态（SDOWN）， 则 Master 主服务器会被标记为客观下线（ODOWN）。
5. 在一般情况下， 每个 Sentinel（哨兵）进程会以每 10 秒一次的频率向集群中的所有Master 主服务器、Slave 从服务器发送 INFO 命令。
6. 当 Master 主服务器被 Sentinel（哨兵）进程标记为客观下线（ODOWN）时，Sentinel（哨兵）进程向下线的 Master 主服务器的所有 Slave 从服务器发送 INFO 命令的频率会从 10 秒一次改为每秒一次。
7. 若没有足够数量的 Sentinel（哨兵）进程同意 Master 主服务器下线， Master 主服务器的客观下线状态就会被移除。若 Master 主服务器重新向 Sentinel（哨兵）进程发送 PING 命令返回有效回复，Master 主服务器的主观下线状态就会被移除。
8. 哪个哨兵节点判断主节点为「客观下线」，这个哨兵节点就是候选者，所谓的候选者就是想当 Leader 的哨兵。
9. 让 leader 来执行主从切换

## 哨兵选举过程
1. 第一个发现该master挂了的哨兵，向每个哨兵发送命令，让对方选举自己成为领头哨兵
2. 其他哨兵如果没有选举过他人，就会将这一票投给第一个发现该master挂了的哨兵
3. 第一个发现该master挂了的哨兵如果发现由超过一半哨兵投给自己，并且其数量也超过了设定的quoram参数，那么该哨兵就成了领头哨兵
4. 如果多个哨兵同时参与这个选举，那么就会重复该过程，知道选出一个领头哨兵

## Master选举过程：
1. 从所有在线的从数据库中，选择优先级最高的从数据库
2. 如果有多个优先级高的从数据库，那么就会判断其偏移量，选择偏移量最小的从数据库，这里的偏移量就是增量复制的

3. 如果还是有相同条件的从数据库，就会选择运行id较小的从数据库升级为master

## 主从故障转移的过程
在哨兵集群中通过投票的方式，选举出了哨兵 leader 后，就可以进行主从故障转移的过程了
1. 在已下线主节点（旧主节点）属下的所有「从节点」里面，挑选出一个从节点，并将其转换为主节点。
2. 让已下线主节点属下的所有「从节点」修改复制目标，修改为复制「新主节点」
3. 将新主节点的 IP 地址和信息，通过「发布者/订阅者机制」通知给客户端
4. 继续监视旧主节点，当这个旧主节点重新上线时，将它设置为新主节点的从节点；

## 常见的扩容方式有垂直和水平扩容两种方式：
- 垂直扩容：通过增加master内存来增加容量；
- 水平扩容：通过增加节点来进行扩容，即在当前基础上再增加一个master节点

# 数据一致性
|问题场景|描述|解决|
|:--:|:--:|:--:|
|先写缓存，再写数据库，缓存写成功，数据库写失败|缓存写成功，但写数据库失败或者响应延迟，则下次读取（并发读）缓存时，就出现脏读|这个写缓存的方式，本身就是错误的，需要改为先写数据库，把旧缓存置为失效；读取数据的时候，如果缓存不存在，则读取数据库再写缓存|
|先写数据库，再写缓存，数据库写成功，缓存写失败|写数据库成功，但写缓存失败，则下次读取（并发读）缓存时，则读不到数据|缓存使用时，假如读缓存失败，先读数据库，再回写缓存的方式实现|
|需要缓存异步刷新|指数据库操作和写缓存不在一个操作步骤中，比如在分布式场景下，无法做到同时写缓存或需要异步刷新（补救措施）时候|确定哪些数据适合此类场景，根据经验值确定合理的数据不一致时间，用户数据刷新的时间间隔|
# 一致性哈希算法
Redis集群通过分布式存储的方式解决了单节点的海量数据存储的问题，对于分布式存储，需要考虑的重点就是如何将数据进行拆分到不同的Redis服务器上。常见的分区算法有hash算法、一致性hash算法，关于这些算法这里就不多介绍。
## 分布式算法
在做服务器负载均衡时候可供选择的负载均衡的算法有很多，包括： 轮循算法(Round Robin)、哈希算法(HASH)、最少连接算法(Least Connection)、响应速度算法(Response Time)、加权法(Weighted )等。其中哈希算法是最为常用的算法.

典型的应用场景是： 有N台服务器提供缓存服务，需要对服务器进行负载均衡，将请求平均分发到每台服务器上，每台机器负责1/N的服务。

常用的算法是对hash结果取余数 (hash() mod N )：对机器编号从0到N-1，按照自定义的 hash()算法，对每个请求的hash()值按N取模，得到余数i，然后将请求分发到编号为i的机器。但这样的算法方法存在致命问题，如果某一台机器宕机，那么应该落在该机器的请求就无法得到正确的处理，这时需要将当掉的服务器从算法从去除，此时候会有(N-1)/N的服务器的缓存数据需要重新进行计算;如果新增一台机器，会有N /(N+1)的服务器的缓存数据需要进行重新计算。对于系统而言，这通常是不可接受的颠簸(因为这意味着大量缓存的失效或者数据需要转移)。那么，如何设计一个负载均衡策略，使得受到影响的请求尽可能的少呢?

在Memcached、Key-Value Store 、Bittorrent DHT、LVS中都采用了Consistent Hashing算法，可以说Consistent Hashing 是分布式系统负载均衡的首选算法。

## 分布式缓存问题
在大型web应用中，缓存可算是当今的一个标准开发配置了。在大规模的缓存应用中，应运而生了分布式缓存系统。分布式缓存系统的基本原理，大家也有所耳闻。key-value如何均匀的分散到集群中？说到此，最常规的方式莫过于hash取模的方式。比如集群中可用机器适量为N，那么key值为K的的数据请求很简单的应该路由到hash(K) mod N对应的机器。的确，这种结构是简单的，也是实用的。但是在一些高速发展的web系统中，这样的解决方案仍有些缺陷。随着系统访问压力的增长，缓存系统不得不通过增加机器节点的方式提高集群的相应速度和数据承载量。增加机器意味着按照hash取模的方式，在增加机器节点的这一时刻，大量的缓存命不中，缓存数据需要重新建立，甚至是进行整体的缓存数据迁移，瞬间会给DB带来极高的系统负载，设置导致DB服务器宕机。 那么就没有办法解决hash取模的方式带来的诟病吗？

假设我们有一个网站，最近发现随着流量增加，服务器压力越来越大，之前直接读写数据库的方式不太给力了，于是我们想引入Memcached作为缓存机制。现在我们一共有三台机器可以作为Memcached服务器，如下图所示：

![分布式缓存问题](分布式缓存问题.png)

很显然，最简单的策略是将每一次Memcached请求随机发送到一台Memcached服务器，但是这种策略可能会带来两个问题：一是同一份数据可能被存在不同的机器上而造成数据冗余，二是有可能某数据已经被缓存但是访问却没有命中，因为无法保证对相同key的所有访问都被发送到相同的服务器。因此，随机策略无论是时间效率还是空间效率都非常不好。

要解决上述问题只需做到如下一点：保证对相同key的访问会被发送到相同的服务器。很多方法可以实现这一点，最常用的方法是计算哈希。例如对于每次访问，可以按如下算法计算其哈希值：
h = Hash(key) % 3

其中Hash是一个从字符串到正整数的哈希映射函数。这样，如果我们将Memcached Server分别编号为0、1、2，那么就可以根据上式和key计算出服务器编号h，然后去访问。

这个方法虽然解决了上面提到的两个问题，但是存在一些其它的问题。如果将上述方法抽象，可以认为通过：
h = Hash(key) % N

这个算式计算每个key的请求应该被发送到哪台服务器，其中N为服务器的台数，并且服务器按照0 – (N-1)编号。

这个算法的问题在于容错性和扩展性不好。所谓容错性是指当系统中某一个或几个服务器变得不可用时，整个系统是否可以正确高效运行；而扩展性是指当加入新的服务器后，整个系统是否可以正确高效运行。

现假设有一台服务器宕机了，那么为了填补空缺，要将宕机的服务器从编号列表中移除，后面的服务器按顺序前移一位并将其编号值减一，此时每个key就要按h = Hash(key) % (N-1)重新计算；同样，如果新增了一台服务器，虽然原有服务器编号不用改变，但是要按h = Hash(key) % (N+1)重新计算哈希值。因此系统中一旦有服务器变更，大量的key会被重定位到不同的服务器从而造成大量的缓存不命中。而这种情况在分布式系统中是非常糟糕的。

一个设计良好的分布式哈希方案应该具有良好的单调性，即服务节点的增减不会造成大量哈希重定位。一致性哈希算法就是这样一种哈希方案。

Hash 算法的一个衡量指标是单调性（ Monotonicity ），定义如下：单调性是指如果已经有一些内容通过哈希分派到了相应的缓冲中，又有新的缓冲加入到系统中。哈希的结果应能够保证原有已分配的内容可以被映射到新的缓冲中去，而不会被映射到旧的缓冲集合中的其他缓冲区。

容易看到，上面的简单 hash 算法 hash(object)%N 难以满足单调性要求

## 一致性哈希算法
一致性哈希算法(Consistent Hashing Algorithm)是一种分布式算法，常用于负载均衡。Memcached client也选择这种算法，解决将key-value均匀分配到众多Memcached server上的问题。它可以取代传统的取模操作，解决了取模操作无法应对增删Memcached Server的问题(增删server会导致同一个key,在get操作时分配不到数据真正存储的server，命中率会急剧下降)。

简单来说，一致性哈希将整个哈希值空间组织成一个虚拟的圆环，如假设某哈希函数H的值空间为0 - (2^32)-1（即哈希值是一个32位无符号整形），整个哈希空间环如下：

![一致性哈希算法1](一致性哈希算法1.png)

整个空间按顺时针方向组织。0和(2^32)-1在零点中方向重合。

下一步将各个服务器使用H进行一个哈希，具体可以选择服务器的ip或主机名作为关键字进行哈希，这样每台机器就能确定其在哈希环上的位置，这里假设将上文中三台服务器使用ip地址哈希后在环空间的位置如下：

![一致性哈希算法2](一致性哈希算法2.png)

接下来使用如下算法定位数据访问到相应服务器：将数据key使用相同的函数H计算出哈希值h，通根据h确定此数据在环上的位置，从此位置沿环顺时针“行走”，第一台遇到的服务器就是其应该定位到的服务器。

例如我们有A、B、C、D四个数据对象，经过哈希计算后，在环空间上的位置如下：

![一致性哈希算法3](一致性哈希算法3.png)

根据一致性哈希算法，数据A会被定为到Server 1上，D被定为到Server 3上，而B、C分别被定为到Server 2上。

## 容错性和可扩展性分析
下面分析一致性哈希算法的容错性和可扩展性。现假设Server 3宕机了：

![一致性哈希算法4](一致性哈希算法4.png)

可以看到此时A、C、B不会受到影响，只有D节点被重定位到Server 2。一般的，在一致性哈希算法中，如果一台服务器不可用，则受影响的数据仅仅是此服务器到其环空间中前一台服务器（即顺着逆时针方向行走遇到的第一台服务器）之间数据，其它不会受到影响。

下面考虑另外一种情况，如果我们在系统中增加一台服务器Memcached Server 4：

![一致性哈希算法5](一致性哈希算法5.png)

此时A、D、C不受影响，只有B需要重定位到新的Server 4。一般的，在一致性哈希算法中，如果增加一台服务器，则受影响的数据仅仅是新服务器到其环空间中前一台服务器（即顺着逆时针方向行走遇到的第一台服务器）之间数据，其它不会受到影响。

综上所述，一致性哈希算法对于节点的增减都只需重定位环空间中的一小部分数据，具有较好的容错性和可扩展性。

## 虚拟节点
一致性哈希算法在服务节点太少时，容易因为节点分部不均匀而造成数据倾斜问题。例如我们的系统中有两台服务器，其环分布如下：

![一致性哈希算法6](一致性哈希算法6.png)

此时必然造成大量数据集中到Server 1上，而只有极少量会定位到Server 2上。为了解决这种数据倾斜问题，一致性哈希算法引入了虚拟节点机制，即对每一个服务节点计算多个哈希，每个计算结果位置都放置一个此服务节点，称为虚拟节点。具体做法可以在服务器ip或主机名的后面增加编号来实现。例如上面的情况，我们决定为每台服务器计算三个虚拟节点，于是可以分别计算“Memcached Server 1#1”、“Memcached Server 1#2”、“Memcached Server 1#3”、“Memcached Server 2#1”、“Memcached Server 2#2”、“Memcached Server 2#3”的哈希值，于是形成六个虚拟节点：

![一致性哈希算法7](一致性哈希算法7.png)

## JAVA实现
```java
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collection;
import java.util.SortedMap;
import java.util.TreeMap;

/**
 * 一致性Hash算法
 *
 * @param <T> 节点类型
 */
public class ConsistentHash<T> {
    /**
     * Hash计算对象，用于自定义hash算法
     */
    HashFunc hashFunc;
    /**
     * 复制的节点个数
     */
    private final int numberOfReplicas;
    /**
     * 一致性Hash环
     */
    private final SortedMap<Long, T> circle = new TreeMap<>();

    /**
     * 构造，使用Java默认的Hash算法
     * @param numberOfReplicas 复制的节点个数，增加每个节点的复制节点有利于负载均衡
     * @param nodes            节点对象
     */
    public ConsistentHash(int numberOfReplicas, Collection<T> nodes) {
        this.numberOfReplicas = numberOfReplicas;
        this.hashFunc = new HashFunc() {

            @Override
            public Long hash(Object key) {
//                return fnv1HashingAlg(key.toString());
                return md5HashingAlg(key.toString());
            }
        };
        //初始化节点
        for (T node : nodes) {
            add(node);
        }
    }

    /**
     * 构造
     * @param hashFunc         hash算法对象
     * @param numberOfReplicas 复制的节点个数，增加每个节点的复制节点有利于负载均衡
     * @param nodes            节点对象
     */
    public ConsistentHash(HashFunc hashFunc, int numberOfReplicas, Collection<T> nodes) {
        this.numberOfReplicas = numberOfReplicas;
        this.hashFunc = hashFunc;
        //初始化节点
        for (T node : nodes) {
            add(node);
        }
    }

    /**
     * 增加节点<br>
     * 每增加一个节点，就会在闭环上增加给定复制节点数<br>
     * 例如复制节点数是2，则每调用此方法一次，增加两个虚拟节点，这两个节点指向同一Node
     * 由于hash算法会调用node的toString方法，故按照toString去重
     *
     * @param node 节点对象
     */
    public void add(T node) {
        for (int i = 0; i < numberOfReplicas; i++) {
            circle.put(hashFunc.hash(node.toString() + i), node);
        }
    }

    /**
     * 移除节点的同时移除相应的虚拟节点
     *
     * @param node 节点对象
     */
    public void remove(T node) {
        for (int i = 0; i < numberOfReplicas; i++) {
            circle.remove(hashFunc.hash(node.toString() + i));
        }
    }

    /**
     * 获得一个最近的顺时针节点
     *
     * @param key 为给定键取Hash，取得顺时针方向上最近的一个虚拟节点对应的实际节点
     * @return 节点对象
     */
    public T get(Object key) {
        if (circle.isEmpty()) {
            return null;
        }
        long hash = hashFunc.hash(key);
        if (!circle.containsKey(hash)) {
            SortedMap<Long, T> tailMap = circle.tailMap(hash); //返回此映射的部分视图，其键大于等于 hash
            hash = tailMap.isEmpty() ? circle.firstKey() : tailMap.firstKey();
        }
        //正好命中
        return circle.get(hash);
    }

    /**
     * 使用MD5算法
     * @param key
     * @return
     */
    private static long md5HashingAlg(String key) {
        MessageDigest md5 = null;
        try {
            md5 = MessageDigest.getInstance("MD5");
            md5.reset();
            md5.update(key.getBytes());
            byte[] bKey = md5.digest();
            long res = ((long) (bKey[3] & 0xFF) << 24) | ((long) (bKey[2] & 0xFF) << 16) | ((long) (bKey[1] & 0xFF) << 8)| (long) (bKey[0] & 0xFF);
            return res;
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return 0l;
    }

    /**
     * 使用FNV1hash算法
     * @param key
     * @return
     */
    private static long fnv1HashingAlg(String key) {
        final int p = 16777619;
        int hash = (int) 2166136261L;
        for (int i = 0; i < key.length(); i++)
            hash = (hash ^ key.charAt(i)) * p;
        hash += hash << 13;
        hash ^= hash >> 7;
        hash += hash << 3;
        hash ^= hash >> 17;
        hash += hash << 5;
        return hash;
    }

    /**
     * Hash算法对象，用于自定义hash算法
     */
    public interface HashFunc {
        public Long hash(Object key);
    }
}
```

Consistent Hashing最大限度地抑制了hash键的重新分布。另外要取得比较好的负载均衡的效果，往往在服务器数量比较少的时候需要增加虚拟节点来保证服务器能均匀的分布在圆环上。因为使用一般的hash方法，服务器的映射地点的分布非常不均匀。使用虚拟节点的思想，为每个物理节点（服务器）在圆上分配100～200个点。这样就能抑制分布不均匀，最大限度地减小服务器增减时的缓存重新分布。用户数据映射在虚拟节点上，就表示用户数据真正存储位置是在该虚拟节点代表的实际物理服务器上。

## 普通hash算法和一致性hash算法的原理
普通hash算法：将key使用hash算法计算之后，按照节点数量来取余，即hash(key)%N。优点就是比较简单，但是扩容或者摘除节点时需要重新根据映射关系计算，会导致数据重新迁移。
一致性hash算法：为每一个节点分配一个token，构成一个哈希环；查找时先根据key计算hash值，然后顺时针找到第一个大于等于该哈希值的token节点。优点是在加入和删除节点时只影响相邻的两个节点，缺点是加减节点会造成部分数据无法命中，所以一般用于缓存，而且用于节点量大的情况下，扩容一般增加一倍节点保障数据负载均衡。

# redis集群原理
将整个数据集按照一定规则分配到多个节点上，称为数据分片，Redis Cluster采用的分片方案是哈希分片, 基本原理如下： Redis Cluster首先定义了编号0 ~ 16383的区间，称为槽，所有的键根据哈希函数映射到0 ~ 16383整数槽内，计算公式：slot=CRC16（key）&16383。每一个节点负责维护一部分槽以及槽所映射的键值数据。

## goosip协议
redis集群的哈希槽算法解决的是数据的存取问题，不同的哈希槽位于不同的节点上，而不同的节点维护着一份它所认为的当前集群的状态，同时，Redis集群是去中心化的架构。那么，当集群的状态发生变化时，比如新节点加入、slot迁移、节点宕机、slave提升为新Master等等，我们希望这些变化尽快被其他节点发现，Redis是如何进行处理的呢？也就是说，Redis不同节点之间是如何进行通信进行维护集群的同步状态呢？

gossip协议，是基于流行病传播方式的节点或者进程之间信息交换的协议。原理就是在不同的节点间不断地通信交换信息，一段时间后，所有的节点就都有了整个集群的完整信息，并且所有节点的状态都会达成一致。每个节点可能知道所有其他节点，也可能仅知道几个邻居节点，但只要这些节可以通过网络连通，最终他们的状态就会是一致的。Gossip协议最大的好处在于，即使集群节点的数量增加，每个节点的负载也不会增加很多，几乎是恒定的。

gossip 协议包含多种消息，包含 ping,pong,meet,fail 等等。
Redis Cluster 的节点之间会相互发送多种消息，较为重要的如下所示：

- MEET：通过「cluster meet ip port」命令，已有集群的节点会向新的节点发送邀请，加入现有集群，然后新节点就会开始与其他节点进行通信；
- PING：节点按照配置的时间间隔向集群中其他节点发送 ping 消息，消息中带有自己的状态，还有自己维护的集群元数据，和部分其他节点的元数据；
- PONG: 节点用于回应 PING 和 MEET 的消息，结构和 PING 消息类似，也包含自己的状态和其他信息，也可以用于信息广播和更新；
- FAIL: 节点 PING 不通某节点后，会向集群所有节点广播该节点挂掉的消息。其他节点收到消息后标记已下线

## redis集群故障发现
1. 主观下线： 当cluster-node-timeout时间内某节点无法与另一个节点顺利完成ping消息通信时，则将该节点标记为主观下线状态。
2. 客观下线：当某个节点判断另一个节点主观下线后，该节点的下线报告会通过Gossip消息传播。当接收节点发现消息体中含有主观下线的节点，其会尝试对该节点进行客观下线，依据下线报告是否在有效期内(如果在cluster-node-timeout*2时间内无法收集到一半以上槽节点的下线报告，那么之前的下线报告会过期)，且数量大于槽节点总数的一半。若是，则将该节点更新为客观下线，并向集群广播下线节点的fail消息。

## redis集群故障恢复
故障节点变为客观下线后，如果下线节点是持有槽的主节点，则需要在它的从节点中选出一个替换它，从而保证集群的高可用，过程如下：
1. 资格审查：从节点符合故障转移资格后，更新触发故障选举时间，只有到达该时间才能执行后续流程。采用延迟触发机制，主要是对多个从节点使用不同的延迟选举时间来支持优先级。复制偏移量越大说明从节点延迟越低，那么它应该具有更高的优先级。
2. 准备选举时间：从节点符合故障转移资格后，更新触发故障选举时间，只有到达该时间才能执行后续流程。采用延迟触发机制，主要是对多个从节点使用不同的延迟选举时间来支持优先级。复制偏移量越大说明从节点延迟越低，那么它应该具有更高的优先级。
3. 发起选举：当从节点到达故障选举时间后，会触发选举流程：(1)更新配置纪元:配置纪元是一个只增不减的整数，每个主节点自身维护一个配置纪元，标示当前主节点的版本，所有主节点的配置纪元都不相等，从节点会复制主节点的配置纪元。整个集群又维护一个全局的配置纪元，用于记录集群内所有主节点配置纪元的最大版本。每次集群发生重大事件，如新加入主节点或由从节点转换而来，从节点竞争选举，都会递增集群全局配置纪元并赋值给相关主节点，用于记录这一关键事件。(2)广播选举消息：在集群内广播选举消息，并记录已发送过消息的状态，保证该从节点在一个配置纪元内只能发起一次选举。
4. 选举投票：只有持有槽的主节点才会处理故障选举消息，每个持有槽的节点在一个配置纪元内都有唯一的一张选票，当接到第一个请求投票的从节点消息，回复消息作为投票，之后相同配置纪元内其它从节点的选举消息将忽略。投票过程其实是一个领导者选举的过程。每个配置纪元代表了一次选举周期，如果在开始投票后的cluster-node-timeout*2时间内从节点没有获取足够数量的投票，则本次选举作废。从节点对配置纪元自增并发起下一轮投票，直到选举成功为止。
5. 替换主节点：当前从节点取消复制变为主节点，撤销故障主节点负责的槽，把这些槽委派给自己，并向集群广播告知所有节点当前从节点变为主节点。

## 为什么是16384（2^14）个
CRC16的算法原理：
1. 根据CRC16的标准选择初值CRCIn的值
2. 将数据的第一个字节与CRCIn高8位异或
3. 判断最高位，若该位为 0 左移一位，若为 1 左移一位再与多项式Hex码异或
4. 重复3直至8位全部移位计算结束。
重复将所有输入数据操作完成以上步骤，所得16位数即16位CRC校验码

在redis节点发送心跳包时需要把所有的槽放到这个心跳包里，以便让节点知道当前集群信息，16384=16k，在发送心跳包时使用char进行bitmap压缩后是2k（2 * 8 (8 bit) * 1024(1k) = 16K），也就是说使用2k的空间创建了16k的槽数。

虽然使用CRC16算法最多可以分配65535（2^16-1）个槽位，65535=65k，压缩后就是8k（8 * 8 (8 bit) * 1024(1k) =65K），也就是说需要需要8k的心跳包，作者认为这样做不太值得；并且一般情况下一个redis集群不会有超过1000个master节点，所以16k的槽位是个比较合适的选择