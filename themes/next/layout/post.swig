{% extends '_layout.swig' %}
{% import '_macro/post.swig' as post_template %}
{% import '_macro/sidebar.swig' as sidebar_template %}


{% block title %}{{ page.title }} | {{ config.title }}{% endblock %}

{% block page_class %}page-post-detail{% endblock %}


{% block content %}

  <div id="posts" class="posts-expand">
    {{ post_template.render(page) }}

    <div class="post-spread">
      {% if theme.jiathis %}
        {% include '_partials/share/jiathis.swig' %}
      {% elseif theme.baidushare %}
        {% include '_partials/share/baidushare.swig' %}
      {% elseif theme.add_this_id %}
        {% include '_partials/share/add-this.swig' %}
      {% elseif theme.duoshuo_shortname and theme.duoshuo_share %}
        {% include '_partials/share/duoshuo_share.swig' %}
      {% endif %}
    </div>
  </div>

  <!-- 下一行是要添加的代码 start  -->
  <!-- Link Gitalk 的支持文件  -->
    <link rel="stylesheet" href="/css/gitalk.css">
    <script src="/js/src/gitalk.min.js"></script> 
    <script src="/js/src/md5.min.js"></script>
    <div id="gitalk-container"></div>     <script type="text/javascript">
    var gitalk = new Gitalk({

    // gitalk的主要参数
        clientID: '0295d6dfeb2a8355d908',
        clientSecret: 'b4b7df99afa11f6cd718b0746b9cb06aa71da955',
        repo: 'blogcomment',
        owner: 'zwlovefish',
        admin: ['zwlovefish'],
        id: md5(location.pathname),

    });
    gitalk.render('gitalk-container');
  </script> 
  <!-- Gitalk end -->
  <!-- 到一上行结束 end  -->

{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(true) }}
{% endblock %}

{% block script_extra %}
  {% include '_scripts/pages/post-details.swig' %}
{% endblock %}
