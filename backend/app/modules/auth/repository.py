"""
Auth repository — stub. Full implementation in Step 2.
"""
from sqlalchemy.ext.asyncio import AsyncSession


class AuthRepository:
    """Data access layer for User model. Implemented in Step 2."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session
