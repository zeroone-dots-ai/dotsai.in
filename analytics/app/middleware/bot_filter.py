from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

BOT_SIGNATURES = [
    "bot",
    "crawler",
    "spider",
    "headless",
    "phantom",
    "selenium",
    "puppeteer",
    "playwright",
    "wget",
    "curl",
    "python-requests",
    "httpx",
    "axios",
    "node-fetch",
    "go-http-client",
    "java/",
    "scrapy",
    "slurp",
    "mediapartners",
    "facebookexternalhit",
    "twitterbot",
    "linkedinbot",
    "whatsapp",
    "telegrambot",
    "bingbot",
    "googlebot",
    "yandexbot",
    "baiduspider",
    "duckduckbot",
    "applebot",
]


class BotFilterMiddleware(BaseHTTPMiddleware):
    """Drop POST /events requests from known bot User-Agents with a silent 204."""

    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/events" and request.method == "POST":
            ua = (request.headers.get("user-agent") or "").lower()
            if any(sig in ua for sig in BOT_SIGNATURES):
                return Response(status_code=204)
        return await call_next(request)
