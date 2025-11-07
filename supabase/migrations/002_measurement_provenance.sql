-- Ensure Supabase auth schema exists locally (noop in hosted Supabase)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) THEN
        EXECUTE 'CREATE SCHEMA auth';
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'auth' AND table_name = 'users'
    ) THEN
        EXECUTE $DDL$
            CREATE TABLE auth.users (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                email TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        $DDL$;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'auth' AND p.proname = 'uid'
    ) THEN
        EXECUTE $DDL$
            CREATE FUNCTION auth.uid()
            RETURNS UUID
            LANGUAGE SQL
            STABLE
            AS $FUNC$ SELECT NULL::uuid $FUNC$
        $DDL$;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'auth' AND p.proname = 'jwt'
    ) THEN
        EXECUTE $DDL$
            CREATE FUNCTION auth.jwt()
            RETURNS JSONB
            LANGUAGE SQL
            STABLE
            AS $FUNC$ SELECT jsonb_build_object('role', 'anon') $FUNC$
        $DDL$;
    END IF;
END
$$;

-- Migration: Measurement Provenance Schema
-- Description: Create tables for storing measurement provenance, including raw photos,
--              MediaPipe landmarks, calculated measurements, and size recommendations.
-- Date: 2025-10-27
-- Author: Manus AI

CREATE TABLE IF NOT EXISTS measurement_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    session_id TEXT UNIQUE NOT NULL,
    source_type TEXT NOT NULL DEFAULT 'mediapipe_web', -- arkit_lidar, mediapipe_native, mediapipe_web, user_input
    platform TEXT NOT NULL DEFAULT 'web_mobile', -- ios, android, web_mobile, web_desktop
    device_id TEXT,
    browser_info JSONB,
    processing_location TEXT, -- client, server
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending', -- pending, completed, failed
    accuracy_estimate FLOAT,
    needs_calibration BOOLEAN DEFAULT FALSE
);

-- Raw photos table
CREATE TABLE IF NOT EXISTS measurement_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
    photo_type TEXT NOT NULL, -- front, side
    photo_url TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    image_width INT,
    image_height INT
);

-- MediaPipe landmarks table
CREATE TABLE IF NOT EXISTS mediapipe_landmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
    photo_id UUID REFERENCES measurement_photos(id) ON DELETE CASCADE,
    landmark_type TEXT NOT NULL, -- front, side
    landmarks JSONB NOT NULL, -- Array of {x, y, z, visibility}
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    model_version TEXT DEFAULT 'v3.1'
);

-- Calculated measurements table (MediaPipe-derived)
CREATE TABLE IF NOT EXISTS measurements_mediapipe (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
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

-- Vendor measurements table (for calibration only, if needed)
CREATE TABLE IF NOT EXISTS measurements_vendor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
    vendor_name TEXT NOT NULL, -- 3dlook, nettelo, etc.
    vendor_version TEXT,
    measurements JSONB NOT NULL, -- Raw vendor JSON response
    confidence FLOAT,
    cost_usd FLOAT,
    called_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_for_calibration BOOLEAN DEFAULT TRUE,
    excluded_from_live BOOLEAN DEFAULT TRUE -- Never use in production
);

-- Size recommendations table
CREATE TABLE IF NOT EXISTS size_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
    measurement_id UUID REFERENCES measurements_mediapipe(id) ON DELETE CASCADE,
    category TEXT NOT NULL, -- tops, bottoms, dresses, etc.
    size TEXT NOT NULL,
    confidence FLOAT NOT NULL,
    rationale TEXT,
    model_version TEXT DEFAULT 'v1.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE measurement_sessions
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS browser_info JSONB,
    ADD COLUMN IF NOT EXISTS processing_location TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS accuracy_estimate FLOAT,
    ADD COLUMN IF NOT EXISTS needs_calibration BOOLEAN DEFAULT FALSE;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_user ON measurement_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON measurement_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_photos_session ON measurement_photos(session_id);
