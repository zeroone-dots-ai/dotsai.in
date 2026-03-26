# Current Build Review

Prepared: March 26, 2026

## Scope
This document reviews the repository state of `dotsai.in` after the SEO/GEO hardening pass and clarifies what is fixed in code versus what still depends on deployment and indexing.

## Executive Summary

### Repo state now
- the static production source is no longer just a single homepage
- dedicated root-domain pages now exist for:
  - `/ai-agency-india/`
  - `/private-ai/`
  - `/ai-automation/`
  - `/geo-ai/`
  - `/web-ai-experiences/`
  - `/platform-engineering/`
  - `/case-studies/`
  - `/insights/`
- homepage metadata, structured data, internal links, sitemap, and `llms.txt` have been moved to a root-domain-first strategy
- real assets now exist for:
  - `/favicon.svg`
  - `/og-image.png`
- the deploy workflow now ships the full `public/` bundle and the production Nginx config
- the Next.js app now builds successfully with `bun run build`

### Live production caveat
If this branch has not been merged and deployed yet, live production will still reflect the older state.

That means:
- current repo state is cleaner than current production state
- the release gate must be rerun after deploy to verify the live domain

## What Is Actually Built

## 1. Static production bundle
The current production-ready source of truth is the `public/` directory.

That bundle now contains:
- a premium homepage
- service landing pages
- support pages for proof and insights
- a shared stylesheet
- a real `404.html`
- brand assets used by metadata
- the monitor HTML

## 2. Deploy path
The workflow in `.github/workflows/deploy.yml` now does two important things:
- copies the full `public/*` bundle to `/opt/services/nginx/html/dotsai.in/`
- copies `deploy/nginx/default.conf` to `/opt/services/nginx/conf.d/default.conf`

This matters because the repo-side 404 fix depends on the Nginx config actually being deployed, not just the HTML files.

## 3. Next app status
The Next app is no longer in a broken state.

Verified result:
- `bun install --frozen-lockfile` passes
- `bun run build` passes

So the repo now has:
- a deployable static path
- a buildable Next path

It is still true that the static path is the current production delivery path.

## SEO / GEO State After This Pass

## What is fixed in repo

### Root-domain information architecture
The repo now follows the stronger initial structure:
- homepage for brand and conversion
- root-domain service pages for search intent
- proof pages and insight pages for topical depth

This is materially better than a single-page + unresolved-subdomain model.

### Sitemap
`public/sitemap.xml` now contains only primary-domain URLs on `https://dotsai.in`.

The unresolved subdomain URLs were removed from the root sitemap.

### Structured data
The homepage and Next metadata now expose a fuller search-understanding layer:
- `Organization`
- `Person`
- `WebSite`
- `OfferCatalog`

The service URLs now point at real root-domain pages instead of dead subdomains.

### Metadata assets
The repo now includes actual files for:
- `/favicon.svg`
- `/og-image.png`

That closes the earlier metadata-asset gap where the OG image path existed but the asset did not.

### Internal linking
Homepage service rows and footer links now point to real root-domain pages:
- `/private-ai/`
- `/web-ai-experiences/`
- `/geo-ai/`
- `/platform-engineering/`

### LLM-facing site index
`public/llms.txt` now describes the actual root-domain page structure rather than unresolved subdomains.

## What still depends on deployment and indexing

### Real 404 behavior on the live site
Repo-side fix is complete:
- `deploy/nginx/default.conf` now uses `try_files $uri $uri/ $uri/index.html =404;`
- `404.html` exists

But this only affects production after:
1. branch is merged
2. GitHub Actions deploys
3. Nginx reloads with the new config

### Search engine state
Even with the repo fixed, rankings do not update instantly.

After deployment, the next steps are still:
- resubmit `https://dotsai.in/sitemap.xml` in Google Search Console
- request indexing for homepage and the new service pages
- validate coverage and canonical selection in Search Console
- monitor crawl and render status

## Monitoring And QA

The monitoring stack is now more complete:
- `scripts/release_audit.sh` covers more service paths by default
- asset checks now include `og-image.png` and `favicon.svg`
- `public/site-monitor.html` now checks those assets in live browser-side mode too

This closes a blind spot from the earlier pass where metadata assets could break without the monitor flagging them.

## Verified In This Branch

The following checks were run locally in this branch:

- `bun install --frozen-lockfile`
- `bun run build`
- local static serving from `public/`
- local Nginx config validation with a temp config

Observed results:
- homepage returns `200`
- service pages return `200`
- missing URLs return `404`
- `/og-image.png` serves as `image/png`
- `/favicon.svg` serves as `image/svg+xml`

## Remaining Priorities

## P0 after merge
1. Deploy this branch to production.
2. Rerun `./scripts/release_gate.sh dotsai.in zeroonedotsai.consulting`.
3. Confirm live production no longer has soft-404 behavior.
4. Confirm live sitemap now contains only `dotsai.in` URLs.

## P1 next wave
1. Expand case studies with stronger proof density and named business contexts where allowed.
2. Publish more GEO-supporting insight pages around private AI, AI agency work in India, and answer-engine discoverability.
3. Add Search Console and Bing Webmaster operational routines to the release process.

## Verdict

The repo is now materially closer to a production-clean SEO foundation.

Before this pass, the codebase had:
- soft-404 deployment behavior
- dead subdomain references in indexable surfaces
- missing metadata assets
- a broken Next build

After this pass, the repo has:
- root-domain landing architecture
- deployable real-404 config
- valid metadata assets
- stronger structured data
- broader audit coverage
- a passing Next build

The remaining gap is no longer repo structure. It is deployment, indexing, and ongoing content authority.
