# ============================================================
#  NJ PLAYER - launcher GUI
#  Browse your downloaded videos, pick an enhancement preset,
#  and play with one click. Pure Windows PowerShell (WinForms),
#  no extra installs needed.
#
#  Launch:  double-click NJ-Player-GUI.bat
# ============================================================

param([switch]$SelfTest)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Root        = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MpvExe      = Join-Path $Root "mpv\mpv.exe"
$ConfigDir   = ($Root -replace "\\", "/")   # forward slashes avoid Windows quoting pitfalls
$LastFolderFile = Join-Path $Root ".last-folder.txt"
$ThumbDir    = Join-Path $Root ".thumbs"
$LibraryDir  = Join-Path $Root "library"
$YtDlp       = Join-Path $Root "mpv\yt-dlp.exe"

$VideoExtensions = @(
    ".mp4", ".mkv", ".avi", ".webm", ".mov", ".m4v",
    ".flv", ".wmv", ".mpg", ".mpeg", ".ts", ".3gp", ".ogv", ".divx"
)

$Presets = @(
    @{ Name = "Enhancement Off";          Profile = "nj-clean" },
    @{ Name = "Lucid (adaptive sharpen)"; Profile = "nj-lucid" },
    @{ Name = "Cinema (full pipeline)";   Profile = "nj-cinema" },
    @{ Name = "Anime4K";                  Profile = "nj-anime" }
)

# Common folder shortcuts
$DownloadsPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
$VideosPath    = [Environment]::GetFolderPath("MyVideos")
$DesktopPath   = [Environment]::GetFolderPath("Desktop")
$LibraryPath   = $LibraryDir

# The library folder exists so the Library button always works
if (-not (Test-Path $LibraryDir)) { New-Item -ItemType Directory -Path $LibraryDir | Out-Null }

# Thumbnail cache: keep it bounded
if (-not (Test-Path $ThumbDir)) { New-Item -ItemType Directory -Path $ThumbDir | Out-Null }
$thumbCount = @(Get-ChildItem -Path $ThumbDir -Filter *.jpg -ErrorAction SilentlyContinue).Count
if ($thumbCount -gt 200) {
    Get-ChildItem -Path $ThumbDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
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
        Set-Status ("Folder not available: " + $path) ([System.Drawing.Color]::FromArgb(255, 255, 200, 180))
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
        Set-Status "No video files found here (try Browse... or untick Include subfolders)." ([System.Drawing.Color]::FromArgb(255, 255, 200, 180))
    } else {
        Set-Status ("$($videos.Count) video(s) found. Double-click or select + PLAY.") ([System.Drawing.Color]::FromArgb(255, 170, 210, 170))
    }
}

$script:DlJob = $null

function Start-Download {
    $url = $linkBox.Text.Trim()
    if (-not $url) {
        Set-Status "Paste a link first, then Download." ([System.Drawing.Color]::FromArgb(255, 255, 200, 120))
        return
    }
    if (-not (Test-Path $YtDlp)) {
        Set-Status "yt-dlp missing - run install.ps1 again (see README)." ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
        return
    }
    if ($script:DlJob -and -not $script:DlJob.P.HasExited) {
        Set-Status "A download is already running - please wait." ([System.Drawing.Color]::FromArgb(255, 255, 200, 120))
        return
    }
    if (-not (Test-Path $LibraryDir)) { New-Item -ItemType Directory -Path $LibraryDir -Force | Out-Null }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $YtDlp
    # FULL HD (1080p): best H.264 video up to 1080p + audio, merged by ffmpeg
    $fmt = "bestvideo[ext=mp4][vcodec^=avc1][height<=1080]+bestaudio[ext=m4a]/bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best"
    $psi.Arguments = '--no-playlist --no-mtime -f "' + $fmt + '" --merge-output-format mp4 --ffmpeg-location "' + (Split-Path $MpvExe -Parent) + '" -o "' + $LibraryDir + '\%(title)s.%(ext)s" --no-progress "' + $url + '"'
    # No output redirection: PS 5.1 event-handler scriptblocks can kill the
    # runspace when fired on background threads. yt-dlp with --no-progress
    # writes only a few lines, which go to the hidden console harmlessly.
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $script:DlJob = @{ P = $p; Url = $url }
        Set-Status ("Downloading to library: " + $url + " ...") ([System.Drawing.Color]::FromArgb(255, 220, 220, 160))
    } catch {
        Set-Status ("Download could not start: " + $_.Exception.Message) ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
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
            Set-Status ("Saved to library: " + $newest.Name) ([System.Drawing.Color]::FromArgb(255, 170, 210, 170))
            if ($folderBox.Text.TrimEnd("\\") -ieq $LibraryDir) { Refresh-VideoList }
        } else {
            Set-Status "Download finished but no file found in library." ([System.Drawing.Color]::FromArgb(255, 255, 200, 120))
        }
    } else {
        Set-Status ("Download failed (exit " + $job.P.ExitCode + "). Check the link or your internet.") ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
    }
}

