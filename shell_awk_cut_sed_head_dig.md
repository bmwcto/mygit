## SHELL实践学习记录

### 目的是为了找到LOG里面同一级域名的所有IP，并变为HOSTS文件格式，先IP后域名

- 从LOG提取带 nanopool.org 的域名列表存到 ool.txt 文件  
    `cat LOG|grep nanopool.org|awk '{print $5}'|cut -d: -f1>./ool.txt`

    因为 nanopool.org 所在列是第5列，然后还带端口类似：  
    `2021-Mar-22 03:19:41: Added pool: xmr-us-west1.nanopool.org:14433`

- 提取出来的列表为：  
    ```
    xmr-asia1.nanopool.org
    xmr-eu2.nanopool.org
    xmr-us-east1.nanopool.org
    xmr-eu1.nanopool.org
    xmr-jp1.nanopool.org
    xmr-us-west1.nanopool.org
    xmr-au1.nanopool.org
    ```

- 然后从ool.txt文件用 dig 查询每个域名的IP,并提取出首行IP和对应的域名，输出为hosts文件解析的格式  
    `while read dom;do dig $dom|awk '/^'"$dom"'/{print $5,$1}'|sed 's/rg./rg/g'|head -n1;done<./ool.txt`  
    解析：循环查询变量dom;然后每行都执行 dig 查询变量dom |用awk 查找以变量dom开头的并先打印出IP再打印出域名|用sed把所有域名后面的小数点去掉|只显示第1行;直到ool.txt列表每一行都读完

- 优化，觉得应该先只显示第1行，然后再用sed查找替换，效率应该更高一些，也就是：  
    `while read dom;do dig $dom|awk '/^'"$dom"'/{print $5,$1}'|head -n1|sed 's/rg./rg/g';done<./ool.txt`  

- 如果想是所有域名的所有对应IP，就要把 `head -n1` 去掉：  
    `while read dom;do dig $dom|awk '/^'"$dom"'/{print $5,$1}'|sed 's/rg./rg/g';done<./ool.txt`

- 添加一个gid为1001的samg用户组;并添加一个uid为1002的用户名为sam的空白密码用户，指定默认的用户路径为 '/home/sam' bash为 '/bin/sh'：  
    `addgroup -g 1001 samg && adduser -h /home/sam -s /bin/sh -G samg -u 1002 sam --disabled-password`

- 把当前用户添加到docker用户组：  
    `sudo usermod -aG docker $USER`

- 查询文件或某路径的gid或uid，或所属用户组或用户：  
    `stat -c %g /path;stat -c %u /path;stat -c %G /path;stat -c %U /path`

- 安装 nscd ,查询DNS缓存记录：  
    `sudo apt install -y nscd && sudo strings /var/cache/nscd/hosts|sort -u`

- 安装 ipset ,配合 iptables 屏蔽IP合集:  
    安装： `sudo apt install -y ipset`  
    查询： `sudo ipset list`  
    创建： `sudo ipset create banthis hash:net maxelem 1000000`  
    添加： `sudo ipset add banthis 192.168.1.2/32;sudo ipset add banthis 192.168.2.2/32`  
    删除： `sudo ipset del banthis 192.168.1.2/32`  
    屏蔽INPUT： `sudo iptables -I INPUT -m set --match-set banthis src -p tcp --destination-port 80 -j DROP`  
    屏蔽FORWARD： `sudo iptables -I FORWARD -m set --match-set banthis src -p tcp --destination-port 80 -j DROP -m comment --comment "Test web2"`  
    屏蔽192.168.1.2访问本机80端口： `sudo iptables -I FORWARD -s 192.168.1.2 -p tcp --dport 80 -j DROP`  
    查询INPUT： `sudo iptables -nv --line-numbers -L INPUT`  
    查询FORWARD： `sudo iptables -nv --line-numbers -L FORWARD`  
    删除INPUT第1条： `sudo iptables -D INPUT 1`  
    替换FORWARD第1条： `sudo iptables -R FORWARD 1 -m set --match-set banthis src -p tcp --destination-port 80 -j DROP -m comment --comment "Test web3"`  
    禁止所有IP连接80端口： `sudo iptables -I FORWARD -p tcp --dport 80 -j DROP`  
    开放192.168.1.2连接80端口： `sudo iptables -I FORWARD -s 192.168.1.2 -p tcp --dport 80 -j ACCEPT`  
    
    
