# 利用kickstart应答文件网络全自动重装CentOS7

> 这是一篇转载（[搬运自此](https://lala.im/7237.html)）

1. 原系统是Debian10/Ubuntu18.04，且使用GRUB2引导。
2. 网络使用DHCP。静态地址应该也是可以的，但本文目前还未提及到相关配置，后续会更新。
3. 需要另外一台机器临时起一个HTTP服务存放kickstart文件。
4. 内存至少1GB，因为CentOS的网络安装机制，安装过程中会下载一个squashfs.img加载到内存中，越高的版本这个镜像越大，所以对内存的要求也越高。

- 注意：1GB内存可以安装CentOS 7.0-7.2，7.3之后的版本至少要2G内存。这里使用7.2演示完整的操作步骤。

***

## 创建kickstart应答文件

- 首先登录你的另外一台机器，在这个机器内创建ks文件  
    `mkdir -p /opt/kickstart && cd /opt/kickstart && nano anaconda-ks.cfg`

- anaconda-ks.cfg 文件如下

    ```txt
    # 安装源
    install
    url --url="http://vault.centos.org/7.2.1511/os/x86_64/"

    # 纯文本安装，自动安装必须指定
    text

    # mbr
    bootloader --location=mbr
    zerombr

    # 设置你的ROOT密码
    rootpw --plaintext 123456

    # 键盘配置/时区配置/语言配置
    keyboard us
    timezone Asia/Shanghai
    lang en_US --addsupport=zh_CN

    # 网络使用DHCP
    network --bootproto=dhcp --ipv6=auto --onboot=on --activate

    # 配置静态地址，本文暂未提及
    # network --bootproto=static --ip=xxx --netmask=xxx --gateway=xxx --nameserver=8.8.8.8 --ipv6=auto --onboot=on --activate

    # 删除硬盘上之前的分区信息并自动分区
    clearpart --all --initlabel
    autopart --type=plain --fstype=ext4

    # 关闭防火墙/SELinux
    firewall --disabled
    selinux --disabled

    # 安装完成后重启
    reboot

    # 最小化安装
    %packages --nobase
    @core
    %end
    ```

- 然后起一个HTTP服务  
    `python3 -m http.server`

- 正常的话应该会有类似如下的回显，打开你的机器IP:8000应该能够下载到这个ks文件  
     `Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...`

***

## 下载initrd和内核

- 现在登录到要重装系统的机器内下载内核和initrd

    ```shell
    mkdir -p /boot/centos && cd /boot/centos
    wget http://vault.centos.org/7.2.1511/os/x86_64/isolinux/vmlinuz
    wget http://vault.centos.org/7.2.1511/os/x86_64/isolinux/initrd.img
    ```

- 新建一个grub菜单  
    `nano /etc/grub.d/40_custom`

- 写入如下配置，注意IP换成你自己的

    ```txt
    menuentry 'CentOS 7 install DHCP' {
    set root='hd0,msdos1'
    linux /boot/centos/vmlinuz nameserver=8.8.8.8 inst.ks=http://IP:8000/anaconda-ks.cfg
    initrd /boot/centos/initrd.img
    }
    ```

- 注：nameserver这里必须指定一个DNS服务器，因为CentOS这个vmlinuz内的DHCP不会帮你配置DNS。
- 接下来编辑grub配置文件  
    `nano /etc/default/grub`
- 修改默认启动项为刚才新添加的菜单  
    `GRUB_DEFAULT="CentOS 7 install DHCP"`

- 注：如果你不知道怎么看启动顺序就可以直接填写menuentry的名字，否则我个人还是建议按启动顺序来配置。

***

## 重启开始安装

- 最后更新grub配置并重启，机器就开始自动重装了

    ```shell
    update-grub
    reboot
    ```

- 安装速度取决于机器网络和性能。

***

## 其它

- 优化的待办事项：

1. 网络不使用DHCP，使用静态地址配置。
2. kickstart不使用外部HTTP服务器，直接加载。
3. CentOS重装CentOS，而不是只能从Debian/Ubuntu重装CentOS。

- 在折腾的过程中还碰到一个[BUG](https://bugs.centos.org/view.php?id=13969)
- 参考文献：  
    <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options>  
    <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax>  
    <https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html>
- 搬运纯属为了学习
