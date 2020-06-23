## 另一种 Win+Linux “多”系统
### 起因
	起因很简单，就是因为我经常要用到Linux系统，但又因为弟弟要用Windows打游戏，所以就有了装双系统的想法，在实践过程中发现一个问题，两者不能同时使用，我又想是不是可以用虚拟机来装个Linux（当然是可以的，但如何自动启动，又跟随Windows的关闭而正常关闭电源呢？）
	

### 开关机虚拟机内的系统( `Debian10` 是虚拟机的名字)
#### 开机
	为了提升使用体验，使用无界面命令启动，放入开始菜单的启动项内即可。
- `"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm Debian10 --type headless`

#### 关机
- `"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm Debian10 poweroff`

	因为如果关机或重启之前不先关闭虚拟内的系统就会引起各种错误，可能会导致下次无法正常启动。我也不想手机关闭虚拟机电源（其实也是来不及了）所以需要创建一个计划任务，在发生关机或重启事件（<key>系统</key>-<key>USER32</key>-<key>1074</key>）时就执行这个程序和参数。

### 虚拟机相关设置
#### 网络
- 全局配置里面添加一个NAT网络（名称：NatNetwork），并配置端口转发(一个SSH+一个日志端口)
	- 名称：ssh 协议：TCP 主机IP：10.0.0.12（Windows内网IP） 主机端口：22 子系统IP：10.0.2.15（Debian内网IP） 子系统端口：22
	- 名称：rsyslog 协议：UDP 主机IP：10.0.0.12（Windows内网IP） 主机端口：514 子系统IP：10.0.2.15（Debian内网IP） 子系统端口：514
- 子系统设置，网络-连接方式：NAT网络，界面名称：NatNetwork
