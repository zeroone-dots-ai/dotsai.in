# QA Validation Matrix

Prepared: March 26, 2026

This file is the release-gate testing document for the DotsAI revamp. It is meant to be used after development is complete and before production launch.

The standard is not "looks fine on my laptop". The standard is:

- crawlable
- indexable
- fast enough
- measurable
- conversion-safe
- platform-safe on Vercel / Cloudflare
- operationally observable

## Release rule

- if any `P0` test fails, do not launch
- if more than 5 `P1` tests fail, do not launch
- every failed test must have:
  - owner
  - issue link
  - fix ETA
  - retest evidence

## Severity scale

- `P0`: launch blocker
- `P1`: should fix before launch
- `P2`: can ship with explicit mitigation

## Required tools and access

- browser with DevTools
- mobile device testing on at least one iPhone and one Android
- `curl`
- `dig`
- `openssl`
- `lighthouse`
- `psql`
- Google Search Console
- Bing Webmaster Tools
- Rich Results Test
- access to Vercel settings if Vercel is used
- access to Cloudflare settings if Cloudflare is used
- access to analytics PostgreSQL

## Evidence package

Create a release evidence folder such as:

```text
/qa/2026-03-26-revamp-release/
  01-headers.txt
  02-robots.txt
  03-sitemap.xml
  04-canonical-screenshots/
  05-rich-results/
  06-mobile-recordings/
  07-performance/
  08-db-snapshots/
  09-form-traces/
  10-search-console/
```

## Command pack

Use these commands during validation.

### Header checks

```bash
curl -I https://dotsai.in/
curl -I https://dotsai.in/ai-agency-india
curl -I https://dotsai.in/this-should-not-exist
curl -I https://zeroonedotsai.consulting/
curl -I https://www.dotsai.in/
```

### Crawler-behavior checks

```bash
curl -I -A "Googlebot/2.1 (+http://www.google.com/bot.html)" https://dotsai.in/
curl -I -A "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)" https://dotsai.in/
curl -I -A "Mozilla/5.0 (compatible; OAI-SearchBot/1.0; +https://openai.com/searchbot)" https://dotsai.in/
```

### DNS and TLS checks

```bash
dig +short dotsai.in
dig +short www.dotsai.in
openssl s_client -connect dotsai.in:443 -servername dotsai.in </dev/null
```

### Crawl artifact checks

```bash
curl -s https://dotsai.in/robots.txt
curl -s https://dotsai.in/sitemap.xml
```

### Analytics checks

```bash
psql "$ANALYTICS_DATABASE_URL" -c "select now();"
psql "$ANALYTICS_DATABASE_URL" -c "select session_id, started_at, landing_touch_id from analytics.sessions order by started_at desc limit 10;"
psql "$ANALYTICS_DATABASE_URL" -c "select event_name, occurred_at, path from analytics.events order by occurred_at desc limit 20;"
psql "$ANALYTICS_DATABASE_URL" -c "select source, medium, campaign, occurred_at from analytics.attribution_touches order by occurred_at desc limit 20;"
```

## Test matrix

### A. Domain, DNS, and canonical routing

1. Test: apex domain resolves correctly
- Priority: `P0`
- Tool:
  - `dig`
- Evidence:
  - IP or CNAME chain output
- Pass:
  - `dotsai.in` resolves to the intended production stack

2. Test: `www` behavior is explicit
- Priority: `P0`
- Tool:
  - `dig`
  - `curl -I`
- Evidence:
  - redirect output
- Pass:
  - `www` either resolves and 301 redirects to the canonical host, or is intentionally unused and still redirects correctly

3. Test: legacy domain redirect chain
- Priority: `P0`
- Tool:
  - `curl -I`
- Evidence:
  - redirect headers from `zeroonedotsai.consulting`
- Pass:
  - one-hop `301` to the correct `dotsai.in` URL

4. Test: uppercase, trailing slash, and parameter variants
- Priority: `P1`
- Tool:
  - `curl -I`
  - browser checks
- Evidence:
  - sample variant outputs
- Pass:
  - variants consolidate to one canonical URL

### B. CDN, hosting, and platform safety

5. Test: Vercel production indexing safety
- Priority: `P0`
- Tool:
  - `curl -I`
  - Vercel settings review
