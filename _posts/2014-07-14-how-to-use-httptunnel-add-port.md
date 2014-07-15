---
layout: post
title: 使用 httptunnel 为花生壳新添端口
tags: httptunnel linux php oray
categories: web
---

免费级的 [花生壳][1] 内网版只默认提供2个端口映射数，一只80用来做知乎日报，另一只22也只好用来做远程SSH了，用的好省。想扩充端口得先要上道，首先要将免费级的个人套餐升级到专业级，花费268元/年，稍后才是购买端口，这需要134/元/映射/年，价格很“公道”。总得来说，看完这篇博客，至少可以节省402元/年呢～

<!--more-->

为什么非 [httptunnel][2] 不可呢?做一个端口转发(80 -> 22)不就能解决问题吗？  
少年，我大黑花生壳才不会这么疏忽呢！首先，花生壳的80端口会将一切协议强制转换成http协议，而SSH的传输、认证和连接协议直接简历在TCP/IP上，此路不通；其次，做22 -> 22的端口转发虽然可以满足需求，但花生壳随机分配的端口号会让你抓狂，每次都得删除、建立并记录新端口号，同时，建立本映射的其他服务也得中断。最完美的方式是：同时运行。

### 1. 首先在服务器下载并编译httptunnel，启动服务端
```sh
wget http://www.nocrew.org/software/httptunnel/httptunnel-3.0.5.tar.gz
tar zxvf httptunnel-3.0.5.tar.gz
cd httptunnel-3.0.5

./configure
make
make install
```
将hts拷贝至系统目录，启动并在开机时运行：  

```sh
sudo cp hts /usr/local/bin
# 以http协议将本地22端口转发至2222端口
sudo hts -F localhost:22 2222
# 开机运行
sudo echo "hts -F localhost:22 2222" >> /etc/rc.local
```
有没有对2222端口感到好奇呢，往下看。

### 2. 利用iptables规则做端口转发
```php5
<?PHP
/**
 * Port Forwarding tool
 *
 * @author popfeng <popfeng@yeah.net>
 */

/** profile */
$server_port_input = 80; // 服务器访问端口
$server_port_forward = 2222; // 服务器转发端口
$server_ip = $_SERVER['SERVER_ADDR'];
$client_ip = $_SERVER['REMOTE_ADDR'];
/** end */

$sudo_cmd = 'sudo -u root'; // iptables NAT表需要root权限
$iptables_cmd = 'iptables -t nat -A PREROUTING -s %s -d %s -p tcp --dport %d -j DNAT --to-destination %s:%d';
$iptables_cmd = sprintf($iptables_cmd, $client_ip, $server_ip, $server_port_input, $server_ip, $server_port_forward);
system($sudo_cmd . ' ' . $iptables_cmd, $return);
if (0 === $return) {
    exit('Success, please wait 30s.');
} else {
    exit('Failed !');
}
```
将上面代码保存为boring.php并移动到web可访问的位置。  
当客户端请求该地址的时候，php会以root权限向iptables NAT表中添加一条规则，这条规则会在路由之前就进行目的NAT，将来自客户端80端口的请求数据转发到服务器2222端口。注意，这里的80端口是全局的，因为它并不具备nginx般根据URI区分来路的能力，所以执行成功后服务器上所有依赖80的服务都会被转发。  

规矩向来是不破不立，有立便有破。破的是清空上面新增的iptables规则，以实现服务器80端口的正常访问。可以在用户成功登录SSH时清空它，这样既能保持SSH连接，又能实现80端口的正常访问，真是“内外兼修”啊~

```sh
vim ~/.bashrc

### 添加两行
#iptables
sudo -u root iptables -t nat -F PREROUTING
```

既然大家都知道root好，那就从了它们：

```sh
sudo vim /etc/sudoers

### 添加两行
# User privilege specification
popfeng,www-data ALL = NOPASSWD: /sbin/iptables
```
其中www-data是nginx运行用户名，popfeng是当前登录用户名，授予它们无需密码以root用户运行iptables命令的权限。  

### 3. httptunnel客户端配置
终于最后一步了，写完就可以睡觉咯～  

客户端配置就很简单了，分3步：  

    1. 运行httptunnel客户端，绑定本地端口
    2. 请求api实现服务器端口转发 
    3. 使用SSH客户端连接本地端口，建立http通道

其实官方 [FAQ][3] 中建议在 [Cygwin][4] 环境下构建运行httptunnel，但我在windows系统CMD下也实现了完美运行。  

首先，下载 [WIN版二进制包][5]，解压到安装程序目录。  

其次，写一个脚本将1、2步串联起来：

```vb.net
Set WS = CreateObject("Wscript.Shell")
WS.run "htc.exe -F 2222 bikethru.com:80",0  '服务器地址:端口

On Error Resume Next
Set HTTP = CreateObject("Microsoft.XMLHTTP")
HTTP.open "GET","http://bikethru.com/boring.php",0  '端口转发api地址
HTTP.send
If Err Then
    WS.Popup "Can't open the url~"
    Err.Clear
Else
    WS.Popup HTTP.responseText,30
End If
Set HTTP = Nothing
```
将上面代码保存为deamon.vbs放入程序目录下，赶快双击看看有什么惊喜～  要是出现 *Success, please wait 30s.* 对话框就太好了，等吧。为什么要等30秒呢？其实这也是大概时间，因为我发现执行脚本后立马SSH登录会失败，而过一会连接就会成功，我想是Oray面对突如起来的转变懵了吧，需要时间。  

### 30秒后会发生什么？

对话框自动关闭; SSH连接成功；web访问正常。

就酱。

[1]: http://hsk.oray.com/price/#lan
[2]: http://www.nocrew.org/software/httptunnel/
[3]: http://www.nocrew.org/software/httptunnel/faq.html
[4]: http://sourceware.cygnus.com/cygwin/
[5]: http://www.neophob.com/files/httptunnel-3.3w32r2.zip
