# Splash Animation — Architecture

> File: `public/index.html` → search `SPLASH ANIMATION`

## Overview

Runs on every page load. 6 GSAP variants chosen randomly. 
Auto-dismisses after 5s or user clicks SKIP.

## Variants

| ID | Name | Description |
|----|------|-------------|
| V1 | SEQUENTIAL | Dots appear one by one, wordmark fades in |
| V2 | ORBIT | Dots orbit from off-screen into formation |
| V3 | SCAN | Horizontal scan line reveals dots |
| V4 | GALAXY BURST | Dots burst from center like supernova |
| V5 | CONSTELLATION | Dots scatter to random positions, connect with lines, snap to grid |
| V6 | GLITCH BOOT | Corrupted start, hard-cut clean, sequential glow |

## Random Selection Logic
```javascript
// Never repeats same variant twice in a row
let v = Math.floor(Math.random() * sRunners.length)
if (v === sCurrent && sRunners.length > 1) {
  v = (v + 1 + Math.floor(Math.random() * (sRunners.length - 1))) % sRunners.length
}
```

## DOM Structure
```
#splash-overlay (fixed, full-screen, z-index 200)
  #s-canvas (galaxy particle canvas behind logo)
  #s-logo-wrap
    .s-dot × 9 (3×3 grid, 4 colored + 5 ghost)
    #s-wordmark → "ZEROONE"
    #s-brandName → "D.O.T.S AI"
    .s-brand-sub → "D · O · T · S"
    #s-tagline
  #splash-skip (button)
```

## Dismiss Flow
```
User clicks SKIP  (or 5s timer fires)
  → _splashDismissed guard (prevents double-call)
  → overlay.classList.add('hiding')  → CSS fade-out (0.8s)
  → setTimeout 800ms:
      overlay.remove()
      window.scrollTo(0, 0)
      #main-page.classList.add('visible')
      initMainPage()  → GSAP entrance + ScrollTrigger setup
```

## Adding a New Variant
1. Write `function sRunV7() { ... }` using GSAP
2. Add to `sRunners` array: `const sRunners = [sRunV1, ..., sRunV7]`
3. Add name to `NAMES` array: `const NAMES = ['SEQUENTIAL', ..., 'YOUR NAME']`
4. Call `sResetAll()` at the start of your function
