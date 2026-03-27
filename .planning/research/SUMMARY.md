# Project Research Summary

**Project:** dotsai.in — Self-Hosted Scheduling + In-House Analytics + Personal Hub
**Domain:** VPS multi-service stack (Cal.com + FastAPI analytics + PostgreSQL + nginx)
**Researched:** 2026-03-27
**Confidence:** HIGH (core stack and pitfalls), MEDIUM (Cal.com image tag details)

---

## Executive Summary

This project adds three self-hosted services to an existing VPS (72.62.229.16) already running nginx + dotsai.in static site: a Cal.com scheduling instance at `cal.dotsai.in`, a FastAPI analytics API at `api.dotsai.in`, and a personal page at `meet.dotsai.in`. The correct architectural approach is a single Docker Compose file that places all services on a shared internal network (`vps-net`), with nginx as the only public-facing component. PostgreSQL uses schema separation (`calcom` schema + `analytics` schema) to serve both Cal.com and analytics from one container, reducing VPS resource usage. The `calcom/docker` community repository was archived October 2025 — the source of truth for Docker configuration is now the main `calcom/cal.com` monorepo.

The recommended build order is dependency-driven: PostgreSQL must be healthy first, analytics API second (validates the network setup cheaply), then Cal.com (the most complex service — Prisma migrations take 2-5 minutes on first start), then nginx subdomain configs, then the browser tracking snippet, and finally the Cal.com-to-analytics webhook bridge. This order means infrastructure is proven before the hardest component (Cal.com) is layered on top. The gateway section in `index.html` and `meet.dotsai.in` are frontend tasks that can proceed in parallel once the backend services are live.

The single highest-risk issue is Cal.com's `NEXT_PUBLIC_WEBAPP_URL` being baked in at Docker image build time — pulling the pre-built image from Docker Hub will result in an instance that renders all links as `localhost:3000`. This has caused full setup failures for 50+ documented community cases. The mitigation is to either build the image locally with the correct build arg or accept the startup-time patching delay from the official image. Every other risk in this project is manageable with standard precautions.

---

## Key Findings

### Recommended Stack

The stack reuses everything already on the VPS and adds the minimum new services. nginx (already running in Docker) handles all SSL termination and subdomain routing via new `server {}` blocks — no new reverse proxy technology is introduced. PostgreSQL 17 is the single database instance, accessed by both Cal.com (via Prisma ORM, `?schema=calcom` in the connection string) and FastAPI analytics (via SQLAlchemy 2.0 async + asyncpg 0.29.0, `analytics` schema). Redis is only required if using Cal.com API v2 — not needed for standard booking flow.

**Core technologies:**
- **Cal.com** (`calcom.docker.scarf.sh/calcom/cal.com`, pinned semver tag): self-hosted scheduling UI, manages bookings and webhook dispatch
- **PostgreSQL 17** (`postgres:17`): single DB instance, multi-schema — do not use `:latest` (risks jumping to v18 on `docker compose pull`)
- **FastAPI 0.115.x** + Python 3.12: async analytics ingest API — 3-5x throughput advantage over sync frameworks under load
- **SQLAlchemy 2.0.48** + **asyncpg 0.29.0**: async ORM; asyncpg pinned to `<0.30` due to known `create_async_engine` compat issues in 0.30+
- **Alembic 1.13.x**: schema migrations for analytics tables — init with `alembic init -t async`
- **nginx** (existing): extend with `cal.dotsai.in.conf` and `api.dotsai.in.conf` in `conf.d/`; add `resolver 127.0.0.11 valid=10s ipv6=off;` to every server block (critical — without it, Docker DNS resolution fails on container restart)
- **slowapi 0.1.9**: FastAPI rate limiting middleware on the analytics ingest endpoint
- **Redis 7-alpine**: only needed if Cal.com API v2 is used; skip for v1

### Expected Features

