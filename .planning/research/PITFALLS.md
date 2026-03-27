# Domain Pitfalls

**Domain:** Self-hosted Cal.com + FastAPI analytics + PostgreSQL on existing production VPS
**Researched:** 2026-03-27
**Scope:** Adding new services to 72.62.229.16 without breaking live dotsai.in

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or production outages.

---

### Pitfall 1: Cal.com URL Stuck at localhost:3000

**What goes wrong:** Cal.com renders all internal links, OAuth redirects, and email confirmation URLs as `http://localhost:3000/...` even after deploying to `cal.dotsai.in`. Bookings appear to work but confirmation emails contain dead links. Google Calendar OAuth callback points to localhost and silently fails.

**Why it happens:** `NEXT_PUBLIC_WEBAPP_URL` is a **build-time** variable baked into the Next.js bundle at image build time. If the container is pulled from Docker Hub without rebuilding (or is pulled pre-built), the embedded URL is whatever was set at build time — typically localhost. Setting it in `.env` at runtime does not override build-time values already compiled into the JS bundle.

**Consequences:** OAuth login loops. Booking confirmation emails are broken. Google Calendar won't connect. Entire Cal.com setup is non-functional despite the UI appearing to load.

**Prevention:**
1. Never use the pre-built `calcom/cal.com` Docker Hub image for production — it was built with localhost URLs.
2. Either build the image locally with correct env vars, or use the official Docker self-host repo (`github.com/calcom/docker`) which supports providing build args.
3. Required build-time args: `NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in`, `NEXT_PUBLIC_LICENSE_CONSENT=agree`.
4. Runtime-only vars (safe to set in `.env`): `NEXTAUTH_SECRET`, `DATABASE_URL`, `NEXTAUTH_URL`.
5. For the NEXTAUTH loopback issue inside containers: set `NEXTAUTH_URL=http://localhost:3000/api/auth` for internal auth callbacks, while `NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in` handles the public URL.

**Detection:**
- Open Cal.com UI → inspect any link href — does it show `localhost:3000`?
- Try booking a test event → check whether confirmation email link is reachable.
- Run: `docker exec <calcom-container> env | grep WEBAPP_URL`

**Phase:** Cal.com Docker setup (Phase 1).

