@echo off
:::9:22 2025/6/20
:: 使用7z压缩备份目标禅道备份文件至SMB服务器并使用企业微信机器人进行结果通知，清除服务器上11天之前一周内的所有目录的旧文件
chcp 65001>nul
setlocal enabledelayedexpansion
if not exist 7za.exe echo 未找到7za程序，无法继续...&&pause&&exit
REM setbotapi
set "botapi=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx"

REM 获取开始时的Unix时间戳（以秒为单位，64位）
for /f "delims=" %%T in ('powershell -NoProfile -Command "[math]::Round((Get-Date).ToUniversalTime().Subtract((Get-Date '1970-01-01T00:00:00Z')).TotalSeconds, 0)"') do set "startEpoch=%%T"

REM 设置源目录
set sourceDir=E:\ZT_Run\xampp\zentao\tmp\backup

REM 设置目标压缩包目录
set destDir=E:\backup-7z

REM 创建目标目录（如果不存在）
if not exist "%destDir%" (
    mkdir "%destDir%"
)

REM 设置密码
set password=11001100

REM 设置临时文件列表路径
set fileList=%destDir%\today_files.txt
REM 设置日志文件路径
set logFile=%destDir%\backup_log.txt

REM 初始化临时文件列表和日志文件
echo. > %fileList%
rem echo. > %logFile%

REM 获取当前日期
for /f %%i in ('powershell -Command "Get-Date -Format yyyy-MM-dd"') do set today=%%i

REM 设置目标压缩包路径
set destArchive=%destDir%\ZT-backup-%today%.7z

REM 查找当天创建的 .php 文件
rem powershell -Command "Get-ChildItem -Path %sourceDir% -Recurse -File -Filter *.php | Where-Object { $_.CreationTime -ge [datetime]::Today } | Select-Object -ExpandProperty FullName">> %fileList%
powershell -Command "Get-ChildItem -Path '%sourceDir%' -Filter '*.php' | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date } | ForEach-Object { Write-Output $_.FullName }" >> %fileList%

REM 查找当天创建的文件夹
powershell -Command "Get-ChildItem -Path '%sourceDir%' | Where-Object { $_.PSIsContainer -and $_.CreationTime.Date -eq (Get-Date).Date } | ForEach-Object { Write-Output $_.FullName }">> %fileList%

REM 检查临时文件列表是否为空
for /f %%i in (%fileList%) do set found=1

if not defined found (
	echo %today%: 当日无文件需要备份 >> %logFile%
	echo 当日无文件需要备份
	rem
	curl -H "Content-Type: application/json" -X POST "!botapi!" -d "{""msgtype"": ""text"", ""text"": {""content"": ""文件备份-未找到需要备份的文件""}}" >nul
	timeout /t 2>nul
	set "okfile=E:\ZT_Run\xampp\zentao\www\ok.txt"
	if exist "!okfile!" del /q /f "!okfile!"
	if not exist "!okfile!" echo.>"!okfile!"
	curl -H "Content-Type: application/json" -X POST "!botapi!" -d "{""msgtype"": ""text"", ""text"": {""content"": ""文件备份-请检查文件后台""}}"
	endlocal
	rem pause
	exit /b
)

::: curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-开始压缩\"}}"

REM 压缩当天创建的文件和文件夹，并分卷压缩每卷大小为4GB
7za a -mx9 -r -t7z -v4g -p%password% %destArchive% @%fileList%

REM 删除临时文件列表
rem del %fileList%

echo %today%: 备份完成 >> %logFile%
echo Backup complete!
REM 获取结束时的Unix时间戳（以秒为单位）
for /f "delims=" %%C in ('powershell -NoProfile -Command "[math]::Round((Get-Date).ToUniversalTime().Subtract((Get-Date '1970-01-01T00:00:00Z')).TotalSeconds, 0)"') do set "C_Epoch=%%C"
set /a Compress_Epoch=C_Epoch-startEpoch
::: curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-压缩完成，耗时：!Compress_Epoch! 秒\"}}"

REM 获取当前日期
for /f %%i in ('powershell -Command "Get-Date -Format yyyy-MM-dd"') do set "today=%%i"

:: 备份至服务器
:: 要复制的文件匹配模式
set "SOURCE_FILES=ZT-backup-%today%.*"

