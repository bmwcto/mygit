#!/bin/bash
# 可执行：chmod +x Sessions_Mot.sh
# 使用watch -n 1 "./Sessions_Mot.sh"，即每秒执行并默认输出前5的连接。
# 使用watch -n 2 "./Sessions_Mot.sh 10"，即每2秒执行并输出前10的连接。

#!/bin/bash

# --- 变量定义 ---
WAN1_IP=$(ifconfig ppp2 | awk '/inet / {print $2}')
WAN2_IP=$(ifconfig eth9 | awk '/inet / {print $2}')
WAN4_IP=$(ifconfig eth1 | awk '/inet / {print $2}')

# 默认显示前5名，可以传入脚本第一个参数更改
TOP_N=${1:-5}

# 核心统计函数：统计连接到指定WAN IP的ESTABLISHED会话中，原始源IP的连接数排名
# 参数1: 目标WAN IP地址 (例如: 1.1.1.1)
# 参数2: 排名前N (默认: 5)
# ---------------------------------------------------------
# 新增函数：统计去重后的原始源 IP 总数 (即设备数量)
# ---------------------------------------------------------
function count_unique_src_ips() {
    local target_ip=${1}

    # 逻辑与之前类似，但最后使用 sort -u (去重) 和 wc -l (计数)
    conntrack -L 2>/dev/null \
    | grep "ESTABLISHED" \
    | grep "${target_ip}" \
    | awk '{
        for(i=1;i<=NF;i++) {
            if($i ~ /^src=/) {
                print substr($i, 5);
                break;
            }
        }
    }' \
    | sort -u \
    | wc -l
}

function count_top_src_ips() {
    local target_ip=${1}
    local top_n=${2:-5}
    # 这里我们可以在内部调用上面的函数，把总数显示在标题里
    local total_devices=$(count_unique_src_ips "$target_ip")

    echo "=== 正在统计连接到 ${target_ip} 且处于【已建立】(ESTABLISHED) 状态的会话 ==="
    #echo "=== 显示排名前 ${top_n} 的原始源 IP 地址 ==="
    echo "=== 原始源 IP 总数(设备数): ${total_devices} 个 | 显示前 ${top_n} 名 ==="

    # 核心统计逻辑：
    # 1. conntrack -L 2>/dev/null: 运行conntrack，并将stderr（版本信息等）重定向到/dev/null
    # 2. grep "ESTABLISHED": 过滤ESTABLISHED状态的会话
    # 3. grep "${target_ip}": 过滤包含目标IP的会话
    # 4. awk 提取原始源 IP: 找到第一个 src= 字段，即连接的原始源IP
    # 5. sort | uniq -c | sort -nr | head -n: 统计、计数、排序、截取前N名
    conntrack -L 2>/dev/null \
    | grep "ESTABLISHED" \
    | grep "${target_ip}" \
    | awk '{
        # 找到并打印第一个 src= 字段，即原始源 IP
        for(i=1;i<=NF;i++) {
            if($i ~ /^src=/) {
                # 提取 IP 地址部分 (跳过 "src=")
                # $i 格式为 src=X.X.X.X
                print substr($i, 5);
                break;
            }
        }
    }' \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n "${top_n}"
}

# --- 主要执行部分 ---

# 1. 统计处于“已建立”状态的会话数量 (解决输出问题：通过重定向 stderr 解决)
# 注意：这里使用 grep -c 计数时，conntrack -L 的输出是作为管道输入，
# 即使重定向 stderr，但 grep -c 计数结果也会因为管道被影响，
# 最佳做法是让 conntrack -L 自身重定向 stderr。

WAN1_ESTABLISHED=$(conntrack -L 2>/dev/null | grep "ESTABLISHED" | grep -c "src=$WAN1_IP\|dst=$WAN1_IP")
WAN2_ESTABLISHED=$(conntrack -L 2>/dev/null | grep "ESTABLISHED" | grep -c "src=$WAN2_IP\|dst=$WAN2_IP")
WAN4_ESTABLISHED=$(conntrack -L 2>/dev/null | grep "ESTABLISHED" | grep -c "src=$WAN4_IP\|dst=$WAN4_IP")

# 2. 统计全部会话总数 (解决输出问题：通过重定向 stderr 和 awk 筛选解决)
# conntrack -L | wc -l 会输出两个数字：版本信息中的计数 和 wc -l 的计数
# 使用 awk '{print $1}' 可以确保只输出 wc -l 的最终计数

# 1. 计算所有 WAN 口实时活动会话的总和
TOTAL_ESTABLISHED_SESSIONS=$((WAN1_ESTABLISHED + WAN2_ESTABLISHED + WAN4_ESTABLISHED))

# 2. 计算正在连接到外部网络的去重设备总数 (汇总所有 WAN 口的唯一源 IP)
# 我们利用之前定义的 count_unique_src_ips 逻辑，但一次性针对所有出口 IP 进行统计
all_total_devices=$(conntrack -L 2>/dev/null \
    | grep "ESTABLISHED" \
    | grep -E "(${WAN1_IP}|${WAN2_IP}|${WAN4_IP})" \
    | awk '{
        for(i=1;i<=NF;i++) {
            if($i ~ /^src=/) {
                print substr($i, 5);
                break;
            }
        }
    }' \
    | sort -u \
    | wc -l)

date
echo "--- 实时活动会话总数：[${TOTAL_ESTABLISHED_SESSIONS}] ---"
echo "WAN1 Sessions (WAN1): $WAN1_ESTABLISHED"
echo "WAN2 Sessions (WAN2): $WAN2_ESTABLISHED"
echo "WAN4 Sessions (WAN3): $WAN4_ESTABLISHED"
echo "------------------------------------"

# 新增，实时活动会话总数TOTAL_ESTABLISHED_SESSIONS
# 新增，正在连接到外部网络的设备总数: ${all_total_devices}

TOTAL_SESSIONS=$(conntrack -L 2>/dev/null | wc -l)
echo "全部会话总数 (包含关闭中): ${TOTAL_SESSIONS}"
echo
echo "当前会话设备总数: ${all_total_devices}"
echo "------------------------------------"

# 3. 系统信息
top -b -n 1 | head -n 6
sensors | grep "Board Temp" | awk '{printf "Board Temp：%s\n", $3}'
echo "------------------------------------"

# 4. 调用函数统计 WAN1
count_top_src_ips "$WAN1_IP" "$TOP_N"
echo "------------------------------------"


# 5. 调用函数统计 WAN2
count_top_src_ips "$WAN2_IP" "$TOP_N"

# 5. 调用函数统计 WAN4
count_top_src_ips "$WAN4_IP" "$TOP_N"
