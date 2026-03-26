# Design System — dotsai.in

> Complete design tokens, typography, color, animation, layout spec

---

## CSS Custom Properties (globals.css)

```css
:root {
  /* ── Backgrounds ── */
  --bg-cream:       #FDFCFA;   /* main body — cream white */
  --bg-dark:        #06060a;   /* hero section — deepest black */
  --bg-dark-mid:    #0c0c14;   /* proof section — deep dark */
  --bg-dark-light:  #1a1a2e;   /* dark card backgrounds */

  /* ── Text ── */
  --text-primary:   #191924;   /* near black — on cream */
  --text-light:     #eae8f2;   /* cream text — on dark */
  --text-muted:     #5e586e;
  --text-dim:       #9b95ae;   /* captions, secondary */

  /* ── D.O.T.S. Accents ── */
  --dots-data:       #C8B6FF;  /* lavender — Private AI */
  --dots-operations: #B8E0D2;  /* mint — Platform/Automation */
  --dots-tech:       #FFCDB2;  /* peach — AI Web */
  --dots-strategy:   #A2D2FF;  /* sky blue — GEO AI */

  /* ── Gradient Presets ── */
  --gradient-aurora:  linear-gradient(135deg, #C8B6FF, #A2D2FF, #B8E0D2);
  --gradient-warmth:  linear-gradient(135deg, #FFCDB2, #FFB5C2, #C8B6FF);
  --gradient-hero:    linear-gradient(180deg, #06060a 0%, #0c0c14 100%);

  /* ── Typography ── */
  --font-display:   'Instrument Serif', Georgia, serif;
  --font-body:      'DM Sans', system-ui, sans-serif;
  --font-mono:      'Space Mono', 'Courier New', monospace;

  /* ── Display Scale (desktop) ── */
  --text-display:   clamp(64px, 9vw, 140px);   /* H1 hero */
  --text-h2:        clamp(40px, 5.5vw, 80px);
  --text-h3:        clamp(24px, 3vw, 40px);
  --text-body-lg:   clamp(17px, 1.1vw, 20px);
  --text-body:      clamp(15px, 1vw, 18px);
  --text-label:     clamp(10px, 0.75vw, 13px);
  --text-caption:   14px;
  --text-mono-xl:   clamp(40px, 4vw, 64px);    /* proof numbers */

  /* ── Spacing ── */
  --section-pad-x:  clamp(24px, 8vw, 120px);
  --section-pad-y:  clamp(60px, 8vh, 120px);

  /* ── Effects ── */
  --blur-glass:     12px;
  --glass-bg:       rgba(255, 255, 255, 0.03);
  --glass-border:   rgba(255, 255, 255, 0.06);
  --grain-opacity:  0.018;
  --radius-sm:      8px;
  --radius-md:      12px;
  --radius-lg:      20px;

  /* ── Motion ── */
  --ease-smooth:    cubic-bezier(0.22, 0.68, 0, 1);
  --ease-snappy:    cubic-bezier(0.4, 0, 0.2, 1);
  --duration-ui:    200ms;
  --duration-reveal: 600ms;
  --duration-hero:  1000ms;
}
```

---

## D.O.T.S. Color → Service Mapping

| Color | Code | D.O.T.S. Letter | Service | Subdomain |
|-------|------|-----------------|---------|-----------|
| Lavender | `#C8B6FF` | **D**ata | Private AI | private.dotsai.in |
| Mint | `#B8E0D2` | **O**perations | Platform | platform.dotsai.in |
| Peach | `#FFCDB2` | **T**ech | AI Web | web.dotsai.in |
| Sky Blue | `#A2D2FF` | **S**trategy | GEO AI | geo.dotsai.in |

### Color Usage Rules
```css
/* ✅ CORRECT — accent only */
.service-label { color: var(--dots-data); }
.service-card  { border-left: 2px solid var(--dots-data); }
.section-tint  { background: rgba(200, 182, 255, 0.04); }

/* ❌ WRONG — never full fill */
.card { background: var(--dots-data); }
```

---

## Typography Rules

### H1 (Hero Display)
```css
font-family: var(--font-display);
font-size: var(--text-display);
font-weight: 400;             /* Instrument Serif looks best at regular weight */
font-style: normal;           /* optional italic for editorial moments */
line-height: 1.05;
letter-spacing: -0.02em;
color: var(--text-light);     /* on dark hero */
```

### H2 (Section Headers)
```css
font-family: var(--font-display);
font-size: var(--text-h2);
font-weight: 400;
line-height: 1.15;
letter-spacing: -0.01em;
```