CREATE INDEX IF NOT EXISTS idx_landmarks_session ON mediapipe_landmarks(session_id);
CREATE INDEX IF NOT EXISTS idx_measurements_session ON measurements_mediapipe(session_id);
CREATE INDEX IF NOT EXISTS idx_vendor_session ON measurements_vendor(session_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_session ON size_recommendations(session_id);

-- Drop existing policies that reference session_id before altering column types
DROP POLICY IF EXISTS "Users can view own photos" ON measurement_photos;
DROP POLICY IF EXISTS "Users can insert own photos" ON measurement_photos;
DROP POLICY IF EXISTS "Users can view own landmarks" ON mediapipe_landmarks;
DROP POLICY IF EXISTS "Users can insert own landmarks" ON mediapipe_landmarks;
DROP POLICY IF EXISTS "Users can view own measurements" ON measurements_mediapipe;
DROP POLICY IF EXISTS "Users can insert own measurements" ON measurements_mediapipe;
DROP POLICY IF EXISTS "Users can view own recommendations" ON size_recommendations;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'measurement_photos'
          AND column_name = 'session_id' AND data_type = 'uuid'
    ) THEN
        EXECUTE 'ALTER TABLE measurement_photos DROP CONSTRAINT IF EXISTS measurement_photos_session_id_fkey';
        EXECUTE 'ALTER TABLE measurement_photos ALTER COLUMN session_id TYPE text USING session_id::text';
        EXECUTE 'ALTER TABLE measurement_photos ADD CONSTRAINT measurement_photos_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'mediapipe_landmarks'
          AND column_name = 'session_id' AND data_type = 'uuid'
    ) THEN
        EXECUTE 'ALTER TABLE mediapipe_landmarks DROP CONSTRAINT IF EXISTS mediapipe_landmarks_session_id_fkey';
        EXECUTE 'ALTER TABLE mediapipe_landmarks ALTER COLUMN session_id TYPE text USING session_id::text';
        EXECUTE 'ALTER TABLE mediapipe_landmarks ADD CONSTRAINT mediapipe_landmarks_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'measurements_mediapipe'
          AND column_name = 'session_id' AND data_type = 'uuid'
    ) THEN
        EXECUTE 'ALTER TABLE measurements_mediapipe DROP CONSTRAINT IF EXISTS measurements_mediapipe_session_id_fkey';
        EXECUTE 'ALTER TABLE measurements_mediapipe ALTER COLUMN session_id TYPE text USING session_id::text';
        EXECUTE 'ALTER TABLE measurements_mediapipe ADD CONSTRAINT measurements_mediapipe_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'measurements_vendor'
          AND column_name = 'session_id' AND data_type = 'uuid'
    ) THEN
        EXECUTE 'ALTER TABLE measurements_vendor DROP CONSTRAINT IF EXISTS measurements_vendor_session_id_fkey';
        EXECUTE 'ALTER TABLE measurements_vendor ALTER COLUMN session_id TYPE text USING session_id::text';
        EXECUTE 'ALTER TABLE measurements_vendor ADD CONSTRAINT measurements_vendor_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'size_recommendations'
          AND column_name = 'session_id' AND data_type = 'uuid'
    ) THEN
        EXECUTE 'ALTER TABLE size_recommendations DROP CONSTRAINT IF EXISTS size_recommendations_session_id_fkey';
        EXECUTE 'ALTER TABLE size_recommendations ALTER COLUMN session_id TYPE text USING session_id::text';
        EXECUTE 'ALTER TABLE size_recommendations ADD CONSTRAINT size_recommendations_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
    END IF;
END
$$;

-- Row Level Security (RLS) policies
ALTER TABLE measurement_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE mediapipe_landmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements_mediapipe ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements_vendor ENABLE ROW LEVEL SECURITY;
ALTER TABLE size_recommendations ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own sessions'
    ) THEN
        CREATE POLICY "Users can view own sessions" ON measurement_sessions
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own sessions'
    ) THEN
        CREATE POLICY "Users can insert own sessions" ON measurement_sessions
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own photos'
    ) THEN
        CREATE POLICY "Users can view own photos" ON measurement_photos
            FOR SELECT USING (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own photos'
    ) THEN
        CREATE POLICY "Users can insert own photos" ON measurement_photos
            FOR INSERT WITH CHECK (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own landmarks'
    ) THEN
        CREATE POLICY "Users can view own landmarks" ON mediapipe_landmarks
            FOR SELECT USING (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own landmarks'
    ) THEN
        CREATE POLICY "Users can insert own landmarks" ON mediapipe_landmarks
            FOR INSERT WITH CHECK (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own measurements'
    ) THEN
        CREATE POLICY "Users can view own measurements" ON measurements_mediapipe
            FOR SELECT USING (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own measurements'
    ) THEN
        CREATE POLICY "Users can insert own measurements" ON measurements_mediapipe
            FOR INSERT WITH CHECK (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own recommendations'
    ) THEN
        CREATE POLICY "Users can view own recommendations" ON size_recommendations
            FOR SELECT USING (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own recommendations'
    ) THEN
        CREATE POLICY "Users can insert own recommendations" ON size_recommendations
            FOR INSERT WITH CHECK (
                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
            );
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access vendor'
    ) THEN
        CREATE POLICY "Service role full access vendor" ON measurements_vendor
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access sessions'
    ) THEN
        CREATE POLICY "Service role full access sessions" ON measurement_sessions
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access photos'
    ) THEN
        CREATE POLICY "Service role full access photos" ON measurement_photos
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access landmarks'
    ) THEN
        CREATE POLICY "Service role full access landmarks" ON mediapipe_landmarks
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access measurements'
    ) THEN
        CREATE POLICY "Service role full access measurements" ON measurements_mediapipe
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access recommendations'
    ) THEN
        CREATE POLICY "Service role full access recommendations" ON size_recommendations
            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
    END IF;
END
$$;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_measurement_sessions_updated_at ON measurement_sessions;

CREATE TRIGGER update_measurement_sessions_updated_at
    BEFORE UPDATE ON measurement_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE measurement_sessions IS 'Tracks measurement sessions with accuracy estimates and calibration flags';
COMMENT ON TABLE measurement_photos IS 'Stores raw photos for provenance and future model training';
COMMENT ON TABLE mediapipe_landmarks IS 'Stores MediaPipe Pose landmarks for measurement calculation';
COMMENT ON TABLE measurements_mediapipe IS 'Stores calculated measurements from MediaPipe landmarks';
COMMENT ON TABLE measurements_vendor IS 'Stores vendor API measurements for calibration only (excluded from live)';
COMMENT ON TABLE size_recommendations IS 'Stores size recommendations generated from measurements';
