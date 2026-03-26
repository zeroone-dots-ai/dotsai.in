# dotsai.in — CLAUDE.md

> **Project:** Premium single-page solopreneur AI agency website
> **Owner:** Meet Deshani — ZeroOne D.O.T.S AI
> **Status:** Revamp in progress (previously served zeroonedotsai.consulting content)
> **Last updated:** 2026-03-26

---

## Who This Site Is For

**Meet Deshani** — solopreneur AI expert. Not a big agency, not a SaaS product. One person who is deeply expert at building private AI systems for enterprises and solopreneurs.

**Tagline direction:** "I build private AI that your business owns."
**Positioning:** The goto expert when a business wants AI that lives on their infrastructure, works offline, and never sends data to OpenAI.

---

## Brand System

### Identity
- **Company:** ZeroOne D.O.T.S AI
- **Domain:** dotsai.in (India-facing) / zeroonedotsai.consulting (global)
- **Pillars:** D = Data · O = Operations · T = Tech · S = Strategy

### Colors
```css
/* Base */
--bg:           #FDFCFA;   /* cream white — main body */
--text:         #191924;   /* near black */
--text-muted:   #5e586e;

/* Hero section (dark contrast) */
--hero-bg:      #06060a;   /* deep black for 3D galaxy hero */

/* Paper / Ink / Plum — Primary (80% of site) */
--paper:       #F7F3ED;   /* primary light bg — warmer than flat white */
--bone:        #ECE5DB;   /* secondary light bg */
--ink:         #171722;   /* text + dark sections */
--smoke:       #6E675F;   /* muted text */

/* Brand Accents (15%) */
--plum:        #43305F;   /* primary accent */
--lavender:    #D7CFF0;   /* light accent */
--gold:        #B28743;   /* premium signal */

/* D.O.T.S. Utility Accents (5% — signal use only) */
--dots-data:       #D7CFF0;  /* soft lavender — Data / Private AI */
--dots-operations: #C9DED4;  /* dust mint — Operations / Platform */
--dots-tech:       #F1C6AE;  /* warm peach — Tech / AI Web */
--dots-strategy:   #BFD6EC;  /* fog blue — Strategy / GEO AI */

/* Hero Gradients */
--hero-dark-start: #171722;
--hero-dark-mid:   #241D33;  /* plum-dark */
--gradient-hero:   linear-gradient(180deg, #171722 0%, #241D33 100%);
--gradient-shimmer: linear-gradient(135deg, #B28743 0%, #D8C39C 45%, #8F6A35 100%);
--hero-glow:       radial-gradient(circle at 50% 35%, rgba(215, 207, 240, 0.55), rgba(247, 243, 237, 0) 55%);
```

### Typography
- **Display (H1/H2):** Instrument Serif — large, editorial, elegant
- **Body:** DM Sans — clean, readable, modern
- **Mono/Labels:** Space Mono — technical accents, timestamps, code
- **Scale:** Hero H1 at 100-140px (desktop), 48-64px (mobile)

### Visual Language
**Direction: "Paper / Ink / Plum"** — editorial technology atelier (see `research/04-design-direction.md`)
- **Light body:** warm paper (`#F7F3ED`) NOT cold white — more premium
- **Dark hero:** plum-dark gradient (`#171722 → #241D33`) with lavender glow bloom
- **3D White Milky Way** — Three.js spiral galaxy, white/silver particles
- Cinematic film grain overlay (SVG turbulence, opacity ~0.018)
- Compartment scroll — GSAP ScrollTrigger pin+scrub per section
- No bento, no neon, no cyberpunk — "editorial technology atelier"
- Gold (`#B28743`) used very sparingly as premium signal in proof section
- Deep Plum (`#43305F`) as primary accent (not the pastel D.O.T.S. colors)

### ⚠️ SEO Note: Subdomains vs Subfolders
**User requested:** service subdomains (geo.dotsai.in, private.dotsai.in, etc.)
**SEO research recommends:** subfolders (/services/private-ai, etc.) for authority concentration
**Decision:** Use subdomains as requested — they are better for branding and clean service separation. Compensate SEO via strong internal links from main page + individual subdomain SEO work.

---

## Site Architecture

### This Page (dotsai.in)
Single-page gateway. Premium first impression. Links out to service subdomains.

