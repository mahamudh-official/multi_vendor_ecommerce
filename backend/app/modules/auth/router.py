"""
FastAPI router for authentication endpoints.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.modules.auth.dependencies import (
    get_auth_service,
    get_current_active_user,
)
from app.modules.auth.models import User
from app.modules.auth.schemas import (
    LoginRequest,
    MessageResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    RegisterRequest,
    TokenResponse,
    UserRead,
)
from app.modules.auth.service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new customer or seller account",
)
async def register(
    request: RegisterRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> UserRead:
    """
    Register a new customer or seller account.
    - Password is automatically hashed with Argon2.
    - Admin registration is forbidden through this endpoint.
    - Returns the created user object without sensitive information.
    """
    user = await auth_service.register(request)
    return UserRead.model_validate(user)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Log in and retrieve access/refresh tokens",
)
async def login(
    request: LoginRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> TokenResponse:
    """
    Authenticate with email and password.
    - Returns an access token, refresh token, expiry metadata, and user profile.
    """
    return await auth_service.login(request)


@router.get(
    "/me",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Get currently authenticated user profile",
)
async def get_me(
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> UserRead:
    """
    Return the profile of the user identified by the Bearer access token.
    """
    return UserRead.model_validate(current_user)


@router.post(
    "/refresh",
    response_model=RefreshTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh an expired access token using a valid refresh token",
)
async def refresh_token(
    request: RefreshTokenRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> RefreshTokenResponse:
    """
    Submit a valid refresh token to obtain a fresh access token.
    - Rejects access tokens used in place of refresh tokens.
    """
    return await auth_service.refresh_tokens(request.refresh_token)


@router.post(
    "/logout",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Log out of current session",
)
async def logout() -> MessageResponse:
    """
    Stateless logout endpoint.
    - Client must discard access and refresh tokens from local secure storage.
    """
    return MessageResponse(message="Successfully logged out.")