function Clear-History {
    $msg = "Clear NJ Player history?" + [Environment]::NewLine + [Environment]::NewLine +
           "This removes:" + [Environment]::NewLine +
           "- Resume positions (videos start from the beginning)" + [Environment]::NewLine +
           "- The remembered last folder" + [Environment]::NewLine + [Environment]::NewLine +
           "Your downloaded videos in the Library are kept."
    $res = [System.Windows.Forms.MessageBox]::Show($form, $msg, "NJ Player - Clear History",
        [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    # Playback resume history (project location + legacy system location)
    $wl = Join-Path $Root "watch_later"
    if (Test-Path $wl) { Remove-Item $wl -Recurse -Force }
    $sysWl = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "mpv\watch_later"
    if (Test-Path $sysWl) { Remove-Item $sysWl -Recurse -Force }

    # Remembered last folder
    Remove-Item $LastFolderFile -Force -ErrorAction SilentlyContinue

    # Jump back to Downloads as visible confirmation
    Set-Folder $DownloadsPath
    Set-Status "History cleared - resume positions and last folder removed." ([System.Drawing.Color]::FromArgb(255, 170, 210, 170))
}

function Play-Link {
    $url = $linkBox.Text.Trim()
    if (-not $url) {
        Set-Status "Paste a video or stream link first (YouTube, Twitch, m3u8, ...)." ([System.Drawing.Color]::FromArgb(255, 255, 200, 120))
        return
    }
    if (-not (Test-Path $MpvExe)) {
        Set-Status "mpv not found - run install.ps1 first (see README)." ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
        return
    }
    $preset = $Presets[$presetCombo.SelectedIndex].Profile
    $cmd = "--config-dir=$ConfigDir --profile=$preset `"$url`""
    try {
        [void][System.Diagnostics.Process]::Start($MpvExe, $cmd)
        Set-Status ("Opening link: " + $url + "  [" + $preset + "] (needs internet)") ([System.Drawing.Color]::FromArgb(255, 170, 210, 170))
    } catch {
        Set-Status ("Could not launch player: " + $_.Exception.Message) ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
    }
}

function Play-Video($item) {
    if (-not (Test-Path $MpvExe)) {
        Set-Status "mpv not found - run install.ps1 first (see README)." ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
        return
    }
    if (-not $item) { Set-Status "Select a video first." ([System.Drawing.Color]::FromArgb(255, 255, 200, 120)); return }

    $file = if ($item.File) { $item.File } else { $item }
    $preset = $Presets[$presetCombo.SelectedIndex].Profile
    $cmd = "--config-dir=$ConfigDir --profile=$preset `"$($file.FullName)`""

    try {
        [void][System.Diagnostics.Process]::Start($MpvExe, $cmd)
        Save-LastFolder $folderBox.Text
        Set-Status ("Playing: " + $file.Name + "  [" + $preset + "]") ([System.Drawing.Color]::FromArgb(255, 170, 210, 170))
    } catch {
        Set-Status ("Could not launch player: " + $_.Exception.Message) ([System.Drawing.Color]::FromArgb(255, 255, 120, 120))
    }
}

# ------------------------------------------------------------
# Thumbnail preview
# ------------------------------------------------------------
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
        Set-PreviewHint "No preview available"
    }
}

