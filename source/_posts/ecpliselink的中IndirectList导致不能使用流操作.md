---
title: eclipselink的中IndirectList导致不能使用流操作
date: 2022-06-28 20:52:25
tags: eclipselink IndirectList 流操作
categories: 工作
---
今天开开心心的写完一段很简单的代码准备跑路回家了，然后手贱的测试了一下，心情突然就不美丽了。。。。

问题的来源是这样子滴。。。且听我慢慢道来

前台rest结构:
```json
{
    "业务": [
        {
            "A": {
                "B": [
                    {
                        "C1": "c1"
                    },
                    {
                        "C2": "c2"
                    }
                ]
            }
        }
    ]
}
```

<!-- more -->

通过jpa存储到数据库一般情况需要三张表，A主表，B是A的子表，c是B的子表，但是根据我们自己的业务，A和B可以唯一确定C，为了减少子表，落库的数据结构是
{A, B, C1}, {A,B,C2}。写编写整集群重启时，需要从DB恢复数据，因此需要将{A, B, C1},{A, B, C2}恢复成rest的结构，首先就需要根据A来分组，在根据B来分组，最后得到C数组，
从数据库读取数据用的是eclipselink，eclipselink在实例化C数组时用的是IndirectList，IndirectList继承的是Vector，Vector在1.8被增强了，增加了spliterator()等函数，这样就可以使用流操作了。但是坑爹的IndirectList，它tmd将Vector中的函数都重写了一遍，因此低版本的Vector不能使用流操作。。。。。

解决方式1：
通过eclipselink读取上来的C数组实际上是List\<C\> cList = new IndirectList\<C\>();为了能够使用流操作，需要通过new ArrayList(cList).stream()就可以了。

解决方式2：
将EclipseLink更新到2.6.2以上的版本即可解决

后面我就以IndirectList不能进行流操作作为关键字google了一下，一顿操作在[Stack Overflow](https://stackoverflow.com/questions/35362581/stream-api-not-working-for-lazy-loaded-collections-in-eclipselink-glassfish)上找到了上述的答案。

这是有关此问题的bug [eclipselink的bug页面](https://bugs.eclipse.org/bugs/show_bug.cgi?id=487799)