**Must have (table stakes):**
- Cal.com accessible at `cal.dotsai.in` with SSL, one event type ("30-min AI consultation"), email confirmation to guest + Meet
- Google Calendar integration (prevents double-booking)
- Cal.com BOOKING_CREATED webhook piped to analytics PostgreSQL
- Analytics ingest: `page_view`, `gateway_click`, `cta_click`, `booking_created`, `session_start` events with IP hashing (never raw IP)
- Gateway section in `index.html`: three destination cards (dotsai.cloud, zeroonedotsai.consulting, meet.dotsai.in), GSAP ScrollTrigger entrance, mobile tap targets ≥ 44px, `<a href>` not `div onclick`
- `meet.dotsai.in` personal page: name + photo + one-liner + Book a call CTA + analytics snippet
- PostgreSQL named volumes declared from day one (prevent data loss on `docker compose down`)

**Should have (differentiators):**
- Pre-booking qualification question: "What are you hoping to solve?"
- 24h minimum notice period + 15min buffer between meetings on Cal.com event type
- "How did you hear about us?" pre-booking field for attribution
- Current availability badge on consulting card in gateway section
- MaxMind GeoLite2 local geolocation (country + city from IP before hashing — no external API call)
- Bot filtering (20-30 common UA strings blocked at ingest)
- FastAPI BackgroundTasks for async DB writes (return HTTP 202 immediately, write to Postgres in background)
- Cal.com-to-analytics webhook via internal Docker network (`http://analytics:8000/webhooks/calcom`) not public internet

**Defer to v2+:**
- Analytics dashboard UI — plain SQL queries in psql are sufficient in v1
- Stripe/payments on Cal.com — add after booking flow is validated
- Multiple Cal.com event types — one type proves the flow first
- Daily email digest from analytics — build dashboard first
- Blog on meet.dotsai.in — content maintenance is a separate project
- Real-time analytics dashboard — daily aggregate queries are sufficient at personal site scale

### Architecture Approach

All services run on a single Docker Compose file sharing a bridge network (`vps-net`). No service except nginx has a host port mapping. nginx resolves container names via Docker's embedded DNS (`127.0.0.11`). The browser tracking snippet on dotsai.in and zeroonedotsai.consulting posts to `https://api.dotsai.in/events` with a static Bearer token — write-only key scoped to event ingestion, never able to read data. Cal.com dispatches BOOKING_CREATED webhooks directly to `http://analytics:8000/webhooks/calcom` over the internal network (HMAC-SHA256 verified via `x-cal-signature-256` header). The webhook endpoint uses its own auth — do NOT put Bearer token auth on it or Cal.com's webhook delivery will fail.

**Major components:**

| Component | Responsibility | Network exposure |
|-----------|----------------|-----------------|
| nginx | TLS termination, subdomain routing, rate limiting | Public (80/443) |
| postgres | Data persistence: Cal.com schema + analytics schema | Internal only |
| calcom | Booking UI, calendar management, webhook dispatch | Via nginx only |
| analytics | Event ingestion, webhook receipt, metrics API | Via nginx only |
| pg-backup | Daily pg_dump to mounted volume | Internal only |

**Database schema layout:**
```sql
CREATE SCHEMA IF NOT EXISTS calcom;    -- Prisma-managed, owned by Cal.com
CREATE SCHEMA IF NOT EXISTS analytics; -- Alembic-managed, three tables below
```

Analytics tables: `analytics.visitors` (UUID, fingerprint, country, referrer), `analytics.events` (BIGSERIAL, ts, visitor_id, site, page, event_name, properties JSONB), `analytics.bookings` (BIGSERIAL, calcom_uid UNIQUE, status, attendee_email, start/end_time, raw_payload JSONB).

### Critical Pitfalls

1. **Cal.com `NEXT_PUBLIC_WEBAPP_URL` baked at build time** — Pulling the pre-built Docker Hub image results in all links pointing to `localhost:3000`. OAuth fails. Confirmation emails are broken. Fix: build the image with `--build-arg NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in` or accept the startup-patching delay from the official image (slower cold start). Verify by inspecting link hrefs in the live UI before onboarding real bookings.

2. **PostgreSQL data loss on `docker compose down`** — All Cal.com accounts, event types, and analytics history are lost permanently if PostgreSQL data is not on a named volume. Declare the volume before first `up`. Never run `docker compose down -v` in production. Use `docker compose stop` for debugging.

3. **nginx DNS resolution fails after container restart** — Without `resolver 127.0.0.11 valid=10s ipv6=off;` in each server block, nginx cannot resolve container names after a restart. All proxied subdomains return 502. Add this directive to every `server {}` block that uses a container name in `proxy_pass`.

