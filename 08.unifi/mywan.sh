$ cat /config/myssh/mywan.sh
#!/bin/sh
#OPENWRT PPPOE WAN IPaddress Send to Work WeiXin Bot
#17:48 2025/10/28 By KiMi And LC And Gemini
IP_FILE="/tmp/wan_ip.txt"
#openwrt
#CURRENT_IP=$(ifconfig pppoe-wan 2>/dev/null | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}')

#VyOS
CURRENT_IP=$(/sbin/ip -o -4 addr show pppoe0 | awk '{split($4,a,"/"); print a[1]}')
if [ -z "$CURRENT_IP" ]; then
    echo "$(date): ............ pppoe-wan IP" >> /tmp/wan_ip.log
    exit 1
fi
if [ -f "$IP_FILE" ]; then
    OLD_IP=$(cat "$IP_FILE")
else
    OLD_IP=""
fi
if [ "$CURRENT_IP" != "$OLD_IP" ]; then
    echo "$(date): WAN IP ............ IP: $OLD_IP...... IP: $CURRENT_IP" >> /tmp/wan_ip.log
    mytxt=LDMS_HOME_IP:${CURRENT_IP}
    curl -H "Content-Type: application/json" -X POST https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx -d '{"msgtype": "text", "text": {"content": "'"${mytxt}"'"}}' >/dev/null 2>&1 &
    echo "$CURRENT_IP" > "$IP_FILE"
fi
