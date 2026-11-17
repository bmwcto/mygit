
#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Xray VLESS TCP XTLS Vision 一键部署
# 独立服务：xray-vision
# 不覆盖现有 xray / xray-ui
# bash -c "$(curl -L https://github.com/bmwcto/mygit/raw/refs/heads/master/00.myss/install-xray-vision.sh)"
# sudo bash -c "$(curl -x http://127.0.0.1:7891 -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --proxy socks5://127.0.0.1:7890
# bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
# ============================================================

# ---------- 可修改变量 ----------
DOMAIN=""
EMAIL=""

XRAY_PORT="443"
HTTP_PORT="80"
FALLBACK_HTTP="8001"
FALLBACK_H2="8002"

BASE="/etc/xray-vision"
WEB_ROOT="/var/www/xray-vision"
NGINX_CONF="/etc/nginx/conf.d/xray-vision.conf"

# ---------- 基础函数 ----------
log() {
    echo
    echo "[$(date '+%F %T')] $*"
}

fail() {
    echo
    echo "[错误] $*" >&2
    exit 1
}

backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$file" "$BACKUP_DIR/"
        log "已备份：$file"
    fi
}

# ---------- 权限检查 ----------
[[ "$EUID" -eq 0 ]] || fail "请使用 root 运行此脚本"

[[ -f /etc/debian_version ]] || fail "此脚本仅适用于 Debian"

# ---------- 参数输入 ----------
if [[ -z "$DOMAIN" ]]; then
    read -rp "请输入域名，例如 a.example.com： " DOMAIN
fi

if [[ -z "$EMAIL" ]]; then
    read -rp "请输入 Certbot 注册邮箱： " EMAIL
fi

[[ -n "$DOMAIN" ]] || fail "域名不能为空"
[[ -n "$EMAIL" ]] || fail "邮箱不能为空"

DOMAIN="${DOMAIN,,}"

