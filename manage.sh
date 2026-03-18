#!/bin/bash

# Master Management Script for All Services
# Manages NATS, Redis, MongoDB, Dokploy, Inngest, and PostHog

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
    echo "All Services Management Script"
    echo "============================="
    echo ""
    echo "Usage: $0 [COMMAND] [SERVICE]"
    echo ""
    echo "Commands:"
    echo "  setup-all     - Setup all services (NATS, Redis, MongoDB, Dokploy, Inngest, PostHog)"
    echo "  start-all     - Start all services"
    echo "  stop-all      - Stop all services"
    echo "  restart-all   - Restart all services"
    echo "  status-all    - Show status of all services"
    echo "  logs-all      - Show logs of all services"
    echo ""
    echo "Individual Service Commands:"
    echo "  setup [service]     - Setup specific service (nats|redis|mongodb|dokploy|inngest|posthog)"
    echo "  start [service]     - Start specific service"
    echo "  stop [service]      - Stop specific service"
    echo "  restart [service]   - Restart specific service"
    echo "  status [service]    - Show status of specific service"
    echo "  logs [service]      - Show logs of specific service"
    echo ""
    echo "Available Services:"
    echo "  nats, redis, mongodb, dokploy, inngest, posthog, all"
    echo ""
    echo "Examples:"
    echo "  $0 setup-all"
    echo "  $0 start redis"
    echo "  $0 stop mongodb"
    echo "  $0 status dokploy"
    echo ""
}

# Function to setup individual service
setup_service() {
    local service=$1
    case $service in
        nats)
            print_info "Setting up NATS..."
            cd nats && docker-compose up -d && cd ..
            print_success "NATS setup completed"
            ;;
        redis)
            print_info "Setting up Redis..."
            cd redis && docker-compose up -d && cd ..
            print_success "Redis setup completed"
            ;;
        mongodb)
            print_info "Setting up MongoDB replica set..."
            cd mongodb && docker-compose up -d && cd ..
            print_info "Initializing MongoDB replica set..."
            sleep 10
            cd mongodb && ./init-replica.sh && cd ..
            print_success "MongoDB setup completed"
            ;;
        dokploy)
            print_info "Setting up Dokploy..."
            cd dokploy && ./setup.sh && cd ..
            print_success "Dokploy setup completed"
            ;;
        inngest)
            print_info "Setting up Inngest..."
            cd inngest && ./setup.sh && cd ..
            print_success "Inngest setup completed"
            ;;
        posthog)
            print_info "Setting up PostHog..."
            cd posthog && ./setup.sh && cd ..
            print_success "PostHog setup completed"
            ;;
        *)
            print_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Function to start individual service
start_service() {
    local service=$1
    case $service in
        nats)
            cd nats && docker-compose up -d && cd ..
            ;;
        redis)
            cd redis && docker-compose up -d && cd ..
            ;;
        mongodb)
            cd mongodb && docker-compose up -d && cd ..
            ;;
        dokploy)
            cd dokploy && docker-compose up -d && cd ..
            ;;
        inngest)
            cd inngest && docker-compose up -d && cd ..
            ;;
        posthog)
            cd posthog && docker-compose up -d && cd ..
            ;;
        *)
            print_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Function to stop individual service
stop_service() {
    local service=$1
    case $service in
        nats)
            cd nats && docker-compose down && cd ..
            ;;
        redis)
            cd redis && docker-compose down && cd ..
            ;;
        mongodb)
            cd mongodb && docker-compose down && cd ..
            ;;
        dokploy)
            cd dokploy && docker-compose down && cd ..
            ;;
        inngest)
            cd inngest && docker-compose down && cd ..
            ;;
        posthog)
            cd posthog && docker-compose down && cd ..
            ;;
        *)
            print_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Function to show status of individual service
status_service() {
    local service=$1
    case $service in
        nats)
            cd nats && docker-compose ps && cd ..
            ;;
        redis)
            cd redis && docker-compose ps && cd ..
            ;;
        mongodb)
            cd mongodb && docker-compose ps && cd ..
            ;;
        dokploy)
            cd dokploy && docker-compose ps && cd ..
            ;;
        inngest)
            cd inngest && docker-compose ps && cd ..
            ;;
        posthog)
            cd posthog && docker-compose ps && cd ..
            ;;
        *)
            print_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Function to show logs of individual service
