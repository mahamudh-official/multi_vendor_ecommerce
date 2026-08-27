"""
FastAPI dependencies for authentication and authorization.
"""
import uuid
from typing import Annotated, Callable

from fastapi import Depends, Header, HTTPException, status
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.handlers import ForbiddenException, UnauthorizedException
from app.core.database import get_db
from app.core.security import decode_token
from app.modules.auth.models import User, UserRole
from app.modules.auth.repository import AuthRepository
from app.modules.auth.service import AuthService


def get_auth_service(session: AsyncSession = Depends(get_db)) -> AuthService:
    """Dependency providing an AuthService instance bound to request DB session."""
    repository = AuthRepository(session)
    return AuthService(repository)


async def get_current_user(
    authorization: Annotated[str | None, Header(description="Bearer <token>")] = None,
    session: AsyncSession = Depends(get_db),
) -> User:
    """
    Authenticate request via Bearer JWT in Authorization header.
    Validates token signature, expiration, and ensures type == 'access'.
    """
    if not authorization:
        raise UnauthorizedException(detail="Authorization header missing.")

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise UnauthorizedException(detail="Invalid Authorization header format. Expected 'Bearer <token>'.")

    token = parts[1]
    try:
        payload = decode_token(token)
    except JWTError:
        raise UnauthorizedException(detail="Invalid or expired authentication token.")

    token_type = payload.get("type")
    if token_type != "access":
        raise UnauthorizedException(detail="Invalid token type. Access token required.")

    sub = payload.get("sub")
    if not sub:
        raise UnauthorizedException(detail="Malformed token.")

    try:
        user_id = uuid.UUID(sub)
    except ValueError:
        raise UnauthorizedException(detail="Malformed token subject.")

    repository = AuthRepository(session)
    user = await repository.get_by_id(user_id)
    if user is None:
        raise UnauthorizedException(detail="User account no longer exists.")

    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Ensure the authenticated user is currently active."""
    if not current_user.is_active:
        raise ForbiddenException(detail="Account is inactive.")
    return current_user


def require_role(*allowed_roles: UserRole) -> Callable:
    """
    Factory creating a dependency that enforces the current user has one of the allowed roles.
    Example: Depends(require_role(UserRole.seller, UserRole.admin))
    """
    async def role_checker(
        current_user: Annotated[User, Depends(get_current_active_user)],
    ) -> User:
        if current_user.role not in allowed_roles:
            roles_str = ", ".join(r.value for r in allowed_roles)
            raise ForbiddenException(
                detail=f"Action requires one of the following roles: {roles_str}."
            )
        return current_user

    return role_checker
