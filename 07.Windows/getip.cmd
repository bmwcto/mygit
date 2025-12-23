@echo off
setlocal enabledelayedexpansion
::: 
::: version:15:23 2025/12/23
::: 
::: 示例：%~n0 [h][/h][-h][help][/help][-help]
::: 显示帮助文件
for %%a in (h /h -h help /help -help "") do if /i "%~1"=="%%~a" goto help

::: 
::: 示例: %~n0 me
::: 查询当前公网出口IP及地理位置
if /i "%1" == "me" curl ip-api.com/line?lang=zh-CN&&exit /b

:: 判断是否进入 all 模式
if /i "%2" == "all" goto all

:: 判断是否进入 where 模式
if /i "%1" == "w" goto where

:: 检查进程是否存在 (核心新增内容)
tasklist /fi "imagename eq %1.exe" /nh 2>NUL | find /i "%1.exe" >NUL
if errorlevel 1 (
    echo 未找到进程 %1.exe
    exit /b
)
::: 
::: 示例: %~n0 chrome
::: 查询 chrome.exe 外连的所有公网连接 (带地理位置)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%1'; $ids=(Get-Process $p -ErrorAction SilentlyContinue).Id; $nets = netstat -ano | ForEach-Object { $c=$_.Trim() -split '\s+'; if($c.Length -ge 5 -and $c[4] -match '^\d+$' -and $ids -contains [int]$c[4]){ $remoteIP=($c[2] -split ':[0-9]+$')[0].Replace('[','').Replace(']',''); if($remoteIP -match '^\d' -and $remoteIP -notmatch '^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|0\.0\.0\.0)') { $_ } } }; if(-not $nets){ Write-Host \"$p.exe 无公网连接，无需查询。\" -Fore Yellow; exit }; Write-Host '正在查询公网连接 (带地理位置)...'; Write-Host '-------------------------------------------------------------------------------'; Write-Host '[协议]    [本地地址]          [远程地址]            [状态]       [地理位置]'; Write-Host '-------------------------------------------------------------------------------'; foreach($line in $nets){ $c=$line.Trim() -split '\s+'; $remoteIP=($c[2] -split ':[0-9]+$')[0].Replace('[','').Replace(']',''); try { $res=Invoke-RestMethod -Uri \"http://ip-api.com/json/$($remoteIP)?lang=zh-CN\" -TimeoutSec 2; if($res.status -eq 'success'){ $geo='{0} {1} {2} [{3}]' -f $res.country, $res.regionName, $res.city, $res.isp; }else{ $geo='[非公网IP]' } } catch { $geo='[查询失败]' }; $out='{0,-6} {1,-20} {2,-20} {3,-12} {4}' -f $c[0], $c[1], $c[2], $c[3], $geo; Write-Host $out; }; Write-Host '-------------------------------------------------------------------------------'; Write-Host '查询完毕。'"

echo -------------------------------------------------------------------------------
echo 过滤模式查询完毕。
exit /b
::: 
::: 示例: %~n0 chrome all
::: 正在显示 [%1.exe] 的所有原始连接 (含局域网)
:all
echo 正在显示 [%1.exe] 的所有原始连接 (含局域网)...
echo -------------------------------------------------------------------------------
for /f "tokens=2 delims=," %%i in ('tasklist /fi "imagename eq %1.exe" /fo csv ^| find /i "%1.exe"') do (
    netstat -ano | findstr %%i
)
echo -------------------------------------------------------------------------------
echo 当前 %1.exe 所有原始连接查询完毕。
exit /b
::: 
::: 示例: %~n0 w 1.1.1.1（查询1.1.1.1的地理位置）
::: 查询指定IP的地理位置
:where
curl http://ip-api.com/line/%2?lang=zh-CN
exit /b

:help
:: 特殊的 Escape 字符，在编辑器中，按 Alt + 27 (小键盘) 可以打出。如果直接复制粘贴可能失效
:: 定义绿色转义码 (Esc[92m)
set "green= [92m"
:: 定义恢复默认码 (Esc[0m)
set "reset= [0m"

for /f "tokens=1* delims= " %%i in ('findstr /b ":::" "%~f0"') do (
    set "msg=%%j"
    if "!msg!"=="" (
        echo.
    ) else (
        :: 仅对这一行输出绿色
        call echo %green%!msg!%reset%
    )
)
echo --------------------------------------
exit /b
