<#
.SYNOPSIS
    Generate the NJ Player logo icon (nj-player.ico).

.DESCRIPTION
    Draws the NJ Player logo - a dark rounded square with a cyan play
    triangle and an "NJ" monogram - at multiple sizes and packs them
    into a single .ico (16/24/32/48/64/128/256). Also writes a preview
    HTML (preview-icon.html) so you can look at the result in a browser.

    Usage:
        powershell -ExecutionPolicy Bypass -File make-icon.ps1
#>

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$IcoPath = Join-Path $Root "nj-player.ico"

Add-Type -AssemblyName System.Drawing

$SIZES = @(16, 24, 32, 48, 64, 128, 256)

function New-RoundedRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-LogoBitmap([int]$size) {
    $S = $size / 256.0
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # ---- dark rounded-square background ----
    $bgPath = New-RoundedRectPath (10 * $S) (10 * $S) (236 * $S) (236 * $S) (46 * $S)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)), (New-Object System.Drawing.PointF($size, $size)),
        [System.Drawing.Color]::FromArgb(255, 46, 46, 64),
        [System.Drawing.Color]::FromArgb(255, 18, 18, 28))
    $g.FillPath($bgBrush, $bgPath)
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 78, 78, 104), [float](2.5 * $S))
    $g.DrawPath($borderPen, $bgPath)

    # ---- cyan play triangle (left) ----
    $pts = @(
        (New-Object System.Drawing.PointF([float](58 * $S), [float](94 * $S))),
        (New-Object System.Drawing.PointF([float](58 * $S), [float](162 * $S))),
        (New-Object System.Drawing.PointF([float](126 * $S), [float](128 * $S)))
    )
    $triBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)), (New-Object System.Drawing.PointF($size, $size)),
        [System.Drawing.Color]::FromArgb(255, 130, 230, 248),
        [System.Drawing.Color]::FromArgb(255, 36, 178, 214))
    $g.FillPolygon($triBrush, $pts)

    # ---- "NJ" monogram (right) ----
    if ($size -ge 48) {
        $fontSize = [float](58 * $S)
        $font = New-Object System.Drawing.Font("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $region = New-Object System.Drawing.RectangleF([float](136 * $S), [float](70 * $S), [float](110 * $S), [float](116 * $S))
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 240, 240, 250))
        $g.DrawString("NJ", $font, $textBrush, $region, $sf)
        $textBrush.Dispose()
        $font.Dispose()
    }

    $bgPath.Dispose(); $bgBrush.Dispose(); $borderPen.Dispose(); $triBrush.Dispose()
    $g.Dispose()
    return $bmp
}

function Get-LogoPngBytes([int]$size) {
    $bmp = New-LogoBitmap $size
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose(); $bmp.Dispose()
    return $bytes
}

# DIB (BITMAPINFOHEADER + BGRA pixels + AND mask) - the classic ICO format
# that every Windows version and System.Drawing can read. Used for the
# smaller sizes; the 256px entry uses PNG (also universally supported).
function Get-LogoDibBytes([int]$size) {
    $bmp = New-LogoBitmap $size

    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $ptr = $data.Scan0

    $xorLen = $size * $size * 4
    $rowBytes = [int][math]::Ceiling($size / 8.0)
    $rowBytesPadded = [int]([math]::Ceiling($rowBytes / 4.0) * 4)
    $andLen = $rowBytesPadded * $size

    $dib = New-Object byte[] (40 + $xorLen + $andLen)

    # BITMAPINFOHEADER (40 bytes)
    [Array]::Copy([BitConverter]::GetBytes([int32]40),   0, $dib, 0, 4)   # biSize
    [Array]::Copy([BitConverter]::GetBytes([int32]$size), 0, $dib, 4, 4)  # biWidth
    [Array]::Copy([BitConverter]::GetBytes([int32]($size * 2)), 0, $dib, 8, 4)  # biHeight (XOR+AND)
    [Array]::Copy([BitConverter]::GetBytes([int16]1),     0, $dib, 12, 2)  # biPlanes
    [Array]::Copy([BitConverter]::GetBytes([int16]32),    0, $dib, 14, 2)  # biBitCount
    [Array]::Copy([BitConverter]::GetBytes([int32]0),     0, $dib, 16, 4)  # biCompression (BI_RGB)
    [Array]::Copy([BitConverter]::GetBytes([int32]($xorLen + $andLen)), 0, $dib, 20, 4)  # biSizeImage

    # XOR bitmap: BGRA rows, bottom-up
    for ($y = 0; $y -lt $size; $y++) {
        $srcRow = $size - 1 - $y
        $srcAddr = [IntPtr]::Add($ptr, $srcRow * $stride)
        [System.Runtime.InteropServices.Marshal]::Copy($srcAddr, $dib, 40 + $y * ($size * 4), $size * 4)
    }

    $bmp.UnlockBits($data)
    $bmp.Dispose()
    # AND mask: zeroed = fully opaque (alpha channel carries transparency)
    return $dib
}

# ---- assemble the .ico (DIB for <256px, PNG for 256px) ----
$blobs = @()
foreach ($s in $SIZES) {
    if ($s -ge 256) { $blobs += ,(Get-LogoPngBytes $s) } else { $blobs += ,(Get-LogoDibBytes $s) }
}

$fs = [System.IO.File]::Create($IcoPath)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([uint16]0)                       # reserved
$bw.Write([uint16]1)                       # type: icon
$bw.Write([uint16]$blobs.Count)            # image count
$offset = 6 + 16 * $blobs.Count
for ($i = 0; $i -lt $blobs.Count; $i++) {
    $dim = if ($SIZES[$i] -ge 256) { 0 } else { $SIZES[$i] }
    $bw.Write([byte]$dim)                  # width  (0 = 256)
    $bw.Write([byte]$dim)                  # height (0 = 256)
    $bw.Write([byte]0)                     # palette
    $bw.Write([byte]0)                     # reserved
    $bw.Write([uint16]1)                   # planes
    $bw.Write([uint16]32)                  # bpp
    $bw.Write([uint32]$blobs[$i].Length)   # data size
    $bw.Write([uint32]$offset)             # data offset
    $offset += $blobs[$i].Length
}
# Note: write blob data via FileStream (BinaryWriter.Write(byte[]) binds to
# the wrong overload under PowerShell 5.1 and writes only 1 byte per blob).
foreach ($blob in $blobs) { $fs.Write($blob, 0, $blob.Length) }
$bw.Close()
Write-Host "  [ok] wrote $IcoPath ($($blobs.Count) sizes, $([math]::Round((Get-Item $IcoPath).Length / 1KB)) KB)"

# ---- preview HTML for visual inspection ----
$prevDir = Join-Path $Root "assets"
New-Item -ItemType Directory -Force -Path $prevDir | Out-Null
$rows = ""
foreach ($s in 16, 32, 48, 256) {
    $bmp = New-LogoBitmap $s
    $bmp.Save((Join-Path $prevDir "logo-$s.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $rows += "<td style='text-align:center;padding:12px'><img src='logo-$s.png' style='image-rendering:auto'/><div style='font-family:Segoe UI;color:#999;margin-top:6px'>${s}px</div></td>`n"
}
$html = @"
<!DOCTYPE html><html><head><meta charset='utf-8'><style>body{background:#12121a;font-family:Segoe UI}</style></head>
<body><table><tr>$rows</tr></table></body></html>
"@
[System.IO.File]::WriteAllText((Join-Path $prevDir "preview-icon.html"), $html)
Write-Host "  [ok] preview: assets/preview-icon.html"
