#!/bin/bash

echo "🚀 Setting up Docker services..."

# Create network if it doesn't exist
echo "Creating Docker network..."
docker network create services-network 2>/dev/null || true

# Start NATS
echo "📝 Starting NATS..."
cd nats && docker-compose up -d && cd ..

# Start Redis
echo "🔄 Starting Redis..."
cd redis && docker-compose up -d && cd ..

# Start MongoDB
echo "🗄️ Starting MongoDB replica set..."
cd mongodb && docker-compose up -d && cd ..

echo "⏳ Waiting for MongoDB to be ready..."
sleep 30

echo "🔧 Initializing MongoDB replica set..."
cd mongodb && ./init-replica.sh && cd ..

echo "✅ All services are up and running!"
echo ""
echo "📋 Service URLs:"
echo "  NATS: localhost:4222 (client), localhost:8222 (monitoring)"
echo "  Redis: localhost:6379"
echo "  MongoDB: localhost:27017 (primary), localhost:27018 (secondary), localhost:27019 (arbiter)"
echo ""
echo "🔑 MongoDB Credentials:"
echo "  Admin: admin/adminpass"
echo "  App User: appuser/apppass"