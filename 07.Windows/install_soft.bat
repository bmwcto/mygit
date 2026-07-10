@ECHO OFF
@echo Please wait, checking the system info......
rem AI修复过后的代码，未进行测试。

net.exe session 1>NUL 2>NUL || goto :EOF
set "mo_time=15:35 2026/7/10"
title checking the system info [%mo_time%]
setlocal enabledelayedexpansion

rem 不在oa内则直接退出
whoami | findstr /i /C:"oa" >nul 2>nul || goto :EOF

rem 软件安装升级排除特定用户
whoami | findstr /i /r "o.002 ruanjianbianyi" >nul 2>nul && set "YoN=1"

:::全局配置
SET "batver=V19"

rem 配置服务器地址
SET "s_ip=server.local"

:::清理DNS缓存
ipconfig/flushdns > nul

:::延迟5秒执行程序
ping -n 5 ::1 > nul

:::若Ping不通服务器，直接退出
ping -n 1 %s_ip% > nul || exit

:::加载服务器路径
pushd \\%s_ip%\it

:::调用安装脚本SoftName、newver、SoftPath、install_cmd
call :_Autoinstall "ShareX" "21.0.0.0" "D:\\soft\\ShareX\\ShareX.exe" "ShareX.sfx-v21.0.0.0.exe" "%YoN%"
call :_Autoinstall "WorkWeChat" "5.0.8.6009" "D:\\soft\\WorkWeChat\\WXWork.exe" "WeCom_5.0.8.6009.exe /S /D=D:\soft\WorkWeChat\" "%YoN%"

:::【已修复】主程序运行完毕后，执行策略更新并正常退出，防止遗漏代码或向下硬性坠落
call :Format_Time
echo [%FmTime%]-[%mo_time%] >C:\00.KB\test.log
gpupdate

popd
goto :EOF


:::升级或安装子程序
:_Autoinstall
ping -n 5 ::1 > nul
set "SoftName=%~1"&set "newver=%~2"&set "SoftPath=%~3"&set "install_cmd=%~4"&set "not_install=%~5"

if "%not_install%"=="1" (
    SET "logname=Not_install-%SoftName%"
    goto save-log
)

set "installver=0"
for /f "skip=2 tokens=2 delims=," %%i in ('wmic datafile where "Name='%SoftPath%'" get Version /format:csv 2^>nul') do set "installver=%%i"

::: 注意：若遇到跨主版本大更（如 9.x 变 10.x），建议在此处做特殊切分处理
if "%installver%"=="%newver%" (
    SET "logname=exist-%SoftName%"
    goto save-log
)

if "%installver%" LSS "%newver%" (
	start /wait exe/%install_cmd%
	for /f "skip=2 tokens=2 delims=," %%i in ('wmic datafile where "Name='%SoftPath%'" get Version /format:csv 2^>nul') do set "installver=%%i"
	SET "logname=installed-%SoftName%"
	goto save-log
) else (
	SET "logname=Newer-%SoftName%"
	goto save-log
)

:::保存日志
:save-log
call :Get-MAC-SN
call :Get_System_Ver
echo Checking and Don't close this window...
timeout /t 3 >nul
echo [%logname%]	[%installver%]	[%FmTime%]	[%computername%]	[%username%]	[%system_ver%]	[%ip%]	[%mac%]	[%sn%]>>logs\%system_ver%-%username%-%batver%.log
exit /b 0


:Save_IP-MAC-SN
call :Get-MAC-SN
echo [IP-MAC]	[%FmTime%]	[%computername%]	[%username%]	[%system_ver%]	[%ip%]	[%mac%]	[%sn%]>>logs\%system_ver%-%username%-%batver%.log
exit /b 0

:Get-MAC-SN
call :Format_Time
for /f tokens^=10^ delims^=^"^" %%a in ('wmic nicconfig get IPAddress^, DNSServerSearchOrder 2^>nul ^| findstr "65.9 8.228 8.1"') do (set "ip=%%~a")
for /f "tokens=5 delims= " %%b in ('wmic nicconfig get MACAddress^, DNSServerSearchOrder 2^>nul ^| findstr "65.9 8.228 8.1"') do (set "mac=%%~b")
for /f "skip=2 tokens=2,3 delims=," %%c in ('wmic csproduct get IdentifyingNumber^,Vendor /format:csv 2^>nul') do (set "sn=%%~c	%%~d")
exit /b 0

:Format_Time
for /f "tokens=1, 2, 3 delims=-/. " %%j in ('Date /T') do set "FmTime=%%j-%%k-%%l"
for /f "tokens=1, 2 delims=: " %%j in ('TIME /T') do set "FmTime=%FmTime%_%%j_%%k"
exit /b 0

:Get_System_Ver
for /f "tokens=2 delims=[]" %%A in ('ver') do for /f "tokens=2 delims= " %%Z in ("%%A") do set "system_ver=%%Z"
exit /b 0