**Confidence:** HIGH — documented in official Cal.com docs and reproduced across 20+ GitHub issues (#3704, #8501, #21921, #136).

---

### Pitfall 2: Cal.com Docker Conflicts with Existing nginx on Port 80/443

**What goes wrong:** The default `calcom/docker` compose file binds port 80 and 443 on the host. Since the VPS already runs nginx in Docker serving dotsai.in on those ports, `docker-compose up` for Cal.com fails immediately with `Bind for 0.0.0.0:80 failed: port is already allocated`.

**Why it happens:** Two Docker services cannot bind the same host port. The existing nginx container owns 80/443.

**Consequences:** Cal.com never starts. Attempting to fix it by stopping the existing nginx takes dotsai.in offline.

**Prevention:**
1. Do **not** expose Cal.com on host ports 80/443 directly.
2. Run Cal.com on an internal Docker network with no public port exposure (e.g., internal port 3000 only, no `ports:` mapping).
3. Add a new `server {}` block to the **existing** nginx config to proxy `cal.dotsai.in` → `http://calcom:3000`.
4. Use Docker network bridge: put Cal.com container on the same Docker network as nginx so nginx can reach it by container name.
5. Reload nginx (`docker exec nginx nginx -s reload`) — zero downtime.

**Detection:**
- Before deploying Cal.com: `docker ps | grep -E "0.0.0.0:80|0.0.0.0:443"` — if anything is listed, that container owns those ports.
- Do not attempt `docker-compose up` for Cal.com until its compose file has no host port 80/443 bindings.

**Phase:** Cal.com Docker setup (Phase 1).

**Confidence:** HIGH — standard Docker port conflict behavior, confirmed by multiple community discussions.

---

### Pitfall 3: PostgreSQL Data Loss on docker-compose down

**What goes wrong:** `docker-compose down` removes containers **and** (depending on compose version) can remove volumes. If PostgreSQL data is stored inside the container (no explicit volume mount), all analytics data and Cal.com database records are permanently lost on any container restart, upgrade, or down command.

**Why it happens:** Docker containers are ephemeral. Data inside `/var/lib/postgresql/data` only persists if mounted to a named volume or host bind mount. Engineers routinely run `docker-compose down` during debugging without realizing it destroys state.

**Consequences:** Complete data loss. All analytics history gone. Cal.com loses all event types, bookings, and user accounts. No recovery possible without backups.

**Prevention:**
1. Always declare a named volume or host bind mount in `docker-compose.yml` for PostgreSQL:
   ```yaml
   volumes:
     - pgdata:/var/lib/postgresql/data
   volumes:
     pgdata:
   ```
2. Never use `docker-compose down -v` (the `-v` flag explicitly removes volumes — never run this in production).
3. Use `docker-compose stop` (stops containers, preserves volumes) rather than `docker-compose down` when debugging.
4. Verify data persistence: after `docker-compose stop && docker-compose start`, confirm PostgreSQL data survived.

**Detection:**
- Check compose file: `grep -A5 postgres docker-compose.yml` — if no `volumes:` under the postgres service, data is not persisted.
- Warning sign: postgres container recreates itself on every restart with zero tables.

**Phase:** PostgreSQL setup (Phase 0 — before anything else).

**Confidence:** HIGH — documented in Docker official docs and multiple community reports.

---

### Pitfall 4: VPS RAM Exhaustion Causing OOM Kills

**What goes wrong:** Cal.com (Next.js) is memory-hungry, especially during startup and after fresh builds. On a 2GB VPS, running Cal.com + PostgreSQL + FastAPI + nginx simultaneously may exhaust RAM. The Linux OOM (Out of Memory) killer picks a process to kill — typically the largest RSS consumer, which is Cal.com — causing silent crashes with no error logs visible in the app.

**Why it happens:** Cal.com Node.js process can consume 500MB–1.5GB at runtime. PostgreSQL adds 100–300MB depending on shared_buffers. FastAPI adds ~80MB. If VPS has 2GB total RAM, headroom disappears during traffic bursts.

**Consequences:** Cal.com silently dies. Bookings stop working. `docker ps` shows container exited. No useful error in Cal.com logs — OOM kills leave no application-level trace.

**Prevention:**
1. Before deploying, check VPS RAM: `free -h` — if less than 3GB available, expect problems.
2. Set PostgreSQL `shared_buffers` conservatively: `shared_buffers=128MB` (default 128MB is fine on 2–4GB VPS; do not increase).
3. Set Node.js memory cap: `NODE_OPTIONS="--max-old-space-size=512"` in Cal.com container env to prevent unbounded growth.
4. Add 2GB swap if not already present — prevents hard OOM kills during bursts: `fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile`.
5. Monitor: `watch -n 5 'free -h && docker stats --no-stream'` during first 48 hours.

**Detection:**
- `dmesg | grep -i 'oom\|killed'` — shows OOM kill events.
- `docker inspect <container> | grep OOMKilled` → `true` confirms OOM death.
- Warning sign: Cal.com container exits with code 137 (SIGKILL).

**Phase:** Pre-deployment infrastructure check (Phase 0).

**Confidence:** MEDIUM — RAM figures from community testing on 4GB VPS; 2GB boundary is extrapolated from documented build requirement (4GB for build) vs runtime needs. Verify actual VPS RAM before deployment.

---

### Pitfall 5: SSL Certificate Issuance Fails for New Subdomains

**What goes wrong:** When requesting Let's Encrypt certificates for `cal.dotsai.in` and `api.dotsai.in`, certbot's HTTP-01 challenge requires the domain to resolve to the VPS and serve a file from `/.well-known/acme-challenge/`. If nginx is not configured to serve that path before cert issuance, the challenge fails with a 404 or connection refused. After 5 failed attempts, Let's Encrypt applies a rate limit (5 failures per hostname per hour).

**Why it happens:** Nginx only serves the challenge path if it has a server block for the subdomain. But you can't configure SSL in nginx until you have the certificate. Classic chicken-and-egg problem if approached incorrectly.

**Consequences:** Certificate issuance blocked for up to 1 hour. If testing repeatedly with the production endpoint, you can hit the weekly rate limit (5 duplicate certificates per 7 days), locking you out for a week.

**Prevention:**
1. Always use `certbot --staging` flag for all testing until confident the configuration is correct. Staging has no rate limits.
2. Create the nginx server block for the new subdomain with HTTP-only first (port 80, no SSL), including the `/.well-known/acme-challenge/` location.
3. Only request the certificate after confirming the domain resolves: `curl http://cal.dotsai.in/.well-known/acme-challenge/test` (should return 404, not connection refused).
4. After cert issuance, update the nginx block to add HTTPS (port 443) and redirect port 80 to HTTPS.
5. DNS must propagate before cert request — verify with `dig cal.dotsai.in` showing VPS IP before running certbot.

**Detection:**
- Warning sign: certbot reports `Connection refused` or `404` during challenge.
- Check rate limit status: `certbot certificates` — shows expiry and renewal status.
- Do not run certbot more than twice per subdomain without investigating failures.

**Phase:** Subdomain + SSL setup (Phase 1).

**Confidence:** HIGH — standard Let's Encrypt behavior, documented in official certbot docs and Let's Encrypt community.

---

### Pitfall 6: Analytics API Key Exposed in Browser JavaScript

**What goes wrong:** The analytics API at `api.dotsai.in` needs an API key so only dotsai.in and zeroonedotsai.consulting can write events — not arbitrary spammers. If the API key is hardcoded in the browser-side JS of `index.html`, it is trivially visible to anyone who opens DevTools → Network tab → inspects the request headers. Attacker can then spam the analytics endpoint directly, polluting the database.

**Why it happens:** Browser JS is fully visible to end users. Any value embedded in JS is public, regardless of how it is named or obfuscated.

**Consequences:** Polluted analytics data. If the FastAPI endpoint is also used to read data or trigger actions, complete API access is compromised. Rate limiting helps but doesn't prevent an API key with known value from being abused.

**Prevention:**
1. Accept that write-only analytics endpoints from browser JS cannot be fully secret — design for it rather than fighting it.
2. Use a **write-only, per-site API key** scoped to a single action (`POST /events`). This key cannot read data, cannot delete data.
3. Enforce **CORS** in FastAPI to only accept requests from `https://dotsai.in` and `https://zeroonedotsai.consulting` — even with the key, other origins get blocked.
4. Add **rate limiting**: maximum 60 events per IP per minute using `slowapi` or `fastapi-limiter` with Redis or in-memory store.
5. Validate the `Referer` header as a secondary check (easy to spoof but adds friction).
6. Log anomalies: if >100 events from a single IP in 60 seconds, write a warning log and silently accept (don't 429 — legitimate users shouldn't notice).
7. Do **not** store the API key in git. Pass it as a Docker environment variable.

**Detection:**
- Open `dotsai.in` → DevTools → Network → filter by `api.dotsai.in` → inspect request headers.
- If the key is visible in plain text in the Authorization header, it is compromised by design.
- Check PostgreSQL for unusual event volumes: `SELECT COUNT(*), ip FROM events WHERE created_at > NOW() - INTERVAL '1 hour' GROUP BY ip ORDER BY COUNT DESC LIMIT 10;`

**Phase:** Analytics API development (Phase 2).

**Confidence:** HIGH — standard browser security model, verified against FastAPI security docs.

---

### Pitfall 7: CORS Misconfiguration Blocks zeroonedotsai.consulting

**What goes wrong:** `zeroonedotsai.consulting` is hosted on Cloudflare Pages — its origin is `https://zeroonedotsai.consulting`. The FastAPI analytics API at `api.dotsai.in` must explicitly allow this origin. If CORS is set to only allow `https://dotsai.in`, all analytics calls from zeroonedotsai.consulting fail silently in the browser (CORS errors do not surface to users, only DevTools).

**Why it happens:** CORS is enforced by the browser. The FastAPI `CORSMiddleware` must list every origin that makes cross-origin requests. Subdomains do not inherit parent domain CORS settings.

**Consequences:** zeroonedotsai.consulting events never reach PostgreSQL. Silent data gap — you won't know until you check logs and notice zero Consulting site events.

**Prevention:**
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://dotsai.in",
        "https://zeroonedotsai.consulting",
        "https://www.zeroonedotsai.consulting",  # include www variant
    ],
    allow_credentials=False,  # analytics doesn't need cookies
    allow_methods=["POST", "OPTIONS"],  # write-only
    allow_headers=["Authorization", "Content-Type"],
)
```
2. CORSMiddleware must be added **before** any other middleware in FastAPI — order matters.
3. Test CORS explicitly from the actual deployed domains, not localhost, before calling it done.

**Detection:**
- Browser DevTools Console on zeroonedotsai.consulting → should show no CORS errors.
- `curl -H "Origin: https://zeroonedotsai.consulting" -I https://api.dotsai.in/events` — response must include `Access-Control-Allow-Origin: https://zeroonedotsai.consulting`.

