# Sources

Research date: March 26, 2026

## Live-site audit inputs
- `https://dotsai.in/`
- `https://dotsai.in/robots.txt`
- `https://dotsai.in/sitemap.xml`
- `https://dotsai.in/assets/index-DuPPBMFw.css`
- `https://zeroonedotsai.consulting/`

## Google Search / crawling / indexing
- Google Search Essentials
  - https://developers.google.com/search/docs/essentials
- SEO Starter Guide
  - https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- JavaScript SEO basics
  - https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics
- Sitemaps overview
  - https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview
- Canonicalization guidance
  - https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Robots.txt introduction
  - https://developers.google.com/search/docs/crawling-indexing/robots/intro
- Site names
  - https://developers.google.com/search/docs/appearance/site-names
- Google’s common crawlers
  - https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers
- Google user-triggered fetchers
  - https://developers.google.com/crawling/docs/crawlers-fetchers/google-user-triggered-fetchers
- Local business structured data
  - https://developers.google.com/search/docs/appearance/structured-data/local-business
- Preferred sources
  - https://developers.google.com/search/docs/appearance/preferred-sources

## Google local search
- Tips to improve your local ranking on Google
  - https://support.google.com/business/answer/7091?hl=en

## OpenAI / ChatGPT search
- Publishers and Developers - FAQ
  - https://help.openai.com/en/articles/12627856-publishers-and-developers-faq

## Motion and performance
- CSS scroll-driven animations
  - https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Scroll-driven_animations
- Avoid large, complex layouts and layout thrashing
  - https://web.dev/articles/avoid-large-complex-layouts-and-layout-thrashing
- Web Vitals
  - https://web.dev/articles/vitals

## Data collection, consent, and analytics implementation
- Digital Personal Data Protection Act, 2023
  - https://www.meity.gov.in/static/uploads/2024/02/Digital-Personal-Data-Protection-Act-2023.pdf
- Digital Personal Data Protection Rules, 2025
  - https://www.meity.gov.in/static/uploads/2025/11/53450e6e5dc0bfa85ebd78686cadad39.pdf
- NGINX `access_log`
  - https://nginx.org/r/access_log
- NGINX embedded variables
  - https://nginx.org/en/docs/varindex.html
- MDN `Navigator.sendBeacon()`
  - https://developer.mozilla.org/en-US/docs/Web/API/Navigator/sendBeacon
- MDN `Document.referrer`
  - https://developer.mozilla.org/en-US/docs/Web/API/Document/referrer
- MDN `Navigator.languages`
  - https://developer.mozilla.org/en-US/docs/Web/API/Navigator/languages
- MDN `NetworkInformation.effectiveType`
  - https://developer.mozilla.org/en-US/docs/Web/API/NetworkInformation/effectiveType
- MDN `PerformanceObserver`
  - https://developer.mozilla.org/en-US/docs/Web/API/PerformanceObserver
- MDN `PerformanceNavigationTiming`
  - https://developer.mozilla.org/en-US/docs/Web/API/PerformanceNavigationTiming
- PostgreSQL declarative partitioning
  - https://www.postgresql.org/docs/current/ddl-partitioning.html
- PostgreSQL JSON types
  - https://www.postgresql.org/docs/current/datatype-json.html
- PostgreSQL `pgcrypto`
  - https://www.postgresql.org/docs/current/pgcrypto.html
- Sentry JavaScript data collected
  - https://docs.sentry.io/platforms/javascript/data-management/data-collected/

## Hosting platform indexing behavior
- Vercel Deployment Protection
  - https://vercel.com/docs/deployment-protection
- Vercel preview deployment indexing
  - https://vercel.com/kb/guide/are-vercel-preview-deployment-indexed-by-search-engines
- Vercel crawler delay mitigation / Skew Protection
  - https://vercel.com/changelog/automatic-mitigation-of-crawler-delay-via-skew-protection
- Cloudflare Crawler Hints
  - https://developers.cloudflare.com/cache/advanced-configuration/crawler-hints/
- Google robots meta and `X-Robots-Tag`
  - https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag
- Google redirects and canonical signals
  - https://developers.google.com/search/docs/crawling-indexing/301-redirects

## Notes used in analysis
- `Google-Extended` can affect Gemini training/grounding permissions but Google states it does not affect ranking in Google Search.
- `Google-NotebookLM` is documented as a user-triggered fetcher for URLs users explicitly provide as sources.
- OpenAI states that any public website can appear in ChatGPT search, but inclusion and ranking are not guaranteed; `OAI-SearchBot` access is important for summaries/snippets.
