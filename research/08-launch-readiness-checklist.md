# Launch Readiness Checklist

Prepared: March 26, 2026

## Important note
No checklist can guarantee "top in India" rankings. It can materially improve your odds by removing avoidable technical failures, making the site easier to crawl and understand, and making the business easier to trust and cite.

Use this as a hard gate before launch.

## 1. Domain and canonical integrity

- [ ] `dotsai.in` is the only primary brand domain used in canonicals, hreflang, OG URLs, sitemap entries, schema URLs, and internal links.
  Validation:
  - inspect homepage and key pages HTML
  - verify `link rel="canonical"`
  - verify `og:url`
  - verify sitemap URLs
  Pass:
  - no canonical or metadata points to `zeroonedotsai.consulting`

- [ ] non-canonical domains 301 redirect to the canonical domain.
  Validation:
  - run `curl -I` on old domains and alternate hostnames
  Pass:
  - one-hop `301` redirect to the final canonical URL

- [ ] `www` vs non-`www`, trailing slash rules, uppercase URLs, and query parameter variants resolve consistently.
  Validation:
  - test representative URL variants
  Pass:
  - only one canonical URL remains indexable

## 2. Crawlability and indexability

- [ ] if the site runs on Vercel, production domains are public and not accidentally covered by Deployment Protection.
  Validation:
  - review Vercel project settings
  - inspect production response behavior in a clean browser and with `curl -I`
  Pass:
  - production domain is publicly accessible
  - preview URLs can stay protected or `noindex`

- [ ] if the site runs on Vercel, production responses do not send `X-Robots-Tag: noindex`.
  Validation:
  - run `curl -I https://dotsai.in/`
  - inspect response headers on key pages
  Pass:
  - no `noindex` header on public production pages

- [ ] if the site runs behind Cloudflare, no transform rule, worker, or cache layer injects `noindex` or stale robots directives.
  Validation:
  - inspect response headers through the live public hostname
  - review Cloudflare Transform Rules / Workers
  Pass:
  - origin and edge agree on indexable headers

- [ ] if the site runs behind Cloudflare, bot management or WAF is not challenging legitimate search crawlers on public pages.
  Validation:
  - review Cloudflare WAF and bot settings
  - test fetches from external monitoring
  Pass:
  - Googlebot and Bingbot can fetch public pages without interstitial challenge

- [ ] `robots.txt` is valid, public, and points to the correct root sitemap.
  Validation:
  - open `/robots.txt`
  Pass:
  - no accidental disallow for public pages
  - correct `Sitemap:` line on `dotsai.in`

- [ ] public money pages are not blocked by `noindex`, auth, JS errors, or broken hydration.
  Validation:
  - view source
  - inspect rendered HTML in Google-accessible mode
  - test in a no-cookie private window
  Pass:
  - primary content is visible and crawlable

- [ ] 404 and 410 pages return correct HTTP status codes.
  Validation:
  - test random missing URLs with `curl -I`
  Pass:
  - missing pages do not return `200`

- [ ] XML sitemap and sitemap index are valid and contain only canonical URLs intended for search.
  Validation:
  - inspect XML directly
  - sample URLs against live pages
  Pass:
  - no redirected URLs
  - no duplicate parameter URLs
  - no staging URLs

## 3. Information architecture and URL strategy

- [ ] homepage stays premium and story-driven, but core service demand is supported by indexable subfolder pages.
  Validation:
  - review IA
  Pass:
  - at minimum, homepage plus dedicated pages for:
    - `/private-ai`
    - `/ai-agency-india`
    - `/ai-automation`
    - `/case-studies`
    - `/insights`

- [ ] do not split core services into subdomains at launch unless there is a strong operational reason.
  Validation:
  - review DNS and IA
  Pass:
  - service pages live under `dotsai.in/...` and inherit root authority

- [ ] every important page is reachable through crawlable HTML links.
  Validation:
  - click through nav, footer, section CTAs, related links
  Pass:
  - no important page exists only behind JS actions

## 4. Metadata and SERP presentation

