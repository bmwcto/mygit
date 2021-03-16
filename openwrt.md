## OPENWRT相关记录（cli）

### [备份和还原](https://openwrt.org/docs/guide-user/troubleshooting/backup_restore)

    # Generate backup
    umask go=
    sysupgrade -b /tmp/backup-${HOSTNAME}-$(date +%F).tar.gz
    ls /tmp/backup-*.tar.gz
    
    # Download backup
    scp ”root@openwrt.lan:/tmp/backup-*.tar.gz“ .

    # Upload backup
    scp ”backup-*.tar.gz“ root@openwrt.lan:/tmp
    
    # Restore backup
    ls /tmp/backup-*.tar.gz
    sysupgrade -r /tmp/backup-*.tar.gz

### 添加SSH [KEY登录](https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth)

   - 需要把Key文件复制到 `/etc/dropbear/authorized_keys` 路径下
   - 使用 `ssh-keygen -t rsa -b 4096` 生成key，并把pubkey内容复制到 `/etc/dropbear/authorized_keys`
   - 对于普通用户： `ssh openwrt.lan "mkdir -p ~/.ssh; tee -a ~/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub`
   - 修复权限： `chmod -R u=rwX,go= /etc/dropbear`

### 升级与查看软件包

   - 一性次升级所有软件包： `opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade`
   - 列出所安装的软件： `opkg list-installed`
   - 中文LUCI界面： `luci-i18n-base-zh-cn` `luci-i18n-nlbwmon-zh-cn`
   - 宽带流量监控软件： `nlbwmon` `luci-app-nlbwmon`
   - 命令行实时流量软件： `bmon` `bwm-ng`

### 重点提示

   - 升级固件后，`/root/` 下的文件都被清空。所有附加软件包也会被清空。

### 计划任务

   - 每周六凌晨5点重启： `00 5 * * 6 sleep 70 && touch /etc/banner && reboot`

### 给opkg添加代理信息

   - 只需要http代理，在 `/etc/opkg.conf`，添类似以下信息：
   - `option http_proxy http://10.0.0.1:3800/`