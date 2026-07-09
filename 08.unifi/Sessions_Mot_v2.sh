#!/bin/bash
## 每3分钟运行一次，ppp0满足7000会话则记录日志
# */3 * * * * /root/s5 -wan ppp0 7000 >> /var/log/log-s5-7000.log 2>&1
# 添加环境变量，确保 Cron 环境下能找到系统命令
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- 1. 参数解析 ---
INTERFACES=()
THRESHOLD=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -wan)
            shift
            while [[ $# -gt 0 && ! $1 =~ ^[0-9]+$ ]]; do
                INTERFACES+=("$1")
                shift
            done
            if [[ $1 =~ ^[0-9]+$ ]]; then
                THRESHOLD=$1
                shift
            fi
            ;;
        *)
            shift
            ;;
    esac
done

# --- 2. 核心逻辑函数 ---

function get_ip() {
    local iface=$1
    local ip=$(ifconfig "$iface" 2>/dev/null | awk '/inet / {print $2}')
    echo "$ip"
}

function filter_conntrack() {
    local target_ip=$1
    conntrack -L 2>/dev/null \
    | grep -E "ESTABLISHED|SYN_RECV|SYN_SENT|udp" \
    | grep "${target_ip}" \
    | awk '{
        for(i=1;i<=NF;i++) {
            if($i ~ /^src=/) {
                print substr($i, 5);
                break;
            }
        }
    }'
}

# --- 3. 数据采集 ---

declare -A IFACE_SESS_COUNT
declare -A IFACE_DEV_COUNT
declare -A IFACE_TOP5
declare -A IFACE_IP        # 新增：存储接口IP
TOTAL_ACTIVE_SESSIONS=0
SESSION_SUM_STR=""
DEVICE_SUM_STR=""
ALL_IPS_COMBINED=""

for iface in "${INTERFACES[@]}"; do
    ip=$(get_ip "$iface")
    IFACE_IP["$iface"]=$ip

    if [[ -n "$ip" ]]; then
        raw_ips=$(filter_conntrack "$ip")
        count=$(echo "$raw_ips" | grep -c .)
        IFACE_SESS_COUNT["$iface"]=$count
        TOTAL_ACTIVE_SESSIONS=$((TOTAL_ACTIVE_SESSIONS + count))
        SESSION_SUM_STR="${SESSION_SUM_STR}${count}+"

        dev_count=$(echo "$raw_ips" | sort -u | grep -v "^$" | wc -l)
        IFACE_DEV_COUNT["$iface"]=$dev_count
        DEVICE_SUM_STR="${DEVICE_SUM_STR}${dev_count}+"

        ALL_IPS_COMBINED="${ALL_IPS_COMBINED}${raw_ips}"$'\n'
        IFACE_TOP5["$iface"]=$(echo "$raw_ips" | sort | uniq -c | sort -nr | head -n 5)
    else
        IFACE_SESS_COUNT["$iface"]=0
        IFACE_DEV_COUNT["$iface"]=0
        SESSION_SUM_STR="${SESSION_SUM_STR}0+"
        DEVICE_SUM_STR="${DEVICE_SUM_STR}0+"
    fi
done

GLOBAL_UNIQUE_DEVICES=$(echo "$ALL_IPS_COMBINED" | sort -u | grep -v "^$" | wc -l)
SESSION_SUM_STR=${SESSION_SUM_STR%+}
DEVICE_SUM_STR=${DEVICE_SUM_STR%+}

# --- 4. 格式化输出 ---

if [ "$TOTAL_ACTIVE_SESSIONS" -ge "$THRESHOLD" ]; then
    echo "统计分隔线------------------------------------------------------------------------------"
    echo "日期及时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "实时活动会话总数: ${TOTAL_ACTIVE_SESSIONS} = ${SESSION_SUM_STR}"
    echo "全网活跃设备总数: ${GLOBAL_UNIQUE_DEVICES} = ${DEVICE_SUM_STR}"

    for iface in "${INTERFACES[@]}"; do
        # 在这里加上了接口的 IP 输出
        current_ip=${IFACE_IP[$iface]:-"未获取到IP"}
        echo "接口 ${iface} (${current_ip}) 的实时会话: ${IFACE_SESS_COUNT[$iface]} 和 DEVICES: ${IFACE_DEV_COUNT[$iface]}，排名（TOP5)的实时会话数量及DEVICE的IP"
        if [ -n "${IFACE_TOP5[$iface]}" ]; then
            echo "${IFACE_TOP5[$iface]}"
        else
            echo "    (无活跃会话)"
        fi
    done

    echo "日期及时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "统计分隔线------------------------------------------------------------------------------"
fi
