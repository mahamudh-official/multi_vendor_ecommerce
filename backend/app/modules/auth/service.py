"""
Auth service — stub. Full implementation in Step 2.
"""
from app.modules.auth.repository import AuthRepository


class AuthService:
    """Business logic for authentication. Implemented in Step 2."""

    def __init__(self, repository: AuthRepository) -> None:
        self.repository = repository
