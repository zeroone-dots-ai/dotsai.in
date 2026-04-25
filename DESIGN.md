---
# =============================================================
# dotsai.in — ZeroOne D.O.T.S. AI Design System
# Generated from production codebase (April 2026)
# =============================================================

meta:
  name: "ZeroOne D.O.T.S. AI"
  description: "Warm editorial meets precision engineering. Four-pillar pastel brand with dark hero sections, cream canvas pages, and deliberate typographic contrast."
  version: "2.0"
  url: "https://dotsai.in"

# ─── COLOR ────────────────────────────────────────────────────────────────────

colors:

  # Primary — D.O.T.S. Pillar Pastels (accent signals, never backgrounds)
  brand-lavender:         "#C8B6FF"   # Data pillar — primary accent
  brand-mint:             "#B8E0D2"   # Operations pillar
  brand-peach:            "#FFCDB2"   # Tech pillar
  brand-sky:              "#A2D2FF"   # Strategy pillar
  brand-rose:             "#FFB5C2"   # Accent highlight
  brand-lemon:            "#FFF3B0"   # Warm highlight

  # Lavender (Data) Tonal Ladder
  data-20:                "#EDE6FF"
  data-40:                "#D3C5FF"
  data-60:                "#C8B6FF"   # BASE
  data-80:                "#5B3FD4"
  data-95:                "#2D1B4E"

  # Mint (Operations) Tonal Ladder
  ops-20:                 "#E5F3EC"
  ops-40:                 "#CCE9DC"
  ops-60:                 "#B8E0D2"   # BASE
  ops-80:                 "#1F7A5C"
  ops-95:                 "#0F3D2E"

  # Peach (Tech) Tonal Ladder
  tech-20:                "#FFEFE3"
  tech-40:                "#FFDFC8"
  tech-60:                "#FFCDB2"   # BASE
  tech-80:                "#A8521A"
  tech-95:                "#5C2A0D"

  # Sky (Strategy) Tonal Ladder
  strat-20:               "#E5F1FF"
  strat-40:               "#C5E0FF"
  strat-60:               "#A2D2FF"   # BASE
  strat-80:               "#1E5B9C"
  strat-95:               "#0F2E4F"

  # Warm Neutral Canvas (light-mode surfaces)
  cream-50:               "#FDFCFA"
  cream-100:              "#F8F7F4"
  cream-150:              "#F2F0EC"
  sand-200:               "#E8E6E0"
  sand-300:               "#D4D1C9"
  stone-400:              "#B5B1A7"
  stone-500:              "#918D82"
  stone-600:              "#6E6B62"
  slate-700:              "#4A4842"
  slate-800:              "#2E2D29"

  # Ink Anchors
  ink:                    "#191924"   # Primary text / dark surface
  plum:                   "#43305F"   # CTA background, hover surface
  plum-deep:              "#241D33"   # Deepest plum
  charcoal:               "#2A2A3C"   # Footer / dark borders
  slate-warm:             "#3A3D4A"   # Cards on dark
  slate-cool:             "#27425D"   # Info panels

  # Named CSS custom properties
  paper:                  "#F7F3ED"   # Main page canvas
  paper-deep:             "#EFE7DC"   # Deeper warm parchment
  smoke:                  "#6E675F"   # Muted body text on light
  hero:                   "#06060A"   # Deepest hero bg
  line:                   "rgba(23,23,34,0.10)"    # Hairline borders
  panel:                  "rgba(255,255,255,0.72)"  # Frosted card surface

  # Sidebar shell (dark navigation)
  sidebar-bg:             "#13131D"
  sidebar-hover:          "#1E1E2E"
  sidebar-active:         "#252538"
  sidebar-border:         "#2A2A3C"
  sidebar-text:           "#A8A6B0"
  sidebar-text-active:    "#FDFCFA"

  # Semantic utility
  success:                "#10B981"
  danger:                 "#EF4444"
  amber:                  "#D4A574"
  gold:                   "#F5C542"
  teal:                   "#4ECDC4"
  teal-hover:             "#3DB8B0"

  # Gradients
  g-aurora:    "linear-gradient(135deg, #C8B6FF, #A2D2FF, #B8E0D2)"
  g-warmth:    "linear-gradient(135deg, #FFCDB2, #FFB5C2, #C8B6FF)"
  g-cosmos:    "linear-gradient(135deg, #191924, #2D1B4E)"
  g-hero:      "linear-gradient(180deg, rgba(23,23,34,0.98) 0%, rgba(36,29,51,0.98) 100%)"

# ─── TYPOGRAPHY ───────────────────────────────────────────────────────────────

