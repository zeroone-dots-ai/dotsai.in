# Feature Landscape

**Domain:** Personal hub gateway + self-hosted scheduling + in-house visitor analytics
**Project:** dotsai.in milestone — gateway section, cal.dotsai.in, meet.dotsai.in, PostgreSQL analytics
**Researched:** 2026-03-27
**Overall confidence:** HIGH (Cal.com requirements verified against official .env.example and docs; gateway patterns verified against multiple UX sources; analytics schema patterns from established tools)

---

## Part A — Gateway Section (dotsai.in)

The gateway section is a block added to the existing `public/index.html` that routes visitors to the three right destinations. It is not a standalone page — it is a new section in the single-file site.

### Table Stakes — Gateway Section

Features visitors expect. Missing = gateway doesn't function as a gateway.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Three destination cards | One card per destination is the minimum routing unit | Low | dotsai.cloud (SaaS), zeroonedotsai.consulting (consulting), meet.dotsai.in (personal) |
| Clear card label + one-liner descriptor | Visitors scan in 2 seconds max; no label = confusion | Low | Each card needs: name + "what it is" in ≤ 8 words |
| Primary CTA per card | Every card must have a verb-first action label | Low | e.g., "Explore the platform", "Book consulting", "Meet Meet" |
| Mobile tap-target sizing | >90% of link-in-bio traffic is mobile; small buttons = dead conversions | Low | Minimum 44px tap target per card |
| Visual distinction between cards | Three destinations, three purposes — they must look different enough to choose | Low | Can use brand accent colors (plum, gold, lavender) per card |
| Scroll anchor from hero | Visitor needs a path from hero CTA to gateway section | Low | A "See where to go" anchor link in hero |
| Fast load / no extra HTTP requests | Gateway is in the critical path; it cannot slow the page | Low | Already static HTML — keep card content inline, no JS fetch |

### Table Stakes — Gateway Section (Continued)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Keyboard / screen-reader accessible cards | Cards that are `<div>` + `onclick` fail accessibility; cards that are `<a>` pass | Low | Use `<a href>` not JS click handlers |
| GSAP entrance animation consistent with rest of site | The rest of the site uses GSAP ScrollTrigger; gateway cards with no animation feel out of place | Low | Match existing `initMainPage()` scroll pattern |

### Differentiators — Gateway Section

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hover preview / micro-interaction per card | Signals interactivity before tap; premium feel consistent with quantum cursor | Low | Subtle border glow using D.O.T.S palette colors on hover |
| "Who should go here" label below card title | Reduces decision anxiety: "For clients who need ongoing AI systems" vs "For developers exploring the product" | Low | 1 sentence under CTA — highly effective for multi-destination gateways |
| Analytics click instrumentation on every card | Tells you which destination gets most traffic from dotsai.in | Low | Custom event `gateway_click` with `{destination: 'dotsai.cloud'}` — feeds in-house analytics |
| Current availability badge on consulting card | "Taking 2 clients — March 2026" on the consulting card creates urgency and social proof | Low | Static text, manually updated monthly |

### Anti-Features — Gateway Section

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Card grid in bento-box layout | Explicitly forbidden in CLAUDE.md; inconsistent with site aesthetic | Use vertical stack on mobile, horizontal row on desktop |
| Descriptions longer than 2 lines | Gateway must be scannable in 2 seconds; long copy makes visitors scroll away | One-liner descriptor maximum per card |
| Background images or heavy media per card | Slows load; conflicts with dark galaxy aesthetic already above it | Use CSS gradient fills using existing brand palette |
| Social proof logos / partner logos in gateway | This is a routing section, not a landing page — logos would confuse the purpose | Keep social proof in the existing Proof section above |
| Email capture form in gateway | Gateway's sole job is routing — adding email capture creates decision paralysis | Email capture belongs in a dedicated section or contact |
| Countdown timers or artificial scarcity | Inconsistent with "premium solopreneur" positioning | Use real availability signal only if accurate |

---

## Part B — Cal.com Self-Hosted (cal.dotsai.in)

### Minimum Required Config — Cal.com Self-Hosting

**CONFIDENCE: HIGH** — Verified against official `.env.example` at `github.com/calcom/cal.com/blob/main/.env.example` and official self-hosting docs.

#### Required Services

| Service | Required? | Notes |
|---------|-----------|-------|
| PostgreSQL | YES — required | Minimum v12.14; officially tested on v14 in Docker guides |
| SMTP / email | YES — functionally required | Booking confirmation emails won't send without it; Mailhog can substitute in dev |
| Redis | NO — not required for basic deployment | Only needed if using Cal.com API v2; not needed for standard booking |
| S3 / object storage | NO — optional | Only needed for Daily Video recording storage |
| Stripe | NO — optional | Only needed if charging for bookings |

