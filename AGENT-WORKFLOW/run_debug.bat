@echo off
cd /d "%~dp0"
"%~dp0..\backend\main_api\venv\Scripts\python.exe" "%~dp0debug_django.py" 2>&1
