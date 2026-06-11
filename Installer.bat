@echo off
setlocal enabledelayedexpansion
color F
title Module Installer
echo ===== Module Installer =====
echo.
echo * Installs latest zip/apk in Downloads
echo * Supported on magisk 29.0 +
echo.
where adb >nul 2>&1
if errorlevel 1 (
    echo [*] ADB was not found
    pause >nul
    exit /b 1
)
adb get-state >nul 2>&1
if errorlevel 1 (
    echo [*] Waiting for device
)
:wait_device
adb get-state >nul 2>&1
if errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto wait_device
)
echo [*] Device connected
timeout /t 1 /nobreak >nul
:main
adb get-state >nul 2>&1
if errorlevel 1 (
    echo [*] Device disconnected, Check USB Cable.
    pause >nul
    goto wait_device
)
echo [*] Finding module
set "DOWNLOADS=%USERPROFILE%\Downloads"
set "LATEST="
set "LATEST2="
dir /b /o-d "%DOWNLOADS%\*.zip" 2>nul > "%TEMP%\ziplist.txt"
for /f "usebackq delims=" %%F in ("%TEMP%\ziplist.txt") do (
    if not defined LATEST set "LATEST=%%~F"
)
del "%TEMP%\ziplist.txt" >nul 2>&1
dir /b /o-d "%DOWNLOADS%\*.apk" 2>nul > "%TEMP%\apklist.txt"
for /f "usebackq delims=" %%F in ("%TEMP%\apklist.txt") do (
    if not defined LATEST2 set "LATEST2=%%~F"
)
del "%TEMP%\apklist.txt" >nul 2>&1
if defined LATEST2 (
    set "CLEAN=!LATEST2!"
    set "CLEAN=!CLEAN:(=!"
    set "CLEAN=!CLEAN:)=!"
    if not "!CLEAN!"=="!LATEST2!" (
        ren "%DOWNLOADS%\!LATEST2!" "!CLEAN!"
        set "LATEST2=!CLEAN!"
    )
)
if defined LATEST (
    if defined LATEST2 (
        echo [*] Found both a ZIP and APK
        echo.
        echo 1. Install ZIP module: !LATEST!
        echo 2. Install APK: !LATEST2!
        echo.
        set /p CHOICE="Choose [1/2]: "
        if "!CHOICE!"=="1" goto main2
        if "!CHOICE!"=="2" goto apk
        echo [*] Invalid choice
        pause >nul
        exit /b 1
    )
    goto main2
)
if defined LATEST2 goto apk
echo [*] No file found
pause >nul
exit /b 1

:apk
echo [*] Found !LATEST2!
echo [*] Installing APK
adb install "%DOWNLOADS%\!LATEST2!"
echo [*] Finished
pause >nul
exit /b 0

:main2
echo [*] Found !LATEST!
echo [*] Pushing to device
echo.
adb push "%DOWNLOADS%\!LATEST!" /sdcard/Download/
echo.
echo [*] Installing module
echo.
adb shell "su -c 'magisk --install-module /sdcard/Download/!LATEST!'"
echo.
echo [*] Rebooting
adb reboot

:waitloop
adb get-state >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto waitloop
)
echo [*] Finished
pause >nul