**Phase:** Analytics API development (Phase 2).

**Confidence:** HIGH — documented FastAPI CORS behavior, verified against official FastAPI docs.

---

## Moderate Pitfalls

### Pitfall 8: Cal.com Email Sending Silently Broken

**What goes wrong:** Cal.com books meetings but sends no confirmation emails. The booking appears successful in the UI but attendees receive nothing. This goes unnoticed until a real client misses a meeting.

**Why it happens:** Cal.com requires SMTP configuration via environment variables (`EMAIL_SERVER_HOST`, `EMAIL_SERVER_PORT`, `EMAIL_SERVER_USER`, `EMAIL_SERVER_PASSWORD`, `EMAIL_FROM`). If these are not set, Cal.com silently skips email sending — no error in the UI, no loud failure.

**Prevention:**
1. Configure SMTP env vars before going live. Free options: Resend (3000 emails/month free), Brevo, or Google Workspace SMTP.
2. After setup, create a test booking on cal.dotsai.in and verify the confirmation email arrives.
3. Check Cal.com container logs for email errors: `docker logs calcom | grep -i email`.
4. Required variables:
   ```
   EMAIL_SERVER_HOST=smtp.resend.com
   EMAIL_SERVER_PORT=465
   EMAIL_SERVER_USER=resend
   EMAIL_SERVER_PASSWORD=<api-key>
   EMAIL_FROM=noreply@dotsai.in
   ```

