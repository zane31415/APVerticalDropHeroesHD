@echo off
REM One-click patcher. Sits in the game folder alongside data.win.
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo.
  echo Python was not found.
  echo Install it from https://www.python.org/downloads/ and be sure to tick
  echo "Add python.exe to PATH" during setup, then run this again.
  echo.
  pause
  exit /b 1
)

python build\build.py
echo.
pause
