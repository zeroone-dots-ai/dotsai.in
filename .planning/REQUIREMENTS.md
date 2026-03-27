# Requirements — dotsai.in Gateway + Analytics Platform

**Project:** dotsai.in self-hosted hub
**Owner:** Meet Deshani · ZeroOne D.O.T.S AI
**Derived from:** Research SUMMARY.md · PROJECT.md
**Written:** 2026-03-27
**Status:** v1 — baseline requirements for Milestone 1

---

## Scope

Milestone 1 delivers four things: a PostgreSQL analytics foundation, a FastAPI event-ingest API, a self-hosted Cal.com at `cal.dotsai.in`, and a gateway section in `public/index.html` plus a `meet.dotsai.in` personal page.

All services run on VPS 72.62.229.16 (Hostinger). Zero new cloud vendors.

---

## Functional Requirements

### REQ-01 — PostgreSQL Analytics Foundation
- **R01.1** Single PostgreSQL 17 instance (pinned, no `:latest`) with two schemas: `calcom` and `analytics`
- **R01.2** PostgreSQL data on a named Docker volume — never lost on `docker compose down`
- **R01.3** Both schemas created before any dependent service starts (`depends_on` healthcheck)
- **R01.4** Daily `pg_dump` backup to mounted volume, retained for 7 days, auto-pruned
- **R01.5** PostgreSQL never port-mapped to host (internal Docker network only)

### REQ-02 — Analytics Tables
- **R02.1** `analytics.visitors` — UUID primary key, fingerprint hash, country, city, referrer, first_seen, last_seen
- **R02.2** `analytics.events` — BIGSERIAL id, timestamp, visitor_id (FK), site (string), page (string), event_name (string), properties (JSONB)
- **R02.3** `analytics.bookings` — BIGSERIAL id, calcom_uid UNIQUE, status, attendee_email (hashed), start_time, end_time, raw_payload JSONB
- **R02.4** Five required event names: `page_view`, `session_start`, `gateway_click`, `cta_click`, `booking_created`
- **R02.5** Raw IP address NEVER stored — fingerprint is a salted SHA-256 hash of IP + UA
- **R02.6** Alembic manages `analytics` schema migrations; `calcom` schema is Prisma-managed (never touched manually)

### REQ-03 — FastAPI Analytics API at api.dotsai.in
- **R03.1** Accessible at `https://api.dotsai.in` via nginx → Docker internal network
- **R03.2** `POST /events` — ingest event payload, return HTTP 202 immediately, write to DB via BackgroundTasks
- **R03.3** Bearer token auth on `/events` — write-only scoped key (env var, never hardcoded)
- **R03.4** `POST /webhooks/calcom` — Cal.com booking webhook, HMAC-SHA256 signature verified via `x-cal-signature-256` header
- **R03.5** CORS allow-list: `https://dotsai.in`, `https://zeroonedotsai.consulting`, `https://www.zeroonedotsai.consulting` — no wildcard
- **R03.6** Rate limiting: 100 req/min per IP on `/events` (slowapi)
- **R03.7** Bot filtering: minimum 20 common headless/bot UA strings blocked at ingest middleware
- **R03.8** SSL via Let's Encrypt; nginx terminates TLS (API container has no open ports on host)
- **R03.9** `restart: always` on the analytics container

### REQ-04 — Cal.com at cal.dotsai.in
- **R04.1** Accessible at `https://cal.dotsai.in` — all internal links must resolve to `cal.dotsai.in` (not `localhost:3000`)
- **R04.2** Docker image built with `NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in` at build time
- **R04.3** Connects to `calcom` schema in the shared PostgreSQL instance
- **R04.4** One event type configured: "30-min AI Consultation" with:
  - 24h minimum advance notice
  - 15min buffer between meetings
  - Pre-booking question: "What are you hoping to solve?"
  - Attribution field: "How did you hear about us?"
- **R04.5** Google Calendar integration connected (prevents double-booking)
- **R04.6** Email confirmation to attendee + Meet on booking (SMTP via Resend free tier)
- **R04.7** BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED webhooks configured to `http://analytics:8000/webhooks/calcom` (internal Docker network, not public internet)
- **R04.8** `NEXTAUTH_SECRET` generated with `openssl rand -hex 32` — never re-used, stored in Vault
- **R04.9** `restart: always` on the Cal.com container
- **R04.10** Cal.com image tag pinned to explicit semver (e.g. `v5.x.y`) — `:latest` forbidden

