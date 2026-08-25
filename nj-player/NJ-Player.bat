@echo off
rem NJ Player - drag a video file onto this to play, or double-click and drop.
rem Uses the GUI script for single file playback with enhancement presets.
cd /d "%~dp0"

rem If a file was dropped, play it directly
if not "%~1"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0NJ-Player-GUI-v2.ps1" -FilePath "%~1"
) else (
    rem No file provided - fall back to basic mpv with force-window
    start "" "%~dp0mpv\mpv.exe" --config-dir="%~dp0." --force-window=yes
)
