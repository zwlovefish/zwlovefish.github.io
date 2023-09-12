---
title: Java并发编程
date: 2023-02-27 12:21:23
tags: 面试 Java基绌
categories: 面试
---

CPU通过每个线程分配CPU时间片来实现机制，时间片是CPU分配给各个线程的时间。所以任务从保存到再加载的过程就是一次上下文切换。

# 如何减少上下文切换
1. 无锁并发编程：不使用锁
2. CAS算法
3. 使用最少线程
4. 协程

# 避免死锁的常用方法
1. 避免一个线程同时获取多个锁
2. 避免一个线程在锁内同占用多个资源，尽量保证每个锁只占用一个资源
3. 尝试使用定时锁，使用lock.tryLock(timeout)来替代使用内部锁机制
4. 对于数据库锁，加锁和解锁必须在一个数据库连接里，否则会出现解锁失败的情况
<!-- more -->
# volatile的应用
## volatile两条实现规则
1. Lock前缀指令会引起处理器缓存回写到内存
2. 一个处理器的缓存回写到内存会导致其他处理器的缓存无效
## votaile
1. __原子性：__ 即一个操作或者多个操作 要么全部执行并且执行的过程不会被任何因素打断，要么就都不执行。<font color="red">Java内存模型只保证了基本读取和赋值是原子性操作</font>，如果要实现更大范围操作的原子性，可以通过synchronized和Lock来实现。由于synchronized和Lock能够保证任一时刻只有一个线程执行该代码块，那么自然就不存在原子性问题了，从而保证了原子性。
<font color="red">必须是将数字赋值给某个变量，变量之间的相互赋值不是原子操作</font>>

2. __可见性:__ 即当多个线程访问同一个变量时，一个线程修改了这个变量的值，其他线程能够立即看得到修改的值。当一个共享变量被volatile修饰时，它会保证修改的值会立即被更新到主存，当有其他线程需要读取时，它会去内存中读取新值。而普通的共享变量不能保证可见性，因为普通共享变量被修改之后，什么时候被写入主存是不确定的，当其他线程去读取时，此时内存中可能还是原来的旧值，因此无法保证可见性。通过synchronized和Lock也能够保证可见性，synchronized和Lock能保证同一时刻只有一个线程获取锁然后执行同步代码，并且在释放锁之前会将对变量的修改刷新到主存当中。因此可以保证可见性。

3. __有序性：__ 即程序执行的顺序按照代码的先后顺序执行。在Java内存模型中，允许编译器和处理器对指令进行重排序，但是重排序过程不会影响到单线程程序的执行，却会影响到多线程并发执行的正确性。另外可以通过synchronized和Lock来保证有序性，很显然，synchronized和Lock保证每个时刻是有一个线程执行同步代码，相当于是让线程顺序执行同步代码，自然就保证了有序性。

## 基于俣守策略的JMM内存屏障插入策略
- 在每个volatile写操作的前面插入一个StoreStore屏障 (禁止上面的普通写和下面的volatile写重排序)
- 在每个volatile写操作的后面插入一个StoreLoad屏障  (防止上面的volatile写与下面可能有的volatile读/写重排序)
- 在每个volatile读操作的后面插入一个LoadLoad屏障   (禁止下面所有的普通读和上面的volatile读重排序)
- 在每个volatile读操作的后面插入一个LoadStore屏障  (禁止下面所有的普通写操作和上面的volatile读重排序)

# final域的重排序规则
1. 在构造函数内对一个final域的写入，与随后把这个被构造对象的引用赋值给一个引用变量，这两个操作不能重排序
2. 初次读一个包含final域的对象的引用，与随后初次读这个final域，这两个操作不能重排序

final域的重排序规则禁止把final域的写重排序到构造函数之外，这个规则的实现包含2个方面
1. JMM禁止编译器把final域的写重排序到构造函数之外
2. 编译器会在final域的写之后，构造函数retrun之前，插入一个StoreStore屏障。这个屏障禁止处理器把final域的写重排序到构造函数之外
3. 编译器会在读final域操作之前插入一个LoadLoad屏障。

# synchronized的实现原理和应用
它是Java中的关键字，是一种同步锁。它修饰的对象有以下几种:

1. 修饰一个代码块，被修饰的代码块称为同步语句块，其作用的范围是大括号{}括起来的代码，作用的对象是调用这个代码块的对象
2. 修饰一个方法，被修饰的方法称为同步方法，其作用的范围是整个方法，作用的对象是调用这个方法的对象
3. 修饰一个静态的方法，其作用的范围是整个静态方法，作用的对象是这个类的所有对象
4. 修饰一个类，其作用的范围是synchronized后面括号括起来的部分，作用的对象是这个类的所有对象。

## 原理
markword

## 锁的状态
锁一共有四种状级别，从低到高是:无锁状态，偏向锁状态，轻量级锁状态和重量级锁状态，<font color="red">锁可以升级，但不能降级 </font>

## 偏向锁
大多数情况下，锁不仅不存在多线程竞争，而且总是由统一线程多次获得，为了让获得锁的代价更低而引入了偏向锁

当一个线程访问同步块并获取锁时，会在对象头和栈帧中的锁记录里存储锁偏向的线程ID，以后该线程在进入和退出同步块时不需要进行CAS操作来加锁和解锁，只需要简单地测试一下对象头的Mark Word里是否存储着指向当前线程的偏向锁。如果测试成功，表示线程已经获得了锁。如果测试失败，则需要在测试一下Mark World中，偏向锁的标志是否设置成1(表示当前是偏向锁).如果没有设置，则使用CAS竞争锁，如果设置了，则尝试使用CAS将对象头的偏向锁指向当前线程。

## 轻量级锁
线程执行同步块之前，JVM会先在当前线程的栈帧中创建用于存储锁记录的空间，并将对象头中的Mark Word复制到锁记录中，官方称为Displaced MarkWord,然后线程尝试使用CAS将对象头中的Mark Word替换为指向锁记录的指针。如果成功，当前线程获得锁，如果失败，表示其他线程竞争失败，当前线程便尝试使用自旋锁来获取锁。

# 锁的优缺点对比
|锁|优点|缺点|适用场景|
|--|--|--|--|
|偏向锁|加锁和解锁不需要额外的消耗，和执行非同步方法相比，仅存在纳秒级别的差距|如果线程间存在锁竞争，会带来额外的锁撤销的消耗|使用只有一个线程访问同步块的场景|
|轻量级锁|竞争的线程不会被阻塞，提高了程序的响应速度|如果始终得不到锁竞争的线程，使用自旋会消耗CPU|追求响应时间，同步块执行的时间非常快|
|重量级锁|线程竞争不使用自旋不会消耗CPU|线程阻塞，响应时间慢|追求吞吐量，同步块执行时间较长|

# 原子操作原理
## 处理器如何实现原子操作
1. 使用总线锁保证原子操作：使用LOCK#信号，当一个处理器在总线上输出此信号时，其他处理器的请求将被阻塞住。那么该处理器可以独占共享内存
2. 使用缓存锁定保证原子性
所谓缓存锁定：内存区域如果被缓存到处理器的缓存行中，并且在Lock操作期间被锁定，那么当它执行锁操作回写到内存时，处理器不在总线上声言LOCK#信号，而是修改内部的内存地址，并允许它的缓存一致性机制来保证操作的原子性，因为缓存一致性机制会阻止同时由两个以上处理器缓存的内存区域数据，当其他处理器回写已被锁定的缓存行的数据时，会使缓存行无效。

## 但有两种情况下处理器不会使用缓存锁定
1. 当操作的数据不能被缓存在处理器内部，或操作的数据跨多个缓存行时，则处理器会调用总线锁定
2. 有些处理器不支持缓存锁定

# JAVA内存模型
线程之间的共享变量存储在主内存中，每个线程都有一个私有的本地内存，本地内存中存储了该线程以读/写共享变量的副本。

从JAVA源代码到最终实际执行的指令序列：

源代码->编译优化重排序->指令级并行重排序->内存系统重排序->最终执行的指令序列

## happens-before
- 程序次序规则：一个线程内，按照代码顺序，书写在前面的操作先行发生于书写在后面的操作
- 锁定规则：一个unLock操作先行发生于后面对同一个锁的lock操作
- volatile变量规则：对一个变量的写操作先行发生于后面对这个变量的读操作
- 传递规则：如果操作A先行发生于操作B，而操作B又先行发生于操作C，则可以得出操作A先行发生于操作C
- 线程启动规则：Thread对象的start()方法先行发生于此线程的每个一个动作
- 线程中断规则：对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生
- 线程终结规则：线程中所有的操作都先行发生于线程的终止检测，我们可以通过Thread.join()方法结束、Thread.isAlive()的返回值手段检测到线程已经终止执行
- 对象终结规则：一个对象的初始化完成先行发生于他的finalize()方法的开始

__第一条规则：__ 一段程序代码的执行在单个线程中看起来是有序的。注意，虽然这条规则中提到“书写在前面的操作先行发生于书写在后面的操作”，这个应该是程序看起来执行的顺序是按照代码顺序执行的，因为虚拟机可能会对程序代码进行指令重排序。虽然进行重排序，但是最终执行的结果是与程序顺序执行的结果一致的，它只会对不存在数据依赖性的指令进行重排序。因此，在单个线程中，程序执行看起来是有序执行的，这一点要注意理解。事实上，这个规则是用来保证程序在单线程中执行结果的正确性，但无法保证程序在多线程中执行的正确性。

__第二条规则:__ 第二条规则也比较容易理解，也就是说无论在单线程中还是多线程中，同一个锁如果出于被锁定的状态，那么必须先对锁进行了释放操作，后面才能继续进行lock操作。无论在单线程中还是多线程中，同一个锁如果出于被锁定的状态，那么必须先对锁进行了释放操作，后面才能继续进行lock操作。   