typography:

  families:
    display:    "'Orbitron', 'Space Grotesk', system-ui, sans-serif"
    editorial:  "'Instrument Serif', serif"
    body:       "'Satoshi', 'DM Sans', system-ui, -apple-system, sans-serif"
    mono:       "'Space Mono', 'JetBrains Mono', ui-monospace, monospace"

  scale:
    xs:   "11px"
    sm:   "13px"
    base: "15px"
    md:   "17px"
    lg:   "20px"
    xl:   "28px"
    2xl:  "36px"
    3xl:  "52px"
    4xl:  "76px"

  fluid:
    xs:   "clamp(10px, 0.7vw + 8px, 11px)"
    sm:   "clamp(12px, 0.4vw + 11px, 13px)"
    base: "clamp(14px, 0.4vw + 13px, 16px)"
    md:   "clamp(15px, 0.6vw + 13px, 18px)"
    lg:   "clamp(17px, 0.8vw + 14px, 22px)"
    xl:   "clamp(22px, 2vw + 14px, 32px)"
    2xl:  "clamp(28px, 3vw + 14px, 44px)"
    3xl:  "clamp(34px, 4vw + 14px, 60px)"
    4xl:  "clamp(40px, 6vw + 14px, 84px)"

  roles:
    h1:
      family:         "display (Orbitron)"
      size:           "clamp(40px, 6.5vw, 76px)"
      weight:         700
      line-height:    1.02
      letter-spacing: "-0.015em"
      transform:      "uppercase"
    h2:
      family:         "display (Orbitron)"
      size:           "clamp(30px, 4.5vw, 58px)"
      weight:         600
      line-height:    1.08
      letter-spacing: "-0.005em"
      transform:      "uppercase"
    h3:
      family:         "display (Orbitron)"
      size:           "28px"
      weight:         600
      line-height:    1.2
      letter-spacing: "-0.02em"
      transform:      "uppercase"
    h4:
      family:         "body (DM Sans)"
      size:           "17px"
      weight:         600
      line-height:    1.4
    display-editorial:
      family:         "editorial (Instrument Serif)"
      size:           "clamp(52px, 8vw, 98px)"
      weight:         400
      line-height:    1.0
      letter-spacing: "-0.04em"
    metric-value:
      family:         "editorial (Instrument Serif)"
      size:           "clamp(30px, 4vw, 46px)"
      weight:         400
      line-height:    1.0
      letter-spacing: "-0.05em"
    body:
      family:         "body (DM Sans)"
      size:           "15px"
      weight:         400
      line-height:    1.65
    lead:
      family:         "body (DM Sans)"
      size:           "17px"
      weight:         400
      line-height:    1.8
    caption:
      family:         "body (DM Sans)"
      size:           "13px"
      weight:         400
      line-height:    1.55
    eyebrow:
      family:         "mono (Space Mono)"
      size:           "10px"
      weight:         400
      letter-spacing: "0.18em"
      transform:      "uppercase"
    label:
      family:         "mono (Space Mono)"
      size:           "11px"
      weight:         400
      letter-spacing: "3px"
      transform:      "uppercase"
    code:
      family:         "mono (Space Mono)"
      size:           "13px"
      weight:         400
      line-height:    1.7

# ─── SPACING ──────────────────────────────────────────────────────────────────

spacing:
  1:   "4px"
  2:   "8px"
  3:   "12px"
  4:   "16px"
  5:   "20px"
  6:   "24px"
  8:   "32px"
  10:  "40px"
  12:  "48px"
  16:  "64px"
  24:  "96px"

  fluid-xs:  "clamp(4px, 0.4vw + 3px, 6px)"
  fluid-sm:  "clamp(8px, 0.8vw + 5px, 12px)"
  fluid-md:  "clamp(12px, 1vw + 8px, 20px)"
  fluid-lg:  "clamp(16px, 2vw + 10px, 32px)"
  fluid-xl:  "clamp(24px, 3vw + 12px, 48px)"
  fluid-2xl: "clamp(32px, 4vw + 16px, 72px)"
  fluid-3xl: "clamp(40px, 6vw + 20px, 112px)"

  section-x: "clamp(16px, 5vw, 80px)"
  section-y: "clamp(48px, 7vw, 120px)"

# ─── BORDER RADIUS ────────────────────────────────────────────────────────────

radii:
  sm:   "6px"
  md:   "10px"
  lg:   "16px"
  xl:   "24px"
  full: "999px"

# ─── SHADOWS ──────────────────────────────────────────────────────────────────

