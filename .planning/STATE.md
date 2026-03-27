# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Every visitor, click, and booking captured in Meet's own PostgreSQL — zero third-party analytics dependency, connected from anywhere.
**Current focus:** Phase 1 — VPS Pre-Flight + PostgreSQL Foundation

## Current Position

Phase: 1 of 5 (VPS Pre-Flight + PostgreSQL Foundation)
Plan: 0 of 2 in current phase
Status: Ready to plan
Last activity: 2026-03-27 — ROADMAP.md and STATE.md initialised

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-phase]: Cal.com self-hosted (MIT, Docker) over SaaS — eliminates third-party booking dependency
- [Pre-phase]: FastAPI analytics API on VPS over Cloudflare D1 — single DB queryable from anywhere
- [Pre-phase]: PostgreSQL over SQLite — concurrent writes from multiple sites, proper analytics queries
- [Pre-phase]: Gateway as section in index.html (not separate page) — single file, simpler deploy

### Pending Todos

None yet.

### Blockers/Concerns

- [Pre-phase]: VPS RAM headroom unconfirmed — must run `free -h` and `docker stats` before Cal.com deployment (Phase 3). If under 3GB available, configure 2GB swap in Phase 1.
- [Pre-phase]: DNS A records for cal.dotsai.in, api.dotsai.in, meet.dotsai.in must point to 72.62.229.16 before certbot runs in Phases 2, 3, 5.
- [Pre-phase]: Cal.com exact semver image tag unconfirmed — check hub.docker.com/r/calcom/cal.com/tags before Phase 3 begins.
- [Pre-phase]: asyncpg 0.29.0 pin is MEDIUM confidence — verify `create_async_engine` works on fresh setup in Phase 2 before committing to version.

## Session Continuity

Last session: 2026-03-27
Stopped at: Roadmap created — project initialised, ready to plan Phase 1
Resume file: None
