# dotsai.in — ZeroOne D.O.T.S AI

> **Private AI Built for You** — [dotsai.in](https://dotsai.in)

Single-page premium landing site for Meet Deshani · ZeroOne D.O.T.S AI

## Stack
- Static HTML + GSAP + Canvas 2D (live site in `public/`)
- Next.js 15 + React 19 + Tailwind (future build in `app/`)
- Nginx on VPS @ 72.62.229.16

## Auto-Deploy
**Feature branch → PR → merge to `main` → GitHub Actions → VPS**

Workflow: `.github/workflows/deploy.yml`
- Copies the full `public/` bundle to VPS
- Updates the production Nginx config from `deploy/nginx/default.conf`
- Validates Nginx before reload
- Runs the post-deploy release gate and publishes `/monitor-data/latest.json`

## Local Edit → Deploy
```bash
# Start a branch
git checkout -b feat/your-change

# Edit the site
code public/index.html

# Commit and push the branch
git add .
git commit -m "feat: your change"
git push origin feat/your-change

# Open PR, review, merge to main
```

## Branch Strategy
| Branch | Purpose |
|--------|---------|
| `main` | Production — auto-deploys to dotsai.in |
| `dev` | Staging / WIP |
| `feat/*` / `codex/*` | Feature branches for review before merge |

## Secrets (in GitHub → Settings → Secrets)
- `VPS_HOST` — 72.62.229.16
- `VPS_USER` — root
- `VPS_SSH_KEY` — ed25519 deploy key
