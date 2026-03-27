# Phase 2: FastAPI Analytics API - Research

**Researched:** 2026-03-27
**Domain:** FastAPI async API with PostgreSQL (asyncpg), rate limiting, bot filtering, nginx reverse proxy, browser tracking snippet
**Confidence:** HIGH

## Summary

This phase builds a production-ready analytics ingest API at api.dotsai.in. The core stack is FastAPI + SQLAlchemy 2.0 async + asyncpg + Alembic, deployed as a Docker container behind nginx with Let's Encrypt SSL. A lightweight browser tracking snippet in public/index.html fires events to the API.

The asyncpg version concern flagged in Phase 1 is now resolved: asyncpg 0.31.0 (released Nov 2025) works with SQLAlchemy 2.0.48 (released Mar 2026). The earlier incompatibility between asyncpg 0.29.0 and SQLAlchemy was fixed in subsequent releases of both libraries. The reference project fastapi-sqlalchemy-asyncpg on GitHub uses asyncpg 0.30.0 + SQLAlchemy 2.0.44 successfully. Pin to asyncpg>=0.30.0,<0.32.0 and SQLAlchemy[asyncio]>=2.0.46 for safety.

The API design is straightforward: POST /events accepts a JSON payload with Bearer token auth, validates it, returns HTTP 202 immediately, and writes to PostgreSQL via BackgroundTasks. Bot filtering is a simple middleware checking User-Agent against a known list. Rate limiting uses slowapi (the standard FastAPI rate limiter, adapted from flask-limiter). CORS is handled entirely by FastAPI CORSMiddleware -- nginx must NOT add CORS headers.

**Primary recommendation:** Use FastAPI 0.135.x + SQLAlchemy[asyncio] 2.0.48 + asyncpg 0.31.0 + Alembic 1.18.x + slowapi 0.1.9 + uvicorn 0.42.0. Scaffold with Alembic async template. Deploy as a single Docker container on dotsai_internal network. Browser snippet uses navigator.sendBeacon for page unload resilience, with fetch API as primary transport.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| FastAPI | >=0.135.0 | ASGI web framework | Standard Python async API framework, massive ecosystem |
| uvicorn[standard] | >=0.42.0 | ASGI server | Default FastAPI production server, includes uvloop |
| SQLAlchemy[asyncio] | >=2.0.46 | Async ORM + Core | Standard Python ORM, first-class async since 2.0 |
| asyncpg | >=0.30.0,<0.32.0 | PostgreSQL async driver | Fastest Python PostgreSQL driver, production-stable |
| Alembic | >=1.18.0 | Database migrations | Official SQLAlchemy migration tool, async template support |
| slowapi | >=0.1.9 | Rate limiting | Standard FastAPI rate limiter, adapted from flask-limiter |
| pydantic | >=2.0 (ships with FastAPI) | Request/response validation | Built into FastAPI, no separate install needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| python-multipart | (FastAPI dep) | Form data parsing | Already a FastAPI dependency |
| httptools | (uvicorn[standard] dep) | Fast HTTP parsing | Installed via uvicorn[standard] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| slowapi | fastapi-guard | fastapi-guard is heavier (IP banning, penetration detection) -- overkill for simple rate limiting |
| asyncpg via SQLAlchemy | Raw asyncpg | Loses ORM, Alembic integration, session management; only consider for extreme perf needs |
| BackgroundTasks | Celery/Redis | BackgroundTasks is in-process, no external dependency; Celery only needed for distributed/retry workloads |
| navigator.sendBeacon | XMLHttpRequest | sendBeacon survives page unload; use fetch as primary, sendBeacon as unload fallback |

**Installation (in Dockerfile):**
```bash
pip install "fastapi[standard]" "sqlalchemy[asyncio]>=2.0.46" "asyncpg>=0.30.0,<0.32.0" "alembic>=1.18.0" "slowapi>=0.1.9"
```

## Architecture Patterns

### Recommended Project Structure (in repo)
```
analytics/
  app/
    __init__.py
    main.py              # FastAPI app, middleware, lifespan
    config.py            # Settings from env vars (pydantic-settings)
    database.py          # create_async_engine, async session factory
    models.py            # SQLAlchemy ORM models (visitors, events)
    schemas.py           # Pydantic request/response schemas
    routes/
      __init__.py
      events.py          # POST /events
      health.py          # GET /health
    middleware/
      __init__.py
      bot_filter.py      # Bot UA detection middleware
    dependencies.py      # get_db session dependency
  alembic/
    env.py               # Async Alembic env (use async template)
    versions/             # Migration files
  alembic.ini
  Dockerfile
  requirements.txt       # Pinned versions
```

