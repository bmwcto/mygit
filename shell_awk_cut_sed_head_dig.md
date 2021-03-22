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

