@echo off
setlocal enabledelayedexpansion
if [%1]==[] goto usage

for /f "tokens=4-5 delims=. " %%a in ('ver') do set "v=%%a.%%b"
if %v% LSS 10.0 (
    echo Only supports Windows 10 or above
    pause >nul
    goto usage
)

@certutil -? >nul 2>&1 || echo Not Found CertUtil.&&goto usage

set STRING="%2"
set TMPFILE="%TMP%\hash-%RANDOM%.tmp"
echo | set /p=%STRING% > %TMPFILE%
if [%1]==[-sha1] set "x=SHA1"&&call :sha
if [%1]==[-sha256] set "x=SHA256"&&call :sha
if [%1]==[-sha512] set "x=SHA512"&&call :sha
if [%1]==[-md5] set "x=md5"&&call :sha
if [%1]==[-file] call :file
if [%1]==[-base64] call :base64
if [%1]==[-?] goto usage
del %TMPFILE%
goto :eof

:file
certutil -hashfile "%STRING%" sha1
certutil -hashfile "%STRING%" sha256
exit /b 0

:sha
certutil -hashfile %TMPFILE% %x% | findstr /v "hash"
exit /b 0

:base64
set TMPFILEBASE64="%TMP%\base-%RANDOM%.tmp"
certutil -encode %TMPFILE% %TMPFILEBASE64%&&type %TMPFILEBASE64%
rem for /f "tokens=*" %%a in ('type %TMPFILEBASE64%^| findstr /i "="') do echo %%a
del %TMPFILEBASE64%
exit /b 0

:usage
echo Usage: %0 string to be hashed
echo Version:v2.2.5 [mo 15:05 2025/9/12] by LC [17:43 2024/1/17]
echo ----------------------------------------------------------------------------------------------------------
echo reg right menu:
echo   reg add HKEY_CLASSES_ROOT\*\shell\shasum /t REG_SZ /d "q~shasum(&q)"
echo   reg add HKEY_CLASSES_ROOT\*\shell\shasum\command /t REG_SZ /d "cmd /k shasum -file \"%%1\"&&pause&&exit"
echo ----------------------------------------------------------------------------------------------------------
echo by CertUtil [Only supports Windows 10 or above]
echo %0 -file string is files SHA1 and SHA256
echo %0 -sha1 string is sha1sum
echo %0 -sha256 string is sha256sum
echo %0 -sha512 string is sha512sum
echo %0 -md5 string is md5sum
echo %0 -base64 string is base64
echo ----------------------------------------------------------------------------------------------------------
