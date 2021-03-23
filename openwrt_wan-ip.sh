#!/bin/bash
# 监控WAN口数据及IP变化，定时发送数据到TGbot，IP变换后立刻发送新的IP到TGbot。
# by BMWCTO
powerby="by <bmwcto> 2021-03-22 18:56:33"
ver="1.0"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!" && exit 1

api_key="YOUR Telegram Bot Key"
chat_id="YOUR Telegram ID"

# Shell路径
SHELL_FOLDER=$(dirname $(readlink -f "$0"))

# PPPOE拨号出来的WAN口数据量,除去行首空格
#WanData=$(ifconfig pppoe-wan |awk 'NR==7 {print $0}')
#WanData=$(ifconfig pppoe-wan |awk 'NR==7 {print}')|sed 's/^[ ]*//g'
WanData=$(ifconfig pppoe-wan |awk 'NR==7 {gsub(/^\s+|\s+$/, "");print}')

# PPPOE拨号出来的WAN口IP
WanIP=$(ifconfig pppoe-wan |awk -F '[ :]+' 'NR==2 {print $4}')



## 使用说明
usage(){
        name=`basename $0`
        echo "$name 版本：$ver $powerby"
        echo
        echo "用处：监控WAN口数据及IP变化，定时发送数据到TGbot，IP变换后立刻发送新的IP到TGbot。"
        echo 
        echo "两个参数分别为：senddata 及 sendip"
        echo 
        echo "发送数据： ./$name senddata"
        echo 
        echo "发送IP： ./$name sendip"
}

# 发送数据量
senddata(){
        WanDatareport="%0A ====#WANDATA======= \
        %0A${WanData} \
        %0A ===========[WANDATA](https://ip.sb/ip/$WanIP)"
        curl -x socks5h://10.0.0.250:443 -s -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id=$chat_id -d text="$WanDatareport" -d parse_mode="markdown" -d disable_web_page_preview="true"> /dev/null
        exit 0
}

#发送IP
sendip(){
        WanlastIpFile=$SHELL_FOLDER/WAN_last_ip.txt
        lastIp='no_ip'

        if test -f "$WanlastIpFile"
        then
                lastIp="$(cat $WanlastIpFile)"   
        else 
                echo 'no_ip' > $WanlastIpFile
        fi
                echo "old ip is:[ $lastIp ]"
                #currentIp=${WanIP}
                echo "new ip is:[ $WanIP" ]
        if [[ $lastIp == $WanIP ]]
        then
                echo "no changes"
        else
                WANIPreport="%0A ====#LDIP======= \
                %0A${WanIP}:1986 \
                %0A ===========[LDIP](https://ip.sb/ip/$WanIP)"
                curl -x socks5h://10.0.0.250:443 -s -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id=$chat_id -d text="$WANIPreport" -d parse_mode="markdown" -d disable_web_page_preview="true"> /dev/null
                echo "$WanIP" > $WanlastIpFile
        fi
}

## 未加任何参数时输出数据，除了senddata和sendip之外就输出使用帮助
## shift `expr $OPTIND - 1`

if [ ! -n "$1" ]; then
        senddata
        exit
elif [ "$1" = "senddata" ]; then
        senddata
        exit
elif [ "$1" = "sendip" ]; then
        sendip
        exit
else
        usage
        exit
fi

# #!/bin/bash
# a(){
#     echo "aaaaa"
# }


# b(){
#     echo "bbbbb"
# }


# c(){
#     echo "ccccc"
# }

# for i in "$@"; do
#     case $i in
#     -a)
#         echo $(a)
#         ;;
#     -b)
#         echo $(b)
#         ;;
#     -c)
#         echo $(c)
#         ;;
#     *) ;;
#     esac
# done%
