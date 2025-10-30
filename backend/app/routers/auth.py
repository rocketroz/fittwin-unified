"""
Authentication Router

Handles user signup, signin, token refresh, and signout.
Complete implementation with auth service integration.
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from typing import Optional
from supabase import create_client
import os

from backend.app.services.auth_service import AuthService
from backend.app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


# Initialize Supabase client
supabase = create_client(
    os.getenv("SUPABASE_URL", ""),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
)

# Initialize auth service
auth_service = AuthService(supabase)


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
    try:
        result = await auth_service.signup(
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
    try:
        result = await auth_service.signin(
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
    try:
        result = await auth_service.refresh_access_token(request.refresh_token)
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
    await auth_service.signout(request.refresh_token)


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
