@echo off
REM Build script for Battle API
REM Requires squish.lua and lua in path

set SQUISH=..\..\ai-play-pokemon\archived\tools\squish\squish.lua
set OUTPUT=battle_api.lua
set BIZHAWK_LUA=..\..\ai-play-pokemon\archived\emulators\BizHawk-2.11-win-x64\Lua\GBA\battle_api.lua

echo Building Battle API...
D:\lua5.1\lua5.1.exe %SQUISH% --no-minify --output=%OUTPUT%
if %ERRORLEVEL% EQU 0 (
    echo Build successful: %OUTPUT%
    echo Copying to BizHawk...
    copy /Y %OUTPUT% %BIZHAWK_LUA%
    echo Done: %BIZHAWK_LUA%
) else (
    echo Build failed
)
