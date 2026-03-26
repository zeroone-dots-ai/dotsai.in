# Release Checklist Template

Use this template for each release after development is complete.

## Release details

- Release name:
- Target domain:
- Environment:
- Release owner:
- QA owner:
- Developer owner:
- Date:
- Commit / deployment ID:

## Scope

- Pages changed:
- SEO-critical changes:
- Motion / UI changes:
- Forms / CTA changes:
- Analytics changes:
- Infra changes:

## P0 release blockers

- [ ] canonical domain verified on production
- [ ] homepage returns `200`
- [ ] fake URL returns `404` or `410`
- [ ] production does not send `X-Robots-Tag: noindex`
- [ ] robots.txt is public and valid
- [ ] sitemap contains only canonical `dotsai.in` URLs
- [ ] primary service pages are crawlable and self-canonical
- [ ] homepage value prop and CTA are clear on mobile
- [ ] compartment scrolling works on real devices
- [ ] contact / booking flow works end-to-end
- [ ] visitor, session, pageview, and attribution rows reach PostgreSQL
- [ ] no sensitive junk data is leaking into logs or analytics
- [ ] staging / preview environments are not publicly indexable

## P1 launch quality checks

- [ ] titles and meta descriptions are unique on key pages
- [ ] organization schema is valid
- [ ] local business schema is valid if used
- [ ] Open Graph preview is correct
- [ ] Core Web Vitals lab check is acceptable
- [ ] Cloudflare does not inject bad indexing headers
- [ ] Vercel production is not accidentally protected
- [ ] Search Console property is verified
- [ ] sitemap submitted in Google Search Console
- [ ] Bing Webmaster and IndexNow are configured
- [ ] Google Business Profile matches the site
- [ ] source, medium, and campaign values are reporting correctly
- [ ] lead identity stitching works if forms are live
- [ ] alerting path is tested

## Evidence captured

- [ ] header outputs
- [ ] robots snapshot
- [ ] sitemap snapshot
- [ ] canonical screenshots
- [ ] mobile recordings
- [ ] Rich Results Test screenshots
- [ ] Search Console screenshots
- [ ] form trace evidence
- [ ] database evidence

## Failed items

| Priority | Issue | Owner | ETA | Retest evidence |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Sign-off

- QA sign-off:
- SEO sign-off:
- Engineering sign-off:
- Final launch decision:

## References

- [QA Validation Matrix](/Users/meetdeshani/Desktop/dotsai.in/research/09-qa-validation-matrix.md)
- [Launch Readiness Checklist](/Users/meetdeshani/Desktop/dotsai.in/research/08-launch-readiness-checklist.md)
- [Technical Architecture Deep Dive](/Users/meetdeshani/Desktop/dotsai.in/research/11-technical-architecture-deep-dive.md)
