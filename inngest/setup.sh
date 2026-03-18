#!/bin/bash

# Inngest Setup Script
# This script helps you set up Inngest with all necessary configurations

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

# Function to generate secure keys
generate_keys() {
    print_info "Generating secure keys for Inngest..."
    
    # Generate event key (64 hex characters)
    EVENT_KEY=$(openssl rand -hex 32)
    
    # Generate signing key (64 hex characters)
    SIGNING_KEY=$(openssl rand -hex 32)
    
    # Generate master key (64 hex characters)
    MASTER_KEY=$(openssl rand -hex 32)
    
    # Update .env file if it exists
    if [ -f .env ]; then
        sed -i "s/INNGEST_EVENT_KEY=.*/INNGEST_EVENT_KEY=$EVENT_KEY/" .env
        sed -i "s/INNGEST_SIGNING_KEY=.*/INNGEST_SIGNING_KEY=$SIGNING_KEY/" .env
        sed -i "s/INNGEST_MASTER_KEY=.*/INNGEST_MASTER_KEY=$MASTER_KEY/" .env
        print_success "Updated .env file with secure keys"
    else
        print_warning ".env file not found. Keys generated but not saved:"
        echo "EVENT_KEY: $EVENT_KEY"
        echo "SIGNING_KEY: $SIGNING_KEY"
        echo "MASTER_KEY: $MASTER_KEY"
    fi
}

# Function to create environment file
create_env_file() {
    if [ ! -f .env ]; then
        print_warning "Creating .env file from .env.example"
        cp .env.example .env
        print_warning "Please review and update the .env file with your settings"
        
        # Generate keys for new .env file
        generate_keys
    else
        print_success ".env file already exists"
    fi
}

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    mkdir -p worker
    mkdir -p logs
    mkdir -p backups
    print_success "Directories created"
}

# Function to create Docker network
create_network() {
    print_info "Creating Docker network..."
    docker network create inngest-network 2>/dev/null || true
    docker network create services-network 2>/dev/null || true
    print_success "Docker networks created"
}

# Function to create example worker
create_example_worker() {
    if [ ! -f worker/package.json ]; then
        print_info "Creating example worker application..."
        
        # Create package.json
        cat > worker/package.json << EOF
{
  "name": "inngest-worker",
  "version": "1.0.0",
  "description": "Example Inngest worker",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "inngest": "^3.0.0",
    "express": "^4.18.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF
        
        # Create example worker
        cat > worker/index.js << 'EOF'
const { Inngest } = require("inngest");
const express = require("express");

// Initialize Inngest client
const inngest = new Inngest({
  name: "My App",
  eventKey: process.env.INNGEST_EVENT_KEY,
  signingKey: process.env.INNGEST_SIGNING_KEY,
  baseUrl: process.env.INNGEST_BASE_URL || "http://inngest:8288",
});

// Create Express app
const app = express();
app.use(express.json());

// Inngest function handlers
const helloWorld = inngest.createFunction(
  { name: "Hello World" },
  { event: "test/hello" },
  async ({ event, step }) => {
    console.log("Hello World function triggered!", event);
    
    await step.sleep("wait-a-second", "1s");
    
    return { message: "Hello from Inngest!", timestamp: new Date().toISOString() };
  }
);

const userCreated = inngest.createFunction(
  { name: "User Created Handler" },
  { event: "user/created" },
  async ({ event, step }) => {
    console.log("User created:", event.data);
    
    // Simulate processing
    await step.sleep("process-user", "2s");
    
    // Send welcome email (simulated)
    await step.run("send-welcome-email", async () => {
      console.log(`Sending welcome email to ${event.data.email}`);
      return { emailSent: true };
    });
    
    return { processed: true, userId: event.data.userId };
  }
);

// Inngest API endpoint
app.use("/api/inngest", inngest.createHandler());

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "inngest-worker" });
});