#### Required Environment Variables (Minimum Viable Instance)

```bash
# Database
DATABASE_URL="postgresql://cal:calpass@db:5432/calcom"
DATABASE_DIRECT_URL="postgresql://cal:calpass@db:5432/calcom"   # for Prisma migrations

# Auth
NEXTAUTH_URL="https://cal.dotsai.in"
NEXTAUTH_SECRET="<openssl rand -base64 32>"

# Public URL
NEXT_PUBLIC_WEBAPP_URL="https://cal.dotsai.in"

# Encryption
CALENDSO_ENCRYPTION_KEY="<openssl rand -base64 24>"

# Email
EMAIL_FROM="meet@dotsai.in"
EMAIL_SERVER_HOST="smtp.example.com"
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER="smtp-user"
EMAIL_SERVER_PASSWORD="smtp-pass"
```

#### Optional but Recommended for Branded Setup

```bash
# Organizations (enables branded subdomain booking pages)
ORGANIZATIONS_ENABLED=1
NEXT_PUBLIC_WEBSITE_URL="https://dotsai.in"

# Disable Cal.com telemetry
NEXT_PUBLIC_TELEMETRY_KEY=""
```

**License key:** NOT required for self-hosted organizations. Official docs state to "ignore pricing information — not required for self-hosting." (MEDIUM confidence — verified against organization-setup docs page)

### Table Stakes — Cal.com Self-Hosted

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Booking page accessible at cal.dotsai.in | Primary purpose — visitors must reach booking from any device | Low | Nginx reverse proxy to Docker container port |
| Event type: "30-min AI consultation" | At minimum one bookable event type configured | Low | Create via Cal.com admin UI after deploy |
| Email confirmation to guest | Standard scheduling expectation — without it the booking feels broken | Low | Requires SMTP — see config above |
| Email notification to Meet | Meet needs to know when someone books | Low | Configured in Cal.com event type settings |
| Calendar integration (Google or iCal) | Prevents double-booking; Meet already uses Google Calendar | Medium | Google Calendar OAuth app setup required in Google Cloud Console |
| Custom domain (not cal.com/meetdeshani) | Branded experience; positions Meet as owning infrastructure | Low | Nginx virtualhost: `cal.dotsai.in` → container |
| Mobile-responsive booking page | Cal.com is responsive by default; no extra work needed | Low | Verify after deploy on mobile viewport |
| Webhook to analytics on BOOKING_CREATED | Every booking must flow into in-house analytics DB | Medium | Cal.com webhook → POST to analytics ingest endpoint |

### Table Stakes — Cal.com Self-Hosted (Continued)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| SSL/TLS at cal.dotsai.in | Required for cal.dotsai.in to work with OAuth and browser security | Low | Let's Encrypt via Certbot or Nginx Proxy Manager |
| BOOKING_CREATED webhook payload captured | Core analytics requirement — captures: attendee name, email, event type, start_time, uid | Medium | See BOOKING_CREATED payload fields below |

### Differentiators — Cal.com Self-Hosted

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Custom booking page branding | Dark background + ZeroOne logo at top of booking page matches dotsai.in aesthetic | Medium | Cal.com supports custom CSS and logo upload in org settings |
| Pre-booking question: "What are you hoping to solve?" | Qualifies leads before the call; saves Meet 5 min of context-gathering | Low | Add custom input in Cal.com event type settings |
| Buffer time between meetings | Prevents back-to-back bookings; forces intentional scheduling | Low | Cal.com event type setting: 15 min buffer |
| Minimum notice period (24h) | Prevents same-day surprise bookings | Low | Cal.com event type setting |
| "How did you hear about us?" pre-booking field | Maps referral source to booking — feeds analytics attribution | Low | Custom input field in event type |

### Anti-Features — Cal.com Self-Hosted

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Multiple event types in v1 | Adds complexity before you know what converts; start with one | One 30-min "AI consultation" type only |
| Payments/Stripe integration in v1 | Adds Stripe OAuth complexity; discovery calls should be free | Add later once booking flow is proven |
| Team scheduling / round-robin | Meet is a solopreneur; team features add configuration overhead | Skip entirely — single-user setup |
| Group bookings / webinar bookings | Not the use case; adds seatsPerTimeSlot complexity | Defer; Cal.com supports this but not needed now |
| Cal.com API v2 | Requires Redis and a license key; not needed for basic booking | Use standard Cal.com booking only |
| Embeds in multiple pages | Complicates analytics (which page did they book from?); hard to track | Single canonical booking URL at cal.dotsai.in |

