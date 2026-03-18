#!/bin/bash

# Dokploy Management Script
# This script helps you manage Dokploy services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_help() {
    echo "Dokploy Management Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Initial setup of Dokploy"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  status    - Show service status"
    echo "  logs      - Show logs for all services"
    echo "  update    - Update Dokploy to latest version"
    echo "  backup    - Create backup of Dokploy data"
    echo "  restore   - Restore Dokploy from backup"
    echo "  cleanup   - Clean up unused Docker resources"
    echo "  shell     - Access Dokploy container shell"
    echo "  db-shell  - Access PostgreSQL shell"
    echo "  redis-cli - Access Redis CLI"
    echo "  help      - Show this help message"
    echo ""
}

start_services() {
    print_info "Starting Dokploy services..."
    docker-compose up -d
    print_success "Services started"
}

stop_services() {
    print_info "Stopping Dokploy services..."
    docker-compose down
    print_success "Services stopped"
}

restart_services() {
    print_info "Restarting Dokploy services..."
    docker-compose restart
    print_success "Services restarted"
}

show_status() {
    print_info "Service Status:"
    docker-compose ps
}

show_logs() {
    print_info "Showing logs (press Ctrl+C to exit):"
    docker-compose logs -f
}

update_dokploy() {
    print_warning "Updating Dokploy to latest version..."
    docker-compose pull
    docker-compose up -d
    print_success "Dokploy updated"
}

create_backup() {
    BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Creating backup in $BACKUP_DIR..."
    
    # Backup PostgreSQL
    docker-compose exec -T dokploy-db pg_dump -U postgres dokploy > "$BACKUP_DIR/dokploy.sql"
    
    # Backup Redis
    docker-compose exec -T dokploy-redis redis-cli --rdb "$BACKUP_DIR/dump.rdb"
    
    # Backup Dokploy data
    docker run --rm -v dokploy_dokploy-data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/dokploy-data.tar.gz -C /data .
    
    print_success "Backup created in $BACKUP_DIR"
}

access_shell() {
    docker-compose exec dokploy /bin/sh
}

access_db_shell() {
    docker-compose exec dokploy-db psql -U postgres -d dokploy
}

access_redis_cli() {
    docker-compose exec dokploy-redis redis-cli
}

cleanup_docker() {
    print_warning "Cleaning up unused Docker resources..."
    docker system prune -f
    docker volume prune -f
    print_success "Docker cleanup completed"
}

# Main script logic
case "${1:-help}" in
    setup)
        ./setup.sh
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_dokploy
        ;;
    backup)
        create_backup
        ;;
    shell)
        access_shell
        ;;
    db-shell)
        access_db_shell
        ;;
    redis-cli)
        access_redis_cli
        ;;
    cleanup)
        cleanup_docker
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac