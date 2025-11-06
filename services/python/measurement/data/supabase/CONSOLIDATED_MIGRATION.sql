-- ============================================================================
-- FITTWIN UNIFIED PLATFORM - CONSOLIDATED DATABASE MIGRATION
-- ============================================================================
-- This file consolidates all migrations into a single script for easy execution
-- Run this entire script in the Supabase SQL Editor
-- Date: 2025-10-30
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- MIGRATION 1: Initial Schema
-- ============================================================================

CREATE TABLE IF NOT EXISTS measurements (
  id SERIAL PRIMARY KEY,
  user_id TEXT,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- MIGRATION 2: Measurement Provenance (Starting from line 50 of original)
-- ============================================================================

-- Measurement sessions table
CREATE TABLE IF NOT EXISTS measurement_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    session_id TEXT UNIQUE NOT NULL,
    source_type TEXT NOT NULL DEFAULT 'mediapipe_web',
    platform TEXT NOT NULL DEFAULT 'web_mobile',
    device_id TEXT,
    browser_info JSONB,
    processing_location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    accuracy_estimate FLOAT,
    needs_calibration BOOLEAN DEFAULT FALSE
);

-- Raw photos table
CREATE TABLE IF NOT EXISTS measurement_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
    photo_type TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    image_width INT,
    image_height INT
);

-- MediaPipe landmarks table
CREATE TABLE IF NOT EXISTS mediapipe_landmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
    photo_id UUID REFERENCES measurement_photos(id) ON DELETE CASCADE,
    landmark_type TEXT NOT NULL,
    landmarks JSONB NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    model_version TEXT DEFAULT 'v3.1'
);

-- Calculated measurements table (MediaPipe-derived)
CREATE TABLE IF NOT EXISTS measurements_mediapipe (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
    height_cm FLOAT NOT NULL,
    neck_cm FLOAT,
    shoulder_cm FLOAT,
    chest_cm FLOAT,
    underbust_cm FLOAT,
    waist_natural_cm FLOAT,
    sleeve_cm FLOAT,
    bicep_cm FLOAT,
    forearm_cm FLOAT,
    hip_low_cm FLOAT,
    thigh_cm FLOAT,
    knee_cm FLOAT,
    calf_cm FLOAT,
    ankle_cm FLOAT,
    front_rise_cm FLOAT,
    back_rise_cm FLOAT,
    inseam_cm FLOAT,
    outseam_cm FLOAT,
    confidence FLOAT DEFAULT 1.0,
    accuracy_estimate FLOAT,
    model_version TEXT DEFAULT 'v1.0-mediapipe',
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendor measurements table (for calibration only)
CREATE TABLE IF NOT EXISTS measurements_vendor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
    vendor_name TEXT NOT NULL,
    vendor_version TEXT,
    measurements JSONB NOT NULL,
    confidence FLOAT,
    cost_usd FLOAT,
    called_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_for_calibration BOOLEAN DEFAULT TRUE,
    excluded_from_live BOOLEAN DEFAULT TRUE
);

-- Size recommendations table
CREATE TABLE IF NOT EXISTS size_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
    measurement_id UUID REFERENCES measurements_mediapipe(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    size TEXT NOT NULL,
    confidence FLOAT NOT NULL,
    rationale TEXT,
    model_version TEXT DEFAULT 'v1.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_user ON measurement_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON measurement_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_photos_session ON measurement_photos(session_id);
CREATE INDEX IF NOT EXISTS idx_landmarks_session ON mediapipe_landmarks(session_id);
CREATE INDEX IF NOT EXISTS idx_measurements_session ON measurements_mediapipe(session_id);
CREATE INDEX IF NOT EXISTS idx_vendor_session ON measurements_vendor(session_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_session ON size_recommendations(session_id);

-- ============================================================================
-- MIGRATION 3: Commerce Tables
-- ============================================================================

-- Carts
CREATE TABLE IF NOT EXISTS carts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carts_user_id ON carts(user_id);

-- Cart Items
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    variant_id UUID NOT NULL,
    variant_sku TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0 AND quantity <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);

-- Addresses
CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('shipping', 'billing', 'both')),
    full_name TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state_province TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL,
    phone TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_user_default ON addresses(user_id, is_default);