__第三条规则:__ 如果一个线程先去写一个变量，然后一个线程去进行读取，那么写入操作肯定会先行发生于读操作。

__第四条规则:__ happens-before原则具备传递性。

# 线程的六种状态和切换
![线程的六种状态](线程的六种状态.PNG)

|状态名称|说明|
|:--:|:--:|
|NEW|初始状态，线程被构建，但是还没有调用start方法|
|RUNNABLE|运行状态，JAVA线程将打操作系统中的就绪和运行两种状态笼统地称作"运行中"|
|BLOCKED|阻塞状态，表示线程阻塞于锁|
|WAITING|等待状态，表示线程进入等待状态，进入该状态表示当前线程需要等待其他线程做出一些特定动作(通知或中断)|
|TIME_WAITING|超时等待状态，该状态不同于WATING，它是可以直指定时间自行返回的|
|TERMINATED|终止状态，表示当前线程已经执行完毕|



# ThreadLocal使用
ThreadLocal，很多地方叫做线程本地变量，也有些地方叫做线程本地存储，其实意思差不多。可能很多朋友都知道ThreadLocal为变量在每个线程中都创建了一个副本，那么每个线程可以访问自己内部的副本变量。



# 锁接口
# AQS
![AbstractQueuedSynchronizer](AbstractQueuedSynchronizer.png)

以下所示RetreentLock的所有public方法

```java
// 获取等待队列中的线程
public final Collection<Thread> getQueuedThreads()
// 获取锁
public final void acquire(int arg)
// 获取排他模式等待队列中的线程
public final Collection<Thread> getExclusiveQueuedThreads()
// 获取等待队列的长度
public final int getQueueLength()
// 以独占模式获取，如果中断则中止
public final void acquireInterruptibly(int arg)
// 查询是否有线程争用过这个同步器
public final boolean hasContended()
// 共享模式释放锁
public final boolean releaseShared(int arg)
// 当前线程之前有排队的线程
public final boolean hasQueuedPredecessors()
// 查询给定的 ConditionObject 是否使用此同步器作为其锁
public final boolean owns(ConditionObject condition)
// 释放锁
public final boolean release(int arg)
// 获取等待队列中的第一个线程
public final Thread getFirstQueuedThread()
// 尝试以共享模式获取，如果中断则中止，如果给定的超时已过则失败
public final boolean tryAcquireSharedNanos(int arg, long nanosTimeout)
// 尝试以独占模式获取，如果中断则中止，如果超过给定的超时则失败
public final boolean tryAcquireNanos(int arg, long nanosTimeout)
// 判断线程是否已经加入等待队列
public final boolean isQueued(Thread thread)
// 判断等待队列中有线程
public final boolean hasQueuedThreads()
// 查询是否有线程正在等待与此同步器关联的给定条件
public final boolean hasWaiters(ConditionObject condition)
// 以共享模式获取，忽略中断
public final void acquireShared(int arg)
// 获取可能正在等待与此同步器关联的给定条件的那些线程
public final Collection<Thread> getWaitingThreads(ConditionObject condition)
// 以共享模式获取，如果中断则中止
public final void acquireSharedInterruptibly(int arg)
// 获取等待与此同步器关联的给定条件的线程数
public final int getWaitQueueLength(ConditionObject condition)
// 获取正在等待以共享模式获取的线程
public final Collection<Thread> getSharedQueuedThreads()

volatile int waitStatus; // 取值如下：
// 0：节点的初始状态，新建一个 Node 实例，其状态值就是 0
// 表明当前结点由于超时或者中断被取消获取这个锁
static final int CANCELLED =  1;
// 表明当前结点的后继结点需要被唤醒
static final int SIGNAL    = -1;
// 表明当前结点进入了等待队列
static final int CONDITION = -2;
// 只有 head 节点会处于这个状态，这个值存在的作用在于：连续唤醒队列中处于共享模式的节点，让他们并发获取共享资源
static final int PROPAGATE = -3;
```

RetreentLock的整体流程图如下所示：
![RetreentLock](RetreentLock.png)

具体代码路程如下：
```java
public class ReentrantLock {
    // 该Sync是一个抽象类，具体的实现是一个FairSync和NonfairSync的具体类
    private final Sync sync;
}

// AbstractQueuedSynchronizer中：
public final void acquire(int arg) {
    if (!tryAcquire(arg) && acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
// 公平锁与非公平锁的区别是公平锁多了个!hasQueuedPredecessors
// 判断当前线程是否要排队
// 如果当前线程之前有排队的线程，则返回true
// 如果当前线程之前位于队列的头部或者队列为空，则返回false
public final boolean hasQueuedPredecessors() {
    Node t = tail;
    Node h = head;
    Node s;
    return h != t 
            && ((s = h.next) == null || s.thread != Thread.currentThread());
}
protected final boolean tryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        // 没有线程持有锁，当前线程需要排队，返回获取锁失败，当前线程不需要排队，cas设置state为1，cas成功，返回获取锁成功，设置当前线程为持有锁的线程。cas失败，返回获取锁失败
        if (!hasQueuedPredecessors() && compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    // 有线程持有锁，如果是同一线程，则设置state为重入次数，返回获取锁成功。
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0)
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    // 有线程持有锁，但不是同一线程，则返回获取锁失败
    return false;
}
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        // 与公平锁的区别是不需要判断，当前线程是否需要排队
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
// tryAcquire或者nonfairTryAcquire获取锁失败，先将当前线程添加到队列尾部
private Node addWaiter(Node mode) {
    // 将节点封装成一个Node节点
    Node node = new Node(Thread.currentThread(), mode);
    Node pred = tail;
    // 如果尾结点不为空，使用cas添加当前结点
    if (pred != null) {
        node.prev = pred;
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    // 如果尾结点为空
    enq(node);
    return node;
}
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        // 如果尾结点为空，创建头结点，并将tail指向head，初始化队列
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            // 如果尾结点不为空，使用cas添加当前结点
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}
// 该函数表示将已经在队列中的node尝试去获取锁否则挂起
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            // 获取当前结点的前任结点p
            final Node p = node.predecessor();
            // 如果p为head且获取锁成功
            if (p == head && tryAcquire(arg)) {
                // 设置当前结点为head结点，设置p的后继结点为null，将q解引用
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            // 如果当前结点不是head结点或者获取锁失败
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    // 获取前驱结点的wait状态
    int ws = pred.waitStatus;
    // 如果前驱结点为SIGNAL，
    if (ws == Node.SIGNAL)
        // 前驱节点已经设置了SIGNAL，闹钟已经设好，现在我可以安心睡觉（阻塞）了。
        // 如果前驱变成了head，并且head的代表线程exclusiveOwnerThread释放了锁，
        // 就会来根据这个SIGNAL来唤醒自己
        return true;
    if (ws > 0) {
        /*
            * 发现传入的前驱的状态大于0，即CANCELLED。说明前驱节点已经因为超时或响应了中断，
            * 而取消了自己。所以需要跨越掉这些CANCELLED节点，直到找到一个<=0的节点
            */
        do {
            node.prev = pred = pred.prev;
        } while (pred.waitStatus > 0);
        pred.next = node;
    } else {
            /*
            * 进入这个分支，ws只能是0或PROPAGATE。
            * CAS设置ws为SIGNAL
            */
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
}

private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}

private void cancelAcquire(Node node) {
    // Ignore if node doesn't exist
    if (node == null)
        return;

    node.thread = null;

    // 1，找到当前节点的前一个不是cancel状态的节点
    // 并将当前节点的前指针指向其
    Node pred = node.prev;
    while (pred.waitStatus > 0)
        node.prev = pred = pred.prev;

    // 2. 将predNext设置为上面找的节点的后面一个节点
    Node predNext = pred.next;

    // Can use unconditional write instead of CAS here.
    // After this atomic step, other Nodes can skip past us.
    // Before, we are free of interference from other threads.
    node.waitStatus = Node.CANCELLED;

    // 如果当前节点是为节点，设置1找到的节点为尾节点，设置next为null
    if (node == tail && compareAndSetTail(node, pred)) {
        compareAndSetNext(pred, predNext, null);
    } else {
        
        // 如果pred不是头结点，将pred的waitStatus设置为SINGAL，设置predNext为当前节点的后继节点，该后继节点不能是cancel状态
        int ws;
        if (pred != head &&
            ((ws = pred.waitStatus) == Node.SIGNAL ||
                (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
            pred.thread != null) {
            Node next = node.next;
            if (next != null && next.waitStatus <= 0)
                compareAndSetNext(pred, predNext, next);
        } else {
            // 如果pred是头结点，则唤醒当前节点的后继节点
            unparkSuccessor(node);
        }

        node.next = node; // help GC
    }
}
private void unparkSuccessor(Node node) {
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0);
    Node s = node.next;
    if (s == null || s.waitStatus > 0) {
        s = null;
        // 从tailf节点开始向前搜索，这是为啥呢？
        // 找到node的后继第一个waitStatus不是cancel状态的节点，并将s设置为该节点
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    // 唤醒node后继中第一个不是cancel状态的节点
    if (s != null)
        LockSupport.unpark(s.thread);
}
```

trylock只有非公平锁的实现，走的是nonfairTryAcquire，等价于RetreentLock非公平锁的lock()。
```java
public boolean tryLock() {
    return sync.nonfairTryAcquire(1);
}
```
Retreent的lockInterruptibly无论是公平锁还是非公平锁都是调用的AQS的lockInterruptibly
```java
public void lockInterruptibly() throws InterruptedException {
    sync.acquireInterruptibly(1);
}

public final void acquireInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (!tryAcquire(arg))
        doAcquireInterruptibly(arg);
}

private void doAcquireInterruptibly(int arg)
    throws InterruptedException {
    final Node node = addWaiter(Node.EXCLUSIVE);
    boolean failed = true;
    try {
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                throw new InterruptedException();
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
```

RetreentLock的释放锁无论是公平锁还是非公平锁都是unlock()方法，且只有一个unLock释放锁的方法
```java
public void unlock() {
    sync.release(1);
}

// 如果tryRelease失败，则释放锁失败
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}
```
tryRelease在AQS类中是一个抽象实现，具体的实现在RetreentLock中
```java
protected final boolean tryRelease(int releases) {
    // state的值-1
    int c = getState() - releases;
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    if (c == 0) {
        free = true;
        setExclusiveOwnerThread(null);
    }
    setState(c);
    return free;
}
```
# 读写锁

# 锁膨胀，锁消除，锁升级

# ConcurrentHashMap
```java
// 表，懒初始化，当有值插入时才初始化，大小为2的n次幂
transient volatile Node<K,V>[] table;
// 只有扩容的时候不为null
private transient volatile Node<K,V>[] nextTable;
// 表初始化或者扩容控制，默认值为0。
// 当为-1时，表正在初始化，
// 当为-(1+正在扩容的线程数)，表示正在扩容
// 如果尚未进行初始化，那这个正数表示需要初始化的大小。
// 初始化后，保存的时下一次扩容的大小。
private transient volatile int sizeCtl;

// 定义节点的hash值
static final int MOVED     = -1; // hash for forwarding nodes
static final int TREEBIN   = -2; // hash for roots of trees
static final int RESERVED  = -3; // hash for transient reservations


static final int HASH_BITS = 0x7fffffff; // usable bits of normal node hash

 // views
private transient KeySetView<K,V> keySet;
private transient ValuesView<K,V> values;
private transient EntrySetView<K,V> entrySet;

static final <K,V> Node<K,V> tabAt(Node<K,V>[] tab, int i) {
    return (Node<K,V>)U.getObjectVolatile(tab, ((long)i << ASHIFT) + ABASE);
}

static final <K,V> boolean casTabAt(Node<K,V>[] tab, int i,
                                    Node<K,V> c, Node<K,V> v) {
    return U.compareAndSwapObject(tab, ((long)i << ASHIFT) + ABASE, c, v);
}

static final <K,V> void setTabAt(Node<K,V>[] tab, int i, Node<K,V> v) {
    U.putObjectVolatile(tab, ((long)i << ASHIFT) + ABASE, v);
}

// 构造函数
public ConcurrentHashMap() {}

public ConcurrentHashMap(int initialCapacity) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException();
    int cap = ((initialCapacity >= (MAXIMUM_CAPACITY >>> 1)) ?
                MAXIMUM_CAPACITY :
                tableSizeFor(initialCapacity + (initialCapacity >>> 1) + 1));
    this.sizeCtl = cap;
}

public ConcurrentHashMap(int initialCapacity, float loadFactor) {
    this(initialCapacity, loadFactor, 1);
}

public ConcurrentHashMap(int initialCapacity,float loadFactor, int concurrencyLevel) {
    if (!(loadFactor > 0.0f) || initialCapacity < 0 || concurrencyLevel <= 0)
        throw new IllegalArgumentException();
    if (initialCapacity < concurrencyLevel)   // Use at least as many bins
        initialCapacity = concurrencyLevel;   // as estimated threads
    long size = (long)(1.0 + (long)initialCapacity / loadFactor);
    int cap = (size >= (long)MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : tableSizeFor((int)size);
    this.sizeCtl = cap;
}

/**
 * 返回一个比输入值大或相等的，离该值最近的2的整数次幂
 */
private static final int tableSizeFor(int c) {
    int n = c - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}

/**
 * 
 * 将高16位与低16位异或，在与HASH_BITS
 * 
*/
static final int spread(int h) {
    return (h ^ (h >>> 16)) & HASH_BITS;
}

/**
 * 
 * n < 0取0，n > Integer.MAX_VALUE取Integer.MAX_VALUE，否则取n
 * 
*/
public int size() {
    long n = sumCount();
    return ((n < 0L) ? 0 :
            (n > (long)Integer.MAX_VALUE) ? Integer.MAX_VALUE :
            (int)n);
}

// 参考LongAdder
final long sumCount() {
    CounterCell[] as = counterCells; CounterCell a;
    long sum = baseCount;
    if (as != null) {
        for (int i = 0; i < as.length; ++i) {
            if ((a = as[i]) != null)
                sum += a.value;
        }
    }
    return sum;
}

static class Node<K,V> implements Map.Entry<K,V> {
    final int hash;
    final K key;
    volatile V val;
    volatile Node<K,V> next;

    Node(int hash, K key, V val, Node<K,V> next) {
        this.hash = hash;
        this.key = key;
        this.val = val;
        this.next = next;
    }

    public final K getKey()       { return key; }
    public final V getValue()     { return val; }
    public final int hashCode()   { return key.hashCode() ^ val.hashCode(); }
    public final String toString(){ return key + "=" + val; }
    public final V setValue(V value) {
        throw new UnsupportedOperationException();
    }

    public final boolean equals(Object o) {
        Object k, v, u; Map.Entry<?,?> e;
        return ((o instanceof Map.Entry) &&
                (k = (e = (Map.Entry<?,?>)o).getKey()) != null &&
                (v = e.getValue()) != null &&
                (k == key || k.equals(key)) &&
                (v == (u = val) || v.equals(u)));
    }

    Node<K,V> find(int h, Object k) {
        Node<K,V> e = this;
        if (k != null) {
            do {
                K ek;
                if (e.hash == h &&
                    ((ek = e.key) == k || (ek != null && k.equals(ek))))
                    return e;
            } while ((e = e.next) != null);
        }
        return null;
    }
}
```
## get方法
```java
public V get(Object key) {
    Node<K,V>[] tab; Node<K,V> e, p; int n, eh; K ek;
    // 获取key的散列值
    int h = spread(key.hashCode());
    // 如果table中有值且桶位上的元素不为null，然后继续查找值，否则直接返回null
    if ((tab = table) != null && (n = tab.length) > 0 && (e = tabAt(tab, (n - 1) & h)) != null) {
        // 如果桶位上的的key相等，则直接返回e的值
        if ((eh = e.hash) == h) {
            if ((ek = e.key) == key || (ek != null && key.equals(ek)))
                return e.val;
        }
        // 指定桶位上的节点hash值是负数
        else if (eh < 0)
            // 插入过程中，Node可能有上图几种类型，调用各自重写的find方法，然后返回该Node的val
            return (p = e.find(h, key)) != null ? p.val : null;
        // 走到这里说明是普通的链表类型 
        while ((e = e.next) != null) {
            if (e.hash == h &&
                ((ek = e.key) == key || (ek != null && key.equals(ek))))
                return e.val;
        }
    }
    return null;
}
```
以上节点类型
![Node节点类型](Node节点类型.jpg)
```java
/**
 * A place-holder node used in computeIfAbsent and compute
 */
static final class ReservationNode<K,V> extends Node<K,V> {
    ReservationNode() {
        // hash的固定值为-3
        super(RESERVED, null, null, null);
    }

    Node<K,V> find(int h, Object k) {
        return null;
    }
}

/**
 * A node inserted at head of bins during transfer operations.
 */
static final class ForwardingNode<K,V> extends Node<K,V> {
    final Node<K,V>[] nextTable;
    ForwardingNode(Node<K,V>[] tab) {
        // hash值固定为-1
        super(MOVED, null, null, null);
        this.nextTable = tab;
    }
    
    Node<K,V> find(int h, Object k) {
        //如果当前访问的节点是ForwardingNode结点，说明数组正在进行扩容，因此会去nextTable获取数据
        outer: for (Node<K,V>[] tab = nextTable;;) {
            Node<K,V> e; int n;
            if (k == null || tab == null || (n = tab.length) == 0 ||
                (e = tabAt(tab, (n - 1) & h)) == null)
                return null;
            for (;;) {
                int eh; K ek;
                if ((eh = e.hash) == h &&
                    ((ek = e.key) == k || (ek != null && k.equals(ek))))
                    return e;
                // 如果当前节点的hash值还是负数，说明节点是TreeBin节点或者ForwardingNode节点
                if (eh < 0) {
                    // 如果当前节点还是ForwardingNode节点，说明nextTable重新触发了扩容机制，再次赋值，跳出去重新查找
                    if (e instanceof ForwardingNode) {
                        tab = ((ForwardingNode<K,V>)e).nextTable;
                        continue outer;
                    }
                    else
                    // 如果是Treebin节点，则调用Treebin的find方法
                        return e.find(h, k);
                }
                if ((e = e.next) == null)
                    return null;
            }
        }
    }
}

static final class TreeBin<K,V> extends Node<K,V> {
    TreeNode<K,V> root;
    volatile TreeNode<K,V> first;
    volatile int lockState;

    static final int WRITER = 1; // set while holding write lock
    static final int WAITER = 2; // set when waiting for write lock
    static final int READER = 4; // increment value for setting read lock

    TreeBin(TreeNode<K,V> b) {
        super(TREEBIN, null, null, null);
        this.first = b;
        TreeNode<K,V> r = null;
        // ***
        this.root = r;
        // ...
    }

    final Node<K,V> find(int h, Object k) {
        if (k != null) {
            //遍历first指针指向的双向链表
            for (Node<K,V> e = first; e != null; ) {
                int s; K ek;
                //(WAITER|WRITER) -> 0010 | 0001 = 0011
                //lockState & 0011 != 0 true -> 表示后两位不为0，说明有等待者线程 或 有写线程在加锁，需要从链表读取数据
                if (((s = lockState) & (WAITER|WRITER)) != 0) {
                    if (e.hash == h && ((ek = e.key) == k || (ek != null && k.equals(ek))))
                        return e;
                    //e指向下一个元素
                    e = e.next;
                }
                //前置条件: 没有等待者线程 或 没有写线程
                //true -> 添加读锁成功 读锁是共享锁 从红黑树中读取数据
                else if (U.compareAndSwapInt(this, LOCKSTATE, s,
                                                s + READER)) {
                    TreeNode<K,V> r, p;
                    try {
                        //从根节点开始往下查找
                        p = ((r = root) == null ? null : r.findTreeNode(h, k, null));
                    } finally {
                        //w: 表示等待者线程
                        Thread w;
                        //(READER|WAITER) -> 0100 | 0010 = 0110 => 6 表示当前有一个读线程和一个等待中的写线程
                        //U.getAndAddInt(this, LOCKSTATE, -READER) 注意:这里是先get到LOCKSTATE的值与(READER|WAITER)对比后再 -4 释放读锁
                        //当前线程为最后一个读线程
                        //(w = waiter) != null true -> 有写线程在等待读操作全部结束
                        if (U.getAndAddInt(this, LOCKSTATE, -READER) ==
                            (READER|WAITER) && (w = waiter) != null)
                            //唤醒等待中的写线程
                            LockSupport.unpark(w);
                    }
                    return p;
                }
            }
        }
        return null;
    }
}

static final class TreeNode<K,V> extends Node<K,V> {
    TreeNode<K,V> parent;  // red-black tree links
    TreeNode<K,V> left;
    TreeNode<K,V> right;
    TreeNode<K,V> prev;    // needed to unlink next upon deletion
    boolean red;

    TreeNode(int hash, K key, V val, Node<K,V> next,
                TreeNode<K,V> parent) {
        super(hash, key, val, next);
        this.parent = parent;
    }

    Node<K,V> find(int h, Object k) {
        return findTreeNode(h, k, null);
    }

    /**
     * Returns the TreeNode (or null if not found) for the given key
     * starting at given root.
     */
    final TreeNode<K,V> findTreeNode(int h, Object k, Class<?> kc) {
        if (k != null) {
            //游标节点 初始值为调用该方法的节点
            TreeNode<K,V> p = this;
            do  {
                //ph: 当前游标节点的hash值
                //dir: 待插入节点位于当前游标节点的 左边 或 右边
                //pk: 当前游标节点的key
                //q: 匹配到的节点
                int ph, dir; K pk; TreeNode<K,V> q;
                //pl: 当前游标节点的左子节点
                //pr: 当前游标节点的右子节点
                TreeNode<K,V> pl = p.left, pr = p.right;
                // CASE1: 当前游标节点的hash值 > 待查找节点的hash值
                if ((ph = p.hash) > h)
                    p = pl;
                // CASE2: 当前游标节点的hash值 < 待查找节点的hash值
                else if (ph < h)
                    p = pr;
                // 前置条件: 当前游标节点的hash值 == 待查找节点的hash值
                // CASE3: 当前游标节点的key == 待查找的节点的key，返回p
                else if ((pk = p.key) == k || (pk != null && k.equals(pk)))
                    return p;
                //前置条件: 1、当前游标节点的hash值 == 待查找节点的hash值
                //         2、当前游标节点的key != 待查找的节点的key
                // CASE4: 当前游标节点的左子节点是null
                else if (pl == null)
                    p = pr;
                //前置条件: 1、当前游标节点的hash值 == 待查找节点的hash值
                //        2、当前游标节点的key != 待查找的节点的key
                // CASE4: 当前游标节点的右子节点是null
                else if (pr == null)
                    p = pl;
                //前置条件: 1、当前游标节点的hash值 == 待查找节点的hash值
                //         2、当前游标节点的key != 待查找的节点的key
                //         3、当前游标节点的左、右节点 != null
                // CASE5: 获取待查找节点的key的class类型 并计算出dir
                else if ((kc != null ||
                            (kc = comparableClassFor(k)) != null) &&
                            (dir = compareComparables(kc, k, pk)) != 0)
                    p = (dir < 0) ? pl : pr;
                //前置条件: 1、当前游标节点的hash值 == 待查找节点的hash值
                //        2、当前游标节点的key != 待查找的节点的key
                //        3、当前游标节点的左、右节点 != null
                //        4、无法通过待查找节点key的class类型计算dir
                // CASE6: 遍历当前游标节点的整个右子树
                else if ((q = pr.findTreeNode(h, k, kc)) != null)
                    return q;
                //前置条件: 1、当前游标节点的hash值 == 待查找节点的hash值
                //        2、当前游标节点的key != 待查找的节点的key
                //        3、当前游标节点的左、右节点 != null
                //        4、无法通过待查找节点key的class类型计算dir
                //        5、遍历当前游标节点的整个右子树还是未找到
                // CASE7: 从左子节点开始继续找
                else
                    p = pl;
            } while (p != null);
        }
        return null;
    }
}
```

