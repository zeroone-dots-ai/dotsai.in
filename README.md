# dotsai.in — ZeroOne D.O.T.S AI

> **Private AI Built for You** — [dotsai.in](https://dotsai.in)

Single-page premium landing site for Meet Deshani · ZeroOne D.O.T.S AI

## Stack
- Static HTML + GSAP + Canvas 2D (live site in `public/`)
- Next.js 15 + React 19 + Tailwind (future build in `app/`)
- Nginx on VPS @ 72.62.229.16

## Auto-Deploy
**Push to `main` → GitHub Actions → VPS in ~30 seconds**

Workflow: `.github/workflows/deploy.yml`
- Copies `public/index.html`, `robots.txt`, `sitemap.xml`, `llms.txt` to VPS
- Reloads Nginx

## Local Edit → Deploy
```bash
# Edit the site
code public/index.html

# Commit & push → auto-deploys
git add public/index.html
git commit -m "feat: your change"
git push origin main
```

## Branch Strategy
| Branch | Purpose |
|--------|---------|
| `main` | Production — auto-deploys to dotsai.in |
| `dev` | Staging / WIP |
| `feat/*` | Feature branches |

## Secrets (in GitHub → Settings → Secrets)
- `VPS_HOST` — 72.62.229.16
- `VPS_USER` — root
- `VPS_SSH_KEY` — ed25519 deploy key