### REQ-05 — Gateway Section in public/index.html
- **R05.1** New section in `public/index.html` with three destination cards:
  1. **dotsai.cloud** — Infinity Nexus platform
  2. **zeroonedotsai.consulting** — Business AI consulting
  3. **meet.dotsai.in** — Who is Meet
- **R05.2** Cards use `<a href>` elements — no `div onclick` handlers (crawlable, accessible)
- **R05.3** Mobile tap targets ≥ 44px
- **R05.4** Each card click fires `gateway_click` event via `window.dotsTrack()`
- **R05.5** GSAP ScrollTrigger entrance animation consistent with existing site animations
- **R05.6** No bento grids, no neon, no glassmorphism — matches existing D.O.T.S. brand palette
- **R05.7** Section accessible server-side (not behind JS guard)

### REQ-06 — Browser Tracking Snippet
- **R06.1** Lightweight inline snippet added to `<head>` of `public/index.html`
- **R06.2** Fires `page_view` event on page load
- **R06.3** Fires `session_start` on first visit (sessionStorage gate)
- **R06.4** Exposes `window.dotsTrack(eventName, properties)` for manual event calls
- **R06.5** POSTs to `https://api.dotsai.in/events` with Bearer token
- **R06.6** Snippet added to zeroonedotsai.consulting source (Cloudflare Pages — confirm CSP allows cross-origin fetch to api.dotsai.in)

### REQ-07 — meet.dotsai.in Personal Page
- **R07.1** Static HTML page served from nginx at `meet.dotsai.in`
- **R07.2** Content: name + photo + one-liner ("I build private AI for enterprises and solopreneurs") + short bio (3-4 sentences) + Book a Call CTA
- **R07.3** Book a Call CTA links to `cal.dotsai.in`
- **R07.4** OpenGraph meta tags: og:title, og:description, og:image, og:url
- **R07.5** Consistent brand: Instrument Serif + DM Sans, D.O.T.S. color palette from index.html CSS vars
- **R07.6** Analytics snippet included (`page_view` fires on load)
- **R07.7** No blog, no contact form, no social feed — simple, direct

### REQ-08 — nginx & Infrastructure
- **R08.1** `resolver 127.0.0.11 valid=10s ipv6=off;` in every nginx server block that proxies to a container
- **R08.2** New server blocks for: `cal.dotsai.in`, `api.dotsai.in`, `meet.dotsai.in`
- **R08.3** SSL via Let's Encrypt for all three subdomains (certbot on VPS)
- **R08.4** Let's Encrypt staging endpoint used for all testing; production endpoint only on final verified run
- **R08.5** CORS headers on analytics nginx block NOT added — FastAPI CORSMiddleware handles it entirely
- **R08.6** All new services: `restart: always` in docker-compose

### REQ-09 — Security
- **R09.1** No credentials in any git-tracked file — all secrets via env vars
- **R09.2** Analytics API write token stored as Docker Compose secret / env file outside repo
- **R09.3** Cal.com `NEXTAUTH_SECRET` min 32 bytes, from `/dev/urandom` or `openssl`
- **R09.4** PostgreSQL password min 24 chars, random, stored in Vault
- **R09.5** All new credentials logged to `~/Desktop/Vault/dotsai.in/credentials.md`
- **R09.6** PostgreSQL port 5432 NOT exposed to host or public internet

### REQ-10 — Observability & Testing
- **R10.1** E2E test script validates all services are live: `api.dotsai.in/health`, `cal.dotsai.in`, `meet.dotsai.in`, dotsai.in gateway section links
- **R10.2** Test booking end-to-end (real test booking on Cal.com) before removing old `cal.com/meetdeshani` link
- **R10.3** Verify analytics event flow: open dotsai.in → `psql` query shows `page_view` event in `analytics.events`
- **R10.4** Verify booking webhook: complete test booking → `analytics.bookings` row appears within 5s
- **R10.5** All docker-compose services show `healthy` or `running` in `docker ps` after setup

