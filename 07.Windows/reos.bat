@echo off
rem 为便于远程维护从本地一次性启动PE创建的一个PE及驱动备份等操作的启动器程序
setlocal EnableDelayedExpansion
rem 使用代码页 65001
@chcp 65001 >nul
rem 使用 UTF-8 字符测试，如果处理失败就切换回默认代码页 936
set "t=■" & if "!t:~0,1!"=="" chcp 936 >nul

rem Get admin permissions.
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %Apply%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
title LC's REOS Tools 【9:21 2025/7/30】
if not defined terminal mode 78, 30
rem 系统版本检测
@ver | findstr /i "10.">nul || echo 系统版本过低，需 Windows 10 及以上&&pause&&exit

:menu
cls
setlocal enabledelayedexpansion
rem 定义变量
echo:
echo:
choice /C:CDEFQ /N /T 10 /D D /M 选择目标盘符(C、D、E、F)【10秒后默认D盘，按Q退出】
set _erl=%errorlevel%
if %_erl%==5 exit
if %_erl%==4 set "pe_PARTITION=F"
if %_erl%==3 set "pe_PARTITION=E"
if %_erl%==2 set "pe_PARTITION=D"
if %_erl%==1 set "pe_PARTITION=C"
if not exist %pe_PARTITION%:\ diskmgmt.msc
set "pe_path=reos"
set "pe_SDI=REPE.SDI"
set "pe_WIM=REPE64.wim"
set "pe_NAME=LCOS"

set "db_win_wim_url=http://0.0.0.0/REOS.WIN10"
set "z_wim_url=http://0.0.0.0/REPE.w64"
set "w_wim_url=http://1.1.1.1/REPE.w64"

set "sha1_x_SDI_file=e06e0fa5403ea1fe426ac782bc502574f1765c87"
set "sha1_x_wim_file=df9b9e93098ae4607b6670297f2f88dc949ed721"

set "wx_botkey=xxx"

set "SDI_file=%pe_PARTITION%:\%pe_path%\%pe_SDI%"
set "wim_file=%pe_PARTITION%:\%pe_path%\%pe_WIM%"

set "win_wim_file=%pe_PARTITION%:\%pe_path%\WIN.WIM"

if not exist %pe_PARTITION%:\ echo 目标盘符不存在，请重新选择或手动创建...&&timeout /t 5 >Nul&&goto menu
if not exist %pe_PARTITION%:\%pe_path% mkdir %pe_PARTITION%:\%pe_path%

:minimenu
cls&color 0a
echo ============================================================
echo 当前目标盘符：【%pe_PARTITION%】，请选择一个操作:
echo ============================================================
echo 	1. 备份全部驱动程序
echo 	2. 备份网络驱动程序
echo 	3. 启动Dism++
echo 	4. 启动到本地PE
echo 	5. 备份全部驱动程序并启动Dism++
echo 	6. 备份全部及网络驱动程序并启动到本地PE
echo 	E. 退出
echo 	A. Download-【%win_wim_file%】
echo 	0. 手动分区或检查分区
echo ============================================================
choice /C:123456ea0 /N /T 30 /D e /M 选择执行项目【30秒后默认退出】：
set _erl=%errorlevel%
if %_erl%==9 diskmgmt.msc
if %_erl%==8 if not exist %win_wim_file% curl -o %win_wim_file% %db_win_wim_url%&&goto minimenu
if %_erl%==7 exit
if %_erl%==6 goto AllAndExeWinPE
if %_erl%==5 goto AllAndExeDismPlusPlus
if %_erl%==4 goto ExeWinPE
if %_erl%==3 goto Exe_DismPlusPlus
if %_erl%==2 goto Exe_BackupNetDrivers
if %_erl%==1 goto Exe_BackupAllDrivers
goto minimenu

:Exe_BackupAllDrivers
call :BackupAllDrivers
goto minimenu

:Exe_BackupNetDrivers
call :BackupNetDrivers
goto minimenu

:Exe_DismPlusPlus
call :DismPlusPlus
goto minimenu

:AllAndExeDismPlusPlus
call :BackupAllDrivers
call :DismPlusPlus
goto minimenu

:AllAndExeWinPE
call :BackupAllDrivers
call :BackupNetDrivers
call :ExeWinPE

