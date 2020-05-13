#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================#
#   System Required:  Debian or Ubuntu                              #
#   Description: Install Shadowsocks-libev server for Debian/Ubuntu #
#   Author: Teddysun <i@teddysun.com>                               #
#   Thanks: @madeye <https://github.com/madeye>                     #
#   Intro:  https://teddysun.com/358.html                           #
#===================================================================#

# Current folder
cur_dir=`pwd`

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1


get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

get_latest_version(){
    ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z ${ver} ] && echo "Error: Get shadowsocks-libev latest version failed" && exit 1
    shadowsocks_libev_ver="shadowsocks-libev-$(echo ${ver} | sed -e 's/^[a-zA-Z]//g')"
    download_link="https://github.com/shadowsocks/shadowsocks-libev/releases/download/${ver}/${shadowsocks_libev_ver}.tar.gz"
}

get_opsy(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

check_installed(){
    if [ "$(command -v "$1")" ]; then
        return 0
    else
        return 1
    fi
}

check_version(){
    check_installed "ss-server"
    if [ $? -eq 0 ]; then
        installed_ver=$(ss-server -h | grep shadowsocks-libev | cut -d' ' -f2)
        get_latest_version
        latest_ver=$(echo ${ver} | sed -e 's/^[a-zA-Z]//g')
        if [ "${latest_ver}" == "${installed_ver}" ]; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

print_info(){
    clear
    echo "#############################################################"
    echo "# Install Shadowsocks-libev server for Debian or Ubuntu     #"
    echo "# Intro:  https://teddysun.com/358.html                     #"
    echo "# Author: Teddysun <i@teddysun.com>                         #"
    echo "# Github: https://github.com/shadowsocks/shadowsocks-libev  #"
    echo "#############################################################"
    echo
}

# Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

version_gt(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

check_kernel_version(){
    local kernel_version=$(uname -r | cut -d- -f1)
    if version_gt ${kernel_version} 3.7.0; then
        return 0
    else
        return 1
    fi
}

check_kernel_headers(){
    if check_sys packageManager yum; then
        if rpm -qa | grep -q headers-$(uname -r); then
            return 0
        else
            return 1
        fi
    elif check_sys packageManager apt; then
        if dpkg -s linux-headers-$(uname -r) > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
    return 1
}

debianversion(){
    if check_sys sysRelease debian;then
        local version=$( get_opsy )
        local code=${1}
        local main_ver=$( echo ${version} | sed 's/[^0-9]//g')
        if [ "${main_ver}" == "${code}" ];then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Pre-installation settings
pre_install(){
    # Check OS system
    if ! check_sys packageManager apt; then
        echo -e "[${red}Error${plain}] Your OS is not supported to run it, please change OS to Debian/Ubuntu and try again."
        exit 1
    fi

    # Check version
    check_version
    status=$?
    if [ ${status} -eq 0 ]; then
        echo -e "[${green}Info${plain}] Latest version ${green}${shadowsocks_libev_ver}${plain} has already been installed, nothing to do..."
        exit 0
    elif [ ${status} -eq 1 ]; then
        echo -e "Installed version: ${red}${installed_ver}${plain}"
        echo -e "Latest version: ${red}${latest_ver}${plain}"
        echo -e "[${green}Info${plain}] Upgrade shadowsocks libev to latest version..."
        ps -ef | grep -v grep | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            systemctl stop myss
        fi
    elif [ ${status} -eq 2 ]; then
        print_info
        get_latest_version
        echo -e "[${green}Info${plain}] Latest version: ${green}${shadowsocks_libev_ver}${plain}"
        echo
    fi

    # Update System
    apt-get -y update
    # Install necessary dependencies
    apt-get -y --no-install-recommends install gettext build-essential autoconf automake libtool openssl libssl-dev zlib1g-dev libpcre3-dev libev-dev libc-ares-dev
}

download() {
    local filename=${1}
    local cur_dir=`pwd`
    if [ -s ${filename} ]; then
        echo -e "[${green}Info${plain}] ${filename} [found]"
    else
        echo -e "[${green}Info${plain}] ${filename} not found, download now..."
        wget --no-check-certificate -cq -t3 -T60 -O ${1} ${2}
        if [ $? -eq 0 ]; then
            echo -e "[${green}Info${plain}] ${filename} download completed..."
        else
            echo -e "[${red}Error${plain}] Failed to download ${filename}, please download it to ${cur_dir} directory manually and try again."
            exit 1
        fi
    fi
}

# Download latest shadowsocks-libev
download_files(){
    cd ${cur_dir}

    download "${shadowsocks_libev_ver}.tar.gz" "${download_link}"
##    download "${libsodium_file}.tar.gz" "${libsodium_url}"
##    download "${mbedtls_file}-gpl.tgz" "${mbedtls_url}"
}

install_libsodium() {
    if [ ! -f /usr/lib/libsodium.a ]; then
        cd ${cur_dir}
        tar zxf ${libsodium_file}.tar.gz
        cd ${libsodium_file}
        ./configure --prefix=/usr && make && make install
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] ${libsodium_file} install failed."
            exit 1
        fi
    else
        echo -e "[${green}Info${plain}] ${libsodium_file} already installed."
    fi
}

install_mbedtls() {
    if [ ! -f /usr/lib/libmbedtls.a ]; then
        cd ${cur_dir}
        tar xf ${mbedtls_file}-gpl.tgz
        cd ${mbedtls_file}
        make SHARED=1 CFLAGS=-fPIC
        make DESTDIR=/usr install
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] ${mbedtls_file} install failed."
            exit 1
        fi
    else
        echo -e "[${green}Info${plain}] ${mbedtls_file} already installed."
    fi
}


# Install Shadowsocks-libev
install_shadowsocks(){
    ##install_libsodium
    ##install_mbedtls

    ldconfig
    cd ${cur_dir}
    tar zxf ${shadowsocks_libev_ver}.tar.gz
    cd ${shadowsocks_libev_ver}
    ./configure --disable-documentation
    make && make install
    rm /usr/bin/ss-server
    rm /usr/bin/ss-local
    ln -s /usr/local/bin/ss-server /usr/bin/ss-server
    ln -s /usr/local/bin/ss-local /usr/bin/ss-local
    if [ $? -eq 0 ]; then
        ##chmod +x /etc/init.d/shadowsocks
        ##update-rc.d -f shadowsocks defaults
        # Start shadowsocks
        systemctl start myss
        if [ $? -eq 0 ]; then
            echo -e "[${green}Info${plain}] Shadowsocks-libev start success!"
        else
            echo -e "[${yellow}Warning${plain}] Shadowsocks-libev start failure!"
        fi
    else
        echo
        echo -e "[${red}Error${plain}] Shadowsocks-libev install failed. please visit https://teddysun.com/358.html and contact."
        exit 1
    fi

    cd ${cur_dir}
    ##rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz

    clear
    echo
    echo -e "Congratulations, Shadowsocks-libev server install completed!"
    echo -e "Your Version        : \033[41;37m $(ss-server -h|awk 'NR==2 {print $2}') \033[0m"
    echo
    echo "Welcome to visit:https://teddysun.com/358.html"
    echo "Enjoy it!"
    echo
}

# Install Shadowsocks-libev
install_shadowsocks_libev(){
#    disable_selinux
    pre_install
    download_files
    install_shadowsocks
}

# Uninstall Shadowsocks-libev
uninstall_shadowsocks_libev(){
    clear
    print_info
    printf "Are you sure uninstall Shadowsocks-libev? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"

    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ps -ef | grep -v grep | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            systemctl start myss
        fi
        update-rc.d -f shadowsocks remove

        rm -fr /etc/shadowsocks-libev
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-manager
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/bin/ss-nat
        rm -f /usr/local/lib/libshadowsocks-libev.a
        rm -f /usr/local/lib/libshadowsocks-libev.la
        rm -f /usr/local/include/shadowsocks.h
        rm -f /usr/local/lib/pkgconfig/shadowsocks-libev.pc
        rm -f /usr/local/share/man/man1/ss-local.1
        rm -f /usr/local/share/man/man1/ss-tunnel.1
        rm -f /usr/local/share/man/man1/ss-server.1
        rm -f /usr/local/share/man/man1/ss-manager.1
        rm -f /usr/local/share/man/man1/ss-redir.1
        rm -f /usr/local/share/man/man1/ss-nat.1
        rm -f /usr/local/share/man/man8/shadowsocks-libev.8
        rm -fr /usr/local/share/doc/shadowsocks-libev
        ##rm -f /etc/init.d/shadowsocks
        echo "Shadowsocks-libev uninstall success!"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_shadowsocks_libev
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [install|uninstall]"
        ;;
esac

