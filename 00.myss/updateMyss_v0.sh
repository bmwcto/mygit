### 本打算自己写，但后来发现 秋水 大佬写的一键安装是现成的轮子，就又偷懒了。

# 检查是否安装过 Shadowsocks-libev，未安装则下载最新版本，并远程拉取远程Git最新版本号

## 本地版本号
get_local_version_v1=$(ss-server -h|awk 'NR==2 {print $2}')

get_local_version_v2=$(ss-server -h | grep shadowsocks-libev | cut -d' ' -f2)

## 远程版本号
get_latest_version_v1=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed -e 's/^[a-zA-Z]//g')

get_latest_version_v2=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep -oP '(?<=tag_name": "v)[0-9]\d*.[0-9]\d*.[0-9]\d*(?=",)')

get_latest_version_v3=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep -oP '(?<=tag_name": "v)[^"]+(?=",)')

get_latest_version_v4=$(curl -L -s -H 'Accept: application/json' https://github.com/shadowsocks/shadowsocks-libev/releases/latest | cut -d\" -f6 | grep -oP '(?<=v)[^"]+')

get_latest_version_v5=$(curl -L -s -H 'Accept: application/json' https://github.com/shadowsocks/shadowsocks-libev/releases/latest | sed -e 's/.*"tag_name":"v\([^"]*\)".*/\1/')

## 检查本地安装

# 若未安装，就直接跳到安装最新版本
# 若已安装，就对比版本号，版本号不一致则安装最新版本，版本号一致则跳过安装，直接输出 log 为 SSlibev installed。

mkdir -p ~/build-area/
cp ./scripts/build_deb.sh ~/build-area/
cd ~/build-area
apt install -y sudo
./build_deb.sh