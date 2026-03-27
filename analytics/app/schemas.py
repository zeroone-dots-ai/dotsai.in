from typing import Optional

from pydantic import BaseModel


class EventIn(BaseModel):
    site: str
    page: str
    event_name: str
    properties: dict = {}
    referrer: Optional[str] = None
    screen_width: Optional[int] = None


class HealthResponse(BaseModel):
    status: str
    db: str
