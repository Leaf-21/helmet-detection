@echo off
cd /d "%~dp0"
echo Starting helmet detection API server on http://127.0.0.1:5000 ...
echo Keep this window open while testing. Close it to stop the server.
"%~dp0..\python310\python.exe" restapi.py
pause
