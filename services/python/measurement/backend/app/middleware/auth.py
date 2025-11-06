"""
Authentication Middleware

Handles JWT token verification and user authentication for protected routes.
"""

from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
import jwt
import os


security = HTTPBearer()


class AuthMiddleware:
    """Middleware for handling authentication."""

    def __init__(self):
        """Initialize auth middleware."""
        self.jwt_secret = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
        self.jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")

    async def verify_token(
        self,
        credentials: HTTPAuthorizationCredentials
    ) -> dict:
        """
        Verify JWT token and return payload.

        Args:
            credentials: HTTP authorization credentials

        Returns:
            Token payload

        Raises:
            HTTPException: If token is invalid
        """
        token = credentials.credentials

        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )

            if payload.get("type") != "access":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token type"
                )

            return payload

        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )

    def get_current_user_id(self, payload: dict) -> str:
        """
        Extract user ID from token payload.

        Args:
            payload: Token payload

        Returns:
            User ID

        Raises:
            HTTPException: If user ID not found
        """
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        return user_id


# Global auth middleware instance
auth_middleware = AuthMiddleware()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = security
) -> str:
    """
    Dependency to get current authenticated user ID.

    Args:
        credentials: HTTP authorization credentials

    Returns:
        User ID

    Usage:
        @app.get("/protected")
        async def protected_route(user_id: str = Depends(get_current_user)):
            return {"user_id": user_id}
    """
    payload = await auth_middleware.verify_token(credentials)
    return auth_middleware.get_current_user_id(payload)


async def get_optional_user(
    request: Request
) -> Optional[str]:
    """
    Dependency to get current user ID if authenticated, None otherwise.

    Args:
        request: HTTP request

    Returns:
        User ID or None

    Usage:
        @app.get("/optional")
        async def optional_route(user_id: Optional[str] = Depends(get_optional_user)):
            if user_id:
                return {"authenticated": True, "user_id": user_id}
            return {"authenticated": False}
    """
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None

    token = auth_header.replace("Bearer ", "")

    try:
        payload = jwt.decode(
            token,
            auth_middleware.jwt_secret,
            algorithms=[auth_middleware.jwt_algorithm]
        )
        return payload.get("sub")
    except jwt.InvalidTokenError:
        return None