- [ ] every indexable page has a unique title and meta description.
  Validation:
  - crawl the site
  Pass:
  - no duplicate titles on money pages
  - titles are not truncated badly on mobile

- [ ] titles target clear commercial intent and geography where relevant.
  Validation:
  - manual review
  Pass:
  - examples:
    - `AI Agency India | DotsAI`
    - `Private AI Development for Businesses | DotsAI`

- [ ] OG and Twitter cards render cleanly.
  Validation:
  - use a card preview tool or inspect metadata
  Pass:
  - correct title, description, image, and URL

## 5. Content and topical coverage

- [ ] homepage clearly states:
  - what DotsAI does
  - who it serves
  - why it is different
  - what outcomes it drives
  - what to do next
  Validation:
  - 5-second comprehension test with neutral readers
  Pass:
  - users can summarize offer and audience correctly

- [ ] each service page covers:
  - problem
  - buyer
  - solution
  - scope
  - process
  - outputs
  - proof
  - CTA
  Validation:
  - content review
  Pass:
  - no thin placeholder service pages

- [ ] publish proof pages, not just claims.
  Validation:
  - review live pages
  Pass:
  - case studies, teardown posts, implementation notes, or point-of-view articles exist

## 6. Structured data

- [ ] organization schema is present and accurate.
  Validation:
  - Rich Results Test
  - Schema validator
  Pass:
  - business name, URL, logo, sameAs, contact details are consistent

- [ ] local business schema is present if DotsAI is targeting local and regional searches.
  Validation:
  - Rich Results Test
  Pass:
  - address / region / phone / hours are consistent with business profiles

- [ ] breadcrumbs schema is present on deeper pages.
  Validation:
  - Rich Results Test
  Pass:
  - breadcrumb trail matches visible navigation

- [ ] FAQ schema is not relied on as a major SERP strategy.
  Validation:
  - review implementation
  Pass:
  - FAQ content exists for users, not as a rich-result gimmick

## 7. Internal linking

- [ ] homepage links to all strategic commercial pages with descriptive anchor text.
  Validation:
  - inspect nav, hero, sections, footer
  Pass:
  - links use real `<a href>` anchors

- [ ] service pages link laterally to adjacent services, proof pages, and insights.
  Validation:
  - click through internal links
  Pass:
  - no orphan money pages

- [ ] blog and insight pages feed authority back into commercial pages.
  Validation:
  - inspect editorial templates
  Pass:
  - each article links to relevant service or case-study pages

## 8. Local SEO and India relevance

- [ ] Google Business Profile is fully completed and aligned with the site.
  Validation:
  - manual profile review
  Pass:
  - NAP, category, services, hours, website, and description match website details

- [ ] city / regional relevance is expressed naturally where real.
  Validation:
  - content review
  Pass:
  - no doorway pages stuffed with city names

- [ ] trust assets are visible.
  Validation:
  - review site
  Pass:
  - founder identity, company details, contact route, privacy policy, and service credibility are easy to find

## 9. AI and answer-engine discoverability

- [ ] `OAI-SearchBot` is not blocked if you want ChatGPT search visibility.
  Validation:
  - inspect `robots.txt`
  Pass:
  - crawler is allowed on public pages

- [ ] Google user-triggered fetchers are not accidentally blocked if you want NotebookLM or user-shared page retrieval to work.
  Validation:
  - inspect `robots.txt`
  Pass:
  - no blanket denial that breaks user-triggered retrieval

- [ ] pages contain quotable, factual, citeable blocks.
  Validation:
  - content review
  Pass:
  - pages include concise statements of offer, methodology, results, and positioning

- [ ] entity consistency is strong across site, profiles, and citations.
  Validation:
  - compare business name, description, logo, and links across properties
  Pass:
  - no confusing alternate identities

## 10. Performance and UX

- [ ] mobile experience is the primary test path.
  Validation:
  - test on real phone and throttled conditions
  Pass:
  - no scroll-jank, clipped layouts, unusable animation, or text overlap

- [ ] field targets are reasonable.
  Validation:
  - PageSpeed Insights
  - live RUM after launch
  Pass:
  - LCP under 2.5s at p75 where possible
  - INP under 200ms at p75 where possible
  - CLS under 0.1 at p75 where possible

