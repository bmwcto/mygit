# PowerShell 脚本 by LC at 21:57 2025/4/23
# 为了方便管理内部Windows，使用PowerShell写的一个命令行工具，慢慢扩展、完善
# 使用【Invoke-ps2exe .\myittools.ps1 -outputFile .\myittools.exe -title myit -description "LC's Tools" -company "LSMR" -version "0.0.0.5"】转换成exe，然后带参数使用

param (
    [string]$cmd,
    [string]$arg
)

$mo = "by LC at 14:11 2025/4/28"
$scriptName = [System.IO.Path]::GetFileName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "`n$mo`n" -ForegroundColor Yellow
        Write-Host "Please Use Administrator Permissions!" -ForegroundColor Red
        Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Pause
        Exit
    }
}

function Show-Help {
    Write-Host "`n$mo`n"
    Write-Host "Usage:"
    Write-Host "  $scriptName a|g|new7z|newworkwechat"
    Write-Host "  $scriptName remove outlook|rust"
    Write-Host "  $scriptName kill foxmail"
    Write-Host "  $scriptName update WorkWeChat|foxmail"
    Write-Host "  $scriptName addwifi localhost|guest"
    Write-Host "  $scriptName clearwifi localhost|guest"
}


function Download-And-Run {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [switch]$Install
    )

    $target = "$env:SystemRoot\it-help.exe"

    if (Test-Path $target) {
        $size = (Get-Item $target).Length
        $sizeMB = "{0:N2}" -f ($size / 1MB)
        Write-Host "目标文件已存在，大小：$sizeMB MB"
        $choice = Read-Host "是否直接运行现有文件？[Y/n]"

        if ($choice -eq "" -or $choice -match "^[Yy]") {
            Write-Host "`n运行程序..."
            if ($Install) {
                Start-Process $target -ArgumentList "/S"
            } else {
                Start-Process $target
            }
            return
        } else {
            Write-Host "`n重新下载文件中..."
        }
    }

    try {
        Write-Host "请稍后，正在下载...`n"
        Invoke-WebRequest -Uri $Url -OutFile $target -UseBasicParsing -ErrorAction Stop
        if (Test-Path $target) {
            Write-Host "下载完毕，运行程序...`n`n如有弹窗请点击【允许访问】即可..."
            if ($Install) {
                Start-Process $target -ArgumentList "/S"
            } else {
                Start-Process $target
            }
        }
    } catch {
        Write-Warning "下载失败，请检查你的网络..."
    }
}

function Remove-App($name) {
    switch ($name.ToLower()) {
        "outlook" {
            Get-AppxPackage -AllUsers -Name Microsoft.OutlookForWindows |
                ForEach-Object { Remove-AppxPackage -AllUsers -Package $_.PackageFullName }
        }
        "rust" {
            $exe = "C:\Program Files\RustDesk\rustdesk.exe"
            if (Test-Path $exe) {
                & $exe --uninstall > $null 2>&1
            }
        }
        default { Show-Help }
    }
}

function Kill-App($name) {
    switch ($name.ToLower()) {
        "foxmail" {
            Stop-Process -Name "FoxmailUpdateHook","foxmail" -Force -ErrorAction SilentlyContinue
        }
        default { Show-Help }
    }
}

function Update-App($name) {
    switch ($name.ToLower()) {
        "workwechat" {
            $file = "WeCom_4.1.36.6004.exe"
            $path = "D:\soft\其它软件\$file"
            if (-not (Test-Path $path)) {
                Write-Host "请检查企业微信 [$file] 是否存在" -ForegroundColor Red
                Pause
                return
            }
            Write-Host "正在升级企业微信 [$file]，请稍候...`n如有弹窗，请点[是]..." -ForegroundColor Cyan
            Start-Process $path -ArgumentList "/S /D=D:\soft\WorkWeChat\" -Wait
            Write-Host "`n升级/安装完毕..."
            $exe = "D:\soft\WorkWeChat\WXWork.exe"
            if (Test-Path $exe) { Start-Process $exe }
        }
        "foxmail" {
            $file = "Foxmail-v7.2.25.375.exe"
            $path = "D:\soft\其它软件\$file"
            if (-not (Test-Path $path)) {
                Write-Host "请检查 Foxmail [$file] 是否存在" -ForegroundColor Red
                Pause
                return
            }
            Stop-Process -Name "foxmail" -Force -ErrorAction SilentlyContinue
            Write-Host "正在升级 Foxmail [$file]，请稍候...`n如有弹窗，请点[是]..." -ForegroundColor Cyan
            Start-Process $path -Wait
        }
        default { Show-Help }
    }
}

