from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address


def get_real_ip(request: Request) -> str:
    """Extract real client IP from X-Real-IP (set by nginx) or fall back to remote address."""
    return request.headers.get("x-real-ip") or get_remote_address(request)


limiter = Limiter(key_func=get_real_ip)
