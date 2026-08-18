# ============================================================
#  NJ PLAYER - launcher GUI v2
#  "Cinematic Dark Luxury" redesign
#  Based on DESIGN-SYSTEM.md — every pixel is a first draft
#
#  Launch:  double-click NJ-Player-GUI.bat
# ============================================================

param([switch]$SelfTest)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#  DESIGN TOKENS (from DESIGN-SYSTEM.md)
# ============================================================

# Core Colors — The Void
$INK          = [System.Drawing.Color]::FromArgb(255, 10, 10, 10)
$SURFACE      = [System.Drawing.Color]::FromArgb(255, 18, 18, 21)
$SURFACE_ELEV = [System.Drawing.Color]::FromArgb(255, 26, 26, 31)
$SURFACE_HVR  = [System.Drawing.Color]::FromArgb(255, 34, 34, 40)

# Text
$TEXT_PRIMARY   = [System.Drawing.Color]::FromArgb(255, 232, 230, 227)
$TEXT_SECONDARY = [System.Drawing.Color]::FromArgb(255, 138, 138, 143)
$TEXT_TERTIARY  = [System.Drawing.Color]::FromArgb(255, 74, 74, 82)

# Accent — Electric Cyan (the soul)
$ACCENT      = [System.Drawing.Color]::FromArgb(255, 0, 212, 255)
$ACCENT_DIM  = [System.Drawing.Color]::FromArgb(180, 0, 212, 255)
$ACCENT_GLOW = [System.Drawing.Color]::FromArgb(40, 0, 212, 255)

# Signals
$SUCCESS = [System.Drawing.Color]::FromArgb(255, 0, 255, 136)
$WARNING = [System.Drawing.Color]::FromArgb(255, 255, 184, 0)
$ERR     = [System.Drawing.Color]::FromArgb(255, 255, 59, 92)

# Borders
$BORDER      = [System.Drawing.Color]::FromArgb(255, 20, 20, 24)
$BORDER_HVR  = [System.Drawing.Color]::FromArgb(255, 40, 40, 48)

# ============================================================
#  PATHS
# ============================================================
$Root        = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MpvExe      = Join-Path $Root "mpv\mpv.exe"
$ConfigDir   = ($Root -replace "\\", "/")
$LastFolderFile = Join-Path $Root ".last-folder.txt"
$ThumbDir    = Join-Path $Root ".thumbs"
$LibraryDir  = Join-Path $Root "library"
$YtDlp       = Join-Path $Root "mpv\yt-dlp.exe"

$VideoExtensions = @(
    ".mp4", ".mkv", ".avi", ".webm", ".mov", ".m4v",
    ".flv", ".wmv", ".mpg", ".mpeg", ".ts", ".3gp", ".ogv", ".divx"
)

$Presets = @(
    @{ Name = "OFF";       Profile = "nj-clean";  Icon = [char]0x25CB },
    @{ Name = "LUCID";     Profile = "nj-lucid";  Icon = [char]0x25C9 },
    @{ Name = "CINEMA";    Profile = "nj-cinema"; Icon = [char]0x25CE },
    @{ Name = "ANIME";     Profile = "nj-anime";  Icon = [char]0x25C8 }
)

# Common folder shortcuts
$DownloadsPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
$VideosPath    = [Environment]::GetFolderPath("MyVideos")
$DesktopPath   = [Environment]::GetFolderPath("Desktop")
$LibraryPath   = $LibraryDir

# Initialize directories
if (-not (Test-Path $LibraryDir)) { New-Item -ItemType Directory -Path $LibraryDir | Out-Null }
if (-not (Test-Path $ThumbDir)) { New-Item -ItemType Directory -Path $ThumbDir | Out-Null }
$thumbCount = @(Get-ChildItem -Path $ThumbDir -Filter *.jpg -ErrorAction SilentlyContinue).Count
if ($thumbCount -gt 200) {
    Get-ChildItem -Path $ThumbDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}

# ============================================================
#  ANIMATION ENGINE
# ============================================================
$script:Animations = @()

function Start-Animation {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Property,
        [int]$TargetValue,
        [int]$DurationMs = 300,
        [int]$StartDelay = 0
    )
    $script:Animations += @{
        Control = $Control
        Property = $Property
        StartValue = $Control.$Property
        TargetValue = $TargetValue
        Duration = $DurationMs
        Delay = $StartDelay
        StartTime = [DateTime]::Now.AddMilliseconds($StartDelay)
    }
}

function Update-Animations {
    $now = [DateTime]::Now
    $completed = @()
    
    foreach ($anim in $script:Animations) {
        $elapsed = ($now - $anim.StartTime).TotalMilliseconds
        if ($elapsed -lt 0) { continue }
        
        $progress = [Math]::Min(1.0, $elapsed / $anim.Duration)
        # ease-out-expo
        $t = 1 - [Math]::Pow(1 - $progress, 4)
        
        $current = [int]($anim.StartValue + ($anim.TargetValue - $anim.StartValue) * $t)
        
        try {
            $anim.Control.($anim.Property) = $current
        } catch { }
        
        if ($progress -ge 1.0) {
            $completed += $anim
        }
    }
    
    foreach ($c in $completed) {
        $script:Animations = $script:Animations | Where-Object { $_ -ne $c }
    }
}

