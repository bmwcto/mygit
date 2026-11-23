#!/usr/bin/env bash
# Parallel Xray REALITY + Vision deployment.
# Keeps the existing xray-vision service and TCP/443 configuration untouched.
# bash -c "$(curl -L https://github.com/bmwcto/mygit/raw/refs/heads/master/00.myss/xray-reality-parallel.sh)"
# apt install -y curl unzip vim
# bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
# sysctl net.ipv4.tcp_congestion_control
# tee /etc/sysctl.d/99-bbr.conf > /dev/null <<'EOF'
# net.core.default_qdisc = fq
# net.ipv4.tcp_congestion_control = bbr
# EOF
# sysctl --system
# Debian/Ubuntu + systemd; requires an already-installed Xray binary with REALITY support.
set -Eeuo pipefail
umask 077

PORT="${PORT:-8443}"
BASE="/etc/xray-reality"
CLIENT_DIR="/root/xray-reality-clients"
SERVICE="xray-reality"
XRAY_BIN="$(command -v xray || true)"

die() { echo "[ERROR] $*" >&2; exit 1; }
info() { echo "[INFO] $*"; }

[[ $EUID -eq 0 ]] || die "请使用 root 运行：sudo bash $0"
[[ -n "$XRAY_BIN" && -x "$XRAY_BIN" ]] || die "未找到 xray。请先安装 Xray-core。"
command -v python3 >/dev/null 2>&1 || die "缺少 python3。"
command -v openssl >/dev/null 2>&1 || die "缺少 openssl。"
command -v systemctl >/dev/null 2>&1 || die "此脚本需要 systemd。"
command -v ss >/dev/null 2>&1 || die "缺少 ss（通常由 iproute2 提供）。"

echo "===== Xray REALITY + Vision 并行部署 ====="
echo "现有 xray-vision / TCP 443 不会被修改。"
echo
read -r -p "服务器连接域名（指向本机公网 IP，例如 node.example.com）: " SERVER_DOMAIN
read -r -p "REALITY 伪装目标域名（建议与服务器同 ASN，不能随便填 CDN）: " TARGET_HOST
read -r -p "REALITY 目标端口 [443]: " TARGET_PORT
TARGET_PORT="${TARGET_PORT:-443}"
read -r -p "新节点监听端口 [${PORT}]: " INPUT_PORT
PORT="${INPUT_PORT:-$PORT}"

SERVER_DOMAIN="${SERVER_DOMAIN,,}"
TARGET_HOST="${TARGET_HOST,,}"

[[ "$SERVER_DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] || die "服务器域名格式不正确。"
[[ "$TARGET_HOST" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] || die "目标域名格式不正确。"
[[ "$TARGET_PORT" =~ ^[0-9]+$ ]] && (( TARGET_PORT > 0 && TARGET_PORT < 65536 )) || die "目标端口无效。"
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT > 0 && PORT < 65536 )) || die "监听端口无效。"
(( PORT >= 1024 )) || die "为避免额外授予低端口权限，请使用 1024 以上端口。"

if ss -lntH "( sport = :$PORT )" | grep -q .; then
    die "TCP $PORT 已被占用。请换一个未占用端口。"
fi

echo
info "Xray 版本：$("$XRAY_BIN" version | sed -n '1p')"
info "检测 REALITY 密钥生成能力……"
KEY_OUTPUT="$("$XRAY_BIN" x25519 2>&1)" || die "当前 Xray 不支持 xray x25519，请先升级 Xray-core。"
PRIVATE_KEY="$(printf '%s\n' "$KEY_OUTPUT" | awk -F': *' '/^PrivateKey:/ {print $2; exit}')"
PUBLIC_KEY="$(printf '%s\n' "$KEY_OUTPUT" | awk -F': *' '/^(Password|PublicKey):/ {print $2; exit}')"
[[ -n "$PRIVATE_KEY" && -n "$PUBLIC_KEY" ]] || {
    printf '%s\n' "$KEY_OUTPUT"
    die "无法从 xray x25519 输出中识别 PrivateKey/Password。请勿继续，先核对当前版本输出格式。"
}

UUID="$("$XRAY_BIN" uuid)"
SHORT_ID="$(openssl rand -hex 8)"
SPIDER_X="/"

info "探测 REALITY 目标 TLS 能力（仅供判断，不会自动更换目标）……"
TLS_PING_OUTPUT="$("$XRAY_BIN" tls ping "${TARGET_HOST}:${TARGET_PORT}" 2>&1 || true)"
printf '%s\n' "$TLS_PING_OUTPUT" | head -n 35
echo
echo "请检查上面的 TLS 探测结果：目标应能正常完成 TLS 握手。"
echo "若 Xray 显示支持 X25519MLKEM768，则 REALITY 可自动协商该后量子密钥交换。"
echo "若目标不支持，当前 REALITY 节点仍可正常使用 X25519，但不能宣称握手已具备后量子保护。"
echo
read -r -p "确认使用该 REALITY 目标并继续？(y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0

BACKUP="/root/xray-reality-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
if [[ -e "$BASE" ]]; then
    cp -a "$BASE" "$BACKUP/"
    info "已备份旧目录：$BASE"
fi
if [[ -e "/etc/systemd/system/${SERVICE}.service" ]]; then
    cp -a "/etc/systemd/system/${SERVICE}.service" "$BACKUP/"
fi

# Dedicated unprivileged service account; do not alter the existing Xray account/service.
if ! id xray-reality >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin xray-reality
fi

install -d -o root -g xray-reality -m 0750 "$BASE"
install -d -o root -g root -m 0700 "$CLIENT_DIR"

python3 - "$BASE/config.json" "$UUID" "$PORT" "$TARGET_HOST" "$TARGET_PORT" "$PRIVATE_KEY" "$SHORT_ID" <<'PY'
import json, sys
path, uid, port, target, target_port, private_key, short_id = sys.argv[1:]
cfg = {
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "tag": "reality-in",
    "listen": "0.0.0.0",
    "port": int(port),
    "protocol": "vless",
    "settings": {
      "clients": [{"id": uid, "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": False,
        "target": f"{target}:{target_port}",
        "xver": 0,
        "serverNames": [target],
        "privateKey": private_key,
        "shortIds": [short_id]
      }
    }
  }],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "block"}
  ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

