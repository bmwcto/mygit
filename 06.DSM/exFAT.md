群晖 exFAT U盘 优盘

登录到SSH,切换到root:
`sudo su -`

开启Root，并重置密码：（反正我没开成功）
`synouser --setpw root password`

下载arm版本的exfat并解压复制到bin：
```
wget -P /tmp/ https://mirrors.edge.kernel.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.2.5-2_armhf.deb
dpkg -x /tmp/exfat-fuse_1.2.5-2_armhf.deb /tmp/exfat-fuse3/
cp /tmp/exfat-fuse3/sbin/mount.exfat-fuse /usr/bin/
```

查看一下usb设备：（我的是 `/dev/sdq` ）
`fdisk -l`

建立一个目录，然后挂载分区，最后备份所有文件到指定路径：
```
mkdir -p /volumeUSB1/usbshare1-3
mount.exfat-fuse /dev/sdq1 /volumeUSB1/usbshare1-3 -o nonempty
cp -r /volumeUSB1/usbshare1-3/* /volume1/01.SoftAndOS/004.USB-bak/
```

推出USB设备：
`eject -F /dev/sdq`



