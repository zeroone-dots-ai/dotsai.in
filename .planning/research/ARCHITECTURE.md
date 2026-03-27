# Architecture Patterns — VPS Multi-Service Stack

**Domain:** Cal.com + PostgreSQL + FastAPI analytics on a single VPS behind nginx
**Researched:** 2026-03-27
**Overall confidence:** HIGH (Docker/nginx patterns), MEDIUM (Cal.com build-time var caveat)

---

## Situation

- **Existing:** nginx in Docker on ports 80/443, serving dotsai.in static files and other subdomains
- **Adding:** PostgreSQL (internal only), Cal.com (cal.dotsai.in), FastAPI analytics API (api.dotsai.in)
- **Analytics sources:** browser JS on dotsai.in AND zeroonedotsai.consulting → api.dotsai.in/events
- **Booking bridge:** Cal.com webhook → api.dotsai.in/webhooks/calcom → PostgreSQL

---

## System Diagram

```
Internet
  │
  ├─ HTTPS → nginx (Docker, port 443)
  │              │
  │              ├─ cal.dotsai.in       → proxy_pass → calcom:3000
  │              ├─ api.dotsai.in       → proxy_pass → analytics:8000
  │              └─ dotsai.in           → /opt/nginx/html/dotsai.in (static, existing)
  │
  └─ (internal Docker network: vps-net)
         ├─ postgres:5432       ← only calcom + analytics can reach this
         ├─ calcom:3000         ← only nginx can reach this externally
         └─ analytics:8000      ← only nginx can reach this externally

Browser (dotsai.in or zeroonedotsai.consulting)
  └─ fetch("https://api.dotsai.in/events", { headers: { Authorization: "Bearer <token>" } })
        └─ nginx → analytics:8000 → postgres
```

---

## Docker Compose Structure

**Recommendation:** Single `docker-compose.yml` that extends the existing nginx service. Do NOT run a separate Compose file — add services to the existing one so all containers share one network.

```yaml
# /opt/services/docker-compose.yml  (extends existing nginx block)

version: "3.9"

networks:
  vps-net:
    driver: bridge
    # Give it an explicit name so nginx can resolve service names via Docker DNS
    name: vps-net

volumes:
  postgres_data:
  calcom_data:
  pg_backups:

services:

  # ─── EXISTING (keep as-is, add network) ───────────────────────────────────
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/services/nginx/html:/usr/share/nginx/html:ro
      - /opt/services/nginx/conf.d:/etc/nginx/conf.d:ro
      - /opt/services/nginx/certs:/etc/letsencrypt:ro
    networks:
      - vps-net
    restart: unless-stopped

  # ─── NEW: PostgreSQL ───────────────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-dotsai}       # single DB, multiple schemas
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB:-dotsai}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - vps-net
    restart: unless-stopped
    # NOT exposed externally — no ports: mapping

  # ─── NEW: Cal.com ──────────────────────────────────────────────────────────
  calcom:
    image: calcom/cal.com:latest
    container_name: calcom
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-dotsai}?schema=calcom
      NEXTAUTH_SECRET: ${CALCOM_NEXTAUTH_SECRET}
      NEXTAUTH_URL: https://cal.dotsai.in/api/auth
      NEXT_PUBLIC_WEBAPP_URL: https://cal.dotsai.in
      NEXT_PUBLIC_API_V2_URL: https://cal.dotsai.in/api/v2
      CALENDSO_ENCRYPTION_KEY: ${CALCOM_ENCRYPTION_KEY}
      NEXT_PUBLIC_LICENSE_CONSENT: agree
      CALCOM_TELEMETRY_DISABLED: 1
      # Tell Cal.com it's behind an SSL-terminating reverse proxy
      NODE_TLS_REJECT_UNAUTHORIZED: 0
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - vps-net
    restart: unless-stopped
    # NOT exposed externally — nginx proxies to calcom:3000 on vps-net

  # ─── NEW: FastAPI Analytics ────────────────────────────────────────────────
  analytics:
    image: dotsai-analytics:latest      # build locally, see Dockerfile below
    container_name: analytics
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-dotsai}
      ANALYTICS_API_KEY: ${ANALYTICS_API_KEY}
      CALCOM_WEBHOOK_SECRET: ${CALCOM_WEBHOOK_SECRET}
      ALLOWED_ORIGINS: "https://dotsai.in,https://zeroonedotsai.consulting"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - vps-net
    restart: unless-stopped
    # NOT exposed externally

  # ─── NEW: Backup sidecar ───────────────────────────────────────────────────
  pg-backup:
    image: prodrigestivill/postgres-backup-local:16
    container_name: pg-backup
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-dotsai}
      SCHEDULE: "@daily"
      BACKUP_KEEP_DAYS: 7
      BACKUP_KEEP_WEEKS: 4
      HEALTHCHECK_PORT: 8080
    volumes:
      - pg_backups:/backups
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - vps-net
    restart: unless-stopped
```

