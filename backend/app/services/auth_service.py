"""
Authentication Service

Handles user authentication, JWT token generation, password security,
and session management.
"""

from typing import Dict, Optional, Tuple
from datetime import datetime, timedelta
import hashlib
import secrets
import jwt
import httpx
from passlib.context import CryptContext
from supabase import Client
import os


class AuthService:
    """Service for user authentication and security."""

    def __init__(self, supabase_client: Client):
        """Initialize auth service."""
        self.db = supabase_client
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.jwt_secret = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
        self.jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
        self.access_token_expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
        self.refresh_token_expire_days = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

    async def signup(
        self,
        email: str,
        password: str,
        name: Optional[str] = None
    ) -> Dict[str, any]:
        """
        Register a new user.

        Args:
            email: User email
            password: User password
            name: User name (optional)

        Returns:
            User data and tokens

        Raises:
            ValueError: If email already exists or password is weak
        """
        # Check if user already exists
        existing_user = self.db.table("users")\
            .select("id")\
            .eq("email", email)\
            .execute()

        if existing_user.data:
            raise ValueError("Email already registered")

        # Validate password strength
        if not self._is_password_strong(password):
            raise ValueError(
                "Password must be at least 8 characters with uppercase, "
                "lowercase, number, and special character"
            )

        # Check password against breach database
        if await self._is_password_breached(password):
            raise ValueError(
                "This password has been found in a data breach. "
                "Please choose a different password."
            )

        # Hash password
        password_hash = self.pwd_context.hash(password)

        # Create user
        user_data = {
            "email": email,
            "password_hash": password_hash,
            "name": name,
            "status": "active",
            "role": "shopper"
        }

        user_response = self.db.table("users")\
            .insert(user_data)\
            .execute()

        user = user_response.data[0]

        # Generate tokens
        access_token = self._create_access_token(user["id"])
        refresh_token = self._create_refresh_token(user["id"])

        # Store refresh token
        await self._store_refresh_token(user["id"], refresh_token)

        return {
            "user": {
                "id": user["id"],
                "email": user["email"],
                "name": user.get("name"),
                "role": user["role"]
            },
            "tokens": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "expires_in": self.access_token_expire_minutes * 60
            }
        }

    async def signin(self, email: str, password: str) -> Dict[str, any]:
        """
        Sign in a user.

        Args:
            email: User email
            password: User password

        Returns:
            User data and tokens

        Raises:
            ValueError: If credentials are invalid
        """
        # Get user
        user_response = self.db.table("users")\
            .select("*")\
            .eq("email", email)\
            .execute()

        if not user_response.data:
            raise ValueError("Invalid email or password")

        user = user_response.data[0]

        # Check if account is active
        if user["status"] != "active":
            raise ValueError("Account is not active")

        # Verify password
        if not self.pwd_context.verify(password, user["password_hash"]):
            # Increment failed attempts
            await self._increment_failed_attempts(user["id"])
            raise ValueError("Invalid email or password")

        # Reset failed attempts on successful login
        await self._reset_failed_attempts(user["id"])

        # Generate tokens
        access_token = self._create_access_token(user["id"])
        refresh_token = self._create_refresh_token(user["id"])

        # Store refresh token
        await self._store_refresh_token(user["id"], refresh_token)

        return {
            "user": {
                "id": user["id"],
                "email": user["email"],
                "name": user.get("name"),
                "role": user["role"]
            },
            "tokens": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "expires_in": self.access_token_expire_minutes * 60
            }
        }

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, str]:
        """
        Refresh access token using refresh token.

        Args:
            refresh_token: Refresh token

        Returns:
            New access token

        Raises:
            ValueError: If refresh token is invalid
        """
        try:
            payload = jwt.decode(
                refresh_token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )
            user_id = payload.get("sub")
            token_type = payload.get("type")

            if token_type != "refresh":
                raise ValueError("Invalid token type")

            # Verify refresh token exists in database
            token_response = self.db.table("refresh_tokens")\
                .select("*")\
                .eq("user_id", user_id)\
                .eq("token", refresh_token)\
                .eq("revoked", False)\
                .execute()

            if not token_response.data:
                raise ValueError("Invalid or revoked refresh token")

            # Generate new access token
            access_token = self._create_access_token(user_id)

            return {
                "access_token": access_token,
                "token_type": "bearer",
                "expires_in": self.access_token_expire_minutes * 60
            }

        except jwt.ExpiredSignatureError:
            raise ValueError("Refresh token has expired")
        except jwt.InvalidTokenError:
            raise ValueError("Invalid refresh token")

    async def signout(self, refresh_token: str) -> None:
        """
        Sign out a user by revoking refresh token.

        Args:
            refresh_token: Refresh token to revoke
        """
        try:
            payload = jwt.decode(
                refresh_token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )
            user_id = payload.get("sub")

            # Revoke refresh token
            self.db.table("refresh_tokens")\
                .update({"revoked": True})\
                .eq("user_id", user_id)\
                .eq("token", refresh_token)\
                .execute()

        except jwt.InvalidTokenError:
            pass  # Token already invalid

    def verify_access_token(self, token: str) -> Dict[str, any]:
        """
        Verify and decode access token.

        Args:
            token: Access token

        Returns:
            Token payload

        Raises:
            ValueError: If token is invalid
        """
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )

            if payload.get("type") != "access":
                raise ValueError("Invalid token type")

            return payload

        except jwt.ExpiredSignatureError:
            raise ValueError("Token has expired")
        except jwt.InvalidTokenError:
            raise ValueError("Invalid token")

    def _create_access_token(self, user_id: str) -> str:
        """Create JWT access token."""
        expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
        payload = {
            "sub": user_id,
            "type": "access",
            "exp": expire,
            "iat": datetime.utcnow()
        }
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)

    def _create_refresh_token(self, user_id: str) -> str:
        """Create JWT refresh token."""
        expire = datetime.utcnow() + timedelta(days=self.refresh_token_expire_days)
        payload = {
            "sub": user_id,
            "type": "refresh",
            "exp": expire,
            "iat": datetime.utcnow(),
            "jti": secrets.token_urlsafe(32)  # Unique token ID
        }
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)

    async def _store_refresh_token(self, user_id: str, token: str) -> None:
        """Store refresh token in database."""
        expire = datetime.utcnow() + timedelta(days=self.refresh_token_expire_days)
        self.db.table("refresh_tokens")\
            .insert({
                "user_id": user_id,
                "token": token,
                "expires_at": expire.isoformat(),
                "revoked": False
            })\
            .execute()

    async def _increment_failed_attempts(self, user_id: str) -> None:
        """Increment failed login attempts."""
        self.db.rpc("increment_failed_attempts", {"user_id": user_id}).execute()

    async def _reset_failed_attempts(self, user_id: str) -> None:
        """Reset failed login attempts."""
        self.db.table("users")\
            .update({"failed_attempts": 0})\
            .eq("id", user_id)\
            .execute()

    def _is_password_strong(self, password: str) -> bool:
        """Check if password meets strength requirements."""
        if len(password) < 8:
            return False

        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password)

        return has_upper and has_lower and has_digit and has_special

    async def _is_password_breached(self, password: str) -> bool:
        """
        Check if password has been found in data breaches using HaveIBeenPwned API.

        Uses k-anonymity model - only sends first 5 chars of SHA-1 hash.
        """
        try:
            # Hash password with SHA-1
            sha1_hash = hashlib.sha1(password.encode()).hexdigest().upper()
            prefix = sha1_hash[:5]
            suffix = sha1_hash[5:]

            # Query HaveIBeenPwned API
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"https://api.pwnedpasswords.com/range/{prefix}",
                    timeout=5.0
                )

            if response.status_code == 200:
                # Check if our suffix appears in the response
                hashes = response.text.split("\r\n")
                for hash_line in hashes:
                    hash_suffix, count = hash_line.split(":")
                    if hash_suffix == suffix:
                        return True  # Password found in breach

            return False  # Password not found in breach

        except Exception:
            # If API is down, don't block registration
            return False