### BOOKING_CREATED Webhook Payload — Fields to Capture

**CONFIDENCE: HIGH** — Verified against official Cal.com webhook docs.

```
triggerEvent          → "BOOKING_CREATED"
payload.uid           → unique booking ID (store as primary key)
payload.type          → event type slug (e.g., "30min-ai-consultation")
payload.title         → full booking title
payload.startTime     → ISO timestamp
payload.endTime       → ISO timestamp
payload.attendees[0].name      → guest name
payload.attendees[0].email     → guest email
payload.attendees[0].timeZone  → guest timezone
payload.organizer.email        → always meet@dotsai.in — confirms it's our instance
payload.responses.notes        → pre-booking notes
payload.responses.*            → all custom input responses
payload.location               → meeting location / video link
```

---

## Part C — In-House PostgreSQL Analytics

The analytics system must answer: who is visiting, where do they click, which destination gets most traffic, how many bookings come from which source.

### Table Stakes — Analytics Events to Capture

**Every event must be captured. "Capture everything, query later" is the right approach for a solo operator.**

#### Core Event Types (minimum viable)

| Event Name | Trigger | Required Fields |
|------------|---------|-----------------|
| `page_view` | Every page load on dotsai.in, meet.dotsai.in | `session_id`, `page_url`, `page_path`, `referrer`, `timestamp`, `user_agent`, `ip_hash`, `country`, `device_type` |
| `gateway_click` | Click on any gateway destination card | `session_id`, `destination` (dotsai.cloud/zeroonedotsai.consulting/meet.dotsai.in), `timestamp`, `page_url` |
| `cta_click` | Click on WhatsApp CTA, Cal.com CTA, any button | `session_id`, `cta_label`, `cta_destination`, `section` (hero/contact/gateway), `timestamp` |
| `booking_created` | Cal.com webhook fires BOOKING_CREATED | `booking_uid`, `event_type`, `start_time`, `attendee_email_hash`, `source_referrer`, `timestamp` |
| `session_start` | First event in a new session | `session_id`, `ip_hash`, `country`, `city`, `device_type`, `browser`, `os`, `referrer`, `utm_source`, `utm_medium`, `utm_campaign`, `timestamp` |

#### Optional but High-Value Events

| Event Name | Trigger | Why Valuable |
|------------|---------|--------------|
| `scroll_depth` | User scrolls past 25%, 50%, 75%, 100% of page | Shows where people drop off |
| `section_visible` | Each section enters viewport | Identifies which sections are actually seen |
| `splash_skipped` | User clicks SKIP on splash | Signals returning vs first-time visitors |
| `cal_page_view` | Page view on cal.dotsai.in | Measures booking funnel entry |

### Table Stakes — PostgreSQL Schema (Minimum)

```sql
-- Sessions: one row per browser session
CREATE TABLE sessions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_hash      TEXT,           -- SHA-256 of IP (never store raw IP)
  country      TEXT,
  city         TEXT,
  device_type  TEXT,           -- desktop | mobile | tablet
  browser      TEXT,
  os           TEXT,
  referrer     TEXT,
  utm_source   TEXT,
  utm_medium   TEXT,
  utm_campaign TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Events: one row per tracked action
CREATE TABLE events (
  id          BIGSERIAL PRIMARY KEY,
  session_id  UUID REFERENCES sessions(id),
  event_name  TEXT NOT NULL,     -- page_view | gateway_click | cta_click | booking_created
  page_url    TEXT,
  properties  JSONB,             -- all extra fields; JSONB allows flexible querying
  timestamp   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON events(session_id);
CREATE INDEX ON events(event_name);
CREATE INDEX ON events(timestamp);

-- Bookings: one row per confirmed booking (from Cal.com webhook)
CREATE TABLE bookings (
  id                  UUID PRIMARY KEY,     -- Cal.com booking uid
  event_type          TEXT,
  start_time          TIMESTAMPTZ,
  attendee_email_hash TEXT,                  -- SHA-256, never raw email
  source_referrer     TEXT,
  raw_payload         JSONB,                 -- full webhook payload for replay
  created_at          TIMESTAMPTZ DEFAULT NOW()
);
```

**Design rationale:** `properties JSONB` on the events table means no migration is needed to add new event fields — just put new keys in the JSON. Querying JSONB is fast enough at the scale of a personal site (< 100K events/month).

### Table Stakes — Analytics Ingest Endpoint

