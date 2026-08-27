"""
Auth router — stub. Full implementation in Step 2.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/auth", tags=["auth"])

# Step 2 will add:
#   POST /auth/register
#   POST /auth/login
#   POST /auth/refresh
#   POST /auth/logout
