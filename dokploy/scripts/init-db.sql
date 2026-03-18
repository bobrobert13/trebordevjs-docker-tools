-- Initialize Dokploy Database
-- This script sets up the initial database schema and users

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create application user
CREATE USER dokploy_app WITH PASSWORD 'dokploy123';
ALTER USER dokploy_app CREATEDB;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE dokploy TO dokploy_app;

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS dokploy;
GRANT ALL ON SCHEMA dokploy TO dokploy_app;

-- Set default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA dokploy GRANT ALL ON TABLES TO dokploy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA dokploy GRANT ALL ON SEQUENCES TO dokploy_app;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON dokploy.applications(user_id);
CREATE INDEX IF NOT EXISTS idx_deployments_application_id ON dokploy.deployments(application_id);
CREATE INDEX IF NOT EXISTS idx_logs_deployment_id ON dokploy.logs(deployment_id);

-- Enable row level security
ALTER TABLE dokploy.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE dokploy.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE dokploy.logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY applications_isolation_policy ON dokploy.applications
    USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY deployments_isolation_policy ON dokploy.deployments
    USING (application_id IN (
        SELECT id FROM dokploy.applications 
        WHERE user_id = current_setting('app.current_user_id')::uuid
    ));

CREATE POLICY logs_isolation_policy ON dokploy.logs
    USING (deployment_id IN (
        SELECT id FROM dokploy.deployments 
        WHERE application_id IN (
            SELECT id FROM dokploy.applications 
            WHERE user_id = current_setting('app.current_user_id')::uuid
        )
    ));