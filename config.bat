@echo off
rem ============================================================
rem  ShopSphere shared settings - used by SETUP / START / RESET.
rem  You normally never need to edit this file.
rem ============================================================
set "DB_INSTANCE=localhost\SQLEXPRESS"
set "SQL_SERVICE=MSSQL$SQLEXPRESS"
set "DB_USER=sa"
set "DB_PASSWORD=YourPassword"
set "DB_NAME=ShopSphereDB"
set "DB_HOST=localhost"
set "BACKEND_PORT=8080"
set "FRONTEND_PORT=5173"

rem Project root (the folder this file lives in), without trailing backslash
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "IMAGES_DIR=%ROOT%\images\products"

rem Newer sqlcmd (ODBC 18) needs -C to trust the local server certificate; older versions do not have the switch.
set "SQLTRUST="
sqlcmd -? 2>nul | findstr /C:"-C" >nul 2>&1
if not errorlevel 1 set "SQLTRUST=-C"
exit /b 0
