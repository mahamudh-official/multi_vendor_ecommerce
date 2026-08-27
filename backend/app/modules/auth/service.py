"""
Business logic service for authentication workflows.
"""
import uuid

from jose import JWTError

from app.common.exceptions.handlers import (
    ConflictException,
    ForbiddenException,
    UnauthorizedException,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.modules.auth.models import User, UserRole
from app.modules.auth.repository import AuthRepository
from app.modules.auth.schemas import (
    LoginRequest,
    RefreshTokenResponse,
    RegisterRequest,
    TokenResponse,
    UserRead,
)


class AuthService:
    """Authentication business logic."""

    def __init__(self, repository: AuthRepository) -> None:
        self.repository = repository

    async def register(self, request: RegisterRequest) -> User:
        """
        Register a new user.
        Raises ConflictException if email is already taken.
        """
        existing = await self.repository.get_by_email(request.email)
        if existing is not None:
            raise ConflictException(detail="An account with this email already exists.")

        # Ensure role is only customer or seller (admin cannot self-register)
        role = UserRole(request.role)
        if role == UserRole.admin:
            raise ForbiddenException(detail="Cannot register as admin.")

        password_hash = hash_password(request.password)
        user = await self.repository.create(
            full_name=request.full_name,
            email=request.email,
            password_hash=password_hash,
            role=role,
        )
        return user

    async def login(self, request: LoginRequest) -> TokenResponse:
        """
        Authenticate user credentials and issue JWT token pair.
        Raises UnauthorizedException on invalid credentials.
        """
        user = await self.repository.get_by_email(request.email)
        if user is None:
            raise UnauthorizedException(detail="Invalid email or password.")

        if not verify_password(request.password, user.password_hash):
            raise UnauthorizedException(detail="Invalid email or password.")

        if not user.is_active:
            raise ForbiddenException(detail="Account has been deactivated.")

        access_token, expires_in = create_access_token(
            subject=user.id,
            role=user.role.value,
        )
        refresh_token = create_refresh_token(subject=user.id)

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=expires_in,
            user=UserRead.model_validate(user),
        )

    async def refresh_tokens(self, refresh_token: str) -> RefreshTokenResponse:
        """
        Validate a refresh token and issue a new access token.
        Raises UnauthorizedException if token is invalid, expired, or wrong type.
        """
        try:
            payload = decode_token(refresh_token)
        except JWTError:
            raise UnauthorizedException(detail="Invalid or expired refresh token.")

        token_type = payload.get("type")
        if token_type != "refresh":
            raise UnauthorizedException(detail="Invalid token type. Refresh token required.")

        sub = payload.get("sub")
        if not sub:
            raise UnauthorizedException(detail="Malformed token payload.")

        try:
            user_id = uuid.UUID(sub)
        except ValueError:
            raise UnauthorizedException(detail="Malformed token subject.")

        user = await self.repository.get_by_id(user_id)
        if user is None or not user.is_active:
            raise UnauthorizedException(detail="User no longer active or exists.")

        new_access_token, expires_in = create_access_token(
            subject=user.id,
            role=user.role.value,
        )

        return RefreshTokenResponse(
            access_token=new_access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=expires_in,
        )