### VPS Structure (on server)
```
/opt/services/
  docker-compose.yml      # Add analytics service
  .env.analytics          # ANALYTICS_WRITE_TOKEN, DATABASE_URL (chmod 600)
  analytics/              # Repo clone or build context (optional)
```

### Pattern 1: Async Database Session with FastAPI Dependency
**What:** Use SQLAlchemy async session as a FastAPI dependency, yielded per-request.
**When to use:** Every endpoint that needs database access.
**Example:**
```python
# database.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

engine = create_async_engine(
    "postgresql+asyncpg://dotsai:password@postgres:5432/dotsai",
    pool_size=5,
    max_overflow=10,
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# dependencies.py
from typing import AsyncGenerator

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
```

### Pattern 2: BackgroundTasks for Fire-and-Forget DB Write
**What:** Accept event, return 202 immediately, write to DB in background.
**When to use:** Analytics ingest where client does not need confirmation of DB write.
**Example:**
```python
# routes/events.py
from fastapi import APIRouter, BackgroundTasks, Depends, Request, Response
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

async def write_event(db: AsyncSession, event_data: dict):
    """Background task -- writes event to analytics.events."""
    visitor = await get_or_create_visitor(db, event_data)
    event = Event(
        visitor_id=visitor.id,
        site=event_data["site"],
        page=event_data["page"],
        event_name=event_data["event_name"],
        properties=event_data.get("properties", {}),
    )
    db.add(event)
    await db.commit()

@router.post("/events", status_code=202)
async def ingest_event(
    request: Request,
    background_tasks: BackgroundTasks,
):
    body = await request.json()
    # Get a NEW session for the background task (not the request session)
    async def _write():
        async with async_session() as db:
            await write_event(db, body)
    background_tasks.add_task(_write)
    return Response(status_code=202)
```

### Pattern 3: Bot Filtering Middleware
**What:** Starlette middleware that checks User-Agent against a blocklist and returns 204 (silently dropped).
**When to use:** On all ingest endpoints.
**Example:**
```python
# middleware/bot_filter.py
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

BOT_SIGNATURES = [
    "bot", "crawler", "spider", "headless", "phantom", "selenium",
    "puppeteer", "playwright", "wget", "curl", "python-requests",
    "httpx", "axios", "node-fetch", "go-http-client", "java/",
    "scrapy", "slurp", "mediapartners", "facebookexternalhit",
    "twitterbot", "linkedinbot", "whatsapp", "telegrambot",
]

class BotFilterMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        ua = (request.headers.get("user-agent") or "").lower()
        if any(sig in ua for sig in BOT_SIGNATURES):
            return Response(status_code=204)
        return await call_next(request)
```

### Pattern 4: Bearer Token Auth
**What:** Simple header-based auth checking a shared secret.
**When to use:** POST /events endpoint.
**Example:**
```python
# dependencies.py
from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security = HTTPBearer()

def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> str:
    if credentials.credentials != settings.ANALYTICS_WRITE_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials
```

### Pattern 5: Visitor Fingerprinting (Privacy-Safe)
**What:** SHA-256 hash of IP + User-Agent + daily salt. Never store raw IP.
**When to use:** Creating or matching visitors.
**Example:**
```python
import hashlib
from datetime import date

def fingerprint(ip: str, ua: str, salt: str) -> str:
    """Daily-rotating fingerprint. Same visitor gets different hash each day."""
    daily = f"{salt}:{date.today().isoformat()}:{ip}:{ua}"
    return hashlib.sha256(daily.encode()).hexdigest()
```

### Pattern 6: Alembic Async Setup
**What:** Initialize Alembic with async template for asyncpg.
**When to use:** First migration setup.
**Commands:**
```bash
cd analytics
alembic init -t async alembic
# Edit alembic.ini: sqlalchemy.url = postgresql+asyncpg://...
# Edit alembic/env.py: import target_metadata from app.models
alembic revision --autogenerate -m "create visitors and events tables"
alembic upgrade head
```

