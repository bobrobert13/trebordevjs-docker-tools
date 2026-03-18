# Dokploy - Docker Deployment Platform

Dokploy is a self-hosted platform for deploying and managing Docker applications with built-in CI/CD, monitoring, and SSL/TLS support.

## 🚀 Quick Start

1. **Clone and setup:**
   ```bash
   cd dokploy
   ./setup.sh
   ```

2. **Access Dokploy:**
   - Dashboard: http://localhost:3000
   - Traefik Dashboard: http://localhost:8080

3. **Manage services:**
   ```bash
   ./dokploy.sh start    # Start all services
   ./dokploy.sh stop     # Stop all services
   ./dokploy.sh status   # Show service status
   ./dokploy.sh logs     # View logs
   ```

## 📋 Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
# Core settings
DOKPLOY_HOST=your-domain.com
DOKPLOY_PORT=3000
JWT_SECRET=your-super-secret-jwt-key
ENCRYPTION_KEY=your-32-character-encryption-key

# Database
POSTGRES_PASSWORD=secure-password
POSTGRES_PORT=5432

# SSL/TLS
TRAEFIK_ACME_EMAIL=admin@your-domain.com
TRAEFIK_SSL_ENABLED=true
```

### Ports

- **3000**: Dokploy Dashboard
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS with SSL/TLS
- **8080**: Traefik Dashboard
- **5432**: PostgreSQL
- **6379**: Redis

## 🔧 Features

### Application Management
- Deploy Docker containers from Git repositories
- Automatic builds with webhooks
- Environment variable management
- Volume and network configuration
- Resource limits and scaling

### SSL/TLS & Domains
- Automatic SSL certificates via Let's Encrypt
- Custom domain support
- Subdomain routing
- HTTP to HTTPS redirection
- Multiple domains per application

### Monitoring & Logs
- Real-time application logs
- Resource usage monitoring
- Health checks and alerts
- Deployment history
- Error tracking

### CI/CD
- GitHub/GitLab integration
- Automatic deployments
- Build logs and notifications
- Rollback capabilities
- Multi-stage deployments

### Security
- JWT authentication
- Encrypted environment variables
- Secure Docker socket access
- Network isolation
- User management

## 🛠️ Management Commands

```bash
# Service management
./dokploy.sh start     # Start services
./dokploy.sh stop      # Stop services
./dokploy.sh restart   # Restart services
./dokploy.sh status    # Show status

# Maintenance
./dokploy.sh update    # Update Dokploy
./dokploy.sh backup    # Create backup
./dokploy.sh cleanup   # Clean Docker resources

# Access services
./dokploy.sh shell     # Dokploy container shell
./dokploy.sh db-shell  # PostgreSQL shell
./dokploy.sh redis-cli # Redis CLI
```

## 📊 Monitoring

Access monitoring dashboards:
- **Dokploy Dashboard**: http://localhost:3000
- **Traefik Dashboard**: http://localhost:8080

## 🔒 Security

### Change Default Passwords

1. Update `.env` file with secure passwords
2. Change JWT secret and encryption key
3. Set up SSL/TLS with your domain

### SSL/TLS Setup

1. Set your domain in `DOKPLOY_HOST`
2. Configure email in `TRAEFIK_ACME_EMAIL`
3. Enable SSL in `TRAEFIK_SSL_ENABLED=true`

### Firewall Rules

```bash
# Allow specific ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp
```

## 💾 Backup & Restore

### Create Backup
```bash
./dokploy.sh backup
```

### Manual Backup
```bash
# Backup PostgreSQL
docker-compose exec -T dokploy-db pg_dump -U postgres dokploy > backup.sql

# Backup Redis
docker-compose exec -T dokploy-redis redis-cli --rdb dump.rdb

# Backup Dokploy data
docker run --rm -v dokploy_dokploy-data:/data -v $(pwd):/backup alpine tar czf /backup/dokploy-data.tar.gz -C /data .
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 80, 443, 3000, 5432, 6379, 8080 are available
2. **Docker permissions**: Add your user to the docker group
3. **SSL issues**: Check domain DNS and email configuration

### View Logs
```bash
# All services
./dokploy.sh logs

# Specific service
docker-compose logs dokploy
docker-compose logs dokploy-db
docker-compose logs dokploy-redis
```

### Reset Everything
```bash
# Stop and remove everything
docker-compose down -v
# Remove volumes
docker volume prune -f
# Start fresh
./setup.sh
```

## 📚 Advanced Configuration

### Custom Traefik Rules

Edit `config/traefik.yml` to add custom routing rules, middlewares, or certificate resolvers.

### Database Optimization

Modify `scripts/init-db.sql` for custom database configurations, indexes, or user setups.

### Redis Configuration

Edit `config/redis.conf` to adjust Redis settings, memory limits, or persistence options.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This Dokploy configuration is provided as-is for educational and development purposes.

## 🆘 Support

For issues and questions:
1. Check the logs: `./dokploy.sh logs`
2. Review configuration files
3. Check Docker and system resources
4. Consult the troubleshooting section