## put操作
```java
final V putVal(K key, V value, boolean onlyIfAbsent) {
    // 防止二义性，get操作时不知道put操作的是null，还是这个值不存在
    if (key == null || value == null) throw new NullPointerException();
    int hash = spread(key.hashCode());
    int binCount = 0; // 链表时表示该桶位上的节点有多少个，用于转红黑树，以及判断是否需要扩容
    for (Node<K,V>[] tab = table;;) {
        Node<K,V> f; int n, i, fh;
        // f是桶位置上的元素
        // n是table的长度
        // i是桶位置
        // fh是桶位置元素的hash值
        if (tab == null || (n = tab.length) == 0)
            // 如果table为空的话，就初始化table
            tab = initTable();
        else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
            // 如果桶位置为空的话，就使用cas设置元素到桶位置
            if (casTabAt(tab, i, null,
                            new Node<K,V>(hash, key, value, null)))
                break;                   // no lock when adding to empty bin
        }
        else if ((fh = f.hash) == MOVED)
            // 如果桶位置元素的hash值为MOVED，说明在进行扩容，该线程去帮助扩容
            tab = helpTransfer(tab, f);
        else {
            // 锁桶位置，然后里面的使用cas设置值，如果链表大于8就转红黑树
            V oldVal = null;
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    if (fh >= 0) {
                        // 普通的链表类型
                        binCount = 1;
                        
                        for (Node<K,V> e = f;; ++binCount) {
                            K ek;
                            // hash相同，key也相同
                            if (e.hash == hash 
                                    && ((ek = e.key) == key 
                                    || (ek != null && key.equals(ek)))) {
                                oldVal = e.val;
                                if (!onlyIfAbsent)
                                    e.val = value;
                                break;
                            }
                            Node<K,V> pred = e;
                            // 这里采用的尾插
                            if ((e = e.next) == null) {
                                pred.next = new Node<K,V>(hash, key,
                                                            value, null);
                                break;
                            }
                        }
                    }
                    else if (f instanceof TreeBin) {
                        // 红黑树类型
                        Node<K,V> p;
                        binCount = 2;
                        if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
                                                        value)) != null) {
                            oldVal = p.val;
                            if (!onlyIfAbsent)
                                p.val = value;
                        }
                    }
                }
            }
            if (binCount != 0) {
                if (binCount >= TREEIFY_THRESHOLD)
                    treeifyBin(tab, i);
                // old有值就是覆盖，不需要后面计数了，直接返回
                if (oldVal != null)
                    return oldVal;
                break;
            }
        }
    }

    // 使用LongAdder思想增加1
    addCount(1L, binCount);
    return null;
}

/**初始化table*/
private final Node<K,V>[] initTable() {
    Node<K,V>[] tab; int sc;
    while ((tab = table) == null || tab.length == 0) {
        if ((sc = sizeCtl) < 0) // 说明有其他线程正在初始化表格
            Thread.yield(); // lost initialization race; just spin
        else if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
            // 将SIZECTL设置为-1
            try {
                if ((tab = table) == null || tab.length == 0) {
                    int n = (sc > 0) ? sc : DEFAULT_CAPACITY;
                    @SuppressWarnings("unchecked")
                    Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                    table = tab = nt;
                    // n - 0.25n = 0.75n，就算下一次扩容的大小
                    sc = n - (n >>> 2); 
                }
            } finally {
                sizeCtl = sc;
            }
            break;
        }
    }
    return tab;
}

// 帮助扩容的函数
// tab：表
// f：桶位元素 
final Node<K,V>[] helpTransfer(Node<K,V>[] tab, Node<K,V> f) {
    Node<K,V>[] nextTab; int sc;
    // 如果有线程在扩容时，会将该桶位元素设置为ForwardingNode，然后在转移元素
    if (tab != null && (f instanceof ForwardingNode) &&
        (nextTab = ((ForwardingNode<K,V>)f).nextTable) != null) {
        int rs = resizeStamp(tab.length);
        while (nextTab == nextTable && table == tab &&
                (sc = sizeCtl) < 0) {
            if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                sc == rs + MAX_RESIZERS || transferIndex <= 0)
                break;
            if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1)) {
                transfer(tab, nextTab);
                break;
            }
        }
        return nextTab;
    }
    return table;
}

// 使用LongAdder思想增加1, putVal中调用addCount(1L, binCount);
// 设置桶元素成功时，bitcount为0，即check为0
// 设置链表时，链表下面有bitcount个元素，即这里的check为bitcount的个数，该bitcount必定大于等于2
// 设置红黑树时，这里的bitcount为2，即check为2
// remove和clear时，check为-1
private final void addCount(long x, int check) {
    CounterCell[] as; long b, s;
    if ((as = counterCells) != null ||
        !U.compareAndSwapLong(this, BASECOUNT, b = baseCount, s = b + x)) {
        CounterCell a; long v; int m;
        boolean uncontended = true;
        if (as == null || (m = as.length - 1) < 0 
                || (a = as[ThreadLocalRandom.getProbe() & m]) == null 
                || !(uncontended = U.compareAndSwapLong(a, CELLVALUE, v = a.value, v + x))) {
        /**当不得已走到fullAddCount()，这个方法是一定会修改元素个数成功的，但是成功就立刻退出整个addCount方法了，不再向后判断扩容？
         * 个人猜想：
         * 1. 假设走到fullAddCount是因为CounterCell[] as为空，那么外围的if，就是 cas 修改baseCount失败了，说明有其他线程修改成功了由它去检查是否扩容。
         * 2. 假设走到fullAddCount是因为 cas 修改counterCell失败，说明有其他线程修改成功，则由它去检查扩容。
         * 3. 既然都执行到fullAddCount，这个方法流程上还是比较复杂的，可能较为耗时，作者意图应该是不想让客户端调用时间太长，既然有其他线程去检查扩容了，当前线程就结束吧，不要让调用者等太久。*/
            fullAddCount(x, uncontended);
            return;
        }
        if (check <= 1)
            return;
        s = sumCount();
    }
    // 替换节点和清空数组时，check=-1，只做元素个数递减，不会触发扩容检查，也不会缩容
    if (check >= 0) {
        Node<K,V>[] tab, nt; int n, sc;
        while (s >= (long)(sc = sizeCtl) && (tab = table) != null 
                && (n = tab.length) < MAXIMUM_CAPACITY) {
            // 1. 当总数大于阈值时；2. table部位null；3. table的长度小于最大值
            int rs = resizeStamp(n);
            if (sc < 0) {
                // 参与扩容的线程干完了自己的活儿，重新检测发现还需要扩容
                if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                    sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                    transferIndex <= 0)
                    break;
                if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                    transfer(tab, nt);
            }
            else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                            (rs << RESIZE_STAMP_SHIFT) + 2))
                // 第一个扩容的线程走这里
                transfer(tab, null);
            s = sumCount();
        }
    }
}

/**
 * n是table的长度
 * 计算扩容时间戳
 * 因为hashtable的长度必是2的n次方，所以记录一下2的n次方转为二进制后，1的前面有几个0即可确认table的长度了
 * 前面一个是计算n的转为2进制后1的前面的0的个数，后面是一个是1左移16 - 1 = 15位，将其设置为负数
 * 举例：前16位是table的长度，后16位是扩容的线程数
 * resizeStamp(16) << 16        => 1000 0000 0001 1011 0000 0000 0000 0000 => -2145714176
 * (resizeStamp(16) << 16) + 1  => 1000 0000 0001 1011 0000 0000 0000 0001 => -2145714175
 * (resizeStamp(16) << 16) + 2  => 1000 0000 0001 1011 0000 0000 0000 0010 => -2145714174
*/
static final int resizeStamp(int n) {
    return Integer.numberOfLeadingZeros(n) | (1 << (RESIZE_STAMP_BITS - 1));
}
```
![扩容戳](扩容戳.png)

