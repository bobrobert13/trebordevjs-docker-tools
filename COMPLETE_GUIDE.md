# 🚀 Complete Docker Services Infrastructure

This repository contains a comprehensive Docker-based infrastructure with NATS, Redis, MongoDB (with replica set), and Dokploy - a complete deployment platform.

## 📁 Directory Structure

```
docker/services-compose/
├── nats/                          # Message broker service
│   ├── docker-compose.yml
│   └── config/
│       └── nats-server.conf
├── redis/                         # In-memory data store
│   ├── docker-compose.yml
│   └── config/
│       └── redis.conf
├── mongodb/                       # NoSQL database with replica set
│   ├── docker-compose.yml
│   ├── init-replica.sh
│   └── scripts/
│       ├── init-replica-set.js
│       └── setup-user.js
├── dokploy/                       # Deployment platform
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── setup.sh
│   ├── dokploy.sh
│   ├── README.md
│   ├── config/
│   │   ├── traefik.yml
│   │   ├── dokploy.json
│   │   └── redis.conf
│   └── scripts/
│       └── init-db.sql
├── docker-compose.yml            # Main compose file
├── docker-compose.full.yml       # Full infrastructure compose
├── manage.sh                     # Master management script
└── README.md
```

## 🎯 Quick Start

### 1. Setup Everything at Once
```bash
# Make the management script executable
chmod +x manage.sh

# Setup all services
./manage.sh setup-all

# Or start everything if already setup
./manage.sh start-all
```

### 2. Access Your Services
- **Dokploy Dashboard**: http://localhost:3000
- **Traefik Dashboard**: http://localhost:8080
- **NATS**: localhost:4222 (client), localhost:8222 (monitoring)
- **Redis**: localhost:6379
- **MongoDB Primary**: localhost:27017
- **MongoDB Secondary**: localhost:27018
- **MongoDB Arbiter**: localhost:27019

### 3. Manage Individual Services
```bash
# Check status of all services
./manage.sh status-all

# View logs for specific service
./manage.sh logs mongodb

# Stop specific service
./manage.sh stop redis

# Restart specific service
./manage.sh restart dokploy
```

## 🔧 Dokploy Configuration

### Environment Setup
1. Copy the example environment file:
   ```bash
   cd dokploy
   cp .env.example .env
   ```

2. Edit `.env` with your settings:
   ```bash
   # Required changes
   DOKPLOY_HOST=your-domain.com
   JWT_SECRET=your-super-secret-jwt-key
   ENCRYPTION_KEY=your-32-character-encryption-key
   TRAEFIK_ACME_EMAIL=admin@your-domain.com
   ```

3. Run setup:
   ```bash
   ./setup.sh
   ```

### Features Included
- **Automatic SSL/TLS** via Let's Encrypt
- **Docker Management** with secure socket access
- **Application Deployment** from Git repositories
- **Monitoring & Logs** with real-time updates
- **Database Management** with PostgreSQL and Redis
- **Backup & Restore** functionality
- **User Management** with JWT authentication

## 📊 Service Details

### NATS (Message Broker)
- **Ports**: 4222 (client), 8222 (monitoring), 6222 (cluster)
- **Features**: High-performance messaging, clustering support
- **Configuration**: `nats/config/nats-server.conf`

### Redis (In-Memory Store)
- **Port**: 6379
- **Features**: Persistence, memory management, security hardening
- **Configuration**: `redis/config/redis.conf`

### MongoDB (Replica Set)
- **Ports**: 27017 (primary), 27018 (secondary), 27019 (arbiter)
- **Features**: Full replica set for transactions and high availability
- **Credentials**: admin/adminpass, appuser/apppass
- **Initialization**: Automatic replica set setup

### Dokploy (Deployment Platform)
- **Port**: 3000 (dashboard), 8080 (Traefik dashboard)
- **Features**: Complete CI/CD platform with Docker management
- **SSL**: Automatic Let's Encrypt certificates
- **Database**: PostgreSQL with Redis for caching

## 🛠️ Management Commands

### Master Script (`manage.sh`)
```bash
./manage.sh setup-all     # Setup everything
./manage.sh start-all     # Start all services
./manage.sh stop-all      # Stop all services
./manage.sh restart-all   # Restart all services
./manage.sh status-all    # Check all statuses
./manage.sh logs-all      # View all logs
```

### Dokploy Management (`dokploy/dokploy.sh`)
```bash
cd dokploy
./dokploy.sh start        # Start Dokploy services
./dokploy.sh stop         # Stop Dokploy services
./dokploy.sh backup       # Create backup
./dokploy.sh update       # Update Dokploy
./dokploy.sh shell        # Access container
```

## 🔒 Security Considerations

### Default Credentials (Change These!)
- **MongoDB**: admin/adminpass
- **PostgreSQL**: postgres/dokploy123
- **Dokploy**: Generated automatically

### SSL/TLS Setup
1. Set your domain in `.env` file
2. Configure email for Let's Encrypt
3. Enable SSL in configuration
4. DNS must point to your server

### Firewall Rules
```bash
# Essential ports
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 3000/tcp    # Dokploy
sudo ufw allow 8080/tcp    # Traefik
```

## 💾 Backup & Restore

### Automated Backup
```bash
cd dokploy
./dokploy.sh backup
```

### Manual Backup
```bash
# Backup PostgreSQL
docker-compose exec -T dokploy-db pg_dump -U postgres dokploy > backup.sql

# Backup Redis
docker-compose exec -T dokploy-redis redis-cli --rdb dump.rdb

# Backup service data
docker run --rm -v dokploy_dokploy-data:/data -v $(pwd):/backup alpine tar czf /backup/dokploy-data.tar.gz -C /data .
```

## 🐛 Troubleshooting

### Common Issues
1. **Port conflicts**: Check if ports are already in use
2. **Docker permissions**: Add user to docker group
3. **Memory issues**: Increase Docker memory limits
4. **Network issues**: Check firewall and DNS settings

### View Logs
```bash
# All services
./manage.sh logs-all

# Specific service
./manage.sh logs dokploy

# Dokploy specific logs
cd dokploy && ./dokploy.sh logs
```

### Reset Services
```bash
# Stop everything
./manage.sh stop-all

# Remove volumes (WARNING: Data loss!)
docker volume prune -f

# Start fresh
./manage.sh setup-all
```

## 📈 Scaling & Production

### Production Considerations
- Use external database services
- Configure proper backups
- Set up monitoring and alerting
- Use dedicated volumes for data
- Configure proper SSL certificates
- Set up log rotation

### Resource Requirements
- **Minimum**: 2 CPU cores, 4GB RAM, 20GB storage
- **Recommended**: 4 CPU cores, 8GB RAM, 50GB+ storage
- **MongoDB**: Additional storage for database growth

## 🤝 Support

For issues and questions:
1. Check service logs: `./manage.sh logs [service]`
2. Verify configuration files
3. Check Docker and system resources
4. Review individual service README files
5. Consult troubleshooting sections

## 🎯 Next Steps

1. **Configure Dokploy**: Set up your domain and SSL
2. **Deploy Applications**: Use Dokploy to deploy your Docker apps
3. **Set up Monitoring**: Configure alerts and monitoring
4. **Backup Strategy**: Implement regular backups
5. **Security Hardening**: Review and update security settings

---

**🚀 You're ready to deploy!** Start with `./manage.sh setup-all` and access your Dokploy dashboard at http://localhost:3000