- Evidence:
  - production response headers
  - deployment protection settings
- Pass:
  - no `X-Robots-Tag: noindex` on production
  - production domain is publicly fetchable

6. Test: Vercel preview protection behavior
- Priority: `P2`
- Tool:
  - preview URL check
- Evidence:
  - preview response headers
- Pass:
  - preview URLs can stay protected or `noindex`; they must not become canonical production URLs

7. Test: Cloudflare edge header parity
- Priority: `P0`
- Tool:
  - `curl -I`
  - Cloudflare Transform Rules review
- Evidence:
  - live edge headers
- Pass:
  - edge does not inject or remove indexing headers incorrectly

8. Test: Cloudflare WAF and bot access
- Priority: `P0`
- Tool:
  - Cloudflare dashboard review
  - external fetch tests
- Evidence:
  - WAF settings
  - successful public fetches
- Pass:
  - legitimate crawlers can access public pages without challenge interstitials

9. Test: cache invalidation on deploy
- Priority: `P1`
- Tool:
  - deploy changed metadata
  - compare post-deploy HTML
- Evidence:
  - before/after responses
- Pass:
  - changed canonicals, titles, and robots output are visible after deploy

### C. HTTP status, robots, and sitemap correctness

10. Test: homepage indexability
- Priority: `P0`
- Tool:
  - browser view source
  - `curl -I`
  - URL Inspection
- Evidence:
  - status code
  - canonical
  - robots signals
- Pass:
  - `200`
  - self-canonical on `https://dotsai.in/`
  - no `noindex`

11. Test: key commercial page indexability
- Priority: `P0`
- Tool:
  - same as above
- Evidence:
  - status and metadata for pages like `/ai-agency-india` and `/private-ai`
- Pass:
  - each page is indexable and self-canonical

12. Test: nonexistent URL behavior
- Priority: `P0`
- Tool:
  - `curl -I https://dotsai.in/this-should-not-exist`
- Evidence:
  - response code
- Pass:
  - returns `404` or `410`, never `200`

13. Test: robots.txt correctness
- Priority: `P0`
- Tool:
  - `curl -s`
- Evidence:
  - robots output snapshot
- Pass:
  - public pages are allowed
  - correct sitemap line
  - no accidental crawler blocks

14. Test: XML sitemap integrity
- Priority: `P0`
- Tool:
  - open XML
  - sample URL checks
- Evidence:
  - sitemap snapshot
- Pass:
  - only canonical `dotsai.in` URLs
  - no redirects
  - no staging or preview URLs

15. Test: X-Robots-Tag review
- Priority: `P0`
- Tool:
  - `curl -I`
- Evidence:
  - response headers on homepage, service pages, assets, PDFs if any
- Pass:
  - no unintended `noindex`, `nofollow`, or media-level suppression on pages intended to rank

### D. Rendering, content visibility, and internal links

16. Test: server-rendered content visibility
- Priority: `P0`
- Tool:
  - view-source
  - rendered DOM inspection
- Evidence:
  - HTML snapshots
- Pass:
  - meaningful headings, body content, and links are present without requiring user interaction

17. Test: hydration integrity
- Priority: `P1`
- Tool:
  - browser console
  - hard refresh
- Evidence:
  - no fatal hydration errors
- Pass:
  - page remains stable after hydration

18. Test: no-JS fallback
- Priority: `P1`
- Tool:
  - disable JavaScript
- Evidence:
  - screenshots
- Pass:
  - content and links remain understandable even if motion is absent

19. Test: internal link crawlability
- Priority: `P0`
- Tool:
  - manual click-through
  - crawler report
- Evidence:
  - exported links
- Pass:
  - all strategic pages reachable through standard links

20. Test: orphan page check
- Priority: `P1`
- Tool:
  - URL inventory review
- Evidence:
  - crawl vs sitemap comparison
- Pass:
  - no key service or proof page is orphaned

### E. Metadata, structured data, and SERP readiness

21. Test: title uniqueness and intent fit
- Priority: `P1`
- Tool:
  - site crawl
- Evidence:
  - title export
- Pass:
  - unique titles on all indexable pages
  - core pages express buyer intent clearly

22. Test: meta description quality
- Priority: `P1`
- Tool:
  - crawl export