chown root:xray-reality "$BASE/config.json"
chmod 0640 "$BASE/config.json"

# Validate before creating/restarting the service.
"$XRAY_BIN" run -test -config "$BASE/config.json" || die "Xray 服务端配置检查失败。未启动新服务。"

cat > "/etc/systemd/system/${SERVICE}.service" <<UNIT
[Unit]
Description=Xray VLESS REALITY Vision (parallel node)
Documentation=https://github.com/XTLS/Xray-core
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=xray-reality
Group=xray-reality
ExecStart=${XRAY_BIN} run -config ${BASE}/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
CapabilityBoundingSet=
AmbientCapabilities=

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now "$SERVICE"
sleep 2
systemctl is-active --quiet "$SERVICE" || {
    journalctl -u "$SERVICE" -n 60 --no-pager
    die "新节点启动失败。旧 xray-vision 节点未被修改。"
}

# Xray client configuration.
python3 - "$CLIENT_DIR/xray-client.json" "$SERVER_DOMAIN" "$PORT" "$UUID" "$TARGET_HOST" "$PUBLIC_KEY" "$SHORT_ID" "$SPIDER_X" <<'PY'
import json, sys
path, server, port, uid, sni, pub, sid, spider = sys.argv[1:]
cfg = {
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "127.0.0.1", "port": 10808, "protocol": "socks",
    "settings": {"auth": "noauth", "udp": True}
  }],
  "outbounds": [{
    "tag": "proxy", "protocol": "vless",
    "settings": {"vnext": [{
      "address": server, "port": int(port),
      "users": [{"id": uid, "encryption": "none", "flow": "xtls-rprx-vision"}]
    }]},
    "streamSettings": {
      "network": "tcp", "security": "reality",
      "realitySettings": {
        "serverName": sni, "fingerprint": "chrome",
        "password": pub, "shortId": sid, "spiderX": spider
      }
    }
  }, {"tag": "direct", "protocol": "freedom"}]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

# sing-box / SFA client configuration.
python3 - "$CLIENT_DIR/sing-box-client.json" "$SERVER_DOMAIN" "$PORT" "$UUID" "$TARGET_HOST" "$PUBLIC_KEY" "$SHORT_ID" <<'PY'
import json, sys
path, server, port, uid, sni, pub, sid = sys.argv[1:]
cfg = {
  "log": {"level": "warn"},
  "inbounds": [{
    "type": "mixed", "tag": "mixed-in",
    "listen": "127.0.0.1", "listen_port": 2080
  }],
  "outbounds": [
    {
      "type": "vless", "tag": "proxy",
      "server": server, "server_port": int(port),
      "uuid": uid, "flow": "xtls-rprx-vision",
      "network": "tcp",
      "tls": {
        "enabled": True, "server_name": sni,
        "utls": {"enabled": True, "fingerprint": "chrome"},
        "reality": {"enabled": True, "public_key": pub, "short_id": sid}
      }
    },
    {"type": "direct", "tag": "direct"}
  ],
  "route": {"final": "proxy", "auto_detect_interface": True}
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

# Common VLESS share link for clients that support VLESS + REALITY + Vision.
python3 - "$CLIENT_DIR/vless-reality-vision.txt" "$SERVER_DOMAIN" "$PORT" "$UUID" "$TARGET_HOST" "$PUBLIC_KEY" "$SHORT_ID" <<'PY'
import sys, urllib.parse
path, server, port, uid, sni, pub, sid = sys.argv[1:]
q = urllib.parse.urlencode({
  "encryption": "none", "security": "reality", "sni": sni,
  "fp": "chrome", "pbk": pub, "sid": sid,
  "type": "tcp", "flow": "xtls-rprx-vision", "spx": "/"
})
link = f"vless://{uid}@{server}:{port}?{q}#VLESS-REALITY-Vision"
with open(path, "w", encoding="utf-8") as f:
    f.write(link + "\n")
PY

chmod 0600 "$CLIENT_DIR"/*
echo
echo "===== 部署成功 ====="
echo "新服务：       $SERVICE"
echo "新端口：       TCP/$PORT"
echo "新协议：       VLESS + REALITY + Vision"
echo "伪装目标：     ${TARGET_HOST}:${TARGET_PORT}"
echo "旧服务：       xray-vision（未修改）"
echo "服务端配置：   $BASE/config.json"
echo "客户端目录：   $CLIENT_DIR"
echo
echo "节点分享链接："
cat "$CLIENT_DIR/vless-reality-vision.txt"
echo
echo "客户端文件："
ls -lh "$CLIENT_DIR"
echo
echo "防火墙：请在云厂商安全组及本机防火墙放行 TCP/$PORT。"
echo "UFW（如已启用）：ufw allow ${PORT}/tcp"
echo
echo "检查服务： systemctl status $SERVICE --no-pager"
echo "查看日志： journalctl -u $SERVICE -f"
echo "监听检查： ss -lntp | grep ':$PORT '"
echo "备份目录： $BACKUP"
echo
echo "注意：ML-KEM 是否协商成功取决于 REALITY target 的 TLS 能力；"
echo "脚本不会将 VLESS Encryption 强加到兼容性优先的通用节点上。"
