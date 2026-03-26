# First-Party Analytics On VPS

Prepared: March 26, 2026

## Scope
This document covers how to log detailed website traffic and behavioral data into your own VPS-hosted PostgreSQL database.

It does **not** recommend covert fingerprinting, hidden PII collection, or recording sensitive user input without clear notice and a lawful basis.

## Bottom line
If you want serious visibility into website traffic on your own infrastructure, the correct architecture is:

1. edge request logging,
2. first-party event collection,
3. consent-aware enrichment,
4. PostgreSQL storage with partitioned event tables,
5. strict retention and scrubbing rules.

That gives you most of the useful signal:
- where visitors came from,
- what pages they saw,
- what they clicked,
- how far they scrolled,
- how long they stayed,
- what converted,
- which devices and browsers they used,
- how the site performed,
- which campaigns and referrers produced revenue.

## Important boundary
“Everything single scrappable detail of the person” is the wrong design objective.

The useful objective is:
- capture business-relevant interaction and attribution data,
- avoid collecting more personal data than you can justify, secure, explain, and erase.

## Legal and platform constraints

### India
The Digital Personal Data Protection Act, 2023 is official law dated August 11, 2023. The official PDF states personal data should be processed only for a lawful purpose with consent or certain legitimate uses, and the notice must describe the personal data and purpose.

The official DPDP Rules, 2025 PDF published November 13, 2025 adds practical requirements around:
- clear and plain notice,
- reasonable security safeguards,
- logging and monitoring,
- breach response,
- retention and erasure.

Important implementation consequence:
- if you collect identifiable visitor data, your notice and consent flows must describe it,
- you need security controls and logs,
- you should not retain raw identifiable data indefinitely.

### If you serve EU/UK visitors
Treat non-essential analytics and replay as consent-gated.

This matters especially for:
- analytics cookies,
- replay cookies,
- ad click IDs,
- personalized retargeting,
- any third-party data sharing.

## Data categories

### Safe and useful by default
- request timestamp
- request path
- response status
- page title
- referrer
- UTM parameters
- device type
- browser family and version
- OS family and version
- language
- viewport size
- coarse geo
- performance metrics
- clicks on key CTAs
- scroll milestones
- form submit success/failure
- JS errors

### Only after clear consent or explicit user action
- full email / phone
- session replay
- form field values
- CRM identity stitching
- ad click identifiers used for remarketing
- persistent cross-session tracking beyond necessary analytics

### Do not collect unless you have a very specific, defensible reason
- passwords
- OTPs
- payment card numbers
- Aadhaar or government IDs
- clipboard contents
- hidden input values
- full keystroke streams
- raw request bodies for forms
- precise geolocation
- invasive fingerprinting from canvas/audio/WebGL/fonts/plugins

## Recommended system architecture

## Layer 1: edge logging
Use NGINX access logs in JSON format as your lowest-level traffic source.

This gives you:
- every request,
- status codes,
- bytes,
- request timings,
- referer,
- user agent,
- request IDs,
- host/path/query.

Use edge logs for:
- crawl and bot analysis,
- uptime and route debugging,
- 404/500 analysis,
- feed into traffic baselines.

Do not treat edge logs alone as product analytics. They do not know scroll, clicks, engagement, or conversions.

### Example fields to log at the edge
- `$request_id`
- `$time_iso8601`
- `$remote_addr`
- `$request_method`
- `$scheme`
- `$host`
- `$request_uri`
- `$status`
- `$request_time`
- `$body_bytes_sent`
- `$http_referer`
- `$http_user_agent`
- `$http_accept_language`
- `$http_x_forwarded_for`
- `$server_protocol`

## Layer 2: first-party browser event collector
Add a lightweight JS SDK hosted from your own domain.

This collector should send events to a first-party endpoint like:
- `POST https://dotsai.in/e`

Use `navigator.sendBeacon()` for unload-safe event delivery and `fetch(..., {keepalive:true})` for larger payloads.

## Layer 3: enrichment worker
Enrich raw requests/events into dimensions:
- parsed UA
- bot classification
- geo lookup
- ASN / ISP
- referrer domain
- campaign parsing
- session stitching

Best practice:
- derive these fields early,
- avoid long-term storage of raw IP where possible,
- store a hashed IP and/or truncated IP for abuse and uniqueness analysis.

## Layer 4: PostgreSQL
Use PostgreSQL for:
- dimensions,
- sessions,
- pageviews,
- events,
- conversions,
- consent records,
- web vitals,
- errors.

For low to moderate traffic this is enough.

If you later hit high event volume, keep PostgreSQL for business entities and add a dedicated event/log store.

## What to capture