- Evidence:
  - descriptions export
- Pass:
  - no duplicates on key pages
  - not empty on money pages

23. Test: Open Graph and social preview
- Priority: `P1`
- Tool:
  - metadata inspection
  - preview tooling
- Evidence:
  - screenshot of card previews
- Pass:
  - correct image, title, description, and canonical URL

24. Test: Organization schema
- Priority: `P1`
- Tool:
  - Rich Results Test
  - Schema validator
- Evidence:
  - validation screenshots
- Pass:
  - business name, logo, URL, and sameAs are consistent

25. Test: LocalBusiness schema
- Priority: `P1`
- Tool:
  - Rich Results Test
- Evidence:
  - validation screenshot
- Pass:
  - only present if business details are real and consistent

26. Test: BreadcrumbList schema
- Priority: `P2`
- Tool:
  - Rich Results Test
- Evidence:
  - validation screenshot
- Pass:
  - breadcrumbs match visible navigation hierarchy

27. Test: schema URL consistency
- Priority: `P0`
- Tool:
  - source review
- Evidence:
  - JSON-LD snapshot
- Pass:
  - schema URLs use `dotsai.in`, not old domains

### F. Mobile UX, motion, and performance

28. Test: mobile hero clarity
- Priority: `P0`
- Tool:
  - real iPhone and Android
- Evidence:
  - screenshots and recording
- Pass:
  - value proposition and primary CTA are obvious immediately

29. Test: scroll-compartment handoff
- Priority: `P0`
- Tool:
  - real devices
  - low-power mode
  - CPU throttle
- Evidence:
  - screen recording
- Pass:
  - no trapped scroll
  - no skipped sections
  - no motion-induced layout collapse

30. Test: reduced-motion handling
- Priority: `P1`
- Tool:
  - OS reduced-motion setting
- Evidence:
  - recording
- Pass:
  - motion softens or disables while preserving readability

31. Test: font loading discipline
- Priority: `P1`
- Tool:
  - network waterfall
- Evidence:
  - request list
- Pass:
  - no font explosion
  - no major FOIT on mobile

32. Test: image and media budget
- Priority: `P1`
- Tool:
  - network panel
- Evidence:
  - image weights and formats
- Pass:
  - hero assets are compressed and sized intentionally

33. Test: Core Web Vitals lab check
- Priority: `P1`
- Tool:
  - Lighthouse
  - PageSpeed Insights
- Evidence:
  - report exports
- Pass:
  - no severe regression caused by animation, fonts, or media

34. Test: interaction stability
- Priority: `P1`
- Tool:
  - live clicking during scroll
- Evidence:
  - recording
- Pass:
  - CTAs remain clickable and not overlaid by sticky or animated elements

### G. Content quality and conversion readiness

35. Test: homepage comprehension
- Priority: `P0`
- Tool:
  - 5-second test with neutral readers
- Evidence:
  - notes from at least 3 testers
- Pass:
  - testers can correctly answer:
    - what DotsAI does
    - who it is for
    - what the next action is

36. Test: service page completeness
- Priority: `P1`
- Tool:
  - content review
- Evidence:
  - checklist per service page
- Pass:
  - each page includes problem, offer, proof, and CTA

37. Test: proof visibility
- Priority: `P1`
- Tool:
  - manual review
- Evidence:
  - screenshots
- Pass:
  - social proof, founder proof, or case proof is visible before deep scroll

38. Test: primary CTA path
- Priority: `P0`
- Tool:
  - desktop and mobile manual journey
- Evidence:
  - recordings
- Pass:
  - every primary CTA opens the intended route or booking flow

39. Test: contact form end-to-end
- Priority: `P0`
- Tool:
  - live submission
- Evidence:
  - frontend state
  - backend receipt
  - CRM or inbox receipt
- Pass:
  - exactly one lead created
  - success state shown
  - attribution not lost

40. Test: WhatsApp, email, and booking links
- Priority: `P1`
- Tool:
  - manual click test
- Evidence:
  - destination proof
- Pass:
  - links resolve correctly
  - campaign parameters survive if needed

### H. Analytics, attribution, and database validation

41. Test: visitor creation
- Priority: `P0`
- Tool:
  - `psql`
- Evidence:
  - latest rows in `analytics.visitors`
