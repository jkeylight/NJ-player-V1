@echo off
rem NJ Player - drag a video file onto this to play, or double-click and drop.
rem The "%~dp0." form avoids a trailing backslash that would break the quote.
cd /d "%~dp0"
start "" "%~dp0mpv\mpv.exe" --config-dir="%~dp0." --force-window=yes %*