- [ ] scroll-driven compartments degrade gracefully.
  Validation:
  - disable JS
  - reduced motion preference
  - low-power mobile devices
  Pass:
  - content remains readable and navigable

- [ ] hero and section visuals do not block first render.
  Validation:
  - Lighthouse
  - network waterfall
  Pass:
  - no oversized media dominating initial load

## 11. Conversion system

- [ ] every major page has one clear primary CTA.
  Validation:
  - review page hierarchy
  Pass:
  - no CTA clutter

- [ ] contact, WhatsApp, booking, and email routes all work.
  Validation:
  - test end-to-end
  Pass:
  - leads actually arrive in the right inbox/CRM

- [ ] forms are short, fast, and trustworthy.
  Validation:
  - manual submission on mobile and desktop
  Pass:
  - no broken validation loops
  - success state is obvious

## 12. Analytics and attribution

- [ ] request logs, pageviews, sessions, events, and consent states are all reaching PostgreSQL.
  Validation:
  - verify rows in analytics tables
  Pass:
  - timestamps, session stitching, and attribution are consistent

- [ ] UTMs and ad click IDs are captured and normalized.
  Validation:
  - run controlled visits with tagged URLs
  Pass:
  - source, medium, campaign map correctly in DB

- [ ] chatgpt.com, google, direct, referral, LinkedIn, WhatsApp, and paid traffic can be separated in reporting.
  Validation:
  - reporting review
  Pass:
  - acquisition dashboard supports source-level analysis

- [ ] no secrets or sensitive form payloads are being stored accidentally.
  Validation:
  - inspect raw logs and event payloads
  Pass:
  - no passwords, OTPs, cards, or hidden junk data in analytics

## 13. Security and trust

- [ ] HTTPS is clean across all routes.
  Validation:
  - browser inspection
  - SSL test
  Pass:
  - no mixed content

- [ ] security headers are present.
  Validation:
  - inspect response headers
  Pass:
  - CSP, HSTS, X-Content-Type-Options, Referrer-Policy, and sane cookie flags are configured

- [ ] admin, staging, preview, and private routes are not crawlable.
  Validation:
  - URL inventory review
  Pass:
  - no accidental public exposure

## 14. Launch submissions and tooling

- [ ] Google Search Console domain property is verified.
  Validation:
  - Search Console
  Pass:
  - domain property live for `dotsai.in`

- [ ] sitemap is submitted in Google Search Console.
  Validation:
  - Search Console Sitemaps report
  Pass:
  - sitemap fetch succeeds

- [ ] Bing Webmaster Tools is configured.
  Validation:
  - Bing Webmaster
  Pass:
  - site verified and sitemap submitted

- [ ] IndexNow is configured for fast recrawl on updates.
  Validation:
  - publish or update a test page and ping IndexNow
  Pass:
  - submissions succeed

- [ ] if using Cloudflare, Crawler Hints is reviewed and enabled when it fits the setup.
  Validation:
  - inspect Cloudflare Cache configuration
  Pass:
  - crawler hinting is either deliberately enabled or deliberately left off with reason

## 15. Launch monitoring

- [ ] create alerts for:
  - downtime
  - 5xx spikes
  - sudden 404 spikes
  - traffic drops
  - form failures
  - JS error spikes
  Validation:
  - trigger test incidents
  Pass:
  - alerts route to the right person and channel

- [ ] create baseline reports for first 30 days.
  Validation:
  - dashboard review
  Pass:
  - daily traffic, brand vs non-brand, top landing pages, leads, and conversion rates are visible

## Final launch gate
Do not ship the revamp until these are true:

- [ ] canonical domain issues are fixed
- [ ] missing URLs return real 404
- [ ] sitemap only contains canonical `dotsai.in` URLs
- [ ] service architecture supports indexable search-entry pages
- [ ] analytics stack is receiving clean source and conversion data
- [ ] mobile performance and motion are acceptable on real devices
- [ ] contact and booking flows work end-to-end
