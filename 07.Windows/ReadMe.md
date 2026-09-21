## 记Windows下的cmd与powershell日常

### 测试发通知：
- Powershell，iwr(Invoke-WebRequest)
```powershell
iwr 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx -Me PO -Co 'application/json' -B ("{{""msgtype"":""text"",""text"":{{""content"":""[{0}]-[{1}]-[{2}]""}}}}" -f $env:COMPUTERNAME,$env:USERNAME,(Get-NetIPAddress -AddressF IPV4 | ? {$_.PrefixOrigin -eq 'Dhcp'}).IPAddress) > $null
```

- CMD，Powershell+iwr
```cmd
powershell -NoProfile -Command "iwr 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx' -Me PO -Co 'application/json' -B (\"{{\"\"msgtype\"\":\"\"text\"\",\"\"text\"\":{{\"\"content\"\":\"\"[{0}]-[{1}]-[{2}]\"\"}}}}\" -f $env:COMPUTERNAME,$env:USERNAME,(Get-NetIPAddress -AddressF IPV4 | ? {$_.PrefixOrigin -eq 'Dhcp'}).IPAddress) > $null"
```

- CMD，Curl
```cmd
curl https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx-d "{\"msgtype\": \"text\",\"text\": {\"content\": \"[%time%]-[%computername%]-[%username%]-[xxx"]\"}}"
```


## 其它笔记
1、RDCMan.exe更新到Remote Desktop Connection Manager v3.21 版本之后，有一个问题，就是原来添加的server的认证都有可能失效掉，包括本地认证（本地认证还在，单独使用mstsc来连接是没有问题的），解决方案：
* 把出问题的对应的regedit路径这里面的server地址删除掉就行了：
* ```HKEY_CURRENT_USER\SOFTWARE\Microsoft\Terminal Server Client\Servers```

2、.pptx的文件里面有很多图片或视频时，文件会非常大，图片还容易解决（用自带的压缩工具进行另存为就行了），如果是视频，解决方案：
  * 2.1、后缀添加.zip，然后把里面的类似media1.mp4的所有视频都拉出来
  * 2.2、使用ffmpeg进行批量压缩，按[微软文档](https://support.microsoft.com/zh-cn/powerpoint/video-and-audio-file-formats-supported-in-powerpoint)，只支持视频：.mp4 使用 H.264 视频和 AAC 音频编码的文件（格式：.mp4、.m4v、.mov、	.webm）
  * 2.3、```if exist ppt mkdir ppt&&for %a in (*.mp4) do (d:\soft\sharex\ffmpeg.exe -i "%a" -c:v libx264 -preset fast -crf 26 "ppt\%~na.mp4")```
    - 其中crf值用来控制体积（质量），在 FFmpeg 的 libx264 编码器中，CRF（Constant Rate Factor）设置的有效范围是 0 到 51。
    - 0：无损模式（Lossless，文件体积非常庞大）。
    -  18：视觉无损模式（人眼基本无法分辨与原画的区别）。
    -  23：libx264 的默认值。
    -  51：最低画质模式（画面严重打块，体积最小）。
    -  (注：数值越小，画质越高、文件越大；数值越大，画质越低、文件越小。通常建议设置在 18 – 28 之间。)
  * 2.4、然后直接拖进原来的zip的pptx文件中覆盖原来的视频文件，把.zip后缀去掉，变回.pptx文件即可获得压缩后的pptx文件
