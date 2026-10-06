@echo off
setlocal
cd /d "%~dp0"
call "%~dp0config.bat"
echo Stopping ShopSphere ...
for %%P in (%BACKEND_PORT% %FRONTEND_PORT%) do (
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr /R /C:":%%P .*LISTENING"') do (
        taskkill /PID %%i /T /F >nul 2>&1
        echo   stopped process %%i on port %%P
    )
)
echo Done.
if not defined NOPAUSE timeout /t 3 >nul
exit /b 0
