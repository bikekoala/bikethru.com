---
layout: post
title: Operate Multidimensional Arrays with PHP-2
tags: array
---

设计一简单的文件管理平台，允许上传文件夹，产品规划中需要对文件夹的深度有所限制。

<!--more-->

# 1. 现有一混乱的多层文件夹，如何知道它的深度呢?

```php
<?PHP
$dir = array(
    'a' => 'a',
    'b' => array(
        'c' => array(
            'd' => 'd',
            'e' => 'e'
        ),
        'f' => 'f'
    )
);
```

当然是3层，如下代码可以实现: 

### 版本一:

```php
<?PHP
function getLayer($arr) {
    $layer = 0;
    if (is_array($arr)) {
        foreach ($arr as $val) {
            $layer = max($layer, getLayer($val));
        }
        return $layer+1;
    } else {
        return 0;
    }
}
$result = getLayer($dir);
print_r($result);
```

### 版本二: 利用5.3新增的闭包语法写计数器

```php
<?PHP
function getLayer($arr, $counter) {
    if (is_array($arr)) {
        foreach ($arr as $val) {
            $layer = max($layer, getLayer($val, $counter));
        }
        return $counter();
    } else {
        return 0;
    }
}

/*
 * 1. counter函数每次调用, 创建一个局部变量$counter, 初始化为1.
 * 2. 然后创建一个闭包, 闭包产生了对局部变量$counter的引用.
 * 3. 函数counter返回创建的闭包, 并销毁局部变量, 但此时有闭包对$counter的引用,
 * 它并不会被回收, 因此, 我们可以这样理解, 被函数counter返回的闭包, 携带了一
 * 个游离态的变量.
 * 4. 由于每次调用counter都会创建独立的$counter和闭包, 因此返回的闭包相互之间是
 * 独立的.
 * 5. 执行被返回的闭包, 对其携带的游离态变量自增并返回, 得到的就是一个计数器.
 * 结论: 此函数可以用来生成相互独立的计数器.
 */
function counter() {
    $counter = 0;
    return function() use(&$counter) {return $counter++;};
}
$result = getLayer($dir, counter());
print_r($result);
```

<br />

# 2. 想象一下，100层的文件夹是多么的变态  所以要有个限制$layerLimit,当深度大于$layerLimit时，把其下所有的文件已一维方式放入$layerLimit层。 例如，$layerLimit = 2时，上面的$dir数组会变成这个样子:

```php
<?PHP
array(
    'a' => 'a',
    'b' => array(
       'f' => 'f',
       'd' => 'd',
       'e' => 'e'
    )
);
```

文件数据没丢，样子也不错，就是要它。不过可能出现key值冲突的情况，下面是实现方式:

```php
<?PHP
function getRelation($arr, $layerLimit, $thisLayer = 0) {
    if ($arr && is_array($arr)) {
        $thisLayer++;
        foreach ($arr as $key=>$val) {
            if (($thisLayer >= $layerLimit) && ($val && is_array($val))) {
                $i = 0;
                $it = new RecursiveIteratorIterator( new RecursiveArrayIterator($val));
                foreach ($it as $key1=>$val1) {
                    $result[$i] = $val1;
                    $i++;
                }
            } else {
                $result[$key] = getRelation($val, $thisLayer, $layerLimit);
            }
        }
        return $result;
    } else {
        return $arr;
    }
}
$result = getRelation($dir, 2);
print_r($result);
```

对吧，用到了遍历和数组迭代器，完毕。