```java
/**扩容的过程*/ 
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    int n = tab.length, stride;
    if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE)
        stride = MIN_TRANSFER_STRIDE; // subdivide range
    if (nextTab == null) {            // initiating
        try {
            @SuppressWarnings("unchecked")
            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
            nextTab = nt;
        } catch (Throwable ex) {      // try to cope with OOME
            sizeCtl = Integer.MAX_VALUE;
            return;
        }
        nextTable = nextTab;
        transferIndex = n;
    }
    int nextn = nextTab.length;
    ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);
    // 判断当前桶位是否已经转移完毕
    boolean advance = true;
    boolean finishing = false; // to ensure sweep before committing nextTab
    for (int i = 0, bound = 0;;) {
        Node<K,V> f; int fh;
        while (advance) {
            int nextIndex, nextBound;
            if (--i >= bound || finishing)
                // 无论哪个线程第一次都不走这里， --0 >= 0都是false
                advance = false;
            else if ((nextIndex = transferIndex) <= 0) {
                // 根据transferIndex获取当前线程需要从哪个index开始转移，如果<=0，说明已经分配完毕
                i = -1;
                advance = false;
            }
            else if (U.compareAndSwapInt
                        (this, TRANSFERINDEX, nextIndex,
                        nextBound = (nextIndex > stride ?
                                    nextIndex - stride : 0))) {
                // 设置transferIndex，其他线程根据这个标记位，分配自己需要执行的任务
                bound = nextBound;
                // 根据transferIndex - 1设置i，即从第i个位置开始转移
                i = nextIndex - 1;
                advance = false;
            }
        }
        if (i < 0 || i >= n || i + n >= nextn) {
            // 当前线程分配的任务结束
            int sc;
            if (finishing) {
                nextTable = null;
                table = nextTab;
                sizeCtl = (n << 1) - (n >>> 1);
                return;
            }
            if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {
                if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)
                    return;
                finishing = advance = true;
                i = n; // recheck before commit
            }
        }
        else if ((f = tabAt(tab, i)) == null)
            // 设置桶位元素
            advance = casTabAt(tab, i, null, fwd);
        else if ((fh = f.hash) == MOVED)
            // 当前桶位被标记位 MOVED
            advance = true; // already processed
        else {
            // 转移桶位元素
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    Node<K,V> ln, hn;
                    if (fh >= 0) {
                        int runBit = fh & n;
                        Node<K,V> lastRun = f;
                        for (Node<K,V> p = f.next; p != null; p = p.next) {
                            int b = p.hash & n;
                            if (b != runBit) {
                                runBit = b;
                                lastRun = p;
                            }
                        }
                        if (runBit == 0) {
                            ln = lastRun;
                            hn = null;
                        }
                        else {
                            hn = lastRun;
                            ln = null;
                        }
                        for (Node<K,V> p = f; p != lastRun; p = p.next) {
                            int ph = p.hash; K pk = p.key; V pv = p.val;
                            if ((ph & n) == 0)
                                ln = new Node<K,V>(ph, pk, pv, ln);
                            else
                                hn = new Node<K,V>(ph, pk, pv, hn);
                        }
                        setTabAt(nextTab, i, ln);
                        setTabAt(nextTab, i + n, hn);
                        setTabAt(tab, i, fwd);
                        advance = true;
                    }
                    else if (f instanceof TreeBin) {
                        TreeBin<K,V> t = (TreeBin<K,V>)f;
                        TreeNode<K,V> lo = null, loTail = null;
                        TreeNode<K,V> hi = null, hiTail = null;
                        int lc = 0, hc = 0;
                        for (Node<K,V> e = t.first; e != null; e = e.next) {
                            int h = e.hash;
                            TreeNode<K,V> p = new TreeNode<K,V>
                                (h, e.key, e.val, null, null);
                            if ((h & n) == 0) {
                                if ((p.prev = loTail) == null)
                                    lo = p;
                                else
                                    loTail.next = p;
                                loTail = p;
                                ++lc;
                            }
                            else {
                                if ((p.prev = hiTail) == null)
                                    hi = p;
                                else
                                    hiTail.next = p;
                                hiTail = p;
                                ++hc;
                            }
                        }
                        ln = (lc <= UNTREEIFY_THRESHOLD) ? untreeify(lo) :
                            (hc != 0) ? new TreeBin<K,V>(lo) : t;
                        hn = (hc <= UNTREEIFY_THRESHOLD) ? untreeify(hi) :
                            (lc != 0) ? new TreeBin<K,V>(hi) : t;
                        setTabAt(nextTab, i, ln);
                        setTabAt(nextTab, i + n, hn);
                        setTabAt(tab, i, fwd);
                        advance = true;
                    }
                }
            }
        }
    }
}
```
## remove操作
```java
public V remove(Object key) {
    return replaceNode(key, null, null);
}

final V replaceNode(Object key, V value, Object cv) {
    int hash = spread(key.hashCode());
    for (Node<K,V>[] tab = table;;) {
        Node<K,V> f; int n, i, fh;
        // f是table的桶位元素，n是table的长度，i是桶位置，fh是桶位元素的hash值
        if (tab == null || (n = tab.length) == 0 ||
            (f = tabAt(tab, i = (n - 1) & hash)) == null)
            break;
        else if ((fh = f.hash) == MOVED)
            // 辅助扩容，完毕之后，循环到下次，在执行remove操作
            tab = helpTransfer(tab, f);
        else {
            V oldVal = null;
            boolean validated = false;
            synchronized (f) { // 锁住桶位元素
                if (tabAt(tab, i) == f) {
                    if (fh >= 0) { // 说明是普通链表
                        validated = true;
                        for (Node<K,V> e = f, pred = null;;) {
                            // 普通节点remove
                            K ek;
                            if (e.hash == hash &&
                                ((ek = e.key) == key ||
                                    (ek != null && key.equals(ek)))) {
                                V ev = e.val;
                                if (cv == null || cv == ev ||
                                    (ev != null && cv.equals(ev))) {
                                    oldVal = ev;
                                    if (value != null)
                                        e.val = value;
                                    else if (pred != null)
                                        pred.next = e.next;
                                    else
                                        setTabAt(tab, i, e.next);
                                }
                                break;
                            }
                            pred = e;
                            if ((e = e.next) == null)
                                break;
                        }
                    }
                    else if (f instanceof TreeBin) {
                        // 树节点remove
                        validated = true;
                        TreeBin<K,V> t = (TreeBin<K,V>)f;
                        TreeNode<K,V> r, p;
                        if ((r = t.root) != null &&
                            (p = r.findTreeNode(hash, key, null)) != null) {
                            V pv = p.val;
                            if (cv == null || cv == pv ||
                                (pv != null && cv.equals(pv))) {
                                oldVal = pv;
                                if (value != null)
                                    p.val = value;
                                else if (t.removeTreeNode(p))
                                    setTabAt(tab, i, untreeify(t.first));
                            }
                        }
                    }
                }
            }
            if (validated) {
                if (oldVal != null) {
                    if (value == null)
                        // 总数 - 1 
                        addCount(-1L, -1);
                    return oldVal;
                }
                break;
            }
        }
    }
    return null;
}

final boolean removeTreeNode(TreeNode<K,V> p) {
    TreeNode<K,V> next = (TreeNode<K,V>)p.next;
    TreeNode<K,V> pred = p.prev;  // unlink traversal pointers
    TreeNode<K,V> r, rl;
    if (pred == null)
        first = next;
    else
        pred.next = next;
    if (next != null)
        next.prev = pred;
    if (first == null) {
        root = null;
        return true;
    }
    if ((r = root) == null || r.right == null || // too small
        (rl = r.left) == null || rl.left == null)
        return true;
    lockRoot();
    try {
        TreeNode<K,V> replacement;
        TreeNode<K,V> pl = p.left;
        TreeNode<K,V> pr = p.right;
        if (pl != null && pr != null) {
            TreeNode<K,V> s = pr, sl;
            while ((sl = s.left) != null) // find successor
                s = sl;
            boolean c = s.red; s.red = p.red; p.red = c; // swap colors
            TreeNode<K,V> sr = s.right;
            TreeNode<K,V> pp = p.parent;
            if (s == pr) { // p was s's direct parent
                p.parent = s;
                s.right = p;
            }
            else {
                TreeNode<K,V> sp = s.parent;
                if ((p.parent = sp) != null) {
                    if (s == sp.left)
                        sp.left = p;
                    else
                        sp.right = p;
                }
                if ((s.right = pr) != null)
                    pr.parent = s;
            }
            p.left = null;
            if ((p.right = sr) != null)
                sr.parent = p;
            if ((s.left = pl) != null)
                pl.parent = s;
            if ((s.parent = pp) == null)
                r = s;
            else if (p == pp.left)
                pp.left = s;
            else
                pp.right = s;
            if (sr != null)
                replacement = sr;
            else
                replacement = p;
        }
        else if (pl != null)
            replacement = pl;
        else if (pr != null)
            replacement = pr;
        else
            replacement = p;
        if (replacement != p) {
            TreeNode<K,V> pp = replacement.parent = p.parent;
            if (pp == null)
                r = replacement;
            else if (p == pp.left)
                pp.left = replacement;
            else
                pp.right = replacement;
            p.left = p.right = p.parent = null;
        }

        // 红黑树的重新平衡
        root = (p.red) ? r : balanceDeletion(r, replacement);

        if (p == replacement) {  // detach pointers
            TreeNode<K,V> pp;
            if ((pp = p.parent) != null) {
                if (p == pp.left)
                    pp.left = null;
                else if (p == pp.right)
                    pp.right = null;
                p.parent = null;
            }
        }
    } finally {
        unlockRoot();
    }
    assert checkInvariants(root);
    return false;
}

private final void lockRoot() {
    if (!U.compareAndSwapInt(this, LOCKSTATE, 0, WRITER))
        contendedLock(); // offload to separate method
}

/**
 * Releases write lock for tree restructuring.
 */
private final void unlockRoot() {
    lockState = 0;
}

private final void contendedLock() {
    boolean waiting = false;
    for (int s;;) {
        if (((s = lockState) & ~WAITER) == 0) {
            if (U.compareAndSwapInt(this, LOCKSTATE, s, WRITER)) {
                if (waiting)
                    waiter = null;
                return;
            }
        }
        else if ((s & WAITER) == 0) {
            if (U.compareAndSwapInt(this, LOCKSTATE, s, s | WAITER)) {
                waiting = true;
                waiter = Thread.currentThread();
            }
        }
        else if (waiting)
            LockSupport.park(this);
    }
}
```
# ForkJoin

