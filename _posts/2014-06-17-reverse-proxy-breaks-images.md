---
layout: post
title: 如何外链知乎图片
tags: nginx image hotlinking
categories: php
---

知乎日报网页版的API来自反编译后的Android安装包，未开放。所以近期文章列表的缩略图经常打不开，像是不断的提醒我：“快来盗链，满足你的好奇心吧”。简单测试发现知乎是采用判断Referer信息来防盗链的，不难，使用现成的Nginx和PHP很容易实现图片的反向代理。

<!--more-->

### Nginx 配置
在http模块中加入图片缓存配置

```sh
    ##
    # Fastcgi Cache config
    #
    # 参数：
    #   图片缓存目录
    #   目录哈希层级，1:2会生成16*256个子目录，2:2会生成256*256个子目录
    #   所有活动的关键字及数据相关信息都存储于共享内存池，这个值的名称和大小通过keys_zone参数指定
    #   inactive参数指定了内存中的数据存储时间, 默认10分钟
    #   max_size参数设置缓存的最大值, 一个指定的进程将周期性的删除旧的缓存数据
    ##
    fastcgi_cache_path /tmp/nginx_cache_one levels=1:2 keys_zone=nginx_cache_one:128m inactive=1d max_size=256m;
```
在server模块中配置反向代理

```sh
    ## 重写url
    location ~ ^/img/ {
        rewrite ^/img/(.*)$ /img.php?url=$1 last;
    }

    ##
    # 缓存图片
    #
    # 参数：
    #   fastcgi_cache 缓存空间名称
    #   fastcgi_cache_min_uses 设置连接请求几次就被缓存
    #   fastcgi_cache_valid 定义哪些http头要存，以及缓存时间
    #   fastcgi_cache_use_stale 定义哪些情况下就用过期缓存, 如网关错误、超时
    #   fastcgi_cache_key 设置缓存的关键字
    ##
    location ~* \img.php$ {
        # fastcgi_cache的配置
        fastcgi_cache           nginx_cache_one;
        fastcgi_cache_min_uses  1;
        fastcgi_cache_valid     200 302 1d;
        fastcgi_cache_use_stale error timeout invalid_header http_500;
        fastcgi_cache_key       $host$request_uri;
        # php5-fpm
        fastcgi_pass            unix:/var/run/php5-fpm.sock;
        include                 fastcgi_params;
    }
```

### PHP代码部分

```php
<?PHP
if (empty($_GET['url'])) {
    output_404();
}
$url = trim($_GET['url']);
if ('http' !== substr($url, 0, 4)) {
    $url = 'http://' . $url;
}
$urlInfo = parse_url($url);
$referer = $urlInfo['scheme'] . '://' . $urlInfo['host'] . '/';

// Create a stream
$opts = array(
    'http'=>array(
        'method'  => 'GET',
        'timeout' => 30,
        'header'  => 
            "referer:{$referer}\r\n" .
            "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36"
    )
);
$ctx = stream_context_create($opts);
// Open the file using the HTTP headers set above
$file = file_get_contents($url, false, $ctx);
// output
if ( ! $file) {
    output_404();
}
output_image($file);

// output image header
function output_image($file) {
    header('Content-type: image/jpeg');
    exit($file);
}

// output not found header
function output_404() {
    header('HTTP/1.1 404 Not Found');
    header('Status: 404 Not Found');
    exit;
}
```

至此，图片能够正常访问了，还剩最后一步，清理图片缓存。我对 [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge/) 编译无爱，喜欢简单极致。

### Cron 定时清理文件缓存

```sh
# Nginx Fastcgi Cache - 每天凌晨1点清理修改时间超过2天的临时文件
0 1 * * * find /tmp/nginx_cache_one -type f -mtime +2 -print0 | xargs -0 -r rm >/dev/null 2>&1
```

收工。
