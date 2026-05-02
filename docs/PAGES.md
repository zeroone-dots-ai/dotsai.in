# dotsai.in — Page Registry

Single source of truth for every page: file path, URL, nav pill links, section anchors.

> **To add a new page:** create the HTML file, add it here, run `python3 scripts/fix_contextual_nav.py` to apply contextual nav.

---

## Homepage

| Path | URL | Nav pill |
|------|-----|----------|
| `public/index.html` | `https://dotsai.in/` | Services · Case Studies · How I Work · Pricing *(scroll links)* |

**Sections (scroll anchors):**
`#pillars` · `#cases` · `#work` · `#reviews` · `#workstyle` · `#regions` · `#pricing` · `#lfs` · `#founder` · `#faq` · `#cta`

---

## Services

| Path | URL | Nav pill |
|------|-----|----------|
| `public/private-ai/index.html` | `/private-ai/` | ← Services · Case Studies · Pricing · About |
| `public/ai-automation/index.html` | `/ai-automation/` | ← Services · Case Studies · Pricing · About |
| `public/geo-ai/index.html` | `/geo-ai/` | ← Services · Case Studies · Pricing · About |
| `public/web-ai-experiences/index.html` | `/web-ai-experiences/` | ← Services · Case Studies · Pricing · About |
| `public/platform-engineering/index.html` | `/platform-engineering/` | ← Services · Case Studies · Pricing · About |

---

## Case Studies

| Path | URL | Nav pill |
|------|-----|----------|
| `public/case-studies/index.html` | `/case-studies/` | ← Home · NeoNir · WORO · Aamdhanee |
| `public/case-studies/neonir/index.html` | `/case-studies/neonir/` | ← Case Studies · WORO · Aamdhanee · Pricing |
| `public/case-studies/woro/index.html` | `/case-studies/woro/` | ← Case Studies · NeoNir · Aamdhanee · Pricing |
| `public/case-studies/aamdhanee/index.html` | `/case-studies/aamdhanee/` | ← Case Studies · NeoNir · WORO · Pricing |

---

## Region Landing Pages

| Path | URL | Nav pill |
|------|-----|----------|
| `public/ai-agency-india/index.html` | `/ai-agency-india/` | ← Home · Private AI · Case Studies · Pricing |
| `public/ai-agency-gurugram/index.html` | `/ai-agency-gurugram/` | ← Home · Private AI · Case Studies · Pricing |
| `public/regions/index.html` | `/regions/` | ← Home · India · Gurugram · Pricing |

---

## About

| Path | URL | Nav pill |
|------|-----|----------|
| `public/about/index.html` | `/about/` | ← Home · Meet Deshani · Case Studies · Pricing |
| `public/about/meetdeshani/index.html` | `/about/meetdeshani/` | ← About · Case Studies · Pricing · Services |

---

## Pricing

| Path | URL | Nav pill |
|------|-----|----------|
| `public/pricing/index.html` | `/pricing/` | ← Home · Services · Case Studies · About |

---

## Content

| Path | URL | Nav pill |
|------|-----|----------|
| `public/insights/index.html` | `/insights/` | ← Home · Services · Case Studies · Pricing |

---

## Labs

| Path | URL | Nav pill |
|------|-----|----------|
| `public/labs/index.html` | `/labs/` | AI Chat · Doc Parser · SEO Checker · Workflow Viz |
| `public/labs/ai-chat/index.html` | `/labs/ai-chat/` | ← Labs · Doc Parser · SEO Checker · Services |
| `public/labs/doc-parser/index.html` | `/labs/doc-parser/` | ← Labs · AI Chat · SEO Checker · Services |
| `public/labs/seo-checker/index.html` | `/labs/seo-checker/` | ← Labs · AI Chat · Doc Parser · Services |
| `public/labs/workflow-viz/index.html` | `/labs/workflow-viz/` | ← Labs · AI Chat · SEO Checker · Services |

---

## Company

| Path | URL | Nav pill |
|------|-----|----------|
| `public/careers/index.html` | `/careers/` | ← About · Team · Case Studies · Pricing |
| `public/team/index.html` | `/team/` | ← About · Careers · Case Studies · Pricing |
| `public/sitemap/index.html` | `/sitemap/` | ← Home · Services · Case Studies · Pricing |

---

## System

| Path | URL | Nav pill |
|------|-----|----------|
| `public/404.html` | *(any 404)* | ← Home · Case Studies · Pricing · About |

---

## Shared Assets

| Asset | Path | Notes |
|-------|------|-------|
| Global CSS | `public/site.css` | Nav + footer CSS shared here. Bump `?v=YYYYMMDD` on every change. |
| i18n JS | `public/assets/js/i18n.js` | EN/HI/GU switcher. Injected on all pages via `<script defer>`. |
| i18n strings | `public/assets/i18n/en.json` | English strings |
| i18n strings | `public/assets/i18n/hi.json` | Hindi strings (full native) |
| i18n strings | `public/assets/i18n/gu.json` | Gujarati strings (full native) |
| OG image | `public/og-image.png` | Used in all `og:image` meta tags |
| Favicon | `public/favicon.svg` | All pages |

---

## Scripts

| Script | What it does |
|--------|-------------|
| `scripts/deploy.sh` | Safe deploy: `git add public/ → commit → push`. Always use this instead of bare `git push`. |
| `scripts/fix_nav_footer.py` | Replace old topbar + minimal footer on any OLD-style page |
| `scripts/fix_contextual_nav.py` | Set page-specific nav pill links on all pages |

---

## Adding a new page — checklist

```bash
# 1. Create the HTML file
touch public/new-page/index.html

# 2. Add entry to this file (PAGES.md) with path, URL, nav pill

# 3. Add nav pill config to scripts/fix_contextual_nav.py PAGES dict

# 4. Add to sitemap
#    → public/sitemap.xml (add <url> entry)

# 5. Add to deep-dives footer nav if it's a primary page
#    → Edit footer in index.html + update RICH_FOOTER in scripts/fix_nav_footer.py

# 6. Deploy
bash scripts/deploy.sh "feat: add /new-page/"
```