# CountDownLatch

# 同步屏障CyclicBarrier

# 控制并发线程数的Semaphore

# 线程池
如果workercount < corePoolSize，则创建并启动一个线程来执行新提交的任务
如果workercount >= corePoolSize，且线程池内的阻塞队列未满，则将任务添加到阻塞队列中
如果workercount >= corePoolSize && workercount < maximumPoolSize，如果线程池内的阻塞队列已满，则创建并启动一个线程来执行新提交的任务
如果workercount >= maximumPoolSize，如果阻塞队列已满，则根据拒绝策来处理该任务，默认的处理方式是直接抛异常

```java
// COUNT_BITS = 29，前三位用来表示线程池的状态，后29位表示工作线程数。
// 线程池有5种状态，只用2个bit位无法表示全部，因此需要3个bit位
private static final int COUNT_BITS = Integer.SIZE - 3;
// 0001 1111 1111 1111 1111 1111 1111 1111
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;
// 取前3位的值
private static int runStateOf(int c)     { return c & ~CAPACITY; }
// 取后29位的值
private static int workerCountOf(int c)  { return c & CAPACITY; }

// 线程池的状态
// 1110 0000 0000 0000 0000 0000 0000 0000
private static final int RUNNING    = -1 << COUNT_BITS;
// 0000 0000 0000 0000 0000 0000 0000 0000
private static final int SHUTDOWN   =  0 << COUNT_BITS;
// 0010 0000 0000 0000 0000 0000 0000 0000
private static final int STOP       =  1 << COUNT_BITS;
// 0100 0000 0000 0000 0000 0000 0000 0000
private static final int TIDYING    =  2 << COUNT_BITS;
// 0110 0000 0000 0000 0000 0000 0000 0000
private static final int TERMINATED =  3 << COUNT_BITS;
// 初始值是：1110 0000 0000 0000 0000 0000 0000 0000
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
// 查看线程池状态
private static boolean runStateLessThan(int c, int s) {
    return c < s;
}
private static boolean runStateAtLeast(int c, int s) {
    return c >= s;
}
private static boolean isRunning(int c) {
    return c < SHUTDOWN;
}
```
线程池的入口
```java
<T> Future<T> submit(Callable<T> task);
<T> Future<T> submit(Runnable task, T result);
Future<?> submit(Runnable task);
void execute(Runnable command);
```
submit可以传入Runnable和Callable，execute只能传Runnable。<br/>
FutureTask实现了RunnableFuture接口。FutureTask构造器中，将Runnable转化为Callable接口。<br/>
submit中将Runnable和Callable封装成FutureTask类，然后调用execute(futuretask)。

