# dotsai.in — CLAUDE.md

> **Project:** ZeroOne D.O.T.S AI — Premium solopreneur AI agency website
> **Owner:** Meet Deshani · ZeroOne D.O.T.S AI
> **Live:** https://dotsai.in
> **Repo:** https://github.com/zeroone-dots-ai/dotsai.in
> **Last updated:** 2026-03-26

---

## Quick Start (New Teammate)

```bash
# Clone
git clone https://github.com/zeroone-dots-ai/dotsai.in.git
cd dotsai.in

# NEVER work directly on main — create your branch
git checkout -b feat/your-feature-name

# The live site is ONE file: public/index.html
# Edit it, open in browser to preview locally
open public/index.html

# When done — commit and push YOUR branch
git add public/index.html
git commit -m "feat: what you changed"
git push origin feat/your-feature-name

# Open a PR on GitHub → Meet reviews → merges to main → auto-deploys in ~30s
```

---

## Git Workflow

### Branch Strategy
| Branch | Purpose | Who touches it |
|--------|---------|----------------|
| `main` | **Production** — auto-deploys to dotsai.in | Meet only (via PR merge) |
| `dev` | Staging / integration | Team |
| `feat/*` | New features | Anyone |
| `fix/*` | Bug fixes | Anyone |
| `content/*` | Copy/text changes | Anyone |

### Rules
- **Never commit directly to `main`** — always PR
- One PR = one logical change
- PR title format: `feat: galaxy improvements` / `fix: cursor on mobile` / `content: update hero copy`
- Meet approves and merges → deploy happens automatically

### Auto-Deploy Pipeline
```
Push/merge to main
      ↓
GitHub Actions fires (.github/workflows/deploy.yml)
      ↓
SCP → copies public/ files to VPS
      ↓
nginx reload
      ↓
dotsai.in live ✅  (~30 seconds total)
```

---

## What's Actually Built

### Live Site: `public/index.html`
Single static HTML file. **This is the source of truth for what's live.**

#### Sections (in order)
1. **Splash** — 6-variant random logo animation (GSAP). Auto-dismisses after 5s or SKIP button.
2. **Hero** — Dark galaxy scene. "Own Your AI. Don't Rent It."
3. **Manifesto** — Word-by-word scroll reveal. "I am one person. I build AI that lives on YOUR server."
4. **Services** — 4 service rows with GSAP entrance. Links to service subdomains.
5. **Proof** — 3 case study cards + animated metrics (70%, 8L/yr, 99%)
6. **Contact** — WhatsApp + Cal.com CTAs. No form — direct contact only.

#### Interactive Elements (all in `public/index.html`)
| System | File section | What it does |
|--------|-------------|-------------|
| **Splash animation** | `sRunV1`–`sRunV6` | 6 GSAP logo variants, random on each load |
| **Galaxy** | `HERO GALAXY v3` | 4000 stars, 3 depth layers, nebulae across 4 quadrants |
| **D.O.T.S Planet** | Inside galaxy script | 4 brand dots orbiting bottom-right, physics shield |
| **Infinity orbit** | `PARTICLE MESH` | Lemniscate particle orbit, top-right of hero |
| **Quantum Cursor** | `QUANTUM DOT CURSOR` | Spring-physics cursor, color cycles D.O.T.S palette |
| **Scroll animations** | `initMainPage()` | GSAP ScrollTrigger on all sections |

#### Physics behaviour
- **Hover over galaxy** → stars repel from cursor (120px radius)
- **Click galaxy** → stars explode outward + ripple rings
- **Hover near D.O.T.S planet** → shield glows up
- **Click near D.O.T.S planet** → shield ripple, dots bounce back (spring physics)
- **Cursor** → inner dot exact pos, outer ring lags (spring), nova burst on click

---

## File Structure

