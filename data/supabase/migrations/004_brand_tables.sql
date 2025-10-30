-- Migration: 004_brand_tables.sql
-- Description: Create tables for brands, products, variants, and size charts
-- Author: Laura Tornga (@rocketroz)
-- Date: 2025-10-30

-- ============================================================================
-- BRANDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    contact_email TEXT NOT NULL,
    website TEXT,
    onboarded BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_brands_slug ON brands(slug);
CREATE INDEX idx_brands_onboarded ON brands(onboarded);

-- ============================================================================
-- BRAND USERS (for multi-user brand accounts)
-- ============================================================================

CREATE TABLE IF NOT EXISTS brand_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'editor', 'viewer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brand_id, user_id)
);

CREATE INDEX idx_brand_users_brand_id ON brand_users(brand_id);
CREATE INDEX idx_brand_users_user_id ON brand_users(user_id);

-- ============================================================================
-- PRODUCTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('tops', 'bottoms', 'dresses', 'outerwear', 'other')),
    hero_image_url TEXT,
    size_chart_id UUID, -- Foreign key added after size_charts table
    fit_map_id UUID, -- Foreign key added after fit_maps table
    active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(active);

-- ============================================================================
-- PRODUCT VARIANTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL, -- e.g., 'S', 'M', 'L', 'XL'
    attributes JSONB, -- e.g., {"chest": 100, "waist": 82, "length": 70}
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX idx_product_variants_sku ON product_variants(sku);
CREATE INDEX idx_product_variants_stock ON product_variants(stock);

-- ============================================================================
-- SIZE CHARTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS size_charts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('tops', 'bottoms', 'dresses', 'outerwear', 'other')),
    unit TEXT NOT NULL CHECK (unit IN ('cm', 'in')),
    measurements JSONB NOT NULL, -- e.g., {"S": {"chest": 90, "waist": 74}, "M": {...}}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_size_charts_brand_id ON size_charts(brand_id);
CREATE INDEX idx_size_charts_category ON size_charts(category);

-- ============================================================================
-- FIT MAPS (brand-specific fit rules)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fit_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('tops', 'bottoms', 'dresses', 'outerwear', 'other')),
    rules JSONB NOT NULL, -- Fit calculation rules and adjustments
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_fit_maps_brand_id ON fit_maps(brand_id);
CREATE INDEX idx_fit_maps_category ON fit_maps(category);

-- ============================================================================
-- Add foreign key constraints to products
-- ============================================================================

ALTER TABLE products
    ADD CONSTRAINT fk_products_size_chart
    FOREIGN KEY (size_chart_id) REFERENCES size_charts(id) ON DELETE SET NULL;

ALTER TABLE products
    ADD CONSTRAINT fk_products_fit_map
    FOREIGN KEY (fit_map_id) REFERENCES fit_maps(id) ON DELETE SET NULL;

-- ============================================================================
-- CATALOG IMPORT JOBS
-- ============================================================================

CREATE TABLE IF NOT EXISTS catalog_import_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
    file_url TEXT NOT NULL,
    total_rows INTEGER,
    processed_rows INTEGER DEFAULT 0,
    errors JSONB, -- Array of error objects
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_catalog_import_jobs_brand_id ON catalog_import_jobs(brand_id);
CREATE INDEX idx_catalog_import_jobs_status ON catalog_import_jobs(status);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE size_charts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fit_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog_import_jobs ENABLE ROW LEVEL SECURITY;

-- Brands: Users can view all brands, but only brand users can modify
CREATE POLICY "Anyone can view brands"
    ON brands FOR SELECT
    USING (true);

CREATE POLICY "Brand users can update their brands"
    ON brands FOR UPDATE
    USING (id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

-- Brand Users: Users can view their own brand memberships
CREATE POLICY "Users can view their brand memberships"
    ON brand_users FOR SELECT
    USING (user_id = auth.uid());

-- Products: Anyone can view active products, brand users can manage
CREATE POLICY "Anyone can view active products"
    ON products FOR SELECT
    USING (active = true OR brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

CREATE POLICY "Brand users can insert products"
    ON products FOR INSERT
    WITH CHECK (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

CREATE POLICY "Brand users can update products"
    ON products FOR UPDATE
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

CREATE POLICY "Brand users can delete products"
    ON products FOR DELETE
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

-- Product Variants: Anyone can view variants of active products
CREATE POLICY "Anyone can view product variants"
    ON product_variants FOR SELECT
    USING (product_id IN (SELECT id FROM products WHERE active = true)
           OR product_id IN (SELECT id FROM products WHERE brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid())));

CREATE POLICY "Brand users can manage product variants"
    ON product_variants FOR ALL
    USING (product_id IN (SELECT id FROM products WHERE brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid())));

-- Size Charts: Brand users can manage their size charts
CREATE POLICY "Brand users can view their size charts"
    ON size_charts FOR SELECT
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

CREATE POLICY "Brand users can manage size charts"
    ON size_charts FOR ALL
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

-- Fit Maps: Brand users can manage their fit maps
CREATE POLICY "Brand users can view their fit maps"
    ON fit_maps FOR SELECT
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

CREATE POLICY "Brand users can manage fit maps"
    ON fit_maps FOR ALL
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

-- Catalog Import Jobs: Brand users can view their import jobs
CREATE POLICY "Brand users can view their import jobs"
    ON catalog_import_jobs FOR SELECT
    USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Triggers for updated_at
CREATE TRIGGER update_brands_updated_at
    BEFORE UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_size_charts_updated_at
    BEFORE UPDATE ON size_charts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fit_maps_updated_at
    BEFORE UPDATE ON fit_maps
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_catalog_import_jobs_updated_at
    BEFORE UPDATE ON catalog_import_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE brands IS 'Brand partners in the FitTwin platform';
COMMENT ON TABLE brand_users IS 'Users associated with brands (multi-tenant)';
COMMENT ON TABLE products IS 'Products offered by brands';
COMMENT ON TABLE product_variants IS 'Size/color variants of products';
COMMENT ON TABLE size_charts IS 'Brand-specific size charts';
COMMENT ON TABLE fit_maps IS 'Brand-specific fit calculation rules';
COMMENT ON TABLE catalog_import_jobs IS 'Async catalog import job tracking';
