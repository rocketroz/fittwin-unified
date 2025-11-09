-- Referrals and Brand Admins Migration
-- Adds tables for referral tracking and brand admin management

-- Create referrals table
-- Migration 007 adds auxiliary indexes/policies to the referral schema from 005 plus brand admins.
-- Make sure 005_referral_tables.sql has already run before applying this file.

-- Create brand_admins table
CREATE TABLE IF NOT EXISTS brand_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(brand_id, user_id)
);

-- Create indexes
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
ALTER TABLE brand_admins ENABLE ROW LEVEL SECURITY;

-- Brand admins can view their brand
CREATE POLICY "Brand admins can view their brand association"
  ON brand_admins FOR SELECT
  USING (auth.uid() = user_id);

-- Comments
COMMENT ON TABLE brand_admins IS 'Associates users with brands they can manage';