if [[ ! "$DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]]; then
    fail "域名格式不正确"
fi

if [[ ! "$EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
    fail "邮箱格式不正确"
fi

echo
echo "========== 部署参数 =========="
echo "域名：$DOMAIN"
echo "邮箱：$EMAIL"
echo "服务端口：$XRAY_PORT"
echo "HTTP 回落：$FALLBACK_HTTP"
echo "HTTP/2 回落：$FALLBACK_H2"
echo "=============================="
echo

read -rp "确认开始部署？(y/N)： " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0

BACKUP_DIR="/root/xray-vision-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# ---------- 检查 Xray ----------
log "检查现有 Xray"

XRAY_BIN="$(command -v xray || true)"
[[ -n "$XRAY_BIN" && -x "$XRAY_BIN" ]] || \
    fail "未找到 Xray 可执行文件。请先安装 Xray，再运行本脚本"

XRAY_VERSION="$("$XRAY_BIN" version | sed -n '1p')"
echo "$XRAY_VERSION"

# ---------- 检查 GeoIP ----------
log "查找 GeoIP 数据文件"

GEOIP_FILE=""

for file in \
    /usr/local/share/xray/geoip.dat \
    /usr/local/share/v2ray/geoip.dat \
    /usr/local/xray-ui/bin/geoip.dat \
    /usr/share/xray/geoip.dat
do
    if [[ -s "$file" ]]; then
        GEOIP_FILE="$file"
        break
    fi
done

[[ -n "$GEOIP_FILE" ]] || fail "未找到 geoip.dat"

ASSET_DIR="$(dirname "$GEOIP_FILE")"
echo "GeoIP：$GEOIP_FILE"
echo "Asset：$ASSET_DIR"

# ---------- 检查端口 ----------
log "检查端口占用"

if ss -lntH '( sport = :443 )' | grep -q .; then
    if ! systemctl is-active --quiet xray-vision; then
        fail "TCP 443 已被其他服务占用，请先检查"
    fi
fi

# ---------- 安装依赖 ----------
log "检查并安装 Nginx、Certbot"

PACKAGES=()

for package in nginx certbot; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        PACKAGES+=("$package")
    fi
done

if ((${#PACKAGES[@]})); then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"
fi

systemctl enable nginx
systemctl start nginx

# ---------- 创建网站目录 ----------
log "创建网站目录"

mkdir -p "$WEB_ROOT/.well-known/acme-challenge"

cat > "$WEB_ROOT/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Welcome</title>
<style>
body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f5f5f5;
    color: #333;
    font-family: Arial, sans-serif;
}
main {
    text-align: center;
    padding: 40px;
}
h1 {
    font-size: 28px;
    font-weight: 500;
}
p {
    color: #888;
}
</style>
</head>
<body>
<main>
<h1>Welcome</h1>
<p>$DOMAIN</p>
</main>
</body>
</html>
HTML

# ---------- Nginx 配置 ----------
log "生成 Nginx 配置"

backup_file "$NGINX_CONF"

cat > "$NGINX_CONF" <<NGINX
server {
    listen 80;
    server_name $DOMAIN;

    root $WEB_ROOT;
    index index.html;

    location ^~ /.well-known/acme-challenge/ {
        default_type text/plain;
        try_files \$uri =404;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 127.0.0.1:$FALLBACK_HTTP proxy_protocol;
    listen 127.0.0.1:$FALLBACK_H2 http2 proxy_protocol;

    server_name $DOMAIN;
    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX

nginx -t || fail "Nginx 配置检查失败"
systemctl reload nginx

# ---------- 申请证书 ----------
log "申请 Let's Encrypt 证书"

certbot certonly \
    --webroot \
    -w "$WEB_ROOT" \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive \
    --keep-until-expiring

CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

[[ -s "$CERT" && -s "$KEY" ]] || fail "证书申请失败"

# ---------- 生成 UUID ----------
log "生成客户端 UUID"

UUID="$("$XRAY_BIN" uuid)"
[[ -n "$UUID" ]] || fail "UUID 生成失败"

# ---------- 生成 Xray 配置 ----------
log "生成 Xray Vision 配置"

mkdir -p "$BASE"
chmod 700 "$BASE"

backup_file "$BASE/config.json"

cat > "$BASE/config.json" <<JSON
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray-vision/access.log",
    "error": "/var/log/xray-vision/error.log"
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "ip": [
          "geoip:cn"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $XRAY_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": "$FALLBACK_HTTP",
            "xver": 1
          },
          {
            "alpn": "h2",
            "dest": "$FALLBACK_H2",
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "rejectUnknownSni": true,
          "minVersion": "1.2",
          "alpn": [
            "h2",
            "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "$CERT",
              "keyFile": "$KEY"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "policy": {
    "levels": {
      "0": {
        "handshake": 2,
        "connIdle": 120
      }
    }
  }
}
JSON

# ---------- 创建日志目录 ----------
mkdir -p /var/log/xray-vision
chmod 750 /var/log/xray-vision

# ---------- 检查配置 ----------
log "检查 Xray 配置"

XRAY_LOCATION_ASSET="$ASSET_DIR" \
    "$XRAY_BIN" run -test -config "$BASE/config.json" \
    || fail "Xray 配置检查失败"

# ---------- 创建独立 systemd 服务 ----------
log "创建 xray-vision 服务"

SERVICE_FILE="/etc/systemd/system/xray-vision.service"

backup_file "$SERVICE_FILE"

cat > "$SERVICE_FILE" <<SERVICE
[Unit]
Description=Xray VLESS TCP XTLS Vision
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target nginx.service
Wants=network-online.target

[Service]
Type=simple
User=root
Environment=XRAY_LOCATION_ASSET=$ASSET_DIR
ExecStart=$XRAY_BIN run -config $BASE/config.json
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xray-vision
systemctl restart xray-vision

sleep 2

systemctl is-active --quiet xray-vision || {
    journalctl -u xray-vision -n 50 --no-pager
    fail "xray-vision 启动失败"
}

# ---------- Certbot 自动续期 Hook ----------
log "配置证书续期自动重启"

HOOK_DIR="/etc/letsencrypt/renewal-hooks/deploy"
HOOK_FILE="$HOOK_DIR/restart-xray-vision.sh"

mkdir -p "$HOOK_DIR"
backup_file "$HOOK_FILE"

cat > "$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
set -e

systemctl restart xray-vision
HOOK

chmod 750 "$HOOK_FILE"


# ---------- 生成客户端配置 ----------
log "生成客户端节点配置"

NODE_LINK="vless://${UUID}@${DOMAIN}:${XRAY_PORT}?encryption=none&security=tls&type=tcp&flow=xtls-rprx-vision&sni=${DOMAIN}&fp=chrome#XTLS-Vision"

printf '%s\n' "$NODE_LINK" > "$BASE/v2rayng-link.txt"
chmod 600 "$BASE/v2rayng-link.txt"

CLIENT_CONFIG="$BASE/linux-client.json"

cat > "$CLIENT_CONFIG" <<JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 10809,
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$DOMAIN",
            "port": $XRAY_PORT,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "serverName": "$DOMAIN",
          "fingerprint": "chrome",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        }
      },
      "tag": "proxy"
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
JSON

chmod 600 "$CLIENT_CONFIG"

# 检查客户端配置
log "检查 Linux 客户端配置"

XRAY_LOCATION_ASSET="$ASSET_DIR" \
    "$XRAY_BIN" run -test -config "$CLIENT_CONFIG" \
    || fail "Linux 客户端配置检查失败"


# ---------- 最终检查 ----------
log "执行最终检查"

systemctl is-active nginx
systemctl is-active xray-vision

echo
echo "===== 监听端口 ====="
ss -lntp | grep -E "(:443|:80|:$FALLBACK_HTTP|:$FALLBACK_H2)([[:space:]]|$)" || true

echo
echo "===== HTTPS 回落测试 ====="
curl -fsSI \
    --resolve "$DOMAIN:$XRAY_PORT:127.0.0.1" \
    "https://$DOMAIN/" || true

echo
echo "===== 证书续期模拟测试 ====="
certbot renew --dry-run

# ---------- 输出结果 ----------
echo
echo "=========================================="
echo "          Xray Vision 部署完成"
echo "=========================================="
echo
echo "域名：       $DOMAIN"
echo "端口：       $XRAY_PORT"
echo "协议：       VLESS TCP XTLS Vision"
echo "Flow：       xtls-rprx-vision"
echo "TLS：        Let's Encrypt"
echo "Fingerprint：chrome"
echo
echo "Xray 服务：  xray-vision"
echo "Nginx 服务： nginx"
echo
echo "配置文件：   $BASE/config.json"
echo "节点链接：   $BASE/v2rayng-link.txt"
echo "日志目录：   /var/log/xray-vision/"
echo "备份目录：   $BACKUP_DIR"
echo
echo "查看节点链接："
echo "cat $BASE/v2rayng-link.txt"
echo
echo "查看运行日志："
echo "journalctl -u xray-vision -f"
echo
echo "=========================================="