### H3 / Service Names
```css
font-family: var(--font-body);
font-size: var(--text-h3);
font-weight: 600;
line-height: 1.3;
```

### Body
```css
font-family: var(--font-body);
font-size: var(--text-body);
font-weight: 400;
line-height: 1.7;
```

### Labels (Space Mono)
```css
font-family: var(--font-mono);
font-size: var(--text-label);
font-weight: 400;
text-transform: uppercase;
letter-spacing: 0.1em;
color: var(--dots-data);      /* service-specific D.O.T.S. color */
```

### Proof Numbers
```css
font-family: var(--font-mono);
font-size: var(--text-mono-xl);
font-weight: 700;
letter-spacing: -0.02em;
color: var(--text-light);
```

---

## Animation Timing

### Fade-in (Hero Headline)
```js
{ from: { opacity: 0, y: 40 }, to: { opacity: 1, y: 0, duration: 0.8, ease: 'power2.out' } }
```

### Word Reveal (Manifesto)
```js
// Each word, staggered in GSAP timeline at 0.05 per word
{ from: { opacity: 0.08, filter: 'blur(4px)' }, to: { opacity: 1, filter: 'blur(0px)', duration: 0.1 } }
```

### Counter Animate (Proof Numbers)
```js
gsap.to(counterEl, {
  innerText: finalValue,
  duration: 1.5,
  snap: { innerText: 1 },
  ease: 'power2.out',
  scrollTrigger: { trigger: counterEl, start: 'top 80%' }
})
```

### Service Slide-in
```js
{ from: { opacity: 0, x: -60 }, to: { opacity: 1, x: 0, duration: 0.6, ease: 'power2.out' } }
```

### Glass Button Hover
```css
transition: all 200ms var(--ease-smooth);
/* hover: */
background: var(--gradient-warmth);
border-color: transparent;
box-shadow: 0 0 40px rgba(200, 182, 255, 0.3);
```

---

## Glass Morphism (Hero CTA Button)

```css
.glass-button {
  backdrop-filter: blur(var(--blur-glass));
  -webkit-backdrop-filter: blur(var(--blur-glass));
  background: var(--glass-bg);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-md);
  color: var(--text-light);
  padding: 14px 28px;
  font-family: var(--font-body);
  font-size: 15px;
  font-weight: 500;
  letter-spacing: 0.02em;
  cursor: pointer;
  transition: all var(--duration-ui) var(--ease-smooth);
}

.glass-button:hover {
  background: var(--gradient-warmth);
  border-color: transparent;
  box-shadow: 0 0 40px rgba(200, 182, 255, 0.2);
}
```

---

## Film Grain Overlay

```css
/* Fixed overlay, pointer-events: none */
.grain-overlay::before {
  content: '';
  position: fixed;
  inset: 0;
  opacity: var(--grain-opacity);
  pointer-events: none;
  z-index: 9999;
  background-image: url("data:image/svg+xml,..."); /* SVG turbulence */
}
```

---

## Layout Grid

### Hero Section
```css
.section-hero {
  height: 100vh;
  display: grid;
  place-items: center;
  position: relative;
  background: var(--bg-dark);
  overflow: hidden;
}

/* Galaxy canvas: absolute, fills section */
.galaxy-canvas { position: absolute; inset: 0; }

/* Content: centered, above canvas */
.hero-content {
  position: relative;
  z-index: 10;
  text-align: center;
  max-width: 900px;
  padding: 0 var(--section-pad-x);
}
```

### Services Section (70/30 Split)
```css
.service-item {
  display: grid;
  grid-template-columns: 7fr 3fr;
  gap: 60px;
  align-items: center;
  padding: 0 var(--section-pad-x);
  height: 100vh;
}
```

### Subdomain Gateway
```css
/* Option A: Full-width stacked */
.subdomain-list { display: flex; flex-direction: column; gap: 2px; }
.subdomain-item {
  padding: 40px var(--section-pad-x);
  border-bottom: 1px solid rgba(25, 25, 36, 0.08);
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background 200ms;
}
.subdomain-item:hover {
  background: rgba(200, 182, 255, 0.05); /* service-specific color */
}
```

---

## Responsive Breakpoints

```css
/* Mobile-first */
@media (max-width: 480px) {
  /* Disable pin, use simple fades */
  /* Reduce galaxy particles to 15,000 */
  /* Stack service layout vertically */
}

@media (max-width: 768px) {
  /* Tablet — intermediate sizes */
  /* Galaxy particles: 30,000 */
}

@media (min-width: 1280px) {
  /* Large desktop — max sizes */
  /* Galaxy particles: 100,000 */
}
```