### Anti-Patterns to Avoid
- **Using the request's DB session in BackgroundTasks:** The request session closes after response. Background tasks MUST create their own session.
- **Adding CORS headers in nginx AND FastAPI:** Double CORS headers break browsers. Use FastAPI CORSMiddleware ONLY (REQ-08.5).
- **Storing raw IP anywhere:** Even temporarily in logs. Hash immediately upon receipt.
- **Using `allow_origins=["*"]` with `allow_credentials=True`:** Browsers reject this combination. Must list specific origins.
- **Running Alembic migrations with async connection string in alembic.ini:** Use the async template's env.py which handles the async engine properly; the alembic.ini URL is only used as a fallback.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rate limiting | Custom counter middleware | slowapi 0.1.9 | Handles storage backends, key functions, header injection, decorator syntax |
| CORS | Manual header injection | FastAPI CORSMiddleware | Handles preflight OPTIONS, Vary headers, credential rules correctly |
| Request validation | Manual JSON parsing | Pydantic models via FastAPI | Automatic 422 errors, type coercion, OpenAPI schema |
| DB migrations | Manual CREATE TABLE | Alembic + autogenerate | Versioned, reversible, team-friendly |
| Bearer auth | Custom header parsing | FastAPI HTTPBearer | OpenAPI integration, proper 401/403 responses |
| SSL termination | Application-level TLS | nginx + certbot | Standard, auto-renewal, no Python TLS overhead |

**Key insight:** FastAPI's dependency injection system handles auth, DB sessions, and validation as composable dependencies. Do NOT build middleware for things that should be dependencies, and vice versa.

## Common Pitfalls

### Pitfall 1: BackgroundTasks Session Lifecycle
**What goes wrong:** Background task tries to use the request's DB session, gets "Session is closed" error.
**Why it happens:** FastAPI closes the yielded session dependency after the response is sent. BackgroundTasks run after response.
**How to avoid:** Create a NEW async session inside the background task function. Do not pass the request's `db` dependency.
**Warning signs:** Intermittent "Session is closed" or "Cannot operate on a closed transaction" errors.

### Pitfall 2: Alembic autogenerate Misses analytics Schema
**What goes wrong:** `alembic revision --autogenerate` generates empty migration or creates tables in `public` schema.
**Why it happens:** Alembic defaults to `public` schema. Models must specify `__table_args__ = {"schema": "analytics"}`.
**How to avoid:** Set `include_schemas=True` in `env.py` `run_migrations_online()`, and set `schema_translate_map` or explicitly define schema in models and in alembic's `version_table_schema`.
**Warning signs:** Tables appear in `public` schema instead of `analytics`.

### Pitfall 3: slowapi Not Getting Real Client IP Behind nginx
**What goes wrong:** All requests rate-limited as one client (same IP).
**Why it happens:** nginx proxies all requests, so the client IP appears as the Docker gateway IP.
**How to avoid:** Set `proxy_set_header X-Real-IP $remote_addr;` in nginx, and configure slowapi's key function to read `X-Real-IP` or `X-Forwarded-For` header.
**Warning signs:** Rate limit triggers after 100 requests total (not per-client).

### Pitfall 4: Let's Encrypt Rate Limits During Testing
**What goes wrong:** certbot fails with "too many certificates already issued" after multiple test runs.
**Why it happens:** Let's Encrypt production endpoint limits to 5 duplicate certificates per week.
**How to avoid:** ALWAYS use `--staging` flag first (`--server https://acme-staging-v02.api.letsencrypt.org/directory`). Only switch to production endpoint on final verified run.
**Warning signs:** certbot returns "rateLimited" error.

### Pitfall 5: CORS Preflight Blocked by nginx
**What goes wrong:** Browser sends OPTIONS preflight request, nginx returns 405 or no CORS headers.
**Why it happens:** nginx intercepts OPTIONS before proxying to FastAPI.
**How to avoid:** Ensure nginx passes ALL methods (including OPTIONS) through to FastAPI. Do NOT add any CORS headers in nginx config. FastAPI CORSMiddleware handles everything including preflight.
**Warning signs:** Browser console shows "CORS preflight did not succeed" or "No Access-Control-Allow-Origin header".

### Pitfall 6: sendBeacon Payload Too Large
**What goes wrong:** Browser silently drops the beacon request.
**Why it happens:** Most browsers cap sendBeacon payloads at ~64KB. Large `properties` JSONB payloads can exceed this.
**How to avoid:** Keep event payloads minimal (event name, page, site, small properties object). Use fetch for the primary transport; sendBeacon only as unload fallback.
**Warning signs:** Events disappear intermittently (only on page navigation, not on idle pages).

