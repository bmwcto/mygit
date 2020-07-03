#!/usr/bin/env bash

## v6
## Fri Jul  4 04:50:06 CST 2020 
## bash <(wget --no-check-certificate -qO- 'https://git.io/JJkJ2')

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


### 卸载
xz_frps(){
    systemctl stop frps
    systemctl disable frps
    systemctl daemon-reload
    rm /usr/bin/frps
    rm /etc/frps/frps.ini
    rm /usr/lib/systemd/system/frps.service
    systemctl status frps
}

### 安装
az_frps(){
    frpcd=$(pwd)

    frpsfils=$(pwd)/frps

    mkdir -p /etc/frps/
    mkdir -p /var/log/frps/

    # 这里的-f 参数判断 $frpsfils 是否存在，若不存在就下载一个64位的最新版本
    if [ ! -f "$frpsfils" ]; then
        ## get last version frp with AMD64
        GetFrpLastVer=$(wget --no-check-certificate -qO- https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed -e 's/^[a-zA-Z]//g')
        wget https://github.com/fatedier/frp/releases/download/v${GetFrpLastVer}/frp_${GetFrpLastVer}_linux_amd64.tar.gz
        tar zxf frp_${GetFrpLastVer}_linux_amd64.tar.gz
        cp frp_${GetFrpLastVer}_linux_amd64/frps ${frpcd}/
    fi

    frpsini=$(pwd)/frps.ini
    if [ ! -f "$frpsini" ]; then
        wget https://git.io/JJkJF -O ${frpsini}
    fi

    frpsserver=$(pwd)/frps.service
    if [ ! -f "$frpsserver" ]; then
        wget https://git.io/JJkJQ -O ${frpsserver}
    fi

    systemctl stop frps
    systemctl daemon-reload
    rm /usr/bin/frps
    rm /etc/frps/frps.ini
    rm /usr/lib/systemd/system/frps.service
    ln -s ${frpcd}/frps /usr/bin/frps
    ln -s ${frpcd}/frps.ini /etc/frps/frps.ini
    cp ${frpcd}/frps.service /usr/lib/systemd/system/
    chmod a+x ${frpcd}/frps
    systemctl daemon-reload
    systemctl start frps
    systemctl enable frps
    systemctl status frps
}


action=$1
[ -z $1 ] && action=az
case "$action" in
    az|xz)
        ${action}_frps
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [az|xz]"
        ;;
esac