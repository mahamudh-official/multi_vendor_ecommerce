"""
Security utilities: JWT token handling and password hashing.

Password hashing: pwdlib with argon2 (replaces passlib).
JWT: python-jose.
"""
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher

from app.core.config import get_settings

settings = get_settings()

# ── Password hashing ───────────────────────────────────────────────────────
# pwdlib with Argon2 — modern, memory-hard, recommended algorithm
_password_hash = PasswordHash([Argon2Hasher()])


def hash_password(plain_password: str) -> str:
    """Hash a plain-text password using Argon2."""
    return _password_hash.hash(plain_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain-text password against a stored Argon2 hash."""
    return _password_hash.verify(plain_password, hashed_password)


# ── JWT ────────────────────────────────────────────────────────────────────

def create_access_token(
    subject: str | Any,
    expires_delta: timedelta | None = None,
) -> str:
    """Create a signed JWT access token."""
    expire = datetime.now(timezone.utc) + (
        expires_delta
        if expires_delta is not None
        else timedelta(minutes=settings.access_token_expire_minutes)
    )
    payload = {"sub": str(subject), "exp": expire, "type": "access"}
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def create_refresh_token(
    subject: str | Any,
    expires_delta: timedelta | None = None,
) -> str:
    """Create a signed JWT refresh token."""
    expire = datetime.now(timezone.utc) + (
        expires_delta
        if expires_delta is not None
        else timedelta(days=settings.refresh_token_expire_days)
    )
    payload = {"sub": str(subject), "exp": expire, "type": "refresh"}
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_token(token: str) -> dict[str, Any]:
    """
    Decode and verify a JWT token.
    Raises JWTError if token is invalid or expired.
    """
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )
        return payload
    except JWTError:
        raise