---

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NF-01 | Cal.com page load | < 3s on 4G (after cold start) |
| NF-02 | Analytics ingest latency | < 50ms p95 (returns 202 immediately) |
| NF-03 | PostgreSQL uptime | 99.9% (Docker `restart: always`) |
| NF-04 | Backup window | Daily, off-peak (3 AM VPS time) |
| NF-05 | SSL renewal | Certbot auto-renew cron (Let's Encrypt 90-day cycle) |
| NF-06 | VPS RAM budget | Cal.com ≤ 512MB runtime, analytics ≤ 128MB, postgres ≤ 256MB |
| NF-07 | No third-party analytics | Zero visitor data to GA, Mixpanel, or similar |

---

## Out of Scope (v1)

- Analytics dashboard UI — raw `psql` queries sufficient
- Stripe/paid bookings on Cal.com
- Multiple Cal.com event types
- Blog on meet.dotsai.in
- Real-time analytics streaming
- Multi-user access to PostgreSQL
- Redis (unless Cal.com API v2 is required — skip in v1)

---

## Constraints

- **Infrastructure:** VPS 72.62.229.16 only — no new cloud vendors
- **Licenses:** Cal.com (MIT), FastAPI (MIT), PostgreSQL (PostgreSQL License), nginx (BSD)
- **Budget:** Zero additional cost in v1 (Resend free tier for SMTP: 3000 emails/month)
- **Deployment:** All services via Docker Compose with `restart: always`
- **Git workflow:** All changes via PR → merge to main → auto-deploy (no direct VPS edits for code)

---

## Assumptions

1. VPS has ≥ 3GB available RAM (or swap configured to cover Cal.com runtime)
2. DNS A records for `cal.dotsai.in`, `api.dotsai.in`, `meet.dotsai.in` point to 72.62.229.16 before certbot runs
3. zeroonedotsai.consulting CSP policy does not block cross-origin fetch to `api.dotsai.in`
4. `cal.com/meetdeshani` SaaS link stays live until Cal.com self-hosted is E2E verified
5. Resend free tier (3000 emails/month) is sufficient for booking volume at launch

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-01 — PostgreSQL Foundation | Phase 1 | Pending |
| REQ-02 (R02.1, R02.2, R02.4–R02.6) — Analytics Tables (visitors + events) | Phase 2 | Pending |
| REQ-02 (R02.3) — Analytics Tables (bookings) | Phase 4 | Pending |
| REQ-03 (R03.1–R03.3, R03.5–R03.9) — FastAPI API | Phase 2 | Pending |
| REQ-03 (R03.4) — Webhook endpoint | Phase 4 | Pending |
| REQ-04 (R04.1–R04.6, R04.8–R04.10) — Cal.com setup | Phase 3 | Pending |
| REQ-04 (R04.7) — Cal.com webhooks configured | Phase 4 | Pending |
| REQ-05 — Gateway Section | Phase 5 | Pending |
| REQ-06 — Browser Tracking Snippet | Phase 2 | Pending |
| REQ-07 — meet.dotsai.in Personal Page | Phase 5 | Pending |
| REQ-08 (R08.6) — restart: always for all services | Phase 1 | Pending |
| REQ-08 (R08.1–R08.5) — nginx config patterns | Phase 2 | Pending |
| REQ-08 (R08.2, R08.3) — meet.dotsai.in server block | Phase 5 | Pending |
| REQ-09 (R09.4, R09.6) — PostgreSQL password + no port | Phase 1 | Pending |
| REQ-09 (R09.1–R09.3) — Secret management for API + Cal.com | Phase 2–3 | Pending |
| REQ-09 (R09.5) — Vault credential logging | Phase 3 | Pending |
| REQ-10 (R10.3, R10.5) — Analytics event verification | Phase 2 | Pending |
| REQ-10 (R10.2, R10.5) — Cal.com E2E test booking | Phase 3 | Pending |
| REQ-10 (R10.4) — Webhook row verification | Phase 4 | Pending |
| REQ-10 (R10.1) — Full E2E health check script | Phase 5 | Pending |

---

*Last updated: 2026-03-27*
