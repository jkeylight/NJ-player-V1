@echo off
rem NJ Player GUI - double-click to open the launcher.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0NJ-Player-GUI.ps1"
