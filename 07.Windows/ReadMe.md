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
