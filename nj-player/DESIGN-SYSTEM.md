# NJ PLAYER — Design System
## "Cinematic Dark Luxury"

> "No fingerprints. No templates. Every pixel is a first draft."

---

## Creative Direction

**Aesthetic Direction:** Dark Luxury + Cinematic Interface
**Emotion:** Immersive, premium, focused — like a private cinema
**One thing visitors remember:** The feeling of watching content through a premium lens

---

## Color Palette

### Semantic Tokens
```css
:root {
  /* Core */
  --ink: #0a0a0a;           /* Deep black — the void */
  --surface: #121215;       /* Card/panel background */
  --surface-elevated: #1a1a1f; /* Elevated elements */
  --surface-hover: #222228;  /* Hover state */
  
  /* Text */
  --text-primary: #e8e6e3;  /* Primary text — warm white */
  --text-secondary: #8a8a8f; /* Secondary text — muted */
  --text-tertiary: #4a4a52;  /* Hints, placeholders */
  
  /* Accent — Electric Cyan */
  --accent: #00d4ff;        /* Primary accent — the soul */
  --accent-glow: rgba(0, 212, 255, 0.15); /* Glow effect */
  --accent-soft: rgba(0, 212, 255, 0.08); /* Subtle tint */
  
  /* Signal Colors */
  --success: #00ff88;       /* Active, playing, success */
  --warning: #ffb800;       /* Attention, download progress */
  --error: #ff3b5c;         /* Errors, destructive actions */
  
  /* Borders */
  --border: rgba(255, 255, 255, 0.06); /* Subtle dividers */
  --border-hover: rgba(255, 255, 255, 0.12);
  
  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.4);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.5);
  --shadow-lg: 0 8px 32px rgba(0, 0, 0, 0.6);
  --shadow-glow: 0 0 20px rgba(0, 212, 255, 0.2);
  
  /* Gradients */
  --gradient-accent: linear-gradient(135deg, #00d4ff 0%, #0088cc 100%);
  --gradient-surface: linear-gradient(180deg, #121215 0%, #0a0a0a 100%);
}
```

---

## Typography

### Font Stack
- **Display:** 'JetBrains Mono' (monospace, technical, cinematic)
- **Body:** 'Inter' (clean, readable, modern)
- **Mono:** 'JetBrains Mono' (code, status, technical)

### Scale
```css
:root {
  --text-xs: 11px;    /* Hints, labels */
  --text-sm: 13px;    /* Secondary text */
  --text-base: 14px;  /* Body */
  --text-lg: 16px;    /* Emphasis */
  --text-xl: 20px;    /* Subheadings */
  --text-2xl: 28px;   /* Headings */
  --text-hero: 48px;  /* Brand display */
}
```

### Typographic Treatment
- **Headings:** All caps, letter-spacing: 0.08em, font-weight: 600
- **Body:** Normal case, letter-spacing: 0, font-weight: 400
- **Mono:** Used for status, technical info, keyboard shortcuts
- **Labels:** All caps, letter-spacing: 0.1em, font-weight: 500

---

## Spacing Rhythm

### Musical Pacing (8px base unit)
```css
:root {
  --space-1: 4px;    /* Tight */
  --space-2: 8px;    /* Comma */
  --space-3: 12px;   /* Breath */
  --space-4: 16px;   /* Word */
  --space-5: 24px;   /* Phrase */
  --space-6: 32px;   /* Sentence */
  --space-7: 48px;   /* Paragraph */
  --space-8: 64px;   /* Section */
  --space-9: 96px;   /* Scene */
  --space-10: 128px; /* Chapter */
}
```

### Application
- **Tight clusters:** 16px (within components)
- **Breath gaps:** 48px (between related elements)
- **Cinematic pauses:** 96px (between sections)
- **Scene transitions:** 128px (major divisions)

---

## Layout System

### Grid Philosophy
- **Asymmetric balance:** 70/30 splits, not 50/50
- **Negative space as content:** The void is part of the story
- **Overlapping planes:** Depth creates hierarchy