function Add-And-ConnectWiFi {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SSID,
        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    $ProfileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

    $ProfilePath = "$env:TEMP\$SSID.xml"
    $ProfileXml | Out-File -Encoding UTF8 -FilePath $ProfilePath

    netsh wlan add profile filename="$ProfilePath" | Out-Null
    netsh wlan connect name="$SSID" | Out-Null

    Remove-Item $ProfilePath -Force
    Write-Host "已连接到 Wi-Fi：$SSID"
}

function Remove-WiFiProfile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SSID
    )
    netsh wlan delete profile name="$SSID" | Out-Null
    Write-Host "已删除配置文件：$SSID"
}

# 连接指定WIFI
function Add-WiFi($name) {
    switch ($name.ToLower()) {
        "localhost" {
            Add-And-ConnectWiFi -SSID "localhost" -Password "localhostPASS"
        }
        "guest" {
            Add-And-ConnectWiFi -SSID "localhost_Guest" -Password "GuestPASS"
        }
        default { Show-Help }
    }
}

# 清除指定WIFI
function Clear-WiFi($name) {
    switch ($name.ToLower()) {
        "localhost" {
                Remove-WiFiProfile -SSID "localhost"
        }
        "guest" {
                Remove-WiFiProfile -SSID "localhost_Guest"
         }
        default { Show-Help }
    }
}

# ========== 主逻辑入口 ==========
# Write-Host "`n$mo`n"
# https://work.weixin.qq.com/wework_admin/commdownload?platform=win
Ensure-Admin

switch ($cmd.ToLower()) {
    "a" {
        if (Test-Connection -Count 2 -Quiet -ComputerName "dl.anyviewer.com") {
            Download-And-Run -Url "https://dl.anyviewer.com/noinstall/AnyViewer.exe"
        }
    }
    "g" {
        if (Test-Connection -Count 2 -Quiet -ComputerName "db.localhost.cn") {
            Download-And-Run -Url "http://db.localhost.cn/myit/it-help.md"
        }
    }
    "new7z" {
        if (Test-Connection -Count 2 -Quiet -ComputerName "api.github.com") {
            # 获取最新版本的发布信息
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/ip7z/7zip/releases/latest'
            # 从发布的资产中查找 x64 的 .exe 安装程序
            $asset = $release.assets | Where-Object { $_.name -match 'x64\.exe$' } | Select-Object -First 1
            # 获取下载链接
            $7zdownloadUrl = $asset.browser_download_url
            # 输出下载链接
            Write-Output "最新版本的7z：$7zdownloadUrl"
            Download-And-Run -Url "https://ghcy.eu.org/$7zdownloadUrl" -Install
        }
    }
    "newworkwechat" {
        if (Test-Connection -Count 2 -Quiet -ComputerName "work.weixin.qq.com") {
            Download-And-Run -Url "https://work.weixin.qq.com/wework_admin/commdownload?platform=win" -Install
        }
    }
    "remove" {
        if ($arg) { Remove-App $arg } else { Show-Help }
    }
    "kill" {
        if ($arg) { Kill-App $arg } else { Show-Help }
    }
    "update" {
        if ($arg) { Update-App $arg } else { Show-Help }
    }
    "addwifi" {
        if ($arg) { Add-WiFi $arg } else { Show-Help }
    }
    "clearwifi" {
        if ($arg) { Clear-WiFi $arg } else { Show-Help }
    }
    default { Show-Help }
}
