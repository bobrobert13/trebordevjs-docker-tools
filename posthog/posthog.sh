#!/bin/bash

# PostHog Management Script
# This script helps you manage PostHog services

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
    echo "PostHog Management Script"
    echo "======================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Initial setup of PostHog"
    echo "  start     - Start all PostHog services"
    echo "  stop      - Stop all PostHog services"
    echo "  restart   - Restart all PostHog services"
    echo "  status    - Show service status"
    echo "  logs      - Show logs for all services"
    echo "  update    - Update PostHog to latest version"
    echo "  backup    - Create backup of PostHog data"
    echo "  shell     - Access PostHog container shell"
    echo "  db-shell  - Access PostgreSQL shell"
    echo "  ch-shell  - Access ClickHouse shell"
    echo "  redis-cli - Access Redis CLI"
    echo "  workers   - Start background workers"
    echo "  plugins   - Start plugin server"
    echo "  help      - Show this help message"
    echo ""
}

start_services() {
    print_info "Starting PostHog services..."
    docker-compose up -d
    print_success "Services started"
}

stop_services() {
    print_info "Stopping PostHog services..."
    docker-compose down
    print_success "Services stopped"
}

restart_services() {
    print_info "Restarting PostHog services..."
    docker-compose restart
    print_success "Services restarted"
}

show_status() {
    print_info "PostHog Service Status:"
    docker-compose ps
}

show_logs() {
    print_info "Showing logs (press Ctrl+C to exit):"
    docker-compose logs -f
}

update_posthog() {
    print_warning "Updating PostHog to latest version..."
    docker-compose pull
    docker-compose up -d
    print_success "PostHog updated"
}

create_backup() {
    BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Creating backup in $BACKUP_DIR..."
    
    # Backup PostgreSQL
    docker-compose exec -T posthog-db pg_dump -U posthog posthog > "$BACKUP_DIR/posthog.sql"
    
    # Backup Redis
    docker-compose exec -T posthog-redis redis-cli --rdb "$BACKUP_DIR/dump.rdb"
    
    # Backup ClickHouse schema (data is usually too large)
    docker-compose exec -T clickhouse clickhouse-client --query "SHOW CREATE DATABASE posthog" > "$BACKUP_DIR/clickhouse_schema.sql" 2>/dev/null || true
    
    # Backup configuration
    cp -r config "$BACKUP_DIR/" 2>/dev/null || true
    cp .env "$BACKUP_DIR/" 2>/dev/null || true
    
    print_success "Backup created in $BACKUP_DIR"
}

start_workers() {
    print_info "Starting PostHog background workers..."
    docker-compose --profile with-workers up -d posthog-worker
    print_success "Workers started"
}

start_plugins() {
    print_info "Starting PostHog plugin server..."
    docker-compose --profile with-plugins up -d posthog-plugins
    print_success "Plugin server started"
}

access_shell() {
    docker-compose exec posthog /bin/bash
}

access_db_shell() {
    docker-compose exec posthog-db psql -U posthog -d posthog
}

access_clickhouse_shell() {
    docker-compose exec clickhouse clickhouse-client --database=posthog
}

access_redis_cli() {
    docker-compose exec posthog-redis redis-cli
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
        update_posthog
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
    ch-shell)
        access_clickhouse_shell
        ;;
    redis-cli)
        access_redis_cli
        ;;
    workers)
        start_workers
        ;;
    plugins)
        start_plugins
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