**Why single DB, multiple schemas:** Cal.com requires PostgreSQL and will run Prisma migrations on startup. Keeping it in its own schema (`?schema=calcom` in the DATABASE_URL) isolates it from the analytics schema while using one Postgres instance. This reduces VPS resource usage and simplifies backup.

---

## Build Order (dependency chain)

```
1. postgres        → must be healthy before anything else starts
2. analytics       → depends_on: postgres (healthcheck)
3. calcom          → depends_on: postgres (healthcheck)
4. pg-backup       → depends_on: postgres (healthcheck)
5. nginx           → starts independently, but proxy_pass targets must be up
                     (nginx will 502 until calcom/analytics are ready — acceptable)
```

**Do this first on the VPS:**
1. Add `postgres` service and bring it up in isolation — verify pg_isready
2. Add `analytics` service, run Alembic migrations, test `/health` via curl on the internal network
3. Add `calcom` — this takes 2-5 minutes on first start (Prisma migrations)
4. Update nginx configs for cal.dotsai.in and api.dotsai.in
5. Add pg-backup last

---

## nginx Reverse Proxy Configs

### Critical nginx finding: Docker DNS resolver

nginx by default does NOT use Docker's internal DNS (127.0.0.11). Without the `resolver` directive, `proxy_pass http://calcom:3000` will fail at container restart. Always add `resolver 127.0.0.11 valid=10s ipv6=off;` inside the server block.

### cal.dotsai.in (Cal.com)

```nginx
# /opt/services/nginx/conf.d/cal.dotsai.in.conf

map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name cal.dotsai.in;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name cal.dotsai.in;

    ssl_certificate     /etc/letsencrypt/live/cal.dotsai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cal.dotsai.in/privkey.pem;

    # Required: Docker DNS resolver for proxy_pass to container names
    resolver 127.0.0.11 valid=10s ipv6=off;

    location / {
        proxy_pass http://calcom:3000;

        # Required for Next.js / Cal.com
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Cal.com can be slow to respond on first load
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        proxy_connect_timeout 10s;

        # Buffer settings for Next.js streaming
        proxy_buffering off;
    }
}
```

**Cal.com-specific notes:**
- `proxy_buffering off` prevents issues with Next.js SSR streaming responses
- WebSocket headers (`Upgrade`/`Connection`) are required — Cal.com uses WebSockets for real-time features
- `proxy_read_timeout 300s` — Cal.com cold starts on initial request can hit 60s+ timeout with default settings
- `NEXTAUTH_URL` must be `https://cal.dotsai.in/api/auth` (NOT just the domain root)
- **Build-time caveat (MEDIUM confidence):** The official calcom/cal.com Docker image has `NEXT_PUBLIC_WEBAPP_URL` baked in at build time as a Next.js `NEXT_PUBLIC_*` variable. The container will attempt to patch static files at startup when the runtime value differs from the build-time default (localhost:3000). This patching works but adds startup delay. For a stable production setup, build a custom image: `docker build --build-arg NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in .`

### api.dotsai.in (FastAPI Analytics)

```nginx
# /opt/services/nginx/conf.d/api.dotsai.in.conf

server {
    listen 80;
    server_name api.dotsai.in;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.dotsai.in;

    ssl_certificate     /etc/letsencrypt/live/api.dotsai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.dotsai.in/privkey.pem;

    resolver 127.0.0.11 valid=10s ipv6=off;

    location / {
        proxy_pass http://analytics:8000;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 30s;

        # FastAPI handles CORS itself — do NOT add CORS headers in nginx
        # Duplicate CORS headers from nginx + FastAPI cause browser rejections
    }
}
```

