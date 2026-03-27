# Roadmap: dotsai.in — Self-Hosted Hub

## Overview

Milestone 1 transforms dotsai.in from a standalone static site into a fully self-hosted hub: PostgreSQL analytics foundation on the VPS, a FastAPI event-ingest API at api.dotsai.in, a self-hosted Cal.com booking system at cal.dotsai.in, a webhook bridge connecting bookings to analytics, and a gateway section plus meet.dotsai.in personal page that tie all services together. Every visitor interaction and booking is owned entirely by Meet — zero third-party analytics dependency.

## Milestone

**Milestone 1 — Self-Hosted Hub v1**

## Phases

- [x] **Phase 1: VPS Pre-Flight + PostgreSQL Foundation** - Provision the database layer; nothing else can start without it
- [x] **Phase 2: FastAPI Analytics API** - Self-contained analytics ingest service, proves Docker networking before Cal.com
- [~] **Phase 3: Cal.com at cal.dotsai.in** - SKIPPED (using Cal.com SaaS at cal.com/meetdeshani instead of self-hosting)
- [ ] **Phase 4: Cal.com Webhook Bridge to Analytics** - Wire Cal.com SaaS booking events into PostgreSQL via HMAC-verified webhook
- [ ] **Phase 5: Gateway Section + meet.dotsai.in** - Frontend layer completing the hub — navigation and personal page

## Phase Details

---

### Phase 1: VPS Pre-Flight + PostgreSQL Foundation

**Goal**: A healthy PostgreSQL 17 instance with both schemas created is running on the VPS, backed up nightly, and accessible only to other Docker services on the internal network.

**Depends on**: Nothing (first phase)

**Requirements**: REQ-01 (R01.1–R01.5), REQ-08 (R08.6), REQ-09 (R09.4, R09.6)

**Success Criteria** (what must be TRUE when this phase completes):
1. `docker exec postgres pg_isready` returns `accepting connections` and `docker ps` shows the container as `healthy`
2. `psql` query confirms both `calcom` and `analytics` schemas exist in the database
3. PostgreSQL has no host port mapping — `docker inspect postgres` shows no `HostPort` entries
4. A named Docker volume exists and survives `docker compose stop && docker compose start` without data loss
5. `pg_dump` backup cron fires at 3 AM and a `.sql.gz` file appears in the backup volume; files older than 7 days are pruned automatically

**Plans**: 3 plans (COMPLETE)

Plans:
- [x] 01-01: VPS RAM audit, swap configuration, and Docker Compose scaffold with postgres:17 service
- [x] 01-02: Schema initialisation, healthcheck verification, and pg_dump backup cron setup
- [x] 01-03: Named volume migration and external: true declaration

---

### Phase 2: FastAPI Analytics API

**Goal**: A production-ready analytics ingest API is live at api.dotsai.in — accepting events from dotsai.in with bot filtering, rate limiting, and SSL. The browser tracking snippet on dotsai.in fires page_view events that appear in analytics.events.

**Depends on**: Phase 1 (PostgreSQL with analytics schema must be healthy)

**Requirements**: REQ-02 (R02.1–R02.6), REQ-03 (R03.1–R03.9), REQ-06 (R06.1–R06.6), REQ-08 (R08.1–R08.5), REQ-09 (R09.1–R09.3), REQ-10 (R10.3, R10.5)

**Success Criteria** (what must be TRUE when this phase completes):
1. `https://api.dotsai.in/health` returns HTTP 200 with a valid SSL certificate
2. Opening dotsai.in in a browser and running `SELECT * FROM analytics.events LIMIT 5;` in psql shows a `page_view` row within 30 seconds
3. A `session_start` event appears in analytics.events on first visit (not on repeat visits within the same browser session)
4. `window.dotsTrack('cta_click', {target: 'test'})` called from browser devtools produces a row in analytics.events
5. A POST to `https://api.dotsai.in/events` without a Bearer token returns HTTP 401; a POST from a bot UA string returns HTTP 204 (silently dropped)

**Plans**: 4 plans (COMPLETE)

Plans:
- [x] 02-01-PLAN.md — FastAPI service scaffold: project structure, SQLAlchemy models, Alembic async migrations, Dockerfile, health endpoint
- [x] 02-02-PLAN.md — POST /events endpoint: Bearer auth, bot filtering middleware, rate limiting, CORS, BackgroundTasks DB write
- [x] 02-03-PLAN.md — VPS deployment: docker-compose service, nginx server block for api.dotsai.in, Let's Encrypt SSL (staging first)
- [x] 02-04-PLAN.md — Browser tracking snippet in public/index.html: page_view, session_start, window.dotsTrack(); CSP check on zeroonedotsai.consulting

---

### Phase 3: Cal.com at cal.dotsai.in — SKIPPED

**Status**: SKIPPED — Using Cal.com SaaS (cal.com/meetdeshani) with webhooks instead of self-hosting. Google Calendar already connected. Phase 4 receives webhooks directly from Cal.com SaaS.

---

### Phase 4: Cal.com Webhook Bridge to Analytics (SLIM)

**Goal**: Every Cal.com SaaS booking event (created, cancelled, rescheduled) is automatically recorded in analytics.bookings via HMAC-verified webhook at api.dotsai.in, within 5 seconds of the booking action.

**Depends on**: Phase 2 (FastAPI analytics service running at api.dotsai.in)

