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
# Nomad (Local Orchestration)
# ─────────────────────────────────────────────────────────────────────────────

# Start Nomad agent in dev mode (background)
nomad-agent:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Starting Nomad agent in dev mode..."
    nomad agent -dev -bind=127.0.0.1 > /tmp/nomad.log 2>&1 &
    # Wait for Nomad API to be ready
    for i in {1..30}; do
        if nomad status &>/dev/null; then
            echo "Nomad agent started. UI: http://localhost:4646"
            exit 0
        fi
        sleep 0.5
    done
    echo "Error: Nomad agent failed to start"
    exit 1

# Stop Nomad agent
nomad-agent-stop:
    @pkill -f "nomad agent -dev" || true
    @echo "Nomad agent stopped"

# Wait for PostgreSQL to be ready
[private]
wait-postgres:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Waiting for PostgreSQL..."
    for i in {1..60}; do
        if nc -z localhost 5432 2>/dev/null; then
            echo "PostgreSQL is ready"
            exit 0
        fi
        sleep 0.5
    done
    echo "Error: PostgreSQL failed to start within 30s"
    exit 1

# Start all services with Nomad (dynamically discovers job files)
nomad-up: nomad-agent
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Starting services..."

    # Start postgres first (infrastructure)
    nomad job run {{justfile_directory()}}/infra/nomad/jobs/postgres.nomad

    # Wait for postgres to be healthy
    just wait-postgres

    # Start all other jobs dynamically
    for job in {{justfile_directory()}}/infra/nomad/jobs/*.nomad; do
        [[ "$(basename "$job")" == "postgres.nomad" ]] && continue
        nomad job run -var="project_dir={{justfile_directory()}}" "$job"
    done

    echo ""
    echo "All services started!"
    echo "  Web:      http://localhost:3000"
    echo "  API:      http://localhost:3001"
    echo "  Nomad UI: http://localhost:4646"

# Stop all services and Nomad agent (dynamically discovers running jobs)
nomad-down:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Stopping services..."

    # Get all running jobs and stop them
    for job in $(nomad job status -short 2>/dev/null | tail -n +2 | awk '{print $1}'); do
        echo "Stopping $job..."
        nomad job stop -purge "$job" 2>/dev/null || true
    done

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

# Full project setup (install deps, start nomad, push schema)
setup: install
    just nomad-up
    just db-push
