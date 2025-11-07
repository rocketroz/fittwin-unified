-- Ensure uuid-ossp extension exists before tables or functions reference uuid_generate_v4().
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