function Start-Thumbnail($file) {
    $script:ThumbGen++
    $gen = $script:ThumbGen

    # Abandon any previous extraction
    if ($script:ThumbJob) {
        try { if (-not $script:ThumbJob.P.HasExited) { $script:ThumbJob.P.Kill() } } catch { }
        $script:ThumbJob = $null
    }

    $cacheFile = Get-ThumbPath $file
    if (Test-Path $cacheFile) { Load-PreviewImage $cacheFile; return }

    Set-PreviewHint "Generating preview..."

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
        Set-PreviewHint "No preview available"
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
            Set-PreviewHint "No preview available"
        }
    } elseif (-not (Test-Path $out)) {
        Set-PreviewHint "No preview available"
    }
    Remove-Item $job.Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# Build the form
# ------------------------------------------------------------
$dark    = [System.Drawing.Color]::FromArgb(255, 30, 30, 34)
$dark2   = [System.Drawing.Color]::FromArgb(255, 45, 45, 52)
$text    = [System.Drawing.Color]::FromArgb(255, 225, 225, 228)
$accent  = [System.Drawing.Color]::FromArgb(255, 90, 160, 255)
$ok      = [System.Drawing.Color]::FromArgb(255, 170, 210, 170)
$bad     = [System.Drawing.Color]::FromArgb(255, 255, 120, 120)
$hint    = [System.Drawing.Color]::FromArgb(255, 140, 140, 150)

$form = New-Object System.Windows.Forms.Form
$form.Text = "NJ Player"
$form.Size = New-Object System.Drawing.Size(920, 560)
$form.StartPosition = "CenterScreen"
$form.BackColor = $dark
$form.MinimumSize = New-Object System.Drawing.Size(720, 460)
$NjIco = Join-Path $Root "nj-player.ico"
if (Test-Path $NjIco) {
    try {
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($NjIco)
    } catch {
        try { $form.Icon = [System.Drawing.Icon]::FromFile($NjIco) } catch { }
    }
}
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# --- top: folder row with quick folders ---
$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "Folder:"
$folderLabel.Location = New-Object System.Drawing.Point(12, 15)
$folderLabel.Size = New-Object System.Drawing.Size(55, 26)
$folderLabel.ForeColor = $text

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(70, 12)
$folderBox.Size = New-Object System.Drawing.Size(340, 26)
$folderBox.BackColor = $dark2
$folderBox.ForeColor = $text
$folderBox.BorderStyle = "FixedSingle"
$folderBox.ReadOnly = $true

$dlBtn = New-Object System.Windows.Forms.Button
$dlBtn.Text = "Downloads"
$dlBtn.Location = New-Object System.Drawing.Point(416, 11)
$dlBtn.Size = New-Object System.Drawing.Size(72, 28)
$dlBtn.BackColor = $dark2
$dlBtn.ForeColor = $text
$dlBtn.FlatStyle = "Flat"
$dlBtn.Add_Click({ Set-Folder $DownloadsPath })

$vidBtn = New-Object System.Windows.Forms.Button
$vidBtn.Text = "Videos"
$vidBtn.Location = New-Object System.Drawing.Point(492, 11)
$vidBtn.Size = New-Object System.Drawing.Size(58, 28)
$vidBtn.BackColor = $dark2
$vidBtn.ForeColor = $text
$vidBtn.FlatStyle = "Flat"
$vidBtn.Add_Click({ Set-Folder $VideosPath })

$deskBtn = New-Object System.Windows.Forms.Button
$deskBtn.Text = "Desktop"
$deskBtn.Location = New-Object System.Drawing.Point(554, 11)
$deskBtn.Size = New-Object System.Drawing.Size(62, 28)
$deskBtn.BackColor = $dark2
$deskBtn.ForeColor = $text
$deskBtn.FlatStyle = "Flat"
$deskBtn.Add_Click({ Set-Folder $DesktopPath })

