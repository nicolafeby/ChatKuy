@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_through_fvm.ps1"

if errorlevel 1 (
    echo.
    echo Setup through FVM failed.
    exit /b %errorlevel%
)

echo.
echo Setup through FVM completed.