```
dotsai.in/
├── public/                    ← DEPLOYED FILES (what goes live)
│   ├── index.html             ← THE SITE — edit this
│   ├── robots.txt             ← SEO: allows all AI crawlers
│   ├── sitemap.xml            ← SEO: dotsai.in + 4 subdomains
│   ├── llms.txt               ← LLM-friendly plain text description
│   ├── brand/                 ← SVG logos (zeroone-dark-*.svg)
│   └── logo-splash-v5-random.html  ← standalone splash preview
│
├── app/                       ← Future Next.js build (not deployed yet)
│   ├── components/
│   │   ├── GalaxyBackground.tsx   ← Galaxy logic (React version)
│   │   ├── SplashIntro.tsx        ← Splash (React version)
│   │   ├── QuantumCursor.tsx      ← Cursor (React version)
│   │   └── InfinityCompanion.tsx  ← Infinity orbit (React version)
│   ├── page.tsx               ← Main page
│   └── globals.css            ← CSS vars + Tailwind
│
├── .github/
│   └── workflows/
│       └── deploy.yml         ← CI/CD: push to main → VPS deploy
│
├── .planning/                 ← Research docs (NotebookLM outputs)
├── research/                  ← Detailed strategy docs
├── scripts/                   ← release_audit.sh, release_gate.sh
├── sql/                       ← Analytics schema (future)
├── qa/                        ← QA run logs
│
├── CLAUDE.md                  ← This file
└── README.md                  ← GitHub-facing docs
```

---

## Brand System

### Identity
- **Company:** ZeroOne D.O.T.S AI
- **Person:** Meet Deshani
- **Domain:** dotsai.in (India) · zeroonedotsai.consulting (global)
- **Pillars:** D = Data · O = Operations · T = Tech · S = Strategy

### Colors (use these everywhere)
```css
/* Dark Hero */
--hero-bg:     #06060a;   /* deep black */
--ink:         #171722;   /* dark sections */
--plum-dark:   #241D33;   /* hero gradient end */

/* Light Body */
--paper:       #F7F3ED;   /* warm cream — primary bg */
--bone:        #ECE5DB;   /* secondary bg */
--smoke:       #6E675F;   /* muted text */

/* Brand Accents */
--plum:        #43305F;   /* primary accent */
--lavender:    #D7CFF0;   /* light accent */
--gold:        #B28743;   /* premium signal — use sparingly */

/* D.O.T.S Palette (galaxy + cursor colors) */
--dots-data:       #D7CFF0;  /* lavender — Data */
--dots-operations: #C9DED4;  /* mint    — Operations */
--dots-tech:       #F1C6AE;  /* peach   — Tech */
--dots-strategy:   #BFD6EC;  /* sky     — Strategy */
```

### Typography
- **H1/H2:** Instrument Serif (Google Fonts) — editorial, elegant
- **Body:** DM Sans — clean, modern
- **Labels/mono:** Space Mono — technical accents, timestamps

