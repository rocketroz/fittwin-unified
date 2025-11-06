"""
Referral system router for FitTwin Platform.

Adapted from fittwindev/fittwin referral.service.ts
Provides viral growth capabilities with attribution tracking.
"""

from typing import List, Dict, Any
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field

from app.core.config import settings
from app.schemas.errors import ErrorResponse

router = APIRouter(prefix="/referrals", tags=["referrals"])


# Pydantic Models
class CreateReferralRequest(BaseModel):
    product_id: str | None = Field(None, description="Optional product to feature in referral")
    campaign: str | None = Field(None, description="Campaign identifier")


class ReferralResponse(BaseModel):
    rid: str  # Referral ID (≥128-bit)
    referrer_id: str
    share_url: str
    product_id: str | None
    campaign: str | None
    created_at: str
    expires_at: str | None


class ReferralEventResponse(BaseModel):
    event_id: str
    rid: str
    event_type: str  # click, signup, purchase, reward_issued
    attributed: bool
    metadata: Dict[str, Any]
    created_at: str


class ReferralSummaryResponse(BaseModel):
    rid: str
    clicks: int
    signups: int
    purchases: int
    revenue_cents: int
    rewards_issued: int
    status: str  # active, expired, fraud_flagged


@router.post("", response_model=ReferralResponse, status_code=status.HTTP_201_CREATED)
async def create_referral(
    request: CreateReferralRequest,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Create a new referral link.
    
    Generates unique RID (≥128-bit) and shareable URL.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual referral creation
    # 1. Get user ID from auth context
    # 2. Generate unique RID (≥128-bit, cryptographically secure)
    # 3. Create referral record
    # 4. Generate share URL with RID
    # 5. Return referral details
    
    import secrets
    rid = secrets.token_urlsafe(16)  # 128-bit
    
    return ReferralResponse(
        rid=rid,
        referrer_id="user-demo-123",
        share_url=f"https://fittwin.com/r/{rid}",
        product_id=request.product_id,
        campaign=request.campaign,
        created_at="2025-10-30T12:00:00Z",
        expires_at=None
    )


@router.get("/{rid}", response_model=ReferralSummaryResponse)
async def get_referral(
    rid: str,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Get referral summary with performance metrics.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual referral retrieval
    # 1. Query referral by RID
    # 2. Verify user owns the referral
    # 3. Calculate performance metrics
    # 4. Return summary
    
    return ReferralSummaryResponse(
        rid=rid,
        clicks=0,
        signups=0,
        purchases=0,
        revenue_cents=0,
        rewards_issued=0,
        status="active"
    )


@router.get("/{rid}/events", response_model=List[ReferralEventResponse])
async def list_referral_events(
    rid: str,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    List attribution events for a referral.
    
    Includes clicks, signups, purchases, and reward issuance.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual event listing
    # 1. Query referral by RID
    # 2. Verify user owns the referral
    # 3. Query attribution events
    # 4. Return event list
    
    return []


@router.post("/{rid}/track-click", status_code=status.HTTP_204_NO_CONTENT)
async def track_click(
    rid: str,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Track a referral link click.
    
    Used for analytics and fraud detection.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual click tracking
    # 1. Validate RID exists
    # 2. Check for fraud patterns (duplicate IPs, bots)
    # 3. Create click event
    # 4. Return 204 No Content
    
    return None


@router.post("/attribute-purchase", status_code=status.HTTP_200_OK)
async def attribute_purchase(
    order_id: str,
    rid: str | None = None,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Attribute a purchase to a referral.
    
    Called internally during checkout flow.
    Enforces fraud rules (self-purchase, duplicate attribution).
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual purchase attribution
    # 1. Validate order exists
    # 2. If RID provided, validate referral exists
    # 3. Check fraud rules:
    #    - Self-purchase (referrer == buyer)
    #    - Duplicate attribution (order already attributed)
    #    - Suspicious patterns
    # 4. Create purchase event if valid
    # 5. Queue reward after return window
    # 6. Return attribution result
    
    return {
        "order_id": order_id,
        "rid": rid,
        "attributed": rid is not None,
        "message": "Purchase attributed successfully" if rid else "No referral attribution"
    }
