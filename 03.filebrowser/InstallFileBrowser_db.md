## Linux [文件管理器](https://filebrowser.org/installation)

### 安装：
`curl -fsSL https://filebrowser.org/get.sh | bash`

### 配置：

- 建立相关目录
	```
	mkdir -p /home/fbro/upload
	mkdir -p /home/fbro/config
	```
- 进一步配置生成数据库
	```
	cd /home/fbro/config

	filebrowser config init --locale "zh-cn" --commands "cat ls pwd cp vim wget curl mkdir free du df fdisk uptime uname mv tar unzip apt date last lastb head tail grep git" --branding.name "BMWCTO" -a 0.0.0.0 -p 7890 -r /home/fbro/upload -l /home/fbro/config/fbro.log --perm.admin

	filebrowser users add myadmin mypassword --locale "zh-cn" --perm.admin
	```
	
	`说明：进入 config 目录后；配置默认为 中文，允许执行 cat 等shell，改网站显示名为 BMWCTO ，监听地址为 0.0.0.0，端口为 7890，主目录为 upload，日志路径为 fbro.log，用户为管理员权限；添加用户名为 myadmin 密码为 mypassword 的 中文 管理员 用户；并在 config 目录生成了 filebrowser.db 数据库。`

	`.*` 表示可执行[所有SHELL命令](https://github.com/filebrowser/filebrowser/issues/654)，但对SHELL的支持度不够高。
- 临时运行：`filebrowser -d /home/fbro/config/filebrowser.db`

### 开机服务：
`vim /usr/lib/systemd/system/fbro.service`

```
[Unit]
Description=filebrowser Server Service
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/filebrowser -d /home/fbro/config/filebrowser.db

[Install]
WantedBy=multi-user.target
```

#### 服务相关：

```
systemctl daemon-reload
systemctl start fbro
systemctl enable fbro
systemctl status fbro
```

#### 附录 get.sh

```
#!/usr/bin/env bash
#
#           File Browser Installer Script
#
#   GitHub: https://github.com/filebrowser/filebrowser
#   Issues: https://github.com/filebrowser/filebrowser/issues
#   Requires: bash, mv, rm, tr, type, grep, sed, curl/wget, tar (or unzip on OSX and Windows)
#
#   This script installs File Browser to your path.
#   Usage:
#
#   	$ curl -fsSL https://filebrowser.xyz/get.sh | bash
#   	  or
#   	$ wget -qO- https://filebrowser.xyz/get.sh | bash
#
#   In automated environments, you may want to run as root.
#   If using curl, we recommend using the -fsSL flags.
#
#   This should work on Mac, Linux, and BSD systems, and
#   hopefully Windows with Cygwin. Please open an issue if
#   you notice any bugs.
#

install_filemanager()
{
	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; return 1' ERR
	filemanager_os="unsupported"
	filemanager_arch="unknown"
	install_path="/usr/local/bin"

	# Termux on Android has $PREFIX set which already ends with /usr
	if [[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]]; then
		install_path="$PREFIX/bin"
	fi

	# Fall back to /usr/bin if necessary
	if [[ ! -d $install_path ]]; then
		install_path="/usr/bin"
	fi

	# Not every platform has or needs sudo (https://termux.com/linux.html)
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	#########################
	# Which OS and version? #
	#########################

	filemanager_bin="filebrowser"
	filemanager_dl_ext=".tar.gz"

	# NOTE: `uname -m` is more accurate and universal than `arch`
	# See https://en.wikipedia.org/wiki/Uname
	unamem="$(uname -m)"
	case $unamem in
	*aarch64*)
		filemanager_arch="arm64";;
	*64*)
		filemanager_arch="amd64";;
	*86*)
		filemanager_arch="386";;
	*armv5*)
		filemanager_arch="armv5";;
	*armv6*)
		filemanager_arch="armv6";;
	*armv7*)
		filemanager_arch="armv7";;
	*)
		echo "Aborted, unsupported or unknown architecture: $unamem"
		return 2
		;;
	esac

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ $unameu == *DARWIN* ]]; then
		filemanager_os="darwin"
	elif [[ $unameu == *LINUX* ]]; then
		filemanager_os="linux"
	elif [[ $unameu == *FREEBSD* ]]; then
		filemanager_os="freebsd"
	elif [[ $unameu == *NETBSD* ]]; then
		filemanager_os="netbsd"
	elif [[ $unameu == *OPENBSD* ]]; then
		filemanager_os="openbsd"
	elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
		# Should catch cygwin
		sudo_cmd=""
		filemanager_os="windows"
		filemanager_bin="filebrowser.exe"
		filemanager_dl_ext=".zip"
	else
		echo "Aborted, unsupported or unknown OS: $uname"
		return 6
	fi

	########################
	# Download and extract #
	########################

	echo "Downloading File Browser for $filemanager_os/$filemanager_arch..."
	filemanager_file="${filemanager_os}-$filemanager_arch-filebrowser$filemanager_dl_ext"
	filemanager_tag="$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')"
	filemanager_url="https://github.com/filebrowser/filebrowser/releases/download/$filemanager_tag/$filemanager_file"
	echo "$filemanager_url"

	# Use $PREFIX for compatibility with Termux on Android
	rm -rf "$PREFIX/tmp/$filemanager_file"

	if type -p curl >/dev/null 2>&1; then
		curl -fsSL "$filemanager_url" -o "$PREFIX/tmp/$filemanager_file"
	elif type -p wget >/dev/null 2>&1; then
		wget --quiet "$filemanager_url" -O "$PREFIX/tmp/$filemanager_file"
	else
		echo "Aborted, could not find curl or wget"
		return 7
	fi

	echo "Extracting..."
	case "$filemanager_file" in
		*.zip)    unzip -o "$PREFIX/tmp/$filemanager_file" "$filemanager_bin" -d "$PREFIX/tmp/" ;;
		*.tar.gz) tar -xzf "$PREFIX/tmp/$filemanager_file" -C "$PREFIX/tmp/" "$filemanager_bin" ;;
	esac
	chmod +x "$PREFIX/tmp/$filemanager_bin"

	echo "Putting filemanager in $install_path (may require password)"
	$sudo_cmd mv "$PREFIX/tmp/$filemanager_bin" "$install_path/$filemanager_bin"
	if setcap_cmd=$(PATH+=$PATH:/sbin type -p setcap); then
		$sudo_cmd $setcap_cmd cap_net_bind_service=+ep "$install_path/$filemanager_bin"
	fi
	$sudo_cmd rm -- "$PREFIX/tmp/$filemanager_file"

	if type -p $filemanager_bin >/dev/null 2>&1; then
		echo "Successfully installed"
		trap ERR
		return 0
	else
		echo "Something went wrong, File Browser is not in your path"
		trap ERR
		return 1
	fi
}

install_filemanager
```