// Test endpoint to trigger events
app.post("/test-event", async (req, res) => {
  try {
    await inngest.send({
      name: "test/hello",
      data: { message: "Test event", timestamp: new Date().toISOString() }
    });
    res.json({ success: true, message: "Test event sent" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const port = process.env.INNGEST_SERVE_PORT || 3000;
const host = process.env.INNGEST_SERVE_HOST || "0.0.0.0";

app.listen(port, host, () => {
  console.log(`Worker server running on http://${host}:${port}`);
  console.log(`Inngest endpoint: http://${host}:${port}/api/inngest`);
});
EOF
        
        # Create Dockerfile for worker
        cat > worker/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S worker -u 1001

# Change ownership
RUN chown -R worker:nodejs /app
USER worker

EXPOSE 3000

CMD ["npm", "start"]
EOF
        
        print_success "Example worker created in worker/ directory"
    else
        print_success "Worker directory already exists"
    fi
}

# Function to pull images
pull_images() {
    print_info "Pulling Docker images..."
    docker-compose pull
    print_success "Docker images pulled"
}

# Function to start services
start_services() {
    print_info "Starting Inngest services..."
    docker-compose up -d
    print_success "Services started"
}

# Function to wait for services
wait_for_services() {
    print_info "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_info "Waiting for PostgreSQL..."
    timeout=60
    while ! docker-compose exec -T inngest-db pg_isready -U ${INNGEST_DB_USER:-inngest} -d ${INNGEST_DB_NAME:-inngest}; do
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
    while ! docker-compose exec -T inngest-redis redis-cli ping | grep -q PONG; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "Redis failed to start within 30 seconds"
            exit 1
        fi
    done
    
    # Wait for Inngest
    print_info "Waiting for Inngest..."
    timeout=60
    while ! curl -f http://localhost:${INNGEST_PORT:-8288}/health > /dev/null 2>&1; do
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -le 0 ]; then
            print_error "Inngest failed to start within 60 seconds"
            exit 1
        fi
    done
    
    print_success "All services are ready"
}

# Function to test Inngest
test_inngest() {
    print_info "Testing Inngest..."
    
    # Test health endpoint
    if curl -f http://localhost:${INNGEST_PORT:-8288}/health > /dev/null 2>&1; then
        print_success "Inngest health check passed"
    else
        print_error "Inngest health check failed"
        return 1
    fi
    
    # Test dashboard
    if curl -f http://localhost:${INNGEST_PORT:-8288} > /dev/null 2>&1; then
        print_success "Inngest dashboard is accessible"
    else
        print_error "Inngest dashboard is not accessible"
        return 1
    fi
    
    # Test worker if running
    if docker-compose ps | grep -q inngest-worker; then
        if curl -f http://localhost:${WORKER_PORT:-3000}/health > /dev/null 2>&1; then
            print_success "Worker is accessible"
        else
            print_warning "Worker is not accessible"
        fi
    fi
}

# Function to display status
show_status() {
    echo ""
    print_success "🎉 Inngest setup completed successfully!"
    echo ""
    echo "📋 Service Status:"
    docker-compose ps
    echo ""
    echo "🔗 Access URLs:"
    echo "  Inngest Dashboard: http://localhost:${INNGEST_PORT:-8288}"
    echo "  Inngest API: http://localhost:${INNGEST_PORT:-8288}/api"
    echo "  Health Check: http://localhost:${INNGEST_PORT:-8288}/health"
    echo ""
    if docker-compose ps | grep -q inngest-worker; then
        echo "  Worker API: http://localhost:${WORKER_PORT:-3000}"
        echo "  Worker Health: http://localhost:${WORKER_PORT:-3000}/health"
        echo ""
    fi
    echo "📊 Service URLs:"
    echo "  PostgreSQL: localhost:${INNGEST_DB_PORT:-5433}"
    echo "  Redis: localhost:${INNGEST_REDIS_PORT:-6380}"
    echo ""
    echo "🔑 Configuration:"
    echo "  Config file: ./.env"
    echo "  Logs: docker-compose logs -f"
    echo "  Worker code: ./worker/"
    echo ""
    print_warning "Next steps:"
    echo "  1. Update .env file with your domain and secure keys"
    echo "  2. Start worker with: docker-compose --profile with-worker up -d"
    echo "  3. Send test event: curl -X POST http://localhost:${WORKER_PORT:-3000}/test-event"
    echo "  4. Check dashboard for function executions"
}

# Main execution
main() {
    print_info "Starting Inngest setup..."
    
    create_directories
    create_env_file
    create_network
    create_example_worker
    
    # Generate keys if in production mode
    if [ "${INNGEST_ENV:-dev}" = "prod" ]; then
        generate_keys
    fi
    
    pull_images
    start_services
    wait_for_services
    test_inngest
    show_status
}

# Run main function
main