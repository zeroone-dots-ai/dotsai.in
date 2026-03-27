from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.database import engine
from app.middleware.bot_filter import BotFilterMiddleware
from app.rate_limit import limiter
from app.routes.events import router as events_router
from app.routes.health import router as health_router
from app.routes.webhooks import router as webhooks_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    if engine is not None:
        await engine.dispose()


app = FastAPI(title="dotsai analytics", lifespan=lifespan)

# Attach limiter to app state (required by slowapi)
app.state.limiter = limiter

# Exception handler for rate limit exceeded
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS -- only allow our domains
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

# Bot filter -- must be added after CORS so CORS headers are set on preflight
app.add_middleware(BotFilterMiddleware)

# Routers
app.include_router(health_router)
app.include_router(events_router)
app.include_router(webhooks_router)
