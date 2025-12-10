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
