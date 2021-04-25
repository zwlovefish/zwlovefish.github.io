{% if page.prev or page.next %}
  <nav class="pagination">
    {{
      paginator({
        prev_text: '前一页',
        next_text: '后一页',
        mid_size: 1
      })
    }}
  </nav>
{% endif %}
