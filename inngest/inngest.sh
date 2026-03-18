#!/bin/bash

# Inngest Management Script
# This script helps you manage Inngest services

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
    echo "Inngest Management Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Initial setup of Inngest"
    echo "  start     - Start all Inngest services"
    echo "  stop      - Stop all Inngest services"
    echo "  restart   - Restart all Inngest services"
    echo "  status    - Show service status"
    echo "  logs      - Show logs for all services"
    echo "  update    - Update Inngest to latest version"
    echo "  backup    - Create backup of Inngest data"
    echo "  shell     - Access Inngest container shell"
    echo "  db-shell  - Access PostgreSQL shell"
    echo "  redis-cli - Access Redis CLI"
    echo "  test      - Send test event to Inngest"
    echo "  help      - Show this help message"
    echo ""
}

start_services() {
    print_info "Starting Inngest services..."
    docker-compose up -d
    print_success "Services started"
}

stop_services() {
    print_info "Stopping Inngest services..."
    docker-compose down
    print_success "Services stopped"
}

restart_services() {
    print_info "Restarting Inngest services..."
    docker-compose restart
    print_success "Services restarted"
}

show_status() {
    print_info "Inngest Service Status:"
    docker-compose ps
}

show_logs() {
    print_info "Showing logs (press Ctrl+C to exit):"
    docker-compose logs -f
}

update_inngest() {
    print_warning "Updating Inngest to latest version..."
    docker-compose pull
    docker-compose up -d
    print_success "Inngest updated"
}

create_backup() {
    BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Creating backup in $BACKUP_DIR..."
    
    # Backup PostgreSQL
    docker-compose exec -T inngest-db pg_dump -U inngest inngest > "$BACKUP_DIR/inngest.sql"
    
    # Backup Redis
    docker-compose exec -T inngest-redis redis-cli --rdb "$BACKUP_DIR/dump.rdb"
    
    # Backup configuration
    cp -r config "$BACKUP_DIR/" 2>/dev/null || true
    cp .env "$BACKUP_DIR/" 2>/dev/null || true
    
    print_success "Backup created in $BACKUP_DIR"
}

access_shell() {
    docker-compose exec inngest /bin/sh
}

access_db_shell() {
    docker-compose exec inngest-db psql -U inngest -d inngest
}

access_redis_cli() {
    docker-compose exec inngest-redis redis-cli
}

send_test_event() {
    print_info "Sending test event to Inngest..."
    
    # Check if worker is running
    if docker-compose ps | grep -q inngest-worker; then
        if curl -X POST http://localhost:3000/test-event; then
            print_success "Test event sent successfully"
        else
            print_error "Failed to send test event"
        fi
    else
        print_warning "Worker is not running. Start it with: docker-compose --profile with-worker up -d"
    fi
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
        update_inngest
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
    test)
        send_test_event
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