**Detection:** Make a test booking → wait 60 seconds → if no email, email is broken. Check `docker logs calcom --tail 50 | grep -i mail`.

**Phase:** Cal.com setup and smoke test (Phase 1).

**Confidence:** MEDIUM — documented in Cal.com GitHub issues #10592, #19068; SMTP variables verified in official install docs.

---

### Pitfall 9: Cal.com Google Calendar OAuth Requires HTTPS Throughout

**What goes wrong:** Google Calendar integration fails with `invalid_client` or `redirect_uri_mismatch` if any part of the OAuth flow uses HTTP instead of HTTPS. Google enforces that all redirect URIs in the OAuth client must exactly match the URL Cal.com uses, including protocol.

**Why it happens:** If nginx is terminating SSL but not forwarding the `X-Forwarded-Proto: https` header, Cal.com sees the internal request as HTTP and generates HTTP callback URLs. Google rejects them.

**Prevention:**
1. Add to nginx proxy config for cal.dotsai.in:
   ```nginx
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header Host $host;
   ```
2. Add to Cal.com environment: `NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in` (must be HTTPS, no trailing slash).
3. In Google Cloud Console, authorized redirect URIs must be:
   - `https://cal.dotsai.in/api/integrations/googlecalendar/callback`
   - `https://cal.dotsai.in/api/auth/callback/google`
