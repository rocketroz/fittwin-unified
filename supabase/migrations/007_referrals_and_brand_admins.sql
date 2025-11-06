-- Referrals and Brand Admins Migration
-- Adds tables for referral tracking and brand admin management

-- Create referrals table
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rid TEXT NOT NULL UNIQUE,
  referrer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active BOOLEAN DEFAULT TRUE,
  total_clicks INTEGER DEFAULT 0,
  total_signups INTEGER DEFAULT 0,
  total_conversions INTEGER DEFAULT 0,
  total_revenue_cents BIGINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create referral_events table
CREATE TABLE IF NOT EXISTS referral_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rid TEXT NOT NULL REFERENCES referrals(rid) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL, -- 'click', 'signup', 'conversion'
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  amount_cents INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create referral_rewards table
CREATE TABLE IF NOT EXISTS referral_rewards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rid TEXT NOT NULL REFERENCES referrals(rid) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  amount_cents INTEGER NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'cancelled'
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create brand_admins table
CREATE TABLE IF NOT EXISTS brand_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(brand_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_referrals_rid ON referrals(rid);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_events_rid ON referral_events(rid);
CREATE INDEX IF NOT EXISTS idx_referral_events_user ON referral_events(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_events_order ON referral_events(order_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_user ON referral_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_admins_brand ON brand_admins(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_admins_user ON brand_admins(user_id);

-- Functions for referral tracking
CREATE OR REPLACE FUNCTION increment_referral_signups(referral_rid TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE referrals
  SET total_signups = total_signups + 1,
      updated_at = NOW()
  WHERE rid = referral_rid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_referral_conversions(
  referral_rid TEXT,
  amount INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE referrals
  SET total_conversions = total_conversions + 1,
      total_revenue_cents = total_revenue_cents + amount,
      updated_at = NOW()
  WHERE rid = referral_rid;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_admins ENABLE ROW LEVEL SECURITY;

-- Users can view their own referrals
CREATE POLICY "Users can view their own referrals"
  ON referrals FOR SELECT
  USING (auth.uid() = referrer_user_id);

-- Users can create referrals
CREATE POLICY "Users can create referrals"
  ON referrals FOR INSERT
  WITH CHECK (auth.uid() = referrer_user_id);

-- Users can view their own referral rewards
CREATE POLICY "Users can view their own referral rewards"
  ON referral_rewards FOR SELECT
  USING (auth.uid() = user_id);

-- Brand admins can view their brand
CREATE POLICY "Brand admins can view their brand association"
  ON brand_admins FOR SELECT
  USING (auth.uid() = user_id);

-- Comments
COMMENT ON TABLE referrals IS 'Stores referral links and tracking data';
COMMENT ON TABLE referral_events IS 'Tracks referral events (clicks, signups, conversions)';
COMMENT ON TABLE referral_rewards IS 'Stores referral rewards earned by users';
COMMENT ON TABLE brand_admins IS 'Associates users with brands they can manage';
