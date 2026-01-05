
## LOID（找装维索取）

**测试型号：ZXHN F410GV9，EOPN，此型号会自动保留上一次注册过的LOID**

注册LOID后，拔掉光纤，并重置光猫（长按reset孔20秒以上，观察指示灯，ping 192.168.1.1 -t，重活后，再断电重启一次）
然后：[factorymode_crack.exe](https://www.jarvisw.com/?p=1517)

`factorymode_crack.exe -l xxx open -i 192.168.1.1 -p 8080`      

(有的光猫使用的是8080端口，IP地址默认是192.168.1.1如果你的光猫已经修改请指定自己的地址，另外-l参数已经无效，但仍然需要指定，随便填即可)
可能需要多试几次，如果打开成功会出现：

```
Enter192.168.1.1  
FactoryModeSuccess:FactoryModeAuth.gch?user=l0Fo18jP&pass=7N518I28
```

user=的值是telnet的用户名，pass=后面的是telnet的密码
`telnet 192.168.1.1`
输入上面的用户名和密码，下载配置文件，拿到超级密码

### 给普通用户提权
`sendcmd 1 DB set DevAuthInfo 1 Level 1`
### 保存
`sendcmd 1 DB save`

**普通用户进入后可查看pppoe账号以及vlan号，记下来，保存好，还有拨号密码可向运营商索取可通过客服自行重置**

### 拒绝 nbif0 接口(069)的所有进出流量
```
iptables -I INPUT -i nbif0 -j DROP
iptables -I OUTPUT -o nbif0 -j DROP
iptables -I FORWARD -i nbif0 -j DROP
```

### 下载配置文件 [tftp](https://github.com/PJO2/tftpd64/releases/)
`tftp -p -l userconfig/cfg/db_user_cfg.xml -r db_user_cfg.xml 192.168.1.2`

### 解密配置文件 [ztecfg.exe](https://github.com/wx1183618058/ZET-Optical-Network-Terminal-Decoder/releases)
`.\ztecfg.exe -d AESCBC -i .\db_user_cfg.xml -o break.cfg`

**在 break.cfg 中搜索 TelnetCfg，找到TS_UPwd字段下的就是telnet超密，搜索telecomadmin ，看到 telecomadmin270391161 就是web超密，用户名是 telecomadmin**

```
<Tbl name="TelnetCfg" RowCount="1">
<DM name="TS_UName" val="user"/>
<DM name="TS_UPwd" val="BCF45F6093251"/>

<DM name="User" val="telecomadmin"/>
<DM name="Pass" val="telecomadmin270391161"/>
```
### 开启永久telnet
```
sendcmd 1 DB set TelnetCfg 0 Lan_Enable 1
sendcmd 1 DB set TelnetCfg 0 InitSecLvl 3
sendcmd 1 DB set TelnetCfg 0 Max_Con_Num 5
sendcmd 1 DB save
```

### 查看所有接口信息
`sendcmd 1 DB all`

### 找到WANC下的069字样
`sendcmd 1 DB p WANC`

### 禁用069
`sendcmd 1 DB set WANC 0 Enable 0`

### 修改FTP信息
```
sendcmd 1 DB set FTPServerCfg 0 FtpEnable 1
sendcmd 1 DB set FTPServerCfg 0 FtpLanEnable 1
sendcmd 1 DB set FTPUser 0 Location /
sendcmd 1 DB set FTPUser 0 UserRight 3
sendcmd 1 DB save
```

### 保存配置
`sendcmd 1 DB save`

### 重启光猫
`reboot`
