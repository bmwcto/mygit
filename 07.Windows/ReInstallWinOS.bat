@echo off
setlocal enabledelayedexpansion
title ÆóÒµ¼¶È«×Ô¶¯ÏµÍ³ÖØ×°¼Ü¹¹
rem !!!¶à´ÅÅÌÊ±»áÒòPEµÄÊ¶±ðµ½µÄÅÌ·û²»Í¬¶øÎÞÐ§£¬ÐèÒªÊÖ¶¯µ÷ÕûÅÌ·û!!!
mode con lines=80 cols=100
:: 1. È«¾ÖÅäÖÃÇøÓò
set "PE_PARTITION=D"
set "PE_PATH=REOS"
set "PE_NAME=LCOS"
set "BACKUP_DR=mydr"
set "PE_WIM=REPE64.wim"
set "PE_SDI=REPE.sdi"
set "Win_WallPaper=img0.jpg"

set "botkey=xxxxxxxx"
set "disk_folder=xxxx"
set "http_url=down.local"
set "http_path=http://%http_url%/reos"

:: ¾µÏñ²¿ÊðÅäÖÃ
set "ESD_NAME=19044_20260611_1550.esd"
set "ESD_INDEX=1"

rem loT LTSC2021 Key
set "PRODUCT_KEY=KBN8V-HFGQ4-MGXVD-347P6-PDQGT"

:: Â·¾¶¿ì½Ý±äÁ¿
set "TARGET_DIR=%PE_PARTITION%:\%PE_PATH%"
set "DRV_BACKUP_PATH=%TARGET_DIR%\%BACKUP_DR%"

:: ¼ì²éÈç¹ûÊÇ´Ó PE »·¾³ÖÐ±»»½ÐÑ
if "%~1"=="_PE_STAGE_" goto :PE_DEPLOY_STAGE
reg query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1 && goto :PE_DEPLOY_STAGE

cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %Apply%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