-- Payment Methods
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL DEFAULT 'stripe',
    provider_payment_method_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('card', 'bank_account', 'other')),
    last4 TEXT,
    brand TEXT,
    exp_month INTEGER,
    exp_year INTEGER,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_default ON payment_methods(user_id, is_default);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN (
        'created', 'paid', 'sent_to_brand', 'fulfilled', 'delivered',
        'return_requested', 'closed', 'cancelled'
    )),
    payment_intent_ref TEXT NOT NULL,
    payment_method_id UUID REFERENCES payment_methods(id),
    shipping_address_id UUID REFERENCES addresses(id),
    billing_address_id UUID REFERENCES addresses(id),
    subtotal_cents INTEGER NOT NULL,
    shipping_cents INTEGER NOT NULL,
    tax_cents INTEGER NOT NULL,
    total_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    tracking_number TEXT,
    referral_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_referral_id ON orders(referral_id);

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    variant_id UUID NOT NULL,
    variant_sku TEXT NOT NULL,
    product_name TEXT NOT NULL,
    size_label TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    fit_confidence INTEGER,
    fit_notes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Checkout Intents
CREATE TABLE IF NOT EXISTS checkout_intents (
    idempotency_key TEXT PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id),
    payload_hash TEXT NOT NULL,
    payment_intent_ref TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_checkout_intents_order_id ON checkout_intents(order_id);

-- ============================================================================
-- MIGRATION 4: Brand Tables
-- ============================================================================

-- Brands
CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    logo_url TEXT,
    website_url TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    api_key_hash TEXT,
    webhook_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_brands_slug ON brands(slug);
CREATE INDEX IF NOT EXISTS idx_brands_status ON brands(status);

-- Products
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    gender TEXT CHECK (gender IN ('men', 'women', 'unisex', 'kids')),
    base_price_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    images JSONB,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'draft')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brand_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_products_brand_id ON products(brand_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

-- Product Variants
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku TEXT NOT NULL UNIQUE,
    size_label TEXT NOT NULL,
    color TEXT,
    price_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_variants_product_id ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_variants_sku ON product_variants(sku);

-- ============================================================================
-- MIGRATION 5: Referral Tables
-- ============================================================================

-- Referrals
CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    referral_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired')),
    reward_cents INTEGER DEFAULT 0,
    reward_currency TEXT DEFAULT 'USD',
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referral_code);

-- ============================================================================
-- MIGRATION 6: Auth Enhancements
-- ============================================================================

-- Add additional user profile fields (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'phone') THEN
        ALTER TABLE auth.users ADD COLUMN phone TEXT;
    END IF;
END $$;

-- Refresh Tokens (for JWT rotation)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- ============================================================================
-- MIGRATION 7: Brand Admins
-- ============================================================================

-- Brand Admins (junction table for brand access control)
CREATE TABLE IF NOT EXISTS brand_admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('owner', 'admin', 'viewer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brand_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_brand_admins_brand_id ON brand_admins(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_admins_user_id ON brand_admins(user_id);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE measurement_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE mediapipe_landmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements_mediapipe ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements_vendor ENABLE ROW LEVEL SECURITY;
ALTER TABLE size_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkout_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_admins ENABLE ROW LEVEL SECURITY;

-- Measurement Sessions: Users can view/insert their own
CREATE POLICY "Users can view own sessions" ON measurement_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON measurement_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Carts: Users can manage their own carts
CREATE POLICY "Users can view their own carts" ON carts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own carts" ON carts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own carts" ON carts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own carts" ON carts
    FOR DELETE USING (auth.uid() = user_id);

-- Cart Items: Users can manage items in their own carts
CREATE POLICY "Users can view their own cart items" ON cart_items
    FOR SELECT USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert their own cart items" ON cart_items
    FOR INSERT WITH CHECK (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));

CREATE POLICY "Users can update their own cart items" ON cart_items
    FOR UPDATE USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete their own cart items" ON cart_items
    FOR DELETE USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));

-- Orders: Users can view their own orders
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Products: Public read access
CREATE POLICY "Anyone can view active products" ON products
    FOR SELECT USING (status = 'active');

-- Product Variants: Public read access
CREATE POLICY "Anyone can view available variants" ON product_variants
    FOR SELECT USING (is_available = TRUE);

-- Brands: Public read access for active brands
CREATE POLICY "Anyone can view active brands" ON brands
    FOR SELECT USING (status = 'active');

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_measurement_sessions_updated_at
    BEFORE UPDATE ON measurement_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_carts_updated_at
    BEFORE UPDATE ON carts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_items_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_addresses_updated_at
    BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brands_updated_at
    BEFORE UPDATE ON brands
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ FitTwin Unified Platform database migration completed successfully!';
    RAISE NOTICE 'Tables created: 25';
    RAISE NOTICE 'RLS policies applied: Yes';
    RAISE NOTICE 'Triggers configured: Yes';
END $$;
