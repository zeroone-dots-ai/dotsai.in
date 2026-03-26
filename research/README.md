# DotsAI Research Pack

Prepared: March 26, 2026

## What this pack is for
- Reposition `dotsai.in` as a premium, founder-led AI agency brand.
- Improve eligibility to rank in India for commercial queries around `AI Agency`, `AI Consulting`, `Private AI`, and adjacent service terms.
- Improve visibility in LLM-driven surfaces such as ChatGPT and Gemini by fixing crawlability, strengthening entity consistency, and publishing better public proof.
- Define a premium single-page homepage direction without sacrificing search-entry pages.
- Define a first-party analytics and attribution stack that can run on your VPS-backed PostgreSQL setup without turning into an unmanageable privacy or compliance risk.

## Most important conclusions
- `dotsai.in` should become the primary canonical brand domain if that is the domain you want people, Google, and LLMs to remember.
- A pure one-page site is the wrong architecture if the goal is to rank broadly for `AI Agency` work. The best structure is a premium single-page homepage plus indexable service, case-study, and insight subpages.
- Do not split services into subdomains yet. Use subfolders first to concentrate authority and reduce operational overhead.
- The current home page has a strong manifesto, but it is not aimed at `AI Agency` demand capture.
- Current technical issues are serious enough to delay ranking progress even if the design improves.

## Documents
- `01-current-site-audit.md`: live-site technical, SEO, and brand audit.
- `02-seo-geo-strategy.md`: indexing, ranking, GEO, local search, and authority strategy.
- `03-site-structure-and-scroll-storytelling.md`: recommended IA and the scroll-compartment homepage model.
- `04-design-direction.md`: premium visual direction, best-fit palette, alternatives, and motion rules.
- `05-first-party-analytics-on-vps.md`: what to capture, what not to capture, and how to structure first-party tracking on your own infra.
- `06-postgres-schema-and-ingestion.md`: PostgreSQL entity model, ingestion flow, indexing, retention, and operational rules.
- `07-implementation-rollout.md`: practical implementation path for NGINX, event collection, consent, sessioning, and rollout order.
- `08-launch-readiness-checklist.md`: full launch checklist for SEO, GEO, UX, analytics, conversion, and monitoring.
- `09-qa-validation-matrix.md`: exact test cases, tools, evidence, and pass criteria after development.
- `10-post-launch-growth-operating-rhythm.md`: weekly and monthly operating cadence to grow traffic and authority after launch.
- `11-technical-architecture-deep-dive.md`: end-to-end technical architecture, crawl flow, CDN risks, analytics flow, and failure map.
- `99-sources.md`: primary references used for this research.

## Utilities
- `scripts/release_audit.sh`: shell audit that collects production evidence for headers, robots, sitemap, canonical, crawler responses, and optional DB snapshots.
- `scripts/release_gate.sh`: stricter release gate that runs the audit, writes a gate report, and publishes the latest monitor snapshot into `public/monitor-data/`.
- `qa/RELEASE_CHECKLIST_TEMPLATE.md`: reusable release sign-off template for the dev and QA team.
- `public/site-monitor.html`: single HTML dashboard for live crawl/index checks plus latest audit snapshot data.

## Notes
- The requested `/meet-notebooklm` capability was not available in this session. This pack was produced through direct multi-pass web research plus a live audit of `dotsai.in`.
