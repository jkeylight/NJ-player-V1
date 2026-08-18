<#
.SYNOPSIS
    NJ Player installer — sets up a portable, offline video player with
    GPU-accelerated enhancement shaders ("better Lucid Mode", no AI).

.DESCRIPTION
    Downloads a portable mpv build and the enhancement shaders into this
    folder, then creates the NJ-Player.bat launcher. Everything stays
    inside this project folder — nothing is installed system-wide and no
    administrator rights are needed.

    Usage:  powershell -ExecutionPolicy Bypass -File install.ps1
    Re-run: powershell -ExecutionPolicy Bypass -File install.ps1 -Force
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MpvDir    = Join-Path $Root "mpv"
$ShaderDir = Join-Path $Root "shaders"

# ---------------------------------------------------------------------------
# Download sources (verified Aug 2026)
# ---------------------------------------------------------------------------
$MpvUrl = "https://github.com/mpv-player/mpv/releases/download/v0.41.0/mpv-v0.41.0-x86_64-pc-windows-msvc.zip"

$Shaders = [ordered]@{
    "adaptive-sharpen.glsl"          = "https://gist.githubusercontent.com/igv/8a77e4eb8276753b54bb94c1c50c317e/raw/f496fcc10f7e9602ff9fd12f6ab4930ffb3ac470/adaptive-sharpen.glsl"
    "KrigBilateral.glsl"             = "https://gist.githubusercontent.com/igv/a015fc885d5c22e6891820ad89555637/raw/d7f39734d6aff4c0989f32a4530b1b010e64bda3/KrigBilateral.glsl"
    "SSimSuperRes.glsl"              = "https://gist.githubusercontent.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b/raw/a8feaac97835c211fa3ebcabf90db149a254187b/SSimSuperRes.glsl"
    "FSRCNNX_x2_16-0-4-1.glsl"       = "https://raw.githubusercontent.com/awused/dotfiles/master/mpv/.config/mpv/shaders/fsrcnnx/FSRCNNX_x2_16-0-4-1.glsl"
    "Anime4K_Restore_CNN_Soft_M.glsl" = "https://raw.githubusercontent.com/bloc97/Anime4K/master/glsl/Restore/Anime4K_Restore_CNN_Soft_M.glsl"
    "Anime4K_Upscale_CNN_x2_M.glsl"  = "https://raw.githubusercontent.com/bloc97/Anime4K/master/glsl/Upscale/Anime4K_Upscale_CNN_x2_M.glsl"
}

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Download($url, $dest) {
    if ((Test-Path $dest) -and -not $Force) { Write-Ok "exists: $(Split-Path $dest -Leaf)"; return }
    Write-Host "    downloading $(Split-Path $dest -Leaf) ..."
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    if ((Get-Item $dest).Length -lt 1000) { throw "Downloaded file too small: $dest" }
}

Write-Host ""
Write-Host "  ===============================" -ForegroundColor Magenta
Write-Host "   NJ PLAYER installer" -ForegroundColor Magenta
Write-Host "  ===============================" -ForegroundColor Magenta

# ---------------------------------------------------------------------------
# 1. Portable mpv
# ---------------------------------------------------------------------------
if ((Test-Path (Join-Path $MpvDir "mpv.exe")) -and -not $Force) {
    Write-Step "mpv already installed, skipping"
} else {
    Write-Step "Downloading portable mpv ..."
    $zip = Join-Path $Root "mpv.zip"
    $tmp = Join-Path $Root ".mpv-tmp"
    Download $MpvUrl $zip

    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    Remove-Item $zip -Force

    $mpvExe = Get-ChildItem -Path $tmp -Recurse -Filter "mpv.exe" | Select-Object -First 1
    if (-not $mpvExe) { throw "mpv.exe not found inside the downloaded archive" }

    if (Test-Path $MpvDir) { Remove-Item $MpvDir -Recurse -Force }
    New-Item -ItemType Directory -Path $MpvDir | Out-Null
    Copy-Item -Path (Join-Path $mpvExe.DirectoryName "*") -Destination $MpvDir -Recurse -Force
    Remove-Item $tmp -Recurse -Force
    Write-Ok "mpv installed to $MpvDir"
}

# ---------------------------------------------------------------------------
# 2. yt-dlp (plays website & live-stream links - YouTube, Twitch, m3u8 ...)
# ---------------------------------------------------------------------------
$YtDlp = Join-Path $MpvDir "yt-dlp.exe"
if ((Test-Path $YtDlp) -and -not $Force) {
    Write-Step "yt-dlp already installed, skipping"
} else {
    Write-Step "Downloading yt-dlp (for website / live-stream links) ..."
    Download "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" $YtDlp
    try { Write-Ok "yt-dlp $(& $YtDlp --version 2>&1 | Select-Object -First 1)" } catch { }
}

