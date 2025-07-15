# PowerShell 脚本 by LC at 07:57 2025/7/7
# 为了方便管理内部Windows软件使用及安装更新，使用PowerShell写的一个命令行下载安装工具
# Invoke-ps2exe .\DownAndRunSoft-v0.0.0.1.ps1 -outputFile .\DownAndRunSoft.exe -title DownAndRunSoft -description "LC's DownAndRunSoft" -company "LSMR" -version "0.0.0.1"
# DownAndRunSoft.exe -extract:D:\DownAndRunSoft.ps1

# 确保以管理员权限运行
#if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
#        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
#    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#    exit
#}

# 设置输出编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$mo = "Download Tools by LC at 17:47 2025/07/15"

function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "`n$mo`n" -ForegroundColor Yellow
        Write-Host "Please Use Administrator Permissions!" -ForegroundColor Red
        Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        sleep 10
        Exit
    }
}
Ensure-Admin

$host.UI.RawUI.WindowTitle = "$mo"

$setup_path = "D:\myos\setup"

while (-not (Test-Path $setup_path)) {
    if (-not (Test-Path "D:\")) {
		Write-Host "`n未检测到D盘，启动磁盘管理器" -ForegroundColor Red
        Start-Process "diskmgmt.msc" -Wait
		# 调出磁盘管理后直接进入下一轮检测
        continue 
    }
    New-Item -Path $setup_path -ItemType Directory -Force | Out-Null
}

$extMap = @{
    ".x64" = ".exe"
    ".m64" = ".msi"
    ".k64" = ".key"
}

$files = @{
    a = "1-7z.x64"
    b = "rarreg.k64"
    c = "1-Winrar.x64"
    d = "1-EverythingToolbar.m64"
    e = "2-Kcodec.x64"
    f = "2-Est.x64"
    g = "1-Chrome.m64"
    h = "2-VIP.x64"
}

function Select-Server {
    #Write-Host "请选择下载服务器: w (192.168.2.2), e (192.168.3.3), p (手动输入)，q（退出）默认 z"
    while ($true) {
		clear
        Write-Host "`n准备就绪...`n请选择服务器或退出（w/e/p/q）:" -NoNewline
        $key = [System.Console]::ReadKey($true)
        switch ($key.KeyChar.ToString().ToLower()) {
            'q' { exit }
            'w' { Write-Host ' w'; return "192.168.2.2" }
            'e' { Write-Host ' e'; return "192.168.3.3" }
            'p' {
                Write-Host ' p'
                $ip = Read-Host "手动输入 IP"
                return $ip
            }
            "`r" {  # 回车默认 e
                Write-Host ''
                return "192.168.2.2"
            }
            default {
                clear
                Write-Host "`n无效输入，请输入 w, e, p 或回车默认"
            }
        }
    }
}

function Download-Files {
    param($url_ip)

    $down_url = "http://$url_ip/pe/setup"
    Write-Host "`n当前选择的服务器：$down_url`n"

    Write-Host @"
============================================================
	请选择一个操作:
============================================================

	a. 7-zip
	b. rarkey
	c. Winrar
	d. EverythingToolbar
	e. K-Lite_Codec_Pack_Full-VERYSILENT
	f. Est-932CDG-101-Auto
	g. GoogleChromeStandaloneEnterprise
	h. D-Soft-VIP
	all. ALL
	exit. 退出

============================================================
"@

    $choice = Read-Host "请输入要安装的文件代号（例如 abd 或 all 或 exit）"
    if ($choice.ToLower() -eq "exit" -or [string]::IsNullOrWhiteSpace($choice)) { exit }

    $selected = if ($choice.ToLower() -eq "all") {
        $files.Keys
    } else {
        ($choice.ToLower().ToCharArray() | ForEach-Object { "$_" }) | Where-Object { $files.ContainsKey($_) }
    }

    if (-not $selected) {
        Write-Host "没有匹配任何有效项目，请重试。" -ForegroundColor Yellow
        return
    }

    foreach ($key in $selected) {
        $fullname = $files[$key]
        $ext = [System.IO.Path]::GetExtension($fullname).ToLower()
        $name = [System.IO.Path]::GetFileNameWithoutExtension($fullname)

        if ($extMap.ContainsKey($ext)) {
            $target_ext = $extMap[$ext]
            $final_name = "$name$target_ext"
            $target_file = Join-Path $setup_path $final_name
            $source_url = "$down_url/$fullname"

            if (-not (Test-Path $target_file)) {
                Write-Host "正在下载 $fullname ..."
                try {
                    Invoke-WebRequest -Uri $source_url -OutFile $target_file -UseBasicParsing
                    Write-Host "下载完成：$final_name"
                } catch {
                    Write-Host "下载失败：$source_url" -ForegroundColor Red
                }
            } else {
                Write-Host "已存在：$final_name，跳过下载"
            }
        } else {
            Write-Host "未知扩展类型：$ext" -ForegroundColor Yellow
        }
    }

    Write-Host "`n正在安装..."

    Get-ChildItem -Path $setup_path -Filter "1-*.exe" | Sort-Object Name | ForEach-Object {
        Start-Process $_.FullName -ArgumentList "/S" -Wait
        Write-Host "Install: $($_.Name)"
    }

    Get-ChildItem -Path $setup_path -Filter "1-*.msi" | Sort-Object Name | ForEach-Object {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$($_.FullName)`" /qn /norestart" -Wait
        Write-Host "Install: $($_.Name)"
    }

    Get-ChildItem -Path $setup_path -Filter "2-*.exe" | Sort-Object Name | ForEach-Object {
        Start-Process $_.FullName -Wait
        Write-Host "Install: $($_.Name)"
    }

    Write-Host "`n安装完毕！`n10秒后返回主菜单..."
	sleep 10
}

# 🔁 主循环
while ($true) {
    $server = Select-Server
    Download-Files -url_ip $server
}
