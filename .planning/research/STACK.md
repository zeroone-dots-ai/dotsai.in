# Technology Stack

**Project:** dotsai.in — Self-hosted Scheduling + In-house Analytics
**Milestone:** Cal.com at cal.dotsai.in + FastAPI analytics + PostgreSQL on existing VPS
**Researched:** 2026-03-27
**Confidence:** MEDIUM-HIGH (Cal.com image tag unverifiable from Docker Hub tags page; all other components HIGH)

---

## Recommended Stack

### Scheduling Layer

| Technology | Version / Image | Purpose | Why |
|------------|-----------------|---------|-----|
| Cal.com | `calcom.docker.scarf.sh/calcom/cal.com` (latest or pinned semver tag from Docker Hub) | Self-hosted scheduling at cal.dotsai.in | MIT-licensed, Docker-native, officially maintained in main repo as of v5.9; ARM variant available via `-arm` suffix |
| Redis | `redis:latest` (pin to `redis:7-alpine` in production) | Session cache + background job queue for Cal.com | Required by Cal.com API v2; without it the API service will not start |

**IMPORTANT — calcom/docker repo archived Oct 29, 2025.** The `calcom/docker` community repo is read-only. All Docker files now live in the main `calcom/cal.com` monorepo at `docker-compose.yml` in root. Use that as source of truth, not the archived community repo. Confidence: HIGH (verified via GitHub).

### Analytics API Layer

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| FastAPI | `0.115.x` (pin; avoid `0.135.x` until stable in prod) | HTTP API receiving analytics events | Async-native, Pydantic v2 built-in, 3-5x better throughput than sync under load |
| Python | `3.12` | Runtime | Latest stable with all async features; 3.13 available but ecosystem adoption still catching up |
| SQLAlchemy | `2.0.48` | ORM + async DB sessions | 2.0 is the current stable line with first-class async support; `2.1.x` docs exist but `2.0` is production-stable |
| asyncpg | `0.29.0` | PostgreSQL async driver | Pinned to `<0.30` due to known compatibility issues with SQLAlchemy `create_async_engine` in `0.30+` series. Confidence: MEDIUM — from community reports, verify on fresh setup |
| Pydantic | `v2` (bundled via FastAPI) | Request/response validation | V2 is the current standard; V1 is legacy |
| Alembic | `1.13.x` | Database schema migrations | Standard FastAPI/SQLAlchemy migration tool; use `alembic init -t async` for async engine |
| uvicorn | `0.34.x` | ASGI server | Production ASGI server for FastAPI; use `uvicorn[standard]` for uvloop |

### Database Layer

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | `17` (pin to `postgres:17` in Docker; `17.4` is the latest patch as of March 2025) | Single database instance for both Cal.com and analytics | PostgreSQL 17 is current stable. Cal.com's docker-compose uses `image: postgres` (untagged latest) — override to `postgres:17` for production stability. Analytics schema lives in a separate database or separate schema within same instance |

### Infrastructure Layer

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Docker | CE current | Container runtime | Already in use on VPS |
| Docker Compose | v2 (`docker compose`, no hyphen) | Service orchestration | Cal.com officially uses `docker compose` (v2 syntax); avoid legacy `docker-compose` (v1) |
| nginx | Current (already deployed in Docker) | Reverse proxy, SSL termination, subdomain routing | Already serving dotsai.in; extend with new `server` blocks for cal.dotsai.in and api.dotsai.in |
| Let's Encrypt | Certbot / existing setup | SSL for new subdomains | Already handling dotsai.in SSL; extend to new subdomains |

### Supporting Libraries (Analytics API)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `python-dotenv` | `1.x` | Load `.env` into environment | Always — keeps secrets out of code |
| `httpx` | `0.27.x` | Async HTTP client | If analytics API needs to call external services (e.g. webhook on booking) |
| `python-jose[cryptography]` | `3.3.x` | JWT signing for API auth token | Used to validate bearer tokens from dotsai.in and zeroonedotsai.consulting callers |
| `passlib[bcrypt]` | `1.7.x` | Password hashing utility | Only needed if API has admin login — skip for token-only auth |
| `slowapi` | `0.1.x` | Rate limiting middleware for FastAPI | Apply to POST /event endpoint to prevent abuse from Cloudflare Pages origins |

