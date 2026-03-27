from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = ""
    ANALYTICS_WRITE_TOKEN: str = ""
    FINGERPRINT_SALT: str = ""
    CAL_WEBHOOK_SECRET: Optional[str] = None

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
