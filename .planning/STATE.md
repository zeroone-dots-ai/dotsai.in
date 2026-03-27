# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Every visitor, click, and booking captured in Meet's own PostgreSQL — zero third-party analytics dependency, connected from anywhere.
**Current focus:** Phase 2 — FastAPI Analytics API

## Current Position

Phase: 2 of 5 (FastAPI Analytics API)
Plan: 2 of 4 in current phase — COMPLETE (02-02 endpoints)
Status: Plan 02-02 complete — POST /events with auth, bot filter, rate limit, CORS, fingerprinting. Ready for Plan 02-03 (VPS deploy).
Last activity: 2026-03-27 — Plan 02-02 complete (POST /events endpoint + middleware)

Progress: [████░░░░░░] 33% (Phase 1 complete, Phase 2 plan 2/4 done)

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: 8min
- Total execution time: 0.67 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 17min | 6min |
| 02 | 2 | 23min | 12min |

**Recent Trend:**
- Last 5 plans: 01-01 (6min), 01-02 (8min), 01-03 (3min), 02-01 (20min), 02-02 (3min)
- Trend: 02-02 fast -- endpoints and middleware on existing scaffold

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-phase]: Cal.com self-hosted (MIT, Docker) over SaaS — eliminates third-party booking dependency
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

### Pending Todos

None yet.

### Blockers/Concerns

- ~~[Pre-phase]: VPS RAM headroom unconfirmed~~ RESOLVED in 01-01: 31GB total, 24GB available, 8GB swap
- [Pre-phase]: DNS A records for cal.dotsai.in, api.dotsai.in, meet.dotsai.in must point to 72.62.229.16 before certbot runs in Phases 2, 3, 5.
- [Pre-phase]: Cal.com exact semver image tag unconfirmed — check hub.docker.com/r/calcom/cal.com/tags before Phase 3 begins.
- ~~[Pre-phase]: asyncpg 0.29.0 pin is MEDIUM confidence~~ RESOLVED in 02-01: pinned asyncpg>=0.30.0,<0.32.0 per research (0.31.0 confirmed working with SQLAlchemy 2.0.48)

## Session Continuity

Last session: 2026-03-27
Stopped at: Completed 02-02-PLAN.md — POST /events endpoint complete, ready for 02-03 (VPS deploy)
Resume file: None
