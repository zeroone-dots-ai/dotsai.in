# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Every visitor, click, and booking captured in Meet's own PostgreSQL — zero third-party analytics dependency, connected from anywhere.
**Current focus:** Phase 4 — Cal.com Webhook Bridge (SLIM: SaaS webhooks to api.dotsai.in)

## Current Position

Phase: 4 of 5 — PLANNING (Cal.com Webhook Bridge)
Plan: 0 of 2 in Phase 4 — Plans created, not yet executed
Status: Phase 4 planned (SLIM variant — Cal.com SaaS webhooks to api.dotsai.in, no self-hosted Cal.com). Phase 3 SKIPPED — using Cal.com SaaS at cal.com/meetdeshani instead of self-hosting.
Last activity: 2026-03-28 — Phase 4 plans created (04-01: migration + endpoint, 04-02: webhook config + E2E)

Progress: [████████░░] 50% (Phases 1-2 complete, Phase 3 skipped, Phase 4 planned)

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 7min
- Total execution time: 0.80 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 17min | 6min |
| 02 | 4 | 31min | 8min |

**Recent Trend:**
- Last 5 plans: 01-03 (3min), 02-01 (20min), 02-02 (3min), 02-03 (3min), 02-04 (5min)
- Trend: Phase 2 complete -- 4 plans in 31min, analytics pipeline fully operational

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-phase]: Cal.com self-hosted (MIT, Docker) over SaaS — eliminates third-party booking dependency
- [Phase 4 OVERRIDE]: Using Cal.com SaaS (cal.com/meetdeshani) with webhooks to api.dotsai.in — skips Phase 3 self-hosting entirely. HMAC-SHA256 verification via X-Cal-Signature-256 header.
- [Pre-phase]: FastAPI analytics API on VPS over Cloudflare D1 — single DB queryable from anywhere
- [Pre-phase]: PostgreSQL over SQLite — concurrent writes from multiple sites, proper analytics queries
- [Pre-phase]: Gateway as section in index.html (not separate page) — single file, simpler deploy
- [01-01]: Kept existing user 'dotsai' instead of plan's 'dotsai_admin' — 10+ services depend on it
- [01-01]: Used existing password in Docker secrets instead of generating new one — avoids breaking dependent services
- [01-01]: Kept docker-compose.yml naming (not compose.yaml) — matches existing VPS convention
- [01-02]: Used docker exec pg_dump (database-scoped, not pg_dumpall) — dotsai DB only, simpler restore
- [01-02]: 7-day retention via find -mtime — bounded storage growth, matches ROADMAP requirement
- [01-03]: Added external: true to dotsai_pgdata volume declaration — volume pre-existed compose, external: true suppresses warning and correctly models independent volume lifecycle
- [01-03]: Preserved /opt/services/postgres-data/ bind-mount as 7-day rollback — safe to remove after 2026-04-03
- [02-01]: Used Optional[str] type hints for Python 3.9 local compat (Docker target is 3.12)
- [02-01]: Alembic version table in analytics schema (version_table_schema="analytics")
- [02-01]: Conditional engine creation — None when DATABASE_URL empty, avoids startup crash
- [02-02]: Extracted limiter to app/rate_limit.py — avoids circular import between main.py and events.py
- [02-02]: 30 bot UA signatures including modern headless browsers and social crawlers
- [02-02]: Bot filter scoped to POST /events only — monitoring bots can still health-check
- [02-03]: Used --config-dir /opt/services/nginx/certs for certbot — matches existing cert store, visible to nginx container
- [02-03]: Activated pre-built api.dotsai.in.conf.ssl-ready — avoided rewriting nginx conf from scratch
- [02-03]: Certbot webroot is /opt/services/certbot-webroot (host) mapped to /var/www/certbot (container)
- [02-04]: ANALYTICS_WRITE_TOKEN exposed in client JS -- write-only, can only POST events, safe for browser
- [02-04]: sessionStorage gate (_ds key) for session_start dedup -- natural session boundary on tab close
- [02-04]: fetch with keepalive over sendBeacon -- allows custom Authorization header
- [02-04]: zeroonedotsai.consulting has no CSP -- snippet can be added in separate PR to that repo

### Pending Todos

None yet.

### Blockers/Concerns

- ~~[Pre-phase]: VPS RAM headroom unconfirmed~~ RESOLVED in 01-01: 31GB total, 24GB available, 8GB swap
- ~~[Pre-phase]: DNS A record for api.dotsai.in~~ RESOLVED in 02-03: api.dotsai.in -> 72.62.229.16 confirmed, SSL cert issued
- ~~[Pre-phase]: DNS A records for cal.dotsai.in, meet.dotsai.in must point to 72.62.229.16 before certbot runs in Phases 3, 5.~~ PARTIALLY RESOLVED: Phase 3 skipped (using Cal.com SaaS). meet.dotsai.in DNS still needed for Phase 5.
- ~~[Pre-phase]: Cal.com exact semver image tag unconfirmed~~ NO LONGER NEEDED: Phase 3 skipped, using Cal.com SaaS.
- ~~[Pre-phase]: asyncpg 0.29.0 pin is MEDIUM confidence~~ RESOLVED in 02-01: pinned asyncpg>=0.30.0,<0.32.0 per research (0.31.0 confirmed working with SQLAlchemy 2.0.48)

## Session Continuity

Last session: 2026-03-28
Stopped at: Phase 4 plans created (04-01-PLAN.md, 04-02-PLAN.md). Ready to execute with /gsd:execute-phase 04-calcom-webhook.
Resume file: None
