@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title ShopSphere - Setup
echo ==========================================================
echo   ShopSphere - one-time setup
echo ==========================================================
echo.
call "%~dp0config.bat"

echo [Step 1/6] Checking required software
set "MISSING="
java -version >nul 2>&1
if errorlevel 1 ( echo   [X] Java not found - install JDK 17 or newer and add it to PATH ^(https://adoptium.net^) & set "MISSING=1" ) else (
    set "JV="
    for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do if not defined JV set "JV=%%~v"
    echo   [OK] Java !JV!
    echo !JV! | findstr /R /C:"^1[7-9]\." /C:"^[2-9][0-9]\." /C:"^1[7-9]$" /C:"^[2-9][0-9]$" >nul || ( echo   [X] Java 17 or newer is required & set "MISSING=1" )
)
call mvn -v >nul 2>&1
if errorlevel 1 ( echo   [X] Maven not found - install Apache Maven 3.8+ and add it to PATH ^(https://maven.apache.org^) & set "MISSING=1" ) else ( echo   [OK] Maven )
node -v >nul 2>&1
if errorlevel 1 ( echo   [X] Node.js not found - install Node.js 18 or newer ^(https://nodejs.org^) & set "MISSING=1" ) else ( for /f %%v in ('node -v') do echo   [OK] Node.js %%v )
call npm -v >nul 2>&1
if errorlevel 1 ( echo   [X] npm not found - it is installed together with Node.js & set "MISSING=1" ) else ( echo   [OK] npm )
sqlcmd -? >nul 2>&1
if errorlevel 1 ( echo   [X] sqlcmd not found - install "SQL Server Command Line Utilities" or SSMS & set "MISSING=1" ) else ( echo   [OK] sqlcmd )
if defined MISSING goto :fail

echo.
echo [Step 2/6] Product images
set "IMGCOUNT=0"
for %%f in ("%IMAGES_DIR%\*.jpg") do set /a IMGCOUNT+=1
if !IMGCOUNT! LSS 24 ( echo   [!] Only !IMGCOUNT! images found in images\products - some products will show a placeholder. ) else ( echo   [OK] !IMGCOUNT! product images found )

echo.
echo [Step 3/6] SQL Server
call "%~dp0scripts\ensure-sql.bat"
if errorlevel 1 goto :fail

echo.
echo [Step 4/6] Creating database, tables and demo data
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -I -b -i "%ROOT%\database\01_schema.sql"
if errorlevel 1 ( echo   [X] Running database\01_schema.sql failed - see the message above. & goto :fail )
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -I -b -i "%ROOT%\database\02_seed.sql"
if errorlevel 1 ( echo   [X] Running database\02_seed.sql failed - see the message above. & goto :fail )
echo   [OK] Database %DB_NAME% is ready

echo.
echo [Step 5/6] Building the backend ^(Maven - the first run downloads libraries, please wait^)
pushd "%ROOT%\backend"
call mvn -q -B -DskipTests clean package
if errorlevel 1 ( popd & echo   [X] Backend build failed - see the Maven messages above. & goto :fail )
popd
if not exist "%ROOT%\backend\target\shopsphere-backend.jar" ( echo   [X] Backend jar was not produced. & goto :fail )
echo   [OK] Backend built

echo.
echo [Step 6/6] Installing frontend packages ^(npm^)
pushd "%ROOT%\frontend"
call npm install --no-audit --no-fund
if errorlevel 1 ( popd & echo   [X] npm install failed - check your internet connection. & goto :fail )
popd
echo   [OK] Frontend packages installed

echo.
echo ==========================================================
echo   Setup complete!
echo ==========================================================
echo   Next: double-click START.bat
echo   Demo accounts ^(password for all: Demo@123^):
echo     admin@shopsphere.lk      ^(Admin^)
echo     staff@shopsphere.lk      ^(Staff^)
echo     warehouse@shopsphere.lk  ^(Warehouse^)
echo     delivery@shopsphere.lk   ^(Delivery^)
echo     customer@shopsphere.lk   ^(Customer^)
echo.
if not defined NOPAUSE pause
exit /b 0

:fail
echo.
echo ==========================================================
echo   Setup did not finish - fix the problem above and run SETUP.bat again.
echo ==========================================================
if not defined NOPAUSE pause
exit /b 1