4. The app must be in "Production" mode in Google Cloud Console or OAuth tokens expire every 7 days (testing mode limitation).

**Detection:** Try connecting Google Calendar in Cal.com settings — if it redirects to an error page or loops back to Cal.com login, check nginx headers and NEXTAUTH_URL.

**Phase:** Cal.com Google Calendar integration (Phase 1 post-setup).

**Confidence:** MEDIUM — documented in Cal.com discussion #8322 and issue #25476.

---

### Pitfall 10: PostgreSQL Migration State Desync on Cal.com Upgrades

**What goes wrong:** When Cal.com is upgraded to a new version, the Docker entrypoint runs `prisma migrate deploy`. If the `_prisma_migrations` table in PostgreSQL is out of sync with the migration files in the new image (can happen if a previous migration partially failed), Prisma refuses to apply new migrations. Cal.com starts but database schema is stale — features silently broken.

**Why it happens:** Prisma tracks applied migrations in a metadata table. If a migration ran partially (container killed mid-migration), the record shows "applied" but the schema is incomplete. Future `migrate deploy` skips it, leaving a schema mismatch.

**Prevention:**
1. Always back up PostgreSQL before any Cal.com version upgrade: `docker exec postgres pg_dump -U calcom calcom > backup_pre_upgrade_$(date +%Y%m%d).sql`.
2. Monitor migration output during container startup: `docker logs calcom 2>&1 | grep -i migrat`.
3. If migration fails: `docker exec calcom yarn workspace @calcom/prisma db-deploy` — check the output for failed migration names.
4. Fix desync with: `docker exec calcom yarn prisma migrate resolve --applied <migration_name>`.
5. Pin Cal.com to a specific version tag in docker-compose (`image: calcom/cal.com:v5.x.x`) — do not use `latest` in production.

**Detection:** After Cal.com upgrade, create a new booking type and check if it saves correctly. Failed migrations often manifest as 500 errors on specific actions, not global failures.

**Phase:** Cal.com ongoing maintenance; initial awareness during setup.

**Confidence:** MEDIUM — documented in Cal.com database migrations docs and issue #2398.

---

### Pitfall 11: Analytics Data Gaps from Browser Beacon Failures

**What goes wrong:** Browser-side analytics JS fires a `fetch()` to `api.dotsai.in`. If the request fails (network error, server overloaded, timeout), the event is silently dropped. No retry logic. Page views and CTA clicks are permanently lost. Data shows lower engagement than reality.

**Why it happens:** Browser JS `fetch()` does not retry on failure. The page may navigate away before any retry can be attempted. `navigator.sendBeacon()` is fire-and-forget with no response handling.

**Prevention:**
1. Use `navigator.sendBeacon()` for page unload events — it survives page navigation but gives no feedback.
2. For click events and important CTA events, use `fetch()` with a short timeout (2s) and silent error catch — never let analytics errors affect the user experience.
3. Keep the analytics payload small (< 64KB) to stay within beacon limits.
4. Accept ~2–5% event loss as normal for browser-side analytics — do not over-engineer.
5. On the FastAPI side, use async handlers so slow DB writes do not delay HTTP 200 responses to the browser:
   ```python
   @app.post("/events", status_code=202)
   async def record_event(event: EventSchema, background_tasks: BackgroundTasks):
       background_tasks.add_task(write_to_db, event)
       return {"status": "accepted"}
   ```

**Detection:** Compare event count in PostgreSQL to approximate page view count from server nginx logs. If divergence > 10%, there is a systemic drop issue.

**Phase:** Analytics API development (Phase 2).

**Confidence:** MEDIUM — browser analytics behavior well-documented; FastAPI background tasks pattern verified in official FastAPI docs.

---

### Pitfall 12: PostgreSQL Backups Not Tested = No Backup