### Pitfall 7: Docker Container Name Collision
**What goes wrong:** `docker compose up` fails because container name "analytics" is already in use.
**Why it happens:** VPS has 80+ containers; name may already be taken.
**How to avoid:** Check `docker ps -a --format '{{.Names}}' | grep analytics` before adding to compose. The requirement specifies container_name: "analytics" for Cal.com webhook routing.
**Warning signs:** "Conflict. The container name '/analytics' is already in use by container..."

### Pitfall 8: Cloudflare Pages CSP Blocks Cross-Origin Fetch
**What goes wrong:** zeroonedotsai.consulting snippet cannot POST to api.dotsai.in.
**Why it happens:** Cloudflare Pages may set `default-src 'self'` CSP which blocks cross-origin `connect-src` by default.
**How to avoid:** Add a `_headers` file to the zeroonedotsai.consulting repo with `connect-src` directive allowing api.dotsai.in. Or check if no CSP is set (many Pages sites don't set one by default).
**Warning signs:** Browser console shows "Refused to connect to 'https://api.dotsai.in/events' because it violates the following Content Security Policy directive: 'default-src 'self''".

## Code Examples

### FastAPI App Scaffold (main.py)
```python
# Source: FastAPI official docs + community patterns
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import settings
from app.database import engine
from app.middleware.bot_filter import BotFilterMiddleware
from app.routes import events, health

def get_real_ip(request):
    """Extract real client IP from X-Real-IP header (set by nginx)."""
    return request.headers.get("x-real-ip", get_remote_address(request))

limiter = Limiter(key_func=get_real_ip)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: engine pool is lazy, no explicit connect needed
    yield
    # Shutdown: dispose engine pool
    await engine.dispose()

app = FastAPI(title="dotsai analytics", lifespan=lifespan)

# Middleware order matters: first added = outermost
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://dotsai.in",
        "https://zeroonedotsai.consulting",
        "https://www.zeroonedotsai.consulting",
    ],
    allow_methods=["POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.add_middleware(BotFilterMiddleware)

app.include_router(health.router)
app.include_router(events.router)
```

### SQLAlchemy Models (models.py)
```python
# Source: SQLAlchemy 2.0 async docs
import uuid
from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class Visitor(Base):
    __tablename__ = "visitors"
    __table_args__ = {"schema": "analytics"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    fingerprint: Mapped[str] = mapped_column(String(64), index=True)
    country: Mapped[str | None] = mapped_column(String(2))
    city: Mapped[str | None] = mapped_column(String(128))
    referrer: Mapped[str | None] = mapped_column(Text)
    first_seen: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    last_seen: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

class Event(Base):
    __tablename__ = "events"
    __table_args__ = {"schema": "analytics"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    visitor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("analytics.visitors.id")
    )
    site: Mapped[str] = mapped_column(String(128))
    page: Mapped[str] = mapped_column(Text)
    event_name: Mapped[str] = mapped_column(String(64))
    properties: Mapped[dict] = mapped_column(JSONB, default=dict)
```

### Alembic env.py (Async Template Key Changes)
```python
# Source: Alembic cookbook + SQLAlchemy async docs
# Key modifications to the auto-generated async template:

from app.models import Base
target_metadata = Base.metadata

# In run_migrations_online():
def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        include_schemas=True,
        version_table_schema="analytics",  # Store alembic_version in analytics schema
    )
    with context.begin_transaction():
        context.execute(f"SET search_path TO analytics, public")
        context.run_migrations()
```

### Dockerfile
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run Alembic migrations on startup, then start uvicorn
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
```

### Docker Compose Service Addition
```yaml
# Add to /opt/services/docker-compose.yml
  analytics:
    build: ./analytics
    # Or if pre-built: image: analytics:latest
    container_name: analytics
    restart: always
    env_file:
      - .env.analytics
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - dotsai_internal
    # No ports: -- nginx proxies via internal network
    deploy:
      resources:
        limits:
          memory: 128M
```

### .env.analytics (on VPS, chmod 600)
```bash
DATABASE_URL=postgresql+asyncpg://dotsai:<password>@postgres:5432/dotsai
ANALYTICS_WRITE_TOKEN=<generated-with-openssl-rand-hex-32>
FINGERPRINT_SALT=<generated-with-openssl-rand-hex-16>
```

### nginx Server Block for api.dotsai.in
```nginx
# /opt/services/nginx/conf.d/api.dotsai.in.conf
server {
    listen 80;
    server_name api.dotsai.in;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.dotsai.in;

    ssl_certificate /etc/letsencrypt/live/api.dotsai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.dotsai.in/privkey.pem;

    # Docker DNS resolver -- required for container name resolution
    resolver 127.0.0.11 valid=10s ipv6=off;

    # Variable forces re-resolution via resolver
    set $upstream_analytics http://analytics:8000;

    location / {
        proxy_pass $upstream_analytics;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # NO CORS headers here -- FastAPI CORSMiddleware handles it
    }
}
```

### Browser Tracking Snippet (for public/index.html)
```html
<!-- Analytics: dotsai self-hosted tracking -->
<script>
(function(){
  var API = "https://api.dotsai.in/events";
  var TOKEN = "PUBLIC_WRITE_TOKEN_HERE";
  var SITE = location.hostname;

  function track(name, props) {
    var payload = JSON.stringify({
      site: SITE,
      page: location.pathname,
      event_name: name,
      properties: props || {},
      referrer: document.referrer || null,
      screen_width: screen.width,
    });
    // Primary: fetch with keepalive
    if (typeof fetch !== "undefined") {
      fetch(API, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + TOKEN,
        },
        body: payload,
        keepalive: true,
      }).catch(function(){});
    }
  }

  // page_view on load
  track("page_view");

  // session_start on first visit (sessionStorage gate)
  try {
    if (!sessionStorage.getItem("_ds")) {
      sessionStorage.setItem("_ds", "1");
      track("session_start");
    }
  } catch(e) {}

  // Expose for manual calls: window.dotsTrack('cta_click', {target: 'whatsapp'})
  window.dotsTrack = track;
})();
</script>
```

### certbot Staging Command
```bash
# Run on VPS AFTER DNS A record for api.dotsai.in points to 72.62.229.16
# STAGING first -- no rate limit risk
certbot certonly \
  --webroot \
  -w /opt/services/nginx/certbot/ \
  -d api.dotsai.in \
  --staging \
  --agree-tos \
  --email aamdhanee.dev@gmail.com \
  --non-interactive

