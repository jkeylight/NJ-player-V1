<#
.SYNOPSIS
    Register "Open with NJ Player" in the Windows right-click menu.

.DESCRIPTION
    Adds a per-user (no admin needed) registry entry so every file's
    right-click menu shows "Open with NJ Player", and NJ Player appears
    in the "Open with" dialog for video files. Nothing is written
    outside HKCU\Software\Classes, so it is fully reversible.

    Uses the .NET Registry API (Microsoft.Win32.Registry) because the
    PowerShell registry provider treats "*" as a wildcard.

    Usage:
        Register:  powershell -ExecutionPolicy Bypass -File associate.ps1
        Uninstall: powershell -ExecutionPolicy Bypass -File associate.ps1 -Remove

    Note: if you move the nj-player folder, re-run this script so the
    registered path points at the new location.
#>
param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

$Root          = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MpvExe        = Join-Path $Root "mpv\mpv.exe"
$ConfigDir     = ($Root.TrimEnd("\") -replace "\\", "/")
$ProgIdName    = "NJPlayer.Video"
$Label         = "Open with NJ Player"
$ClearLabel    = "Clear NJ Player History"
$NjIco         = Join-Path $Root "nj-player.ico"
$Icon          = '"' + $NjIco + '"'
$OpenCommand   = '"' + $MpvExe + '" --config-dir=' + $ConfigDir + ' --force-window=yes "%1"'
$ClearScript   = Join-Path $Root "clear-history.ps1"
$ClearCommand  = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $ClearScript + '"'

$VideoExtensions = @(
    ".mp4", ".mkv", ".avi", ".webm", ".mov", ".m4v",
    ".flv", ".wmv", ".mpg", ".mpeg", ".ts", ".3gp", ".ogv", ".divx"
)

if (-not (Test-Path $MpvExe)) {
    Write-Host "ERROR: mpv not found at $MpvExe" -ForegroundColor Red
    Write-Host "Run install.ps1 first (see README)." -ForegroundColor Red
    exit 1
}

$classes = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Classes", $true)
if (-not $classes) { $classes = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Classes") }

# ------------------------------------------------------------
# Uninstall
# ------------------------------------------------------------
if ($Remove) {
    try { $classes.DeleteSubKeyTree($ProgIdName, $false); Write-Host "  [ok] removed app identity" -ForegroundColor Green } catch { }
    try { $classes.DeleteSubKeyTree("*\shell\" + $Label, $false); Write-Host "  [ok] removed right-click menu item" -ForegroundColor Green } catch { }
    try { $classes.DeleteSubKeyTree("*\shell\" + $ClearLabel, $false); Write-Host "  [ok] removed right-click Clear History item" -ForegroundColor Green } catch { }
    foreach ($ext in $VideoExtensions) {
        $k = $classes.OpenSubKey($ext + "\OpenWithProgIds", $true)
        if ($k) {
            if ($k.GetValueNames() -contains $ProgIdName) { $k.DeleteValue($ProgIdName, $false) }
            $k.Close()
        }
    }
    Write-Host "  [ok] removed 'Open with' entries for video types" -ForegroundColor Green
    $classes.Close()
    Write-Host ""
    Write-Host "NJ Player file associations removed." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "  NJ Player - file associations" -ForegroundColor Magenta
Write-Host "  Registering 'Open with NJ Player' for the current user only..." -ForegroundColor Cyan

# ------------------------------------------------------------
# 1. App identity (ProgID) - used by the "Open with" dialog
# ------------------------------------------------------------
$progIdKey = $classes.CreateSubKey($ProgIdName)
$progIdKey.SetValue("", "NJ Player Video")
$progIdKey.SetValue("FriendlyAppName", "NJ Player")
$progIdKey.CreateSubKey("DefaultIcon").SetValue("", $Icon)
$progIdKey.CreateSubKey("shell\open\command").SetValue("", $OpenCommand)
$progIdKey.Close()
Write-Host "  [ok] app identity registered" -ForegroundColor Green

# ------------------------------------------------------------
# 2. Right-click menu on every file (mpv also plays audio, so this
#    covers both video and audio files - handy bonus).
# ------------------------------------------------------------
$verb = $classes.CreateSubKey("*\shell\" + $Label)
$verb.SetValue("MUIVerb", $Label)
$verb.SetValue("Icon", $Icon)
$verb.CreateSubKey("command").SetValue("", $OpenCommand)
$verb.Close()
Write-Host "  [ok] right-click menu item added" -ForegroundColor Green

# ------------------------------------------------------------
# 2b. "Clear NJ Player History" - wipes resume positions and the
#     remembered folder without opening the GUI (clear-history.ps1)
# ------------------------------------------------------------
$clearVerb = $classes.CreateSubKey("*\shell\" + $ClearLabel)
$clearVerb.SetValue("MUIVerb", $ClearLabel)
$clearVerb.SetValue("Icon", $Icon)
$clearVerb.CreateSubKey("command").SetValue("", $ClearCommand)
$clearVerb.Close()
Write-Host "  [ok] right-click Clear History item added" -ForegroundColor Green

# ------------------------------------------------------------
# 3. List NJ Player in the "Open with" dialog for video files
# ------------------------------------------------------------
foreach ($ext in $VideoExtensions) {
    $k = $classes.CreateSubKey($ext + "\OpenWithProgIds")
    $k.SetValue($ProgIdName, "")
    $k.Close()
}
Write-Host "  [ok] NJ Player added to 'Open with' for $($VideoExtensions.Count) video types" -ForegroundColor Green

$classes.Close()

Write-Host ""
Write-Host "  Done. Right-click any video -> 'Open with NJ Player'." -ForegroundColor Green
Write-Host "  (If the menu item doesn't show up, restart File Explorer.)"
Write-Host "  To undo:  powershell -ExecutionPolicy Bypass -File associate.ps1 -Remove"
Write-Host ""
