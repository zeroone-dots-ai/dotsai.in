from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.database import engine
from app.routes.health import router as health_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    if engine is not None:
        await engine.dispose()


app = FastAPI(title="dotsai analytics", lifespan=lifespan)

app.include_router(health_router)
