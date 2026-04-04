@echo off
cd /d "%~dp0..\backend\main_api"
"%~dp0..\backend\main_api\venv\Scripts\python.exe" manage.py showmigrations api 2>&1
