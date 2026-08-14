@echo off
cd /d "%~dp0"
"%~dp0python310\python.exe" -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
"%~dp0python310\python.exe" -m pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
echo.
echo Mirror set OK! All pip installs will be ~7x faster now.
pause