**Requirements**: REQ-02 (R02.3, R02.4), REQ-03 (R03.4), REQ-10 (R10.4)

**Success Criteria** (what must be TRUE when this phase completes):
1. Completing a test booking on cal.com/meetdeshani produces a row in `analytics.bookings` within 5 seconds — verified via `SELECT * FROM analytics.bookings ORDER BY id DESC LIMIT 1;`
2. Cancelling the test booking updates the same row's `status` field to `cancelled`
3. `POST /webhooks/calcom` with an invalid HMAC signature returns HTTP 403 — the endpoint is not publicly callable without the shared secret
4. The webhook URL in Cal.com admin shows `https://api.dotsai.in/webhooks/calcom`

**Plans**: 2 plans

Plans:
- [ ] 04-01-PLAN.md — Alembic migration for analytics.bookings table; POST /webhooks/calcom endpoint with HMAC-SHA256 verification; deploy to VPS
- [ ] 04-02-PLAN.md — Configure Cal.com SaaS webhook in admin; E2E test with real booking creation and cancellation

---

### Phase 5: Gateway Section + meet.dotsai.in

**Goal**: Visitors to dotsai.in can navigate to all three hub destinations from a branded gateway section, and meet.dotsai.in is live as a personal page linking directly to cal.com/meetdeshani for bookings. All pages fire analytics events. An E2E health script confirms all services are up.

**Depends on**: Phase 2 (analytics snippet and window.dotsTrack available), Phase 4 (gateway_click events flow into analytics)

**Requirements**: REQ-05 (R05.1–R05.7), REQ-07 (R07.1–R07.7), REQ-08 (R08.2, R08.3), REQ-10 (R10.1)

**Success Criteria** (what must be TRUE when this phase completes):
1. The gateway section renders in dotsai.in with three cards (dotsai.cloud, zeroonedotsai.consulting, meet.dotsai.in) — each is an `<a href>` element visible in page source with no JS required to render
2. Clicking a gateway card fires a `gateway_click` event visible in `analytics.events` within 30 seconds; tap targets measure ≥ 44px on mobile
3. `https://meet.dotsai.in` loads a page with name, photo, one-liner, short bio, and a "Book a Call" link pointing to `cal.com/meetdeshani`; the page fires a `page_view` event to the analytics API
4. `curl -I https://meet.dotsai.in` returns HTTP 200 with a valid SSL certificate and correct OpenGraph meta tags in the HTML
5. Running the E2E health check script returns `PASS` for all services: `api.dotsai.in/health`, `meet.dotsai.in`, dotsai.in gateway section links, and `docker ps` showing all containers healthy

**Plans**: 3 plans

Plans:
- [ ] 05-01: Gateway section in public/index.html — three destination cards, GSAP ScrollTrigger entrance, gateway_click events, >=44px tap targets
- [ ] 05-02: meet.dotsai.in — static HTML page, brand-consistent, OpenGraph tags, analytics snippet, nginx server block with SSL
- [ ] 05-03: E2E health check script validating all services; remove old cal.com/meetdeshani link from dotsai.in after verification

---

## Progress

**Execution Order:** 1 -> 2 -> ~~3~~ -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. VPS Pre-Flight + PostgreSQL Foundation | 3/3 | Complete | 2026-03-27 |
| 2. FastAPI Analytics API | 4/4 | Complete | 2026-03-28 |
| 3. Cal.com at cal.dotsai.in | - | SKIPPED | - |
| 4. Cal.com Webhook Bridge (SLIM) | 0/2 | Planned | - |
| 5. Gateway Section + meet.dotsai.in | 0/3 | Not started | - |

---

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-01 (R01.1-R01.5) -- PostgreSQL Foundation | Phase 1 | Complete |
| REQ-02 (R02.1-R02.6) -- Analytics Tables | Phase 2 (R02.1-R02.2, R02.4-R02.6), Phase 4 (R02.3) | Partial |
| REQ-03 (R03.1-R03.9) -- FastAPI Analytics API | Phase 2 (R03.1-R03.3, R03.5-R03.9), Phase 4 (R03.4) | Partial |
| REQ-04 (R04.1-R04.10) -- Cal.com | Phase 3 SKIPPED (using SaaS), Phase 4 (R04.7 webhook) | Partial |
| REQ-05 (R05.1-R05.7) -- Gateway Section | Phase 5 | Pending |
| REQ-06 (R06.1-R06.6) -- Browser Tracking Snippet | Phase 2 | Complete |
| REQ-07 (R07.1-R07.7) -- meet.dotsai.in Personal Page | Phase 5 | Pending |
| REQ-08 (R08.1-R08.6) -- nginx & Infrastructure | Phase 2 (R08.1-R08.5), Phase 1 (R08.6), Phase 5 (R08.2, R08.3) | Partial |
| REQ-09 (R09.1-R09.6) -- Security | Phase 1 (R09.4, R09.6), Phase 2 (R09.1-R09.3) | Partial |
| REQ-10 (R10.1-R10.5) -- Observability & Testing | Phase 2 (R10.3, R10.5), Phase 4 (R10.4), Phase 5 (R10.1) | Partial |

**Coverage: 10/10 requirement groups mapped. No orphaned requirements.**

---

*Created: 2026-03-27 | Updated: 2026-03-28 | Milestone 1 — Self-Hosted Hub v1*
