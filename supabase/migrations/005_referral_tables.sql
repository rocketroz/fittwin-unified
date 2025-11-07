-- Migration: 005_referral_tables.sql
-- Description: Create tables for referral system with attribution tracking
-- Author: Laura Tornga (@rocketroz)
-- Date: 2025-10-30

-- ============================================================================
-- REFERRALS
-- ============================================================================

CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rid TEXT NOT NULL UNIQUE, -- Referral ID (≥128-bit, URL-safe)
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL, -- Optional featured product
    campaign TEXT, -- Optional campaign identifier
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'fraud_flagged')),
    expires_at TIMESTAMP WITH TIME ZONE, -- NULL = no expiration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referrals_rid ON referrals(rid);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals(created_at DESC);

-- ============================================================================
-- REFERRAL EVENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('click', 'signup', 'purchase', 'reward_issued')),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- User who performed the action
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL, -- For purchase events
    attributed BOOLEAN DEFAULT FALSE, -- Whether event was successfully attributed
    fraud_check_passed BOOLEAN DEFAULT TRUE,
    metadata JSONB, -- Additional event data (IP, user agent, etc.)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_events_referral_id ON referral_events(referral_id);
CREATE INDEX IF NOT EXISTS idx_referral_events_event_type ON referral_events(event_type);
CREATE INDEX IF NOT EXISTS idx_referral_events_user_id ON referral_events(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_events_order_id ON referral_events(order_id);
CREATE INDEX IF NOT EXISTS idx_referral_events_attributed ON referral_events(attributed);
CREATE INDEX IF NOT EXISTS idx_referral_events_created_at ON referral_events(created_at DESC);

-- ============================================================================
-- REFERRAL REWARDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- User who made purchase
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    reward_type TEXT NOT NULL CHECK (reward_type IN ('credit', 'discount', 'cash', 'points')),
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'issued', 'cancelled')),
    issued_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_rewards_referral_id ON referral_rewards(referral_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_referrer_id ON referral_rewards(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_order_id ON referral_rewards(order_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_status ON referral_rewards(status);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_created_at ON referral_rewards(created_at DESC);

-- ============================================================================
-- REFERRAL FRAUD RULES
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_fraud_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name TEXT NOT NULL UNIQUE,
    rule_type TEXT NOT NULL CHECK (rule_type IN ('self_purchase', 'duplicate_attribution', 'suspicious_pattern', 'velocity_check')),
    enabled BOOLEAN DEFAULT TRUE,
    config JSONB NOT NULL, -- Rule-specific configuration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_fraud_rules_enabled ON referral_fraud_rules(enabled);

-- ============================================================================
-- Add foreign key to orders table for referral tracking
-- ============================================================================

ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS fk_orders_referral,
    ADD CONSTRAINT fk_orders_referral
    FOREIGN KEY (referral_id) REFERENCES referrals(id) ON DELETE SET NULL;

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_fraud_rules ENABLE ROW LEVEL SECURITY;

-- Referrals: Users can view and manage their own referrals
DROP POLICY IF EXISTS "Users can view their own referrals" ON referrals;
CREATE POLICY "Users can view their own referrals"
    ON referrals FOR SELECT
    USING (auth.uid() = referrer_id);

DROP POLICY IF EXISTS "Users can insert their own referrals" ON referrals;
CREATE POLICY "Users can insert their own referrals"
    ON referrals FOR INSERT
    WITH CHECK (auth.uid() = referrer_id);

DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
CREATE POLICY "Users can update their own referrals"
    ON referrals FOR UPDATE
    USING (auth.uid() = referrer_id);

-- Referral Events: Users can view events for their referrals
DROP POLICY IF EXISTS "Users can view events for their referrals" ON referral_events;
CREATE POLICY "Users can view events for their referrals"
    ON referral_events FOR SELECT
    USING (referral_id IN (SELECT id FROM referrals WHERE referrer_id = auth.uid()));

-- Referral Rewards: Users can view their own rewards
DROP POLICY IF EXISTS "Users can view their own rewards" ON referral_rewards;
CREATE POLICY "Users can view their own rewards"
    ON referral_rewards FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referee_id);

-- Fraud Rules: No direct user access (service role only)
-- RLS is enabled but no policies created

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_referrals_updated_at ON referrals;
CREATE TRIGGER update_referrals_updated_at
    BEFORE UPDATE ON referrals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_referral_rewards_updated_at ON referral_rewards;
CREATE TRIGGER update_referral_rewards_updated_at
    BEFORE UPDATE ON referral_rewards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_referral_fraud_rules_updated_at ON referral_fraud_rules;
CREATE TRIGGER update_referral_fraud_rules_updated_at
    BEFORE UPDATE ON referral_fraud_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED FRAUD RULES
-- ============================================================================

INSERT INTO referral_fraud_rules (rule_name, rule_type, enabled, config) VALUES
    ('self_purchase_block', 'self_purchase', true, '{"block": true, "message": "Self-referral not allowed"}'),
    ('duplicate_attribution_block', 'duplicate_attribution', true, '{"block": true, "message": "Order already attributed"}'),
    ('velocity_check_hourly', 'velocity_check', true, '{"max_events_per_hour": 10, "event_types": ["click", "signup"]}'),
    ('suspicious_ip_pattern', 'suspicious_pattern', true, '{"check_ip_diversity": true, "min_unique_ips": 3}')
ON CONFLICT (rule_name) DO NOTHING;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE referrals IS 'Referral links created by users';
COMMENT ON TABLE referral_events IS 'Attribution events for referrals (clicks, signups, purchases)';
COMMENT ON TABLE referral_rewards IS 'Rewards issued to referrers';
COMMENT ON TABLE referral_fraud_rules IS 'Fraud detection rules for referral system';
