---
phase: 02-fastapi-analytics-api
plan: 03
subsystem: infra
tags: [docker, nginx, ssl, certbot, letsencrypt, vps, deploy]

# Dependency graph
requires:
  - phase: 01-vps-pre-flight-postgresql-foundation
    provides: PostgreSQL with dotsai DB, dotsai_internal Docker network
  - phase: 02-01
    provides: FastAPI scaffold, Dockerfile, Alembic migrations
  - phase: 02-02
    provides: POST /events endpoint, Bearer auth, bot filter, rate limiting, CORS
provides:
  - analytics container running on VPS with restart: always
  - https://api.dotsai.in/health returns 200 with valid SSL
  - POST /events returns 401 without Bearer token (403 for invalid token)
  - nginx proxy with Docker DNS resolver for analytics:8000
  - ANALYTICS_WRITE_TOKEN for browser snippet (Plan 02-04)
affects: [02-04, 03-cal-com]

# Tech tracking
tech-stack:
  added: [certbot, letsencrypt]
  patterns: [certbot-webroot-via-nginx, nginx-docker-resolver-pattern]

key-files:
  created:
    - /opt/services/nginx/conf.d/api.dotsai.in.conf (SSL + proxy)
    - /opt/services/.env.analytics (chmod 600, tokens)
  modified:
    - /opt/services/docker-compose.yml (analytics service added)

key-decisions:
  - "Used --config-dir /opt/services/nginx/certs for certbot to match existing cert store location"
  - "Activated pre-built api.dotsai.in.conf.ssl-ready instead of writing new nginx conf"
  - "Verified auth via custom User-Agent since curl UA is correctly caught by bot filter (204)"

patterns-established:
  - "Certbot webroot: host path /opt/services/certbot-webroot, container path /var/www/certbot"
  - "SSL certs stored at /opt/services/nginx/certs/live/{domain}/, mapped to /etc/letsencrypt inside nginx"
  - "New subdomain SSL: certbot --config-dir /opt/services/nginx/certs --webroot -w /opt/services/certbot-webroot"

# Metrics
duration: 3min
completed: 2026-03-27
---

# Phase 02 Plan 03: VPS Deploy Summary

**Analytics service deployed to VPS with Let's Encrypt SSL on api.dotsai.in, nginx reverse proxy via Docker DNS resolver, and Alembic auto-migration**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-27T17:50:12Z
- **Completed:** 2026-03-27T17:53:28Z
- **Tasks:** 2 (1 auto + 1 human-verify)
- **Files modified:** 3 (all on VPS)

## Accomplishments
- Let's Encrypt production SSL certificate issued for api.dotsai.in (TLSv1.3)
- Activated HTTPS nginx config with Docker DNS resolver (127.0.0.11) for upstream analytics:8000
- Verified end-to-end: health returns 200, unauthenticated POST returns 401, bot-filtered curl returns 204
- All 3 analytics schema tables confirmed: visitors, events, alembic_version
- Container running with restart: always policy

## Task Commits

No local code commits -- all work was VPS-side deployment (SSH commands). The analytics code was already committed in Plans 02-01 and 02-02.

**Plan metadata:** (see final commit below)

## Files Created/Modified (VPS)
- `/opt/services/nginx/conf.d/api.dotsai.in.conf` - SSL server block with proxy_pass to analytics:8000
- `/opt/services/.env.analytics` - DATABASE_URL, ANALYTICS_WRITE_TOKEN, FINGERPRINT_SALT (chmod 600)
- `/opt/services/nginx/certs/live/api.dotsai.in/` - Let's Encrypt SSL cert (fullchain.pem + privkey.pem)

## Credentials

**ANALYTICS_WRITE_TOKEN:** `8ad6b8017639f8b248ccb25609f9112e14472e932169567948b554aa16a03b02`

This token is needed in Plan 02-04 for the browser analytics snippet. It is stored on VPS at `/opt/services/.env.analytics`.

## Decisions Made
- **Certbot config-dir:** Used `--config-dir /opt/services/nginx/certs` to place certs where nginx container expects them (mapped to `/etc/letsencrypt` inside container). The default certbot path (`/etc/letsencrypt`) would not be visible to nginx.
- **Staging then production:** Ran certbot staging first to validate ACME challenge path works, then production cert. Staging cert was deleted before production run.
- **SSL-ready conf activation:** The `api.dotsai.in.conf.ssl-ready` file was pre-created (likely during Task 1's initial VPS setup). Activated by copying over the HTTP-only conf rather than writing from scratch.
- **Bot filter curl behavior is correct:** curl User-Agent is caught by `BotFilterMiddleware` returning 204 -- this is by design. Auth verification must use a browser-like User-Agent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Certbot webroot path correction**
- **Found during:** Task 1 (SSL certificate)
- **Issue:** Plan suggested `/opt/services/nginx/certbot/` as webroot but actual path is `/opt/services/certbot-webroot` (mapped to `/var/www/certbot` inside nginx container)
- **Fix:** Discovered correct webroot via `docker inspect nginx` mount inspection, used `/opt/services/certbot-webroot`
- **Verification:** ACME challenge test file served successfully at `http://api.dotsai.in/.well-known/acme-challenge/test-token`

**2. [Rule 3 - Blocking] Certbot config-dir required for nginx cert visibility**
- **Found during:** Task 1 (SSL certificate)
- **Issue:** Default certbot stores certs at `/etc/letsencrypt/live/` on host, but nginx reads from `/opt/services/nginx/certs/live/` (bind-mounted). Staging cert landed in wrong location.
- **Fix:** Deleted staging cert, re-ran production certbot with `--config-dir /opt/services/nginx/certs`
- **Verification:** Cert at `/opt/services/nginx/certs/live/api.dotsai.in/fullchain.pem`, nginx test and reload successful

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary -- certbot paths differ from plan's assumptions. No scope creep.

## Issues Encountered
- Staging certbot cert landed at `/etc/letsencrypt/live/` instead of where nginx expects. Resolved by using `--config-dir` flag on production run.
- `curl` based auth test returned 204 instead of 401 -- initially looked like auth was broken but actually the bot filter middleware correctly catches curl's User-Agent. Verified auth works by testing with `User-Agent: Mozilla/5.0`.

## User Setup Required
None - all deployment configuration done on VPS.

## Verification Results

```
PASS: health (https://api.dotsai.in/health returns {"status":"ok","db":"connected"})
PASS: auth (POST /events without Bearer returns 401)
PASS: container (analytics running with restart: always)
PASS: tables (3 tables in analytics schema)
PASS: SSL (TLSv1.3, CN=api.dotsai.in)
PASS: env file permissions (chmod 600)
```

## Next Phase Readiness
- api.dotsai.in live with SSL -- ready for Plan 02-04 (browser snippet integration)
- ANALYTICS_WRITE_TOKEN documented above for snippet Bearer header
- CORS allows dotsai.in and zeroonedotsai.consulting origins

---
*Phase: 02-fastapi-analytics-api*
*Completed: 2026-03-27*

## Self-Check: PASSED
- [x] 02-03-SUMMARY.md exists on disk
- [x] https://api.dotsai.in/health returns 200 with valid SSL
- [x] No local code commits needed (VPS-only deployment)
