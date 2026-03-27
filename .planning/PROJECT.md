# dotsai.in — Gateway + Analytics Platform

## What This Is

dotsai.in is Meet Deshani's personal hub — a premium single-page gateway that routes visitors to three destinations (ZeroOne consulting, Infinity platform, Meet's personal page) and captures every visitor interaction into an in-house PostgreSQL database running 24/7 on the VPS. It also hosts a self-branded Cal.com calendar at cal.dotsai.in for direct meeting scheduling.

## Core Value

Every visitor, click, and booking is captured in Meet's own PostgreSQL database — zero third-party dependency for analytics, zero data leakage, connected from anywhere.

## Requirements

### Validated

- ✓ dotsai.in single-page static site with galaxy hero — existing
- ✓ D.O.T.S. brand system (Instrument Serif, DM Sans, brand palette) — existing
- ✓ Auto-deploy via GitHub Actions → VPS nginx — existing
- ✓ Telegram real-time visitor notifications (via dotsai.in scripts) — existing

### Active

- [ ] Gateway section: 3 destination cards (dotsai.cloud, zeroonedotsai.consulting, meet.dotsai.in)
- [ ] PostgreSQL database on VPS for all visitor/event analytics
- [ ] Analytics API service on VPS (FastAPI) — receives events from all sites
- [ ] Both sites (dotsai.in + zeroonedotsai.consulting) log to PostgreSQL
- [ ] Self-hosted Cal.com at cal.dotsai.in (MIT, Docker)
- [ ] meet.dotsai.in subdomain (static page — who is Meet)
- [ ] E2E test suite validating all services are live and logging

### Out of Scope

- Multi-user analytics dashboard — single operator (Meet only), raw DB access sufficient for v1
- Custom calendar UI from scratch — Cal.com provides this with branding
- Mobile apps — web only

## Context

**VPS:** 72.62.229.16 (Hostinger), nginx in Docker, Let's Encrypt SSL auto-renew
**Repo:** https://github.com/zeroone-dots-ai/dotsai.in
**Current site:** `public/index.html` — single HTML file, deployed via SCP on push to main
**zeroonedotsai.consulting:** Separate repo, Cloudflare Pages, already has Telegram + Pages Function

**Three gateway destinations:**
1. `dotsai.cloud` → Infinity Nexus SaaS platform
2. `zeroonedotsai.consulting` → Business consulting (margins, Private AI, productivity, efficiency)
3. `meet.dotsai.in` → Who is Meet Deshani

**Analytics requirements:**
- Every visitor: IP, location, device, browser, session, entry page, referrer
- Every page view on high-value pages
- Every CTA click, form open, form submit, booking
- Data persisted in PostgreSQL — queryable from anywhere

**Cal.com specifics:**
- MIT licensed, self-hostable via Docker
- Brand match: D.O.T.S. colors, Instrument Serif / DM Sans
- Accessible at cal.dotsai.in
- Bookings logged to PostgreSQL alongside all other events
- Replaces current Cal.com SaaS dependency

## Constraints

- **Infrastructure:** VPS 72.62.229.16 only — no new cloud vendors
- **License:** All new tools must be MIT or Apache 2.0 licensed
- **Design:** Must match D.O.T.S. brand system — no bento grids, no neon
- **Uptime:** All services must auto-restart (Docker `restart: always`)
- **Data sovereignty:** Zero visitor data to third parties for analytics

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Cal.com (self-hosted) vs custom calendar | MIT licensed, full scheduling logic, Google Cal sync, embed API | — Pending |
| FastAPI analytics API vs Cloudflare D1 | VPS-based = single DB, queryable from anywhere, no vendor | — Pending |
| PostgreSQL vs SQLite for analytics | PostgreSQL = concurrent writes from multiple sites, proper analytics queries | — Pending |
| Gateway as section in index.html vs separate page | Single file = simpler deploy, no routing needed | — Pending |

---
*Last updated: 2026-03-27 after initialization*
