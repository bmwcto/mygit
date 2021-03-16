#!/bin/bash

## sudo bash ./wg-dom-ip.sh wg0
## */10 * * * * sleep 10 && bash /etc/wireguard/wg-dom-ip.sh wg0
## by BMWCTO
## 2021-03-16 21:12:18 


SHELL_FOLDER=$(dirname $(readlink -f "$0"))
dom=$(grep -Ev "^$|[#;]" /etc/wireguard/$1.conf|awk '/Endpoint/{print $3}'|cut -d: -f1)
nsdomip=$(nslookup $dom 114.114.114.114|awk -F '[ ():]+' 'NR==6 {print $2}')

lastIpFile=$SHELL_FOLDER/wg-dom-last-ip-$1
lastIp='no_ip'

if test -f "$lastIpFile"
then
        lastIp="$(cat $SHELL_FOLDER/wg-dom-last-ip-$1)"   
else 
        echo 'no_ip' > $SHELL_FOLDER/wg-dom-last-ip-$1
fi
echo "old ip is:[ $lastIp ]"
currentIp=$nsdomip
echo "new ip is:[ $currentIp" ]
if [[ $lastIp == $currentIp ]]
then
        echo "no changes"
else
        
sleep 10s
systemctl restart wg-quick@$1> /dev/null
echo "$currentIp" > $SHELL_FOLDER/wg-dom-last-ip-$1
fi