```java
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    else if (!addWorker(command, false))
        reject(command);
}

// 1). 采用cas将工作线程数加1，2). 新建线程并启用
private boolean addWorker(Runnable firstTask, boolean core) {
    // 1). 采用cas将工作线程数加1
    retry:
    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);
        // 如果线程池的状态是STOP, TIDYING,TERMINATED的话，添加任务失败
        // 如果线程池的态态是SHUTDOWN，首个任务不为null或者阻塞队列为空的话，添加任务失败
        if (rs >= SHUTDOWN && !(rs == SHUTDOWN && firstTask == null && !workQueue.isEmpty()))
            return false;

        for (;;) {
            int wc = workerCountOf(c);
            if (wc >= CAPACITY || wc >= (core ? corePoolSize : maximumPoolSize))
                return false;
            if (compareAndIncrementWorkerCount(c))
                break retry;
            // 有其他线程改变了线程池的状态，重新检测一下
            c = ctl.get();  // Re-read ctl
            if (runStateOf(c) != rs)
                continue retry;
            // else CAS failed due to workerCount change; retry inner loop
        }
    }
    // 2). 新建线程并启用
    boolean workerStarted = false;
    boolean workerAdded = false;
    Worker w = null;
    try {
        w = new Worker(firstTask);
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            try {
                // Recheck while holding lock.
                // Back out on ThreadFactory failure or if
                // shut down before lock acquired.
                int rs = runStateOf(ctl.get());
                // 如果是RUNNING，则继续
                // 如果是SHUTDOWN的话，且firstTask为null的话，则继续
                if (rs < SHUTDOWN || (rs == SHUTDOWN && firstTask == null)) {
                    if (t.isAlive()) // precheck that t is startable
                        throw new IllegalThreadStateException();
                    workers.add(w);
                    int s = workers.size();
                    if (s > largestPoolSize)
                        largestPoolSize = s;
                    workerAdded = true;
                }
            } finally {
                mainLock.unlock();
            }
            if (workerAdded) {
                t.start();
                workerStarted = true;
            }
        }
    } finally {
        if (! workerStarted)
            addWorkerFailed(w);
    }
    return workerStarted;
}

private void addWorkerFailed(Worker w) {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        if (w != null)
            workers.remove(w);
        // 工作线程数-1
        decrementWorkerCount();
        // 尝试中断线程
        tryTerminate();
    } finally {
        mainLock.unlock();
    }
}

final void tryTerminate() {
    for (;;) {
        int c = ctl.get();
        // 如果是Running，不中断
        // 如果是TIDYING或者TERMINATED，不中断
        // 如果是SHUTDOWN状态且队列不为空，不中断
        if (isRunning(c) 
            || runStateAtLeast(c, TIDYING) 
            || (runStateOf(c) == SHUTDOWN && ! workQueue.isEmpty()))
            return;
        // 如果是SHUTDOWN且队列为空或者STOP状态，工作线程数不为0，尝试中断一个空闲线程
        if (workerCountOf(c) != 0) { // Eligible to terminate
            // ONLY_ONE为true，中断一个，在processWorkerExit中，也会执行tryTerminate，起到传播的作用
            interruptIdleWorkers(ONLY_ONE);
            return;
        }
        
        // 如果是SHUTDOWN且队列为空或者STOP状态，工作线程数为0，走terminated()
        // 方法进行到这里说明线程池所有条件都已经满足关闭的要求，下面的操作就是将线程池状态置为TERMINATED
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            if (ctl.compareAndSet(c, ctlOf(TIDYING, 0))) {
                try {
                    // 空实现
                    terminated();
                } finally {
                    ctl.set(ctlOf(TERMINATED, 0));
                    termination.signalAll();
                }
                return;
            }
        } finally {
            mainLock.unlock();
        }
        // else retry on failed CAS
    }
}

private void interruptIdleWorkers(boolean onlyOne) {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        for (Worker w : workers) {
            Thread t = w.thread;
            if (!t.isInterrupted() && w.tryLock()) {
                try {
                    t.interrupt();
                } catch (SecurityException ignore) {
                } finally {
                    w.unlock();
                }
            }
            if (onlyOne)
                break;
        }
    } finally {
        mainLock.unlock();
    }
}
```
上述addWorker中， w = new Worker(firstTask);final Thread t = w.thread;t.start();
```java
private final class Worker extends AbstractQueuedSynchronizer implements Runnable {
    Worker(Runnable firstTask) {
        setState(-1); // inhibit interrupts until runWorker
        this.firstTask = firstTask;
        this.thread = getThreadFactory().newThread(this);
    }

    public void run() {
        runWorker(this);
    }
}

final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock(); // allow interrupts
    boolean completedAbruptly = true;
    try {
        // 如果null和下一个任务为null，则跳出循环
        while (task != null || (task = getTask()) != null) {
            w.lock();
            // If pool is stopping, ensure thread is interrupted;
            // if not, ensure thread is not interrupted.  This
            // requires a recheck in second case to deal with
            // shutdownNow race while clearing interrupt
            if ((runStateAtLeast(ctl.get(), STOP) || (Thread.interrupted() && runStateAtLeast(ctl.get(), STOP))) 
                && !wt.isInterrupted())
                wt.interrupt();
            try {
                beforeExecute(wt, task); // 空实现
                Throwable thrown = null;
                try {
                    // 如果调用的execute会抛出异常
                    // 如果调用的是submit，task是FutureTask，走的是FutureTask的run
                    task.run();
                } catch (RuntimeException x) {
                    thrown = x; throw x;
                } catch (Error x) {
                    thrown = x; throw x;
                } catch (Throwable x) {
                    thrown = x; throw new Error(x);
                } finally {
                    afterExecute(task, thrown);// 空实现
                }
            } finally {
                task = null;
                w.completedTasks++;
                w.unlock();
            }
        }
        completedAbruptly = false;
    } finally {
        processWorkerExit(w, completedAbruptly);
    }
}
// FutureTask的run
public void run() {
    if (state != NEW ||
        !UNSAFE.compareAndSwapObject(this, runnerOffset,
                                        null, Thread.currentThread()))
        return;
    try {
        Callable<V> c = callable;
        if (c != null && state == NEW) {
            V result;
            boolean ran;
            try {
                result = c.call();
                ran = true;
            } catch (Throwable ex) {
                result = null;
                ran = false;
                // 会将异常吃掉
                setException(ex);
            }
            if (ran)
                set(result);
        }
    } finally {
        // runner must be non-null until state is settled to
        // prevent concurrent calls to run()
        runner = null;
        // state must be re-read after nulling runner to prevent
        // leaked interrupts
        int s = state;
        if (s >= INTERRUPTING)
            handlePossibleCancellationInterrupt(s);
    }
}

protected void setException(Throwable t) {
    // 设置FutureTask的状态
    if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
        // 设置FutureTask的outcome为异常
        outcome = t;
        // 设置FutureTask的状态
        UNSAFE.putOrderedInt(this, stateOffset, EXCEPTIONAL); // final state
        finishCompletion();
    }
}

protected void set(V v) {
    // 设置FutureTask的状态
    if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
         // 设置FutureTask的outcome为异常
        outcome = v;
         // 设置FutureTask的状态
        UNSAFE.putOrderedInt(this, stateOffset, NORMAL); // final state
        finishCompletion();
    }
}

/**
 * Removes and signals all waiting threads, invokes done(), and
 * nulls out callable.
 */
// 一个FutureTask完成了
private void finishCompletion() {
    // assert state > COMPLETING;
    for (WaitNode q; (q = waiters) != null;) {
        if (UNSAFE.compareAndSwapObject(this, waitersOffset, q, null)) {
            for (;;) {
                Thread t = q.thread;
                if (t != null) {
                    q.thread = null;
                    LockSupport.unpark(t);
                }
                WaitNode next = q.next;
                if (next == null)
                    break;
                q.next = null; // unlink to help gc
                q = next;
            }
            break;
        }
    }

    done();

    callable = null;        // to reduce footprint
}

private Runnable getTask() {
    boolean timedOut = false; // Did the last poll() time out?

    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);
        // 如果线程池的状态是STOP, TIDYING或者是TERMINATED状态的话，工作线程数-1，并返回null
        // 如果线程池的状态是SHUTDOWN的话，阻塞队列是空的话，工作线程数-1， 并返回null
        if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
            decrementWorkerCount();
            return null;
        }

        int wc = workerCountOf(c);

        // wc > maximumPoolSize的情况是因为可能在此方法执行阶段同时执行了setMaximumPoolSize方法
        // timed && timedOut如果为true，表示当前操作进行超时控制，并且上次从阻塞队列中获取任务发生了超时
        // 接下来判断，如果有效线程数量 > 1，或者阻塞队列是空的，那么尝试将workerCount减1;
        // 如果减1失败，则返回重试。
        // 如果wc == 1，也就说明当前线程是线程池唯一的一个线程
        boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
        // 如果工作线程数大于最大线程数或者核心线程数，或者设置了超时时间
        // 并且工作线程数大于1或者阻塞队列为空，工作线程数-1，并返回null
        if ((wc > maximumPoolSize || (timed && timedOut))
            && (wc > 1 || workQueue.isEmpty())) {
            if (compareAndDecrementWorkerCount(c))
                return null;
            continue;
        }

        try {
            // 如果工作线程数大于核心线程数或设置超时时间，走workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS)，否则阻塞取任务
            Runnable r = timed ? workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) : workQueue.take();
            if (r != null)
                return r;
            timedOut = true;
        } catch (InterruptedException retry) {
            timedOut = false;
        }
    }
}

private void processWorkerExit(Worker w, boolean completedAbruptly) {
    if (completedAbruptly) // If abrupt, then workerCount wasn't adjusted
        decrementWorkerCount();

    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        completedTaskCount += w.completedTasks;
        workers.remove(w);
    } finally {
        mainLock.unlock();
    }

    tryTerminate();

    // 当线程池是running或shutdown状态时，如果worker是异常结束，那么会直接addWorker
    // 如果allowCoreThreadTimeOut=true,并且等待队列有任务，至少保留一个worker
    // 如果allowCoreThreadTimeOut=false，worker不少于corePoolSize
    int c = ctl.get();
    // 如果线程池的状态是RUNNING或者是SHUTDOWN
    if (runStateLessThan(c, STOP)) {
        // 当前worker退出run方法
        if (!completedAbruptly) {
            // 设置了超时时间，min为0，否则min为核心线程数
            int min = allowCoreThreadTimeOut ? 0 : corePoolSize;
            // 如果min为0，且阻塞队列不为空，则min为1
            if (min == 0 && ! workQueue.isEmpty())
                min = 1;
            // 如果当前工作线程数 >= min，不创建线程
            if (workerCountOf(c) >= min)
                return; // replacement not needed
        }
        // 重新创建一个线程
        addWorker(null, false);
    }
}
```

线程池的出口
```java
void shutdown();
List<Runnable> shutdownNow();
boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException;
```
- shutdown流程
1. 修改线程池状态为SHUTDOWN
2. 不再接收新提交的任务
3. 中断线程池中空闲的线程
4. 第3步只是中断了空闲的线程，但正在执行的任务以及线程池任务队列中的任务会继续执行完毕

- shutdownNow流程
1. 修改线程池状态为STOP
2. 不再接收任务提交
3. 尝试中断线程池中所有的线程（包括正在执行的线程）
4. 返回正在等待执行的任务列表 List<Runnable\>

