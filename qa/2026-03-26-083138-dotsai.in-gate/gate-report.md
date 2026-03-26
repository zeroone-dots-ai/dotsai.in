# Release Gate Report

- Domain: `dotsai.in`
- Generated: `2026-03-26-083139`
- P0 failures: `4`
- P1 failures: `0`
- P1 threshold: `5`

## Checks

- [pass] P0 Homepage returns 200 | expected: `200` | actual: `200`
- [fail] P0 Missing URL returns 404 or 410 | expected: `404 or 410` | actual: `200`
- [pass] P0 Homepage is not noindex | expected: `no noindex header` | actual: `none`
- [fail] P0 Homepage canonical points to primary domain | expected: `https://dotsai.in/` | actual: `https://zeroonedotsai.consulting/`
- [fail] P0 robots.txt points to primary sitemap | expected: `sitemap on dotsai.in` | actual: `https://zeroonedotsai.consulting/sitemap.xml`
- [fail] P0 Sitemap contains only primary-domain URLs | expected: `0 foreign URLs` | actual: `33 foreign URLs`
- [pass] P1 Legacy domain resolves cleanly | expected: `final public target on dotsai.in` | actual: `200`
- [pass] P1 www host resolves cleanly | expected: `final public target on dotsai.in` | actual: `200`
