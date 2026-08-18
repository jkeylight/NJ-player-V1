<#
.SYNOPSIS
    Wipe NJ Player's history: resume positions and the remembered
    last folder. Your Library downloads, thumbnails and settings are kept.

    Invoked by the right-click menu item "Clear NJ Player History"
    (registered by associate.ps1). Can also be run by hand:
        powershell -ExecutionPolicy Bypass -File clear-history.ps1
#>

$Root = Split-Path -Parent $MyInvocation.MyCommand.Definition

Add-Type -AssemblyName System.Windows.Forms

$msg = "Clear NJ Player history?" + [Environment]::NewLine + [Environment]::NewLine +
       "This removes:" + [Environment]::NewLine +
       "- Resume positions (videos start from the beginning)" + [Environment]::NewLine +
       "- The remembered last folder" + [Environment]::NewLine + [Environment]::NewLine +
       "Your downloaded videos in the Library are kept."
$res = [System.Windows.Forms.MessageBox]::Show($msg, "NJ Player - Clear History",
    [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { exit 0 }

# Playback resume history: project location + legacy system location
$wl = Join-Path $Root "watch_later"
if (Test-Path $wl) { Remove-Item $wl -Recurse -Force }
$sysWl = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "mpv\watch_later"
if (Test-Path $sysWl) { Remove-Item $sysWl -Recurse -Force }

# Remembered last folder
Remove-Item (Join-Path $Root ".last-folder.txt") -Force -ErrorAction SilentlyContinue

[System.Windows.Forms.MessageBox]::Show("NJ Player history cleared." + [Environment]::NewLine +
    "Resume positions and the remembered folder were removed.",
    "NJ Player", [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
exit 0