4. **SSL certificate issuance rate-limited by Let's Encrypt** — Repeated failed certbot runs against production endpoints trigger a 5-failures/hour rate limit (and 5 duplicates/week weekly limit). Always use `certbot --staging` for all testing. Only switch to production endpoint once confident in the nginx config. Verify DNS propagation (`dig cal.dotsai.in` showing VPS IP) before running certbot.

5. **Duplicate CORS headers crash browser requests to analytics API** — If nginx adds `Access-Control-Allow-Origin` headers AND FastAPI's CORSMiddleware also adds them, browsers see duplicated headers and reject the response. Never add CORS headers in nginx for the analytics service. FastAPI handles CORS entirely. Both `https://zeroonedotsai.consulting` and `https://www.zeroonedotsai.consulting` must be listed explicitly in `allow_origins`.

---

## Implications for Roadmap

All four research files converge on the same dependency chain. Phase order is forced by technical dependencies, not preference.

### Phase 0: VPS Pre-Flight + PostgreSQL Foundation

**Rationale:** Nothing else can start without a healthy PostgreSQL instance and a VPS that can support the memory load. Check VPS RAM (`free -h`) and add 2GB swap before any Docker work. If RAM is under 3GB, Cal.com OOM kills are likely. Configure named volumes in docker-compose before any `up` command — retrofitting this later risks data loss.

**Delivers:** Running PostgreSQL with `calcom` and `analytics` schemas created, verified via `pg_isready` healthcheck. Backup cron configured from day one. No public exposure (no `ports:` on postgres service).

**Addresses:** Analytics schema foundation (FEATURES.md Part C), backup requirements

**Avoids:** Pitfall 3 (data loss), Pitfall 14 (postgres port exposed), Pitfall 12 (backup not tested), Pitfall 4 (RAM exhaustion)

**Research flag:** Standard patterns — no additional research needed.

---

### Phase 1: FastAPI Analytics API + Browser Snippet

**Rationale:** Analytics is the simplest new service to bring up and directly validates the Docker network setup (nginx → analytics container routing) at low risk. Once this is live, every subsequent milestone gets instrumented from day one — including Cal.com bookings and the gateway section.

**Delivers:** `POST /events` ingest endpoint live at `api.dotsai.in`, CORS configured for dotsai.in + zeroonedotsai.consulting, rate limiting active, Alembic migrations applied, SSL cert issued for `api.dotsai.in`. Browser tracking snippet added to `public/index.html` — fires `page_view` on load, exposes `window.dotsTrack()` for manual events.

**Uses:** FastAPI 0.115.x, Python 3.12, SQLAlchemy 2.0.48, asyncpg 0.29.0, slowapi, Alembic

**Implements:** `analytics.visitors` + `analytics.events` tables

**Avoids:** Pitfall 7 (CORS missing zeroonedotsai.consulting), Pitfall 6 (API key design), Pitfall 15 (nginx config syntax)

**Research flag:** Standard patterns — FastAPI + SQLAlchemy async is well-documented.

---

### Phase 2: Cal.com at cal.dotsai.in

**Rationale:** Cal.com is the most complex service (Prisma migrations, build-time URL caveat, Google OAuth HTTPS chain). It goes after the infrastructure is proven, so debugging Cal.com-specific issues is isolated from network and database issues. The existing `cal.com/meetdeshani` booking link on dotsai.in stays live until this is fully verified.

**Delivers:** Cal.com accessible at `cal.dotsai.in` with SSL, one event type configured, SMTP email confirmed working (test booking end-to-end before cutting over), Google Calendar integration connected.

**Uses:** Cal.com Docker image (built with correct `NEXT_PUBLIC_WEBAPP_URL`), PostgreSQL `calcom` schema, Redis 7-alpine (only if API v2 needed — skip otherwise), SMTP provider (Resend free tier recommended)

**Avoids:** Pitfall 1 (localhost:3000 URL), Pitfall 2 (port 80/443 conflict), Pitfall 8 (silent email failures), Pitfall 9 (Google OAuth HTTPS chain), Pitfall 5 (SSL cert rate limiting), Pitfall 13 (weak NEXTAUTH_SECRET), Pitfall 16 (latest tag auto-upgrades)

