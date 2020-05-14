# mygit
## update by myphone
## update by myphone test
## Test my ssh login
## test my ssh mi6
## Test proxy socks5 for ssh(git)
 ```bash
$ cat ~/.ssh/config
Host github.com
   HostName github.com
   User git
   ProxyCommand ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p
```
