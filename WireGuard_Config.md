## WireGuard 配置记录([树莓派](https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit))

### 1. 安装（[install](https://www.wireguard.com/install/)）

`sudo apt install -y wireguard*`

如果太慢，可以为apt配置一下代理：`sudo vi /etc/apt/apt.conf.d/proxy.conf`

```conf
Acquire::http::Proxy "http://10.0.0.1:404/";
Acquire::https::Proxy "http://10.0.0.1:404/";
```

### 2. 配置（[config](https://www.wireguard.com/quickstart/)）
生成密钥：`wg genkey | tee 1privatekey | wg pubkey > 1publickey`

当前目录下就应该会有两个文件：1privatekey 和 1publickey

```bash
pi@raspberrypi:~ $ cat 1privatekey
eAMcr0vgBvMo9CE/kkVletvbchkZITyKNMEOsvQIgGg=
pi@raspberrypi:~ $ cat 1publickey
QKzuDLnQt6c6+jsl/8s4Y3jZpXM3qP+axynZuOHzz0o=
```

*注意，这只是一端使用的，另一端配置使用的话，还得生成一次*

生成密钥：`wg genkey | tee 2privatekey | wg pubkey > 2publickey`

当前目录下就应该会有两个文件：2privatekey 和 2publickey

```bash
pi@raspberrypi:~ $ cat 2privatekey
cDNgJrk0zAB3vCOWCfU6HdweHTc3IIkKZk+/1YPU0E0=
pi@raspberrypi:~ $ cat 2publickey
k2Ve29BxonbkwRr/6XLogOlvxdGuHCcoHWaCzBCbJXE=
```

假如1开头的私钥当服务器的话，1开头的公钥就是客端需对接的;

2开头的私钥当客户端的话，2开头的公钥就是服端需对接的;

也就是说，任一端只有另对方的公钥和自己的私钥。

服务器（192.168.1.11）配置 `/etc/wireguard/wg0.conf` 如下：
```
[Interface]
Address = 10.0.33.1/32
ListenPort = 3800
PrivateKey = eAMcr0vgBvMo9CE/kkVletvbchkZITyKNMEOsvQIgGg=
#1privatekey

# 访问内网
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s25 -j MASQUERADE

#Raspberry pi 3B+
[Peer]
AllowedIPs = 10.0.33.4/32
PublicKey = k2Ve29BxonbkwRr/6XLogOlvxdGuHCcoHWaCzBCbJXE=
#2publickey
```

客户端配置 `/etc/wireguard/wg0.conf` 如下：
```
[Interface]
Address = 10.0.33.4/32
DNS = 1.1.1.1, 8.8.8.8
PrivateKey = cDNgJrk0zAB3vCOWCfU6HdweHTc3IIkKZk+/1YPU0E0=
#2privatekey

[Peer]
AllowedIPs = 10.0.33.0/24,192.168.1.0/24
Endpoint = 192.168.1.11:3800
PublicKey = QKzuDLnQt6c6+jsl/8s4Y3jZpXM3qP+axynZuOHzz0o=
#1publickey
```

### 3. 启动

先后在服务器和客户端执行： `sudo wg-quick up wg0`

查看状态：`wg`

断开：`sudo wg-quick down wg0`

加载内核：`sudo modprobe wireguard`

查询内核：`sudo lsmod | grep 'tun\|wireguard'`

服务端内网漫游配置： `sudo vim /etc/sysctl.conf`

修改为 `net.ipv4.ip_forward = 1`

应用并查询：`sysctl -p && sysctl net.ipv4.ip_forward`

### 4. 附录

[在/boot/下放一个名为 ssh 的文件即可开启SSH登录](https://www.raspberrypi.org/documentation/remote-access/ssh/README.md)
 
[在/boot/下放一个名为 wpa_supplicant.conf 的文件可自动连接WIFI](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md)

`wpa_supplicant.conf`

```conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=<Insert 2 letter ISO 3166-1 country code here>

network={
 ssid="<Name of your wireless LAN>"
 psk="<Password for your wireless LAN>"
}
```

用nmap扫描一下子网： `nmap -sn 192.168.1.0/24`

[用arp当前当前连接](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#4-boot-ubuntu-server)的3B： `arp -na | grep -i "b8:27:eb"`

4B：`arp -na | grep -i "dc:a6:32"`