:: 目标SMB共享路径
set "SMB_SHARE=\\192.168.1.1\Backup\zt"

:: 自动生成的日期目录(格式: YYYYMMDD)
set "TARGET_DIR=%today%"

:: SMB认证凭据
set "USERNAME=smbuser"
set "Spwd=smbpasswd"
:: 保存当前工作目录
set "CURRENT_DIR=%cd%"

:: 建立SMB连接并映射临时驱动器
net use "%SMB_SHARE%" /user:%USERNAME% %Spwd%
pushd %SMB_SHARE%

:: 在目标位置创建日期目录
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: 执行文件复制操作
::: curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-开始复制文件\"}}"
echo.
set "FILE_COUNT=0"
set "SIZE_COUNT=0"
for %%f in ("%CURRENT_DIR%\%SOURCE_FILES%") do (
    if exist "%%~f" (
	for /f "delims=" %%m in ('powershell -Command "(%%~zf / 1MB).ToString('0.00')"') do set "fsize=%%m"
	rem curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-开始复制文件[%%~nxf，!fsize! MB]\"}}"
	echo 当前文件[%%~nxf，!fsize! MB]
	copy "%%~f" "%TARGET_DIR%\" >nul
	rem robocopy "%CURRENT_DIR%" "%SMB_SHARE%\%TARGET_DIR%" "%%~nxf" /NJH /NJS /NC /NS /NP >nul
	set /a FILE_COUNT+=1
	rem 累加文件大小：调用PowerShell进行64位加法运算
	for /f "delims=" %%p in ('powershell -NoProfile -Command "[Int64]('!SIZE_BYTES!') + [Int64](%%~zf)"') do set "SIZE_BYTES=%%p"
	timeout /t 1 >nul
    )
)
:: 执行文件复制结束
::: curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-文件复制结束\"}}"
for /f "delims=" %%y in ('powershell -NoProfile -Command "('{0:N2}' -f ([convert]::ToDouble([Int64]('!SIZE_BYTES!')) / 1GB))"') do set "SIZE_COUNT=%%y"

::清除服务器上的旧文件，11天之前一周内的所有目录
for /f "usebackq delims=" %%d in (`powershell -NoLogo -NoProfile "for ($i=11; $i -le 17; $i++) { (Get-Date).AddDays(-$i).ToString('yyyy-MM-dd') }"`) do @if exist %%d rd /q /s %%d
::for /f %%k in ('powershell -Command "(Get-Date).AddDays(-11).ToString('yyyy-MM-dd')"') do set Clear_Server_Days=%%k
::echo 清除服务器上11天前的文件：!Clear_Server_Days!
::if exist !Clear_Server_Days! rd /q /s !Clear_Server_Days!
::: if not exist !Clear_Server_Days! curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-已清除服务器上[!Clear_Server_Days!]的文件\"}}"

:: 断开网络连接并清理
popd
REM 获取结束时的Unix时间戳（以秒为单位）
for /f "delims=" %%T in ('powershell -NoProfile -Command "[math]::Round((Get-Date).ToUniversalTime().Subtract((Get-Date '1970-01-01T00:00:00Z')).TotalSeconds, 0)"') do set "endEpoch=%%T"
echo 总计[!FILE_COUNT! 个文件，!SIZE_COUNT! GB]
set /a duration=endEpoch-startEpoch
curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-全部完成-总计[!FILE_COUNT! 个文件，!SIZE_COUNT! GB，耗时：!duration! 秒]\"}}"
echo.
echo 总耗时：!duration! 秒

net use * /delete /y >nul


::清除本地旧文件
for /f %%j in ('powershell -Command "(Get-Date).AddDays(-2).ToString('yyyy-MM-dd')"') do set Clear_Days=%%j
echo 清除本地2天前的文件：!Clear_Days!

:: 要清除的文件匹配模式
set "Clear_FILES=ZT-backup-%Clear_Days%.*"

for %%f in ("%CURRENT_DIR%\%Clear_FILES%") do (
    if exist "%%~f" (
	del /f /q "%%~f"
	timeout /t 1 >nul
    )
)
::: if not exist ZT-backup-%Clear_Days%.7z.001 curl -H "Content-Type: application/json" -X POST !botapi! -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"文件备份-已清理本地[%Clear_Days%]的旧文件\"}}"
endlocal

exit
