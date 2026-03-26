# Current Site Audit

Audit date: March 26, 2026
Live targets reviewed: `https://dotsai.in/` and `https://zeroonedotsai.consulting/`

## Executive read
The current site has a good brand line and decent lab performance, but it is sending mixed domain signals, weak `AI Agency` signals, and avoidable crawl/indexing errors. The fastest path to stronger visibility is not a cosmetic redesign alone. It is:

1. choose one canonical domain,
2. fix route/indexing behavior,
3. simplify the homepage into a premium agency story,
4. move search depth into service and proof pages.

## Critical technical findings

### 1. `dotsai.in` currently nominates another domain as canonical
- `dotsai.in` currently outputs canonicals, hreflang URLs, OG URLs, and sitemap references pointing to `zeroonedotsai.consulting`.
- If `dotsai.in` is the intended brand domain, this is the biggest indexing conflict on the site.
- Current examples observed on `dotsai.in`:
  - canonical: `https://zeroonedotsai.consulting/`
  - sitemap in `robots.txt`: `https://zeroonedotsai.consulting/sitemap.xml`
  - `og:url`: `https://zeroonedotsai.consulting/`
  - `hreflang` alternates: `https://zeroonedotsai.consulting/`

### 2. The site has soft-404 risk
- Nonexistent URLs on `dotsai.in` return `HTTP 200`.
- The app does render a visible `Page not found` UI, but the server response remains `200`.
- This is exactly the kind of SPA routing issue Google warns about for JavaScript sites.
- Fix options:
  - best: return an actual `404` from the server for missing routes
  - fallback: inject `noindex` for error routes and/or redirect to a real server-side `404`

### 3. Route and canonical mismatches already exist
- Internal navigation links to `/services`.
- The rendered page canonicalizes to `/solutions`.
- This means users, crawlers, and internal links are not aligned around one preferred URL.
- Pick one route and make all internal links, canonicals, sitemap entries, and breadcrumbs agree.

### 4. The robots file is permissive, but not strategically useful yet
- The current `robots.txt` allows Googlebot, GPTBot, ChatGPT-User, ClaudeBot, Google-Extended, PerplexityBot, and more.
- That is fine, but it does not compensate for canonical conflicts or soft-404 behavior.
- Also, `Google-Extended` does not affect ranking in Google Search.

### 5. The sitemap is structurally okay but attached to the wrong host
- The sitemap includes a wide set of pages and clusters.
- The problem is host alignment, not sitemap existence.
- If `dotsai.in` is the money domain, the sitemap must live there and list `dotsai.in` URLs only.

## Search and positioning findings

### 1. The homepage is not targeting `AI Agency` intent
- The live homepage title after render focuses on `Private AI for Every Business`.
- The hero message is strong, but it is manifesto-first, not search-demand-first.
- For a brand trying to win `AI Agency` work, the homepage needs clearer commercial relevance:
  - AI agency
  - AI consulting
  - private AI systems
  - AI automation for businesses
  - India relevance

### 2. The current homepage tries to do too many jobs
- Agency
- private AI movement
- community
- bounty board
- education
- outcomes
- multiple product/service clusters

This makes the homepage feel broader than the buying intent you want to win.

### 3. Brand search visibility appears weak
- Inference: current web search checks did not surface meaningful indexed results for `dotsai.in` or `zeroonedotsai.consulting`.
- This is not a formal indexing report, but it strongly suggests the site is not yet earning much search presence.

## Current visual system audit

### What is strong
- `Own Your AI. Don't Rent It.` is memorable.
- The light editorial base is more distinctive than generic dark-SaaS AI sites.
- `Instrument Serif` + mono detailing gives character.
- The current brand already has a good paper/ink/plum foundation.

### What is holding it back
- Too many sections feel like a multi-offer startup rather than a premium specialist agency.
- Pastel accents are used too broadly, which softens authority.
- Some pages lean into card grids and product tiles more than a premium narrative.
- The homepage is not visually severe enough for enterprise trust and not focused enough for agency conversion.

## Current palette tokens observed
- Background: `40 20% 99%`
- Foreground: `240 18% 12%`
- Dots data: `#C8B6FF`
- Dots operations: `#B8E0D2`
- Dots tech: `#FFCDB2`
- Dots strategy: `#A2D2FF`
- Accent: `266 48% 21%`
- Gradient aurora: `#C8B6FF -> #A2D2FF -> #B8E0D2`
- Gradient cosmos: `#191924 -> #2D1B4E`

## Performance snapshot
- Desktop Lighthouse lab scores observed:
  - Performance: `0.88`
  - Accessibility: `0.91`
  - Best Practices: `0.96`
  - SEO: `1.00`
- Lab SEO being high does not invalidate the live canonical and soft-404 problems above.

## What to keep
- Hero theme: `Own Your AI. Don't Rent It.`
- Light editorial canvas
- Serif-led brand expression
- India-first positioning
- Privacy / ownership / offline capability theme

## What to remove from the homepage
- Bounty engine as a primary homepage storyline
- Community as a major early conversion path
- Over-wide service sprawl
- Multi-color card density
- Any section that makes the agency feel like a content platform before it feels like the best partner to hire

## What to rewrite
- Home title, H1, metadata, and intro copy around `AI Agency` + `Private AI`
- Core nav
- Service taxonomy
- Proof narrative
- Founder story
- CTA path

## Immediate action order
1. Choose `dotsai.in` or `zeroonedotsai.consulting` as the single primary domain.
2. Align canonicals, hreflang, sitemap, OG URLs, and internal links to that domain.
3. Fix soft-404 behavior.
4. Collapse the homepage around one commercial story.
5. Move depth into service and proof pages.
