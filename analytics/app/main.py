from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.database import engine
from app.middleware.bot_filter import BotFilterMiddleware
from app.routes.health import router as health_router


def get_real_ip(request: Request) -> str:
    """Extract real client IP from X-Real-IP (set by nginx) or fall back to remote address."""
    return request.headers.get("x-real-ip") or get_remote_address(request)


limiter = Limiter(key_func=get_real_ip)


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

# Events router imported here to avoid circular import (events.py imports limiter from main)
# Will be added in Task 2
