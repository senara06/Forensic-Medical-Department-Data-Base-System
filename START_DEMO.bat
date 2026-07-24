@echo off
title ForensicDB - Lecturer Demonstration Launcher
color 0A
cls
echo ============================================================
echo   FORENSICDB - LECTURER DEMONSTRATION LAUNCHER
echo ============================================================
echo.
echo Installing required Python packages (if missing)...
pip install -r requirements.txt reportlab
echo.
echo Running automated database configuration script...
python setup_demo.py
pause
