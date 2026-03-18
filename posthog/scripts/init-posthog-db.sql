-- Initialize PostHog Database
-- This script sets up the initial database schema for PostHog

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schema
CREATE SCHEMA IF NOT EXISTS posthog;

-- Set search path
SET search_path TO posthog, public;

-- Create users table
CREATE TABLE IF NOT EXISTS posthog.user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(254) NOT NULL UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    password VARCHAR(128),
    is_staff BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS posthog.team (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    api_token VARCHAR(200) NOT NULL UNIQUE,
    app_urls TEXT[],
    opt_out_capture BOOLEAN DEFAULT FALSE,
    slack_incoming_webhook VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS posthog.organization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create organization membership table
CREATE TABLE IF NOT EXISTS posthog.organization_membership (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES posthog.organization(id),
    user_id UUID REFERENCES posthog.user(id),
    level INTEGER DEFAULT 1,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- Create events table
CREATE TABLE IF NOT EXISTS posthog.event (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    event VARCHAR(200) NOT NULL,
    distinct_id VARCHAR(200) NOT NULL,
    properties JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create person table
CREATE TABLE IF NOT EXISTS posthog.person (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_identified BOOLEAN DEFAULT FALSE
);

-- Create person distinct ID table
CREATE TABLE IF NOT EXISTS posthog.persondistinctid (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    person_id UUID REFERENCES posthog.person(id),
    distinct_id VARCHAR(400) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, distinct_id)
);

-- Create feature flags table
CREATE TABLE IF NOT EXISTS posthog.featureflag (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    name VARCHAR(200) NOT NULL,
    key VARCHAR(200) NOT NULL,
    filters JSONB DEFAULT '{}',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by_id UUID REFERENCES posthog.user(id)
);

-- Create dashboard table
CREATE TABLE IF NOT EXISTS posthog.dashboard (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by_id UUID REFERENCES posthog.user(id)
);

-- Create insight table
CREATE TABLE IF NOT EXISTS posthog.insight (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES posthog.team(id),
    dashboard_id UUID REFERENCES posthog.dashboard(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    query JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by_id UUID REFERENCES posthog.user(id)
);

-- Create plugin table
CREATE TABLE IF NOT EXISTS posthog.plugin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES posthog.organization(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    url VARCHAR(800),
    config_schema JSONB DEFAULT '[]',
    tag VARCHAR(200),
    archive BYTEA,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create plugin config table
CREATE TABLE IF NOT EXISTS posthog.pluginconfig (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plugin_id UUID REFERENCES posthog.plugin(id),
    team_id UUID REFERENCES posthog.team(id),
    enabled BOOLEAN DEFAULT FALSE,
    order INTEGER DEFAULT 0,
    config JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_email ON posthog.user(email);
CREATE INDEX IF NOT EXISTS idx_user_created_at ON posthog.user(created_at);
CREATE INDEX IF NOT EXISTS idx_team_api_token ON posthog.team(api_token);
CREATE INDEX IF NOT EXISTS idx_team_created_at ON posthog.team(created_at);
CREATE INDEX IF NOT EXISTS idx_organization_membership_user ON posthog.organization_membership(user_id);
CREATE INDEX IF NOT EXISTS idx_organization_membership_org ON posthog.organization_membership(organization_id);
CREATE INDEX IF NOT EXISTS idx_event_team_id ON posthog.event(team_id);
CREATE INDEX IF NOT EXISTS idx_event_timestamp ON posthog.event(timestamp);
CREATE INDEX IF NOT EXISTS idx_event_distinct_id ON posthog.event(distinct_id);
CREATE INDEX IF NOT EXISTS idx_person_team_id ON posthog.person(team_id);
CREATE INDEX IF NOT EXISTS idx_persondistinctid_team_id ON posthog.persondistinctid(team_id);
CREATE INDEX IF NOT EXISTS idx_persondistinctid_person_id ON posthog.persondistinctid(person_id);
CREATE INDEX IF NOT EXISTS idx_persondistinctid_distinct_id ON posthog.persondistinctid(distinct_id);
CREATE INDEX IF NOT EXISTS idx_featureflag_team_id ON posthog.featureflag(team_id);
CREATE INDEX IF NOT EXISTS idx_featureflag_key ON posthog.featureflag(key);
CREATE INDEX IF NOT EXISTS idx_dashboard_team_id ON posthog.dashboard(team_id);
CREATE INDEX IF NOT EXISTS idx_insight_team_id ON posthog.insight(team_id);
CREATE INDEX IF NOT EXISTS idx_insight_dashboard_id ON posthog.insight(dashboard_id);
CREATE INDEX IF NOT EXISTS idx_plugin_org_id ON posthog.plugin(organization_id);
CREATE INDEX IF NOT EXISTS idx_pluginconfig_plugin_id ON posthog.pluginconfig(plugin_id);
CREATE INDEX IF NOT EXISTS idx_pluginconfig_team_id ON posthog.pluginconfig(team_id);

-- Create GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_event_properties ON posthog.event USING GIN(properties);
CREATE INDEX IF NOT EXISTS idx_person_properties ON posthog.person USING GIN(properties);
CREATE INDEX IF NOT EXISTS idx_featureflag_filters ON posthog.featureflag USING GIN(filters);
CREATE INDEX IF NOT EXISTS idx_insight_query ON posthog.insight USING GIN(query);
CREATE INDEX IF NOT EXISTS idx_plugin_config_schema ON posthog.plugin USING GIN(config_schema);
CREATE INDEX IF NOT EXISTS idx_pluginconfig_config ON posthog.pluginconfig USING GIN(config);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_user_updated_at 
    BEFORE UPDATE ON posthog.user 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_updated_at 
    BEFORE UPDATE ON posthog.team 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_updated_at 
    BEFORE UPDATE ON posthog.organization 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_membership_updated_at 
    BEFORE UPDATE ON posthog.organization_membership 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plugin_updated_at 
    BEFORE UPDATE ON posthog.plugin 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pluginconfig_updated_at 
    BEFORE UPDATE ON posthog.pluginconfig 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO posthog.user (email, first_name, last_name, password, is_staff, is_superuser) VALUES
    ('admin@example.com', 'Admin', 'User', 'pbkdf2_sha256$260000$example', true, true)
ON CONFLICT (email) DO NOTHING;

INSERT INTO posthog.organization (name) VALUES
    ('Default Organization')
ON CONFLICT DO NOTHING;

INSERT INTO posthog.team (name, api_token, app_urls) VALUES
    ('Default Team', 'phc_1234567890abcdefghijklmnopqrstuvwxyz', ARRAY['http://localhost:3000'])
ON CONFLICT (api_token) DO NOTHING;

-- Link admin user to organization
INSERT INTO posthog.organization_membership (organization_id, user_id, level) 
SELECT 
    (SELECT id FROM posthog.organization LIMIT 1),
    (SELECT id FROM posthog.user WHERE email = 'admin@example.com' LIMIT 1),
    15
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA posthog TO ${POSTHOG_DB_USER:-posthog};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA posthog TO ${POSTHOG_DB_USER:-posthog};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA posthog TO ${POSTHOG_DB_USER:-posthog};