**What goes wrong:** A cron job runs `pg_dump` nightly. At some point, the cron silently fails (Docker container name changed, password wrong, disk full). Weeks pass. A destructive mistake happens. The "backup" is actually months old or nonexistent.

**Why it happens:** Backup scripts are written once and never checked again. Errors in cron jobs are not surfaced unless log monitoring is in place.

**Prevention:**
1. Schedule automated backups with a cron job inside the postgres container or from the host:
   ```bash
   # Host cron — runs at 2AM daily
   0 2 * * * docker exec postgres pg_dump -U calcom calcom | gzip > /opt/backups/pg_$(date +\%Y\%m\%d).sql.gz
   ```
2. Keep 7 daily backups, then prune: `find /opt/backups/ -name "pg_*.sql.gz" -mtime +7 -delete`
3. Test restore monthly: `gunzip -c backup.sql.gz | docker exec -i postgres psql -U calcom calcom`
4. Monitor backup file age: if newest file is > 25 hours old, alert (Telegram message via existing webhook).

**Detection:** `ls -lh /opt/backups/ | tail -5` — check dates. If last backup is > 1 day old, backup is broken.

**Phase:** PostgreSQL setup (Phase 0 — configure before adding data).

**Confidence:** HIGH — universal database operations knowledge; backup failure pattern documented across multiple PostgreSQL and Docker guides.

---

## Minor Pitfalls

### Pitfall 13: Cal.com NEXTAUTH_SECRET Not Random Enough

**What goes wrong:** If `NEXTAUTH_SECRET` is set to a short, guessable, or hardcoded string (e.g., `mysecret`, copied from a tutorial), session tokens can be forged. An attacker can authenticate as any Cal.com user.

**Prevention:** Generate with `openssl rand -base64 32` — use the output as-is. Do the same for `CALENDSO_ENCRYPTION_KEY`. Store in a `.env` file that is never committed to git (verify `.gitignore` includes `.env`).

**Phase:** Cal.com Docker setup (Phase 1).

**Confidence:** HIGH.

---

### Pitfall 14: Docker Compose Postgres Port Exposed to Internet

**What goes wrong:** If the PostgreSQL service in `docker-compose.yml` maps port 5432 to the host (`"5432:5432"`), the database is accessible from the internet. Anyone can attempt to brute-force credentials directly.

**Prevention:** Do **not** add `ports:` to the PostgreSQL service in docker-compose. FastAPI and Cal.com reach it via Docker internal network. Only expose PostgreSQL locally when needed for queries: `docker exec -it postgres psql -U calcom`.

**Detection:** `nmap -p 5432 72.62.229.16` from outside the VPS — if port is open, it is exposed.

**Phase:** PostgreSQL setup (Phase 0).

**Confidence:** HIGH.

---

### Pitfall 15: Nginx Config Syntax Error Takes Down All Sites

**What goes wrong:** Adding a new `server {}` block for `cal.dotsai.in` or `api.dotsai.in` with a typo causes `nginx -t` to fail. Reloading nginx propagates the bad config. All sites (dotsai.in, cal.dotsai.in, etc.) return 502 simultaneously.

**Prevention:**
1. Always test before reloading: `docker exec nginx nginx -t` — must return "syntax is ok".
2. Only reload (never restart) when adding configs: `docker exec nginx nginx -s reload` — gracefully drains connections.
3. Keep each subdomain in a separate `.conf` file under `conf.d/` so a broken new config can be removed without touching existing configs.

**Detection:** After any nginx config change, `curl -sk https://dotsai.in | grep '<title>'` — if it returns nothing, nginx is broken.

**Phase:** Subdomain setup (Phase 1).

**Confidence:** HIGH.

---

### Pitfall 16: Cal.com Uses `latest` Tag and Auto-Upgrades Unexpectedly

**What goes wrong:** Using `image: calcom/cal.com:latest` in docker-compose means the next `docker-compose pull` fetches a new version. If the new version has breaking schema changes, running `docker-compose up` can run a breaking migration against production data.

