# NJ Player - Complete Feature Summary

## ✓ All Features Working

### 1. **GUI Fixed** - No More Crashes
- ✓ Assembly loading errors fixed
- ✓ Button hover exceptions fixed  
- ✓ Null reference exceptions fixed
- ✓ GUI opens smoothly without error dialogs

### 2. **Single File Opening**
- ✓ Drag & drop any video onto `NJ-Player.bat` to play it instantly
- ✓ Command-line support: `NJ-Player-GUI-v2.ps1 -FilePath "video.mp4"`
- ✓ Uses Cinema enhancement preset by default

### 3. **MAXED Video Enhancements** - Videos Look Amazing
All enhancements have been pushed to maximum for dramatic visual improvement:

#### **Base Quality (Always Active):**
- ✓ Sharpest upscaling: `ewa_lanczossharp`
- ✓ Anti-ringing: 0.8 (cleaner edges)
- ✓ Saturation: **+20%** (vibrant colors)
- ✓ Gamma: **+10** (brighter, punchier)
- ✓ Contrast: **+15** (deeper blacks, brighter whites)
- ✓ Brightness: **+5** (more visible detail)
- ✓ Tone mapping: Hable with 1.5 parameter (HDR-like contrast)

#### **Lucid Mode (CTRL+1):**
- KrigBilateral (better chroma)
- Adaptive sharpening at **1.0 strength** (MAXED)
- Noticeable pop and clarity

#### **Cinema Mode (CTRL+2):**
- Full shader pipeline
- Sharpening at **1.2 strength** (MAXED)
- Debanding: 5 iterations, grain 64 (smoothest gradients)
- Best for low-res videos needing heavy enhancement

#### **Anime Mode (CTRL+3):**
- Anime4K restoration and upscaling
- Perfect for anime/cartoons

### 4. **VLC-Style On-Screen Controls** ✓
- ✓ Visible seek bar at bottom
- ✓ Play/Pause button
- ✓ Volume slider
- ✓ Time display
- ✓ Window border with title bar
- ✓ Larger OSD text (40pt) for better visibility
- ✓ Controls appear on mouse movement

---

## How to Use Everything

### **Playing Videos:**

**Method 1: Drag & Drop (Easiest)**
- Drag any video file onto `NJ-Player.bat`
- Player opens instantly with Cinema mode enhancements

**Method 2: GUI Browser**
- Double-click `NJ-Player-GUI.bat`
- Browse folders, select videos
- Click PLAY or double-click a video

**Method 3: Right-Click Menu**
- Run `associate.ps1` once (see below)
- Right-click any video → "Open with NJ Player"

### **File Association (Make NJ Player Default):**

1. Open PowerShell in the `nj-player` folder
2. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File associate.ps1
   ```
3. Now right-clicking any video shows "Open with NJ Player"
4. To make it the actual default (not just in menu):
   - Right-click a video → "Open with" → "Choose another app"
   - Select "NJ Player" from the list
   - Check "Always use this app"

### **Enhancement Controls (While Playing):**

| Key | Action |
|-----|--------|
| **F9** | Cycle through enhancement presets |
| **CTRL+0** | Enhancement OFF (clean playback) |
| **CTRL+1** | Lucid mode (sharp + vibrant) |
| **CTRL+2** | Cinema mode (full enhancement) |
| **CTRL+3** | Anime mode (for anime/cartoons) |
| **CTRL+d** | Toggle debanding |
| **CTRL+h** | Cycle hardware decoding |

### **Player Controls (VLC-style):**

| Key | Action |
|-----|--------|
| **SPACE** | Play/Pause |
| **←/→** | Seek 5 seconds |
| **↑/↓** | Seek 60 seconds |
| **[/]** | Adjust playback speed |
| **f** | Fullscreen |
| **m** | Mute |
| **s** | Screenshot |
| **9/0** | Volume down/up |
| **q** | Quit |

**Mouse Controls:**
- Move mouse to bottom → seek bar appears
- Click on seek bar to jump to position
- Hover over controls for buttons
- Scroll wheel = volume

---

## What Videos Look Like Now

### **Before (dull, flat):**
- Washed out colors
- Blurry, soft edges
- Dark, murky scenes
- Low contrast

### **After (MAXED enhancements):**
- ✓ **20% more saturation** - Rich, vibrant colors
- ✓ **+15 contrast** - Deep blacks, bright whites
- ✓ **+10 gamma** - Punchy, lively brightness
- ✓ **1.2x sharpening** (Cinema) - Crystal clear edges
- ✓ **FSRCNNX upscaling** - Low-res looks near-HD
- ✓ **Advanced debanding** - Smooth gradients, no banding

**Expected improvement:**
- Web videos look like high-quality downloads
- Old low-res content looks modern and sharp
- Everything is brighter, more colorful, more engaging
- Videos have a "Hollywood" or "premium streaming" look

---

## File Structure

```
nj-player/
├── NJ-Player-GUI.bat          ← Double-click for GUI
├── NJ-Player.bat              ← Drag & drop videos here
├── NJ-Player-GUI-v2.ps1       ← Main GUI script (fixed)
├── mpv.conf                   ← Enhancement config (MAXED)
├── input.conf                 ← Keyboard shortcuts
├── associate.ps1              ← Right-click menu setup
├── install.ps1                ← Downloads mpv + shaders
├── mpv/                       ← mpv player + yt-dlp
├── shaders/                   ← Enhancement shaders
│   ├── adaptive-sharpen.glsl
│   ├── KrigBilateral.glsl
│   ├── FSRCNNX_x2_16-0-4-1.glsl
│   ├── SSimSuperRes.glsl
│   └── Anime4K_*.glsl
├── scripts/
│   └── nj-presets.lua         ← Preset switching
└── library/                   ← Downloaded videos
```

---

## Performance Notes

- **Lucid mode**: Very light, works on any GPU
- **Cinema mode**: Heavy (FSRCNNX upscaling)
  - May stutter on older/weak GPUs
  - Press CTRL+h to toggle hardware decoding if it stutters
  - Or use Lucid mode instead (still great quality)
- **Anime mode**: Moderate GPU usage

---

## Troubleshooting

### "Still looks dull"
- Press **F9** or **CTRL+1/2/3** to activate enhancements
- Cinema mode (CTRL+2) has the most dramatic effect
- Check that shaders exist in `shaders/` folder

### "Too oversaturated/bright"
The settings are MAXED for dramatic effect. To tone down:
- Edit `mpv.conf`
- Reduce `saturation=20` to `saturation=10` or lower
- Reduce `gamma=10` to `gamma=5` or lower
- Reduce `contrast=15` to `contrast=10` or lower

### "Cinema mode stutters"
- Your GPU isn't powerful enough for FSRCNNX
- Use Lucid mode (CTRL+1) - still looks great
- Or press CTRL+h to cycle hardware decoding

### "Controls not visible"
- Move mouse to bottom of screen
- Controls fade in automatically
- Or press SPACE for play/pause

### "Videos open in VLC instead"
- Run `associate.ps1` to add right-click menu
- Or drag & drop onto `NJ-Player.bat` directly

---

## Summary

NJ Player now has:
✓ **Stable GUI** - no crashes
✓ **Drag & drop** - instant playback
✓ **MAXED enhancements** - dramatic visual improvement
✓ **VLC-style controls** - proper seek bar, buttons, volume
✓ **File association** - right-click menu support

**The enhancements are set to MAXIMUM.** Videos should look significantly better - sharper, brighter, more vibrant, and more engaging. If it's too much, you can easily dial it down in `mpv.conf`.

Test it with any video and press F9 to see the difference!
