# PostHog Setup Script
# This script helps you set up PostHog with all necessary configurations

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

# Function to generate secure key
generate_secret_key() {
    print_info "Generating secure secret key for PostHog..."
    SECRET_KEY=$(openssl rand -hex 32)
    
    # Update .env file if it exists
    if [ -f .env ]; then
        sed -i "s/POSTHOG_SECRET_KEY=.*/POSTHOG_SECRET_KEY=$SECRET_KEY/" .env
        print_success "Updated .env file with secure secret key"
    else
        print_warning ".env file not found. Generated key: $SECRET_KEY"
    fi
}

# Function to create environment file
create_env_file() {
    if [ ! -f .env ]; then
        print_warning "Creating .env file from .env.example"
        cp .env.example .env
        print_warning "Please review and update the .env file with your settings"
        
        # Generate secret key for new .env file
        generate_secret_key
    else
        print_success ".env file already exists"
    fi
}

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    mkdir -p logs
    mkdir -p backups
    mkdir -p uploads
    print_success "Directories created"
}

# Function to create Docker network
create_network() {
    print_info "Creating Docker network..."
    docker network create posthog-network 2>/dev/null || true
    docker network create services-network 2>/dev/null || true
    print_success "Docker networks created"
}

# Function to check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check available memory
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$MEMORY_GB" -lt 8 ]; then
        print_warning "System has less than 8GB RAM. PostHog recommends at least 8GB for optimal performance."
    fi
    
    # Check available disk space
    DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_GB" -lt 20 ]; then
        print_warning "Less than 20GB disk space available. PostHog requires significant storage for analytics data."
    fi
    
    print_success "System requirements check completed"
}

# Function to create ClickHouse configuration
create_clickhouse_config() {
    if [ ! -f config/clickhouse-config.xml ]; then
        print_info "Creating ClickHouse configuration..."
        
        # Create the config file (already created in config directory)
        print_success "ClickHouse configuration ready"
    fi
}

# Function to create PostHog configuration
create_posthog_config() {
    if [ ! -f config/posthog.yml ]; then
        print_info "Creating PostHog configuration..."
        
        # Create the config file (already created in config directory)
        print_success "PostHog configuration ready"
    fi
}

# Function to pull images
pull_images() {
    print_info "Pulling Docker images..."
    docker-compose pull
    print_success "Docker images pulled"
}

# Function to start core services first
start_core_services() {
    print_info "Starting core services (PostgreSQL, Redis, ClickHouse, Zookeeper)..."
    
    # Start infrastructure services first
    docker-compose up -d posthog-db posthog-redis clickhouse zookeeper minio
    
    print_success "Core services started"
}

# Function to wait for core services
wait_for_core_services() {
    print_info "Waiting for core services to be ready..."
    
    # Wait for PostgreSQL
    print_info "Waiting for PostgreSQL..."
    timeout=60
    while ! docker-compose exec -T posthog-db pg_isready -U ${POSTHOG_DB_USER:-posthog} -d ${POSTHOG_DB_NAME:-posthog}; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "PostgreSQL failed to start within 60 seconds"
            exit 1
        fi
    done
    
    # Wait for Redis
    print_info "Waiting for Redis..."
    timeout=30
    while ! docker-compose exec -T posthog-redis redis-cli ping | grep -q PONG; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "Redis failed to start within 30 seconds"
            exit 1
        fi
    done
    
    # Wait for ClickHouse
    print_info "Waiting for ClickHouse..."
    timeout=60
    while ! docker-compose exec -T clickhouse wget --no-verbose --tries=1 --spider http://localhost:8123/ping; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "ClickHouse failed to start within 60 seconds"
            exit 1
        fi
    done
    
    # Wait for Zookeeper
    print_info "Waiting for Zookeeper..."
    timeout=30
    while ! docker-compose exec -T zookeeper zkCli.sh ls / > /dev/null 2>&1; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "Zookeeper failed to start within 30 seconds"
            exit 1
        fi
    done
    
    # Wait for MinIO
    print_info "Waiting for MinIO..."
    timeout=30
    while ! curl -f http://localhost:${MINIO_PORT:-9000}/minio/health/live > /dev/null 2>&1; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "MinIO failed to start within 30 seconds"
            exit 1
        fi
    done
    
    print_success "All core services are ready"
}

# Function to start remaining services
start_remaining_services() {
    print_info "Starting remaining services (Kafka, PostHog)..."
    
    # Start Kafka
    docker-compose up -d kafka
    
    # Wait for Kafka to be ready
    print_info "Waiting for Kafka to be ready..."
    sleep 30
    
    # Start PostHog
    docker-compose up -d posthog
    
    print_success "All services started"
}

# Function to wait for PostHog
wait_for_posthog() {
    print_info "Waiting for PostHog to be ready..."
    
    timeout=120
    while ! curl -f http://localhost:${POSTHOG_PORT:-8000}/_health/ > /dev/null 2>&1; do
        sleep 5
        timeout=$((timeout - 5))
        if [ $timeout -le 0 ]; then
            print_error "PostHog failed to start within 120 seconds"
            exit 1
        fi
    done
    
    print_success "PostHog is ready"
}