**Do NOT put CORS headers in nginx for the analytics service.** FastAPI's CORSMiddleware handles preflight OPTIONS requests by returning the correct `Access-Control-Allow-Origin` header. If nginx also adds these headers, the browser sees them duplicated and rejects the response.

---

## FastAPI Analytics API

### CORS Configuration (correct pattern)

```python
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI()

# CORSMiddleware MUST be first middleware added
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://dotsai.in",
        "https://www.dotsai.in",
        "https://zeroonedotsai.consulting",
        "https://www.zeroonedotsai.consulting",
    ],
    allow_credentials=False,   # False because we use Bearer token, not cookies
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
```

**Why `allow_credentials=False`:** Authentication uses a static `Authorization: Bearer <token>` header, not cookies. Setting `allow_credentials=True` with an explicit origins list is only needed for cookie-based auth. With Bearer tokens, credentials=False is correct and simpler.

### Bearer Token Auth (simple static key for MVP)

```python
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()
API_KEY = os.environ["ANALYTICS_API_KEY"]

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return credentials.credentials
```

**Why static key, not JWT:** Analytics events come from browser JS on public pages — there's no user login. A static Bearer token rotated occasionally is appropriate. JWT would add unnecessary complexity with no security benefit here.

### Endpoint Map

```
POST /events           — page view / click events from browser
POST /webhooks/calcom  — Cal.com booking events (webhook, separate auth)
GET  /health           — nginx upstream health check
GET  /metrics          — summary stats (authenticated, for internal dashboard)
```

### Cal.com Webhook Endpoint (HMAC verification)

```python
import hmac, hashlib

CALCOM_WEBHOOK_SECRET = os.environ["CALCOM_WEBHOOK_SECRET"]

@app.post("/webhooks/calcom")
async def calcom_webhook(request: Request):
    body = await request.body()
    sig = request.headers.get("x-cal-signature-256", "")

    # Verify HMAC-SHA256 signature
    expected = hmac.new(
        CALCOM_WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(sig, expected):
        raise HTTPException(status_code=401, detail="Invalid webhook signature")

    payload = json.loads(body)
    trigger = payload.get("triggerEvent")

    # Route by event type
    if trigger == "BOOKING_CREATED":
        await store_booking(payload["payload"], status="confirmed")
    elif trigger == "BOOKING_CANCELLED":
        await update_booking_status(payload["payload"]["uid"], "cancelled")
    elif trigger == "BOOKING_RESCHEDULED":
        await store_booking(payload["payload"], status="rescheduled")

    return {"ok": True}
```

**Note:** The Cal.com webhook endpoint uses its own authentication (`x-cal-signature-256`) — NOT the Bearer token. Do NOT put Bearer token auth on `/webhooks/calcom` or Cal.com's webhook delivery will fail.

---

## Database Schema

### Schema separation

Use PostgreSQL schemas to isolate Cal.com's Prisma-managed tables from analytics tables:

```sql
-- init-db.sql (runs on first postgres container start)
CREATE SCHEMA IF NOT EXISTS calcom;
CREATE SCHEMA IF NOT EXISTS analytics;
```

Cal.com's `DATABASE_URL` gets `?schema=calcom` appended — Prisma manages all tables in that schema.

Analytics tables live in the `analytics` schema, managed by Alembic.

### Analytics Tables

```sql
-- analytics.visitors
CREATE TABLE analytics.visitors (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fingerprint VARCHAR(64),          -- hashed (IP + UA + date) for daily uniqueness
    first_seen  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    country     VARCHAR(2),
    referrer    TEXT
);

-- analytics.events
CREATE TABLE analytics.events (
    id          BIGSERIAL PRIMARY KEY,
    ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    visitor_id  UUID REFERENCES analytics.visitors(id),
    site        VARCHAR(64) NOT NULL,     -- 'dotsai.in' | 'zeroonedotsai.consulting'
    page        TEXT NOT NULL,            -- URL path
    event_name  VARCHAR(128) NOT NULL,    -- 'pageview' | 'cta_click' | 'section_view'
    properties  JSONB                     -- flexible: { section: 'hero', element: 'whatsapp_cta' }
);
CREATE INDEX events_ts_idx ON analytics.events (ts DESC);
CREATE INDEX events_site_idx ON analytics.events (site, ts DESC);

-- analytics.bookings
CREATE TABLE analytics.bookings (
    id              BIGSERIAL PRIMARY KEY,
    calcom_uid      VARCHAR(128) UNIQUE NOT NULL,   -- Cal.com booking UID
    calcom_event_id INTEGER,
    status          VARCHAR(32) NOT NULL,            -- confirmed | cancelled | rescheduled
    attendee_email  VARCHAR(256),
    start_time      TIMESTAMPTZ,
    end_time        TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    raw_payload     JSONB                            -- full Cal.com webhook payload
);
```