:BackupAllDrivers
rem 备份路径目录以当前硬件SN命名
rem Win11默认不带wmic，更换成powershell
rem for /f "skip=1 tokens=2 delims==" %%G in ('wmic csproduct get Name /value') do set "My_SN=%%G"
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(Get-CimInstance -ClassName Win32_ComputerSystemProduct).Name"`) do set "My_SN=%%i"
rem 如果pe_PARTITION盘或Soft路径下已有驱动目录，则跳过备份，否则先备份驱动程序到pe_PARTITION盘目录下
if not exist "%pe_PARTITION%:\%My_SN%" (
	if not exist "%pe_PARTITION%:\soft\%My_SN%" (
	mkdir "%pe_PARTITION%:\%My_SN%"
	echo.
	echo 正在备份导出驱动
	pnputil /export-driver * "%pe_PARTITION%:\%My_SN%"
	cls&&echo 驱动备份完毕...
	)
)  else (
echo 备份驱动的路径已存在...
echo 请检查【%pe_PARTITION%:\%My_SN%】或【%pe_PARTITION%:\soft\%My_SN%】&&timeout /t 5 >Nul
)
exit /b 1

:BackupNetDrivers
rem 导出网卡驱动到指定路径，便于PE启动后自动扫描并加载
set "NetDir=%pe_PARTITION%:\%pe_path%\Dr\NetDrivers_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%"
set "NetDir=%NetDir: =0%"
if not exist "%NetDir%" mkdir "%NetDir%"

echo.&echo 正在扫描网络适配器...
echo.
rem 循环获取 PCI 网卡的 InstanceId
for /f "delims=" %%I in ('powershell -Command "Get-PnpDevice -Class Net | Where-Object { $_.InstanceId -match '^PCI' } | ForEach-Object { $_.InstanceId }"') do (
	set "deviceid=%%I"

rem 获取对应 INF 文件名
	for /f "delims=" %%J in ('powershell -Command "Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceID -eq '!deviceid!' } | ForEach-Object { $_.InfName }"') do (
	echo 正在导出网卡驱动 %%J 到 【%NetDir%】
	pnputil /export-driver %%J "%NetDir%" >nul
	echo 已完成网卡驱动备份...&&timeout /t 5 >Nul
    )
)
exit /b 1

:Save_lc_bat
(
echo @echo off
echo title 如需继续操作PE，请手动关闭此窗口
echo setlocal enabledelayedexpansion
echo if not defined terminal mode 78, 30
echo ping -n 2 qyapi.weixin.qq.com^&^&curl -H "Content-Type: application/json" -X POST https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=%wx_botkey% -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[%%time%%]-[%%computername%%]-[Ready]\"}}"
echo color 0c
echo echo.
echo echo 【请手动关闭本脚本，如无操作，666秒后即自动重启】
echo echo.
echo choice /C:QR /N /T 600 /D R /M 【如需立刻重启请按R，否则请按Q退出】
echo set _erl=%%errorlevel%%
echo if %%_erl%%==2 shutdown /r /f /t 6
echo if %%_erl%%==1 exit
) > %pe_PARTITION%:\%pe_path%\lc.bat
exit /b 1

:DismPlusPlus
if exist "%pe_PARTITION%:\%pe_path%\Dism\Dism++x64.exe" start /wait %pe_PARTITION%:\%pe_path%\Dism\Dism++x64.exe
if not exist "%pe_PARTITION%:\%pe_path%\Dism\Dism++x64.exe" echo 没找到【Dism++】可执行文件...&&timeout /t 5 >Nul
exit /b 1

:DownWim
echo.
choice /C:wzpe /N /T 10 /D z /M 请选择PE关键文件下载地址(w、z、p、e)【10秒后默认z、按e退出】
set _erl=%errorlevel%
if %_erl%==4 exit
if %_erl%==3 set /p "DownUrl=手动输入示例（http://0.0.0.0/REPE.wim）："&&curl -k -o %wim_file% %DownUrl%
if %_erl%==2 curl -k -o %wim_file% %z_wim_url%
if %_erl%==1 curl -k -o %wim_file% %w_wim_url%
goto ExeWinPE