## Request-level capture
Collected at the server or edge:
- request ID
- timestamp
- host
- method
- path
- raw query string
- status code
- bytes sent
- request time
- referer header
- user-agent header
- accept-language header
- IP address or proxy-derived client IP
- TLS / protocol info

## Session-level capture
Derived from pageviews/events:
- session ID
- visitor ID
- start time
- end time
- session duration
- entry page
- exit page
- bounce flag
- engaged flag
- engaged time
- total pageviews
- total key events
- conversion flag

## Visitor-level capture
First-party only:
- anonymous visitor ID
- first seen / last seen
- first landing attribution
- latest device class
- latest geo
- consent state
- optional link to a known lead/contact after explicit submission

## Attribution capture
On landing and on every session:
- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`
- referrer URL
- referrer domain
- click IDs if you use ads:
  - `gclid`
  - `gbraid`
  - `wbraid`
  - `fbclid`
  - `msclkid`

Important:
- store the raw values only if you actually use them,
- avoid letting query strings with tokens or secrets flow through unsanitized.

## Behavioral capture
Use explicit event names, not arbitrary DOM dumps.

Recommended events:
- `page_view`
- `cta_click`
- `nav_click`
- `section_view`
- `scroll_25`
- `scroll_50`
- `scroll_75`
- `scroll_90`
- `form_start`
- `form_submit`
- `form_submit_success`
- `form_submit_error`
- `outbound_click`
- `video_start`
- `video_progress`
- `video_complete`
- `calendly_open`
- `whatsapp_click`
- `copy_email`

## UX/performance capture
Collect field performance, not just lab data:
- LCP
- INP
- CLS
- TTFB
- FCP
- navigation timing summary
- JS errors
- failed network requests

## Device/network capture
Use privacy-coarsened signals only:
- browser brand/version
- OS brand/version
- mobile/tablet/desktop
- viewport width/height
- screen width/height
- DPR
- preferred languages
- device memory if available
- hardware concurrency if available
- connection effective type / downlink / RTT if available
- reduced-motion preference
- dark/light preference

Do not use these to build an invasive fingerprint.

## Identity stitching

### Anonymous first
Start every visitor as anonymous.

### Promote to known user only on explicit action
When a visitor submits:
- contact form,
- lead form,
- calendar booking,
- email signup,

you can link `visitor_id -> contact_id`.

### Keep identity data separate
Do not scatter emails and phone numbers across pageview/event rows.
Store identified contacts in a separate table or separate schema.

## Consent model

Use at least three categories:
- essential
- analytics
- marketing

Recommended rules:
- essential is always on
- analytics gates persistent analytics cookies and replay
- marketing gates ad-related IDs and retargeting

Also record:
- `navigator.globalPrivacyControl` if available
- consent version
- consent timestamp

## Session replay

## Recommendation
Treat replay as optional and gated.

Replay is useful for:
- conversion debugging,
- UX debugging,
- form friction analysis,
- animation or layout issues.

Replay is risky because it can capture more than you intended.

### If you enable replay
- mask text by default
- mask all inputs by default
- exclude auth/account/billing/admin routes
- never capture payment or identity verification flows
- do not capture request/response bodies unless explicitly scrubbed
- expire raw replay segments quickly

## Bot handling

Separate:
- human traffic,
- verified bots,
- unknown automation.

Signals:
- user agent parsing
- reverse DNS verification for major crawlers if needed
- headless/browser automation heuristics
- request cadence

Store bot classification on the request and session.

## Retention model

Recommended starting point:
- raw request logs: 30 to 90 days
- raw event payloads: 90 to 180 days
- replay segments: 7 to 30 days
- identified lead/contact records: according to your CRM policy and notice
- aggregate daily summaries: long term

If you need stronger compliance posture:
- store coarse geo only
- hash IPs with a rotating salt
- purge raw query strings after extraction and scrubbing

## Security controls

Minimum controls:
- dedicated DB user for ingestion
- dedicated DB user for analytics reads
- row-level or schema-level separation for identified contacts
- at-rest encryption on disk
- TLS in transit
- backups
- audit logs
- secret rotation
- access-limited dashboards

## Practical recommendation for DotsAI

### Phase 1
- NGINX JSON logs
- first-party `POST /e`
- PostgreSQL core tables
- consent-aware cookie
- pageviews + CTA + scroll + form + web vitals

### Phase 2
- geo/ASN enrichment
- lead identity stitching
- route and section analytics
- campaign ROI reporting

### Phase 3
- optional replay with strict masking
- warehouse exports
- automated anomaly alerts

## Final recommendation
Build an analytics stack that is:
- first-party,
- explicit,
- partitioned,
- consent-aware,
- useful for revenue decisions.

Do not build a surveillance stack that becomes impossible to defend, secure, or explain.