---

## Exact Docker Compose Structure (Two Compose Files)

Use **two separate docker-compose files** on the VPS:

```
/opt/services/
  calcom/
    docker-compose.yml      ← Cal.com + Redis + (shares Postgres)
    .env
  analytics/
    docker-compose.yml      ← FastAPI analytics API
    .env
  nginx/                    ← Already exists
    html/
    conf.d/
```

### Why two files instead of one mega-compose?
- Cal.com and analytics have independent release cycles
- Postgres restarts from one compose don't affect the other
- Simpler to debug and redeploy individual services

---

## Key Configuration Details

### Cal.com docker-compose.yml (minimum required services)

```yaml
version: "3.8"

services:
  database:
    image: postgres:17
    restart: always
    volumes:
      - database-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}

  redis:
    image: redis:7-alpine
    restart: always
    volumes:
      - redis-data:/data
    ports:
      - "127.0.0.1:6379:6379"    # bind to loopback only

  calcom:
    image: calcom.docker.scarf.sh/calcom/cal.com    # official image
    restart: always
    depends_on:
      - database
      - redis
    ports:
      - "127.0.0.1:3000:3000"    # expose only to loopback; nginx proxies externally
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@database/${POSTGRES_DB}
      NEXTAUTH_SECRET: ${NEXTAUTH_SECRET}
      NEXTAUTH_URL: https://cal.dotsai.in/api/auth
      NEXT_PUBLIC_WEBAPP_URL: https://cal.dotsai.in
      JWT_SECRET: ${JWT_SECRET}
      CALENDSO_ENCRYPTION_KEY: ${CALENDSO_ENCRYPTION_KEY}
      REDIS_URL: redis://redis:6379
      NODE_TLS_REJECT_UNAUTHORIZED: "0"       # only safe behind nginx SSL termination

volumes:
  database-data:
  redis-data:
```

**Note:** Remove Prisma Studio (`studio:` service) in production. It exposes raw DB access on port 5555.

### Required .env variables (Cal.com)

Generate secrets with `openssl rand -base64 32`:

```
POSTGRES_USER=calcom
POSTGRES_PASSWORD=<strong-random>
POSTGRES_DB=calcom
DATABASE_HOST=database
NEXTAUTH_SECRET=<openssl-rand-base64-32>
JWT_SECRET=<openssl-rand-base64-32>
CALENDSO_ENCRYPTION_KEY=<openssl-rand-base64-32>
NEXT_PUBLIC_WEBAPP_URL=https://cal.dotsai.in
```

Stripe variables (`STRIPE_API_KEY`, `NEXT_PUBLIC_STRIPE_PUBLIC_KEY`, `STRIPE_WEBHOOK_SECRET`) are only required if using payments. For basic scheduling, they can be left empty or omitted.

---

### Analytics API (FastAPI) docker-compose.yml

```yaml
version: "3.8"

services:
  analytics-api:
    build: .
    restart: always
    ports:
      - "127.0.0.1:8000:8000"    # loopback only; nginx proxies
    environment:
      DATABASE_URL: ${DATABASE_URL}
      API_SECRET_TOKEN: ${API_SECRET_TOKEN}
      ALLOWED_ORIGINS: ${ALLOWED_ORIGINS}
    depends_on:
      - analytics-db

  analytics-db:
    image: postgres:17
    restart: always
    volumes:
      - analytics-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: analytics
    ports:
      - "127.0.0.1:5433:5432"    # port 5433 avoids conflict with Cal.com's Postgres on 5432

volumes:
  analytics-data:
```

**Alternative:** Share Cal.com's Postgres instance (create a separate `analytics` database on it). This saves ~50MB RAM but couples the two services. Recommended only on low-memory VPS (<2GB RAM). Prefer separate containers for isolation.