# ---------------------------------------------------------------------------
# 3. ffmpeg (merges 1080p video + audio for FULL HD downloads)
# ---------------------------------------------------------------------------
$FfmpegZip  = Join-Path $Root "ffmpeg.zip"
$FfmpegExe  = Join-Path $MpvDir "ffmpeg.exe"
$FfprobeExe = Join-Path $MpvDir "ffprobe.exe"
if ((Test-Path $FfmpegExe) -and -not $Force) {
    Write-Step "ffmpeg already installed, skipping"
} else {
    Write-Step "Downloading ffmpeg (for 1080p video+audio merging) ..."
    Download "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" $FfmpegZip
    $ffTmp = Join-Path $Root ".ffmpeg-tmp"
    if (Test-Path $ffTmp) { Remove-Item $ffTmp -Recurse -Force }
    New-Item -ItemType Directory -Path $ffTmp | Out-Null
    Expand-Archive -Path $FfmpegZip -DestinationPath $ffTmp -Force
    Remove-Item $FfmpegZip -Force
    $ffBin = Get-ChildItem -Path $ffTmp -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    if (-not $ffBin) { throw "ffmpeg.exe not found inside the downloaded archive" }
    Copy-Item -Path (Join-Path $ffBin.DirectoryName "ffmpeg.exe") -Destination $MpvDir -Force
    Copy-Item -Path (Join-Path $ffBin.DirectoryName "ffprobe.exe") -Destination $MpvDir -Force
    Remove-Item $ffTmp -Recurse -Force
    Write-Ok "ffmpeg + ffprobe installed"
}

# ---------------------------------------------------------------------------
# 4. Enhancement shaders
# ---------------------------------------------------------------------------
Write-Step "Downloading enhancement shaders ..."
New-Item -ItemType Directory -Path $ShaderDir -Force | Out-Null
foreach ($name in $Shaders.Keys) {
    Download $Shaders[$name] (Join-Path $ShaderDir $name)
}
Write-Ok "$($Shaders.Count) shaders installed"

# ---------------------------------------------------------------------------
# 5. Launcher
# ---------------------------------------------------------------------------
Write-Step "Creating NJ-Player.bat launcher ..."
$bat = @"
@echo off
rem NJ Player - drag a video file onto this to play, or double-click and drop.
rem The "%~dp0." form avoids a trailing backslash that would break the quote.
cd /d "%~dp0"
start "" "%~dp0mpv\mpv.exe" --config-dir="%~dp0." --force-window=yes %*
"@
$batPath = Join-Path $Root "NJ-Player.bat"
# Ensure CRLF line endings (Windows CMD expects them; LF-only can cause
# the batch file to be silently ignored or mis-parsed on some systems).
$batContent = $bat -replace "`r`n", "`n" -replace "`n", "`r`n"
[System.IO.File]::WriteAllText($batPath, $batContent, [System.Text.Encoding]::ASCII)
Write-Ok "launcher created: $batPath"

# ---------------------------------------------------------------------------
# 6. Verify
# ---------------------------------------------------------------------------
Write-Step "Verifying installation ..."
$mpv = Join-Path $MpvDir "mpv.exe"
if (-not (Test-Path $mpv)) { throw "mpv.exe missing after install" }
$version = & $mpv --version 2>&1 | Select-Object -First 1
Write-Ok "$version"
Write-Ok "shaders: $((Get-ChildItem $ShaderDir -Filter *.glsl).Count) .glsl files in $ShaderDir"
if (Test-Path $YtDlp) { Write-Ok "yt-dlp: installed (website/live-stream links)" }
if (Test-Path $FfmpegExe) { Write-Ok "ffmpeg: installed (FULL HD 1080p downloads)" }

Write-Host ""
Write-Host "  NJ Player is ready!" -ForegroundColor Green
Write-Host "  Play a video:   drag it onto NJ-Player.bat"
Write-Host "  Or browse:      double-click NJ-Player-GUI.bat"
Write-Host "  Play a link:    paste a YouTube/Twitch/stream URL in the"
Write-Host "                  GUI's 'Play Link' box (needs internet)"
Write-Host "  Full HD save:   the Download button saves 1080p MP4s"
Write-Host "                  into the Library for offline watching"
Write-Host "  Enhancements:   F9 cycles presets, CTRL+0..3 pick one"
Write-Host "  Optional:       run associate.ps1 to add right-click"
Write-Host "                  'Open with NJ Player' to Windows"
Write-Host "  Optional:       run desktop-shortcut.ps1 to put an"
Write-Host "                  'NJ Player' icon on your Desktop"
Write-Host "  (See README.md for the full hotkey list)"
Write-Host ""
