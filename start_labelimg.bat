@echo off
cd /d "%~dp0"
set QT_QPA_PLATFORM_PLUGIN_PATH=%~dp0python310\Lib\site-packages\PyQt5\Qt5\plugins
echo Starting labelImg ...
"%~dp0python310\Scripts\labelImg.exe"
pause