---

### FastAPI Analytics API — Core Code Pattern

```python
# main.py
from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from pydantic import BaseModel
import os

DATABASE_URL = os.environ["DATABASE_URL"]  # postgresql+asyncpg://...
API_SECRET_TOKEN = os.environ["API_SECRET_TOKEN"]
ALLOWED_ORIGINS = os.environ["ALLOWED_ORIGINS"].split(",")

engine = create_async_engine(DATABASE_URL, echo=False, pool_size=10, max_overflow=20)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,    # e.g. ["https://dotsai.in", "https://zeroonedotsai.consulting"]
    allow_credentials=False,           # no cookies needed for analytics
    allow_methods=["POST", "OPTIONS"],
    allow_headers=["Content-Type", "X-Api-Token"],
)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

async def verify_token(x_api_token: str = Header(...)):
    if x_api_token != API_SECRET_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")

class EventPayload(BaseModel):
    event_type: str          # "pageview" | "cta_click" | "booking_complete"
    page: str
    source: str              # "dotsai.in" | "zeroonedotsai.consulting"
    metadata: dict = {}

@app.post("/event", dependencies=[Depends(verify_token)])
async def record_event(payload: EventPayload, db: AsyncSession = Depends(get_db)):
    # insert into events table
    ...
```

**CORS note:** `allow_credentials=False` with explicit origin list is the correct pattern for cross-origin analytics calls from Cloudflare Pages. Do NOT use `allow_origins=["*"]` — it prevents the `X-Api-Token` header from being sent correctly in all browsers.