### Subdomain Map
| Subdomain | Service | Description |
|-----------|---------|-------------|
| `geo.dotsai.in` | GEO AI & Local SEO | AI-optimized local visibility, GEO targeting |
| `private.dotsai.in` | Private AI Deployment | On-premise LLM, data sovereignty, enterprise |
| `platform.dotsai.in` | Infinity Platform | SaaS → redirects to platform.dotsai.cloud |
| `web.dotsai.in` | AI Web Presence | Full-stack web products built with AI |
| *(TBD from research)* | | |

---

## Page Sections (Compartment Scroll)

```
┌─────────────────────────────────────────────┐
│  SECTION 1: HERO (dark)                     │
│  Three.js white milky way galaxy (3D)       │
│  Headline: "Own Your AI. Don't Rent It."    │
│  Sub: Position as solopreneur expert        │
│  Camera zooms/rotates as user scrolls       │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  SECTION 2: MANIFESTO (light cream)         │
│  Large type reveals word-by-word            │
│  "I am one person. I build AI that..."      │
│  Instrument Serif at max scale              │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  SECTION 3: SERVICES                        │
│  Each service slides in on scroll           │
│  Full-width, editorial, no cards            │
│  Links to service subdomains                │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  SECTION 4: PROOF / OUTCOMES                │
│  Case study reveals (Logistics, etc.)       │
│  Numbers animate in on scroll               │
│  "70% cost reduction · 8L/year saved"       │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  SECTION 5: SUBDOMAIN GATEWAY               │
│  Each subdomain orbits in                   │
│  Click → navigate to service site           │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  SECTION 6: CONTACT CTA (free scroll)       │
│  Direct: "Let's talk" → WhatsApp/Cal        │
│  No form — solopreneur direct contact       │
└─────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Next.js 15 | App router, TypeScript |
| UI | React 19 | Latest concurrent features |
| Styling | Tailwind CSS 4 | Utility-first |
| Scroll | **GSAP + ScrollTrigger** | Pinned compartment scroll |
| 3D | **Three.js** | White milky way hero scene |
| Animations | Framer Motion | Secondary micro-animations |
| Deployment | Docker → VPS | 72.62.229.16 (Hostinger) |
| Reverse Proxy | Nginx + SSL | Let's Encrypt |

---

## Reference Codebases

### web.dotsai.cloud — `/Users/meetdeshani/Desktop/Web-App/web.dotsai.cloud`
Assets to inherit/reuse:
- `src/app/globals.css` — CSS custom properties (D.O.T.S. color system)
- `src/lib/motion.ts` — Framer Motion animation presets
- `src/components/GalaxyBackground.tsx` — Canvas particle logic (adapt to Three.js milky way)
- `public/brand/` — Logo SVGs (zeroone-dark-icon.svg, zeroone-dark-horizontal.svg, etc.)

### Current Live Site (zeroonedotsai.consulting = dotsai.in)
- Sections: Hero, Our Promise, Private AI Platform, How Private AI Grows Your Business, Use Cases, Case Studies
- Content to migrate/adapt into new compartment-scroll format
- Copy reference: "Own Your AI. Don't Rent It." — keep this as hero headline

---

## Planning Files

All research and specs live in `.planning/`:

| File | Purpose |
|------|---------|
| `.planning/RESEARCH.md` | NotebookLM research findings |
| `.planning/ARCHITECTURE.md` | Detailed component tree + subdomain map |
| `.planning/DESIGN-SYSTEM.md` | Full design tokens + animation spec |
| `.planning/COPY.md` | Final copy for all sections |
| `.planning/SCROLL-SPEC.md` | Per-section GSAP ScrollTrigger config |

---

## Deployment

- **Domain:** dotsai.in (DNS → VPS 72.62.229.16)
- **Port:** 3025 (separate from web.dotsai.cloud on 3020)
- **Container:** `dotsai-in` Docker container
- **Nginx config:** `/etc/nginx/sites-available/dotsai.in`
- **SSL:** Let's Encrypt via Certbot

---

## DO NOT

- Do NOT use bento box / card grid layouts
- Do NOT use dark space galaxy (web.dotsai.cloud style) — use WHITE milky way
- Do NOT build multi-page — single page only, services on subdomains
- Do NOT add a contact form — direct WhatsApp/Cal link only (solopreneur = direct)
- Do NOT copy the Infinity Platform SaaS messaging — this is the person, not the product
