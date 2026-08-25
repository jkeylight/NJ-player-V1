# NJ Player - On-Screen Controls Guide

## VLC-Style Controls Are Active! ✓

The player now has a full control bar at the bottom of the screen.

## How to See the Controls

**MOVE YOUR MOUSE TO THE BOTTOM OF THE VIDEO WINDOW**

The control bar will fade in automatically when you move your mouse near the bottom edge.

## What You'll See

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                      VIDEO PLAYING HERE                     │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ ▶️ ⏸️  [●────────────────────────────────⚪──] 🔊 ──── 100% │
│ Play  0:15 / 2:30                              Volume      │
└─────────────────────────────────────────────────────────────┘
```

## Control Bar Elements

From left to right:

1. **▶️ Play/Pause button** - Click to toggle playback
2. **⏮️ Previous/⏭️ Next** - Skip between playlist items (if in queue)
3. **⏱️ Time display** - Current position / Total duration
4. **━━━━━━━ Seek bar** - Drag the circle to jump around
5. **🔊 Volume icon** - Click to mute
6. **─── Volume slider** - Drag to adjust volume
7. **⚙️ Settings icon** - Click for quality/subtitle options

## How to Use

### Mouse Controls:
- **Click video** → Play/Pause
- **Move mouse to bottom** → Show controls
- **Click on seek bar** → Jump to that position
- **Drag seek bar circle** → Scrub through video
- **Scroll wheel** → Adjust volume
- **Right-click** → Context menu

### Keyboard Shortcuts:
- **SPACE** → Play/Pause
- **←/→** → Seek backward/forward 5 seconds
- **↑/↓** → Seek backward/forward 60 seconds
- **[/]** → Decrease/increase playback speed
- **f** → Fullscreen
- **m** → Mute/Unmute
- **9/0** → Volume down/up
- **s** → Screenshot
- **q** → Quit

## If Controls Don't Appear

1. **Make sure you're using the updated player:**
   - Close any running mpv windows
   - Launch a video fresh with `NJ-Player.bat`

2. **Move mouse ALL THE WAY to the bottom:**
   - The controls fade in when mouse is near bottom edge
   - Try moving mouse up and down

3. **Check OSC is enabled:**
   - The `osc=yes` line is in mpv.conf (it is!)
   
4. **Test with keyboard:**
   - Even if controls don't show visually, press SPACE to pause/play
   - This confirms the player is working

## Control Appearance Settings

The controls are configured with:
- **Layout**: Bottom bar (like VLC)
- **Seek bar style**: Bar (not slider)
- **Deadzone**: 0.5 (responsive)
- **OSD font**: 40pt (large and readable)

## Still Not Seeing Controls?

Try launching mpv directly with force-window to test:
```
cd C:\Users\norma\OneDrive\Desktop\PROJECTS\NJ-player\nj-player
mpv\mpv.exe --config-dir=. "library/Me at the zoo.mp4"
```

Then move your mouse and see if controls appear.

## Alternative: Use input.conf for Custom Buttons

If the OSC still doesn't show, we can add custom on-screen buttons via Lua scripts. Let me know if you need this!