# Verify staging cert works, then production:
certbot certonly \
  --webroot \
  -w /opt/services/nginx/certbot/ \
  -d api.dotsai.in \
  --agree-tos \
  --email aamdhanee.dev@gmail.com \
  --non-interactive \
  --force-renewal
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| asyncpg 0.29.0 (compat concerns) | asyncpg 0.30.0-0.31.0 (stable with SA 2.0.46+) | Nov 2024-2025 | Pin >=0.30.0, not 0.29.0 as originally planned |
| SQLAlchemy 1.4 async (greenlet required) | SQLAlchemy 2.0.48 (`[asyncio]` extra installs greenlet) | 2023 | Use `sqlalchemy[asyncio]` install target |
| `@app.on_event("startup")` | `lifespan` context manager | FastAPI 0.100+ (2023) | Use `lifespan` parameter on FastAPI() |
| `docker-compose.yml` v2 format | `docker-compose.yml` v3 (existing VPS convention) | N/A | Keep existing naming per Phase 1 decision |
| XMLHttpRequest for analytics | fetch with keepalive + sendBeacon fallback | 2020+ | fetch is standard, keepalive survives navigation |
| Alembic sync-only | Alembic async template (`alembic init -t async`) | Alembic 1.7+ | Use async template for asyncpg compatibility |

**Deprecated/outdated:**
- asyncpg 0.29.0: Had known issues with SQLAlchemy create_async_engine. Use >=0.30.0.
- `@app.on_event("startup"/"shutdown")`: Deprecated in FastAPI 0.100+. Use lifespan.
- flask-limiter (for FastAPI): Use slowapi instead, which is the FastAPI-adapted version.

## Open Questions

1. **DNS A record for api.dotsai.in**
   - What we know: Must point to 72.62.229.16 before certbot runs
   - What's unclear: Whether the A record has been created yet
   - Recommendation: First task in Plan 02-03 must verify DNS resolution before running certbot

2. **Existing container named "analytics" on VPS**
   - What we know: VPS has 80+ containers
   - What's unclear: Whether "analytics" container name is already taken
   - Recommendation: Check `docker ps -a --format '{{.Names}}' | grep analytics` in first task

