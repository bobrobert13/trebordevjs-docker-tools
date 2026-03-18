# Docker Services Configuration

This directory contains Docker configurations for NATS, Redis, and MongoDB with replica set.

## Services Overview

- **NATS**: Message broker on ports 4222 (client), 8222 (monitoring), 6222 (cluster)
- **Redis**: In-memory data store on port 6379
- **MongoDB**: Replica set with 3 nodes on ports 27017, 27018, 27019

## Quick Start

### Start all services:
```bash
docker-compose up -d
```

### Start individual services:
```bash
cd nats && docker-compose up -d
cd redis && docker-compose up -d
cd mongodb && docker-compose up -d
```

### Stop services:
```bash
docker-compose down
```

## MongoDB Replica Set Setup

After starting MongoDB services, initialize the replica set:

```bash
docker exec -it mongo-primary mongosh -u admin -p adminpass --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo1:27017', priority: 2}, {_id: 1, host: 'mongo2:27017', priority: 1}, {_id: 2, host: 'mongo3:27017', arbiterOnly: true]})"
```

Check replica set status:
```bash
docker exec -it mongo-primary mongosh -u admin -p adminpass --eval "rs.status()"
```

## Default Credentials

- **MongoDB Admin**: admin/adminpass
- **MongoDB App User**: appuser/apppass (created after replica set initialization)

## Configuration Files

Each service has its own configuration directory:
- `nats/config/nats-server.conf` - NATS server configuration
- `redis/config/redis.conf` - Redis server configuration
- `mongodb/scripts/` - MongoDB initialization scripts

## Data Persistence

All services use Docker volumes for data persistence:
- `nats-data` - NATS data
- `redis-data` - Redis data
- `mongo1-data`, `mongo2-data`, `mongo3-data` - MongoDB replica set data