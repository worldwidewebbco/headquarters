# Nomad Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace docker-compose with HashiCorp Nomad for local development orchestration with hot reload support.

**Architecture:** Nomad runs in dev mode on macOS, using the Docker driver to launch containers via OrbStack. A single multi-stage Dockerfile serves all apps. Volume mounts enable hot reload without image rebuilds.

**Tech Stack:** Nomad (dev mode), Docker (via OrbStack), Node.js 22, pnpm, Just task runner

---

## Task 1: Create infra directory structure

**Files:**
- Create: `infra/docker/.gitkeep`
- Create: `infra/nomad/jobs/.gitkeep`

**Step 1: Create directory structure**

```bash
mkdir -p infra/docker infra/nomad/jobs
touch infra/docker/.gitkeep infra/nomad/jobs/.gitkeep
```

**Step 2: Commit**

```bash
git add infra/
git commit -m "chore: create infra directory structure for Docker and Nomad"
```

---

## Task 2: Create shared multi-stage Dockerfile

**Files:**
- Create: `infra/docker/Dockerfile`

**Step 1: Create the Dockerfile**

Create `infra/docker/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1

# Build argument to specify which app to build
ARG APP=api

# ─────────────────────────────────────────────────────────────────────────────
# Base stage: Common setup for all stages
# ─────────────────────────────────────────────────────────────────────────────
FROM node:22-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# ─────────────────────────────────────────────────────────────────────────────
# Dev stage: For local development with volume mounts
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS dev

ARG APP

# Install dependencies for all workspaces
# In dev, we mount the entire project, so deps are on the host
# This stage is mainly for the CMD

# The actual source code is mounted as a volume
# node_modules from host is also mounted

CMD ["sh", "-c", "pnpm --filter @hq/${APP} dev"]

# ─────────────────────────────────────────────────────────────────────────────
# Dependencies stage: Install production dependencies
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS deps

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api/package.json ./apps/api/
COPY apps/web/package.json ./apps/web/
COPY apps/worker/package.json ./apps/worker/
COPY packages/db/package.json ./packages/db/
COPY packages/shared/package.json ./packages/shared/
COPY packages/ui/package.json ./packages/ui/

RUN pnpm install --frozen-lockfile

# ─────────────────────────────────────────────────────────────────────────────
# Build stage: Build the specified app
# ─────────────────────────────────────────────────────────────────────────────
FROM deps AS build

ARG APP

COPY . .

# Build shared packages first, then the app
RUN pnpm --filter @hq/shared build 2>/dev/null || true
RUN pnpm --filter @hq/db build 2>/dev/null || true
RUN pnpm --filter @hq/ui build 2>/dev/null || true
RUN pnpm --filter @hq/${APP} build

# ─────────────────────────────────────────────────────────────────────────────
# Prod stage: Production image for API
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS prod-api

WORKDIR /app

COPY --from=build /app/apps/api/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps/api/package.json ./

ENV NODE_ENV=production

EXPOSE 3001

CMD ["node", "dist/index.js"]

# ─────────────────────────────────────────────────────────────────────────────
# Prod stage: Production image for Web (Next.js standalone)
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS prod-web

WORKDIR /app

# Next.js standalone output
COPY --from=build /app/apps/web/.next/standalone ./
COPY --from=build /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=build /app/apps/web/public ./apps/web/public

ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "apps/web/server.js"]
```

**Step 2: Verify Dockerfile syntax**

```bash
docker build --check -f infra/docker/Dockerfile .
```

Expected: No syntax errors

**Step 3: Commit**

```bash
git add infra/docker/Dockerfile
git commit -m "feat: add shared multi-stage Dockerfile for all apps"
```

---

## Task 3: Create Nomad job for PostgreSQL

**Files:**
- Create: `infra/nomad/jobs/postgres.nomad`

**Step 1: Create the postgres job file**

Create `infra/nomad/jobs/postgres.nomad`:

```hcl
job "postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    count = 1

    network {
      port "db" {
        static = 5432
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:16-alpine"
        ports = ["db"]

        # Persist data across restarts
        volumes = [
          "hq-postgres-data:/var/lib/postgresql/data",
        ]
      }

      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "headquarters"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "postgres"
        port = "db"

        check {
          type     = "script"
          command  = "pg_isready"
          args     = ["-U", "postgres"]
          interval = "5s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

**Step 2: Validate syntax (requires Nomad installed)**

```bash
nomad job validate infra/nomad/jobs/postgres.nomad 2>/dev/null || echo "Nomad not installed yet - will validate after setup"
```

**Step 3: Commit**

```bash
git add infra/nomad/jobs/postgres.nomad
git commit -m "feat: add Nomad job for PostgreSQL"
```

---

## Task 4: Create Nomad job for API

**Files:**
- Create: `infra/nomad/jobs/api.nomad`

**Step 1: Create the api job file**

Create `infra/nomad/jobs/api.nomad`:

```hcl
variable "project_dir" {
  type    = string
  default = ""
}