| Requirement | Detail |
|-------------|--------|
| Ingest endpoint | `POST /api/track` — accepts events from browser JS snippet |
| Lightweight browser snippet | < 2 KB inline JS; fires `page_view` on load, `cta_click` on button clicks, `gateway_click` on card clicks |
| IP anonymization | SHA-256 hash of IP before storage — never store raw IP (GDPR/privacy baseline) |
| Geolocation lookup | Country + city from IP before hashing — use MaxMind GeoLite2 (free, local DB, no API call) |
| Webhook receiver | `POST /api/webhooks/cal` — receives Cal.com BOOKING_CREATED and writes to `bookings` table |
| No third-party calls | All data stays on VPS — no Google Analytics, no Plausible, no external service |

### Differentiators — Analytics

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Simple dashboard (read-only) | Single HTML page showing: total visitors today/week/month, top referrers, gateway click rates, booking count | Medium | Can be a password-protected static page reading from PostgreSQL via a simple API endpoint |
| UTM attribution on bookings | Match `utm_source` from session to bookings — shows which channel drives actual meetings | Low | Join `sessions` to `bookings` on session_id stored in Cal.com referrer field |
| Bot filtering | Exclude known bot user-agents from page_view counts — gives accurate human traffic | Low | Blocklist of 20–30 common bot UA strings in ingest endpoint |
| Daily email digest | Email Meet a daily summary: X visitors, X gateway clicks, X bookings | Medium | Cron job + SMTP; requires no dashboard UI |

### Anti-Features — Analytics

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Google Analytics / GA4 | Sends data to Google; contradicts "own your data" goal; blocked by ad-blockers | Custom ingest only |
| Plausible or Umami as a layer on top | Adds another service to maintain; redundant with custom analytics | Build lean custom system |
| Real-time dashboard in v1 | Engineering complexity with no immediate ROI at personal site scale | Daily aggregate queries are sufficient |
| Heatmaps / session replay (Hotjar-style) | Expensive to store; privacy-invasive; overkill for this use case | Scroll depth events are sufficient proxy |
| Raw IP storage | GDPR risk; unnecessary if country + city are extracted first | Always hash IPs |
| User accounts / login wall on analytics | Solo operator; a simple read-only secret URL is sufficient | One-page password-protected dashboard |

---

## Part D — meet.dotsai.in Personal Page

### Table Stakes — Personal Page

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Name, photo, one-liner headline | The absolute minimum for a personal page — who you are in 3 seconds | Low | "Meet Deshani — AI systems for businesses that want to own their AI" |
| Primary CTA: Book a call | Converts visitors into bookings; links to cal.dotsai.in | Low | WhatsApp + Cal.com buttons — same pattern as dotsai.in contact section |
| Short bio (3–5 sentences) | Establishes credibility; answers "why should I listen to you?" | Low | Focus on: what Meet builds, who for, outcome achieved |
| Link back to dotsai.in | Keeps navigation coherent between the pages | Low | "Back to dotsai.in" link in header or footer |
| Social proof — 1–2 results | "Built systems saving 8L/yr per client" — minimum proof needed before CTA | Low | Pull from existing Proof section on dotsai.in |
| Mobile-responsive layout | >60% personal page traffic is mobile | Low | Use existing CSS variables from dotsai.in brand system |
| page_view analytics tracking | Must fire analytics event on load — same snippet as dotsai.in | Low | Include same `<script>` tracking snippet |

### Differentiators — Personal Page

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Consistent visual identity with dotsai.in | Plum + cream + Instrument Serif signals it's the same person/brand | Low | Copy CSS variables from index.html |
| "Currently working on" section | Makes the page feel alive and updated; builds trust | Low | One sentence, manually updated monthly |
| Embedded Cal.com widget or direct link | Zero-friction booking from the personal page itself | Low | Use direct link to cal.dotsai.in rather than embed (simpler, tracked better) |
| OpenGraph meta tags (og:image, og:title, og:description) | When shared on WhatsApp/LinkedIn, shows a rich preview instead of blank | Low | Essential for a personal page that gets shared directly |

### Anti-Features — Personal Page

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Long list of skills / tech stack | Nobody reads it; makes page feel like a resume not a business page | 2–3 categories maximum: AI agents, web systems, data |
| Contact form | CLAUDE.md explicitly forbids forms; direct WhatsApp/Cal only | WhatsApp link + Cal.com link |
| Blog or article listing | Adds content maintenance burden; out of scope for v1 | Defer to v2 if needed |
| Social media feed embed | Slow, breaks design consistency, adds external JS dependencies | Link to socials in footer if needed |
| Testimonial carousel | Complex JS, often feels fake; static 1–2 quotes are more credible | 1 static quote with attribution |

