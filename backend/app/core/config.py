"""
Application configuration using pydantic-settings.
"""
from functools import lru_cache
from typing import List, Optional, Set

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

FORBIDDEN_PRODUCTION_SECRETS: Set[str] = {
    "change-this-secret-key-in-production",
    "secret",
    "changeme",
    "placeholder",
    "admin",
    "password",
    "123456",
    "secretkey",
}


class Settings(BaseSettings):
    """
    Central configuration loaded from environment variables / .env file.
    All secrets must come from environment — never hardcoded here.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Database ──────────────────────────────────────────────────────────
    database_url: str

    # ── Security ──────────────────────────────────────────────────────────
    secret_key: str
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    algorithm: str = "HS256"

    # ── CORS ──────────────────────────────────────────────────────────────
    cors_origins: str = "http://localhost:3000,http://localhost:8080,http://localhost:8000,http://127.0.0.1:8000"

    # ── Observability & Logging ───────────────────────────────────────────
    log_level: str = "INFO"
    correlation_id_header: str = "X-Request-ID"

    # ── Rate Limiting ─────────────────────────────────────────────────────
    rate_limit_auth_per_minute: int = 30
    rate_limit_payments_per_minute: int = 20
    rate_limit_reviews_per_minute: int = 30
    rate_limit_default_per_minute: int = 120

    # ── External Services ─────────────────────────────────────────────────
    redis_url: Optional[str] = None
    stripe_secret_key: Optional[str] = None
    stripe_webhook_secret: Optional[str] = None

    # ── Application ───────────────────────────────────────────────────────
    environment: str = "development"
    app_name: str = "Multi-Vendor Marketplace API"
    app_version: str = "1.0.0"

    @model_validator(mode="after")
    def validate_production_and_database(self) -> "Settings":
        """
        Validate database URL dialect and enforce strict production secrets.
        """
        # 1. Normalize Postgres database URL for asyncpg
        url = self.database_url
        if url.startswith("postgres://"):
            self.database_url = url.replace("postgres://", "postgresql+asyncpg://", 1)
        elif url.startswith("postgresql://") and not url.startswith("postgresql+asyncpg://"):
            self.database_url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

        # 2. Production safeguards
        if self.environment.lower() == "production":
            key = self.secret_key.strip()
            if len(key) < 32:
                raise ValueError(
                    "Production configuration error: SECRET_KEY must be at least 32 characters long."
                )
            if any(f in key.lower() for f in FORBIDDEN_PRODUCTION_SECRETS):
                raise ValueError(
                    f"Production configuration error: Insecure default SECRET_KEY '{key}' is forbidden in production."
                )

        return self

    @property
    def cors_origins_list(self) -> List[str]:
        """Parse comma-separated CORS origins into a list."""
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def is_development(self) -> bool:
        return self.environment.lower() == "development"

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    """Return cached Settings instance."""
    return Settings()