shadows:
  sm:    "0 1px 2px rgba(25,25,36,0.04)"
  md:    "0 4px 12px rgba(25,25,36,0.06)"
  lg:    "0 10px 32px rgba(25,25,36,0.08)"
  xl:    "0 20px 50px rgba(25,25,36,0.10)"
  2xl:   "0 30px 80px rgba(25,25,36,0.14)"
  card:  "0 24px 60px rgba(28,20,39,0.12)"
  hero:  "0 30px 80px rgba(6,6,10,0.30)"
  focus: "0 0 0 4px rgba(200,182,255,0.20)"
  glass: "0 0 0 1px rgba(255,255,255,0.04), 0 8px 32px rgba(0,0,0,0.45), inset 0 0 16px rgba(0,0,0,0.25)"

# ─── MOTION ───────────────────────────────────────────────────────────────────

motion:
  easing:
    out:    "cubic-bezier(0.16, 1, 0.3, 1)"       # Snappy deceleration — default
    snap:   "cubic-bezier(0.34, 1.56, 0.64, 1)"   # Bouncy spring
    in-out: "cubic-bezier(0.40, 0, 0.20, 1)"      # Symmetric on-screen movement
    ui:     "cubic-bezier(0.23, 1, 0.32, 1)"      # Micro-interactions

  durations:
    fast: "150ms"
    med:  "250ms"
    slow: "400ms"

  transitions:
    button:  "transform 160ms cubic-bezier(0.23,1,0.32,1), background 160ms cubic-bezier(0.23,1,0.32,1)"
    card:    "border-color 200ms, background 200ms, transform 200ms"
    focus:   "box-shadow 220ms cubic-bezier(0.23,1,0.32,1)"
    nav:     "color 200ms ease-out, background 200ms ease-out"

  keyframes:
    story-spin:     "12s linear infinite"
    story-spin-rev: "8s linear infinite"
    platform-spin:  "24s linear infinite"
    platform-float: "6s ease-in-out infinite"
    platform-pulse: "5.2s ease-in-out infinite"
    scroll-pulse:   "2s ease-in-out infinite"

# ─── LAYOUT ───────────────────────────────────────────────────────────────────

layout:
  container-max: "1280px"
  page-shell:    "min(1120px, calc(100vw - 32px))"

  breakpoints:
    xs:  "360px"
    sm:  "480px"
    md:  "768px"
    lg:  "1024px"
    xl:  "1280px"
    2xl: "1536px"

  touch-targets:
    min:     "44px"
    comfort: "48px"
    large:   "56px"

# ─── COMPONENT TOKENS ─────────────────────────────────────────────────────────

components:

  button-primary:
    background:      "#43305F"
    color:           "#FFFFFF"
    padding:         "14px 20px"
    border-radius:   "999px"
    font-size:       "14px"
    font-weight:     600
    hover-transform: "translateY(-1px)"
    active-scale:    0.97

  button-cta:
    background:    "#C8B6FF"
    color:         "#191924"
    padding:       "16px 28px"
    border-radius: "999px"
    font-size:     "15px"
    font-weight:   600

  nav-topbar:
    height:      "72px"
    backdrop:    "blur(20px)"
    background:  "rgba(247,243,237,0.82)"
    border:      "1px solid rgba(23,23,34,0.06)"

  nav-filter-bar:
    background:    "rgba(12,12,18,0.72)"
    border:        "1px solid rgba(255,255,255,0.10)"
    border-radius: "4px"
    padding:       "4px"
    gap:           "6px"

  nav-filter-active:
    background:  "#C8B6FF"
    color:       "#171722"
    font-weight: 500

  card:
    padding:       "24px"
    border-radius: "24px"
    background:    "rgba(255,255,255,0.72)"
    border:        "1px solid rgba(23,23,34,0.10)"
    shadow:        "0 24px 60px rgba(28,20,39,0.12)"

  metric:
    padding:       "18px"
    border-radius: "18px"
    background:    "rgba(255,255,255,0.66)"
    border:        "1px solid rgba(23,23,34,0.08)"

  eyebrow-pill:
    background:    "rgba(255,255,255,0.06)"
    color:         "rgba(255,255,255,0.72)"
    padding:       "8px 12px"
    border-radius: "999px"

  quote-card:
    background:    "linear-gradient(180deg, rgba(67,48,95,0.96), rgba(36,29,51,0.98))"
    color:         "#F3F0FF"
    border-radius: "24px"

  grain-overlay:
    opacity:    0.018
    blend-mode: "overlay"
    tile:       "SVG fractal noise, 200px × 200px"

---

# ZeroOne D.O.T.S. AI — Design Language

## Philosophy

dotsai.in occupies a deliberate visual tension: **warm editorial on the light side, precision dark on the hero side**. Pages open on a cream parchment canvas (`#F7F3ED`) that feels like quality stationery — analogue, considered, human. Hero and feature sections flip to near-black (`#06060A → #2D1B4E` plum gradient), giving the brand depth and authority without the sterile harshness of pure black.

