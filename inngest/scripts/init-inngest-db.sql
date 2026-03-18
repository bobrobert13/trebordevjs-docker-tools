-- Initialize Inngest Database
-- This script sets up the initial database schema for Inngest

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create database if not exists (handled by docker, but good for manual setup)
-- CREATE DATABASE inngest;

-- Create schema
CREATE SCHEMA IF NOT EXISTS inngest;

-- Create functions table
CREATE TABLE IF NOT EXISTS inngest.functions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create events table
CREATE TABLE IF NOT EXISTS inngest.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    user_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create runs table for function executions
CREATE TABLE IF NOT EXISTS inngest.runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    function_id UUID REFERENCES inngest.functions(id),
    event_id UUID REFERENCES inngest.events(id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    output JSONB,
    error TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_functions_slug ON inngest.functions(slug);
CREATE INDEX IF NOT EXISTS idx_functions_created_at ON inngest.functions(created_at);
CREATE INDEX IF NOT EXISTS idx_events_name ON inngest.events(name);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON inngest.events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON inngest.events(user_id);
CREATE INDEX IF NOT EXISTS idx_runs_function_id ON inngest.runs(function_id);
CREATE INDEX IF NOT EXISTS idx_runs_event_id ON inngest.runs(event_id);
CREATE INDEX IF NOT EXISTS idx_runs_status ON inngest.runs(status);
CREATE INDEX IF NOT EXISTS idx_runs_created_at ON inngest.runs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for functions updated_at
CREATE TRIGGER update_functions_updated_at 
    BEFORE UPDATE ON inngest.functions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable row level security
ALTER TABLE inngest.functions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inngest.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE inngest.runs ENABLE ROW LEVEL SECURITY;

-- Insert sample data for testing
INSERT INTO inngest.functions (name, slug, description, config) VALUES
    ('Hello World', 'hello-world', 'A simple hello world function', '{"runtime": "node"}'),
    ('User Created', 'user-created', 'Triggered when a user is created', '{"event": "user.created"}')
ON CONFLICT (slug) DO NOTHING;

-- Grant permissions (if using separate user)
-- GRANT ALL PRIVILEGES ON SCHEMA inngest TO inngest;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA inngest TO inngest;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA inngest TO inngest;