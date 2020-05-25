## 小米6(sagit)刷机记录 lineageos 17.1 （Linux）

### 1. 线刷最新MIUI（可以避免很多坑）
    2020-05-17 00:32 cd sagit_images_V11.0.5.0.PCACNXM_20200305.0000.00_9.0_cn
    2020-05-17 00:39 adb reboot bootloader
    2020-05-17 00:40 sudo bash ./flash_all.sh
    2020-05-17 01:05 fastboot flash recovery twrp-3.3.1-sagit-20191204.img
    2020-05-17 01:07 fastboot reboot
- 执行重启并按住 <kbd>音量加</kbd> 键进入TWRP（抢在MIUI启动之前，不然它会替换成MI-Re）

### 2. 全清操作
- <kbd>TWRP主界面</kbd>-><kbd>Wipe</kbd>-><kbd>Adavanced Wipe</kbd>-> 勾选<kbd>Dalvik / ART Cache</kbd>、<kbd>Cache</kbd>、<kbd>System</kbd>、<kbd>Data</kbd>、<kbd>Internal Storage</kbd>（切勿勾选到<kbd>Vendor</kbd>） -> 划过滑动条确认擦除
    （输入 yes，打钩确认格式化 data）

### 3. 刷入fireware、lineage、opengapps、magisk
- 因每次sideload后都会自动退出 ADB Sideload，所以以下每次执行都需要，<kbd>TWRP主界面</kbd>-><kbd>Advanced</kbd>-><kbd>ADB Sideload</kbd>（划过滑条即可）

        2020-05-17 01:18 adb sideload fw_sagit_miui_MI6_20.4.30_1f77f6d5fe_9.0.zip
        2020-05-17 01:19 adb sideload lineage-17.1-20200428-nightly-sagit-signed.zip
        2020-05-17 01:21 adb sideload open_gapps-arm64-10.0-nano-20200516.zip
        2020-05-17 01:23 adb sideload Magisk-v20.4.zip

### 4. 重启并跳过导向
- 开机第一屏，语言选择界面，顺时针点击屏幕白色区域四个角，即可跳过向导（Google的联网检查）
    
- 左键返回，右键任务：在<kbd>Settings 设置</kbd>-><kbd>System 系统</kbd>-><kbd>Buttons 按键</kbd>-><kbd>Additional buttons 更多按键</kbd>-><kbd>Swap buttons 交换按键</kbd>开启这个选项

- 长按电源键开手电筒：在<kbd>Settings 设置</kbd>-><kbd>System 系统</kbd>-><kbd>Buttons 按键</kbd>-><kbd>长按打开手电筒</kbd>

### 附录

- [MIUI线刷](https://www.miui.com/shuaji-393.html)
- [sagit_images_V11.0.5.0.PCACNXM_20200305.0000.00_9.0_cn](https://update.miui.com/updates/v1/fullromdownload.php?d=sagit&b=F&r=cn&n=)
- [recovery twrp-3.3.1-sagit-20191204.img](https://github.com/xiaomi-msm8998/twrp_device_xiaomi_sagit/releases)
- [fw_sagit_miui_MI6_20.4.30_1f77f6d5fe_9.0.zip](https://github.com/XiaomiFirmwareUpdater/firmware_xiaomi_sagit/releases/)
- [lineage-17.1-20200428-nightly-sagit-signed.zip](https://download.lineageos.org/sagit)
- [open_gapps-arm64-10.0-nano-20200516.zip](https://opengapps.org/)
- [Magisk-v20.4.zip](https://github.com/topjohnwu/Magisk/releases)


### 已知问题
- 无法使用人脸识别解锁（听说是漏洞和侵权造成的）
- 无法切换至SIM卡的NFC（例如sim卡的公交卡）
- 双卡铃声无法单独设置（两个sim卡来电同一铃声）
- 自带拨号器的通话录音无法自动录音（我用[第三方](https://gitlab.com/axet/android-call-recorder)解决）

参考 [2020年 小米6 刷机 LineageOS 17.1 Official](https://ericclose.github.io/Install-LineageOS-on-sagit.html)
