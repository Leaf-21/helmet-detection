@echo off
cd /d "%~dp0"
echo Sending test request to the server ...
"%~dp0..\python310\python.exe" example_request.py
pause