job "api" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = 1

    network {
      port "http" {
        static = 3001
      }
    }

    task "api" {
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        ports   = ["http"]
        command = "pnpm"
        args    = ["--filter", "@hq/api", "dev"]

        # Mount source code for hot reload
        volumes = [
          "${var.project_dir}:/app",
        ]

        # Working directory
        work_dir = "/app"
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@host.docker.internal:5432/headquarters"
        PORT         = "3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "api"
        port = "http"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

**Step 2: Commit**

```bash
git add infra/nomad/jobs/api.nomad
git commit -m "feat: add Nomad job for API service"
```

---

## Task 5: Create Nomad job for Web

**Files:**
- Create: `infra/nomad/jobs/web.nomad`

**Step 1: Create the web job file**

Create `infra/nomad/jobs/web.nomad`:

```hcl
variable "project_dir" {
  type    = string
  default = ""
}

job "web" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    task "web" {
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        ports   = ["http"]
        command = "pnpm"
        args    = ["--filter", "@hq/web", "dev"]

        # Mount source code for hot reload
        volumes = [
          "${var.project_dir}:/app",
        ]

        # Working directory
        work_dir = "/app"
      }

      env {
        NODE_ENV = "development"
        PORT     = "3000"
        # API URL for tRPC client
        NEXT_PUBLIC_API_URL = "http://localhost:3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "web"
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

**Step 2: Commit**

```bash
git add infra/nomad/jobs/web.nomad
git commit -m "feat: add Nomad job for Web service"
```

---

## Task 6: Create Nomad job for Worker

**Files:**
- Create: `infra/nomad/jobs/worker.nomad`

**Step 1: Create the worker job file**

Create `infra/nomad/jobs/worker.nomad`:

```hcl
variable "project_dir" {
  type    = string
  default = ""
}

job "worker" {
  datacenters = ["dc1"]
  type        = "service"

  group "worker" {
    count = 1

    task "worker" {
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        command = "pnpm"
        args    = ["--filter", "@hq/worker", "dev"]

        # Mount source code for hot reload
        volumes = [
          "${var.project_dir}:/app",
        ]

        # Working directory
        work_dir = "/app"
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@host.docker.internal:5432/headquarters"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
```

**Step 2: Commit**

```bash
git add infra/nomad/jobs/worker.nomad
git commit -m "feat: add Nomad job for Worker service"
```

---

## Task 7: Add Nomad commands to justfile

**Files:**
- Modify: `justfile`

**Step 1: Add Nomad recipes to justfile**

Add these recipes after the existing Docker section in `justfile`:

```just
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
```

**Step 2: Verify justfile syntax**

```bash
just --list
```

Expected: All commands listed without errors

**Step 3: Commit**

```bash
git add justfile
git commit -m "feat: add Nomad commands to justfile"
```

---

## Task 8: Update README with Nomad workflow

**Files:**
- Modify: `README.md`

**Step 1: Update README.md**

Replace the contents of `README.md` with:

```markdown
# HQ (Headquarters)

Personal homelab dashboard and workspace.

## Tech Stack

- **Runtime:** Node.js 22 LTS
- **Package Manager:** pnpm (monorepo with workspaces)
- **Frontend:** Next.js 15, React 19, Tailwind CSS 4
- **API:** tRPC (end-to-end type safety)
- **Database:** PostgreSQL with Drizzle ORM
- **Orchestration:** HashiCorp Nomad (local dev)
- **Testing:** Vitest (unit), Playwright (E2E)
- **Tooling:** Biome (lint/format), Turbo (build), Husky (git hooks), Just (task runner)

## Project Structure

```
headquarters/
├── apps/
│   ├── web/        # Next.js frontend
│   ├── api/        # tRPC API server
│   └── worker/     # Background worker (Temporal - future)
├── packages/
│   ├── db/         # Database schema and client
│   ├── shared/     # Shared types and utilities
│   └── ui/         # Shared React components
└── infra/
    ├── docker/     # Shared Dockerfile
    └── nomad/      # Nomad job specifications
```

## Getting Started

### Prerequisites

- Node.js 22+
- pnpm 9+
- Docker (OrbStack, Docker Desktop, or Colima)
- [Just](https://just.systems) (task runner)
- [Nomad](https://developer.hashicorp.com/nomad/install) (orchestration)

### Installation

```bash
# Install Nomad (macOS)
brew install nomad

# Install Just (if not installed)
brew install just
```

### Development

```bash
# Full stack with Nomad (recommended)
just nomad-up        # Start all services via Nomad
just nomad-down      # Stop all services

# Or run directly without containers
just setup           # Install deps, start Postgres, push schema
just dev             # Start dev servers
```

### Available Commands

Run `just` to see all available commands. Key commands:

| Command | Description |
|---------|-------------|
| **Development** | |
| `just dev` | Start apps directly (no containers) |
| `just build` | Build all apps |
| **Nomad** | |
| `just nomad-up` | Start full stack via Nomad |
| `just nomad-down` | Stop Nomad and all services |
| `just nomad-status` | Show running Nomad jobs |
| `just nomad-logs <service>` | Tail logs for a service |
| `just nomad-restart <service>` | Restart a specific service |
| `just nomad-ui` | Open Nomad UI in browser |
| **Testing** | |
| `just test` | Run unit tests |
| `just test-e2e` | Run E2E tests (headless) |
| `just test-e2e-ui` | Run E2E tests with interactive UI |
| **Code Quality** | |
| `just lint` | Lint all files |
| `just format` | Format all files |
| `just typecheck` | Type-check all packages |
| `just check` | Run lint + typecheck |
| **Database** | |
| `just db-migrate` | Run database migrations |
| `just db-studio` | Open Drizzle Studio |

### Development URLs

| Service | URL |
|---------|-----|
| Web | http://localhost:3000 |
| API | http://localhost:3001 |
| Nomad UI | http://localhost:4646 |

## License

Private
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with Nomad workflow"
```

---

## Task 9: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update CLAUDE.md database section**

Replace the Database section in `CLAUDE.md`:

```markdown
### Database

```bash
just nomad-up                      # Start PostgreSQL via Nomad (recommended)
# Or standalone:
just docker-up                     # Start PostgreSQL container only
pnpm --filter @hq/db db:generate   # Generate migrations
pnpm --filter @hq/db db:migrate    # Run migrations
pnpm --filter @hq/db db:studio     # Open Drizzle Studio
```
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with Nomad database command"
```

---

## Task 10: Delete docker-compose

**Files:**
- Delete: `docker/docker-compose.yml`
- Delete: `docker/` directory

**Step 1: Remove docker-compose references from justfile**

Remove the Docker section from `justfile` (lines with docker-up, docker-down, docker-logs):

```bash
# Remove these recipes from justfile:
# docker-up, docker-down, docker-logs
```

Update the `setup` recipe to use Nomad instead:

```just
# Full project setup (install deps, start nomad, push schema)
setup: install
    just nomad-up
    @echo "Waiting for PostgreSQL to be ready..."
    @sleep 3
    just db-push
```

**Step 2: Delete docker directory**

```bash
rm -rf docker/
```

**Step 3: Commit**

```bash
git add justfile
git rm -r docker/
git commit -m "chore: remove docker-compose in favor of Nomad"
```

---

## Task 11: Test the full workflow

**Step 1: Verify Nomad is installed**

```bash
nomad version
```

Expected: Version info (e.g., `Nomad v1.x.x`)

If not installed:
```bash
brew install nomad
```

**Step 2: Build dev image**

```bash
just nomad-build
```

Expected: Image builds successfully

**Step 3: Start Nomad and services**

```bash
just nomad-up
```

Expected: All services start, URLs printed

**Step 4: Verify services are running**

```bash
just nomad-status
```

Expected: 4 jobs (postgres, api, web, worker) with status "running"

**Step 5: Test API health endpoint**

```bash
curl http://localhost:3001/health
```

Expected: Health response

**Step 6: Test Web**

```bash
curl -I http://localhost:3000
```

Expected: HTTP 200 response

**Step 7: Stop everything**

```bash
just nomad-down
```

Expected: All services stopped, Nomad agent stopped

**Step 8: Commit verification notes (optional)**

If everything works, update the design doc status:

```bash
# Edit docs/plans/2025-12-09-nomad-setup-design.md
# Change Status: Draft → Implemented
git add docs/plans/2025-12-09-nomad-setup-design.md
git commit -m "docs: mark Nomad design as implemented"
```

---

## Summary

After completing all tasks, you will have:

1. `infra/docker/Dockerfile` - Shared multi-stage Dockerfile
2. `infra/nomad/jobs/` - 4 Nomad job files (postgres, api, web, worker)
3. Updated `justfile` with Nomad commands
4. Updated `README.md` with Nomad workflow
5. Removed `docker/` folder

Run `just nomad-up` to start the full stack via Nomad!
