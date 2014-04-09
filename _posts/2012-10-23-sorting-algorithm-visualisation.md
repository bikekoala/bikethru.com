---
layout: post
title: 可视化的排序过程
tags: sort
categories: php
---

今天老汪问我有哪些排序方式，只对冒泡和快速有印象了  ，赶紧温习了数据结构，下面是冒泡排序和快速排序的PHP版本:

<!--more-->

### 冒泡排序:(仅次于Bogo  ,时间复杂度为 O(n*n) )

```php
<?PHP
function bubble($arr)
{
    for ($i=0, $n=count($arr); $i<$n-1; $i++) {
        for ($j=$i+1; $j<=$n-1; $j++) {
            if ($arr[$j] > $arr[$i]) {
                $t = $arr[$i];
                $arr[$i] = $arr[$j];
                $arr[$j] = $t;
            }
        }
    }
    return $arr;
}
$arr = array(5, 1, 3, 2, 4);
$arr = bubble($arr);
print_r($arr);
```

### 快速排序:(传说中最快的  ，时间复杂度为 O(n*logn) )

```php
<?PHP
function quick($arr)
{
    if (count($arr) <= 1) {
        return $arr;
    }
    $key = $arr[0];
    $l = array();
    $r = array();
    for ($i=1, $n=count($arr); $i<$n; $i++) {
        if ($arr[$i] > $key) {
            $l[] =$arr[$i];
        } else {
            $r[] = $arr[$i];
        }
    }
    $l = quick($l);
    $r = quick($r);
    return array_merge($l, array($key), $r);
}
$arr = array(5, 1, 3, 2, 4);
$arr = bubble($arr);
print_r($arr);
```

给看点牛的。
这是一个日本程序员制做的一个可视化的排序过程，包括了各种经典的排序算法，可以调整速度和需要排序的个数。

<iframe src="http://jsrun.it/norahiko/oxIy" height="360" width="770" frameborder="0"></iframe>
