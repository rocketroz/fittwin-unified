-- FitTwin Supabase Database Schema
-- This schema defines the tables needed for the FitTwin iOS app backend

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Measurements table
-- Stores body measurements captured by the iOS app
CREATE TABLE IF NOT EXISTS measurements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- User height (reference measurement)
    height_cm DOUBLE PRECISION NOT NULL,
    
    -- Primary measurements (circumferences in cm)
    shoulder_width DOUBLE PRECISION NOT NULL,
    chest_circumference DOUBLE PRECISION NOT NULL,
    waist_circumference DOUBLE PRECISION NOT NULL,
    hip_circumference DOUBLE PRECISION NOT NULL,
    neck_circumference DOUBLE PRECISION,
    bicep_circumference DOUBLE PRECISION,
    forearm_circumference DOUBLE PRECISION,
    wrist_circumference DOUBLE PRECISION,
    thigh_circumference DOUBLE PRECISION,
    calf_circumference DOUBLE PRECISION,
    ankle_circumference DOUBLE PRECISION,
    
    -- Length measurements (in cm)
    inseam DOUBLE PRECISION NOT NULL,
    arm_length DOUBLE PRECISION NOT NULL,
    torso_length DOUBLE PRECISION,
    leg_length DOUBLE PRECISION,
    arm_span DOUBLE PRECISION,
    
    -- Width measurements (in cm)
    chest_width DOUBLE PRECISION,
    waist_width DOUBLE PRECISION,
    hip_width DOUBLE PRECISION,
    
    -- Depth measurements (in cm)
    chest_depth DOUBLE PRECISION,
    waist_depth DOUBLE PRECISION,
    hip_depth DOUBLE PRECISION,
    
    -- Metadata
    confidence_score DOUBLE PRECISION,
    device_model TEXT,
    device_os TEXT,
    app_version TEXT,
    
    -- Indexes
    CONSTRAINT measurements_user_id_idx FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_measurements_user_id ON measurements(user_id);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_measurements_created_at ON measurements(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only read their own measurements
CREATE POLICY "Users can view own measurements"
    ON measurements
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own measurements
CREATE POLICY "Users can insert own measurements"
    ON measurements
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own measurements
CREATE POLICY "Users can update own measurements"
    ON measurements
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own measurements
CREATE POLICY "Users can delete own measurements"
    ON measurements
    FOR DELETE
    USING (auth.uid() = user_id);

-- Storage bucket for measurement images (optional)
-- This allows users to upload front/side photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('measurement-images', 'measurement-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policies
-- Users can upload their own images
CREATE POLICY "Users can upload own images"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'measurement-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can view their own images
CREATE POLICY "Users can view own images"
    ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'measurement-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own images
CREATE POLICY "Users can delete own images"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'measurement-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_measurements_updated_at
    BEFORE UPDATE ON measurements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Optional: View for latest measurements per user
CREATE OR REPLACE VIEW latest_measurements AS
SELECT DISTINCT ON (user_id)
    *
FROM measurements
ORDER BY user_id, created_at DESC;

-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON measurements TO authenticated;
GRANT SELECT ON latest_measurements TO authenticated;
