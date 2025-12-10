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
