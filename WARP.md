# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Stipendariet is a multi-service application for managing grants and scholarships. The infra-test directory contains Docker Compose orchestration for the full stack:

- **Backend**: FastAPI application (Python 3.11+, not 3.14 due to SQLAlchemy compatibility)
- **Frontend**: React + Vite + TypeScript application with shadcn-ui and Tailwind CSS
- **Database**: PostgreSQL 18
- **Vector Store**: ChromaDB for embeddings/search

The backend and frontend live in sibling directories (`../backend` and `../stipendium-assistenten-frontend`).

## Development Commands

### Primary Development Workflow

Start development with hot reload (recommended):
```bash
docker compose watch
```

Or use the helper script:
```bash
./dev.sh                    # Start with hot reload (default)
./dev.sh start              # Same as above
```

### Other Common Commands

```bash
# Start services in background
docker compose up -d

# Stop all services
docker compose down
./dev.sh down

# View logs
docker compose logs -f                # All services
docker compose logs -f backend        # Backend only
docker compose logs -f frontend       # Frontend only
./dev.sh logs [service]               # Using helper script

# Rebuild containers
docker compose build
./dev.sh build

# Production build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build
./dev.sh prod

# Clean environment (removes containers, volumes, networks)
./dev.sh clean              # Interactive confirmation
```

### Service-Specific Development

Watch specific services only:
```bash
docker compose watch backend
docker compose watch frontend
```

Check service health:
```bash
docker compose ps
docker inspect --format='{{json .State.Health}}' backend
```

### Backend Development

The backend uses uvicorn with `--reload` for automatic restarts on file changes when using `docker compose watch`.

Run tests:
```bash
# Inside backend container or with local Python env
cd ../backend
pytest                      # All tests
pytest tests/               # Tests directory
pytest test_sync_logic.py   # Specific file
```

Backend runs on port 8000 (exposed via nginx in production, directly in dev).

### Frontend Development

The frontend uses Vite dev server with hot module replacement (HMR).

Available scripts (when running locally):
```bash
cd ../stipendium-assistenten-frontend
npm run dev                 # Development server
npm run build               # Production build
npm run build:dev           # Development build
npm run lint                # ESLint
npm run preview             # Preview production build
```

Frontend runs on port 8080.

### Database Access

PostgreSQL runs on port 5432 with default credentials:
```bash
# Connect to database
docker exec -it postgres psql -U postgres -d stipendariet

# Or from host (if psql installed)
psql -h localhost -U postgres -d stipendariet
# Password: postgres
```

ChromaDB runs on port 8000 and is accessible at `http://chroma:8000` from within the Docker network.

## Architecture

### Service Communication

Services communicate within a Docker bridge network named `stipendariet`. In production, nginx proxies requests:

- Frontend requests to `/api/*` are proxied to backend
- Direct backend endpoints: `/grants/`, `/funding/`, `/foundations/`, `/applications/`, `/search/`, `/foundation-sync/`, `/health`
- All other paths serve the frontend

### Backend Structure

```
backend/app/
├── main.py                     # FastAPI app entry point
├── api/v1/routers/            # API endpoints (versioned)
│   ├── grants.py
│   ├── applications.py
│   ├── profile.py
│   ├── generate.py
│   ├── foundations.py
│   ├── foundation_sync.py
│   ├── funding.py
│   └── search.py
├── db/                         # Database layer
│   ├── models.py              # SQLAlchemy models
│   ├── database.py            # Connection setup
│   └── schemas.py             # Pydantic schemas
├── crud/                       # Data access operations
│   └── crud.py
├── foundation/                 # Foundation scraping/sync
│   ├── foundation_api.py
│   ├── sync_service.py
│   ├── scheduler.py
│   └── foundation_schemas.py
└── chroma_service.py           # Vector database integration
```

### Frontend Structure

React SPA with:
- React Router for routing
- TanStack Query for data fetching
- shadcn-ui components
- Tailwind CSS for styling
- Zod for validation

Frontend was originally built with Lovable and includes Lovable-specific tooling.

### Docker Compose Watch

Both services use `develop.watch` for hot reload:

**Backend**: 
- Syncs Python files from `../backend` to `/app` in container
- Rebuilds on `requirements.txt` changes
- uvicorn `--reload` handles automatic restarts

**Frontend**:
- Syncs `src/` and `public/` directories
- Rebuilds on package.json, package-lock.json, vite.config.ts, tailwind.config.ts, or tsconfig.json changes
- Vite HMR provides instant updates

### Environment Variables

**Backend**:
- `DATABASE_URL`: PostgreSQL connection string
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`: PostgreSQL config
- `CHROMA_HOST`, `CHROMA_PORT`: ChromaDB config
- `PYTHONUNBUFFERED=1`: Ensures logs aren't buffered
- `ENVIRONMENT`: Set to `production` in prod builds

**Frontend**:
- `VITE_API_URL`: API base URL (defaults to `/api` via nginx proxy)
- `NODE_ENV`: Set to `production` in prod builds

### Data Persistence

Volumes for persistent data:
- `stipendariet-backend-data`: Backend application data
- `postgres_data`: PostgreSQL database
- `chroma_data`: ChromaDB vector storage
- `./data/postgres`: Local PostgreSQL data (mounted from host)

## Port Reference

- **5432**: PostgreSQL
- **8000**: ChromaDB (conflicts with backend port - backend only exposed internally in docker-compose.yml)
- **8080**: Frontend (exposed)
- **Backend**: Exposed internally, accessible via nginx or docker network

## Compatibility Notes

- **Python 3.14**: Not recommended due to SQLAlchemy compatibility issues. Use Python 3.11 or 3.12.
- **Docker Desktop**: Required for `docker compose watch` feature. Ensure running latest version.

## Troubleshooting

### File changes not detected
```bash
docker compose down && docker compose watch
docker compose logs -f [service-name]
```

### Port conflicts
```bash
lsof -i :8000
lsof -i :8080
lsof -i :5432
# Or modify ports in docker-compose.yml
```

### Database connection issues
Ensure postgres healthcheck passes:
```bash
docker compose ps
docker exec postgres pg_isready -U postgres
```

### Performance on macOS/Windows
- Allocate sufficient resources in Docker Desktop settings
- Enable Docker Desktop's file sharing improvements