$libBtn = New-Object System.Windows.Forms.Button
$libBtn.Text = "Library"
$libBtn.Location = New-Object System.Drawing.Point(620, 11)
$libBtn.Size = New-Object System.Drawing.Size(72, 28)
$libBtn.BackColor = $dark2
$libBtn.ForeColor = $text
$libBtn.FlatStyle = "Flat"
$libBtn.Add_Click({ Set-Folder $LibraryPath })

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Browse..."
$browseBtn.Location = New-Object System.Drawing.Point(696, 11)
$browseBtn.Size = New-Object System.Drawing.Size(130, 28)
$browseBtn.BackColor = $dark2
$browseBtn.ForeColor = $text
$browseBtn.FlatStyle = "Flat"
$browseBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Choose a folder with your videos"
    if (Test-Path $folderBox.Text) { $dlg.SelectedPath = $folderBox.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $folderBox.Text = $dlg.SelectedPath
        Save-LastFolder $dlg.SelectedPath
        Refresh-VideoList
    }
})

# --- middle: video list ---
$videoList = New-Object System.Windows.Forms.ListBox
$videoList.Location = New-Object System.Drawing.Point(12, 48)
$videoList.Size = New-Object System.Drawing.Size(680, 404)
$videoList.BackColor = $dark2
$videoList.ForeColor = $text
$videoList.BorderStyle = "FixedSingle"
$videoList.HorizontalScrollbar = $true
$videoList.DisplayMember = "Name"
$videoList.Add_DoubleClick({ Play-Video $videoList.SelectedItem })
$videoList.Add_SelectedIndexChanged({ Show-Preview $videoList.SelectedItem })

# --- right: preview + controls ---
$previewBox = New-Object System.Windows.Forms.PictureBox
$previewBox.Location = New-Object System.Drawing.Point(700, 48)
$previewBox.Size = New-Object System.Drawing.Size(200, 112)
$previewBox.BackColor = $dark2
$previewBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom

$previewHint = New-Object System.Windows.Forms.Label
$previewHint.Location = New-Object System.Drawing.Point(700, 48)
$previewHint.Size = New-Object System.Drawing.Size(200, 112)
$previewHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$previewHint.ForeColor = $hint
$previewHint.BackColor = $dark2
$previewHint.Text = "Select a video for a preview"

$presetLabel = New-Object System.Windows.Forms.Label
$presetLabel.Text = "Enhancement"
$presetLabel.Location = New-Object System.Drawing.Point(700, 168)
$presetLabel.Size = New-Object System.Drawing.Size(200, 22)
$presetLabel.ForeColor = $text

$presetCombo = New-Object System.Windows.Forms.ComboBox
$presetCombo.Location = New-Object System.Drawing.Point(700, 192)
$presetCombo.Size = New-Object System.Drawing.Size(200, 28)
$presetCombo.DropDownStyle = "DropDownList"
$presetCombo.BackColor = $dark2
$presetCombo.ForeColor = $text
$presetCombo.FlatStyle = "Flat"
foreach ($p in $Presets) { [void]$presetCombo.Items.Add($p.Name) }
$presetCombo.SelectedIndex = 2   # Cinema as default

$recursiveCheck = New-Object System.Windows.Forms.CheckBox
$recursiveCheck.Text = "Include subfolders"
$recursiveCheck.Location = New-Object System.Drawing.Point(700, 224)
$recursiveCheck.Size = New-Object System.Drawing.Size(200, 26)
$recursiveCheck.ForeColor = $text
$recursiveCheck.Checked = $true
$recursiveCheck.Add_CheckedChanged({ Refresh-VideoList })

$playBtn = New-Object System.Windows.Forms.Button
$playBtn.Text = "PLAY"
$playBtn.Location = New-Object System.Drawing.Point(700, 258)
$playBtn.Size = New-Object System.Drawing.Size(200, 44)
$playBtn.BackColor = $accent
$playBtn.ForeColor = [System.Drawing.Color]::White
$playBtn.FlatStyle = "Flat"
$playBtn.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$playBtn.Add_Click({ Play-Video $videoList.SelectedItem })

