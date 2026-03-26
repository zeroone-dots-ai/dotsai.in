# Quantum Dot Cursor — Architecture

> File: `public/index.html` → search `QUANTUM DOT CURSOR`

## Overview

Custom cursor system replacing the browser default. Canvas-based, full-viewport, z-index 999999.

## Components

### 1. Inner Dot
- Size: 3.5px radius
- Position: exact mouse position (no lag)
- Color: cycles through D.O.T.S palette via `colorT` timer
- Has radial gradient glow (3× radius)

### 2. Outer Ring
- Rest radius: 22px
- Position: spring-physics lag behind mouse
- Spring: stiffness 0.10, damping 0.74 (hover: 0.14 / 0.70)
- Stretches along velocity direction: `stretch = speed * 0.06` (max 0.9)
- On hover over links: fills with 12% alpha, rotating label text

### 3. Nebula Trail
- Last 14 mouse positions stored
- Each point renders as fading dot (opacity by age + position index)
- Connecting line at 6% alpha

### 4. Hover State
- Detects: `a`, `button`, `[role=button]`, `.btn-primary`, `.btn-secondary`, `.service-row`, `.nav-cta`
- Ring fills + label text rotates around ring at `time * 0.001` rad/s
- Label: first 12 chars of element text, uppercase, 7px Space Mono

### 5. Click Nova
- 12 particles burst radially
- Speed: 3–8px/frame, friction 0.92
- Life: 1.0 → 0, each frame −0.04 × dt
- Color: random D.O.T.S palette

## Color Palette (cycles)
```javascript
[200, 182, 255]  // lavender (Data)
[184, 224, 210]  // mint (Operations)
[255, 205, 178]  // peach (Tech)
[162, 210, 255]  // sky (Strategy)
```
Cycle speed: `colorT += 0.008 * dt`

## CSS Impact
```css
body, a, button, etc. { cursor: none !important; }
#qc-canvas { position: fixed; inset: 0; z-index: 999999; pointer-events: none; }
```