:: ËµÃ÷
cls
echo.
echo =======================================================================
echo [93m ÖØÒªËµÃ÷ [0m[91m *%PE_PARTITION%:·ÖÇø¿ÉÓÃ¿Õ¼äÖÁÉÙÐèÒª 10GB* [0m
echo =======================================================================
echo 1. ¼Ü¹¹×ÜÀÀ
echo    ±¾½Å±¾²ÉÓÃ¡¾Èý½×¶ÎÎÞ·ìÏÎ½Ó¡¿Éè¼Æ£º
echo    - ½×¶ÎÒ»(µ±Ç°): È¨ÏÞÌáÉý - ×ÊÔ´¶à¼¶À­È¡ - Çý¶¯µ¼³ö - ¹¹ÔìË«Æô¶¯Ïî²¢µ¹¼ÆÊ±ÖØÆô¡£
echo    - ½×¶Î¶þ(PE)  : ×Ô¶¯¸ñÊ½»¯CÅÌ - DISMÊÍ·Å¾µÏñ - ×¢ÈëÎÞÈËÖµÊØÅäÖÃ - ÐÞ¸´Òýµ¼¡£
echo    - ½×¶ÎÈý(OOBE): ×Ô¶¯¼ÓÓò - ¾²Ä¬°²×°Ô¤ÉèÈí¼þ - ¿ªÆôRDPÔ¶³Ì - ÆóÒµÎ¢ÐÅ»úÆ÷ÈËÍ¨Öª¡£
echo.
echo 2. ºËÐÄ¼¼Êõµã½âÎö
echo    ¹ÜÀíÔ±È¨ÏÞ×ÔÌá : ÀûÓÃ VBS ¶¯Ì¬´´½¨ UAC ÌáÈ¨»úÖÆ£¬È·±£¸ßÈ¨ÏÞÖ´ÐÐ¡£
echo    ·Ö¼¶×ÊÔ´¼ìË÷   : ÒÀ´Î´Ó [±¾µØÄ¿±êÎÄ¼þ¼Ð] -^> [¿çÅÌ·ûÉ¨Ãè] -^> [ÄÚÍø HTTP ÏÂÔØ] ²éÕÒ WIM/ESD ¹Ø¼ü×é¼þ£¬¾ß±¸¸ßÈÝ´íÐÔ¡£
echo    ¶¯Ì¬ XML ×¢Èë  : »ùÓÚÊ±¼ä´ÁÉú³É LC-¿ªÍ·µÄ¼ÆËã»úÃû£¬¶¯Ì¬Ìæ»» Unattend Õ¼Î»·û¡£
echo    Ô­³§Çý¶¯±£»¤   : ²ÉÓÃ Pnputil Áª»ú±¸·Ýµ±Ç°»úÆ÷Ó²¼þÇý¶¯£¬²¢ÔÚÐÂÏµÍ³ÖÐ×Ô¶¯×¢Èë¡£
echo    ºóÖÃºó´¦ÀíÓÅ»¯ : ×Ô¶¯¼¤»î KMS ÃÜÔ¿¡¢¿ªÆôÔ¶³Ì×ÀÃæ²¢ÅäÖÃ·À»ðÇ½¹æÔò¡¢Ìæ»»ÆóÒµ±ÚÖ½¡£
echo.
echo 3. ÍøÂçÓëÍâÎ§ÒÀÀµ»·¾³·ÖÎö (¹Ø¼ü)
echo    [92m * ÄÚÍøÏÂÔØ·þÎñÆ÷ : ½Å±¾ÒÀÀµ·þÎñÆ÷ %http_url% ÏÂ·¢ºËÐÄ WIM/ESD/XML/±ÚÖ½×é¼þ¡£ [0m
echo    [91m * Èô´¦ÓÚ¡¾ÎÞÍø¡¿»ò¡¾´¿ÍâÍø¸ôÀë¡¿»·¾³£¬±ØÐëÌáÇ°½«ÏÂÁÐÎÄ¼þ·ÅÖÃÓÚÈÎÒâÅÌ·ûÏÂµÄ "%disk_folder%" ÎÄ¼þ¼ÐÄÚ£¬ÒÔ´¥·¢±¾µØ¿çÅÌÉ¨Ãè¸´ÖÆ£º- %PE_WIM% ^| %PE_SDI% ^| %ESD_NAME% ^| %Win_WallPaper% [0m
echo    * ÆóÒµÓò¿ØÒÀÀµ   : Ó¦´ðÎÄ¼þ(XML)ÖÐÔ¤ÉèÁË ".VIP" Óò¿ØºÍÖ¸¶¨ OU ÈÝÆ÷Â·¾¶¡£·Ç¸ÃÆóÒµÓò»·¾³ÔËÐÐ£¬¼ÓÓò²½Öè»á³¬Ê±Ê§°Ü£¬µ«²»Ó°ÏìÏµÍ³»ù´¡¾ÍÐ÷¡£
echo    * OOBE ½×¶ÎÊÕÎ²Ê±£¬ÄÜ¹»Õý³£·ÃÎÊÍâÍøÊ±¸ø³öÆóÒµÎ¢ÐÅ¡¾OS_Ready¡¿Í¨Öªºó²¢×Ô¶¯ÖØÆô¡£
echo.
echo 4. ºËÐÄÂ·¾¶±äÁ¿
echo    [91m * Ä¿±ê²¿ÊðÄ¿Â¼   : %TARGET_DIR% [0m
echo    [91m * Çý¶¯±¸·ÝÂ·¾¶   : %DRV_BACKUP_PATH% [0m
echo =======================================================================
echo.
echo °´ÈÎÒâ¼ü¿ªÊ¼Ð£Ñé±¾µØ»·¾³²¢¼ÌÐøºóÐø×Ô¶¯Á÷³Ì...
pause >nul
cls

:: 2. ¹Ø¼ü×é¼þ·Ö¼¶À­È¡Âß¼­ (±¾µØ´æÔÚÔòÌø¹ý -> ¿çÅÌÉ¨Ãè -> ÄÚÍøcurlÏÂÔØ)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" 2>nul
for %%f in ("%PE_SDI%" "%PE_WIM%" "%ESD_NAME%" "%Win_WallPaper%") do (
    set "FOUND="
    set "CUR_FILE=%%~nxf"
    if exist "%TARGET_DIR%\!CUR_FILE!" (
        echo [ÐÅÏ¢] ÒÑ´æÔÚ£¬Ìø¹ý£º!CUR_FILE!
        set "FOUND=1"
    )
    
    if "!FOUND!"=="" (
        call :FindLocalFile "!CUR_FILE!" && (
            echo [ÐÅÏ¢] ÒÑ´Ó±¾µØ½éÖÊ»ñÈ¡£º!CUR_FILE!
            set "FOUND=1"
        )
    )

    if "!FOUND!"=="" (

        ping -n 1 -w 1000 %http_url% >nul 2>&1

       if not errorlevel 1 (

            echo [ÐÅÏ¢] ´Ó·þÎñÆ÷ÏÂÔØ£º!CUR_FILE!

            curl -L -f -k --connect-timeout 5 ^
                -o "%TARGET_DIR%\!CUR_FILE!" ^
                "%http_path%/!CUR_FILE!"

            if not errorlevel 1 (
                if exist "%TARGET_DIR%\!CUR_FILE!" (
                    set "FOUND=1"
                ) else (
                    echo [¾¯¸æ] ´ÅÅÌÉÏÎ´Éú³ÉÄ¿±êÎÄ¼þ£º!CUR_FILE!
                )
            ) else (
                echo [¾¯¸æ] ÏÂÔØÊ§°Ü£¬·þÎñÆ÷¿ÉÄÜ·µ»ØÁË´íÎó×´Ì¬Âë£º!CUR_FILE!
                if exist "%TARGET_DIR%\!CUR_FILE!" del /q "%TARGET_DIR%\!CUR_FILE!"
            )

        ) else (
            echo [ÌáÊ¾] %http_url% ²»¿É´ï£¬Ìø¹ýÏÂÔØ½×¶Î¡£
        )
    )

    if "!FOUND!"=="" (
        echo.
        echo =======================================================
        echo [´íÎó] È±ÉÙ¹Ø¼üÎÄ¼þ£º!CUR_FILE!
        echo [´íÎó] ±¾µØ C~H:\%disk_folder% Î´ÕÒµ½¸ÃÎÄ¼þ
        echo [´íÎó] ÎÞ·¨´Ó %http_url% »ñÈ¡¸ÃÎÄ¼þ
        echo =======================================================
        pause
        exit /b 1
    )
) 2>nul

echo.
echo ËùÓÐ¹Ø¼ü×é¼þ¼ì²éÍê³É£¬¼ÌÐøÖ´ÐÐºóÐøÁ÷³Ì¡£
goto :CONTINUE_FLOW

:FindLocalFile
set "FILE_NAME=%~1"

for %%d in (C D E F G H) do (
    if exist "%%d:\%disk_folder%\!FILE_NAME!" (
        echo [ÐÅÏ¢] ´Ó %%d:\%disk_folder% ¸´ÖÆ !FILE_NAME!
        copy /y "%%d:\%disk_folder%\!FILE_NAME!" "%TARGET_DIR%\" >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
)
exit /b 1

:CONTINUE_FLOW
echo [×´Ì¬]»ù´¡»·¾³ÒÑ×¼±¸¾ÍÐ÷
echo.

:: ×îÖÕ¸ñÊ½£ºLC-260605153322 (¹²15Î»£¬ÍêÃÀ·ûºÏ¹æ·¶)
set "d=%date%"&set "t=%time: =0%"
set "F_DATETIME=LC-%d:~2,2%%d:~5,2%%d:~8,2%%t:~0,2%%t:~3,2%%t:~6,2%"
:: ×Ô¶¨ÒåÃû³Æ
set /p ="ÇëÊäÈë×Ô¶¨ÒåÃû³Æ (Ä¬ÈÏ: %F_DATETIME%): " <nul
:: ³¬Ê± 60 ÃëÄ¬ÈÏ
for /f "delims=" %%I in ('powershell -Command "$w=[Diagnostics.Stopwatch]::StartNew(); while($w.Elapsed.TotalSeconds -lt 60 -and -not [Console]::KeyAvailable){Start-Sleep -m 100}; if([Console]::KeyAvailable){Read-Host}"') do set "USER_INPUT=%%I"
if "%USER_INPUT%"=="" (set "DYNAMIC_PCNAME=%F_DATETIME%") else (set "DYNAMIC_PCNAME=%USER_INPUT%")

:: ¶¯Ì¬ÊÍ·Å´ð°¸ÎÄ¼þ (XML) µ½ÖØ×°Ä¿Â¼±¸·Ý£¬²¢×¢Èë¶¯Ì¬¼ÆËã»úÃû
echo ÕýÔÚ½âÎöÊÍ·Å²¢×¢Èë¶¯Ì¬±äÁ¿µ½ Unattend ÎÞÈËÖµÊØÅäÖÃÎÄ¼þ...
set "TEMP_XML=%TARGET_DIR%\win-auto.xml"
if exist "%TEMP_XML%" del /q "%TEMP_XML%"
set "xml_start="
for /f "delims=:" %%n in ('findstr /n /c:"===XML_START===" "%~f0"') do set /a xml_start=%%n
(
    for /f "usebackq skip=%xml_start% delims=" %%l in ("%~f0") do (
        set "line=%%l"
        :: ¼ì²âµ½Õ¼Î»·ûÐÐ£¬Ö´ÐÐ¶¯Ì¬±äÁ¿Ìæ»»
        if "!line:<ComputerName>DYNAMIC_PCNAME_PLACEHOLDER</ComputerName>=!" neq "!line!" (
            echo       ^<ComputerName^>%DYNAMIC_PCNAME%^</ComputerName^>
        ) else (
            echo %%l
        )
    )
) > "%TEMP_XML%"

:: µ¼³ö/±¸·Ýµ±Ç°»úÆ÷µÄÔ­³§Çý¶¯
echo ÕýÔÚ±¸·Ýµ±Ç°ÏµÍ³Çý¶¯³ÌÐòÖÁ %DRV_BACKUP_PATH%...
if exist "%DRV_BACKUP_PATH%" rd /q /s "%DRV_BACKUP_PATH%"
mkdir "%DRV_BACKUP_PATH%"
pnputil /export-driver * "%DRV_BACKUP_PATH%" >nul
if exist "HP_640_G10_USB" xcopy "HP_640_G10_USB" "%DRV_BACKUP_PATH%\xyz" /E /I /Y /Q

:: ¶¯Ì¬Éú³ÉÏÂÒ»²½ÔÚ PE »·¾³ÏÂÐèÒªÔËÐÐµÄ¶ÀÁ¢¿ØÖÆ½Å±¾
copy /y "%~f0" "%TARGET_DIR%\pe_%F_DATETIME%.bat" >nul
echo ÕýÔÚÉú³É PE ½×¶ÎÐÔ»·¾³²¿ÊðÂß¼­...
set "PE_RUN_BAT=%TARGET_DIR%\lc.bat"
(
    echo @echo off
    echo title PE ×Ô¶¯²¿ÊðÁ÷³Ì
    echo if /i "%%UserName%%" == "Administrator" tsdiscon
    echo rem ÅÐ¶ÏÖ÷½Å±¾ÊÇ·ñ´æÔÚ£¬Èç²»´æÔÚ£¬ÔòÖ´ÐÐÔÝÍ££¬±ÜÃâÎó²Ù×÷Ôì³É²»¿ÉÍì»ØµÄÓ°Ïì
    echo if not exist "%TARGET_DIR%\pe_%F_DATETIME%.bat" pause
    echo rem Ö÷½Å±¾Èç´æÔÚ£¬Ôò¿ªÊ¼µ÷ÓÃ pe_%F_DATETIME%.bat
    echo if exist "%TARGET_DIR%\pe_%F_DATETIME%.bat" call "%TARGET_DIR%\pe_%F_DATETIME%.bat"
    echo del %%0 ^& exit
) > "%PE_RUN_BAT%"

:: ÅäÖÃ BCD Æô¶¯²Ëµ¥ÏîÄ¿
set "guid_ram={ramdiskoptions}"
set "guid_os={66668888-a8d0-11f0-910e-d85ed3740d10}"

bcdedit /delete %guid_ram% /f >nul 2>&1
bcdedit /delete %guid_os% /f >nul 2>&1

bcdedit /create %guid_ram% /d "%PE_NAME%" >nul
bcdedit /create %guid_os% /d "%PE_NAME%" /application osloader >nul

if exist %SystemRoot%\System32\boot\winload.efi (
    set "loaderPath=\windows\system32\boot\winload.efi"
    echo [¼ì²â] µ±Ç°Ö÷°åÒýµ¼Ä£Ê½£ºUEFI
) else (
    set "loaderPath=\windows\system32\boot\winload.exe"
    echo [¼ì²â] µ±Ç°Ö÷°åÒýµ¼Ä£Ê½£ºLegacy/MBR
)

bcdedit /set %guid_os% path %loaderPath% >nul
bcdedit /set %guid_os% device ramdisk=[%PE_PARTITION%:]\%PE_PATH%\%PE_WIM%,%guid_ram% >nul
bcdedit /set %guid_os% osdevice ramdisk=[%PE_PARTITION%:]\%PE_PATH%\%PE_WIM%,%guid_ram% >nul
bcdedit /set %guid_os% systemroot \windows >nul
bcdedit /set %guid_os% winpe yes >nul
bcdedit /set %guid_os% detecthal yes >nul

bcdedit /set %guid_ram% ramdisksdidevice partition=%PE_PARTITION%: >nul
bcdedit /set %guid_ram% ramdisksdipath \%PE_PATH%\%PE_SDI% >nul

bcdedit /displayorder %guid_os% /addlast >nul
bcdedit /bootsequence %guid_os% /addfirst >nul
bcdedit /timeout 3 >nul

echo.
echo BCD »·¾³¹¹½¨Íê±Ï£¬»Ø³µºó×Ô¶¯ÖØÆôÖØ×°ÏµÍ³...
pause
shutdown /r /t 1
del %0 & exit /b

:: 3. PE »·¾³ÏÂµÄ²¿Êð½×¶Î

:PE_DEPLOY_STAGE
setlocal enabledelayedexpansion
echo =======================================================
echo        »¶Ó­½øÈë PE ×Ô¶¯»¯¾µÏñÊÍ·ÅÓë»Ö¸´½×¶Î
echo =======================================================

:: É¨ÃèÏµÍ³ÅÌÎ»ÖÃ
set "SysDrive="
for %%i in (C D E F G) do (
    if exist "%%i:\Windows\System32" set "SysDrive=%%i:"
)
if not defined SysDrive (
    echo [´íÎó] Î´ÄÜÊ¶±ðµ½°üº¬ Windows Ä¿Â¼µÄÏµÍ³·ÖÇø¡£
    pause & exit
)

:: Ñ°ÕÒÖØ×°Ô´ÎÄ¼þÂ·¾¶£¨¼ì²éµ±Ç°Ö÷½Å±¾ËùÔÚµÄ¸ùÂ·¾¶»òDÅÌ£©
if not defined ESD_NAME (
    echo [´íÎó0] Î´ÄÜÕÒµ½ÏµÍ³ ESD Ó³ÏñÔ´ÎÄ¼þ¡£
    pause & exit
)

set "OS_SRC_DIR="
for %%i in (C D E F G) do (
    if exist "%%i:\%PE_PATH%\%ESD_NAME%" set "OS_SRC_DIR=%%i:\%PE_PATH%"
)

if not defined OS_SRC_DIR  (
    echo [´íÎó1] Î´ÄÜÕÒµ½ÏµÍ³ %PE_NAME% Â·¾¶¡£
    pause & exit
)

echo [×´Ì¬] Ê¶±ðÏµÍ³ÅÌ: %SysDrive%
echo [×´Ì¬] Ê¶±ðÓ³ÏñÔ´: %OS_SRC_DIR%\%ESD_NAME%

:: ¸ñÊ½»¯Ô­ÏµÍ³ÅÌ
echo ÕýÔÚÖ´ÐÐ¿ìËÙ¸ñÊ½»¯ %SysDrive%...
format %SysDrive% /q /y /v:System >nul

:: Áª¶¯ÊÍ·Å²¢Ó¦ÓÃ ESD Ó³Ïñ
echo ÕýÔÚÏòÄ¿±êÅÌÓ¦ÓÃÏµÍ³Ó³Ïñ (DISM Compact Ñ¹ËõÄ£Ê½)...
set "unattend_param="
if exist "%OS_SRC_DIR%\win-auto.xml" set "unattend_param=/unattend:"%OS_SRC_DIR%\win-auto.xml""
dism /Apply-Image /ImageFile:"%OS_SRC_DIR%\%ESD_NAME%" /Index:%ESD_INDEX% /ApplyDir:%SysDrive%\ /Compact %unattend_param%

:: ÆÁ±Î¡°Í¬Òâ¸öÈËÊý¾Ý¿ç¾³´«Êä¡±ÒþË½ÌáÊ¾µ¯´°
echo ÕýÔÚ¶ÔÈ«ÐÂÓÃ»§ÅäÖÃÎÄ¼þ½øÐÐºóÖÃ×¢²á±íÓÅ»¯×¢Èë...
for /d %%i in (%SysDrive%\Users\*) do (
    if not "%%~nxi"=="Public" (
        if exist "%%i\NTUSER.DAT" (
            reg load HKU\UXPC "%%i\NTUSER.DAT" >nul
            reg add "HKU\UXPC\Software\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\PersonalDataExport" /f /v "PDEShown" /t REG_DWORD /d 2 >nul
            reg unload HKU\UXPC >nul
        )
    )
)
if exist "%SysDrive%\Users\Default\NTUSER.DAT" (
    reg load HKU\UXPC "%SysDrive%\Users\Default\NTUSER.DAT" >nul
    reg add "HKU\UXPC\Software\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\PersonalDataExport" /f /v "PDEShown" /t REG_DWORD /d 2 >nul
    reg unload HKU\UXPC >nul
)

:: ÐÞ¸´ÏµÍ³Òýµ¼
echo ÕýÔÚÖØ½¨²¢ÐÞ¸´Ö÷Òýµ¼¼ÇÂ¼...
bcdboot %SysDrive%\Windows /s %SysDrive% /f ALL >nul
bcdedit /store %SysDrive%\Boot\BCD /timeout 3 >nul 2>&1

:: ×¢ÈëÖ®Ç°µ¼³öµÄ±¸·ÝÇý¶¯
echo ÕýÔÚ½«Éè±¸Ô­³§Ó²¼þÇý¶¯Áª»ú×¢Èëµ½ÐÂÏµÍ³ÖÐ...
if exist "%DRV_BACKUP_PATH%" dism /Image:%SysDrive%\ /Add-Driver /Driver:"%DRV_BACKUP_PATH%" /Recurse >nul

:: ´´½¨ Windows Ó¦´ðÄ¿Â¼²¢¸´ÖÆ XML È·±£ OOBE ½×¶ÎÉúÐ§
if exist "%OS_SRC_DIR%\win-auto.xml" (
    mkdir "%SysDrive%\Windows\Panther" 2>nul
    copy /y "%OS_SRC_DIR%\win-auto.xml" "%SysDrive%\Windows\Panther\unattend.xml" >nul
)

:: Ìæ»» Windows Ä¬ÈÏ±ÚÖ½
if exist "%OS_SRC_DIR%\"%Win_WallPaper%"" (
	takeown /f "%SysDrive%\Windows\Web\Wallpaper\Windows\img0.jpg" /a >nul
	icacls "%SysDrive%\Windows\Web\Wallpaper\Windows\img0.jpg" /grant administrators:F >nul
	copy /y "%OS_SRC_DIR%\%Win_WallPaper%" "%SysDrive%\Windows\Web\Wallpaper\Windows\img0.jpg" >nul
)

:: ¶¯Ì¬×é×° OOBE Ê×´ÎµÇÂ¼Ö´ÐÐµÄÏµÍ³ÓÅ»¯½Å±¾ (1.cmd)
echo ÕýÔÚÏòÏµÍ³ÅÌ×¢ÈëÊ×´ÎµÇÂ¼×Ô¶¯Åú´¦Àí½Å±¾ (1.cmd)...
mkdir "%SysDrive%\Admin" 2>nul
set "OOBE_CMD=%SysDrive%\Admin\1.cmd"

set "d=%date%"&set "t=%time: =0%"
set "DR_NAME=BAK%d:~2,2%%d:~5,2%%d:~8,2%%t:~0,2%%t:~3,2%%t:~6,2%"

:: »ù´¡¾²Ì¬ÅäÖÃ²¿·ÖÖ±½Ó´ó¿éÐ´Èë
(
    echo @echo off
    echo title ÏµÍ³Ê×´Î½ø×ÀÃæÅäÖÃÓëÓÅ»¯
    echo setlocal enabledelayedexpansion
    echo echo.
    echo tsdiscon
    echo net user %%username%% /fullname:%%computername%%
    echo :: 1. ×¢²áÏµÍ³ Kms ÃÜÔ¿ÓëÏµÍ³×é¼þ³õÊ¼»¯
    echo cscript //nologo %%systemroot%%\system32\slmgr.vbs /ipk %PRODUCT_KEY% ^>nul
    echo net user %%username%% /expires:never ^>nul
    echo wmic UserAccount where Name='%%USERNAME%%' set PasswordExpires=false ^>nul 2^>^&1
    echo.
    echo :: 2. ¿ªÆôÔ¶³Ì×ÀÃæ RDP ·þÎñÓë°²È«×é²ßÂÔÅäÖÃ
    echo reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f ^>nul
    echo reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f ^>nul
    echo netsh advfirewall firewall add rule name="Allow RDP" protocol=TCP dir=in localport=3389 action=allow ^>nul
    echo netsh advfirewall firewall add rule name="Allow_RDP_Shadow_Process" dir=in action=allow program=%%SystemRoot%%\system32\RdpSa.exe enable=yes protocol=TCP ^>nul
    echo net localgroup "Remote Desktop Users" "%%username%%" /add ^>nul 2^>^&1
    echo net start TermService ^>nul 2^>^&1
    echo.
    echo :: 3. Ó²¼þµçÔ´¼Æ»®Óë²¹¶¡Éý¼¶
    echo powercfg -change -standby-timeout-dc 60 ^>nul
    echo powercfg -change -standby-timeout-ac 0 ^>nul
    echo reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f ^>nul
    echo gpupdate /force ^>nul
    echo if exist %PE_PARTITION%:\kb.msu wusa %PE_PARTITION%:\kb.msu /quiet /forcerestart
    echo.
    echo :: 4. ×Ô¶¯»¯Èí¼þ¾²Ä¬°²×°
    echo if exist "E:\myos\setup\0-InstallAllSoft-v0.0.0.2.exe" start "" /wait "E:\myos\setup\0-InstallAllSoft-v0.0.0.2.exe"
    echo if exist "f:\myos\setup\0-InstallAllSoft-v0.0.0.2.exe" start "" /wait "f:\myos\setup\0-InstallAllSoft-v0.0.0.2.exe"
    echo if exist %PE_PARTITION%:\%PE_PATH%\mydr move %PE_PARTITION%:\%PE_PATH%\mydr %PE_PARTITION%:\%DR_NAME%mydr ^>nul
    echo.
    echo :: 5. ÅäÖÃÎÞÏßÍøÂç WLAN Profile Ô¤ÉèÎÄ¼þ
    echo if exist "E:\myos\WLAN-WIFI.xml" netsh wlan add profile filename="E:\myos\WLAN-WIFI.xml" ^>nul
    echo if exist "F:\myos\WLAN-WIFI.xml" netsh wlan add profile filename="F:\myos\WLAN-WIFI.xml" ^>nul
    echo.
    echo :: 6.×ÀÃæÏÔÊ¾ ´ËµçÄÔ¡¢ÓÃ»§ÎÄ¼þ¼Ð¡¢ÍøÂç
    echo set "regpath=HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer"
    echo reg add "%%regpath%%\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d "0" /f ^>nul
    echo reg add "%%regpath%%\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d "0" /f ^>nul
    echo reg add "%%regpath%%\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d "0" /f ^>nul
    echo.
    echo :: 7.ÉèÖÃ´ò¿ªÎÄ¼þ×ÊÔ´¹ÜÀíÆ÷Ê±´ò¿ª´ËµçÄÔ
    echo reg add "%%regpath%%\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f ^>nul
) > "%OOBE_CMD%"

:: ²ÉÓÃµ¥ÐÐ×·¼ÓÄ£Ê½Ð´Èë BCD ¸´ÔÓÑ­»·Ìå£¬ÍêÈ«±Ü¿ªÀ¨ºÅ¶ÔÍâ²¿½âÊÍÆ÷µÄ¸ÉÈÅ
echo set "cur_id=">> "%OOBE_CMD%"
echo for /f "tokens=1,2*" %%%%i in ('bcdedit') do (>> "%OOBE_CMD%"
echo     if "%%%%i"=="±êÊ¶·û" set "cur_id=%%%%j">> "%OOBE_CMD%"
echo     if "%%%%i"=="identifier" set "cur_id=%%%%j">> "%OOBE_CMD%"
echo     if "%%%%i"=="description" (>> "%OOBE_CMD%"
echo         if "%%%%j %%%%k"=="EDY Recovery" bcdedit /delete %%cur_id%% /f ^>nul>> "%OOBE_CMD%"
echo     )>> "%OOBE_CMD%"
echo )>> "%OOBE_CMD%"

:: ×·¼ÓºóÐøÇåÀíÓëÆóÒµÎ¢ÐÅÍ¨Öª²¿·Ö
(
    echo bcdedit /delete {66668888-a8d0-11f0-910e-d85ed3740d10} /f ^>nul 2^>^&1
    echo bcdedit /timeout 0 ^>nul
    echo.
    echo :: 8. OFFICE°²×°¡¢ÆóÒµÎ¢ÐÅ»úÆ÷ÈËÉÏÏßÍ¨ÖªÓë»·¾³ÊÕÎ²ÇåÀí
    echo ping -n 2 -w 2000 %http_url% ^>nul ^&^& curl -o %PE_PARTITION%:\%PE_PATH%\0_soft.exe http://%http_url%/soft/reos/0_soft.x64
    echo if exist %PE_PARTITION%:\%PE_PATH%\0_soft.exe %PE_PARTITION%:\%PE_PATH%\0_soft.exe all
    echo ping -n 2 -w 2000 %http_url% ^>nul ^&^& curl -o %PE_PARTITION%:\%PE_PATH%\setup.exe http://%http_url%/soft/office/setup.exe ^&^& curl -o %PE_PARTITION%:\%PE_PATH%\configuration.xml http://%http_url%/soft/office/configuration.xml
    echo if exist %PE_PARTITION%:\%PE_PATH%\configuration.xml %PE_PARTITION%:\%PE_PATH%\setup.exe /configure
    echo if exist C:\Windows\Panther rd /q /s C:\Windows\Panther
    echo if exist %PE_PARTITION%:\%PE_PATH% rd /q /s %PE_PARTITION%:\%PE_PATH%
    echo ping -n 2 qyapi.weixin.qq.com ^>nul ^&^& curl -H "Content-Type: application/json" -X POST https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=%botkey% -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[%%time%%]-[%%computername%%]-[OS_Ready]\"}}" ^>nul 2^>^&1
    echo net user %%username%% Test ^>nul
    echo net user %%username%% /fullname:%%computername%% ^>nul
    echo wmic useraccount where name='%%username%%' set passwordexpires=false ^>nul
    echo powershell -Command "Restart-Computer -Force"
    echo del %%0 ^& exit
) >> "%OOBE_CMD%"

echo [Íê³É] ¾µÏñÊÍ·ÅÓëºóÖÃÅäÖÃ×¢Èë³É¹¦¡£
echo 30ÃëºóÏµÍ³½«×Ô¶¯ÖØÆô½øÈë¿ªÏä OOBE È«×Ô¶¯ÅäÖÃ½×¶Î...
shutdown /r /t 30
del %0 & exit /b

:: ´Ë´¦Îª±ê¼ÇÎ»£ºÒÔÏÂËùÓÐÎÄ±¾½«ÔÚÖ´ÐÐÊ±±»Ö±½Ó¶ÁÈ¡²¢Éú³É±¾µØ´ð°¸ÎÄ¼þ
===XML_START===
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">  
  <settings pass="windowsPE"> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <SetupUILanguage> 
        <UILanguage>zh-CN</UILanguage> 
      </SetupUILanguage>  
      <InputLocale>0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411f-A5AC-CA038EC515D7}</InputLocale>  
      <SystemLocale>zh-CN</SystemLocale>  
      <UILanguage>zh-CN</UILanguage>  
      <UILanguageFallback>zh-CN</UILanguageFallback>  
      <UserLocale>zh-CN</UserLocale> 
    </component>  
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <UserData> 
        <ProductKey> 
          <Key/>  
          <WillShowUI>Never</WillShowUI> 
        </ProductKey>  
        <AcceptEula>true</AcceptEula>  
        <FullName/>  
        <Organization/> 
      </UserData> 
    </component> 
  </settings>  
  <settings pass="offlineServicing"> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <EnableLUA>false</EnableLUA> 
    </component> 
  </settings>  
  <settings pass="generalize"> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <SkipRearm>1</SkipRearm> 
    </component> 
  </settings>  
  <settings pass="specialize"> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <InputLocale>0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411f-A5AC-CA038EC515D7}</InputLocale>  
      <SystemLocale>zh-CN</SystemLocale>  
      <UILanguage>zh-CN</UILanguage>  
      <UILanguageFallback>zh-CN</UILanguageFallback>  
      <UserLocale>zh-CN</UserLocale> 
    </component>  
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <SkipAutoActivation>true</SkipAutoActivation> 
    </component>  
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">  
      <CEIPEnabled>0</CEIPEnabled> 
    </component> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <ComputerName>DYNAMIC_PCNAME_PLACEHOLDER</ComputerName>
    </component>
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <Identification>
        <Credentials>
          <Domain>JWSD.VIP</Domain>
          <Username>join.ad</Username>
          <Password>Join.Jwsd.Vip</Password>
        </Credentials>
        <JoinDomain>JWSD.VIP</JoinDomain>
        <MachineObjectOU>OU=0.VieStar,OU=3.jwsd,DC=JWSD,DC=VIP</MachineObjectOU>
        <UnsecureJoin>false</UnsecureJoin>
        <TimeoutPeriodInMinutes>5</TimeoutPeriodInMinutes>
      </Identification>
    </component>
  </settings>  
  <settings pass="oobeSystem"> 
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OEMInformation> 
        <SupportProvider>Support</SupportProvider>  
        <SupportAppURL>LC-contact-support</SupportAppURL>  
        <SupportURL>https://microsoft.com</SupportURL>  
        <Manufacturer>(BS GROUP)</Manufacturer> 
      </OEMInformation>  
      <OEMName>BS GROUP</OEMName>  
      <UserAccounts> 
        <LocalAccounts> 
          <LocalAccount wcm:action="add"> 
            <Name>Test</Name>  
            <Group>Administrators</Group>  
            <Password> 
              <Value>Test</Value>
              <PlainText>true</PlainText> 
            </Password>  
            <Description>LC Auto Account</Description>  
            <DisplayName>Admin</DisplayName> 
          </LocalAccount> 
        </LocalAccounts> 
      </UserAccounts>  
      <AutoLogon> 
        <Enabled>true</Enabled>  
        <Username>Test</Username>  
        <Domain>.</Domain>  
        <Password> 
          <Value>Test</Value> 
          <PlainText>true</PlainText> 
        </Password>  
        <LogonCount>2</LogonCount> 
      </AutoLogon>  
      <OOBE> 
        <HideEULAPage>true</HideEULAPage>  
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>  
        <NetworkLocation>Work</NetworkLocation>  
        <ProtectYourPC>3</ProtectYourPC>  
        <SkipMachineOOBE>true</SkipMachineOOBE>  
        <SkipUserOOBE>true</SkipUserOOBE> 
      </OOBE>  
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add"> 
          <CommandLine>%SystemDrive%\Admin\1.cmd</CommandLine>  
          <Description>Location Setup Cmd</Description>  
          <Order>1</Order> 
        </SynchronousCommand> 
      </FirstLogonCommands> 
    </component> 
  </settings> 
</unattend>