# NJ Player

An offline desktop video player with real-time GPU-accelerated video enhancement — a "better Lucid Mode" that goes beyond Opera's one-click sharpener.

- **Fully offline** for downloaded videos — no internet needed
- **No AI** — pure GPU shader algorithms, fast and artifact-light
- **GPU-accelerated** — enhancement applies in real time as the video plays
- **Plays almost everything** — MP4, MKV, AVI, WebM, MOV and more (built on mpv)
- **Self-contained** — everything lives in one folder; works from a USB stick

---

## Quick start

### 1. Install

Open this folder in PowerShell and run:

```powershell
powershell -ExecutionPolicy Bypass -File nj-player/install.ps1
```

This downloads a portable mpv build and the enhancement shaders into the `nj-player/` folder. Nothing is installed system-wide; no admin rights needed.

### 2. Play a video

- **GUI** — double-click `nj-player/NJ-Player-GUI.bat`: browse your folders, pick an enhancement preset, hit **PLAY**.
- **Drag & drop** — drag a video file onto `nj-player/NJ-Player.bat` (or double-click it, then drop files onto the mpv window).

### 3. Enhance

Press **F9** to cycle enhancement presets, or **CTRL+1..3** to jump straight to one. The current mode appears as an OSD message in the corner.

---

## Enhancement presets

| Key | Preset | What it does |
|-----|--------|--------------|
| `CTRL+0` | **Off** | Clean, unmodified playback |
| `CTRL+1` | **Lucid** | Smart adaptive sharpening — the Opera Lucid Mode look, without over-sharpening artifacts |
| `CTRL+2` | **Cinema** | Full pipeline for low-res video: KrigBilateral (better color) → FSRCNNX x2 (upscale) → SSimSuperRes (de-ring) → adaptive sharpen |
| `CTRL+3` | **Anime** | Anime4K — restores line art and removes compression artifacts (also helps on cartoons/2D content) |

`F9` cycles through all four.

---

## Playing web links (YouTube, Twitch, live streams)

In the GUI, paste a link into the **Link** bar at the bottom and hit **Play Link** (or press Enter). Accepted sources:

- **YouTube / Twitch / Vimeo / hundreds of sites** — powered by **yt-dlp** (bundled by `install.ps1`)
- **Direct video files** — `https://example.com/video.mp4`
- **Live streams / HLS** — `https://example.com/stream.m3u8`

Web links need internet; downloaded videos play fully offline. NJ Player prefers H.264/MP4 streams by default (hardware-decodable on almost any GPU). To allow 4K+ or best quality, change `ytdl-format` in `mpv.conf` to `bestvideo+bestaudio/best`.

You can also play links without the GUI — from a terminal: `NJ-Player.bat "https://..."`.

## Saving web streams for offline (the Library)

The **Library** (`nj-player/library/` folder, button at the top of the GUI) stores downloaded videos.

1. Paste a link in the GUI's Link bar
2. Click **Download** — NJ Player downloads it as a Full HD 1080p H.264 MP4 into the Library
3. The status line shows progress; the list refreshes automatically when done

One download at a time. Playlist links save only the first video.

---

## Right-click "Open with NJ Player" (Windows)

Run once to register a **right-click menu item** on every file:

```powershell
powershell -ExecutionPolicy Bypass -File nj-player/associate.ps1
```

What it registers (per-user, in `HKCU\Software\Classes` — no admin needed):

- **Right-click menu** → plays the file directly in NJ Player
- **"Clear NJ Player History"** → wipes resume positions without opening the GUI
- **"Open with" dialog** entry for all supported video types

To undo: `powershell -ExecutionPolicy Bypass -File nj-player/associate.ps1 -Remove`

If the menu item doesn't appear immediately, restart File Explorer. If you move the folder, re-run the script to update the registered paths.

## Desktop icon

```powershell
powershell -ExecutionPolicy Bypass -File nj-player/desktop-shortcut.ps1
```

Puts an **NJ Player** icon on your Desktop (launches the GUI). Remove with `-Remove`.

---

## All hotkeys

