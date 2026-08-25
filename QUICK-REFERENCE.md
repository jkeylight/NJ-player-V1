# NJ Player - Quick Reference

## Fixed Configuration Issues ✓
The enhancement settings now use proper mpv syntax with VIDEO FILTERS.

## Current Active Enhancements

### Always Active (Base):
```
contrast: 1.15 (15% boost)
brightness: 0.05 (5% boost)
gamma: 1.10 (10% boost)
saturation: 1.20 (20% boost)
```

These apply to ALL videos automatically — now via `scripts/nj-quality.lua`
(mpv's brightness/contrast/saturation/gamma properties), so you can
**adjust or disable them live** instead of editing a config file:

- **F2** — on-screen quality menu (arrows + ENTER)
- **ALT+↑/↓** then **ALT+←/→** — quick tweak with OSD readout
- **ALT+B** — color boost on/off · **ALT+0** — reset to neutral
- **GUI: PICTURE button** — sliders dialog (next to the preset picker)

Your values persist in `.quality.txt` (shared by GUI and player).

### Press F9 or CTRL+0/1/2/3 to Switch:

- **CTRL+0** - Enhancement OFF (clean, original video)
- **CTRL+1** - Lucid Mode (KrigBilateral + adaptive-sharpen)
- **CTRL+2** - Cinema Mode (full shader pipeline: KrigBilateral → FSRCNNX upscale → SSimSuperRes → adaptive-sharpen)
- **CTRL+3** - Anime Mode (Anime4K restoration)

## What You Should See Now

The video should look:
- **More vibrant** - 20% more saturated colors
- **Brighter** - 5% brightness + 10% gamma boost
- **Higher contrast** - 15% deeper blacks and brighter whites
- **Sharper** - When using Lucid/Cinema modes

## Testing the Enhancements

1. **Test base enhancements:**
   - Open any video
   - It should immediately look more vibrant and bright
   - Compare to the original by watching in another player (VLC)

2. **Test shader enhancements:**
   - Press **CTRL+1** (Lucid) - adds sharpening
   - Press **CTRL+2** (Cinema) - adds upscaling + heavy enhancement
   - You should see an OSD message showing which mode is active

3. **Compare OFF vs Cinema:**
   - Press **CTRL+0** (OFF) - see the dull original
   - Press **CTRL+2** (Cinema) - see the full enhancement
   - The difference should be dramatic

## On-Screen Controls

- Move mouse to bottom → seek bar appears
- Click to play/pause
- Drag seek bar to jump around
- Scroll wheel for volume

## If You Still Don't See Changes

The video filter is now correctly configured. If it's still not visible:

1. **Make sure you're testing with a dull/low-quality video** - high-quality content won't show as much improvement
2. **Try Cinema mode (CTRL+2)** - most dramatic
3. **Check mpv is using the config** - it should show enhancement messages when you press F9

## Adjust if Too Strong

The color boost is adjustable live — no file editing:

1. Press **F2** while watching → arrows + ENTER (Color Boost toggles it, Reset Picture zeroes it)
2. Or press **ALT+B** to toggle the boost instantly
3. Or use the **PICTURE** button in the NJ Player GUI (sliders)

For milder values, set them once with F2 (e.g. contrast +8, saturation +10)
— they're saved in `.quality.txt` and apply from then on.

## VLC-Style Touches

- **Right-click the video** → VLC-style menu (playback, speed, A-B loop,
  audio, video, subtitles, snapshot, media info)
- **VLC keys**: v (subtitle track), b (audio track), a (aspect ratio),
  n/p (next/previous), t (show time), g/h (subtitle delay), SHIFT+s (snapshot)
