#!/bin/bash

# Script to initialize MongoDB replica set
echo "Initializing MongoDB replica set..."

docker exec -it mongo-primary mongosh -u admin -p adminpass --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: 'mongo1:27017', priority: 2 },
    { _id: 1, host: 'mongo2:27017', priority: 1 },
    { _id: 2, host: 'mongo3:27017', arbiterOnly: true }
  ]
});
"

echo "Waiting for replica set to initialize..."
sleep 10

echo "Creating application user..."
docker exec -it mongo-primary mongosh -u admin -p adminpass --eval "
db = db.getSiblingDB('admin');
db.createUser({
  user: 'appuser',
  pwd: 'apppass',
  roles: [
    { role: 'readWrite', db: 'myapp' },
    { role: 'readWrite', db: 'test' }
  ]
});
"

echo "Replica set status:"
docker exec -it mongo-primary mongosh -u admin -p adminpass --eval "rs.status()"