---
layout: post
title: Operate Multidimensional Arrays with PHP-1
tags: array
categories: php
---

昨遇一通过key操作多维数组的问题，伤脑筋，如下

<!--more-->

```php5
<?PHP
$keys = array('a', 'c');
// $array 是n维数组
$array = array(
    'a' => array(
        'c' => array('e'),
        'd' => 1
        ),
    'b' => 1
);
```

通过$keys对$array子节点进行 查看/删除 操作?

### 1.查看
```php
<?PHP
function arrayFind($array, $keys) {
    foreach ($keys as $key=>$val) {
        if ($array[$val]) {
            $array = $array[$val];
        }
    }
    return $array;
}
```

### 2.删除

```php
<?PHP
function arrayRemove($array, $keys) {
    // single
    $num = count($keys);
    if ($num === 1) {
        $key = array_shift($keys);
        unset($array[$key]);
        return $array;
    }
    // recursive delete
    $lastNum = $num - 1;
    $thisArray0 = &$array;
    $lastKey = $keys[$lastNum];
    for ($i = 0; $i < $lastNum; $i ++) {
        $thisKey = $keys[$i];
        $thisVarName = 'thisArray' . $i;
        $nextVarName = 'thisArray' . ($i + 1);
        if ( ! array_key_exists($thisKey, $$thisVarName)) {
            break;
        }
        $$nextVarName = &${$thisVarName}[$thisKey];
    }
    unset(${$nextVarName}[$lastKey]);
    return array_filter($array);
}
```

多维数组当然用递归思想，有复杂度低算法pm我
