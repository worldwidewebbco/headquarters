# Default: show available recipes
default:
    @just --list

# ─────────────────────────────────────────────────────────────────────────────
# Development
# ─────────────────────────────────────────────────────────────────────────────

# Start all apps in development mode
dev:
    pnpm dev

# Build all apps
build:
    pnpm build

# ─────────────────────────────────────────────────────────────────────────────
# Testing
# ─────────────────────────────────────────────────────────────────────────────

# Run unit tests
test:
    pnpm test

# Run unit tests in watch mode
test-watch:
    pnpm test:watch

# Run unit tests with coverage
test-coverage:
    pnpm test:coverage

# Run E2E tests (headless)
test-e2e:
    pnpm test:e2e

# Run E2E tests with interactive UI
test-e2e-ui:
    pnpm test:e2e:ui

# ─────────────────────────────────────────────────────────────────────────────
# Code Quality
# ─────────────────────────────────────────────────────────────────────────────

# Lint code with Biome
lint:
    pnpm lint

# Format code with Biome
format:
    pnpm format

# Type-check all packages
typecheck:
    pnpm typecheck

# Run all checks (lint + typecheck)
check: lint typecheck

# ─────────────────────────────────────────────────────────────────────────────
# Docker
# ─────────────────────────────────────────────────────────────────────────────

# Start PostgreSQL container
docker-up:
    docker compose -f docker/docker-compose.yml up -d

# Stop PostgreSQL container
docker-down:
    docker compose -f docker/docker-compose.yml down

# View PostgreSQL container logs
docker-logs:
    docker compose -f docker/docker-compose.yml logs -f

# ─────────────────────────────────────────────────────────────────────────────
# Nomad (Local Orchestration)
# ─────────────────────────────────────────────────────────────────────────────

# Build dev Docker image for Nomad
nomad-build:
    docker build -f infra/docker/Dockerfile --target dev -t hq-dev:latest .

# Start Nomad agent in dev mode (background)
nomad-agent:
    @echo "Starting Nomad agent in dev mode..."
    @nomad agent -dev -bind=127.0.0.1 > /tmp/nomad.log 2>&1 &
    @sleep 2
    @echo "Nomad agent started. UI: http://localhost:4646"

# Stop Nomad agent
nomad-agent-stop:
    @pkill -f "nomad agent -dev" || true
    @echo "Nomad agent stopped"

# Start all services with Nomad
nomad-up: nomad-build nomad-agent
    @echo "Starting services..."
    nomad job run -var="project_dir={{justfile_directory()}}" infra/nomad/jobs/postgres.nomad
    @echo "Waiting for PostgreSQL..."
    @sleep 3
    nomad job run -var="project_dir={{justfile_directory()}}" infra/nomad/jobs/api.nomad
    nomad job run -var="project_dir={{justfile_directory()}}" infra/nomad/jobs/web.nomad
    nomad job run -var="project_dir={{justfile_directory()}}" infra/nomad/jobs/worker.nomad
    @echo ""
    @echo "All services started!"
    @echo "  Web:      http://localhost:3000"
    @echo "  API:      http://localhost:3001"
    @echo "  Nomad UI: http://localhost:4646"

# Stop all services and Nomad agent
nomad-down:
    @echo "Stopping services..."
    @nomad job stop -purge web 2>/dev/null || true
    @nomad job stop -purge api 2>/dev/null || true
    @nomad job stop -purge worker 2>/dev/null || true
    @nomad job stop -purge postgres 2>/dev/null || true
    just nomad-agent-stop

# Show Nomad job status
nomad-status:
    @nomad job status

# Tail logs for a specific service
nomad-logs service:
    nomad alloc logs -job {{service}} -f

# Restart a specific service
nomad-restart service:
    nomad job restart {{service}}

# Open Nomad UI in browser
nomad-ui:
    open http://localhost:4646

# ─────────────────────────────────────────────────────────────────────────────
# Database
# ─────────────────────────────────────────────────────────────────────────────

# Generate Drizzle migrations
db-generate:
    pnpm --filter @hq/db db:generate

# Run Drizzle migrations
db-migrate:
    pnpm --filter @hq/db db:migrate

# Push schema to database (dev only)
db-push:
    pnpm --filter @hq/db db:push

# Open Drizzle Studio
db-studio:
    pnpm --filter @hq/db db:studio

# ─────────────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────────────

# Install dependencies
install:
    pnpm install

# Full project setup (install deps, start docker, push schema)
setup: install docker-up
    @echo "Waiting for PostgreSQL to be ready..."
    @sleep 2
    just db-push