| Key | Action |
|-----|--------|
| `F9` | Cycle enhancement presets |
| `CTRL+0` / `1` / `2` / `3` | Pick preset: Off / Lucid / Cinema / Anime |
| `CTRL+d` | Toggle debanding (removes color banding in dark scenes) |
| `CTRL+SHIFT+1` | Toggle the sharpening shader on top of the current preset |
| `CTRL+h` | Cycle hardware decoding (try if video stutters) |
| `CTRL+BACKSPACE` | Clear the resume position of just the current video |
| `TAB` then `2` | Show tech stats — active shader passes listed |

Plus all standard mpv controls: `space` play/pause, `←`/`→` seek 5s, `↑`/`↓` seek 60s, `[`/`]` speed, `f` fullscreen, `m` mute, `s` screenshot.

---

## Project structure

```
nj-player/
├── NJ-Player-GUI.bat      <- launcher GUI (double-click me)
├── NJ-Player-GUI.ps1      <- the GUI itself (PowerShell WinForms)
├── NJ-Player.bat           <- drag-and-drop launcher
├── install.ps1             <- one-time setup (downloads mpv + shaders)
├── associate.ps1           <- right-click menu registration (+ -Remove)
├── desktop-shortcut.ps1    <- desktop icon (+ -Remove)
├── clear-history.ps1       <- clears resume positions standalone
├── make-icon.ps1           <- draws the NJ Player logo (nj-player.ico)
├── nj-player.ico           <- custom logo
├── mpv.conf                <- core config + enhancement profiles
├── input.conf              <- extra hotkeys
├── scripts/
│   └── nj-presets.lua      <- preset switching (F9, CTRL+0..3) + resume control
├── mpv/                    <- mpv + yt-dlp + ffmpeg (created by install.ps1)
├── shaders/                <- enhancement shaders (created by install.ps1)
│   ├── adaptive-sharpen.glsl
│   ├── KrigBilateral.glsl
│   ├── SSimSuperRes.glsl
│   ├── FSRCNNX_x2_16-0-4-1.glsl
│   ├── Anime4K_Restore_CNN_Soft_M.glsl
│   └── Anime4K_Upscale_CNN_x2_M.glsl
└── library/                <- downloaded web videos (created on first download)
```

Everything is self-contained — move the folder anywhere (USB stick included) and it keeps working. To uninstall, delete the folder.

---

## History & privacy

NJ Player resumes videos where you left off (`save-position-on-quit`). History is stored in `watch_later/` inside the project folder — fully portable.

- **Clear all history**: GUI → **Clear History**, or right-click any file → **Clear NJ Player History**
- **Clear one video**: press `CTRL+BACKSPACE` while watching

---

## Customizing

- **Change enhancement strength** — edit `mpv.conf`: the `[nj-lucid]` and `[nj-cinema]` profiles list the shader files. Add or remove lines; shaders apply in the order listed.
- **Add shaders** — drop new `.glsl` files into `shaders/` and reference them from a profile in `mpv.conf`.
- **Start with enhancement on** — add `profile=nj-lucid` as the *first* line of `mpv.conf`.

## Updating

Re-run `install.ps1 -Force` to re-download mpv, yt-dlp, ffmpeg, and shaders.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Video stutters on Cinema preset | GPU is doing heavy upscaling. Use `CTRL+1` (Lucid) instead, or press `CTRL+h` to toggle hardware decoding |
| YouTube link won't play | Run `install.ps1` again so yt-dlp is present; verify the link works in a browser first |
| Shaders not applying | Press `TAB` then `2` to check active passes. If missing, run `install.ps1` again |
| mpv.exe won't start ("DLL not found") | Install the [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe), or edit `$MpvUrl` in `install.ps1` to use the MinGW build |
| Playback position not remembered | Check that `save-position-on-quit=yes` is in `mpv.conf` |
| Video judders with interpolation | Set `interpolation=no` in `mpv.conf` |
| Wrong volume | Volume max is 200% (`volume-max=200` in `mpv.conf`) |
| GUI won't open / crashes silently | Ensure PowerShell 5.1+ is available. Try running from PowerShell directly: `powershell -ExecutionPolicy Bypass -File NJ-Player-GUI.ps1` |

---

## Roadmap

- Thumbnail grid view — browse all videos as a poster wall
- Preset remembered per file type
- Playlist support — download or queue all videos from a playlist link

---

## License

Built on [mpv](https://mpv.io), [yt-dlp](https://github.com/yt-dlp/yt-dlp), [ffmpeg](https://ffmpeg.org), and community shaders. All components are open-source.