---

## Feature Dependencies

```
Analytics ingest endpoint (POST /api/track)
    → Required by: gateway_click event, page_view events, cta_click events

Cal.com webhook receiver (POST /api/webhooks/cal)
    → Required by: booking_created analytics event

Cal.com self-hosted instance (cal.dotsai.in)
    → Required by: booking CTA on dotsai.in, booking CTA on meet.dotsai.in
    → Required by: Cal.com webhook receiver

PostgreSQL database on VPS
    → Required by: analytics ingest endpoint, webhook receiver, bookings table

Gateway section in index.html
    → Required by: gateway_click analytics event
    → Requires: three destination URLs to exist (dotsai.cloud is live, zeroonedotsai.consulting needs verification, meet.dotsai.in needs to be built)

meet.dotsai.in
    → Required by: gateway section (destination card #3)
    → Requires: Nginx virtualhost for meet.dotsai.in
```

---

## MVP Recommendation

**Phase order forced by dependencies:**

1. **PostgreSQL analytics schema + ingest endpoint** — no other milestone can track events without this; build first, instrument everything else on top
2. **Cal.com self-hosted at cal.dotsai.in** — booking CTA exists on the site now; replace cal.com/meetdeshani with owned infrastructure; configure BOOKING_CREATED webhook to analytics
3. **Gateway section in index.html** — add section above Contact; three destination cards; instrument gateway_click; requires meet.dotsai.in URL to exist (can use placeholder during build)
4. **meet.dotsai.in personal page** — final destination that gateway card #3 points to; lighter build; add analytics snippet

**Defer to v2:**
- Dashboard UI for analytics — plain SQL queries in psql are sufficient to read data in v1
- Payments / Stripe on Cal.com — add after booking flow is validated
- Multiple Cal.com event types — one type proves the flow first
- Blog on meet.dotsai.in — content maintenance is a separate project

---

## Quality Gate Checklist

- [x] Cal.com minimum required config documented (verified against official .env.example)
- [x] Analytics events listed specifically — `page_view`, `gateway_click`, `cta_click`, `booking_created`, `session_start` with exact field lists
- [x] Gateway UX patterns from best personal hub sites noted — 2-second scan rule, verb-first CTAs, 3 destinations max above fold, mobile tap targets

---

## Sources

| Source | Confidence | Used For |
|--------|------------|----------|
| [Cal.com official .env.example](https://github.com/calcom/cal.com/blob/main/.env.example) | HIGH | Required env vars, Redis/S3 not required |
| [Cal.com Docker docs](https://cal.com/docs/self-hosting/docker) | HIGH | Minimum services: PostgreSQL + SMTP |
| [Cal.com Organization Setup docs](https://cal.com/docs/self-hosting/guides/organization/organization-setup) | HIGH | ORGANIZATIONS_ENABLED, no license key needed |
| [Cal.com Webhook docs](https://cal.com/docs/developing/guides/automation/webhooks) | HIGH | BOOKING_CREATED payload fields |
| [Self-hosted Cal.com on Ubuntu guide — DEV Community](https://dev.to/therealfloatdev/how-to-self-host-calcom-on-ubuntu-with-monitoring-1ph9) | MEDIUM | Deployment steps, monitoring importance |
| [Link-in-Bio Best Practices 2025 — Mingly](https://mingly.link/blog/link-in-bio-2025) | MEDIUM | Above-fold patterns, 3-destination max, verb-first labels |
| [Link-in-Bio Optimization Guide — BITHUB](https://the-bithub.com/blog/link-in-bio-optimization-guide-2025) | MEDIUM | CTA conversion patterns, mobile-first requirements |
| [Above the Fold Best Practices 2025 — Evergreen DM](https://evergreendm.com/above-the-fold-what-should-actually-be-there-in-2025/) | MEDIUM | Gateway hero content rules |
| [Best Self-Hosted Web Analytics 2026 — OpenPanel](https://openpanel.dev/articles/self-hosted-web-analytics) | MEDIUM | Analytics feature landscape, event types |
| [Event Analytics: User Sessions with SQL — DZone](https://dzone.com/articles/event-analytics-how-to-define-user-sessions-with-s) | MEDIUM | Session + event table design patterns |
| [Analytics Schema Guide — BuildWithStudio](https://buildwithstudio.com/knowledge/guide-to-laying-out-an-analytics-schema/) | MEDIUM | Schema structure for events + sessions |