# ============================================================
#  PLATFORM CONTROLS (Custom Drawn)
# ============================================================

# --- Custom Panel with grain overlay ---
function New-GrainPanel {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($W, $H)
    $panel.BackColor = $SURFACE
    $panel.ForeColor = $TEXT_PRIMARY
    $panel.BorderStyle = "None"
    
    # Custom paint for grain
    $panel.Add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Subtle grain effect using random dots
        $rng = New-Object System.Random(42)  # Fixed seed for consistency
        $brush = [System.Drawing.Brushes]::White
        for ($i = 0; $i -lt 50; $i++) {
            $x = $rng.Next(0, $s.Width)
            $y = $rng.Next(0, $s.Height)
            $g.FillRectangle($brush, $x, $y, 1, 1)
        }
    })
    
    return $panel
}

# --- Custom Button with hover effects ---
function New-NjButton {
    param(
        [string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H,
        [System.Drawing.Color]$BgColor = $SURFACE,
        [System.Drawing.Color]$TextColor = $TEXT_PRIMARY,
        [bool]$IsAccent = $false,
        [string]$Tooltip = ""
    )
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($W, $H)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $BgColor
    $btn.ForeColor = $TextColor
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Hover state tracking
    $btn.Tag = @{ BgColor = $BgColor; IsAccent = $IsAccent; Hovered = $false }
    
    $btn.Add_MouseEnter({
        $btn.Tag.Hovered = $true
        if ($btn.Tag.IsAccent) {
            $btn.BackColor = $ACCENT
            $btn.ForeColor = $INK
        } else {
            $btn.BackColor = $SURFACE_HVR
        }
        $btn.FlatAppearance.BorderColor = $ACCENT
    })
    
    $btn.Add_MouseLeave({
        $btn.Tag.Hovered = $false
        $btn.BackColor = $btn.Tag.BgColor
        if ($btn.Tag.IsAccent) {
            $btn.ForeColor = $INK
        } else {
            $btn.ForeColor = $TEXT_PRIMARY
        }
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::Transparent
    })
    
    if ($Tooltip) {
        $tip = New-Object System.Windows.Forms.ToolTip
        $tip.SetToolTip($btn, $Tooltip)
    }
    
    return $btn
}

# --- Custom ListBox with custom draw ---
function New-NjListBox {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    
    $list = New-Object System.Windows.Forms.ListBox
    $list.Location = New-Object System.Drawing.Point($X, $Y)
    $list.Size = New-Object System.Drawing.Size($W, $H)
    $list.BackColor = $SURFACE
    $list.ForeColor = $TEXT_PRIMARY
    $list.BorderStyle = "None"
    $list.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $list.HorizontalScrollbar = $true
    $list.IntegralHeight = $false
    $list.DrawMode = "OwnerDrawFixed"
    $list.ItemHeight = 36
    
    # Custom draw for items
    $list.Add_DrawItem({
        param($s, $e)
        
        if ($e.Index -lt 0) { return }
        
        $g = $e.Graphics
        $item = $s.Items[$e.Index]
        $isSelected = ($e.State -band [System.Windows.Forms.DrawItemState]::Selected)
        
        # Background
        $bgColor = if ($isSelected) { $SURFACE_HVR } else { $SURFACE }
        $bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
        $g.FillRectangle($bgBrush, $e.Bounds)
        $bgBrush.Dispose()
        
        # Selection indicator
        if ($isSelected) {
            $accentBrush = New-Object System.Drawing.SolidBrush($ACCENT)
            $g.FillRectangle($accentBrush, $e.Bounds.X, $e.Bounds.Y, 3, $e.Bounds.Height)
            $accentBrush.Dispose()
        }
        
        # Text
        $textColor = if ($isSelected) { $TEXT_PRIMARY } else { $TEXT_SECONDARY }
        $textBrush = New-Object System.Drawing.SolidBrush($textColor)
        $textFormat = [System.Drawing.StringFormat]::GenericVerticalCenter
        $textFormat.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
        
        $displayText = if ($item.Name) { $item.Name } else { $item.ToString() }
        $g.DrawString($displayText, $s.Font, $textBrush, ($e.Bounds.X + 10), $e.Bounds, $textFormat)
        $textBrush.Dispose()
        
        # Bottom border (subtle separator)
        $borderPen = New-Object System.Drawing.Pen($BORDER)
        $g.DrawLine($borderPen, $e.Bounds.X + 10, $e.Bounds.Bottom - 1, $e.Bounds.Right, $e.Bounds.Bottom - 1)
        $borderPen.Dispose()
    })
    
    return $list
}

# --- Custom ComboBox with custom draw ---
function New-NjComboBox {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    
    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.Location = New-Object System.Drawing.Point($X, $Y)
    $combo.Size = New-Object System.Drawing.Size($W, $H)
    $combo.BackColor = $SURFACE
    $combo.ForeColor = $TEXT_PRIMARY
    $combo.FlatStyle = "Flat"
    $combo.DropDownStyle = "DropDownList"
    $combo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $combo.DrawMode = "OwnerDrawFixed"
    $combo.ItemHeight = 28
    
    # Custom draw
    $combo.Add_DrawItem({
        param($s, $e)
        
        if ($e.Index -lt 0) { return }
        
        $g = $e.Graphics
        $isSelected = ($e.State -band [System.Windows.Forms.DrawItemState]::Selected)
        
        # Background
        $bgColor = if ($isSelected) { $SURFACE_HVR } else { $SURFACE }
        $bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
        $g.FillRectangle($bgBrush, $e.Bounds)
        $bgBrush.Dispose()
        
        # Text
        $textBrush = New-Object System.Drawing.SolidBrush($TEXT_PRIMARY)
        $g.DrawString($s.Items[$e.Index].ToString(), $s.Font, $textBrush, $e.Bounds.X + 8, $e.Bounds.Y + 4)
        $textBrush.Dispose()
    })
    
    return $combo
}

# ============================================================
#  HELPERS
# ============================================================

function Get-Videos([string]$dir, [bool]$recursive) {
    if (-not (Test-Path $dir)) { return @() }
    $params = @{ Path = $dir; File = $true; ErrorAction = "SilentlyContinue" }
    if ($recursive) { $params.Recurse = $true }
    Get-ChildItem @params |
        Where-Object { $VideoExtensions -contains $_.Extension.ToLower() } |
        Sort-Object FullName
}

function Get-RelativePath([string]$folder, [string]$fullPath) {
    if ($fullPath.StartsWith($folder, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $fullPath.Substring($folder.Length).TrimStart("\", "/")
        if ($rel) { return $rel }
    }
    return $fullPath
}

function Save-LastFolder([string]$dir) {
    try { Set-Content -Path $LastFolderFile -Value $dir -Encoding ASCII } catch { }
}

function Load-LastFolder() {
    try {
        if (Test-Path $LastFolderFile) {
            $f = (Get-Content $LastFolderFile -Raw).Trim()
            if (Test-Path $f) { return $f }
        }
    } catch { }
    if (Test-Path $DownloadsPath) { return $DownloadsPath }
    return $VideosPath
}

function Set-Status([string]$msg, [System.Drawing.Color]$color) {
    $statusLabel.Text = $msg
    $statusLabel.ForeColor = $color
}

function Set-Folder([string]$path) {
    if (-not (Test-Path $path)) {
        Set-Status ("Folder not available: " + $path) $WARNING
        return
    }
    $folderBox.Text = $path
    Save-LastFolder $path
    Refresh-VideoList
}

function Refresh-VideoList() {
    $folder = $folderBox.Text
    $videos = Get-Videos $folder $recursiveCheck.Checked
    $videoList.Items.Clear()
    foreach ($v in $videos) {
        $display = if ($recursiveCheck.Checked) { Get-RelativePath $folder $v.FullName } else { $v.Name }
        [void]$videoList.Items.Add([pscustomobject]@{ Name = $display; File = $v })
    }
    if ($videos.Count -eq 0) {
        Set-Status "No videos found" $TEXT_TERTIARY
    } else {
        Set-Status ("$($videos.Count) videos  |  Select and play") $TEXT_SECONDARY
    }
}

# ============================================================
#  PLAYLIST QUEUE
# ============================================================
$script:Playlist = [System.Collections.ArrayList]::new()

function Add-ToQueue($item) {
    $file = if ($item.File) { $item.File } else { $item }
    foreach ($existing in $script:Playlist) {
        if ($existing.FullName -ieq $file.FullName) {
            Set-Status "Already in queue" $WARNING
            return
        }
    }
    [void]$script:Playlist.Add($file)
    Refresh-QueueList
    Set-Status ("+" + $file.Name + "  ($($script:Playlist.Count) in queue)") $SUCCESS
}

function Remove-FromQueue {
    if (-not $queueList.SelectedItem) { return }
    $idx = $queueList.SelectedIndex
    $script:Playlist.RemoveAt($idx)
    Refresh-QueueList
    Set-Status "Removed from queue" $TEXT_SECONDARY
}

function Clear-Queue {
    $script:Playlist.Clear()
    Refresh-QueueList
    Set-Status "Queue cleared" $TEXT_SECONDARY
}

function Refresh-QueueList {
    $queueList.Items.Clear()
    $i = 1
    foreach ($f in $script:Playlist) {
        [void]$queueList.Items.Add([pscustomobject]@{ Name = "$i  $($f.Name)"; File = $f })
        $i++
    }
    $queueCountLabel.Text = "$($script:Playlist.Count)"
}

function Play-Queue {
    if ($script:Playlist.Count -eq 0) {
        Set-Status "Queue empty" $WARNING
        return
    }
    if (-not (Test-Path $MpvExe)) {
        Set-Status "mpv not found" $ERR
        return
    }
    $playlistFile = Join-Path $Root ".playlist.m3u"
    $lines = @("#EXTM3U")
    foreach ($f in $script:Playlist) { $lines += $f.FullName }
    $lines -join "`r`n" | Set-Content -Path $playlistFile -Encoding UTF8

    $preset = $Presets[$presetCombo.SelectedIndex].Profile
    $cmd = "--config-dir=$ConfigDir --profile=$preset `"$playlistFile`""
    try {
        [void][System.Diagnostics.Process]::Start($MpvExe, $cmd)
        Save-LastFolder $folderBox.Text
        Set-Status ("Playing $($script:Playlist.Count) videos") $SUCCESS
    } catch {
        Set-Status "Launch failed" $ERR
    }
}

# ============================================================
#  DOWNLOAD
# ============================================================
$script:DlJob = $null

function Start-Download {
    $url = $linkBox.Text.Trim()
    if (-not $url) {
        Set-Status "Paste a link first" $WARNING
        return
    }
    if (-not (Test-Path $YtDlp)) {
        Set-Status "yt-dlp missing" $ERR
        return
    }
    if ($script:DlJob -and -not $script:DlJob.P.HasExited) {
        Set-Status "Download in progress" $WARNING
        return
    }
    if (-not (Test-Path $LibraryDir)) { New-Item -ItemType Directory -Path $LibraryDir -Force | Out-Null }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $YtDlp
    $fmt = "bestvideo[ext=mp4][vcodec^=avc1][height<=1080]+bestaudio[ext=m4a]/bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best"
    $psi.Arguments = '--no-mtime -f "' + $fmt + '" --merge-output-format mp4 --ffmpeg-location "' + (Split-Path $MpvExe -Parent) + '" -o "' + $LibraryDir + '\%(title)s.%(ext)s" --no-progress "' + $url + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $script:DlJob = @{ P = $p; Url = $url }
        Set-Status "Downloading..." $ACCENT
    } catch {
        Set-Status "Download failed" $ERR
    }
}

function Tick-Download {
    if (-not $script:DlJob) { return }
    $job = $script:DlJob
    if (-not $job.P.HasExited) { return }
    $script:DlJob = $null

    if ($job.P.ExitCode -eq 0) {
        $newest = Get-ChildItem -Path $LibraryDir -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($newest) {
            Set-Status ("Saved: " + $newest.Name) $SUCCESS
            if ($folderBox.Text.TrimEnd("\") -ieq $LibraryDir) { Refresh-VideoList }
        } else {
            Set-Status "Download complete" $SUCCESS
        }
    } else {
        Set-Status "Download failed" $ERR
    }
}

function Clear-History {
    $msg = "Clear resume positions?" + [Environment]::NewLine + [Environment]::NewLine +
           "Videos will restart from the beginning." + [Environment]::NewLine +
           "Library downloads are kept."
    $res = [System.Windows.Forms.MessageBox]::Show($form, $msg, "NJ Player",
        [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $wl = Join-Path $Root "watch_later"
    if (Test-Path $wl) { Remove-Item $wl -Recurse -Force }
    $sysWl = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "mpv\watch_later"
    if (Test-Path $sysWl) { Remove-Item $sysWl -Recurse -Force }
    Remove-Item $LastFolderFile -Force -ErrorAction SilentlyContinue
    Set-Folder $DownloadsPath
    Set-Status "History cleared" $SUCCESS
}

function Play-Link {
    $url = $linkBox.Text.Trim()
    if (-not $url) {
        Set-Status "Paste a link first" $WARNING
        return
    }
    if (-not (Test-Path $MpvExe)) {
        Set-Status "mpv not found" $ERR
        return
    }
    $preset = $Presets[$presetCombo.SelectedIndex].Profile
    $cmd = "--config-dir=$ConfigDir --profile=$preset `"$url`""
    try {
        [void][System.Diagnostics.Process]::Start($MpvExe, $cmd)
        Set-Status "Opening link..." $ACCENT
    } catch {
        Set-Status "Launch failed" $ERR
    }
}

function Play-Video($item) {
    if (-not (Test-Path $MpvExe)) {
        Set-Status "mpv not found" $ERR
        return
    }
    if (-not $item) { Set-Status "Select a video" $WARNING; return }

    $file = if ($item.File) { $item.File } else { $item }
    $preset = $Presets[$presetCombo.SelectedIndex].Profile
    $cmd = "--config-dir=$ConfigDir --profile=$preset `"$($file.FullName)`""

    try {
        [void][System.Diagnostics.Process]::Start($MpvExe, $cmd)
        Save-LastFolder $folderBox.Text
        Set-Status ("Playing: " + $file.Name) $SUCCESS
    } catch {
        Set-Status "Launch failed" $ERR
    }
}

# ============================================================
#  THUMBNAIL PREVIEW
# ============================================================
$script:ThumbJob = $null
$script:ThumbGen = 0

function Get-ThumbPath($file) {
    $key = $file.Name + "-" + $file.Length + "-" + $file.LastWriteTimeUtc.Ticks
    $safe = -join ($key.ToCharArray() | ForEach-Object {
        if ([char]::IsLetterOrDigit($_) -or $_ -eq '-' -or $_ -eq '.') { $_ } else { '_' }
    })
    return Join-Path $ThumbDir ($safe + ".jpg")
}

function Set-PreviewHint([string]$text) {
    $previewHint.Text = $text
    $previewHint.Visible = $true
}

function Clear-Preview() {
    if ($previewBox.Image) { $previewBox.Image.Dispose(); $previewBox.Image = $null }
    $previewHint.Visible = $true
}

function Load-PreviewImage([string]$path) {
    try {
        $img = [System.Drawing.Image]::FromFile($path)
        if ($previewBox.Image) { $previewBox.Image.Dispose() }
        $previewBox.Image = $img
        $previewBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $previewHint.Visible = $false
    } catch {
        Set-PreviewHint "No preview"
    }
}

function Start-Thumbnail($file) {
    $script:ThumbGen++
    $gen = $script:ThumbGen

    if ($script:ThumbJob) {
        try { if (-not $script:ThumbJob.P.HasExited) { $script:ThumbJob.P.Kill() } } catch { }
        $script:ThumbJob = $null
    }

    $cacheFile = Get-ThumbPath $file
    if (Test-Path $cacheFile) { Load-PreviewImage $cacheFile; return }

    Set-PreviewHint "Generating..."

    $tmpDir = Join-Path $ThumbDir ("tmp-" + [guid]::NewGuid().ToString("N"))
    try { New-Item -ItemType Directory -Path $tmpDir | Out-Null } catch { }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $MpvExe
    $psi.Arguments = "--config-dir=$ConfigDir --profile=nj-clean --keep-open=no --no-audio --frames=1 --vo=image --vo-image-outdir=`"$tmpDir`" --start=3 `"$($file.FullName)`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $script:ThumbJob = @{ P = $p; Gen = $gen; Cache = $cacheFile; Tmp = $tmpDir }
    } catch {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        Set-PreviewHint "No preview"
    }
}

function Show-Preview($item) {
    if (-not $item) { Clear-Preview; return }
    $file = if ($item.File) { $item.File } else { $item }
    Start-Thumbnail $file
}

function Tick-Thumbnail {
    if (-not $script:ThumbJob) { return }
    $job = $script:ThumbJob
    if (-not $job.P.HasExited) { return }
    $script:ThumbJob = $null

    $out = Join-Path $job.Tmp "00000001.jpg"
    if ((Test-Path $out) -and ($job.Gen -eq $script:ThumbGen)) {
        try {
            Move-Item -Force $out $job.Cache
            Load-PreviewImage $job.Cache
        } catch {
            Set-PreviewHint "No preview"
        }
    } elseif (-not (Test-Path $out)) {
        Set-PreviewHint "No preview"
    }
    Remove-Item $job.Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ============================================================
#  BUILD THE FORM — Cinematic Dark Luxury
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "NJ Player"
$form.Size = New-Object System.Drawing.Size(1100, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = $INK
$form.MinimumSize = New-Object System.Drawing.Size(900, 650)

# Load icon
$NjIco = Join-Path $Root "nj-player.ico"
if (Test-Path $NjIco) {
    try {
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($NjIco)
    } catch {
        try { $form.Icon = [System.Drawing.Icon]::FromFile($NjIco) } catch { }
    }
}

# --- CINEMATIC HEADER ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(1100, 80)
$headerPanel.BackColor = $SURFACE
$headerPanel.Dock = "Top"
$form.Controls.Add($headerPanel)

# Brand text
$brandLabel = New-Object System.Windows.Forms.Label
$brandLabel.Text = "NJ PLAYER"
$brandLabel.Location = New-Object System.Drawing.Point(24, 20)
$brandLabel.Size = New-Object System.Drawing.Size(300, 40)
$brandLabel.ForeColor = $TEXT_PRIMARY
$brandLabel.Font = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
$brandLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($brandLabel)

# Accent line under brand
$accentLine = New-Object System.Windows.Forms.Panel
$accentLine.Location = New-Object System.Drawing.Point(24, 62)
$accentLine.Size = New-Object System.Drawing.Size(120, 2)
$accentLine.BackColor = $ACCENT
$accentLine.Dock = "None"
$headerPanel.Controls.Add($accentLine)

# Tagline
$tagLabel = New-Object System.Windows.Forms.Label
$tagLabel.Text = "CINEMATIC PLAYBACK"
$tagLabel.Location = New-Object System.Drawing.Point(155, 30)
$tagLabel.Size = New-Object System.Drawing.Size(200, 20)
$tagLabel.ForeColor = $TEXT_TERTIARY
$tagLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$tagLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($tagLabel)

# --- MAIN CONTENT AREA (Left: Files, Right: Controls) ---
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(0, 80)
$mainPanel.Size = New-Object System.Drawing.Size(1100, 600)
$mainPanel.BackColor = $INK
$form.Controls.Add($mainPanel)

# === LEFT COLUMN (65%) — File Browser + Queue ===

# Folder bar
$folderPanel = New-Object System.Windows.Forms.Panel
$folderPanel.Location = New-Object System.Drawing.Point(0, 0)
$folderPanel.Size = New-Object System.Drawing.Size(715, 48)
$folderPanel.BackColor = $SURFACE
$mainPanel.Controls.Add($folderPanel)

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(16, 10)
$folderBox.Size = New-Object System.Drawing.Size(380, 28)
$folderBox.BackColor = $SURFACE_ELEV
$folderBox.ForeColor = $TEXT_PRIMARY
$folderBox.BorderStyle = "None"
$folderBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$folderBox.ReadOnly = $true
$folderPanel.Controls.Add($folderBox)

$dlBtn = New-NjButton "DL" 408 10 44 28
$dlBtn.Add_Click({ Set-Folder $DownloadsPath })
$folderPanel.Controls.Add($dlBtn)

$vidBtn = New-NjButton "VID" 458 10 44 28
$vidBtn.Add_Click({ Set-Folder $VideosPath })
$folderPanel.Controls.Add($vidBtn)

$deskBtn = New-NjButton "DSK" 508 10 44 28
$deskBtn.Add_Click({ Set-Folder $DesktopPath })
$folderPanel.Controls.Add($deskBtn)

$libBtn = New-NjButton "LIB" 558 10 44 28
$libBtn.Add_Click({ Set-Folder $LibraryPath })
$folderPanel.Controls.Add($libBtn)

$browseBtn = New-NjButton "BROWSE" 608 10 96 28
$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Choose a folder"
    if (Test-Path $folderBox.Text) { $dlg.SelectedPath = $folderBox.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $folderBox.Text = $dlg.SelectedPath
        Save-LastFolder $dlg.SelectedPath
        Refresh-VideoList
    }
})
$folderPanel.Controls.Add($browseBtn)

# Video list (large, cinematic)
$videoList = New-NjListBox 0 52 715 268
$videoList.Add_DoubleClick({ Play-Video $videoList.SelectedItem })
$videoList.Add_SelectedIndexChanged({ Show-Preview $videoList.SelectedItem })
$mainPanel.Controls.Add($videoList)

# Recursive checkbox
$recursiveCheck = New-Object System.Windows.Forms.CheckBox
$recursiveCheck.Text = "Subfolders"
$recursiveCheck.Location = New-Object System.Drawing.Point(16, 326)
$recursiveCheck.Size = New-Object System.Drawing.Size(100, 24)
$recursiveCheck.ForeColor = $TEXT_TERTIARY
$recursiveCheck.Font = New-Object System.Drawing.Font("Consolas", 9)
$recursiveCheck.Checked = $true
$recursiveCheck.Add_CheckedChanged({ Refresh-VideoList })
$mainPanel.Controls.Add($recursiveCheck)

# Queue section
$queueDivider = New-Object System.Windows.Forms.Panel
$queueDivider.Location = New-Object System.Drawing.Point(0, 356)
$queueDivider.Size = New-Object System.Drawing.Size(715, 1)
$queueDivider.BackColor = $BORDER
$mainPanel.Controls.Add($queueDivider)

$queueHeaderPanel = New-Object System.Windows.Forms.Panel
$queueHeaderPanel.Location = New-Object System.Drawing.Point(0, 360)
$queueHeaderPanel.Size = New-Object System.Drawing.Size(715, 32)
$queueHeaderPanel.BackColor = [System.Drawing.Color]::Transparent
$mainPanel.Controls.Add($queueHeaderPanel)

$queueLabel = New-Object System.Windows.Forms.Label
$queueLabel.Text = "QUEUE"
$queueLabel.Location = New-Object System.Drawing.Point(16, 4)
$queueLabel.Size = New-Object System.Drawing.Size(100, 24)
$queueLabel.ForeColor = $ACCENT
$queueLabel.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
$queueHeaderPanel.Controls.Add($queueLabel)

$queueCountLabel = New-Object System.Windows.Forms.Label
$queueCountLabel.Text = "0"
$queueCountLabel.Location = New-Object System.Drawing.Point(100, 4)
$queueCountLabel.Size = New-Object System.Drawing.Size(40, 24)
$queueCountLabel.ForeColor = $TEXT_TERTIARY
$queueCountLabel.Font = New-Object System.Drawing.Font("Consolas", 11)
$queueHeaderPanel.Controls.Add($queueCountLabel)

$playQueueBtn = New-NjButton "PLAY QUEUE" 580 2 130 28 -IsAccent $true
$playQueueBtn.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$playQueueBtn.Add_Click({ Play-Queue })
$queueHeaderPanel.Controls.Add($playQueueBtn)

$queueList = New-NjListBox 0 396 715 170
$mainPanel.Controls.Add($queueList)

$removeQueueBtn = New-NjButton "REMOVE" 500 572 100 28
$removeQueueBtn.Font = New-Object System.Drawing.Font("Consolas", 9)
$removeQueueBtn.Add_Click({ Remove-FromQueue })
$mainPanel.Controls.Add($removeQueueBtn)

$clearQueueBtn = New-NjButton "CLEAR" 608 572 100 28
$clearQueueBtn.Font = New-Object System.Drawing.Font("Consolas", 9)
$clearQueueBtn.Add_Click({ Clear-Queue })
$mainPanel.Controls.Add($clearQueueBtn)

# === RIGHT COLUMN (35%) — Preview + Controls + Link ===

# Preview card
$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Location = New-Object System.Drawing.Point(730, 12)
$previewPanel.Size = New-Object System.Drawing.Size(350, 200)
$previewPanel.BackColor = $SURFACE
$mainPanel.Controls.Add($previewPanel)

$previewBox = New-Object System.Windows.Forms.PictureBox
$previewBox.Location = New-Object System.Drawing.Point(0, 0)
$previewBox.Size = New-Object System.Drawing.Size(350, 200)
$previewBox.BackColor = $SURFACE
$previewBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$previewPanel.Controls.Add($previewBox)

$previewHint = New-Object System.Windows.Forms.Label
$previewHint.Location = New-Object System.Drawing.Point(0, 0)
$previewHint.Size = New-Object System.Drawing.Size(350, 200)
$previewHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$previewHint.ForeColor = $TEXT_TERTIARY
$previewHint.BackColor = [System.Drawing.Color]::Transparent
$previewHint.Text = "SELECT A VIDEO"
$previewHint.Font = New-Object System.Drawing.Font("Consolas", 10)
$previewPanel.Controls.Add($previewHint)

# Controls section
$controlsPanel = New-Object System.Windows.Forms.Panel
$controlsPanel.Location = New-Object System.Drawing.Point(730, 224)
$controlsPanel.Size = New-Object System.Drawing.Size(350, 200)
$controlsPanel.BackColor = $SURFACE
$mainPanel.Controls.Add($controlsPanel)

# Enhancement label
$enhLabel = New-Object System.Windows.Forms.Label
$enhLabel.Text = "ENHANCEMENT"
$enhLabel.Location = New-Object System.Drawing.Point(16, 12)
$enhLabel.Size = New-Object System.Drawing.Size(200, 20)
$enhLabel.ForeColor = $TEXT_TERTIARY
$enhLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$controlsPanel.Controls.Add($enhLabel)

$presetCombo = New-NjComboBox 16 36 318 32
foreach ($p in $Presets) { [void]$presetCombo.Items.Add($p.Icon + " " + $p.Name) }
$presetCombo.SelectedIndex = 2   # Cinema default
$controlsPanel.Controls.Add($presetCombo)

# PLAY button (large, cinematic)
$playBtn = New-Object System.Windows.Forms.Button
$playBtn.Text = [char]0x25B6 + "  PLAY"
$playBtn.Location = New-Object System.Drawing.Point(16, 80)
$playBtn.Size = New-Object System.Drawing.Size(318, 52)
$playBtn.FlatStyle = "Flat"
$playBtn.FlatAppearance.BorderSize = 0
$playBtn.BackColor = $ACCENT
$playBtn.ForeColor = $INK
$playBtn.Font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
$playBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$playBtn.Add_Click({ Play-Video $videoList.SelectedItem })
$playBtn.Add_MouseEnter({ $playBtn.BackColor = $TEXT_PRIMARY })
$playBtn.Add_MouseLeave({ $playBtn.BackColor = $ACCENT })
$controlsPanel.Controls.Add($playBtn)

# Add to Queue button
$addQueueBtn = New-NjButton "+ ADD TO QUEUE" 16 144 318 36
$addQueueBtn.Font = New-Object System.Drawing.Font("Consolas", 10)
$addQueueBtn.Add_Click({ Add-ToQueue $videoList.SelectedItem })
$controlsPanel.Controls.Add($addQueueBtn)

# Quick actions
$actionsPanel = New-Object System.Windows.Forms.Panel
$actionsPanel.Location = New-Object System.Drawing.Point(730, 436)
$actionsPanel.Size = New-Object System.Drawing.Size(350, 44)
$actionsPanel.BackColor = $SURFACE
$mainPanel.Controls.Add($actionsPanel)

$refreshBtn = New-NjButton "REFRESH" 16 8 100 28
$refreshBtn.Font = New-Object System.Drawing.Font("Consolas", 9)
$refreshBtn.Add_Click({ Refresh-VideoList })
$actionsPanel.Controls.Add($refreshBtn)

$openBtn = New-NjButton "OPEN FOLDER" 124 8 120 28
$openBtn.Font = New-Object System.Drawing.Font("Consolas", 9)
$openBtn.Add_Click({
    if (Test-Path $folderBox.Text) { [void][System.Diagnostics.Process]::Start("explorer.exe", $folderBox.Text) }
})
$actionsPanel.Controls.Add($openBtn)

$clearBtn = New-NjButton "CLEAR HISTORY" 252 8 100 28
$clearBtn.Font = New-Object System.Drawing.Font("Consolas", 9)
$clearBtn.Add_Click({ Clear-History })
$actionsPanel.Controls.Add($clearBtn)

# Link bar
$linkPanel = New-Object System.Windows.Forms.Panel
$linkPanel.Location = New-Object System.Drawing.Point(730, 492)
$linkPanel.Size = New-Object System.Drawing.Size(350, 112)
$linkPanel.BackColor = $SURFACE
$mainPanel.Controls.Add($linkPanel)

$linkLabel = New-Object System.Windows.Forms.Label
$linkLabel.Text = "LINK"
$linkLabel.Location = New-Object System.Drawing.Point(16, 8)
$linkLabel.Size = New-Object System.Drawing.Size(100, 20)
$linkLabel.ForeColor = $TEXT_TERTIARY
$linkLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$linkPanel.Controls.Add($linkLabel)

$linkBox = New-Object System.Windows.Forms.TextBox
$linkBox.Location = New-Object System.Drawing.Point(16, 32)
$linkBox.Size = New-Object System.Drawing.Size(318, 28)
$linkBox.BackColor = $SURFACE_ELEV
$linkBox.ForeColor = $TEXT_PRIMARY
$linkBox.BorderStyle = "None"
$linkBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$linkBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { Play-Link }
})
$linkPanel.Controls.Add($linkBox)