### Z-Depth Layers
1. **Background:** Ambient atmosphere, grain overlay
2. **Surface:** Cards, panels, content containers
3. **Floating:** Controls, buttons, interactive elements
4. **Foreground:** Cursor effects, temporary overlays

---

## Motion Design

### Personality Preset: "Slow Cinematic"
- **Duration:** 600-900ms
- **Easing:** cubic-bezier(0.16, 1, 0.3, 1) — power4.out
- **Effects:** Opacity + translateY + blur only. No bounces.
- **Feel:** Smooth, inevitable, premium

### Micro-Interactions
- **Hover states:** Scale 1.02, glow effect, border highlight
- **Button press:** Scale 0.98, 100ms
- **Panel transitions:** Fade + slide, 400ms
- **Status messages:** Fade in, hold, fade out

### Animation Principles
- **Anticipation:** Elements prepare before moving
- **Follow Through:** Elements overshoot and settle
- **Slow In/Out:** Custom cubic-beziers only
- **Appeal:** Every motion must delight

---

## Visual Atmosphere

### Grain Overlay
```css
.grain::before {
  content: '';
  position: fixed;
  inset: 0;
  background-image: url("data:image/svg+xml,...");
  opacity: 0.03;
  pointer-events: none;
  z-index: 9999;
}
```

### Glassmorphism
```css
.glass {
  background: rgba(18, 18, 21, 0.8);
  backdrop-filter: blur(12px);
  border: 1px solid var(--border);
}
```

### Glow Effects
```css
.glow {
  box-shadow: 0 0 20px var(--accent-glow);
}
```

---

## Component Specifications

### Buttons
```css
.btn {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text-primary);
  padding: 12px 24px;
  border-radius: 8px;
  font-family: var(--font-body);
  font-weight: 500;
  letter-spacing: 0.02em;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  cursor: pointer;
}

.btn:hover {
  background: var(--surface-hover);
  border-color: var(--border-hover);
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.btn--primary {
  background: var(--gradient-accent);
  border: none;
  color: var(--ink);
  font-weight: 600;
}

.btn--primary:hover {
  box-shadow: var(--shadow-glow);
  transform: translateY(-2px);
}
```

### Cards
```css
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: var(--space-5);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.card:hover {
  border-color: var(--border-hover);
  box-shadow: var(--shadow-lg);
}
```

### Inputs
```css
.input {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text-primary);
  padding: 12px 16px;
  border-radius: 8px;
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  transition: border-color 0.2s;
}

.input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-glow);
}
```

---

## Implementation Notes

### WinForms Adaptation
Since this is a PowerShell WinForms app, we adapt web concepts:
- **Colors:** Direct RGB values via System.Drawing.Color
- **Fonts:** System-installed fonts (JetBrains Mono, Inter)
- **Rounded corners:** Owner-draw or panel overlays
- **Grain overlay:** Semi-transparent panel with noise
- **Glow effects:** Colored borders and shadows
- **Transitions:** Timer-based opacity/position animation

### Performance Budget
- **Frame Rate:** 60fps (no jank)
- **Response Time:** <100ms for interactions
- **Load Time:** Immediate (no splash screens)

---

## Anti-Patterns to Avoid

Based on DESIGN-SKILLS.md:
- ❌ Generic Bootstrap-like layouts
- ❌ Boring hero sections
- ❌ Default system fonts without personality
- ❌ White background + black text
- ❌ Box-shadow cards on white
- ❌ Scroll-triggered fade-ins (overused)
- ❌ Generic stock photography
- ❌ Purple/blue gradient hero (AI startup trope)
- ❌ Centered card with shadow on white bg

---

## The "Wow" Moment

Every design must have one unforgettable moment:
**NJ Player:** The cinematic brand reveal on startup — a subtle glow pulse on the logo, followed by a smooth fade-in of the interface with staggered element reveals.

---

## Footer Attribution

> "Seventy-eight doors. One infinite corridor."
> 
> © 2026. Norman James All rights reserved.
> 
> MADE WITH LOVE ❤️ BY EMPATHY STUDIO
> 91 + 9833274308 / 91 + 9833274305

---

*This design system is a living document. Every pixel is a first draft.*