### Visual Rules
- Dark hero (#06060a) → light cream body (#F7F3ED) — NOT the other way
- Galaxy stars use D.O.T.S palette colors only
- No bento grids · No neon · No cyberpunk · No glassmorphism
- Gold used ONLY in proof/metrics section
- All CTAs: direct contact (WhatsApp/Cal) — NO forms

---

## VPS & Server

| Item | Value |
|------|-------|
| IP | 72.62.229.16 (Hostinger VPS) |
| Server | Nginx in Docker |
| Site root | `/opt/services/nginx/html/dotsai.in/` |
| Nginx config | `/opt/services/nginx/conf.d/default.conf` |
| SSL | Let's Encrypt (auto-renews) |
| Deploy user | `root` |

### Manual deploy (if GitHub Actions fails)
```bash
# SSH to VPS and copy manually
scp public/index.html root@72.62.229.16:/opt/services/nginx/html/dotsai.in/index.html
ssh root@72.62.229.16 "docker exec nginx nginx -s reload"
```

### Check what's live
```bash
curl -sk https://dotsai.in | grep '<title>'
```

---

## GitHub Secrets (already configured)
| Secret | Value |
|--------|-------|
| `VPS_HOST` | 72.62.229.16 |
| `VPS_USER` | root |
| `VPS_SSH_KEY` | ed25519 deploy key (in GitHub → Settings → Secrets) |

Do NOT add these to any file — they live in GitHub Secrets only.

---

## Subdomain Map

| Subdomain | Status | Purpose |
|-----------|--------|---------|
| `geo.dotsai.in` | Planned | GEO AI & Local SEO |
| `private.dotsai.in` | Planned | Private AI Deployment |
| `platform.dotsai.in` | Planned | → redirects to platform.dotsai.cloud |
| `web.dotsai.in` | Planned | AI Web Presence |

Each subdomain = separate nginx config + separate deploy.

---

## Contact Links (use exact URLs)
- **WhatsApp:** `https://wa.me/918320065658`
- **Cal.com:** `https://cal.com/meetdeshani` ← verify this is live before using
- **Email:** aamdhanee.dev@gmail.com

---

## DO NOT

- ❌ Commit directly to `main` — always PR
- ❌ Bento box / card grid layouts
- ❌ Dark neon / cyberpunk / glassmorphism aesthetics
- ❌ Contact forms — direct WhatsApp/Cal only
- ❌ Multi-page routing — single page, subdomains for services
- ❌ Copy Infinity Platform SaaS messaging — this is Meet the person, not the product
- ❌ Change the galaxy to Three.js — it's Canvas 2D (faster, better click interaction)
- ❌ Push `.env` files or credentials to git
- ❌ Edit files directly on VPS — always go through git → auto-deploy

---

## Full Workflow — Step by Step

This is the **exact process** for every change, big or small:

```
1. BRANCH      git checkout -b feat/your-feature-name
                  (from main — always pull main first)

2. EDIT        Edit public/index.html locally
               Preview: open public/index.html in browser

3. COMMIT      git add public/index.html
               git commit -m "feat: what exactly you changed"
               (short, clear message — these are your revert points)

4. PUSH BRANCH git push origin feat/your-feature-name

5. OPEN PR     Go to github.com/zeroone-dots-ai/dotsai.in
               Click "Compare & Pull Request"
               Write what you changed and why

6. MEET MERGES Meet reviews → clicks "Merge pull request" on GitHub

7. AUTO DEPLOY GitHub Actions runs automatically (~30-40 seconds):
               → copies public/index.html to VPS
               → nginx reloads
               → dotsai.in is live with your changes ✅
```

### Which GitHub Account
- **Org:** `zeroone-dots-ai` (not personal account)
- **Repo:** `github.com/zeroone-dots-ai/dotsai.in`
- Ask Meet to add you as a collaborator on the repo
- Clone with: `git clone https://github.com/zeroone-dots-ai/dotsai.in.git`

### Check Deploy Succeeded
```bash
# Watch GitHub Actions in real-time:
# github.com/zeroone-dots-ai/dotsai.in/actions

# Or verify live site content:
curl -sk https://dotsai.in | grep '<title>'
```

---

## Reverting — How to Undo a Bad Deploy

Every commit on `main` is a rollback point. Here's how to revert:

### Option A — Revert one commit (safest, keeps full history)
```bash
git checkout main
git pull origin main

# Find the bad commit hash
git log --oneline -10

# Revert it (creates a new "undo" commit)
git revert <commit-hash>
git push origin main
# → GitHub Actions auto-deploys the reverted version ✅
```

### Option B — Roll back to a specific good version
```bash
git checkout main
git pull origin main

# See all commits (find the last good one)
git log --oneline

# Hard reset to that good commit (⚠️ rewrites history — only Meet should do this)
git reset --hard <good-commit-hash>
git push --force origin main
```

### Option C — Emergency manual rollback (if CI/CD is broken)
```bash
# SSH to VPS and restore previous backup
ssh root@72.62.229.16
cp /opt/services/nginx/html/dotsai.in/index.html.bak /opt/services/nginx/html/dotsai.in/index.html
docker exec nginx nginx -s reload
```

### Why branches + PRs protect you
- Every merge to `main` appears in `git log` with author, date, and message
- You can always see exactly WHAT changed and WHO changed it
- `git revert` undoes a single change without touching others
- Never lose work — even deleted branches are recoverable for 30 days on GitHub

---

## Editing Tips

### Editing the splash animation
Search for `sRunV1` through `sRunV6` in `public/index.html`.
Each is a self-contained GSAP timeline. Add a `sRunV7` and register it in the `sRunners` array.

### Editing the galaxy
Search for `HERO GALAXY v3` comment block. Key vars:
- `COUNT` — star count (4000 desktop, 1600 mobile)
- `GCX/GCY` — galaxy core position (currently left side: 18% x, 50% y)
- `DOTS.orbitCx/Cy` — D.O.T.S planet orbit center (76% x, 72% y)
- `nebulae[]` — glow cloud positions per quadrant

### Editing copy
All copy is in the HTML directly. Sections labelled with `<!-- ─── HERO ─── -->` comments.

### Adding a section
1. Add HTML between existing section divs
2. Add GSAP ScrollTrigger animation in `initMainPage()` function
3. Add CSS in the `<style>` block at top of file
