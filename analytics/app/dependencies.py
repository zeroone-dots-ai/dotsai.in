from typing import AsyncGenerator

from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import async_session_factory

security = HTTPBearer()


def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> str:
    """Validate Bearer token against the configured write token."""
    if credentials.credentials != settings.ANALYTICS_WRITE_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    if async_session_factory is None:
        raise RuntimeError("Database not configured -- set DATABASE_URL")
    async with async_session_factory() as session:
        yield session