**Research flag:** Moderate — Cal.com build-time variable behavior (MEDIUM confidence) should be tested early. Run `docker exec <calcom> env | grep WEBAPP_URL` immediately after first start to verify URL is correct before any other setup.

---

### Phase 3: Cal.com Webhook Bridge to Analytics

**Rationale:** After both Cal.com and analytics are running independently, wire them together. The webhook goes over the internal Docker network (`http://analytics:8000/webhooks/calcom`) — not the public internet — to avoid SSL overhead and latency. This delivers the `booking_created` analytics event and fills in the `analytics.bookings` table.

**Delivers:** Every Cal.com BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED event stored in `analytics.bookings` with HMAC-SHA256 signature verification. Attribution chain: session referrer → booking visible in data.

**Implements:** `analytics.bookings` table, `/webhooks/calcom` endpoint, Cal.com webhook configured in admin UI (Subscriber URL: `http://analytics:8000/webhooks/calcom`)

**Avoids:** Pitfall 10 (migration desync on upgrades — test booking creation after wiring)

**Research flag:** Standard patterns — Cal.com webhook spec is HIGH confidence, HMAC verification is standard.

---

### Phase 4: Gateway Section + meet.dotsai.in

**Rationale:** Frontend work that depends on all backend services being live (gateway must link to real URLs; meet.dotsai.in must link to real Cal.com booking page). These can be built in parallel and staged behind real destinations.

**Delivers:**
- Gateway section in `public/index.html`: three destination cards with GSAP ScrollTrigger entrance, `gateway_click` analytics event on each card, mobile tap targets, `<a href>` elements (not JS click handlers). Uses existing brand palette — no bento grids, no new visual system.
- `meet.dotsai.in`: static HTML with consistent brand identity (Instrument Serif + DM Sans + CSS vars from index.html), name + photo + one-liner + short bio + Book a call CTA linking to `cal.dotsai.in`, OpenGraph meta tags, `page_view` analytics snippet.

**Addresses:** FEATURES.md Parts A and D — all table stakes features for gateway and personal page

**Avoids:** Gateway anti-features (bento grids, long descriptions, countdown timers), personal page anti-features (skills resume lists, contact forms)

**Research flag:** Standard patterns — static HTML, GSAP ScrollTrigger already in use on the site.

---

### Phase Ordering Rationale

- PostgreSQL before all services (healthcheck dependency in `depends_on`)
- Analytics before Cal.com (proves Docker network + nginx routing cheaply before the complex service)
- SSL certs before nginx configs reference them (nginx fails to start on missing cert files)
- Both services running before webhook bridge (obvious — both ends must exist)
- Frontend after backends (gateway cards need real destination URLs; booking CTA needs live Cal.com)
- pg-backup added last (after all data exists — no point backing up empty databases)

### Research Flags

Needs extra care during execution (not additional research-phase, but explicit verification steps):
- **Phase 2 (Cal.com):** Verify `NEXT_PUBLIC_WEBAPP_URL` immediately after container start — `docker exec calcom env | grep WEBAPP_URL`. This single check prevents hours of debugging downstream OAuth and email issues.
- **Phase 1 (asyncpg):** The asyncpg 0.29.0 pinning is based on MEDIUM-confidence community reports. On fresh setup, test `create_async_engine` with asyncpg before committing to the version pin.

Standard patterns (no additional research needed):
- **Phase 0 (PostgreSQL):** Volume mounts, healthchecks, schema creation — all standard Docker Compose patterns.
- **Phase 3 (webhook):** Cal.com BOOKING_CREATED payload spec is HIGH confidence; HMAC-SHA256 verification is standard Python.
- **Phase 4 (frontend):** GSAP ScrollTrigger already used in the codebase; static HTML personal page is low-risk.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified against official PyPI, Docker Hub, and GitHub sources. One exception: asyncpg 0.30+ compat issue is MEDIUM (community reports, needs verification on fresh setup) |
| Features | HIGH | Cal.com env vars verified against official `.env.example`. Analytics schema patterns verified against multiple established tools. Gateway UX patterns from multiple 2025 sources |
| Architecture | HIGH (Docker/nginx patterns), MEDIUM (Cal.com) | Docker Compose multi-service, nginx Docker DNS resolver, CORS patterns — all HIGH. Cal.com `NEXT_PUBLIC_WEBAPP_URL` build-time baking behavior — MEDIUM (GitHub issues confirm it, but startup patching behavior may vary by image version) |
| Pitfalls | HIGH | Most critical pitfalls (localhost URL, port conflict, data loss, SSL rate limiting, CORS) are HIGH confidence from official sources and 20+ community reproductions |