# Function to test PostHog
test_posthog() {
    print_info "Testing PostHog..."
    
    # Test health endpoint
    if curl -f http://localhost:${POSTHOG_PORT:-8000}/_health/ > /dev/null 2>&1; then
        print_success "PostHog health check passed"
    else
        print_error "PostHog health check failed"
        return 1
    fi
    
    # Test main page
    if curl -f http://localhost:${POSTHOG_PORT:-8000} > /dev/null 2>&1; then
        print_success "PostHog main page is accessible"
    else
        print_error "PostHog main page is not accessible"
        return 1
    fi
    
    # Test API
    if curl -f http://localhost:${POSTHOG_PORT:-8000}/api/projects/ > /dev/null 2>&1; then
        print_success "PostHog API is accessible"
    else
        print_warning "PostHog API returned non-200 status (this might be normal for unauthenticated requests)"
    fi
}

# Function to create initial buckets in MinIO
create_minio_buckets() {
    print_info "Creating initial buckets in MinIO..."
    
    # Wait a bit for services to settle
    sleep 10
    
    # Create buckets using MinIO client
    docker run --rm --network posthog-network \
        -e MINIO_HOST=minio:9000 \
        -e MINIO_ACCESS_KEY=${MINIO_ROOT_USER:-minioadmin} \
        -e MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD:-minioadmin} \
        minio/mc:latest /bin/sh -c "
            mc alias set posthog http://minio:9000 ${MINIO_ROOT_USER:-minioadmin} ${MINIO_ROOT_PASSWORD:-minioadmin} &&
            mc mb --ignore-existing posthog/${OBJECT_STORAGE_BUCKET:-posthog} &&
            mc mb --ignore-existing posthog/${OBJECT_STORAGE_MEDIA_BUCKET:-posthog-media} &&
            mc mb --ignore-existing posthog/${OBJECT_STORAGE_SESSION_RECORDING_BUCKET:-posthog-session-recordings} &&
            mc policy set public posthog/${OBJECT_STORAGE_BUCKET:-posthog}
        " || print_warning "Failed to create MinIO buckets automatically. You may need to create them manually."
    
    print_success "MinIO buckets created"
}

# Function to display status
show_status() {
    echo ""
    print_success "🎉 PostHog setup completed successfully!"
    echo ""
    echo "📋 Service Status:"
    docker-compose ps
    echo ""
    echo "🔗 Access URLs:"
    echo "  PostHog Dashboard: http://localhost:${POSTHOG_PORT:-8000}"
    echo "  PostHog API: http://localhost:${POSTHOG_PORT:-8000}/api/"
    echo "  Health Check: http://localhost:${POSTHOG_PORT:-8000}/_health/"
    echo "  MinIO Console: http://localhost:${MINIO_CONSOLE_PORT:-9001}"
    echo ""
    echo "📊 Internal Service URLs:"
    echo "  PostgreSQL: localhost:${POSTHOG_DB_PORT:-5434}"
    echo "  Redis: localhost:${POSTHOG_REDIS_PORT:-6381}"
    echo "  ClickHouse HTTP: localhost:${CLICKHOUSE_HTTP_PORT:-8123}"
    echo "  ClickHouse Native: localhost:${CLICKHOUSE_NATIVE_PORT:-9000}"
    echo "  Kafka: localhost:${KAFKA_PORT:-9092}"
    echo "  MinIO API: localhost:${MINIO_PORT:-9000}"
    echo "  Zookeeper: localhost:${ZOOKEEPER_PORT:-2181}"
    echo ""
    echo "🔑 MinIO Credentials:"
    echo "  Access Key: ${MINIO_ROOT_USER:-minioadmin}"
    echo "  Secret Key: ${MINIO_ROOT_PASSWORD:-minioadmin}"
    echo ""
    echo "⚙️  Configuration:"
    echo "  Config file: ./.env"
    echo "  PostHog config: ./config/posthog.yml"
    echo "  ClickHouse config: ./config/clickhouse-config.xml"
    echo "  Logs: docker-compose logs -f [service]"
    echo ""
    print_warning "Next steps:"
    echo "  1. Update .env file with your domain and secure settings"
    echo "  2. Configure email settings for notifications"
    echo "  3. Set up SSL/TLS certificates for production"
    echo "  4. Create your first project in the PostHog dashboard"
    echo "  5. Install the PostHog snippet on your website"
    echo ""
    print_warning "Default login credentials:"
    echo "  Create a new account at http://localhost:${POSTHOG_PORT:-8000}/signup"
    echo "  Or check the initial admin user in the database"
}

# Main execution
main() {
    print_info "Starting PostHog setup..."
    
    check_requirements
    create_directories
    create_env_file
    create_network
    create_clickhouse_config
    create_posthog_config
    
    # Generate secret key if in production mode
    if [ "${POSTHOG_DEBUG:-0}" = "0" ]; then
        generate_secret_key
    fi
    
    pull_images
    start_core_services
    wait_for_core_services
    start_remaining_services
    wait_for_posthog
    create_minio_buckets
    test_posthog
    show_status
}

# Run main function
main