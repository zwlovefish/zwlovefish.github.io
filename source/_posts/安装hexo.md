---
title: 安装hexo
date: 2020-01-06 14:33:47
tags: 博客搭建
categories: 随笔
---

哇哈哈哈，昨天刚刚将博客环境搭好，终于有自己的博客了。嘿嘿嘿！！！

今天记录一下昨天是如何搭建的

<!--more-->
# 下载git，并在github上注册账号
不谈
# 安装hexo
## 首先安装Node.js
```SHELL
brew install node
```

## 接着安装hexo
npm install hexo-renderer-less --save

## 利用hexo建站
```SHELL
hexo init <folder> #我的是zwlovefish#
cd <folder>
npm install
```

建立完成之后文件夹中的_config.yml是站点配置文件，里面可以选择语言，作者，博客名字等信息


# 安装hexo之后，设置一个逼格很高的主题
我选的是next，next看着非常舒服，不多bb，直接开干
## 利用git下载
```SHELL
git clone https://github.com/iissnan/hexo-theme-next themes/next
```

## 切换版本号
```SHELL
git tag -l
git checkout tags/v5.1.4
```

## 更新Next
```SHELL
cd themes/next
git pull
```

## 启用主题
在这里说明一下哈，blog下面有一个_config.yml(站点配置文件)，next下也有一个_config.yml(主题配置文件)。站点配置文件中，将原来的theme:land啥的给注释掉，前面加#即可。然后输入theme:next

当当当！！！主题已经生效了！！！！

## 升级next
<font color="red">主题启用之后，看着还是有点捞比？不重要！！！这时候就得使用上面说的主题配置文件了，我从不说废话。手动滑稽~~</font>

- 在主题配置文件中，配置scheme
```SHELL
# Schemes
scheme: Muse  //默认主题
#scheme: Mist
#scheme: Pisces
#scheme: Gemini
```

我选的是哪一个的？卧槽，我tm也忘记了。。。妈的，这个记性。不重要，一个一个的自己尝试呗。

- 在主题配置文件中，配置menu
```SHELL
menu:
  home: / || home  //首页
  about: /about/ || user  //关于
  tags: /tags/ || tags  //标签
  categories: /categories/ || th   //分类
  archives: /archives/ || archive //归档
  schedule: /schedule/ || calendar   //日程表
  sitemap: /sitemap.xml || sitemap   //站点地图
```

根据前面的英文单词，依次执行hexo new page 英文单词，比如hexo new page about，当然，home是不用new的，跟java很像，美滋滋，搞完之后，大体上你的博客也差不多了。

里面还有一些Avator，社交信息等等。
- 增加阅读次数和浏览次数等
这里就是使用的一个插件，叫不蒜子(名字有点怪啊)，不重要。

1.打开themes/next/layout/_partial/footer.swig，将下面这段代码添加到footer.swig最后面
```JAVASCRIPT
<script async src="https://busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js"></script>
<div class="theme-info">
  <div class="powered-by"></div>
  <span class="post-count">博客全站共{{ totalcount(site) }}字</span>
  <span class="post-meta-divider">|</span>
  本站总访问量<span id="busuanzi_value_site_pv"></span>次
  <span class="post-meta-divider">|</span>
  本站访客数<span id="busuanzi_value_site_uv"></span>人次
  <span class="post-meta-divider">|</span>
  本文总阅读量<span id="busuanzi_value_page_pv"></span>次
</div>
```
在主题配置文件中配置
```
busuanzi_count:
  enable: true  #是否开启不蒜子统计功能
  total_visitors: false
  total_visitors_icon: user
  total_views: false
  total_views_icon: eye
  post_views: false
  post_views_icon: eye
```


至此已经完全ojbk了！！！一个可用的博客弄好了，剩下来的就是你自己折腾了，我也打算慢慢折腾。毕竟我也是昨天刚弄的！嘿嘿嘿~

# 最后
知道为啥写这篇博客吗？其实也是为了测试，啦啦啦啦~德玛西亚，看看我的归档，标签啥的有没有作用，要测试的话就是hexo new post 文章名称，在文章的开头，本来是没有tags和categories这俩个的
```MARKDOWN
---
title: 新的起点
date: 2020-01-06 14:33:47
tags: 博客搭建
categories: 随笔
---
```


