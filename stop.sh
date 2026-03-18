#!/bin/bash

echo "🛑 Stopping all services..."

# Stop NATS
echo "Stopping NATS..."
cd nats && docker-compose down && cd ..

# Stop Redis
echo "Stopping Redis..."
cd redis && docker-compose down && cd ..

# Stop MongoDB
echo "Stopping MongoDB..."
cd mongodb && docker-compose down && cd ..

echo "✅ All services stopped!"