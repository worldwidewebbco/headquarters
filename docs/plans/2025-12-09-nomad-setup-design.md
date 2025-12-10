# Nomad Setup Design

**Date:** 2025-12-09
**Status:** Draft
**Issue:** https://github.com/worldwidewebbco/headquarters/issues/4

## Overview

Replace docker-compose with HashiCorp Nomad for local development orchestration. Nomad will manage all services (web, api, worker, postgres) in containers with hot reload support via volume mounts.

## Goals

- Full containerized stack for local development
- Hot reload without rebuilding images
- Production-like environment locally
- Environment isolation from host machine
- Simple developer workflow via Just commands

## Non-Goals (for now)

- Production deployment (separate issue later)
- Nomad Pack templating (see issue #10)
- NixOS exploration (see issue #9)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    macOS (Developer Machine)             │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │           Nomad Agent (dev mode)                  │   │
│  │                                                   │   │
│  │   Jobs:                                          │   │
│  │   ├── postgres (Docker driver)                   │   │
│  │   ├── api      (Docker driver, volume mounts)    │   │
│  │   ├── web      (Docker driver, volume mounts)    │   │
│  │   └── worker   (Docker driver, volume mounts)    │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                               │
│                          ▼                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │              OrbStack (Docker runtime)            │   │
│  │                                                   │   │
│  │   Containers managed by Nomad                    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  Source code mounted into containers for hot reload     │
└─────────────────────────────────────────────────────────┘
```

**Key decisions:**
- Nomad runs natively on macOS in dev mode (single-node, in-memory state)
- Nomad uses Docker driver to launch containers via OrbStack
- Source code is volume-mounted for instant hot reload
- All services defined as Nomad jobs in HCL files

## File Structure

```
headquarters/
├── infra/
│   ├── docker/
│   │   └── Dockerfile            # Shared multi-stage (dev + prod targets)
│   └── nomad/
│       └── jobs/
│           ├── postgres.nomad    # PostgreSQL database
│           ├── api.nomad         # tRPC API server
│           ├── web.nomad         # Next.js frontend
│           └── worker.nomad      # Background worker
│
├── apps/                         # Unchanged
├── packages/                     # Unchanged
├── justfile                      # Add nomad-* commands
└── (docker/ folder removed)
```

## Dockerfile Design

Single shared Dockerfile with multi-stage builds:

```dockerfile
ARG APP=api
ARG NODE_ENV=development

FROM node:20-alpine AS base
RUN corepack enable

# Dev stage - for local development with volume mounts
FROM base AS dev
WORKDIR /app
CMD ["pnpm", "--filter", "@hq/${APP}", "dev"]

# Build stage - for production
FROM base AS build
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm --filter "@hq/${APP}" build

# Prod stage - minimal production image
FROM base AS prod
WORKDIR /app
COPY --from=build /app/apps/${APP}/dist ./
CMD ["node", "dist/index.js"]
```

**Usage:**
- Dev: `docker build --build-arg APP=api --target dev -t hq-api:dev .`
- Prod: `docker build --build-arg APP=api --target prod -t hq-api:prod .`

## Nomad Job Pattern

Example for api service:

```hcl
job "api" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = 1

    network {
      port "http" { static = 3001 }
    }

    task "api" {
      driver = "docker"

      config {
        image = "hq-api:dev"
        ports = ["http"]

        volumes = [
          "/path/to/headquarters:/app",
          "/app/node_modules",  # Preserve container's node_modules
        ]
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/headquarters"
      }
    }
  }
}
```

## Developer Workflow

**One-time setup:**
```bash
brew install nomad
just nomad-setup    # Build dev images
```

**Daily workflow:**
```bash
just nomad-up       # Start Nomad + all services
# ... code, hot reload works automatically ...
just nomad-down     # Stop everything
```

**Service control:**
```bash
just nomad-logs api     # Tail logs for api
just nomad-restart web  # Restart web service
just nomad-status       # See what's running
```

**Ports:**
| Service  | Port  |
|----------|-------|
| Web      | 3000  |
| API      | 3001  |
| Postgres | 5432  |
| Nomad UI | 4646  |

## Just Commands

Commands to add to justfile:

| Command | Description |
|---------|-------------|
| `nomad-up` | Start Nomad agent and all services |
| `nomad-down` | Stop Nomad and all services |
| `nomad-status` | Show running Nomad jobs |
| `nomad-logs <app>` | Tail logs for a service |
| `nomad-restart <app>` | Restart a specific job |
| `nomad-ui` | Open Nomad UI in browser |
| `nomad-setup` | Build dev Docker images |

## Migration from docker-compose

**Removed:**
- `docker/docker-compose.yml`
- All `docker compose` references in docs

**Updated:**
- README with new Nomad workflow
- CLAUDE.md if it references docker-compose

## Implementation Tasks

1. Install Nomad via Homebrew
2. Create `infra/docker/Dockerfile` (multi-stage)
3. Create Nomad job files:
   - `infra/nomad/jobs/postgres.nomad`
   - `infra/nomad/jobs/api.nomad`
   - `infra/nomad/jobs/web.nomad`
   - `infra/nomad/jobs/worker.nomad`
4. Add Just commands for Nomad workflow
5. Update README with Nomad instructions
6. Delete `docker/` folder
7. Test full workflow end-to-end

## Related Issues

- #9: Investigate NixOS for reproducible environments
- #10: Explore Nomad Pack for templated deployments
