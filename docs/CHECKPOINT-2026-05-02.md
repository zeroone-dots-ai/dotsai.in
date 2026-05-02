# Checkpoint — 2026-05-02 · Nav + Footer + Reviews

## Git references (restore from any of these)

| Type | Ref | How to restore |
|------|-----|----------------|
| **Tag** | `v2026.05.02-nav-footer-reviews` | `git checkout v2026.05.02-nav-footer-reviews` |
| **Branch** | `checkpoint/nav-footer-reviews-2026-05-02` | `git checkout checkpoint/nav-footer-reviews-2026-05-02` |
| **Commit** | `ba197ed` | `git checkout ba197ed` |

## To restore this exact state

```bash
cd ~/Desktop/dotsai.in

# Restore to tag (read-only view)
git checkout v2026.05.02-nav-footer-reviews

# OR restore as a working branch
git checkout -b restore/2026-05-02 checkpoint/nav-footer-reviews-2026-05-02

# OR hard-reset main to this point (destructive — wipes any newer commits)
git checkout main
git reset --hard v2026.05.02-nav-footer-reviews
git push origin main --force-with-lease
```

## What's in this checkpoint

### 1. Glass pill nav — all 17 subpages updated
Old `<header class="topbar">` replaced with the floating glass pill nav on every page that still had it:

- `about/`
- `ai-agency-india/`, `ai-agency-gurugram/`
- `ai-automation/`, `geo-ai/`, `platform-engineering/`, `private-ai/`, `web-ai-experiences/`
- `case-studies/` (index + neonir + woro + aamdhanee)
- `insights/`
- `labs/ai-chat/`, `labs/doc-parser/`, `labs/seo-checker/`, `labs/workflow-viz/`

Nav structure: `logo (left) · glass pill with 4 links (center) · Book Meet CTA (right)`
Active page gets `class="nav-link is-active"`. Scroll JS auto-detects light/dark sections.

### 2. Rich footer — all 17 subpages updated
Old `<footer class="footer">` (3-line minimal footer) replaced with full footer matching homepage:
- Workstyle chain strip
- Logo + tagline column
- 3 tier link columns (Launch-Critical / Growth / Scale)
- Social links (LinkedIn, Instagram, GitHub, YouTube, X)
- Deep dives navigation grid (4 columns)
- Copyright + contact bot strip

### 3. Testimonials section — added to `index.html`
New `<section class="reviews" id="reviews">` inserted between proof metrics and workstyle sections.
Three real client quotes:
- **Harshit** (WORO) — Voice AI / Ops Automation
- **Nishant** (NeoNir / Vasu Chemical Group) — Custom Platform / Private AI
- **Ankur** (Aamdhanee) — Private AI / Fintech

### 4. site.css — nav + footer CSS added, version bumped
- Nav CSS (`.nav`, `.nav-pill`, `.nav-link`, `.nav-cta`, `.nav-right-slot`, on-light variants)
- Footer CSS (`.foot-*` all variants, `.zo-logo` footer size)
- Version bumped: `?v=20260430` → `?v=20260502` across all 16 pages

### 5. scripts/fix_nav_footer.py — committed to repo
Python script that performs the nav/footer replacement. Safe to re-run — uses regex, idempotent.
Re-run anytime a new subpage is added:
```bash
python3 scripts/deploy.sh  # for deploy
python3 scripts/fix_nav_footer.py  # to apply nav/footer to a new OLD-style page
```

## Files changed in this checkpoint

```
public/site.css                       — nav + footer CSS added, version bump
public/index.html                     — reviews section + reviews CSS added
public/about/index.html               — new nav + footer
public/ai-agency-india/index.html     — new nav + footer
public/ai-agency-gurugram/index.html  — new nav + footer
public/ai-automation/index.html       — new nav + footer
public/case-studies/index.html        — new nav + footer
public/case-studies/neonir/index.html — new nav + footer
public/case-studies/woro/index.html   — new nav + footer
public/case-studies/aamdhanee/index.html — new nav + footer
public/geo-ai/index.html              — new nav + footer
public/insights/index.html            — new nav + footer
public/labs/ai-chat/index.html        — new nav + footer
public/labs/doc-parser/index.html     — new nav + footer
public/labs/seo-checker/index.html    — new nav + footer
public/labs/workflow-viz/index.html   — new nav + footer
public/platform-engineering/index.html — new nav + footer
public/private-ai/index.html          — new nav + footer
public/web-ai-experiences/index.html  — new nav + footer
scripts/fix_nav_footer.py             — replacement script
```

## Deploy protection mechanisms in place

1. **`scripts/deploy.sh`** — always `git add public/ → commit → push`. Never push uncommitted changes.
2. **`.git/hooks/pre-push`** — blocks push if any uncommitted files in `public/`. Prevents rsync wipe.
3. **`rsync --delete`** in CI mirrors committed `public/` exactly — nothing uncommitted survives deploy.

**Golden rule:** always use `bash scripts/deploy.sh "message"` to ship. Never `git push` directly after editing `public/` files.

## What's still on the homepage (not lost)

- `id="workstyle"` — 5 compounding steps section — PRESENT
- `id="regions"` — 6 region cards with compliance strip — PRESENT
- `id="reviews"` — testimonials — ADDED THIS SESSION
- `id="cases"` — 3 case study cards — PRESENT
- Rich footer with deep dives — PRESENT on homepage + all subpages now