**Why JSONB `properties` on events:** Analytics event schemas evolve frequently. A JSONB column for properties avoids constant schema migrations while preserving query capability (`properties->>'section' = 'hero'`).

**Why `raw_payload` on bookings:** Store the complete Cal.com webhook payload. Parsed fields handle reporting; raw payload handles future schema additions without a migration.

**Why NOT TimescaleDB:** At this traffic level (personal agency site), TimescaleDB's complexity and Docker image size overhead is not justified. Plain PostgreSQL with the index on `(ts DESC)` handles millions of rows comfortably. Add TimescaleDB only if query times on time-range aggregations exceed 500ms on real traffic.

### Data Retention

```sql
-- Prune events older than 365 days (run via pg_cron or a weekly cron job on the host)
DELETE FROM analytics.events WHERE ts < NOW() - INTERVAL '365 days';
```

---

## Browser-Side Analytics Pattern

From `dotsai.in` and `zeroonedotsai.consulting`, the tracking snippet:

```javascript
// Minimal analytics tracker — add to both sites
(function() {
  const API = 'https://api.dotsai.in';
  const KEY = 'Bearer <ANALYTICS_API_KEY>';   // public read-only key is fine for event ingestion

  function track(event, properties = {}) {
    fetch(API + '/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': KEY
      },
      body: JSON.stringify({
        site: location.hostname,
        page: location.pathname,
        event_name: event,
        properties
      })
    }).catch(() => {});  // fire-and-forget, never block the page
  }

  // Auto pageview on load
  track('pageview');

  // Expose for manual event tracking
  window.dotsTrack = track;
})();
```

**Security note:** The analytics API key will be visible in browser JS. This is acceptable for an event-ingestion-only endpoint. Rate-limit at nginx level (e.g., `limit_req_zone` — 10 req/s per IP) to prevent abuse.

---

## Cal.com → Analytics Webhook Bridge

```
Cal.com (Docker) → sends POST to https://cal.dotsai.in/api/webhooks/...

Wait — this routes through the PUBLIC internet (dotsai.in → nginx → calcom → nginx → analytics)
```

**Recommendation: Use the internal network instead.**

Configure the Cal.com webhook URL as `http://analytics:8000/webhooks/calcom` — since both containers are on `vps-net`, Cal.com can POST directly to the analytics container without leaving the VPS. This avoids the latency and SSL overhead of routing through nginx.

To do this: in Cal.com's admin interface under Settings → Webhooks, set the Subscriber URL to `http://analytics:8000/webhooks/calcom`.

**Caveat:** If Cal.com uses DNS resolution at the OS level inside its container, `analytics` resolves because Docker's embedded DNS handles service-name resolution on user-defined networks. Test with `docker exec calcom curl http://analytics:8000/health` after both are running.

---

## nginx Rate Limiting (add to nginx.conf http block)

```nginx
# In main nginx.conf http block
limit_req_zone $binary_remote_addr zone=analytics_api:10m rate=20r/s;
limit_req_zone $binary_remote_addr zone=calcom:10m     rate=30r/s;
```

```nginx
# In api.dotsai.in.conf location block
location /events {
    limit_req zone=analytics_api burst=50 nodelay;
    proxy_pass http://analytics:8000;
    # ... rest of proxy headers
}
```

---

## SSL Certificates

Use Certbot with the nginx Docker container's cert volume. Issue certificates for both new subdomains before updating nginx configs (nginx will fail to start if cert files referenced don't exist).

```bash
# On the VPS host (NOT inside Docker)
certbot certonly --webroot \
  -w /opt/services/nginx/html/acme \
  -d cal.dotsai.in \
  -d api.dotsai.in
```

Or use `--nginx` plugin if Certbot can reach the running nginx process. Certs auto-renew via Certbot's systemd timer.

---

## Environment File

