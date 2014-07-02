---
layout: post
title: 黑花生壳
tags: oray ddns openwrt
categories: distraction
---

[花生棒][1]是Oray公司的一款DDNS硬件产品，主打NAT穿透，让远程智能家居、Home Web成为可能。

<!--more-->

![][2]

![][3]

我有一个从小以来的癖好就是，见到不熟悉的电子产品一定要开膛破肚看看其内部构造，看着电阻电容的就无比兴奋呢。这次也不例外，PCB面板上没有任何测试点，尤其是UART针脚 -- RX & TX 正是我需要的。很幸运，我注意到有电路连接在了MicroUSB插槽的数据针脚，但是没有任何电脑能识别它，毫无疑问，这些数据针脚就是URAT信号。

现在，我试着破解它。

```sh
    minicom -b 57600 -D /dev/ttyUSB0
```

看到屏幕输出debug信息说明已经连接成功了，接下来就简单了。断电重启，出现```sh Press the [f] key and hit [enter] to enter failsafe mode ```时按f和回车进入故障恢复模式。

```sh
    # 将root目录已JFFS RW模式挂载
    mount_root

    # 修改密码
    passwd
```
大功告成。

![][4]

![][5]

尝试用```sh opkg``安装nginx, 还部署上了开源的[2048][7] :D

![][6]

    后记：  
    为什么叫黑花生棒呢？有破解之意，还有它确实够黑
    1. 360Mhz CPU + 32M ROM + 16M RAM, 不值测试价94和现在已开放购买的298 RMB (和极路由比比)
    2. 限制太多 ---- 每月2G流量 + 1M带宽 + 域名转入收费 + 超级无敌多的BUG (和DNSPOD比比)
    3. 最最受不了的，它本科纯粹软件实现却绑定硬件销售 (爱和谁比和谁比)
    
    ---- 在目前纷纷推出免费硬件已服务收费的互联网时代，Oray为何反其道而行之呢？我想大概是这样吧
    1. 花生棒属于准极客们的小众产品，也是启蒙产品，门槛高，用户基数小，盈利模式不能走主流路线
    2. 在大多国人的观念里，软件就是免费的，硬件收费心安理得

[1]: http://hsk.oray.com/device
[2]: media/img/2014-07-02-peanutstick1.png
[3]: media/img/2014-07-02-peanutstick2.png
[4]: media/img/2014-07-02-openwrt1.png
[5]: media/img/2014-07-02-openwrt2.png
[6]: media/img/2014-07-02-2048.png
[7]: http://gabrielecirulli.github.io/2048/
