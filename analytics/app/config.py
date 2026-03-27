from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = ""
    ANALYTICS_WRITE_TOKEN: str = ""
    FINGERPRINT_SALT: str = ""

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
