# Stipendariet Infrastructure

This directory contains Docker Compose configurations for running the Stipendariet application stack.

## Quick Start

### Development with Hot Reload (Recommended)

```bash
# Navigate to infra-test directory
cd infra-test

# Start services with watch mode for automatic reloading
docker compose watch

# Or start in detached mode and then watch
docker compose up -d
docker compose watch
```

### Production Build

```bash
# Build and run production containers
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build
```

## Services

- **Backend**: FastAPI application running on port 8000
- **Frontend**: React + Vite application running on port 8080

## Development Features

### Docker Compose Watch

The development setup uses Docker Compose Watch for automatic reloading:

**Backend (FastAPI)**:
- ✅ **File sync**: Python source files are synced to the container
- ✅ **Hot reload**: uvicorn `--reload` automatically restarts on file changes
- ✅ **Dependency rebuild**: Container rebuilds when `requirements.txt` changes

**Frontend (React + Vite)**:
- ✅ **File sync**: Source files (`src/`, `public/`) are synced to the container
- ✅ **Hot reload**: Vite dev server provides instant hot module replacement
- ✅ **Config rebuild**: Container rebuilds when config files change

### Watch Commands

```bash
# Start all services with watch
docker compose watch

# Watch specific service
docker compose watch backend
docker compose watch frontend

# Stop watching (Ctrl+C or)
docker compose down
```

## File Structure

```
infra-test/
├── docker-compose.yml      # Main development configuration
├── docker-compose.prod.yml # Production overrides
└── README.md              # This file

../backend/
├── Dockerfile             # Production backend image
├── Dockerfile.dev         # Development backend image
└── ...

../stipendium-assistenten-frontend/
├── Dockerfile             # Production frontend image
├── Dockerfile.dev         # Development frontend image
└── ...
```

## Environment Variables

### Backend
- `PYTHONUNBUFFERED=1`: Ensures Python output is not buffered
- `ENVIRONMENT`: Set to `production` in prod builds

### Frontend
- `VITE_API_URL`: API endpoint URL (defaults to http://localhost:8000)
- `NODE_ENV`: Set to `production` in prod builds

## Troubleshooting

### File Changes Not Detected
If file changes aren't being detected, try:
1. Ensure you're in the `infra-test` directory
2. Restart the watch: `docker compose down && docker compose watch`
3. Check container logs: `docker compose logs -f [service-name]`

### Port Conflicts
If ports 8000 or 8080 are in use:
```bash
# Check what's using the ports
lsof -i :8000
lsof -i :8080

# Or modify ports in docker-compose.yml
```

### Performance Issues
For better performance on macOS/Windows:
- Ensure Docker Desktop has sufficient resources allocated
- Consider using Docker Desktop's new file sharing improvements