**Prevention:** Pin to a specific version: `image: calcom/cal.com:v5.6.19`. Upgrade intentionally, with a pre-upgrade database backup.

**Phase:** Cal.com Docker setup (Phase 1).

**Confidence:** HIGH — standard Docker versioning discipline.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| VPS pre-check | RAM < 3GB will cause OOM kills | Check `free -h` first; add swap before deploying |
| PostgreSQL setup | No volume → data loss on container restart | Declare named volume before first `up` |
| PostgreSQL setup | Port 5432 exposed to internet | Never add `ports:` to postgres service |
| Cal.com Docker | Port 80/443 conflict with existing nginx | Run Cal.com on internal Docker network only |
| Cal.com Docker | Build-time WEBAPP_URL wrong | Build image with correct args, not pull from Hub |
| Cal.com Docker | NEXTAUTH_SECRET weak or missing | Generate with `openssl rand -base64 32` |
| Cal.com setup | No email = silent booking failures | Configure SMTP before first real booking |
| Subdomain SSL | Challenge fails → rate limited | Use `--staging` flag for all test cert requests |
| Subdomain SSL | DNS not propagated before certbot | Verify `dig cal.dotsai.in` shows VPS IP first |
| Nginx config | Syntax error takes down all sites | Always `nginx -t` before `nginx -s reload` |
| Analytics API | API key visible in browser JS | Design as write-only scoped key + CORS + rate limit |
| Analytics API | CORS missing zeroonedotsai.consulting | Explicitly list both origins in CORSMiddleware |
| Analytics API | Slow DB writes delay responses | Use FastAPI BackgroundTasks for async DB writes |
| Cal.com Google OAuth | HTTP redirect URI rejected | Set `X-Forwarded-Proto` header in nginx |
| Cal.com upgrade | Migration desync | Backup before upgrade; pin version tag |
| PostgreSQL backup | Silent backup failure | Monitor backup file age; test restore monthly |

---

## Sources

- Cal.com official Docker docs: https://cal.com/docs/self-hosting/docker (HIGH confidence)
- Cal.com database migrations docs: https://cal.com/docs/self-hosting/database-migrations (HIGH confidence)
- Cal.com GitHub issue #3704 — localhost URL bug: https://github.com/calcom/cal.com/discussions/3704 (HIGH confidence — 50+ reports)
- Cal.com GitHub issue #8501 — localhost URL stuck: https://github.com/calcom/cal.com/issues/8501 (HIGH confidence)
- Cal.com GitHub issue #21921 — localhost redirect: https://github.com/calcom/cal.com/issues/21921 (HIGH confidence)
- Cal.com docker repo discussion #302 — RAM requirements: https://github.com/calcom/docker/discussions/302 (MEDIUM confidence)
- Cal.com Google OAuth issue #25476: https://github.com/calcom/cal.com/issues/25476 (MEDIUM confidence)
- Cal.com email issue #10592: https://github.com/calcom/cal.com/issues/10592 (MEDIUM confidence)
- FastAPI CORS official docs: https://fastapi.tiangolo.com/tutorial/cors/ (HIGH confidence)
- FastAPI security official docs: https://fastapi.tiangolo.com/tutorial/security/first-steps/ (HIGH confidence)
- PostgreSQL Docker backup guide: https://dev.to/dmdboi/automated-postgresql-backups-in-docker-complete-guide-with-pgdump-52a (MEDIUM confidence)
- Docker PostgreSQL data loss pattern: https://dev.to/ndohjapan/how-to-prevent-data-loss-when-a-postgres-container-is-killed-or-shut-down-p8d (MEDIUM confidence)
- Let's Encrypt certbot + nginx Docker: https://community.letsencrypt.org/t/nginx-and-certbot-with-docker/214552 (MEDIUM confidence)
- Let's Encrypt rate limits 2025: https://blog.miguelgrinberg.com/post/using-free-let-s-encrypt-ssl-certificates-in-2025 (MEDIUM confidence)
