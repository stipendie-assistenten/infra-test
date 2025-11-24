#!/bin/bash

# Development helper script for Stipendariet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check if docker compose supports watch
if ! docker compose --help | grep -q "watch"; then
    print_error "Docker Compose watch is not available. Please update Docker Desktop to the latest version."
    exit 1
fi

case "$1" in
    "start"|"watch"|"")
        print_status "Starting development environment with hot reload..."
        docker compose watch
        ;;
    "up")
        print_status "Starting services in detached mode..."
        docker compose up -d
        print_success "Services started. Use 'docker compose watch' to enable hot reload."
        ;;
    "down")
        print_status "Stopping all services..."
        docker compose down
        print_success "All services stopped."
        ;;
    "logs")
        if [ -n "$2" ]; then
            docker compose logs -f "$2"
        else
            docker compose logs -f
        fi
        ;;
    "build")
        print_status "Building all services..."
        docker compose build
        print_success "Build complete."
        ;;
    "prod")
        print_status "Starting production environment..."
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build
        ;;
    "clean")
        print_warning "This will remove all containers, networks, and volumes."
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down -v --remove-orphans
            docker system prune -f
            print_success "Cleanup complete."
        else
            print_status "Cleanup cancelled."
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Stipendariet Development Helper"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start, watch, (empty)  Start development with hot reload (default)"
        echo "  up                     Start services in detached mode"
        echo "  down                   Stop all services"
        echo "  logs [service]         Show logs (optionally for specific service)"
        echo "  build                  Build all services"
        echo "  prod                   Start production environment"
        echo "  clean                  Remove all containers, networks, and volumes"
        echo "  help                   Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                     # Start with hot reload"
        echo "  $0 logs backend        # Show backend logs"
        echo "  $0 prod                # Run production build"
        ;;
    *)
        print_error "Unknown command: $1"
        print_status "Use '$0 help' to see available commands."
        exit 1
        ;;
esac
