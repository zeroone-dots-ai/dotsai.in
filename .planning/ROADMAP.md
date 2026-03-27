# Roadmap: dotsai.in — Self-Hosted Hub

## Overview

Milestone 1 transforms dotsai.in from a standalone static site into a fully self-hosted hub: PostgreSQL analytics foundation on the VPS, a FastAPI event-ingest API at api.dotsai.in, a self-hosted Cal.com booking system at cal.dotsai.in, a webhook bridge connecting bookings to analytics, and a gateway section plus meet.dotsai.in personal page that tie all services together. Every visitor interaction and booking is owned entirely by Meet — zero third-party analytics dependency.

## Milestone

**Milestone 1 — Self-Hosted Hub v1**

## Phases

- [ ] **Phase 1: VPS Pre-Flight + PostgreSQL Foundation** - Provision the database layer; nothing else can start without it
- [ ] **Phase 2: FastAPI Analytics API** - Self-contained analytics ingest service, proves Docker networking before Cal.com
- [ ] **Phase 3: Cal.com at cal.dotsai.in** - Self-hosted scheduling replacing the SaaS cal.com/meetdeshani dependency
- [ ] **Phase 4: Cal.com Webhook Bridge to Analytics** - Wire booking events into PostgreSQL via internal Docker network
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

**Plans**: TBD

Plans:
- [ ] 01-01: VPS RAM audit, swap configuration, and Docker Compose scaffold with postgres:17 service
- [ ] 01-02: Schema initialisation, healthcheck verification, and pg_dump backup cron setup

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

**Plans**: TBD

Plans:
- [ ] 02-01: FastAPI service scaffold — Dockerfile, docker-compose service, Alembic migrations for analytics.visitors and analytics.events
- [ ] 02-02: POST /events endpoint — Bearer auth, BackgroundTasks DB write, slowapi rate limiting, bot filtering middleware
- [ ] 02-03: nginx server block for api.dotsai.in — SSL via Let's Encrypt (staging first), resolver directive, CORS via FastAPI only
- [ ] 02-04: Browser tracking snippet in public/index.html — page_view, session_start, window.dotsTrack(); add snippet to zeroonedotsai.consulting

---

### Phase 3: Cal.com at cal.dotsai.in

**Goal**: Self-hosted Cal.com is live at cal.dotsai.in with SSL, one configured event type, working email confirmations, and Google Calendar connected. A test booking completes end-to-end before the existing cal.com/meetdeshani link is removed.

**Depends on**: Phase 1 (PostgreSQL calcom schema must be healthy), Phase 2 (nginx patterns proven)

**Requirements**: REQ-04 (R04.1–R04.10), REQ-08 (R08.1–R08.4, R08.6), REQ-09 (R09.1, R09.3, R09.4, R09.5), REQ-10 (R10.2, R10.5)

**Success Criteria** (what must be TRUE when this phase completes):
1. `https://cal.dotsai.in` loads the Cal.com booking page in under 3 seconds and all links on the page point to `cal.dotsai.in` — none point to `localhost:3000` (verified via `docker exec calcom env | grep WEBAPP_URL`)
2. A test booking for "30-min AI Consultation" completes: the attendee receives an email confirmation and Meet receives a notification email within 2 minutes
3. Google Calendar shows the test booking in Meet's calendar, preventing double-booking
4. `docker inspect calcom` shows the container connects to the shared PostgreSQL service with `?schema=calcom` in the connection string — no separate database container
5. `docker ps` shows the calcom container with `restart: always` policy and `running` status after a `docker restart calcom`

**Plans**: TBD

Plans:
- [ ] 03-01: Build Cal.com Docker image with NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in; add service to docker-compose connecting to calcom schema
- [ ] 03-02: nginx server block for cal.dotsai.in with SSL; verify WEBAPP_URL immediately after first start
- [ ] 03-03: Configure event type, Google Calendar integration, and SMTP via Resend; run E2E test booking

---

### Phase 4: Cal.com Webhook Bridge to Analytics

**Goal**: Every Cal.com booking event (created, cancelled, rescheduled) is automatically recorded in analytics.bookings via the internal Docker network — no public internet hop, HMAC-verified, within 5 seconds of the booking action.

**Depends on**: Phase 2 (FastAPI analytics service running), Phase 3 (Cal.com running and booking flow verified)

**Requirements**: REQ-02 (R02.3, R02.4), REQ-03 (R03.4), REQ-04 (R04.7), REQ-10 (R10.4)

**Success Criteria** (what must be TRUE when this phase completes):
1. Completing a test booking on cal.dotsai.in produces a row in `analytics.bookings` within 5 seconds — verified via `SELECT * FROM analytics.bookings ORDER BY id DESC LIMIT 1;`
2. Cancelling the test booking updates the same row's `status` field to `cancelled`
3. `POST /webhooks/calcom` with an invalid HMAC signature returns HTTP 403 — the endpoint is not publicly callable without the shared secret
4. The webhook URL in Cal.com admin shows `http://analytics:8000/webhooks/calcom` (internal network) — not the public `api.dotsai.in` URL

