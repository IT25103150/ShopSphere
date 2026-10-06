@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title ShopSphere - Reset database
echo ==========================================================
echo   Reset ShopSphere database to the original demo data
echo ==========================================================
call "%~dp0config.bat"
echo.
echo   WARNING: this DELETES the database %DB_NAME% ^(all orders, users, products,
echo   stock changes...^) and recreates it with the original seed data.
echo   Product images you uploaded from the admin screen are removed too.
echo.
if /i not "%RESET_CONFIRM%"=="yes" (
    set /p "CONFIRM=  Type yes to continue: "
    if /i not "!CONFIRM!"=="yes" (
        echo   Cancelled - nothing was changed.
        if not defined NOPAUSE pause
        exit /b 0
    )
)

echo.
call "%~dp0scripts\ensure-sql.bat"
if errorlevel 1 goto :fail

echo.
echo Dropping database %DB_NAME% ...
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -b -Q "IF DB_ID(N'%DB_NAME%') IS NOT NULL BEGIN ALTER DATABASE [%DB_NAME%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [%DB_NAME%]; END"
if errorlevel 1 ( echo   [X] Could not drop the database. & goto :fail )

echo Creating tables ...
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -I -b -i "%ROOT%\database\01_schema.sql"
if errorlevel 1 ( echo   [X] Schema script failed. & goto :fail )

echo Inserting demo data ...
sqlcmd -S "%DB_INSTANCE%" -U %DB_USER% -P "%DB_PASSWORD%" %SQLTRUST% -I -b -i "%ROOT%\database\02_seed.sql"
if errorlevel 1 ( echo   [X] Seed script failed. & goto :fail )

del /q "%IMAGES_DIR%\upload-*" >nul 2>&1

echo.
echo ==========================================================
echo   Database reset complete - original seed data restored.
echo   If ShopSphere is running you can simply refresh the browser.
echo ==========================================================
if not defined NOPAUSE pause
exit /b 0

:fail
echo.
echo   Reset failed - fix the problem above and run RESET_DATABASE.bat again.
if not defined NOPAUSE pause
exit /b 1