**Overall confidence:** HIGH

### Gaps to Address

- **Cal.com image version to pin:** The exact stable semver tag (e.g., `v5.6.19`) was not confirmed from Docker Hub tags page. Before Phase 2, check `hub.docker.com/r/calcom/cal.com/tags` or the GitHub releases page and pin to the latest stable tag — do not use `:latest` in the compose file.
- **VPS RAM headroom:** Actual VPS RAM and current usage must be checked before Cal.com deployment (`free -h` + `docker stats`). The 3GB threshold is extrapolated from community reports on 4GB VPS builds — the exact safe minimum for the production runtime (not build) is MEDIUM confidence.
- **SMTP provider selection:** Research documents Resend as the free-tier option (3000 emails/month) but does not confirm current Resend SMTP credentials format. Verify `EMAIL_SERVER_HOST=smtp.resend.com`, port, and API key format against Resend docs at time of Phase 2 execution.
- **`zeroonedotsai.consulting` hosting:** FEATURES.md notes this site needs to include the analytics snippet. Confirm whether it is on Cloudflare Pages (implied) and whether any CSP headers would block the `fetch()` call to `api.dotsai.in`.

---

## Sources

### Primary (HIGH confidence)
- Cal.com main repo `docker-compose.yml`: https://github.com/calcom/cal.com/blob/main/docker-compose.yml
- Cal.com official `.env.example`: https://github.com/calcom/cal.com/blob/main/.env.example
- Cal.com Docker docs: https://cal.com/docs/self-hosting/docker
- Cal.com Webhook docs: https://cal.com/docs/developing/guides/automation/webhooks
- Cal.com Organization Setup docs: https://cal.com/docs/self-hosting/guides/organization/organization-setup
- FastAPI CORS official docs: https://fastapi.tiangolo.com/tutorial/cors/
- FastAPI security official docs: https://fastapi.tiangolo.com/tutorial/security/first-steps/
- SQLAlchemy 2.0.48 PyPI: https://pypi.org/project/SQLAlchemy/
- PostgreSQL 17 Docker Hub: https://hub.docker.com/_/postgres
- Docker Compose healthcheck startup order: https://docs.docker.com/compose/how-tos/startup-order/
- Cal.com `calcom/docker` repo archived Oct 29 2025: https://github.com/calcom/docker

### Secondary (MEDIUM confidence)
- Cal.com GitHub issues #3704, #8501, #21921, #136 — localhost URL bug (50+ reports, HIGH pattern confidence)
- Cal.com GitHub issue #25476 — Google OAuth HTTPS chain
- Cal.com GitHub issue #10592 — silent email failure
- nginx Docker DNS resolver: https://www.emmanuelgautier.com/blog/nginx-docker-dns-resolution
- FastAPI async SQLAlchemy pattern: https://leapcell.io/blog/building-high-performance-async-apis-with-fastapi-sqlalchemy-2-0-and-asyncpg
- asyncpg 0.29.0 / 0.30+ compat issue: community reports via WebSearch (MEDIUM — verify on fresh setup)
- Cal.com RAM requirements: https://github.com/calcom/docker/discussions/302
- Let's Encrypt rate limits: https://blog.miguelgrinberg.com/post/using-free-let-s-encrypt-ssl-certificates-in-2025
- Gateway UX best practices: https://mingly.link/blog/link-in-bio-2025, https://the-bithub.com/blog/link-in-bio-optimization-guide-2025
- Analytics schema patterns: https://buildwithstudio.com/knowledge/guide-to-laying-out-an-analytics-schema/

---

*Research completed: 2026-03-27*
*Ready for roadmap: yes*