- awaitTermination，可以配合shutdown使用
它本身并不是用来关闭线程池的，而是主要用来判断线程池状态的。比如我们给 awaitTermination 方法传入的参数是 10 秒，那么它就会陷入 10 秒钟的等待，直到发生以下三种情况之一：
1. 等待期间（包括进入等待状态之前）线程池已关闭并且所有已提交的任务（包括正在执行的和队列中等待的）都执行完毕，相当于线程池已经“终结”了，方法便会返回 true；
2. 等待超时时间到后，第一种线程池“终结”的情况始终未发生，方法返回 false；
3. 等待期间线程被中断，方法会抛出 InterruptedException 异常。
也就是说，调用 awaitTermination 方法后当前线程会尝试等待一段指定的时间，如果在等待时间内，线程池已关闭并且内部的任务都执行完毕了，也就是说线程池真正“终结”了，那么方法就返回 true，否则超时返回 fasle。
```java
public void shutdown() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        // 检查方法调用方是否用权限关闭线程池以及中断工作线程
        checkShutdownAccess();
        // 设置线程池的状态为SHUTDOWN
        advanceRunState(SHUTDOWN);
        // 中断所有空闲线程
        interruptIdleWorkers();
        // 此方法在ThreadPoolExecutor中是空实现，具体实现在其子类ScheduledThreadPoolExecutor
        // 中，用于取消延时任务。
        onShutdown(); // hook for ScheduledThreadPoolExecutor
    } finally {
        mainLock.unlock();
    }
    // 尝试将线程池置为TERMINATED状态
    tryTerminate();
}
private void interruptIdleWorkers() {
    interruptIdleWorkers(false);
}
// 中断空闲线程，如果参数为false，中断所有空闲线程，如果为true，则只中断一个空闲线程
private void interruptIdleWorkers(boolean onlyOne) {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        for (Worker w : workers) {
            Thread t = w.thread;
            // 如果线程还未中断且处于空闲状态，将其中断。
            // if条件的前半部分很好理解
            // 后半部分 w.tryLock() 方法调用了tryAcquire(int)方法 (继承自AQS)，也就是尝试以独占的方式获取资源，
            // 成功则返回true，表示线程处于空闲状态；失败会返回false，表示线程处于工作状态。
            if (!t.isInterrupted() && w.tryLock()) {
                try {
                    t.interrupt();
                } catch (SecurityException ignore) {
                } finally {
                    w.unlock();
                }
            }
            // 如果为true，表示只中断一个空闲线程，并退出循环，这一情况只会用在tryTerminate()方法中
            if (onlyOne)
                break;
        }
    } finally {
        mainLock.unlock();
    }
}

public List<Runnable> shutdownNow() {
    List<Runnable> tasks;
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        // 检查方法调用方是否用权限关闭线程池以及中断工作线程
        checkShutdownAccess();
        // 设置线程池的状态为STOP
        advanceRunState(STOP);
        // 中断所有线程，包括正在运行的线程
        interruptWorkers();
        // 将未执行的任务移入列表中
        tasks = drainQueue();
    } finally {
        mainLock.unlock();
    }
    // 尝试将线程池置为TERMINATED状态
    tryTerminate();
    return tasks;
}
private List<Runnable> drainQueue() {
    BlockingQueue<Runnable> q = workQueue;
    ArrayList<Runnable> taskList = new ArrayList<Runnable>();
    // 调用BlockingQueue的drainTo()方法转移元素
    q.drainTo(taskList);
    if (!q.isEmpty()) {
        // 一个一个地转移元素
        for (Runnable r : q.toArray(new Runnable[0])) {
            if (q.remove(r))
                taskList.add(r);
        }
    }
    return taskList;
}
// 中断所有的线程，不管线程是否正在运行
private void interruptWorkers() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        for (Worker w : workers)
            w.interruptIfStarted();
    } finally {
        mainLock.unlock();
    }
}
void interruptIfStarted() {
    Thread t;
    if (getState() >= 0 && (t = thread) != null && !t.isInterrupted()) {
        try {
            t.interrupt();
        } catch (SecurityException ignore) {
        }
    }
}

public boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException {
    long nanos = unit.toNanos(timeout);
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        for (;;) {
            // 如果线程池已经是TERMINATED状态，返回true
            if (runStateAtLeast(ctl.get(), TERMINATED))
                return true;
            // 超时但是线程池未关闭，返回false
            if (nanos <= 0)
                return false;
            // 实现阻塞效果
            nanos = termination.awaitNanos(nanos);
        }
    } finally {
        mainLock.unlock();
    }
}
```

# 线程池的拒绝策略
1. CallerRunsPolicy - 当触发拒绝策略，只要线程池没有关闭的话，则使用调用线程直接运行任务。一般并发比较小，性能要求不高，不允许失败。但是，由于调用者自己运行任务，如果任务提交速度过快，可能导致程序阻塞，性能效率上必然的损失较大
2. AbortPolicy - 丢弃任务，并抛出拒绝执行 RejectedExecutionException 异常信息。线程池默认的拒绝策略。必须处理好抛出的异常，否则会打断当前的执行流程，影响后续的任务执行。
3. DiscardPolicy - 直接丢弃，其他啥都没有
4. DiscardOldestPolicy - 当触发拒绝策略，只要线程池没有关闭的话，丢弃阻塞队列 workQueue 中最老的一个任务，并将新任务加入

```java
// 拒绝策略
final void reject(Runnable command) {
    handler.rejectedExecution(command, this);
}

public interface RejectedExecutionHandler {
    void rejectedExecution(Runnable r, ThreadPoolExecutor executor);
}

// 由调用者运行
public static class CallerRunsPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            r.run();
        }
    }
}
// 抛出异常
public static class AbortPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        throw new RejectedExecutionException("Task " + r.toString() +
                                                " rejected from " +
                                                e.toString());
    }
}
// 丢弃任务，不做处理
public static class DiscardPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
    }
}
// 从阻塞队列中选出最老的，然后执行
public static class DiscardOldestPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            e.getQueue().poll();
            e.execute(r);
        }
    }
}
```

# JAVA捕获异常的几种方式
1. 实现UncaughtExceptionHandler接口，JDK5之后允许我们在每一个Thread对象上添加一个异常处理器UncaughtExceptionHandler 。
```java
//Thread类中的接口
public interface UncaughtExceptionHanlder {
	void uncaughtException(Thread t, Throwable e);
}
// 自定义异常捕获器
public class MyUnchecckedExceptionhandler implements UncaughtExceptionHandler {
    @Override
    public void uncaughtException(Thread t, Throwable e) {
        System.out.println("捕获异常处理方法：" + e);
    }
}

Thread t = new Thread(new ExceptionThread());
t.setUncaughtExceptionHandler(new MyUnchecckedExceptionhandler());
t.start();
```

2. 使用线程池时，可以在ThreadFactory中设置
```java
ExecutorService exec = Executors.newCachedThreadPool(new ThreadFactory(){
            @Override
            public Thread newThread(Runnable r) {
                Thread thread = new Thread(r);
                thread.setUncaughtExceptionHandler(new MyUnchecckedExceptionhandler());
                return thread;
            }
});
exec.execute(new ExceptionThread());
```
通过execute方式提交的任务，能将它抛出的异常交给异常处理器。

如果改成submit方式提交任务，则异常不能被异常处理器捕获，查看源码后可以发现，如果一个由submit提交的任务由于抛出了异常而结束，那么这个异常将被Future.get封装在ExecutionException中重新抛出。
```java
// java.util.concurrent.FutureTask 源码

public V get() throws InterruptedException, ExecutionException {
    int s = state;
    if (s <= COMPLETING)//如果任务没有结束，则等待结束
        s = awaitDone(false, 0L);
    return report(s);//如果执行结束，则报告执行结果
}
@SuppressWarnings("unchecked")
private V report(int s) throws ExecutionException {
    Object x = outcome;
    if (s == NORMAL)//如果执行正常，则返回结果
        return (V)x;
    if (s >= CANCELLED)//如果任务被取消，调用get则报CancellationException
        throw new CancellationException();
    throw new ExecutionException((Throwable)x);//执行异常，则抛出ExecutionException
}
```

3. 使用线程组ThreadGroup
```java
//1.创建线程组
ThreadGroup threadGroup =
        // 这是匿名类写法
        new ThreadGroup("group") {
            // 继承ThreadGroup并重新定义以下方法
            // 在线程成员抛出unchecked exception 会执行此方法
            @Override
            public void uncaughtException(Thread t, Throwable e) {
                //4.处理捕获的线程异常
            }
        };
//2.创建Thread        
Thread thread = new Thread(threadGroup, new Runnable() {
    @Override
    public void run() {
        System.out.println(1 / 0);

    }
}, "my_thread");  
//3.启动线程
thread.start();   
```

4. 默认的线程异常捕获器
```java
// 如果我们只需要一个线程异常处理器处理线程的异常，那么我们可以设置一个默认的线程异常处理器，当线程出现异常时，
// 如果我们没有指定线程的异常处理器，而且线程组也没有设置，那么就会使用默认的线程异常处理器
// 设置默认的线程异常捕获处理器
Thread.setDefaultUncaughtExceptionHandler(new MyUnchecckedExceptionhandler());
```

5. 使用FetureTask来捕获异常
```java
//1.创建FeatureTask
FutureTask<Integer> futureTask = new FutureTask<>(new Callable<Integer>() {
    @Override
    public Integer call() throws Exception {
        return 1/0;
    }
});
//2.创建Thread
Thread thread = new Thread(futureTask);
//3.启动线程
thread.start();
try {
    Integer result = futureTask.get();
} catch (InterruptedException e) {
    e.printStackTrace();
} catch (ExecutionException e) {
    //4.处理捕获的线程异常
}
```

6. 利用线程池提交线程时返回的Feature引用
```java
//1.创建线程池
ExecutorService executorService = Executors.newFixedThreadPool(10);
//2.创建Callable，有返回值的，你也可以创建一个线程实现Callable接口。
//  如果你不需要返回值，这里也可以创建一个Thread即可，在第3步时submit这个thread。
Callable<Integer> callable = new Callable<Integer>() {
    @Override
    public Integer call() throws Exception {
        return 1/0;
    }
};
//3.提交待执行的线程
Future<Integer> future = executorService.submit(callable);
try {
     Integer result = future.get();
} catch (InterruptedException e) {
    e.printStackTrace();
} catch (ExecutionException e) {
    //4.处理捕获的线程异常
}
```

7. 重写ThreadPoolExecutor的afterExecute方法
```java
//1.创建线程池
ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(10, 10, 0L, TimeUnit.MILLISECONDS,
        new LinkedBlockingQueue<>()) {
    @Override
    protected void afterExecute(Runnable r, Throwable t) {
        if (r instanceof Thread) {
            if (t != null) {
                //处理捕获的异常
            }
        } else if (r instanceof FutureTask) {
            FutureTask futureTask = (FutureTask) r;
            try {
                futureTask.get();
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (ExecutionException e) {
                //处理捕获的异常
            }
        }

    }
};


Thread t1 = new Thread(() -> {
    int c = 1 / 0;
});
threadPoolExecutor.execute(t1);

Callable<Integer> callable = () -> 2 / 0;
threadPoolExecutor.submit(callable);

```