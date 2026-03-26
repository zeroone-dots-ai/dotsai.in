# Release Audit Summary

- Domain: `dotsai.in`
- Old domain: `zeroonedotsai.consulting`
- Generated: `2026-03-26-083115`
- Output: `qa/2026-03-26-083115-dotsai.in-gate`

## High-level checks

- Homepage status: `200`
- Missing URL status: `200`
- Old domain terminal status: `200`
- www terminal status: `200`
- Homepage X-Robots-Tag: `none`
- Homepage canonical: `https://zeroonedotsai.consulting/`
- robots.txt sitemap line: `Sitemap: https://zeroonedotsai.consulting/sitemap.xml`
- Foreign sitemap URL count: `33`

## Release signals

- PASS: homepage returns 200
- FAIL: missing URL does not return 404/410
- PASS: production homepage is not sending noindex
- FAIL: homepage canonical is missing or points elsewhere
- FAIL: robots.txt sitemap line is missing or points elsewhere
- FAIL: sitemap includes URLs outside dotsai.in

- INFO: database snapshots skipped because ANALYTICS_DATABASE_URL was not set or psql was unavailable

## Manual follow-up

- run the full checklist in `research/08-launch-readiness-checklist.md`
- run the full QA matrix in `research/09-qa-validation-matrix.md`
- capture screenshots, Search Console evidence, and form traces into this release folder