The four brand pastels map to the D.O.T.S. acronym — Data (Lavender), Operations (Mint), Tech (Peach), Strategy (Sky). These are **accent signals only**, never background fills. Against dark hero backgrounds they glow; against cream canvas they read as soft category markers. Using them as dominant background colours breaks the design.

---

## Typography Character

**Orbitron** carries every headline — geometric, uppercase-only, unmistakably synthetic. It never appears in sentence-case body copy and should not be used below ~20px where it loses legibility.

**Instrument Serif** appears for large display numbers (metric values, key statistics) and editorial hero moments where the brand signals craft and humanity. The tension between these two faces — machine vs. artisan — is intentional.

**DM Sans / Satoshi** handles all readable body content. Weight 400 at 15px / 1.65 line-height is the default comfortable reading rhythm. Never replace with a condensed or geometric sans — the softness of humanist letterforms is the counterweight to Orbitron's rigidity.

**Space Mono** marks eyebrows, category labels, and data tags. At 10–11px with 0.18em letter-spacing it becomes a texture element rather than a text element. Always uppercase.

---

## Light Mode: Cream Canvas

The page background is `#F7F3ED` (paper), not white. Cards sit on top as `rgba(255,255,255,0.72)` frosted panels — semi-transparent so they feel continuous with the parchment beneath. Shadows are warm-toned (plum-shifted, `rgba(28,20,39,0.12)`) not neutral grey.

Text is `#191924` (ink, near-black indigo) for headings and `#6E675F` (smoke) for body — never pure black. This keeps the page warm and unified.

---

## Dark Mode: Plum Hero

Hero sections live in `linear-gradient(180deg, rgba(23,23,34,0.98), rgba(36,29,51,0.98))` — deep navy-indigo at top shifting to plum at bottom. Radial pastel glow spots (lavender most commonly) at 0.08–0.14 opacity create atmospheric depth. The grain texture overlay (SVG fractal noise, 200×200px, opacity 0.018) prevents flat-fill appearance and gives surfaces a quality-print character.

On dark backgrounds, body text is `rgba(255,255,255,0.72)` — never full white. The slight translucency maintains the perception of depth.

---

## Navigation

The sticky topbar is frosted glass: `rgba(247,243,237,0.82)` + `backdrop-filter: blur(20px)` + 72px height. It dissolves into the page above. Section filter pills sit in a dark frosted bar; active state is the only place pure pastel colour appears in navigation.

---

## Buttons

**Plum pill** (`#43305F`, white text, `border-radius: 999px`) — primary conversion actions. Lifts `translateY(-1px)` on hover.

**Lavender pill** (`#C8B6FF`, ink `#191924` text) — hero CTAs where dark background makes plum invisible.

Both press with `transform: scale(0.97)` on `:active`. Ghost variants use near-invisible `rgba(23,23,34,0.04)` background so secondary actions don't compete visually.

---

## Motion Signature

Primary easing is `cubic-bezier(0.16, 1, 0.3, 1)` — strong ease-out that starts with authority and lands softly. Duration defaults: 150ms fast, 250ms standard, 400ms slow reveals. **Keyboard-triggered actions receive no animation.** The motion vocabulary is for pointer-driven interactions only.

---

## Texture

Every gradient surface — light or dark — carries a grain overlay: SVG fractal noise at opacity 0.018 (light) or 0.035 (dark) with `mix-blend-mode: overlay`. This breaks the "AI render" flatness and gives surfaces a quality-print character. If grain is visible as individual pixels, reduce opacity.

---

## Composition Patterns

- **Hero:** Asymmetric two-column `minmax(0, 1.25fr) minmax(280px, 0.75fr)`, collapses at 768px. Content aligns to grid bottom (`align-items: end`).
- **Metric strip:** Three equal columns for statistics. Single column on mobile.
- **Service row:** `120px 1fr` — fixed icon column creates rhythm across variable labels.
- **Mobile card stacks:** `scroll-snap-type: x mandatory` with `scroll-padding-inline: 1.5rem`.

---

## Do / Don't

**Do:**
- Use pastels as accent signals, not backgrounds
- Use Orbitron UPPERCASE for all display headings
- Keep cream `#F7F3ED` as the light page canvas — not white
- Apply grain texture to every gradient surface
- Use plum shades for interactive hover and pressed states

**Don't:**
- Set pure white `#FFFFFF` as a page background
- Set pure black `#000000` as text — use ink `#191924`
- Animate keyboard-triggered actions
- Use Orbitron below 20px — switch to DM Sans
- Use pastel colours as dominant background fills
- Write `transition: all` — always specify exact properties
