<#
.SYNOPSIS
    Create (or remove) the "NJ Player" desktop shortcut.

.DESCRIPTION
    Adds a shortcut on your Desktop that launches the NJ Player GUI
    (NJ-Player-GUI.bat). It uses the mpv icon, the same one as the
    right-click menu. Per-user only - no admin needed.

    Usage:
        Create:  powershell -ExecutionPolicy Bypass -File desktop-shortcut.ps1
        Remove:  powershell -ExecutionPolicy Bypass -File desktop-shortcut.ps1 -Remove

    Note: if you move the nj-player folder, re-run this script so the
    shortcut points at the new location.
#>
param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

$Root     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Launcher = Join-Path $Root "NJ-Player-GUI.bat"
$MpvExe   = Join-Path $Root "mpv\mpv.exe"
$CustomIco = Join-Path $Root "nj-player.ico"
$Desktop  = [Environment]::GetFolderPath("Desktop")
$Shortcut = Join-Path $Desktop "NJ Player.lnk"

if (-not (Test-Path $Launcher)) {
    Write-Host "ERROR: launcher not found at $Launcher" -ForegroundColor Red
    Write-Host "Run install.ps1 first (see README)." -ForegroundColor Red
    exit 1
}

$ws = New-Object -ComObject WScript.Shell

if ($Remove) {
    if (Test-Path $Shortcut) {
        Remove-Item $Shortcut -Force
        Write-Host "  [ok] desktop shortcut removed" -ForegroundColor Green
    } else {
        Write-Host "  no shortcut found to remove" -ForegroundColor Yellow
    }
    exit 0
}

# Use the custom NJ Player logo when it exists, otherwise the mpv icon.
if (Test-Path $CustomIco) {
    $IconLoc = $CustomIco
} else {
    $IconLoc = '"' + $MpvExe + ',0"'
}

$sc = $ws.CreateShortcut($Shortcut)
$sc.TargetPath       = $Launcher
$sc.WorkingDirectory = $Root
$sc.IconLocation     = $IconLoc
$sc.Description      = "NJ Player - open videos with the launcher GUI"
$sc.Save()

Write-Host ""
Write-Host "  NJ Player - desktop shortcut" -ForegroundColor Magenta
Write-Host "  [ok] created: $Shortcut" -ForegroundColor Green
Write-Host "  To remove:  powershell -ExecutionPolicy Bypass -File desktop-shortcut.ps1 -Remove"
Write-Host ""
