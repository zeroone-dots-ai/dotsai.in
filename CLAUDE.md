# dotsai.in — CLAUDE.md

> **Project:** ZeroOne D.O.T.S AI — Premium solopreneur AI agency website
> **Owner:** Meet Deshani · ZeroOne D.O.T.S AI
> **Live:** https://dotsai.in (production) · https://test.dotsai.in (testing)
> **Repo:** https://github.com/zeroone-dots-ai/dotsai.in
> **Last updated:** 2026-04-02

---

## Quick Start

```bash
git clone https://github.com/zeroone-dots-ai/dotsai.in.git
cd dotsai.in

# Work on master (testing branch)
git checkout master

# The live site is static HTML in public/
# Edit public/index.html and public/main.css
open public/index.html

# Commit and push to master
git add public/
git commit -m "feat: what you changed"
git push origin master

# Test on test.dotsai.in → when verified, PR master → main for production
```

---

## Branching Strategy

| Branch | Environment | Domain | Purpose |
|--------|------------|--------|---------|
| `master` | Testing | test.dotsai.in | All development lands here first |
| `main` | Production | dotsai.in | Only tested, verified code gets merged here |

**Flow:**
```
master (edit + test on test.dotsai.in) → PR → main (production on dotsai.in)
```

**Rules:**
- Default target is always `master` unless explicitly told to edit production
- After testing on test.dotsai.in, create PR from `master` → `main`
- Never commit directly to `main`

---

## File Structure

```
dotsai.in/
├── public/                    ← DEPLOYED FILES (what goes live)
│   ├── index.html             ← THE SITE — main page
│   ├── main.css               ← All styles
│   ├── site.css               ← Additional styles
│   ├── favicon.svg            ← Site icon
│   ├── og-image.png           ← Social share image
│   ├── robots.txt             ← SEO: allows all AI crawlers
│   ├── sitemap.xml            ← SEO sitemap
│   ├── llms.txt               ← LLM-friendly description
│   ├── 404.html               ← Custom 404 page
│   ├── brand/                 ← SVG logos (zeroone-dark-*.svg)
│   ├── labs/                  ← Interactive demos
│   ├── meet/                  ← Meet's personal page
│   ├── ai-agency-india/       ← SEO landing page
│   ├── ai-agency-gurugram/    ← SEO landing page
│   ├── ai-automation/         ← SEO landing page
│   ├── geo-ai/                ← SEO landing page
│   ├── platform-engineering/  ← SEO landing page
│   ├── private-ai/            ← SEO landing page
│   ├── web-ai-experiences/    ← SEO landing page
│   ├── case-studies/          ← Case studies page
│   ├── insights/              ← Blog/insights page
│   └── monitor-data/          ← Site monitoring data
│
├── research/                  ← SEO strategy & site research docs
├── deploy/nginx/              ← Nginx config reference
├── .claude/                   ← Claude Code config
├── CLAUDE.md                  ← This file
└── .gitignore
```

---

## Sections (index.html)

| Section ID | Nav Filter | Content |
|-----------|-----------|---------|
| `hero` | All filters | 3-panel pinned scroll: Private AI, GEO, Web Presence |
| `meet` | Meet | Manifesto + credentials (5+, 2+, 1, 0) + tagline |
| `platform` | Product | Platform redirect — "Give Your Team Their Own Agents" |
| `consulting` | Services | Consulting redirect — 4 service items |
| `proof` | Work | Case studies + animated metrics |
| `labs-teaser` | Work | Interactive demos grid |
| `contact` | All filters | WhatsApp + Cal.com CTAs |

### Nav Filter Mapping
- **All** → all sections visible
- **Meet** → hero, meet, contact
- **Services** → hero, consulting, contact
- **Product** → hero, platform, contact
- **Work** → hero, proof, labs-teaser, contact

### Nav Behavior
- Hidden on hero section (slides up, opacity 0)
- Appears when scrolling past hero
- Centered filter pills (All/Meet/Services/Product/Work) + Let's Talk CTA
- Light/dark variant auto-switches per section background

---

## Interactive Systems (all in index.html)

| System | What it does |
|--------|-------------|
| Galaxy | 4000 stars, 3 depth layers, nebulae, click explosions |
| D.O.T.S Planet | 4 brand dots orbiting, physics shield on hover |
| Infinity orbit | Lemniscate particle mesh, top-right of hero |
| Quantum Cursor | Spring-physics cursor, D.O.T.S color cycling |
| Splash | 6 GSAP logo variants, random on load |
| Scroll animations | GSAP ScrollTrigger on all sections (pinned compartments) |
| Manifesto | Word-by-word scroll reveal |

---

## Brand System

### Colors
```css
--hero-bg:     #06060a;   /* deep black */
--paper:       #F7F3ED;   /* warm cream */
--plum:        #43305F;   /* primary accent */
--lavender:    #D7CFF0;   /* light accent */
--dots-data:       #D7CFF0;  /* lavender */
--dots-operations: #C9DED4;  /* mint */
--dots-tech:       #F1C6AE;  /* peach */
--dots-strategy:   #BFD6EC;  /* sky */
```

### Typography
- **Headlines:** Instrument Serif
- **Body:** DM Sans
- **Labels/code:** Space Mono

---

## VPS & Deployment

| Item | Value |
|------|-------|
| IP | 72.62.229.16 (Hostinger VPS) |
| Server | Nginx in Docker |
| Production root | `/opt/services/nginx/html/dotsai.in/` |
| Test root | `/opt/services/nginx/html/test.dotsai.in/` |
| Nginx configs | `/opt/services/nginx/conf.d/default.conf` (prod), `test.dotsai.in.conf` (test) |
| SSL | Let's Encrypt (separate certs for each domain) |

### Deploy to test (manual)
```bash
scp public/* root@72.62.229.16:/opt/services/nginx/html/test.dotsai.in/
ssh root@72.62.229.16 "docker exec nginx nginx -s reload"
```

### Deploy to production (after testing)
```bash
scp public/* root@72.62.229.16:/opt/services/nginx/html/dotsai.in/
ssh root@72.62.229.16 "docker exec nginx nginx -s reload"
```

### Or edit VPS directly for quick test iterations
```bash
ssh root@72.62.229.16
vi /opt/services/nginx/html/test.dotsai.in/index.html
```

---

## Contact Links
- **WhatsApp:** `https://wa.me/918320065658`
- **Cal.com:** `https://cal.com/meetdeshani`

---

## DO NOT

- Commit directly to `main` — always PR from master
- Use Vercel — this is VPS-hosted, never Vercel
- Add bento grids, neon, cyberpunk, glassmorphism
- Add contact forms — WhatsApp/Cal only
- Change galaxy to Three.js — it's Canvas 2D
- Push `.env` or credentials to git
- Redesign content when asked to add animations
- Build locally — edit VPS test site directly for quick iterations
