# mygit
克隆到本地

`git clone git@github.com:bmwcto/mygit.git`

## update by myphone
## update by myphone test
## Test my ssh login
## test my ssh mi6
## test my ssh mi6 again
## Test proxy socks5 for ssh(git)
 ```bash
$ cat ~/.ssh/config
Host github.com
   HostName github.com
   User git
   ProxyCommand ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p
```


## 关于用 cli 来操作 issue
 记得先安装 hub

 `sudo apt install hub`

[这里是hub文档](https://hub.github.com/hub.1.html)

### 浏览
 默认浏览前10未关闭的 issue

 `hub issue`

 可以指定浏览第1个 issue

 `hub issue show 1`

 还可以限制输出前3个

 `hub issue -L 3`

### 创建
 用文件创建 issue

 `hub issue create -c -F issue.txt`

 issue.txt的格式是：

 ```
 这是标题（以下空一行之后都是问题描述）

 以下（包括此行）都是问题描述，可以以markdown格式来用做问题描述
 ```

 用一句命令来创建：

 `hub issue create -c -m "这是标题" -m "" -m "这是描述" -l "hub,cli,test"`
