#!/bin/bash

# Dokploy Setup Script
# This script helps you set up Dokploy with all necessary configurations

set -e

echo "🚀 Dokploy Setup Script"
echo "======================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Create environment file
create_env_file() {
    if [ ! -f .env ]; then
        print_warning "Creating .env file from .env.example"
        cp .env.example .env
        print_warning "Please edit .env file with your custom values"
        print_warning "Especially change the JWT_SECRET and ENCRYPTION_KEY!"
    else
        print_success ".env file already exists"
    fi
}

# Create necessary directories
create_directories() {
    print_warning "Creating necessary directories..."
    mkdir -p traefik/dynamic
    mkdir -p backups
    mkdir -p logs
    mkdir -p apps
    print_success "Directories created"
}

# Generate secure keys
generate_keys() {
    if grep -q "your-super-secret-jwt-key" .env; then
        print_warning "Generating secure JWT secret..."
        JWT_SECRET=$(openssl rand -base64 32)
        sed -i "s/your-super-secret-jwt-key/$JWT_SECRET/g" .env
    fi
    
    if grep -q "your-32-character-encryption-key" .env; then
        print_warning "Generating secure encryption key..."
        ENCRYPTION_KEY=$(openssl rand -base64 24)
        sed -i "s/your-32-character-encryption-key/$ENCRYPTION_KEY/g" .env
    fi
    
    print_success "Secure keys generated"
}

# Create Docker network
create_network() {
    print_warning "Creating Docker network..."
    docker network create dokploy-network 2>/dev/null || true
    print_success "Docker network created"
}

# Pull images
pull_images() {
    print_warning "Pulling Docker images..."
    docker-compose pull
    print_success "Docker images pulled"
}

# Start services
start_services() {
    print_warning "Starting Dokploy services..."
    docker-compose up -d
    print_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    print_warning "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_warning "Waiting for PostgreSQL..."
    timeout=60
    while ! docker-compose exec -T dokploy-db pg_isready -U postgres -d dokploy; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "PostgreSQL failed to start within 60 seconds"
            exit 1
        fi
    done
    
    # Wait for Redis
    print_warning "Waiting for Redis..."
    timeout=30
    while ! docker-compose exec -T dokploy-redis redis-cli ping | grep -q PONG; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "Redis failed to start within 30 seconds"
            exit 1
        fi
    done
    
    print_success "All services are ready"
}

# Display status
show_status() {
    echo ""
    print_success "🎉 Dokploy setup completed successfully!"
    echo ""
    echo "📋 Service Status:"
    docker-compose ps
    echo ""
    echo "🔗 Access URLs:"
    echo "  Dokploy Dashboard: http://localhost:3000"
    echo "  Traefik Dashboard: http://localhost:8080"
    echo ""
    echo "📊 Service URLs:"
    echo "  PostgreSQL: localhost:5432"
    echo "  Redis: localhost:6379"
    echo ""
    echo "⚙️  Configuration:"
    echo "  Config files: ./config/"
    echo "  Logs: ./logs/"
    echo "  Backups: ./backups/"
    echo ""
    print_warning "Don't forget to:"
    echo "  1. Update your domain in .env file (DOKPLOY_HOST)"
    echo "  2. Configure SSL email (TRAEFIK_ACME_EMAIL)"
    echo "  3. Set up admin credentials"
    echo "  4. Configure backup settings"
}

# Main execution
main() {
    check_docker
    create_env_file
    create_directories
    generate_keys
    create_network
    pull_images
    start_services
    wait_for_services
    show_status
}

# Run main function
main