**Plans**: TBD

Plans:
- [ ] 04-01: Alembic migration for analytics.bookings table; POST /webhooks/calcom endpoint with HMAC-SHA256 verification
- [ ] 04-02: Configure Cal.com webhook in admin UI; test BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED events end-to-end

---

### Phase 5: Gateway Section + meet.dotsai.in

**Goal**: Visitors to dotsai.in can navigate to all three hub destinations from a branded gateway section, and meet.dotsai.in is live as a personal page linking directly to cal.dotsai.in for bookings. All pages fire analytics events. An E2E health script confirms all five services are up.

**Depends on**: Phase 2 (analytics snippet and window.dotsTrack available), Phase 3 (cal.dotsai.in live for Book a Call CTA), Phase 4 (gateway_click events flow into analytics)

**Requirements**: REQ-05 (R05.1–R05.7), REQ-07 (R07.1–R07.7), REQ-08 (R08.2, R08.3), REQ-10 (R10.1)

**Success Criteria** (what must be TRUE when this phase completes):
1. The gateway section renders in dotsai.in with three cards (dotsai.cloud, zeroonedotsai.consulting, meet.dotsai.in) — each is an `<a href>` element visible in page source with no JS required to render
2. Clicking a gateway card fires a `gateway_click` event visible in `analytics.events` within 30 seconds; tap targets measure ≥ 44px on mobile
3. `https://meet.dotsai.in` loads a page with name, photo, one-liner, short bio, and a "Book a Call" link pointing to `cal.dotsai.in`; the page fires a `page_view` event to the analytics API
4. `curl -I https://meet.dotsai.in` returns HTTP 200 with a valid SSL certificate and correct OpenGraph meta tags in the HTML
5. Running the E2E health check script returns `PASS` for all five services: `api.dotsai.in/health`, `cal.dotsai.in`, `meet.dotsai.in`, dotsai.in gateway section links, and `docker ps` showing all containers healthy

**Plans**: TBD

Plans:
- [ ] 05-01: Gateway section in public/index.html — three destination cards, GSAP ScrollTrigger entrance, gateway_click events, ≥44px tap targets
- [ ] 05-02: meet.dotsai.in — static HTML page, brand-consistent, OpenGraph tags, analytics snippet, nginx server block with SSL
- [ ] 05-03: E2E health check script validating all five services; remove old cal.com/meetdeshani link from dotsai.in after verification

---

## Progress

**Execution Order:** 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. VPS Pre-Flight + PostgreSQL Foundation | 0/2 | Not started | - |
| 2. FastAPI Analytics API | 0/4 | Not started | - |
| 3. Cal.com at cal.dotsai.in | 0/3 | Not started | - |
| 4. Cal.com Webhook Bridge to Analytics | 0/2 | Not started | - |
| 5. Gateway Section + meet.dotsai.in | 0/3 | Not started | - |

---

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-01 (R01.1–R01.5) — PostgreSQL Foundation | Phase 1 | Pending |
| REQ-02 (R02.1–R02.6) — Analytics Tables | Phase 2 (R02.1–R02.2, R02.4–R02.6), Phase 4 (R02.3) | Pending |
| REQ-03 (R03.1–R03.9) — FastAPI Analytics API | Phase 2 (R03.1–R03.3, R03.5–R03.9), Phase 4 (R03.4) | Pending |
| REQ-04 (R04.1–R04.10) — Cal.com at cal.dotsai.in | Phase 3 (R04.1–R04.6, R04.8–R04.10), Phase 4 (R04.7) | Pending |
| REQ-05 (R05.1–R05.7) — Gateway Section | Phase 5 | Pending |
| REQ-06 (R06.1–R06.6) — Browser Tracking Snippet | Phase 2 | Pending |
| REQ-07 (R07.1–R07.7) — meet.dotsai.in Personal Page | Phase 5 | Pending |
| REQ-08 (R08.1–R08.6) — nginx & Infrastructure | Phase 2 (R08.1–R08.5), Phase 1 (R08.6), Phase 5 (R08.2, R08.3) | Pending |
| REQ-09 (R09.1–R09.6) — Security | Phase 1 (R09.4, R09.6), Phase 2 (R09.1–R09.3), Phase 3 (R09.5) | Pending |
| REQ-10 (R10.1–R10.5) — Observability & Testing | Phase 2 (R10.3, R10.5), Phase 3 (R10.2, R10.5), Phase 4 (R10.4), Phase 5 (R10.1) | Pending |

**Coverage: 10/10 requirement groups mapped. No orphaned requirements.**

---

*Created: 2026-03-27 | Milestone 1 — Self-Hosted Hub v1*
