# PostgreSQL Schema And Ingestion Design

## Goal
Store first-party website traffic and behavior on your VPS in PostgreSQL with a schema that is:
- queryable,
- scalable enough for a growing marketing site,
- safe to retain,
- compatible with reporting and future app logic.

## Database recommendation
- Create a dedicated database such as `dotsai_analytics`.
- Use a dedicated schema such as `analytics`.
- Keep identified lead/contact data in a separate schema such as `crm` if possible.

## Core entities

### `visitor`
Represents an anonymous or later-identified browser/person.

### `session`
Represents a visit window, typically broken after 30 minutes of inactivity.

### `pageview`
Represents a page render or route view.

### `event`
Represents meaningful user behavior.

### `attribution_touch`
Represents source/medium/campaign and referrer data.

### `web_vital`
Represents field performance metrics.

### `js_error`
Represents browser runtime and request failures.

### `request_log`
Represents edge/server traffic.

### `consent_event`
Represents consent state changes.

### `contact_identity`
Represents explicit lead/contact identity after a form or booking.

## Schema design principles

### 1. Normalize hot dimensions
Normalize high-cardinality but reusable dimensions where practical:
- browser / OS / device
- geo
- attribution source

### 2. Keep event payloads in `jsonb`
Use explicit typed columns for common filter fields and `jsonb` for flexible detail.

### 3. Partition event-heavy tables by time
Partition:
- `request_log`
- `pageview`
- `event`
- `web_vital`
- `js_error`

Monthly range partitions are a good default.

### 4. Separate anonymous tracking from known identity
The same `visitor_id` can later map to a `contact_id`, but contact attributes should not be copied into every event row.

## Recommended tables

## `analytics.visitors`
Key fields:
- `visitor_id uuid primary key`
- `anonymous_id text unique`
- `first_seen_at timestamptz`
- `last_seen_at timestamptz`
- `first_touch_id bigint`
- `latest_touch_id bigint`
- `latest_geo_id bigint`
- `latest_user_agent_id bigint`
- `is_known boolean`
- `contact_id uuid null`
- `gpc boolean`
- `do_not_track boolean`
- `analytics_consent boolean`
- `marketing_consent boolean`
- `consent_updated_at timestamptz`

## `analytics.sessions`
Key fields:
- `session_id uuid primary key`
- `visitor_id uuid not null`
- `started_at timestamptz`
- `ended_at timestamptz`
- `last_activity_at timestamptz`
- `entry_pageview_id bigint`
- `exit_pageview_id bigint`
- `entry_path text`
- `exit_path text`
- `landing_touch_id bigint`
- `geo_id bigint`
- `user_agent_id bigint`
- `ip_hash text`
- `ip_trunc inet`
- `is_bot boolean`
- `bot_classification text`
- `pageviews_count integer`
- `events_count integer`
- `engaged_seconds integer`
- `is_bounce boolean`
- `converted boolean`

## `analytics.pageviews`
Suggested partition key:
- `occurred_at timestamptz`

Key fields:
- `pageview_id bigserial`
- `session_id uuid`
- `visitor_id uuid`
- `request_id text`
- `occurred_at timestamptz`
- `page_url text`
- `path text`
- `query_string text`
- `title text`
- `referrer_url text`
- `referrer_domain text`
- `route_name text`
- `status_code integer`
- `is_entry boolean`
- `is_exit boolean`
- `scroll_max_pct smallint`
- `time_on_page_ms integer`
- `viewport_w integer`
- `viewport_h integer`
- `screen_w integer`
- `screen_h integer`
- `payload jsonb`

## `analytics.events`
Suggested partition key:
- `occurred_at timestamptz`

Key fields:
- `event_id bigserial`
- `session_id uuid`
- `visitor_id uuid`
- `pageview_id bigint`
- `occurred_at timestamptz`
- `event_name text`
- `event_category text`
- `path text`
- `element_type text`
- `element_label text`
- `element_id text`
- `element_href text`
- `section_name text`
- `value_numeric numeric`
- `value_text text`
- `payload jsonb`

## `analytics.attribution_touches`
Key fields:
- `touch_id bigserial`
- `visitor_id uuid`
- `session_id uuid`
- `occurred_at timestamptz`
- `touch_role text`
- `landing_url text`
- `landing_path text`
- `referrer_url text`
- `referrer_domain text`
- `source text`
- `medium text`
- `campaign text`
- `term text`
- `content text`
- `gclid text`
- `gbraid text`
- `wbraid text`
- `fbclid text`
- `msclkid text`
- `payload jsonb`

## `analytics.web_vitals`
Suggested partition key:
- `measured_at timestamptz`

Key fields:
- `web_vital_id bigserial`
- `session_id uuid`
- `visitor_id uuid`
- `pageview_id bigint`
- `measured_at timestamptz`
- `path text`
- `metric_name text`
- `metric_value numeric`
- `metric_rating text`
- `navigation_type text`
- `payload jsonb`

## `analytics.js_errors`
Suggested partition key:
- `occurred_at timestamptz`

