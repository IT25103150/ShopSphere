@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title ShopSphere - Start
echo ==========================================================
echo   Starting ShopSphere
echo ==========================================================
call "%~dp0config.bat"

if not exist "%ROOT%\backend\target\shopsphere-backend.jar" (
    echo [X] The backend has not been built yet. Run SETUP.bat first.
    goto :fail
)
if not exist "%ROOT%\frontend\node_modules" (
    echo [X] Frontend packages are not installed. Run SETUP.bat first.
    goto :fail
)

echo [1/4] Checking SQL Server and the database ...
call "%~dp0scripts\ensure-sql.bat" >nul
if errorlevel 1 (
    call "%~dp0scripts\ensure-sql.bat"
    goto :fail
)
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -b -h -1 -Q "SET NOCOUNT ON; IF DB_ID(N'%DB_NAME%') IS NULL RAISERROR(N'missing',16,1)" >nul 2>&1
if errorlevel 1 (
    echo [X] Database %DB_NAME% does not exist. Run SETUP.bat ^(or RESET_DATABASE.bat^) first.
    goto :fail
)
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\detect-sql-port.ps1"`) do set "DB_PORT=%%p"
echo       OK

rem Environment read by the Spring Boot backend
set "DB_HOST=%DB_HOST%"
set "DB_PORT=%DB_PORT%"
set "DB_NAME=%DB_NAME%"
set "DB_USER=%DB_USER%"
set "DB_PASSWORD=%DB_PASSWORD%"
set "IMAGES_DIR=%IMAGES_DIR%"

echo [2/4] Starting backend on port %BACKEND_PORT% ...
netstat -ano | findstr /R /C:":%BACKEND_PORT% .*LISTENING" >nul
if not errorlevel 1 (
    echo       Port %BACKEND_PORT% is already in use - assuming ShopSphere is already running.
) else (
    start "ShopSphere BACKEND (do not close)" cmd /k "cd /d "%ROOT%" && java -jar backend\target\shopsphere-backend.jar"
)
powershell -NoProfile -Command "for($i=0;$i -lt 120;$i++){ try{ if((Invoke-RestMethod http://localhost:%BACKEND_PORT%/actuator/health -TimeoutSec 2).status -eq 'UP'){ exit 0 } }catch{}; Start-Sleep 1 }; exit 1"
if errorlevel 1 (
    echo [X] The backend did not become healthy within 2 minutes. Look at the "ShopSphere BACKEND" window for the error.
    goto :fail
)
echo       Backend is UP

echo [3/4] Starting frontend on port %FRONTEND_PORT% ...
netstat -ano | findstr /R /C:":%FRONTEND_PORT% .*LISTENING" >nul
if not errorlevel 1 (
    echo       Port %FRONTEND_PORT% is already in use - assuming the frontend is already running.
) else (
    start "ShopSphere FRONTEND (do not close)" cmd /k "cd /d "%ROOT%\frontend" && npm run dev"
)
powershell -NoProfile -Command "for($i=0;$i -lt 90;$i++){ try{ Invoke-WebRequest http://localhost:%FRONTEND_PORT%/ -UseBasicParsing -TimeoutSec 2 | Out-Null; exit 0 }catch{}; Start-Sleep 1 }; exit 1"
if errorlevel 1 (
    echo [X] The frontend did not start. Look at the "ShopSphere FRONTEND" window for the error.
    goto :fail
)
echo       Frontend is UP

echo [4/4] Opening the browser ...
if not defined NOBROWSER start "" "http://localhost:%FRONTEND_PORT%"

echo.
echo ==========================================================
echo   ShopSphere is running
echo ==========================================================
echo   Website : http://localhost:%FRONTEND_PORT%
echo   API     : http://localhost:%BACKEND_PORT%
echo   Login   : admin@shopsphere.lk / customer@shopsphere.lk   password: Demo@123
echo   To stop : run STOP.bat  ^(or close the two black windows^)
echo.
if not defined NOPAUSE timeout /t 8 >nul
exit /b 0

:fail
echo.
if not defined NOPAUSE pause
exit /b 1
