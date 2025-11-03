"""
Configuration module for loading environment variables.
"""

import os
from pathlib import Path
from dataclasses import dataclass
from dotenv import load_dotenv

# Load .env file from project root
env_path = Path(__file__).parent.parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

# Export environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
JWT_SECRET = os.getenv("JWT_SECRET", "")
API_KEY = os.getenv("API_KEY", "staging-secret-key")
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")


@dataclass
class Settings:
    env: str = os.getenv("ENV", "dev")
    vendor_mode: str = os.getenv("VENDOR_MODE", "stub")
    api_key: str = os.getenv("API_KEY", "staging-secret-key")


settings = Settings()
