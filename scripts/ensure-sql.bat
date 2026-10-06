@echo off
rem ============================================================
rem  Verifies SQL Server Express is running and that the configured
rem  SQL login (sa) works. If sa is disabled / has a different password
rem  it is fixed through Windows authentication when possible.
rem  Sets DB_PORT for the backend. Returns errorlevel 1 on failure.
rem ============================================================
call "%~dp0..\config.bat"

echo [1/4] Checking SQL Server service %SQL_SERVICE% ...
sc query "%SQL_SERVICE%" 2>nul | findstr /C:"RUNNING" >nul
if not errorlevel 1 goto :service_ok
echo       Service is not running - trying to start it ...
net start "%SQL_SERVICE%" >nul 2>&1
timeout /t 6 /nobreak >nul
sc query "%SQL_SERVICE%" 2>nul | findstr /C:"RUNNING" >nul
if not errorlevel 1 goto :service_ok
echo.
echo   [X] SQL Server service "%SQL_SERVICE%" is not running and could not be started.
echo       - Install SQL Server Express (instance name SQLEXPRESS), or
echo       - Start it manually: open "Services" ^> "SQL Server (SQLEXPRESS)" ^> Start,
echo         or run this file again as Administrator.
exit /b 1

:service_ok
echo       OK
echo [2/4] Checking login "%DB_USER%" ...
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -b -h -1 -Q "SET NOCOUNT ON; SELECT 1" >nul 2>&1
if not errorlevel 1 goto :login_ok

echo       Login failed - trying to repair it through Windows authentication ...
sqlcmd -S "%DB_INSTANCE%" -E %SQLTRUST% -b -h -1 -Q "SET NOCOUNT ON; SELECT 1" >nul 2>&1
if errorlevel 1 goto :no_windows_auth

set "WINONLY=0"
for /f "usebackq delims= " %%m in (`sqlcmd -S "%DB_INSTANCE%" -E %SQLTRUST% -h -1 -W -Q "SET NOCOUNT ON; SELECT CAST(SERVERPROPERTY('IsIntegratedSecurityOnly') AS INT)" 2^>nul`) do set "WINONLY=%%m"
if "%WINONLY%"=="1" goto :windows_only

sqlcmd -S "%DB_INSTANCE%" -E %SQLTRUST% -b -Q "ALTER LOGIN %DB_USER% ENABLE; ALTER LOGIN %DB_USER% WITH PASSWORD=N'%DB_PASSWORD%', CHECK_POLICY=OFF;" >nul 2>&1
if errorlevel 1 goto :alter_failed
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -b -h -1 -Q "SET NOCOUNT ON; SELECT 1" >nul 2>&1
if errorlevel 1 goto :alter_failed
echo       Enabled login "%DB_USER%" and set the configured password.

:login_ok
echo       OK
echo [3/4] Detecting SQL Server TCP port ...
set "DB_PORT=1433"
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0detect-sql-port.ps1"`) do set "DB_PORT=%%p"
sqlcmd -S "tcp:%DB_HOST%,%DB_PORT%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -b -h -1 -Q "SET NOCOUNT ON; SELECT 1" >nul 2>&1
if not errorlevel 1 goto :tcp_ok
echo.
echo   [X] SQL Server is not reachable over TCP/IP on port %DB_PORT%. The Java backend needs TCP/IP.
echo       Fix once: open "SQL Server Configuration Manager" ^> SQL Server Network Configuration
echo       ^> Protocols for SQLEXPRESS ^> TCP/IP = Enabled ^> Properties ^> IP Addresses ^> IPAll:
echo       clear "TCP Dynamic Ports", set "TCP Port" = 1433, then restart the SQL Server (SQLEXPRESS) service.
exit /b 1

:tcp_ok
echo       OK - port %DB_PORT%
echo [4/4] SQL Server is ready.
exit /b 0

:no_windows_auth
echo.
echo   [X] Cannot log in to SQL Server as "%DB_USER%" (password "%DB_PASSWORD%"), and Windows authentication is not
echo       available for your account, so the login could not be repaired automatically.
echo       Fix once in SQL Server Management Studio (connect with Windows Authentication):
echo         1. Server Properties ^> Security ^> "SQL Server and Windows Authentication mode" ^> OK, restart the service.
echo         2. Security ^> Logins ^> sa ^> Properties: set password to  %DB_PASSWORD%  and Status ^> Login: Enabled.
echo       Or run this in a query window:
echo         ALTER LOGIN sa ENABLE; ALTER LOGIN sa WITH PASSWORD=N'%DB_PASSWORD%', CHECK_POLICY=OFF;
exit /b 1

:windows_only
echo.
echo   [X] SQL Server is set to "Windows Authentication mode only", so the "sa" login cannot be used.
echo       Fix once in SQL Server Management Studio: right-click the server ^> Properties ^> Security ^>
echo       "SQL Server and Windows Authentication mode" ^> OK, then restart the "SQL Server (SQLEXPRESS)" service
echo       and run this script again (it will then enable "sa" automatically).
exit /b 1

:alter_failed
echo.
echo   [X] Could not enable/repair the "%DB_USER%" login automatically (your Windows account may lack sysadmin rights).
echo       Run in SSMS:  ALTER LOGIN sa ENABLE; ALTER LOGIN sa WITH PASSWORD=N'%DB_PASSWORD%', CHECK_POLICY=OFF;
exit /b 1