$playLinkBtn = New-NjButton "PLAY" 16 68 156 32 -IsAccent $true
$playLinkBtn.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$playLinkBtn.Add_Click({ Play-Link })
$linkPanel.Controls.Add($playLinkBtn)

$downloadBtn = New-NjButton "DOWNLOAD" 180 68 154 32
$downloadBtn.Font = New-Object System.Drawing.Font("Consolas", 10)
$downloadBtn.Add_Click({ Start-Download })
$linkPanel.Controls.Add($downloadBtn)

# --- STATUS BAR ---
$statusBar = New-Object System.Windows.Forms.Panel
$statusBar.Location = New-Object System.Drawing.Point(0, 680)
$statusBar.Size = New-Object System.Drawing.Size(1100, 40)
$statusBar.BackColor = $SURFACE
$statusBar.Dock = "Bottom"
$form.Controls.Add($statusBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(24, 10)
$statusLabel.Size = New-Object System.Drawing.Size(800, 24)
$statusLabel.ForeColor = $TEXT_SECONDARY
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Consolas", 10)
$statusBar.Controls.Add($statusLabel)

# Footer attribution
$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Text = "MADE WITH LOVE BY EMPATHY STUDIO"
$footerLabel.Location = New-Object System.Drawing.Point(850, 10)
$footerLabel.Size = New-Object System.Drawing.Size(230, 24)
$footerLabel.ForeColor = $TEXT_TERTIARY
$footerLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
$footerLabel.TextAlign = "MiddleRight"
$statusBar.Controls.Add($footerLabel)

# --- TIMERS ---
$thumbTimer = New-Object System.Windows.Forms.Timer
$thumbTimer.Interval = 250
$thumbTimer.Add_Tick({ Tick-Thumbnail; Tick-Download; Update-Animations })
$thumbTimer.Start()

# ============================================================
#  RUN
# ============================================================
$form.Add_Shown({
    $folderBox.Text = Load-LastFolder
    Refresh-VideoList
    
    # Cinematic entrance animation
    $form.Opacity = 0
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 16
    $timer.Add_Tick({
        $form.Opacity = [Math]::Min(1.0, $form.Opacity + 0.05)
        if ($form.Opacity -ge 1.0) { $timer.Stop(); $timer.Dispose() }
    })
    $timer.Start()
})

$form.Add_FormClosed({
    if ($script:ThumbJob) {
        try { if (-not $script:ThumbJob.P.HasExited) { $script:ThumbJob.P.Kill() } } catch { }
    }
    if ($previewBox.Image) { $previewBox.Image.Dispose() }
})

if ($SelfTest) {
    $form.Add_Shown({ $form.Close() })
    [void]$form.ShowDialog()
    Write-Host "GUI v2 self-test OK"
    exit 0
}

[void]$form.ShowDialog()
