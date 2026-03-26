# Analytics Implementation Rollout

Prepared: March 26, 2026

## Goal
Turn the analytics research into a rollout sequence that can be implemented on your VPS without breaking the site or collecting data you cannot justify later.

## Recommended delivery order

### Step 1: create the database
- create a dedicated database such as `dotsai_analytics`
- apply `sql/analytics_schema.sql`
- create separate DB roles for:
  - ingestion
  - read-only analytics
  - admin / migrations

Do not let the public web app connect as a superuser.

## Step 2: add edge logging in NGINX
Use JSON access logs so you have a low-level source of truth for every request.

Example structure:

```nginx
log_format dotsai_json escape=json
  '{'
    '"request_id":"$request_id",'
    '"time":"$time_iso8601",'
    '"remote_addr":"$remote_addr",'
    '"x_forwarded_for":"$http_x_forwarded_for",'
    '"method":"$request_method",'
    '"scheme":"$scheme",'
    '"host":"$host",'
    '"uri":"$request_uri",'
    '"status":$status,'
    '"request_time":$request_time,'
    '"bytes_sent":$body_bytes_sent,'
    '"referer":"$http_referer",'
    '"user_agent":"$http_user_agent",'
    '"accept_language":"$http_accept_language",'
    '"protocol":"$server_protocol"'
  '}';

access_log /var/log/nginx/dotsai.analytics.json dotsai_json;
```

Important:
- make sure missing pages return real `404`, not soft-404 `200`
- scrub secrets from query strings before storing them long term
- rotate log files

## Step 3: add a first-party collector endpoint
Create an endpoint such as:
- `POST /e` for browser analytics events

Collector rules:
- accept only JSON
- set a tight max body size
- reject unknown origins
- rate-limit by IP and session
- attach a server-side receive timestamp
- write raw events into PostgreSQL quickly, then enrich asynchronously

## Step 4: issue IDs deliberately
Use:
- `visitor_id` as a long-lived first-party anonymous UUID
- `session_id` as a session-scoped UUID
- `pageview_id` as the server-generated row identity

Storage recommendation:
- `visitor_id` in a first-party cookie after consent model is applied
- `session_id` in session storage or a short-lived cookie

## Step 5: track only the events that matter
Start with:
- `page_view`
- `section_view`
- `cta_click`
- `outbound_click`
- `scroll_25`
- `scroll_50`
- `scroll_75`
- `scroll_90`
- `form_start`
- `form_submit`
- `form_submit_success`
- `form_submit_error`
- `calendly_open`
- `whatsapp_click`

Do not start with noisy event spam.

## Step 6: add field performance data
Capture:
- `LCP`
- `INP`
- `CLS`
- `FCP`
- `TTFB`

Store them in `analytics.web_vitals`.

These numbers matter for:
- conversion debugging
- page-level UX quality
- spotting regressions after the revamp

## Step 7: enrich in the background
After insert, run a worker to:
- parse the user agent
- derive device class
- derive referrer domain
- parse UTM values
- map IP to coarse geo and ASN
- classify likely bots
- update session rollups

Do not put enrichment logic in the browser.

## Step 8: identity stitching
Only when a visitor explicitly submits a form or booking request:
- create or update `crm.contact_identities`
- link that contact to `analytics.visitors.contact_id`

Rules:
- do not copy email and phone into every event row
- do not store raw form body dumps in analytics tables

## Step 9: consent handling
Use at least:
- essential
- analytics
- marketing

Implementation rules:
- analytics consent gates persistent analytics identifiers and optional replay
- marketing consent gates ad-related identifiers and remarketing use
- store every consent change in `analytics.consent_events`

## Step 10: retention and cleanup
Automate:
- partition creation
- old partition drops or archive
- raw log retention
- replay expiry if you enable replay later

Starting policy:
- request logs: 30 to 90 days
- raw event detail: 90 to 180 days
- aggregated reporting tables: long-term

## Suggested API contract
Use one compact event envelope:

```json
{
  "visitor_id": "e76baf02-ec5f-4d2f-8cff-7a4a7bde4a90",
  "session_id": "7c5c667f-315b-4a40-9546-5eeeb1dd97ae",
  "sent_at": "2026-03-26T09:14:00.000Z",
  "page": {
    "url": "https://dotsai.in/",
    "path": "/",
    "title": "Private AI Agency India | DotsAI"
  },
  "device": {
    "viewport_w": 1440,
    "viewport_h": 900,
    "screen_w": 1512,
    "screen_h": 982,
    "language": "en-IN"
  },
  "event": {
    "name": "cta_click",
    "category": "conversion",
    "section_name": "hero",
    "element_label": "Book Strategy Call",
    "payload": {
      "href": "/contact"
    }
  }
}
```

## Suggested rollout checkpoints

### Milestone A
- schema applied
- NGINX JSON logs enabled
- request log ingestion running

### Milestone B
- pageviews and key events reaching PostgreSQL
- session stitching working
- consent states stored

### Milestone C
- source/medium/campaign reporting
- geo/ASN enrichment
- lead attribution to form submissions

### Milestone D
- dashboards
- anomaly alerts
- optional replay with strict masking

## Practical recommendation for DotsAI
For this site, the best initial stack is:
- NGINX JSON access logs
- a lightweight first-party web collector
- PostgreSQL as the main analytics store
- a small enrichment worker
- simple dashboards on top of session, pageview, event, and attribution tables

That will give you most of the useful business signal without drifting into fragile surveillance-style tracking.