- Pass:
  - first visit creates one anonymous visitor record

42. Test: session creation
- Priority: `P0`
- Tool:
  - `psql`
- Evidence:
  - latest rows in `analytics.sessions`
- Pass:
  - one coherent session created with timestamps and path context

43. Test: pageview capture
- Priority: `P0`
- Tool:
  - `psql`
- Evidence:
  - latest rows in `analytics.pageviews`
- Pass:
  - each route view or page load creates pageview rows as expected

44. Test: UTM attribution capture
- Priority: `P0`
- Tool:
  - tagged landing visits
  - `psql`
- Evidence:
  - `analytics.attribution_touches` rows
- Pass:
  - `utm_source`, `utm_medium`, and `utm_campaign` stored correctly

45. Test: ad click ID capture
- Priority: `P1`
- Tool:
  - tagged test visits
- Evidence:
  - touch rows with click IDs
- Pass:
  - `gclid`, `gbraid`, `wbraid`, `fbclid`, `msclkid` captured only where present

46. Test: event tracking integrity
- Priority: `P1`
- Tool:
  - trigger CTA, scroll, form, outbound actions
  - `psql`
- Evidence:
  - `analytics.events`
- Pass:
  - expected events exist
  - no duplicate event storm from a single action

47. Test: web vitals ingestion
- Priority: `P1`
- Tool:
  - live browser visit
  - `psql`
- Evidence:
  - rows in `analytics.web_vitals`
- Pass:
  - available vitals inserted with path context

48. Test: JS error ingestion
- Priority: `P2`
- Tool:
  - induced test error on staging or safe test route
  - `psql`
- Evidence:
  - row in `analytics.js_errors`
- Pass:
  - errors are visible and attributable

49. Test: request log ingestion
- Priority: `P1`
- Tool:
  - hit test URLs
  - `psql`
- Evidence:
  - rows in `analytics.request_logs`
- Pass:
  - request metadata lands in DB

50. Test: consent event recording
- Priority: `P1`
- Tool:
  - interact with consent UI
  - `psql`
- Evidence:
  - rows in `analytics.consent_events`
- Pass:
  - consent changes are timestamped and versioned

51. Test: lead identity stitching
- Priority: `P1`
- Tool:
  - submit a form
  - `psql`
- Evidence:
  - `crm.contact_identities`
  - linked `analytics.visitors.contact_id`
- Pass:
  - contact record created and linked without duplicating PII into event rows

52. Test: source grouping quality
- Priority: `P1`
- Tool:
  - dashboard or SQL review
- Evidence:
  - grouped acquisition output
- Pass:
  - direct, search, referral, LinkedIn, WhatsApp, paid, and ChatGPT-originating traffic can be segmented sensibly

53. Test: payload hygiene
- Priority: `P0`
- Tool:
  - inspect raw logs and event payloads
- Evidence:
  - sample rows
- Pass:
  - no passwords, OTPs, payment data, or junk hidden field dumps in storage

### I. Search platform and local presence checks

54. Test: Google Search Console property
- Priority: `P0`
- Tool:
  - Search Console
- Evidence:
  - screenshot of verified domain property
- Pass:
  - `dotsai.in` verified at domain level

55. Test: sitemap submission status
- Priority: `P0`
- Tool:
  - Search Console
  - Bing Webmaster
- Evidence:
  - successful fetch status
- Pass:
  - sitemap parsed successfully

56. Test: URL inspection of core pages
- Priority: `P1`
- Tool:
  - URL Inspection
- Evidence:
  - inspection screenshots
- Pass:
  - homepage and key service pages are fetchable and selected canonical is correct

57. Test: Bing Webmaster and IndexNow readiness
- Priority: `P1`
- Tool:
  - Bing Webmaster
  - IndexNow submission
- Evidence:
  - verification and submission proof
- Pass:
  - changed URLs can be pushed quickly

58. Test: Google Business Profile alignment
- Priority: `P1`
- Tool:
  - manual GBP review
- Evidence:
  - screenshots
- Pass:
  - name, website, category, and contact details align with the site

59. Test: citation consistency
- Priority: `P2`
- Tool:
  - manual profile review
- Evidence:
  - screenshot set
- Pass:
  - LinkedIn, directories, and other public profiles use the same brand identity and domain

