@echo off
chcp 65001 >nul
echo ================================
echo   Lua Script Build Tool
echo ================================
echo.

cd /d "%~dp0pokemon-memory-reader"

echo [1/2] Building pokemon-memory-reader.lua...
..\lua5.1\lua5.1.exe ..\squish\squish.lua --no-minify --output=pokemon-memory-reader.lua

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo [2/3] Copying to BizHawk Lua directory...
copy /Y pokemon-memory-reader.lua "..\BizHawk-2.11-win-x64\Lua\GBA\pokemon-memory-reader.lua"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Copy failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Build completed successfully!
echo Output: BizHawk-2.11-win-x64\Lua\GBA\pokemon-memory-reader.lua
echo.
pause
