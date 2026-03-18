-- Initialize ClickHouse Database for PostHog
-- This script sets up the initial ClickHouse schema

CREATE DATABASE IF NOT EXISTS posthog;

USE posthog;

-- Events table for analytics
CREATE TABLE IF NOT EXISTS events
(
    uuid UUID,
    event VARCHAR,
    properties String,
    properties_json JSON,
    timestamp DateTime64(6, 'UTC'),
    team_id Int64,
    distinct_id VARCHAR,
    elements_hash VARCHAR,
    created_at DateTime64(6, 'UTC'),
    _timestamp DateTime,
    _offset UInt64,
    _partition UInt64
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (team_id, toDate(timestamp), event, uuid)
TTL toDateTime(timestamp) + INTERVAL 1 YEAR;

-- Person table
CREATE TABLE IF NOT EXISTS person
(
    id UUID,
    created_at DateTime64(6, 'UTC'),
    team_id Int64,
    properties VARCHAR,
    properties_json JSON,
    is_identified Int8,
    _timestamp DateTime,
    _offset UInt64,
    _partition UInt64
)
ENGINE = ReplacingMergeTree(_timestamp)
PARTITION BY toYYYYMM(created_at)
ORDER BY (team_id, id);

-- Person distinct ID table
CREATE TABLE IF NOT EXISTS person_distinct_id
(
    id UUID,
    distinct_id VARCHAR,
    person_id UUID,
    team_id Int64,
    _timestamp DateTime,
    _offset UInt64,
    _partition UInt64
)
ENGINE = ReplacingMergeTree(_timestamp)
PARTITION BY toYYYYMM(_timestamp)
ORDER BY (team_id, distinct_id, person_id);

-- Session recording events table
CREATE TABLE IF NOT EXISTS session_recording_events
(
    uuid UUID,
    timestamp DateTime64(6, 'UTC'),
    team_id Int64,
    distinct_id VARCHAR,
    session_id VARCHAR,
    window_id VARCHAR,
    snapshot_data String,
    created_at DateTime64(6, 'UTC'),
    _timestamp DateTime,
    _offset UInt64,
    _partition UInt64
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (team_id, toDate(timestamp), session_id, timestamp, uuid)
TTL toDateTime(timestamp) + INTERVAL 30 DAY;

-- Plugin log entries table
CREATE TABLE IF NOT EXISTS plugin_log_entries
(
    id UUID,
    team_id Int64,
    plugin_id Int64,
    timestamp DateTime64(6, 'UTC'),
    source VARCHAR,
    type VARCHAR,
    message VARCHAR,
    instance_id UUID
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (team_id, plugin_id, timestamp);

-- Create materialized views for optimization
CREATE MATERIALIZED VIEW IF NOT EXISTS events_with_array_props_view
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (team_id, toDate(timestamp), event, uuid)
AS SELECT
    uuid,
    event,
    properties,
    properties_json,
    timestamp,
    team_id,
    distinct_id,
    elements_hash,
    created_at,
    _timestamp,
    _offset,
    _partition
FROM events;

-- Create indexes for better performance
ALTER TABLE events ADD INDEX IF NOT EXISTS idx_event_name (event) TYPE set(0) GRANULARITY 1;
ALTER TABLE events ADD INDEX IF NOT EXISTS idx_team_id (team_id) TYPE minmax GRANULARITY 1;
ALTER TABLE events ADD INDEX IF NOT EXISTS idx_timestamp (timestamp) TYPE minmax GRANULARITY 1;
ALTER TABLE events ADD INDEX IF NOT EXISTS idx_distinct_id (distinct_id) TYPE bloom_filter(0.01) GRANULARITY 1;

ALTER TABLE person ADD INDEX IF NOT EXISTS idx_person_team_id (team_id) TYPE minmax GRANULARITY 1;
ALTER TABLE person ADD INDEX IF NOT EXISTS idx_person_created_at (created_at) TYPE minmax GRANULARITY 1;

ALTER TABLE person_distinct_id ADD INDEX IF NOT EXISTS idx_pdi_team_id (team_id) TYPE minmax GRANULARITY 1;
ALTER TABLE person_distinct_id ADD INDEX IF NOT EXISTS idx_pdi_distinct_id (distinct_id) TYPE bloom_filter(0.01) GRANULARITY 1;

ALTER TABLE session_recording_events ADD INDEX IF NOT EXISTS idx_sr_team_id (team_id) TYPE minmax GRANULARITY 1;
ALTER TABLE session_recording_events ADD INDEX IF NOT EXISTS idx_sr_session_id (session_id) TYPE bloom_filter(0.01) GRANULARITY 1;
ALTER TABLE session_recording_events ADD INDEX IF NOT EXISTS idx_sr_timestamp (timestamp) TYPE minmax GRANULARITY 1;

-- Create dictionaries for faster lookups
CREATE DICTIONARY IF NOT EXISTS person_dict
(
    id UUID,
    team_id Int64,
    properties_json JSON
)
PRIMARY KEY id
SOURCE(CLICKHOUSE(HOST 'localhost' PORT 9000 USER 'default' TABLE 'person' DB 'posthog'))
LAYOUT(COMPLEX_KEY_HASHED())
LIFETIME(300);

-- Create views for common queries
CREATE VIEW IF NOT EXISTS events_view
AS SELECT
    uuid,
    event,
    properties_json,
    timestamp,
    team_id,
    distinct_id,
    created_at
FROM events
WHERE timestamp >= now() - INTERVAL 30 DAY;

-- Create distributed tables for clustering (if needed)
-- Note: These would be used in a clustered setup
/*
CREATE TABLE IF NOT EXISTS events_distributed AS events
ENGINE = Distributed(posthog, posthog, events, rand());

CREATE TABLE IF NOT EXISTS person_distributed AS person
ENGINE = Distributed(posthog, posthog, person, rand());

CREATE TABLE IF NOT EXISTS person_distinct_id_distributed AS person_distinct_id
ENGINE = Distributed(posthog, posthog, person_distinct_id, rand());
*/