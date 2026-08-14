@echo off
cd /d "%~dp0"
"%~dp0python310\python.exe" -c "import torch; print('torch', torch.__version__); print('cuda available:', torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO GPU')"
echo.
echo If you see "cuda available: True", GPU is ready!
pause
