#!/bin/bash

## sudo bash ./wg-dom-ip.sh wg0
## */10 * * * * sleep 10 && bash /etc/wireguard/wg-dom-ip.sh wg0
## by BMWCTO
## 2021-03-16 21:12:18 

## 用NSLOOKUP查询的结果会来回变化，从而导致服务频繁重启
## 改用Ping试试
## 2021-03-17 21:40:05 


## 新增dig查询
## 默认取第一个值
## 2021-03-17 23:47:35 

SHELL_FOLDER=$(dirname $(readlink -f "$0"))
dom=$(grep -Ev "^$|[#;]" /etc/wireguard/$1.conf|awk '/Endpoint/{print $3}'|cut -d: -f1)
#nsdomip=$(nslookup $dom 114.114.114.114|awk -F '[ ():]+' 'NR==6 {print $2}')
pdomip=$(ping -c1 $dom|awk -F '[ ():]+' 'NR==1 {print $3}')
#Ddomip=$(dig $dom|awk '/^$dom/{print $5}'|head -n1)

lastIpFile=$SHELL_FOLDER/wg-dom-last-ip-$1
lastIp='no_ip'

if test -f "$lastIpFile"
then
        lastIp="$(cat $lastIpFile)"   
else 
        echo 'no_ip' > $lastIpFile
fi
echo "old ip is:[ $lastIp ]"
#currentIp=$nsdomip
currentIp=$pdomip
echo "new ip is:[ $currentIp" ]
if [[ $lastIp == $currentIp ]]
then
        echo "no changes"
else
        
sleep 10s
systemctl restart wg-quick@$1> /dev/null
echo "$currentIp" > $lastIpFile
fi