Key fields:
- `js_error_id bigserial`
- `session_id uuid`
- `visitor_id uuid`
- `pageview_id bigint`
- `occurred_at timestamptz`
- `path text`
- `message text`
- `source text`
- `line_no integer`
- `col_no integer`
- `stack text`
- `is_network_error boolean`
- `payload jsonb`

## `analytics.request_logs`
Suggested partition key:
- `requested_at timestamptz`

Key fields:
- `request_log_id bigserial`
- `request_id text`
- `requested_at timestamptz`
- `remote_addr inet`
- `ip_hash text`
- `host text`
- `method text`
- `scheme text`
- `path text`
- `query_string text`
- `status_code integer`
- `request_time_ms integer`
- `bytes_sent bigint`
- `referer text`
- `user_agent text`
- `accept_language text`
- `server_protocol text`
- `payload jsonb`

## `analytics.user_agents`
Key fields:
- `user_agent_id bigserial`
- `raw_user_agent text`
- `browser_name text`
- `browser_version text`
- `os_name text`
- `os_version text`
- `device_type text`
- `device_vendor text`
- `device_model text`
- `is_bot boolean`

## `analytics.geos`
Key fields:
- `geo_id bigserial`
- `country_code text`
- `country_name text`
- `region_name text`
- `city_name text`
- `timezone text`
- `asn text`
- `org_name text`
- `lat numeric`
- `lon numeric`

Store coarse data only if you want lower privacy risk.

## `analytics.consent_events`
Key fields:
- `consent_event_id bigserial`
- `visitor_id uuid`
- `session_id uuid`
- `occurred_at timestamptz`
- `consent_version text`
- `analytics_consent boolean`
- `marketing_consent boolean`
- `preferences_json jsonb`
- `source text`

## `crm.contact_identities`
Key fields:
- `contact_id uuid primary key`
- `visitor_id uuid`
- `created_at timestamptz`
- `email text`
- `phone text`
- `name text`
- `company text`
- `job_title text`
- `source_form text`
- `notes jsonb`

This table is intentionally separate.

## What to store as raw, hashed, or derived

### Store raw temporarily
- raw query string
- raw referrer URL
- raw user agent
- raw IP in request logs only if needed

### Store derived long-term
- referrer domain
- source / medium / campaign
- browser family
- device class
- country / city / ASN
- path and route

### Store hashed
- persistent first-party visitor token
- IP hash for abuse / dedupe analysis

## Ingestion path

## A. Edge log ingestion
NGINX -> JSON file -> parser -> PostgreSQL `request_logs`

Good choices:
- Vector
- Fluent Bit
- a small custom parser in Go/Node/Python

## B. Browser event ingestion
Page JS -> `POST /e` -> app service -> PostgreSQL

Recommended payload shape:

```json
{
  "visitor_id": "uuid",
  "session_id": "uuid",
  "pageview_id": "optional",
  "sent_at": "2026-03-26T08:15:00.000Z",
  "page": {
    "url": "https://dotsai.in/",
    "path": "/",
    "title": "AI Agency India | DotsAI"
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

## C. Enrichment jobs
Run background jobs to:
- parse UTM data,
- derive `referrer_domain`,
- map IP to geo and ASN,
- parse UA,
- roll up session counters,
- build daily aggregate tables.

## Query patterns you should optimize for
- traffic by source/medium/campaign
- conversion by landing page
- CTA click-through by section
- bounce and engagement by page
- performance by page and device
- top referrers
- top cities / states
- paid vs organic quality
- lead submissions by session and source

## Recommended indexes

### On `sessions`
- `(visitor_id, started_at desc)`
- `(started_at desc)`
- `(landing_touch_id)`

### On `pageviews`
- `(session_id, occurred_at)`
- `(path, occurred_at desc)`
- `(visitor_id, occurred_at desc)`

### On `events`
- `(event_name, occurred_at desc)`
- `(session_id, occurred_at)`
- `(path, event_name, occurred_at desc)`
- GIN on `payload`

### On `attribution_touches`
- `(visitor_id, occurred_at)`
- `(source, medium, campaign, occurred_at desc)`

## Operational rules

### Session timeout
- 30 minutes inactivity default

### Pageview creation
- first route load
- every route change in SPA
- optionally every significant soft navigation

### Scroll handling
- store milestones, not every pixel
- use `25/50/75/90`

### Click handling
- log only meaningful clicks
- nav, CTA, outbound, booking, WhatsApp, form submit

### Form handling
- log form start / submit / error
- do not log raw field values by default

## If you absolutely want “more data”
Add these only after you can justify them:
- replay metadata
- more detailed element interaction maps
- anonymous funnel timing
- error breadcrumbs

Still avoid:
- raw input values
- hidden field dumps
- unrestricted network payload capture

## Final recommendation
Use PostgreSQL as the system of record for:
- visitors,
- sessions,
- pageviews,
- events,
- attribution,
- vitals,
- errors,
- consent.

Keep the schema explicit enough for reporting, but flexible enough with `jsonb` to evolve.
