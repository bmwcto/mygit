#!/bin/bash

# 可执行：chmod +x Sessions_Mot.sh
# 使用watch -n 1 "./Sessions_Mot.sh"，即每秒执行并默认输出前5的连接。

#使用方法说明：
#默认运行： 直接运行 ./Sessions_Mot.sh，它会默认只统计 eth9。
#指定多个接口： 使用 -wan 参数，后面跟任意数量的接口名： ./Sessions_Mot.sh -wan eth9 eth1 ppp2
#同时修改排名数量： 使用 -n 参数： ./Sessions_Mot.sh -wan eth9 eth1 -n 10

#错误处理：
#如果你输入了不存在的接口（如 eth99），它会显示 [接口不存在]。
#如果接口存在但没拨号成功（没 IP），它会显示 [未连接/无IP]。

# --- 1. 参数解析与默认值 ---
INTERFACES=("eth9")
TOP_N=5

while [[ $# -gt 0 ]]; do
    case $1 in
        -wan)
            shift
            INTERFACES=()
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                INTERFACES+=("$1")
                shift
            done
            ;;
        -n)
            shift
            TOP_N=$1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# --- 2. 核心逻辑函数 ---

# 获取 CPU 核心数用于计算百分比
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)

# 获取接口 IP
function get_ip() {
    local iface=$1
    if ! ifconfig "$iface" >/dev/null 2>&1; then
        echo "ERR_NOT_FOUND"
        return
    fi
    local ip=$(ifconfig "$iface" 2>/dev/null | awk '/inet / {print $2}')
    if [ -z "$ip" ]; then
        echo "ERR_NOT_CONNECTED"
    else
        echo "$ip"
    fi
}

# 核心过滤逻辑：提取 ESTABLISHED, SYN_RECV, SYN_SENT
function filter_conntrack() {
    local target_ip=$1
    conntrack -L 2>/dev/null \
    | grep -E "ESTABLISHED|SYN_RECV|SYN_SENT" \
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

declare -A WAN_IPS
declare -A WAN_DATA
declare -A WAN_DEV_COUNT  # 新增：用于存储每个接口的设备数
TOTAL_ACTIVE_SESSIONS=0

for iface in "${INTERFACES[@]}"; do
    res=$(get_ip "$iface")
    if [[ "$res" == "ERR_NOT_FOUND" ]]; then
        WAN_IPS["$iface"]="[接口不存在]"
    elif [[ "$res" == "ERR_NOT_CONNECTED" ]]; then
        WAN_IPS["$iface"]="[未连接/无IP]"
    else
        WAN_IPS["$iface"]="$res"
        raw_ips=$(filter_conntrack "$res")
        WAN_DATA["$iface"]="$raw_ips"
        
        # 统计该接口会话总数
        count=$(echo "$raw_ips" | grep -c .)
        TOTAL_ACTIVE_SESSIONS=$((TOTAL_ACTIVE_SESSIONS + count))
        
        # 统计该接口去重后的设备数
        dev_count=$(echo "$raw_ips" | sort -u | grep -v "^$" | wc -l)
        WAN_DEV_COUNT["$iface"]=$dev_count
    fi
done

# 全网总去重设备数
ALL_SRC_IPS=$(for iface in "${!WAN_DATA[@]}"; do echo "${WAN_DATA[$iface]}"; done)
GLOBAL_UNIQUE_DEVICES=$(echo "$ALL_SRC_IPS" | sort -u | grep -v "^$" | wc -l)

# --- 4. 报告输出 ---

date
echo "========================================================="
echo "实时活动会话总数 (ESTABLISHED+SYN_RECV+SYN_SENT): [${TOTAL_ACTIVE_SESSIONS}]"
echo "系统全部会话总数 (含所有状态): $(conntrack -L 2>/dev/null | wc -l)"
echo "全网活跃设备总数 (去重汇总): ${GLOBAL_UNIQUE_DEVICES}"
echo "---------------------------------------------------------"

# 接口列表状态 (重新加入了设备数量统计)
for iface in "${INTERFACES[@]}"; do
    ip=${WAN_IPS[$iface]}
    if [[ "$ip" =~ ^\[ ]]; then
        printf "接口 %-8s : %s\n" "$iface" "$ip"
    else
        sess_count=$(echo "${WAN_DATA[$iface]}" | grep -c .)
        dev_count=${WAN_DEV_COUNT[$iface]}
        # 格式化输出：接口名 | IP | 会话数 | 设备数
        printf "接口 %-8s : %-15s | 实时会话: %-5d | DEVICES: %-d\n" "$iface" "$ip" "$sess_count" "$dev_count"
    fi
done
echo "---------------------------------------------------------"

# 负载百分比计算
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
LOAD_PCT=$(awk -v load="$LOAD_1MIN" -v cores="$CPU_CORES" 'BEGIN {printf "%.1f%%", (load/cores)*100}')

sensors 2>/dev/null | grep "Board Temp" | awk '{printf "板载温度：%s | ", $3}'
echo "CPU 负载率: $LOAD_PCT ($CPU_CORES 核)"
echo "---------------------------------------------------------"

# 排名详情
for iface in "${INTERFACES[@]}"; do
    ip=${WAN_IPS[$iface]}
    if [[ ! "$ip" =~ ^\[ ]]; then
        echo ">>> 排名（TOP$TOP_N): $iface ($ip) - DEVICES: ${WAN_DEV_COUNT[$iface]} <<<"
        data="${WAN_DATA[$iface]}"
        if [ -n "$data" ]; then
            echo "$data" | sort | uniq -c | sort -nr | head -n "$TOP_N"
        else
            echo "(无活跃会话)"
        fi
        echo ""
    fi
done