:ExeWinPE
if not exist %SDI_file% cls&color 0c&echo.&echo 未找到PE关键文件【%SDI_file%】..&timeout /t 2 >Nul&&goto minimenu
if not exist %wim_file% echo 未找到PE关键文件【%wim_file%】..&timeout /t 2 >Nul&&goto DownWim
call :Save_lc_bat
echo.
choice /C:YNE /N /T 10 /D N /M 请选择是否校验SHA1(Y、N、E)【10秒后默认N、按E退出】
set _erl=%errorlevel%
if %_erl%==3 exit
if %_erl%==2 goto ExeBCD
if %_erl%==1 echo.
for /f "skip=1 tokens=1,* delims= " %%a in ('certutil -hashfile "%SDI_file%" SHA1') do @if not defined SDI_fileSha1 set "SDI_fileSha1=%%a"
set "SDI_fileSha1=%SDI_fileSha1: =%"

for /f "skip=1 tokens=1,* delims= " %%a in ('certutil -hashfile "%wim_file%" SHA1') do @if not defined wim_fileSha1 set "wim_fileSha1=%%a"
set "wim_fileSha1=%wim_fileSha1: =%"

set "check_failed=0"

if /i not "%SDI_fileSha1%"=="%sha1_x_SDI_file%" (
    color 0c
    echo:
    echo 【!SDI_file!】文件校验不完整，请重新下载。
    echo 当前 SHA1：【%SDI_fileSha1%】
    echo 期望 SHA1：【%sha1_x_SDI_file%】
    set "check_failed=2"
)

if /i not "%wim_fileSha1%"=="%sha1_x_wim_file%" (
    color 0c
    echo:
    echo 【!wim_file!】文件校验不完整，请重新下载。
    echo 当前 SHA1：【%wim_fileSha1%】
    echo 期望 SHA1：【%sha1_x_wim_file%】
    set "check_failed=1"
)

if "%check_failed%"=="1" timeout /t 10&&goto DownWim
if "%check_failed%"=="2" timeout /t 10&&cls&&goto ExeWinPE
cls&&color 0A
echo:
echo 文件通过校验，准备启动PE。
timeout /t 5
goto ExeBCD

:ExeBCD
rem 尝试删除已存在的 {ramdiskoptions}
bcdedit /delete {ramdiskoptions} /f >nul 2>&1

rem 创建新的 ramdiskoptions 项
for /f "tokens=1-2 delims={}" %%a in ('bcdedit /create {ramdiskoptions} /d "%pe_NAME%"') do @set guid_ram={%%b}

rem 创建 osloader 项目
for /f "tokens=1-2 delims={}" %%a in ('bcdedit /create /d "%pe_NAME%" /application osloader') do @set guid_os={%%b}

rem 配置 osloader
bcdedit /set !guid_os! device ramdisk=[%pe_PARTITION%:]\%pe_path%\%pe_WIM%,!guid_ram!
bcdedit /set !guid_os! osdevice ramdisk=[%pe_PARTITION%:]\%pe_path%\%pe_WIM%,!guid_ram!
bcdedit /set !guid_os! path \windows\system32\boot\winload.efi
bcdedit /set !guid_os! systemroot \windows
bcdedit /set !guid_os! winpe yes
bcdedit /set !guid_os! detecthal yes

rem 配置 ramdiskoptions
bcdedit /set !guid_ram! ramdisksdidevice partition=%pe_PARTITION%:
bcdedit /set !guid_ram! ramdisksdipath \%pe_path%\%pe_SDI%

rem 设置一次性引导顺序和默认项
bcdedit /displayorder !guid_os! /addlast
bcdedit /bootsequence !guid_os! /addfirst
bcdedit /timeout 3
timeout /t 5&&cls&&msconfig -2&timeout /t 5&&cls
ipconfig
if exist "%pe_PARTITION%:\%My_SN%" explorer "%pe_PARTITION%:\%My_SN%"
if exist "%pe_PARTITION%:\soft\%My_SN%" explorer "%pe_PARTITION%:\soft\%My_SN%"
if exist "%NetDir%" explorer "%NetDir%"
color 0c&&echo.&&echo 【注意检查驱动备份，60秒后强行重启进入PE。】&&echo.&&timeout /t 60
PowerShell -Command "Restart-Computer -Force"
