# NJ Player - Enhancement Upgrades Applied

## Summary
The video enhancement system has been significantly upgraded to provide more visible and impactful improvements. Videos should now look noticeably sharper, more vibrant, and higher quality.

---

## What Was Upgraded

### 1. **Base Quality Improvements (Applied to ALL videos)**
These improvements are active even when enhancements are "OFF":

- **Better Upscaling Algorithm**: Changed from `ewa_lanczos` to `ewa_lanczossharp` for crisper edges
- **Improved Color Processing**: Added proper color primaries (bt.709) and gamma correction (2.2)
- **HDR Tone Mapping**: Uses Hable tone mapping for better contrast and dynamic range
- **Enhanced Saturation**: +10% saturation boost for more vibrant colors
- **Gamma Boost**: +5 gamma adjustment for brighter, more vivid picture
- **Better Downscaling**: Enabled `correct-downscaling` for sharper quality when watching high-res on lower-res displays

### 2. **Lucid Mode Upgrade (CTRL+1)**
**Before**: Only adaptive sharpening (very subtle)
**After**: 
- KrigBilateral shader for better chroma/color upsampling
- Adaptive sharpening with boosted strength (0.5)
- Much more noticeable "pop" and clarity

**Use for**: Web videos, streaming content, general purpose enhancement

### 3. **Cinema Mode Upgrade (CTRL+2)** 
**Before**: Good but conservative
**After**:
- Same shader pipeline but with enhanced settings
- Boosted sharpening strength (0.65) for more dramatic effect
- Improved debanding (4 iterations, threshold 40) for smoother gradients
- Better artifact removal

**Use for**: Downloaded movies, low-res videos, content that needs heavy enhancement

### 4. **Anime Mode (CTRL+3)**
No changes - already optimized for anime/cartoon content

---

## How to Use

1. **Launch a video** (drag & drop onto NJ-Player.bat or use the GUI)
2. **Press F9** to cycle through enhancement presets
3. **Or press CTRL+1/2/3** to jump directly to Lucid/Cinema/Anime
4. The current preset shows as an on-screen message

---

## Expected Results

### Videos Should Now Look:
✓ **Sharper** - Edges are more defined, details pop
✓ **More Vibrant** - Colors are richer and more saturated
✓ **Brighter** - Better gamma makes the image more lively
✓ **Smoother** - Better debanding removes color banding artifacts
✓ **Higher Quality** - Upscaling makes low-res videos look closer to HD

### Before vs After:
- **Dull, flat videos** → Vibrant, dynamic
- **Blurry low-res** → Sharp, detailed
- **Washed out colors** → Rich, saturated colors
- **Dark, murky scenes** → Brighter, more visible

---

## Performance Notes

- **Lucid mode**: Very light GPU usage, works on any system
- **Cinema mode**: Heavy GPU usage (FSRCNNX upscaling), may stutter on older GPUs
  - If Cinema stutters, use Lucid instead or press CTRL+h to toggle hardware decoding
- **Anime mode**: Moderate GPU usage

---

## Testing the Upgrades

To see the difference:
1. Open a video
2. Press CTRL+0 (enhancement OFF) - this is the baseline
3. Press CTRL+1 (Lucid) - notice the sharpness and color improvement
4. Press CTRL+2 (Cinema) - full enhancement pipeline

Compare OFF vs Lucid vs Cinema to see the progressive enhancement levels.

---

## Technical Details

### Shaders Applied:
- **KrigBilateral**: Better chroma upsampling (reduces color blur)
- **FSRCNNX**: Neural network-style upscaling without AI (Cinema only)
- **SSimSuperRes**: Removes ringing artifacts after upscaling (Cinema only)
- **Adaptive-sharpen**: Smart edge enhancement that avoids over-sharpening
- **Anime4K**: Line art restoration and compression artifact removal (Anime only)

### MPV Settings Added:
```
scale=ewa_lanczossharp
target-trc=gamma2.2
target-prim=bt.709
tone-mapping=hable
saturation=10
gamma=5
sharpen=0.5 (Lucid) / 0.65 (Cinema)
```

---

## Troubleshooting

### "Videos still look dull"
- Make sure you're pressing F9 or CTRL+1/2/3 to activate an enhancement preset
- Check that shader files exist in `nj-player/shaders/` folder
- Run `install.ps1` again to re-download shaders if missing

### "Cinema mode stutters"
- Your GPU may not be powerful enough for FSRCNNX upscaling
- Use Lucid mode (CTRL+1) instead - still great quality, much lighter
- Or press CTRL+h to cycle hardware decoding modes

### "Colors look oversaturated"
- Reduce saturation in mpv.conf (change `saturation=10` to `saturation=5` or `saturation=0`)

### "Too sharp/artificial looking"
- Use CTRL+0 for clean playback, or reduce the sharpen values in mpv.conf

---

## Summary

The enhancements are now **much more aggressive and visible**. Even the base config (before applying any preset) now has better colors, brightness, and sharpness. Lucid mode is significantly stronger, and Cinema mode provides Hollywood-level enhancement for low-quality videos.

Test it out and adjust the settings in `mpv.conf` if you want to fine-tune the intensity!