logs_service() {
    local service=$1
    case $service in
        nats)
            cd nats && docker-compose logs -f && cd ..
            ;;
        redis)
            cd redis && docker-compose logs -f && cd ..
            ;;
        mongodb)
            cd mongodb && docker-compose logs -f && cd ..
            ;;
        dokploy)
            cd dokploy && docker-compose logs -f && cd ..
            ;;
        inngest)
            cd inngest && docker-compose logs -f && cd ..
            ;;
        posthog)
            cd posthog && docker-compose logs -f && cd ..
            ;;
        *)
            print_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Setup all services
setup_all() {
    print_info "Setting up all services..."
    
    # Create networks
    docker network create services-network 2>/dev/null || true
    docker network create dokploy-network 2>/dev/null || true
    
    # Setup services in order
    setup_service "nats"
    setup_service "redis"
    setup_service "mongodb"
    setup_service "dokploy"
    setup_service "inngest"
    setup_service "posthog"
    
    print_success "All services setup completed!"
    show_access_info
}

# Start all services
start_all() {
    print_info "Starting all services..."
    
    start_service "nats"
    start_service "redis"
    start_service "mongodb"
    start_service "dokploy"
    start_service "inngest"
    start_service "posthog"
    
    print_success "All services started!"
    show_access_info
}

# Stop all services
stop_all() {
    print_info "Stopping all services..."
    
    stop_service "posthog"
    stop_service "inngest"
    stop_service "dokploy"
    stop_service "mongodb"
    stop_service "redis"
    stop_service "nats"
    
    print_success "All services stopped!"
}

# Show status of all services
status_all() {
    print_info "Status of all services:"
    echo ""
    echo "=== NATS ==="
    status_service "nats"
    echo ""
    echo "=== Redis ==="
    status_service "redis"
    echo ""
    echo "=== MongoDB ==="
    status_service "mongodb"
    echo ""
    echo "=== Dokploy ==="
    status_service "dokploy"
    echo ""
    echo "=== Inngest ==="
    status_service "inngest"
    echo ""
    echo "=== PostHog ==="
    status_service "posthog"
}

# Show access information
show_access_info() {
    echo ""
    print_success "🎉 Services are ready!"
    echo ""
    echo "🔗 Access URLs:"
    echo "  NATS Client: localhost:4222"
    echo "  NATS Monitoring: localhost:8222"
    echo "  Redis: localhost:6379"
    echo "  MongoDB Primary: localhost:27017"
    echo "  MongoDB Secondary: localhost:27018"
    echo "  MongoDB Arbiter: localhost:27019"
    echo "  Dokploy Dashboard: http://localhost:3000"
    echo "  Traefik Dashboard: http://localhost:8080"
    echo "  Inngest Dashboard: http://localhost:8288"
    echo "  PostHog Dashboard: http://localhost:8000"
    echo "  PostHog MinIO Console: http://localhost:9001"
    echo ""
    echo "🔑 Default Credentials:"
    echo "  MongoDB Admin: admin/adminpass"
    echo "  MongoDB App: appuser/apppass"
    echo ""
    echo "⚙️  Management Commands:"
    echo "  ./manage.sh status-all  # Check all services"
    echo "  ./manage.sh logs nats   # View NATS logs"
    echo "  ./manage.sh stop redis  # Stop Redis service"
}

# Main script logic
case "${1:-help}" in
    setup-all)
        setup_all
        ;;
    start-all)
        start_all
        ;;
    stop-all)
        stop_all
        ;;
    restart-all)
        stop_all
        sleep 3
        start_all
        ;;
    status-all)
        status_all
        ;;
    logs-all)
        print_info "Showing logs for all services (press Ctrl+C to exit):"
        echo "=== NATS ==="
        cd nats && docker-compose logs --tail=50 && cd ..
        echo ""
        echo "=== Redis ==="
        cd redis && docker-compose logs --tail=50 && cd ..
        echo ""
        echo "=== MongoDB ==="
        cd mongodb && docker-compose logs --tail=50 && cd ..
        echo ""
        echo "=== Dokploy ==="
        cd dokploy && docker-compose logs --tail=50 && cd ..
        ;;
    setup)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        setup_service "$2"
        ;;
    start)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        start_service "$2"
        ;;
    stop)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        stop_service "$2"
        ;;
    restart)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        stop_service "$2"
        sleep 3
        start_service "$2"
        ;;
    status)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        status_service "$2"
        ;;
    logs)
        if [ -z "$2" ]; then
            print_error "Please specify a service: nats, redis, mongodb, dokploy"
            exit 1
        fi
        logs_service "$2"
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