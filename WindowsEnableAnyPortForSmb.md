## 局域网共享配置

两句搞定Windows防火墙，实现跨网段文件和打印机共享

- 配置个用户名和密码：

`net guest PrinterPassw0rd`

- 给防火墙添加一个入站规则：

`netsh advfirewall firewall add rule name="00.LC.Any" protocol=any dir=in action=allow remoteip="172.31.16.0/24" profile="any" description="LC.Any.Protocol"`

就能搞定 Windows 有 密码 的 打印机 共享，这样就不用关闭防火墙了。
