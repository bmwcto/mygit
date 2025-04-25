:::本脚本用处如下：
:::在8-20点之间检查远端网络IP状态，每305秒检测一次，如果掉线或恢复，会使用bot发送状态信息
:::注意修改bot的Key以及文件编码
:::by 0:24 2025/4/26
@echo off
@chcp 65001>nul
mode con lines=10 cols=100
setlocal enabledelayedexpansion

:: 配置
set "IP_LIST=192.168.1.1 1.1.1.1 2.2.2.2"
title 检测【%IP_LIST%】状态
:: 状态文件保存目录
set "STATUS_DIR=status"
set INTERVAL=300

if not exist %STATUS_DIR% mkdir %STATUS_DIR%
:loop1
for /f "tokens=1-3 delims=:." %%a in ('powershell -command "Get-Date -Format 'HH:mm:ss.fff'"') do set nowhh=%%a
:: 去除可能的前导零（避免08被误认为八进制）
set /a nowhh=!nowhh!
cls&echo.
echo 当前[!nowhh!]执行loop1，%time%
timeout /t 5 >nul
:loop2
:: 判断时间是否在8-20点之外，如果需要全天检测，注释下面两行即可
if !nowhh! lss 8 goto loop1
if !nowhh! geq 20 goto loop1

echo 执行loop2，%time%
for %%I in (%IP_LIST%) do (
    set "IP=%%I"
    set "CUR_STATUS_FILE=%STATUS_DIR%\%%I.cur"
    set "LAST_STATUS_FILE=%STATUS_DIR%\%%I.last"

    :: 检测当前状态
    ping -n 1 !IP! | findstr "TTL=" >nul
    if !errorlevel! == 0 (
        echo online > "!CUR_STATUS_FILE!"
    ) else (
        echo offline > "!CUR_STATUS_FILE!"
    )

    :: 如果没有上次状态文件，初始化为 unknown
    if not exist "!LAST_STATUS_FILE!" (
        echo unknown > "!LAST_STATUS_FILE!"
    )

    :: 读取当前和上次状态
    set /p CUR=<"!CUR_STATUS_FILE!"
    set /p LAST=<"!LAST_STATUS_FILE!"

    :: 状态变化则上报
    if /i not "!CUR!"=="!LAST!" (
        echo %time%-!IP! 状态变化：!LAST! -> !CUR!

        :: 替换下面地址为你的服务端地址
        curl -H "Content-Type: application/json" -X POST https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[%time%]-[!ip!]-[!CUR!]\"}}"
	cls&echo.&&echo 每【%INTERVAL%】秒检测一次状态
        :: 更新状态文件
        copy /Y "!CUR_STATUS_FILE!" "!LAST_STATUS_FILE!" >nul
    ) else (
        echo %time%-!IP! 状态未变化：!CUR!
    )

    :: 清理当前状态文件
    del "!CUR_STATUS_FILE!"
)

:: 等待一段时间后继续循环
timeout /t %INTERVAL% /nobreak >nul
cls&echo.
goto loop1
