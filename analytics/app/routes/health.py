from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.schemas import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health():
    """Health check -- verifies API is running and tests DB connectivity."""
    try:
        from app.database import async_session_factory

        if async_session_factory is None:
            return HealthResponse(status="ok", db="not_configured")
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
        return HealthResponse(status="ok", db="connected")
    except Exception:
        return HealthResponse(status="ok", db="disconnected")