### J. LLM and answer-engine discoverability

60. Test: OpenAI crawler accessibility
- Priority: `P1`
- Tool:
  - `robots.txt`
  - crawler-agent header tests
- Evidence:
  - robots snapshot
- Pass:
  - `OAI-SearchBot` is not blocked on public pages

61. Test: Google user-triggered fetcher accessibility
- Priority: `P2`
- Tool:
  - `robots.txt`
- Evidence:
  - robots snapshot
- Pass:
  - no blanket blocks that would break user-provided URL retrieval

62. Test: citeable content blocks
- Priority: `P1`
- Tool:
  - manual content review
- Evidence:
  - screenshots of key page sections
- Pass:
  - pages contain concise, factual, quote-ready statements of offer, proof, and methodology

### K. Security, observability, and rollback readiness

63. Test: HTTPS and mixed content
- Priority: `P0`
- Tool:
  - browser console
  - SSL check
- Evidence:
  - screenshots
- Pass:
  - no mixed-content warnings

64. Test: security headers
- Priority: `P1`
- Tool:
  - `curl -I`
- Evidence:
  - header snapshot
- Pass:
  - HSTS, CSP, X-Content-Type-Options, Referrer-Policy, and sane cookie flags are present

65. Test: staging and preview leakage
- Priority: `P0`
- Tool:
  - URL inventory
  - search operators
- Evidence:
  - inventory notes
- Pass:
  - preview and staging are not crawlable as production content

66. Test: alerting pipeline
- Priority: `P1`
- Tool:
  - trigger test error or test alert
- Evidence:
  - notification received
- Pass:
  - alert reaches the correct owner/channel

67. Test: rollback readiness
- Priority: `P2`
- Tool:
  - deployment platform review
- Evidence:
  - rollback path documented
- Pass:
  - previous stable deployment can be restored quickly if SEO-critical breakage occurs

## SQL verification snippets

Use these after controlled visits.

### Latest sessions

```sql
select
  session_id,
  visitor_id,
  started_at,
  last_activity_at,
  entry_path,
  exit_path,
  landing_touch_id,
  pageviews_count,
  events_count,
  converted
from analytics.sessions
order by started_at desc
limit 20;
```

### Latest attribution touches

```sql
select
  touch_id,
  occurred_at,
  landing_path,
  referrer_domain,
  source,
  medium,
  campaign,
  gclid,
  fbclid
from analytics.attribution_touches
order by occurred_at desc
limit 20;
```

### Latest events

```sql
select
  event_id,
  occurred_at,
  event_name,
  path,
  section_name,
  element_label
from analytics.events
order by occurred_at desc
limit 50;
```

### Lead stitching check

```sql
select
  c.contact_id,
  c.created_at,
  c.email,
  c.source_form,
  v.visitor_id,
  v.contact_id
from crm.contact_identities c
left join analytics.visitors v
  on v.contact_id = c.contact_id
order by c.created_at desc
limit 20;
```

## Acceptance evidence package

Before launch, capture all of these:

- [ ] homepage desktop screenshot
- [ ] homepage mobile screenshot
- [ ] service page mobile screenshot
- [ ] `curl -I` output for homepage
- [ ] `curl -I` output for one service page
- [ ] `curl -I` output for one fake page
- [ ] `robots.txt` snapshot
- [ ] `sitemap.xml` snapshot
- [ ] Rich Results Test screenshots
- [ ] Search Console property screenshot
- [ ] URL Inspection screenshot for homepage
- [ ] URL Inspection screenshot for one service page
- [ ] one mobile screen recording of compartment scrolling
- [ ] one successful form submission trace
- [ ] SQL output for session, attribution, and event rows from a tagged visit
- [ ] security header snapshot

## Final release gate

The revamp is launch-ready only if all of these are true:

- [ ] canonical domain and redirects are clean
- [ ] production is indexable and not accidentally `noindex`
- [ ] fake URLs return real `404`
- [ ] sitemap is canonical and submitted
- [ ] service pages exist and are crawlable
- [ ] mobile compartment scrolling works on real devices
- [ ] CTA and form paths work end-to-end
- [ ] analytics DB receives coherent attribution and conversion data
- [ ] no sensitive junk data is leaking into logs or analytics
