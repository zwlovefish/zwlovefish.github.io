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

## 线程的六种状态和切换
![线程的六种状态](线程的六种状态.PNG)

|状态名称|说明|
|:--:|:--:|
|NEW|初始状态，线程被构建，但是还没有调用start方法|
|RUNNABLE|运行状态，JAVA线程将打操作系统中的就绪和运行两种状态笼统地称作"运行中"|
|BLOCKED|阻塞状态，表示线程阻塞于锁|
|WAITING|等待状态，表示线程进入等待状态，进入该状态表示当前线程需要等待其他线程做出一些特定动作(通知或中断)|
|TIME_WAITING|超时等待状态，该状态不同于WATING，它是可以直指定时间自行返回的|
|TERMINATED|终止状态，表示当前线程已经执行完毕|



## ThreadLocal使用
ThreadLocal，很多地方叫做线程本地变量，也有些地方叫做线程本地存储，其实意思差不多。可能很多朋友都知道ThreadLocal为变量在每个线程中都创建了一个副本，那么每个线程可以访问自己内部的副本变量。



## 锁接口
## AQS

## 读写锁

## 锁膨胀，锁消除，锁升级

## ConcurrentHashMap

## ForkJoin

## CountDownLatch

## 同步屏障CyclicBarrier

## 控制并发线程数的Semaphore

## 线程池
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
            // ONLY_ONE为true
            interruptIdleWorkers(ONLY_ONE);
            return;
        }
        // 如果是SHUTDOWN且队列为空或者STOP状态，工作线程数为0，走terminated()
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

# 线程池的拒绝策略
1. CallerRunsPolicy - 当触发拒绝策略，只要线程池没有关闭的话，则使用调用线程直接运行任务。一般并发比较小，性能要求不高，不允许失败。但是，由于调用者自己运行任务，如果任务提交速度过快，可能导致程序阻塞，性能效率上必然的损失较大
2. AbortPolicy - 丢弃任务，并抛出拒绝执行 RejectedExecutionException 异常信息。线程池默认的拒绝策略。必须处理好抛出的异常，否则会打断当前的执行流程，影响后续的任务执行。
3. DiscardPolicy - 直接丢弃，其他啥都没有
4. DiscardOldestPolicy - 当触发拒绝策略，只要线程池没有关闭的话，丢弃阻塞队列 workQueue 中最老的一个任务，并将新任务加入

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