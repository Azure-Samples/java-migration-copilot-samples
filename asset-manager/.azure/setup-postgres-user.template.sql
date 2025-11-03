-- PostgreSQL User Setup Template
-- This file is created when running the provisioning script, provision.ps1
-- 
-- Placeholders to replace:
-- - {{MANAGED_IDENTITY_NAME}} - Replace with actual managed identity name (e.g., "idib6mj")
-- - {{DATABASE_NAME}} - Replace with actual database name (e.g., "assetsdb")
--
-- This script creates a PostgreSQL user for the managed identity and grants necessary permissions

-- Create user for the managed identity
CREATE USER "{{MANAGED_IDENTITY_NAME}}" WITH LOGIN;

-- Grant database-level privileges
GRANT ALL PRIVILEGES ON DATABASE {{DATABASE_NAME}} TO "{{MANAGED_IDENTITY_NAME}}";

-- Grant schema-level privileges
GRANT ALL PRIVILEGES ON SCHEMA public TO "{{MANAGED_IDENTITY_NAME}}";

-- Grant privileges on existing tables and sequences
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "{{MANAGED_IDENTITY_NAME}}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "{{MANAGED_IDENTITY_NAME}}";

-- Grant default privileges for future tables and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "{{MANAGED_IDENTITY_NAME}}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "{{MANAGED_IDENTITY_NAME}}";