# NJ Player — Instructions

## First-Time Setup

1. Open the `nj-player/` folder in PowerShell
2. Run the installer:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

This downloads mpv and shaders into the folder. No admin rights needed. One-time only.

---

## Launching

| Method | How |
|--------|-----|
| **GUI** | Double-click `NJ-Player-GUI.bat` |
| **Drag & Drop** | Drag a video onto `NJ-Player.bat` |
| **Desktop Shortcut** | Run `desktop-shortcut.ps1` once, then click "NJ Player" on desktop |

---

## Playing Videos

- Open the GUI → click **BROWSE** to select a folder → double-click a video or select and click **PLAY**
- Drag a video file directly onto `NJ-Player.bat`
- Drop files onto the mpv window that opens

---

## Enhancement Presets

| Key | Preset | Best For |
|-----|--------|----------|
| `CTRL+0` | Off | Clean playback |
| `CTRL+1` | Lucid | General sharpening |
| `CTRL+2` | Cinema | Low-res video restoration |
| `CTRL+3` | Anime | Animation / 2D content |
| `F9` | Cycle | Toggle through all presets |

---

## Video Quality Controls

| Key | Action |
|-----|--------|
| `F2` | Open picture settings (brightness/contrast/saturation/gamma/hue) |
| `ALT+Left/Right` | Quick-adjust brightness |
| `ALT+Up/Down` | Quick-adjust contrast |
| `ALT+0` | Reset to defaults |
| `ALT+B` | Color boost (cinematic look) |

Settings are saved permanently in `.quality.txt`.

---

## Stream Quality (Web Links)

| Key | Action |
|-----|--------|
| `F3` | Show available resolutions for web links and switch |

---

## Right-Click Menu (VLC-Style)

Right-click the video window for:
- Play / Pause / Stop
- Jump forward/backward
- Speed control (0.25x – 2x)
- A-B loop
- Audio / Video / Subtitle submenus
- Aspect ratio
- Deinterlace
- Snapshot
- Media info

---

## Queue / Playlist

1. Select a video → click **+ ADD TO QUEUE**
2. Add multiple videos
3. Click **PLAY QUEUE** to play them in order

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `SPACE` | Play / Pause |
| `F` | Fullscreen |
| `ESC` | Exit fullscreen |
| `LEFT/RIGHT` | Seek ±5s |
| `UP/DOWN` | Seek ±30s |
| `M` | Mute |
| `V` | Subtitles |
| `B` | Audio track |
| `A` | Aspect ratio |
| `N` / `P` | Next / Previous |
| `T` | Show time |
| `G` / `H` | Subtitle delay |
| `SHIFT+S` | Snapshot |
| `Q` | Quit |

---

## Files Overview

| File | Purpose |
|------|---------|
| `NJ-Player-GUI.bat` | Launch the GUI |
| `NJ-Player.bat` | Drag-and-drop launcher |
| `nj-player/install.ps1` | One-time installer |
| `nj-player/NJ-Player-GUI-v2.ps1` | GUI script (dark theme) |
| `nj-player/scripts/nj-quality.lua` | Video quality engine |
| `nj-player/scripts/nj-menu.lua` | Right-click context menu |
| `nj-player/mpv.conf` | Player configuration |
| `nj-player/input.conf` | Keyboard shortcuts |
| `nj-player/shaders/` | GPU enhancement shaders |

---

## Troubleshooting

- **GUI freezes on launch** — Make sure you ran `install.ps1` first
- **"mpv not found"** — Run `install.ps1` to download mpv
- **No videos showing** — Click BROWSE and select a folder with video files
- **Enhancement not working** — Check your GPU supports OpenGL, press `CTRL+1` to enable Lucid