**Security model for Cloudflare Pages → API:** Use a static bearer token (`X-Api-Token` header) embedded in the frontend JS. This is the standard pattern for public analytics — the token is not secret (it's in client JS), but it throttles abuse. Pair with `slowapi` rate limiting (e.g. 100 req/min per IP). Do NOT use OAuth2 flows for this use case.

---

### nginx Configuration Pattern (Multi-Service Reverse Proxy)

Add new `server` blocks to the existing nginx config at `/opt/services/nginx/conf.d/`.

```nginx
# cal.dotsai.in — Cal.com scheduling
server {
    listen 443 ssl;
    server_name cal.dotsai.in;

    ssl_certificate     /etc/letsencrypt/live/dotsai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dotsai.in/privkey.pem;

    location / {
        proxy_pass         http://host.docker.internal:3000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;           # Cal.com can be slow on first load
        proxy_connect_timeout 30s;
    }
}

# api.dotsai.in — FastAPI analytics
server {
    listen 443 ssl;
    server_name api.dotsai.in;

    ssl_certificate     /etc/letsencrypt/live/dotsai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dotsai.in/privkey.pem;

    location / {
        proxy_pass         http://host.docker.internal:8000;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        # CORS preflight handled by FastAPI CORSMiddleware — do not add nginx CORS headers
    }
}
```

**Key pattern:** `proxy_pass http://host.docker.internal:<port>` routes from the nginx container to services running on the host's Docker network. This works when nginx is itself a Docker container (your setup). The services in Cal.com's compose expose ports bound to `127.0.0.1`, and `host.docker.internal` resolves to the host from inside the nginx container.

**Alternative approach:** Put all services on a shared Docker network (`dotsai-net`) and use container names as upstream hostnames (e.g. `proxy_pass http://calcom:3000`). This is more robust but requires nginx to join the external Cal.com compose network. Use `host.docker.internal` for simplicity given existing nginx setup.

**SSL wildcard:** If Let's Encrypt already has a wildcard cert for `*.dotsai.in`, reuse it. If not, run `certbot --nginx -d cal.dotsai.in -d api.dotsai.in` to add new domains to the existing cert.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Scheduling | Cal.com (MIT, Docker) | Calendso fork, Formbricks | Cal.com IS the upstream; forks diverge |
| Analytics API | FastAPI + asyncpg | Django REST, Flask | FastAPI is async-native; lower overhead for high-frequency event ingestion |
| Analytics DB driver | asyncpg | psycopg3 (asyncio mode) | asyncpg is the established FastAPI ecosystem default; psycopg3 async is newer, less community examples |
| Reverse proxy | nginx (extend existing) | Traefik, Caddy | nginx already running; adding Traefik would require migrating existing config |
| Cal.com DB | Shared Postgres instance | Dedicated Postgres for Cal.com only | Shared saves resources on small VPS; dedicated is cleaner isolation — both are valid |
| Analytics store | PostgreSQL | ClickHouse, TimescaleDB | PostgreSQL is sufficient for <100K events/month; ClickHouse is overkill at this scale |
| Cal.com image | `calcom.docker.scarf.sh/calcom/cal.com` | Build from source | Official image is the supported path post-v5.9; building from source requires Node.js build environment |

---

## Installation Commands

```bash
# ── PostgreSQL 17 (Cal.com service) ──
# Defined in docker-compose.yml — no separate install

# ── Analytics API Python deps ──
pip install fastapi==0.115.12 \
            uvicorn[standard]==0.34.2 \
            sqlalchemy==2.0.48 \
            asyncpg==0.29.0 \
            alembic==1.13.3 \
            pydantic==2.11.1 \
            python-dotenv==1.0.1 \
            python-jose[cryptography]==3.3.0 \
            slowapi==0.1.9

# ── Init Alembic with async template ──
alembic init -t async migrations

# ── SSL for new subdomains ──
# On VPS (if using certbot standalone):
certbot certonly --standalone -d cal.dotsai.in -d api.dotsai.in
# Or extend existing wildcard:
certbot certonly --dns-cloudflare -d "*.dotsai.in" --expand
```

---

## Version Pinning Rationale

| Package | Pinned At | Reason |
|---------|-----------|--------|
| `asyncpg` | `0.29.0` | Known issues with `create_async_engine` in `0.30+` per community reports (MEDIUM confidence — verify on setup) |
| `postgres` | `17` (not `:latest`) | Prevents unintended major version upgrades across `docker compose pull`; Cal.com compose uses untagged `postgres` which risks jumping to v18 |
| `redis` | `7-alpine` | Cal.com's compose uses `redis:latest`; pin to `7-alpine` for reproducibility and smaller image size |
| `fastapi` | `0.115.x` | Production-stable line; `0.135.x` is very recent (March 2026) and may have undiscovered regressions |

---

## Sources

- Cal.com Docker docs: https://cal.com/docs/self-hosting/docker (MEDIUM confidence — docs may lag code)
- cal.com main repo docker-compose.yml: https://github.com/calcom/cal.com/blob/main/docker-compose.yml (HIGH)
- calcom/docker repo archived Oct 29, 2025: https://github.com/calcom/docker (HIGH — confirmed archived)
- Cal.com v5.9 announcement (Docker officially maintained): https://cal.com/blog/calcom-v5-9 (HIGH)
- PostgreSQL 17 Docker Hub: https://hub.docker.com/_/postgres (HIGH — 17.4 latest patch as of March 2025)
- FastAPI PyPI (0.135.2 latest as of March 2026): https://pypi.org/project/fastapi/ (HIGH)
- SQLAlchemy 2.0.48 PyPI: https://pypi.org/project/SQLAlchemy/ (HIGH)
- asyncpg 0.29.0 compatibility note: Community reports via WebSearch (MEDIUM — needs verification on fresh setup)
- FastAPI CORS official docs: https://fastapi.tiangolo.com/tutorial/cors/ (HIGH)
- FastAPI async SQLAlchemy pattern: https://leapcell.io/blog/building-high-performance-async-apis-with-fastapi-sqlalchemy-2-0-and-asyncpg (MEDIUM — community article, matches official SQLAlchemy async docs)
- Alembic async init: https://testdriven.io/blog/fastapi-sqlmodel/ (MEDIUM)
- Alembic async template `alembic init -t async`: https://berkkaraal.com/blog/2024/09/19/setup-fastapi-project-with-async-sqlalchemy-2-alembic-postgresql-and-docker/ (MEDIUM)
