"""
Referral Service

Handles referral program including RID generation, tracking,
attribution, and reward management.
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
import secrets
import hashlib
from supabase import Client


class ReferralService:
    """Service for managing referral program."""

    RID_BYTES = 16  # 128-bit RID for security

    def __init__(self, supabase_client: Client):
        """Initialize referral service."""
        self.db = supabase_client

    async def generate_referral_link(self, user_id: str) -> Dict[str, str]:
        """
        Generate a unique referral link for a user.

        Args:
            user_id: User ID

        Returns:
            Referral ID and shareable URL
        """
        # Generate cryptographically secure RID
        rid = secrets.token_urlsafe(self.RID_BYTES)

        # Store referral
        self.db.table("referrals")\
            .insert({
                "rid": rid,
                "referrer_user_id": user_id,
                "active": True
            })\
            .execute()

        # Generate shareable URL
        base_url = "https://fittwin.com"  # Replace with actual domain
        referral_url = f"{base_url}?rid={rid}"

        return {
            "rid": rid,
            "url": referral_url,
            "short_url": await self._generate_short_url(referral_url)
        }

    async def track_referral_click(
        self,
        rid: str,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ) -> None:
        """
        Track a referral link click.

        Args:
            rid: Referral ID
            ip_address: IP address of visitor
            user_agent: User agent string
        """
        # Verify RID exists
        referral_response = self.db.table("referrals")\
            .select("id")\
            .eq("rid", rid)\
            .eq("active", True)\
            .execute()

        if not referral_response.data:
            return  # Invalid or inactive RID

        # Track click event
        self.db.table("referral_events")\
            .insert({
                "rid": rid,
                "event_type": "click",
                "metadata": {
                    "ip_address": ip_address,
                    "user_agent": user_agent
                }
            })\
            .execute()

    async def track_referral_signup(self, rid: str, new_user_id: str) -> None:
        """
        Track a successful signup from a referral.

        Args:
            rid: Referral ID
            new_user_id: ID of newly signed up user
        """
        # Verify RID exists
        referral_response = self.db.table("referrals")\
            .select("*")\
            .eq("rid", rid)\
            .eq("active", True)\
            .execute()

        if not referral_response.data:
            return  # Invalid or inactive RID

        referral = referral_response.data[0]

        # Prevent self-referral fraud
        if referral["referrer_user_id"] == new_user_id:
            return

        # Track signup event
        self.db.table("referral_events")\
            .insert({
                "rid": rid,
                "event_type": "signup",
                "user_id": new_user_id,
                "metadata": {}
            })\
            .execute()

        # Update referral stats
        self.db.rpc("increment_referral_signups", {"referral_rid": rid}).execute()

    async def track_referral_conversion(
        self,
        rid: str,
        order_id: str,
        amount_cents: int
    ) -> None:
        """
        Track a purchase conversion from a referral.

        Args:
            rid: Referral ID
            order_id: Order ID
            amount_cents: Order amount in cents
        """
        # Verify RID exists
        referral_response = self.db.table("referrals")\
            .select("*")\
            .eq("rid", rid)\
            .eq("active", True)\
            .execute()

        if not referral_response.data:
            return  # Invalid or inactive RID

        referral = referral_response.data[0]

        # Track conversion event
        self.db.table("referral_events")\
            .insert({
                "rid": rid,
                "event_type": "conversion",
                "order_id": order_id,
                "amount_cents": amount_cents,
                "metadata": {}
            })\
            .execute()

        # Update referral stats
        self.db.rpc("increment_referral_conversions", {
            "referral_rid": rid,
            "amount": amount_cents
        }).execute()

        # Award referral reward to referrer
        await self._award_referral_reward(
            referral["referrer_user_id"],
            rid,
            order_id,
            amount_cents
        )

    async def get_referral_stats(self, user_id: str) -> Dict[str, Any]:
        """
        Get referral statistics for a user.

        Args:
            user_id: User ID

        Returns:
            Referral performance stats
        """
        # Get user's referrals
        referrals_response = self.db.table("referrals")\
            .select("*")\
            .eq("referrer_user_id", user_id)\
            .execute()

        if not referrals_response.data:
            return {
                "total_referrals": 0,
                "total_clicks": 0,
                "total_signups": 0,
                "total_conversions": 0,
                "total_revenue_cents": 0,
                "total_rewards_cents": 0
            }

        rids = [r["rid"] for r in referrals_response.data]

        # Get event counts
        events_response = self.db.table("referral_events")\
            .select("event_type, amount_cents")\
            .in_("rid", rids)\
            .execute()

        clicks = 0
        signups = 0
        conversions = 0
        revenue_cents = 0

        for event in events_response.data:
            if event["event_type"] == "click":
                clicks += 1
            elif event["event_type"] == "signup":
                signups += 1
            elif event["event_type"] == "conversion":
                conversions += 1
                revenue_cents += event.get("amount_cents", 0)

        # Get total rewards earned
        rewards_response = self.db.table("referral_rewards")\
            .select("amount_cents")\
            .eq("user_id", user_id)\
            .execute()

        total_rewards = sum(r["amount_cents"] for r in rewards_response.data)

        return {
            "total_referrals": len(referrals_response.data),
            "total_clicks": clicks,
            "total_signups": signups,
            "total_conversions": conversions,
            "total_revenue_cents": revenue_cents,
            "total_rewards_cents": total_rewards,
            "conversion_rate": (conversions / signups * 100) if signups > 0 else 0
        }

    async def get_referral_rewards(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get referral rewards for a user.

        Args:
            user_id: User ID
            limit: Maximum number of rewards to return
            offset: Offset for pagination

        Returns:
            List of rewards
        """
        rewards_response = self.db.table("referral_rewards")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()

        return rewards_response.data

    async def _award_referral_reward(
        self,
        referrer_user_id: str,
        rid: str,
        order_id: str,
        order_amount_cents: int
    ) -> None:
        """
        Award a referral reward to the referrer.

        Args:
            referrer_user_id: ID of user who made the referral
            rid: Referral ID
            order_id: Order ID that triggered the reward
            order_amount_cents: Order amount in cents
        """
        # Calculate reward (e.g., 10% of order value, max $50)
        reward_cents = min(int(order_amount_cents * 0.10), 5000)

        # Create reward record
        self.db.table("referral_rewards")\
            .insert({
                "user_id": referrer_user_id,
                "rid": rid,
                "order_id": order_id,
                "amount_cents": reward_cents,
                "currency": "USD",
                "status": "pending"
            })\
            .execute()

        # TODO: Integrate with payment system to actually credit the reward
        # This could be store credit, account balance, or direct payout

    async def _generate_short_url(self, long_url: str) -> str:
        """
        Generate a short URL for easier sharing.

        Args:
            long_url: Long URL to shorten

        Returns:
            Short URL
        """
        # Generate short code from hash
        hash_digest = hashlib.sha256(long_url.encode()).hexdigest()[:8]

        # In production, store this mapping in database
        # For now, return a placeholder
        return f"https://fittwin.co/{hash_digest}"
