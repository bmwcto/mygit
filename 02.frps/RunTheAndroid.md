# 在Android手机上运行，并转发sshd

## 下载安装APK

- [去F-Droid下载](https://f-droid.org/packages/com.termux/)
- 安装一些常用软件  
    `pkg install -y openssh vim aria2 curl wget dnsutils tracepath tree`
- 给个本地文件权限  
    `termux-setup-storage`
- 改个密码  
    `passwd`
- 运行SSH服务端(默认端口是8022，不是22)  
    `sshd`

## 下载frpc和frpc.ini

- 复制到当前Termux目录  
    `cp ~/storage/downloads/frpc ~/`
- 给执行权限  
    `chmod u+x frpc`
- 看看frpc.ini配置  

    ```ini
    cat ~/storage/downloads/frpc.ini

    [common]
    server_addr = 1.2.3.4
    server_port = 7111

    [mySSH]
    type = tcp
    local_ip = 127.0.0.1
    local_port = 8022
    remote_port = 9999

    [WINRDP]
    type = tcp
    local_ip = 192.168.143.5
    local_port = 3389
    remote_port = 33889
    ```

- 运行frpc  
    `./frpc -c ~/storage/downloads/frpc.ini`

## 远程连接手机及手机所在的内网

- 连接手机SSH(Termux是单用户，没有用户名也可以任意用户名)  
    `ssh 1.2.3.4 -p 9999`
- 连接内网RDP  
    `mstsc /v:1.2.3.4:33889`

### 后记

- log出现以下字样才算转发成功  
    `[I] [control.go:179] [678440135bbaa784] [WINRDP] start proxy success`
- log若出现以下红色字样，应该属于网络不稳定，多等等或换FRP服务器  
    `[control.go:157] [678440135bbaa784] work connection closed before response StartWorkConn message: EOF`
- 同一SESSION内的SSHD才能流畅或者说不要切Termux的SESSION