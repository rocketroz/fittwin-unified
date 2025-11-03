"""
Authentication Router

Handles user signup, signin, token refresh, and signout.
Complete implementation with auth service integration.
"""

import logging

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from typing import Optional
from supabase import create_client

from app.services.auth_service import AuthService
from app.middleware.auth import get_current_user
from app.core.config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY


logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _init_supabase_client():
    """
    Create a Supabase client if credentials are available.

    Returns:
        Supabase client instance or None when not configured/available.
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.info("Supabase credentials missing; auth routes will be disabled.")
        return None

    try:
        return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.warning("Supabase client initialization failed: %s", exc)
        return None


supabase = _init_supabase_client()
auth_service = AuthService(supabase) if supabase else None


def _require_auth_service() -> AuthService:
    """
    Ensure the authentication service is available, otherwise raise HTTP 503.
    """
    if auth_service is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is not configured. "
                   "Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to enable auth routes.",
        )
    return auth_service


# Request/Response Models
class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None


class SigninRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    user: dict
    tokens: dict


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup(request: SignupRequest):
    """
    Register a new user.

    Args:
        request: Signup request with email and password

    Returns:
        User data and authentication tokens

    Raises:
        HTTPException: If signup fails
    """
    service = _require_auth_service()

    try:
        result = await service.signup(
            email=request.email,
            password=request.password,
            name=request.name
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/signin", response_model=AuthResponse)
async def signin(request: SigninRequest):
    """
    Sign in a user.

    Args:
        request: Signin request with email and password

    Returns:
        User data and authentication tokens

    Raises:
        HTTPException: If signin fails
    """
    service = _require_auth_service()

    try:
        result = await service.signin(
            email=request.email,
            password=request.password
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest):
    """
    Refresh access token using refresh token.

    Args:
        request: Refresh token request

    Returns:
        New access token

    Raises:
        HTTPException: If refresh fails
    """
    service = _require_auth_service()

    try:
        result = await service.refresh_access_token(request.refresh_token)
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/signout", status_code=status.HTTP_204_NO_CONTENT)
async def signout(request: RefreshTokenRequest):
    """
    Sign out a user by revoking refresh token.

    Args:
        request: Refresh token to revoke

    Returns:
        No content
    """
    service = _require_auth_service()
    await service.signout(request.refresh_token)


@router.get("/me")
async def get_current_user_info(user_id: str = Depends(get_current_user)):
    """
    Get current authenticated user information.

    Args:
        user_id: Current user ID from JWT token

    Returns:
        User information

    Raises:
        HTTPException: If user not found
    """
    if supabase is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is not configured."
        )

    user_response = supabase.table("users")\
        .select("id, email, name, role, created_at")\
        .eq("id", user_id)\
        .single()\
        .execute()

    if not user_response.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_response.data