$openBtn = New-Object System.Windows.Forms.Button
$openBtn.Text = "Open Folder"
$openBtn.Location = New-Object System.Drawing.Point(700, 310)
$openBtn.Size = New-Object System.Drawing.Size(200, 28)
$openBtn.BackColor = $dark2
$openBtn.ForeColor = $text
$openBtn.FlatStyle = "Flat"
$openBtn.Add_Click({
    if (Test-Path $folderBox.Text) { [void][System.Diagnostics.Process]::Start("explorer.exe", $folderBox.Text) }
})

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "Refresh"
$refreshBtn.Location = New-Object System.Drawing.Point(700, 346)
$refreshBtn.Size = New-Object System.Drawing.Size(200, 28)
$refreshBtn.BackColor = $dark2
$refreshBtn.ForeColor = $text
$refreshBtn.FlatStyle = "Flat"
$refreshBtn.Add_Click({ Refresh-VideoList })

$clearBtn = New-Object System.Windows.Forms.Button
$clearBtn.Text = "Clear History"
$clearBtn.Location = New-Object System.Drawing.Point(700, 382)
$clearBtn.Size = New-Object System.Drawing.Size(200, 28)
$clearBtn.BackColor = $dark2
$clearBtn.ForeColor = $text
$clearBtn.FlatStyle = "Flat"
$clearBtn.Add_Click({ Clear-History })

# --- bottom: link bar ---
$linkLabel = New-Object System.Windows.Forms.Label
$linkLabel.Text = "Link:"
$linkLabel.Location = New-Object System.Drawing.Point(12, 462)
$linkLabel.Size = New-Object System.Drawing.Size(40, 26)
$linkLabel.ForeColor = $text

$linkBox = New-Object System.Windows.Forms.TextBox
$linkBox.Location = New-Object System.Drawing.Point(54, 459)
$linkBox.Size = New-Object System.Drawing.Size(590, 26)
$linkBox.BackColor = $dark2
$linkBox.ForeColor = $text
$linkBox.BorderStyle = "FixedSingle"
$linkBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$linkBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { Play-Link }
})

$playLinkBtn = New-Object System.Windows.Forms.Button
$playLinkBtn.Text = "Play Link"
$playLinkBtn.Location = New-Object System.Drawing.Point(650, 458)
$playLinkBtn.Size = New-Object System.Drawing.Size(120, 28)
$playLinkBtn.BackColor = $dark2
$playLinkBtn.ForeColor = $text
$playLinkBtn.FlatStyle = "Flat"
$playLinkBtn.Add_Click({ Play-Link })

$downloadBtn = New-Object System.Windows.Forms.Button
$downloadBtn.Text = "Download"
$downloadBtn.Location = New-Object System.Drawing.Point(776, 458)
$downloadBtn.Size = New-Object System.Drawing.Size(120, 28)
$downloadBtn.BackColor = $dark2
$downloadBtn.ForeColor = $text
$downloadBtn.FlatStyle = "Flat"
$downloadBtn.Add_Click({ Start-Download })

# --- bottom: status ---
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(12, 496)
$statusLabel.Size = New-Object System.Drawing.Size(890, 22)
$statusLabel.ForeColor = $ok
$statusLabel.Text = "Ready. Choose a folder to see your videos."

# --- thumbnail poll timer (UI thread - safe) ---
$thumbTimer = New-Object System.Windows.Forms.Timer
$thumbTimer.Interval = 250
$thumbTimer.Add_Tick({ Tick-Thumbnail; Tick-Download })
$thumbTimer.Start()

$form.Controls.AddRange(@($folderLabel, $folderBox, $dlBtn, $vidBtn, $deskBtn, $libBtn, $browseBtn,
                          $videoList, $previewBox, $previewHint, $presetLabel, $presetCombo,
                          $recursiveCheck, $playBtn, $openBtn, $refreshBtn, $clearBtn, $linkLabel,
                          $linkBox, $playLinkBtn, $downloadBtn, $statusLabel))

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------
$form.Add_Shown({
    $folderBox.Text = Load-LastFolder
    Refresh-VideoList
})

$form.Add_FormClosed({
    if ($script:ThumbJob) {
        try { if (-not $script:ThumbJob.P.HasExited) { $script:ThumbJob.P.Kill() } } catch { }
    }
    if ($previewBox.Image) { $previewBox.Image.Dispose() }
})

if ($SelfTest) {
    # Build-only mode: verify everything constructs, then exit.
    $form.Add_Shown({ $form.Close() })
    [void]$form.ShowDialog()
    Write-Host "GUI self-test OK"
    exit 0
}

[void]$form.ShowDialog()
