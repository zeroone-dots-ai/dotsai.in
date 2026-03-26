# Hero Galaxy — Architecture

> File: `public/index.html` → search `HERO GALAXY v3`

## Overview

Canvas 2D (not Three.js) spiral galaxy in the hero section.
Chosen over Three.js for better click interaction and lower overhead.

## Star System

| Layer | Z range | Count share | Size | Brightness | Color |
|-------|---------|-------------|------|------------|-------|
| Far/deep | 0–0.26 | ~35% | 0.15–0.7px | Dim | Blue-white |
| Mid | 0.26–0.73 | ~45% | 0.32–1.5px | Medium | D.O.T.S palette |
| Near | 0.73–1.0 | ~20% | 0.8–5.8px | Bright + halos | D.O.T.S palette |

**Total:** 4000 stars (desktop) · 1600 (mobile)  
**Render order:** Far → near (painter's algorithm, sorted by z)

## Galaxy Layout

```
W=viewport width, H=viewport height

Galaxy core:     GCX=W*0.18, GCY=H*0.50  (left side)
Spiral arms:     3 arms, 9π wind, extend to 95% of max(W,H)
D.O.T.S orbit:  cx=W*0.76, cy=H*0.72     (bottom-right)
Infinity orbit:  cx=W*0.74, cy=H*0.10    (top-right, above text)
```

## Nebulae (5 glow patches)

| Name | Position | Color | Purpose |
|------|----------|-------|---------|
| Core | 18%x 50%y | White | Galactic core anchor |
| Left arm | 10%x 28%y | Lavender | Core glow extension |
| Bottom-left | 14%x 75%y | Mint | Dust lane |
| Far right | 88%x 45%y | Sky blue | Arm tip (text area stays clear) |
| D.O.T.S zone | 76%x 72%y | Peach | Atmosphere around planet |

## Physics

```
Spring constant:     0.003 (stars return to base position)
Friction:            0.96 per frame
Hover radius:        130px
Hover force:         0.26 × z_depth (near stars react more)
Click radius:        260px
Click force:         force² × 12 / mass
```

## D.O.T.S Planet

4 brand-colored dots orbiting in formation at bottom-right.

```javascript
DOTS.orbitCx = W*0.76   // orbit center
DOTS.orbitCy = H*0.72
DOTS.orbitRx = W*0.09   // ellipse radii
DOTS.orbitRy = H*0.07
DOTS.orbitAngle += 0.00008  // per frame (very slow)
```

**Shield system:**
- Outer ring: rotates at `time * 0.22` (dashed, lavender)
- Inner ring: counter-rotates at `time * 0.38` (dashed, mint)
- On hover: `shieldGlow` ramps to 1.0
- On click: ripple rings spawn + DOTS bounce away, spring back

## To Modify

### Move the galaxy core
```javascript
var GCX = W*0.18, GCY = H*0.50;  // change these
```

### Move the D.O.T.S planet
```javascript
DOTS.orbitCx = W*0.76; DOTS.orbitCy = H*0.72;  // change these
```

### Change star count
```javascript
var COUNT = isMobile ? 1600 : 4000;  // change these
```

### Add/change nebulae
```javascript
nebulae = [
  { x: W*0.18, y: H*0.50, rx: W*0.16, ry: H*0.22, r:255, g:255, b:255, a:0.055 },
  // add more here
];
```