3. **zeroonedotsai.consulting CSP policy**
   - What we know: Cloudflare Pages may set restrictive default-src 'self' CSP. If so, cross-origin fetch to api.dotsai.in will be blocked.
   - What's unclear: Whether zeroonedotsai.consulting actually has a CSP header set
   - Recommendation: Check with `curl -sI https://zeroonedotsai.consulting | grep -i content-security` in Plan 02-04. If CSP blocks connect-src, add a `_headers` file to that repo.

4. **certbot setup on VPS -- webroot vs standalone**
   - What we know: nginx is already running in Docker. certbot needs HTTP-01 challenge via port 80.
   - What's unclear: Whether certbot is installed on VPS host, or runs as a Docker container, or how existing certs (e.g., dotsai.in) were obtained
   - Recommendation: Check `which certbot` and `ls /etc/letsencrypt/live/` on VPS in Plan 02-03 to understand existing SSL setup

5. **How to deploy the analytics Python app to VPS**
   - What we know: VPS uses docker-compose.yml at /opt/services/
   - What's unclear: Whether to build the Docker image on VPS or push pre-built; whether code lives on VPS or is pulled from git
   - Recommendation: Simplest approach: clone the analytics code to /opt/services/analytics/ on VPS, add `build: ./analytics` to docker-compose.yml. No Docker registry needed.

## Sources

### Primary (HIGH confidence)
- [FastAPI official docs - CORS](https://fastapi.tiangolo.com/tutorial/cors/) - CORSMiddleware configuration
- [FastAPI official docs - BackgroundTasks](https://fastapi.tiangolo.com/tutorial/background-tasks/) - Fire-and-forget pattern
- [SQLAlchemy 2.0 asyncio docs](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html) - create_async_engine, async session
- [Alembic cookbook - async](https://alembic.sqlalchemy.org/en/latest/cookbook.html) - Async migration environment
- [asyncpg PyPI](https://pypi.org/project/asyncpg/) - Version 0.31.0, Python >=3.9, PG 9.5-18
- [SQLAlchemy PyPI](https://pypi.org/project/SQLAlchemy/) - Version 2.0.48, Mar 2, 2026
- [FastAPI PyPI](https://pypi.org/project/fastapi/) - Version 0.135.2, Mar 23, 2026
- [uvicorn PyPI](https://pypi.org/project/uvicorn/) - Version 0.42.0, Mar 16, 2026
- [slowapi PyPI](https://pypi.org/project/slowapi/) - Version 0.1.9, Feb 5, 2024
- [MDN - navigator.sendBeacon()](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/sendBeacon) - Beacon API spec

### Secondary (MEDIUM confidence)
- [grillazz/fastapi-sqlalchemy-asyncpg](https://github.com/grillazz/fastapi-sqlalchemy-asyncpg) - Reference project: asyncpg 0.30.0 + SA 2.0.44 + Alembic 1.17.2 working
- [Berk Karaal: FastAPI + Async SA2 + Alembic + Docker](https://berkkaraal.com/blog/2024/09/19/setup-fastapi-project-with-async-sqlalchemy-2-alembic-postgresql-and-docker/) - Project structure patterns
- [Cloudflare Pages CSP docs](https://developers.cloudflare.com/fundamentals/reference/policies-compliances/content-security-policies/) - Default CSP behavior
- [slowapi GitHub](https://github.com/laurentS/slowapi) - Rate limiting patterns, key functions

### Tertiary (LOW confidence)
- Cloudflare Pages default CSP may or may not be set on zeroonedotsai.consulting -- needs runtime verification with curl
- Whether certbot is already installed and configured on VPS -- needs SSH verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all library versions verified via PyPI, reference project confirms asyncpg 0.30 + SA 2.0.44 compatibility
- Architecture: HIGH -- patterns from official docs (FastAPI, SQLAlchemy async, Alembic async template)
- Pitfalls: HIGH -- well-documented issues (session lifecycle, CORS double-header, rate limit key extraction)
- Browser snippet: HIGH -- Beacon API and fetch with keepalive are well-documented web standards
- nginx/SSL: MEDIUM -- pattern is standard but VPS-specific setup (existing certbot, webroot path) unknown
- CSP on zeroonedotsai.consulting: LOW -- must check at runtime

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable domain; asyncpg/SQLAlchemy/FastAPI are mature libraries with predictable release cycles)