```bash
# /opt/services/.env  (never commit this)

# Shared postgres
POSTGRES_USER=dotsai
POSTGRES_PASSWORD=<generate: openssl rand -base64 32>
POSTGRES_DB=dotsai

# Cal.com
CALCOM_NEXTAUTH_SECRET=<generate: openssl rand -base64 32>
CALCOM_ENCRYPTION_KEY=<generate: openssl rand -base64 24>

# Analytics
ANALYTICS_API_KEY=<generate: openssl rand -base64 32>
CALCOM_WEBHOOK_SECRET=<generate: openssl rand -base64 32>
```

---

## Component Boundaries

| Component | Responsibility | Network exposure |
|-----------|---------------|-----------------|
| nginx | TLS termination, routing by subdomain, rate limiting | Public (80/443) |
| postgres | Data persistence for both Cal.com and analytics | Internal only |
| calcom | Booking UI, calendar management, webhook dispatch | Via nginx only |
| analytics | Event ingestion, webhook receipt, metrics API | Via nginx only |
| pg-backup | Daily pg_dump to mounted volume | Internal only |

---

## Build Order for Roadmap

1. **PostgreSQL** — stand up first, verify healthcheck, create schemas
2. **FastAPI analytics** — simplest service, validates the network setup early
3. **nginx configs** — add api.dotsai.in config, issue SSL cert, test `/health`
4. **Browser tracking snippet** — add to dotsai.in and zeroonedotsai.consulting
5. **Cal.com** — most complex service (Prisma migrations, build-time var caveat), do this after infrastructure is proven
6. **Cal.com → analytics webhook bridge** — wire up after both are running
7. **pg-backup** — add after everything works in production

---

## Pitfalls Summary (for PITFALLS.md)

| Risk | Severity | Mitigation |
|------|----------|------------|
| Cal.com `NEXT_PUBLIC_WEBAPP_URL` baked at build time | HIGH | Set env var, accept startup patching delay, or build custom image |
| nginx proxy_pass container DNS resolution fails | HIGH | Add `resolver 127.0.0.11 valid=10s ipv6=off;` to every server block |
| Duplicate CORS headers (nginx + FastAPI) | HIGH | NEVER add CORS headers in nginx for FastAPI service |
| Cal.com webhook via public internet (latency/SSL overhead) | MEDIUM | Use internal Docker network URL: `http://analytics:8000/webhooks/calcom` |
| postgres not healthy before calcom starts (Prisma migration fails) | HIGH | Use `depends_on: condition: service_healthy` |
| NEXTAUTH_URL must include `/api/auth` suffix | MEDIUM | Set `NEXTAUTH_URL=https://cal.dotsai.in/api/auth`, NOT just the domain |
| Bearer token visible in browser JS | LOW | Acceptable for event ingestion; use rate limiting at nginx level |

---

## Sources

- Cal.com Docker docs: [https://cal.com/docs/self-hosting/docker](https://cal.com/docs/self-hosting/docker)
- Cal.com webhook payload spec: [https://cal.com/docs/developing/guides/automation/webhooks](https://cal.com/docs/developing/guides/automation/webhooks)
- Cal.com docker-compose reference: [https://docker.recipes/productivity/cal-com-scheduling](https://docker.recipes/productivity/cal-com-scheduling)
- Cal.com NEXT_PUBLIC_WEBAPP_URL issue: [https://github.com/calcom/cal.com/discussions/3704](https://github.com/calcom/cal.com/discussions/3704)
- FastAPI CORS docs: [https://fastapi.tiangolo.com/tutorial/cors/](https://fastapi.tiangolo.com/tutorial/cors/)
- FastAPI CORS + Bearer token: [https://gessfred.xyz/cors-with-jwt-auth/](https://gessfred.xyz/cors-with-jwt-auth/)
- Docker Compose healthcheck patterns: [https://docs.docker.com/compose/how-tos/startup-order/](https://docs.docker.com/compose/how-tos/startup-order/)
- nginx Docker DNS resolver: [https://www.emmanuelgautier.com/blog/nginx-docker-dns-resolution](https://www.emmanuelgautier.com/blog/nginx-docker-dns-resolution)
- PostgreSQL backup container: [https://github.com/prodrigestivill/docker-postgres-backup-local](https://github.com/prodrigestivill/docker-postgres-backup-local)
- nginx WebSocket proxy (Cal.com requirement): [https://nginx.org/en/docs/http/websocket.html](https://nginx.org/en/docs/http/websocket.html)
