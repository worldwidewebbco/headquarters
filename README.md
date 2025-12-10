# HQ (Headquarters)

Personal homelab dashboard and workspace.

## Tech Stack

- **Runtime:** Node.js 22 LTS
- **Package Manager:** pnpm (monorepo with workspaces)
- **Frontend:** Next.js 15, React 19, Tailwind CSS 4
- **API:** tRPC (end-to-end type safety)
- **Database:** PostgreSQL with Drizzle ORM
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
└── docker/         # Docker Compose for local services
```

## Getting Started

### Prerequisites

- Node.js 22+
- pnpm 9+
- Docker (for PostgreSQL)
- [Just](https://just.systems) (task runner)

### Setup

```bash
# Full setup (install deps, start docker, push schema)
just setup

# Or manually:
just install      # Install dependencies
just docker-up    # Start PostgreSQL
just db-push      # Push schema to database
just dev          # Start development servers
```

### Available Commands

Run `just` to see all available commands. Key commands:

| Command | Description |
|---------|-------------|
| `just dev` | Start all apps in development mode |
| `just build` | Build all apps |
| `just test` | Run unit tests |
| `just test-e2e` | Run E2E tests (headless) |
| `just test-e2e-ui` | Run E2E tests with interactive UI |
| `just lint` | Lint all files |
| `just format` | Format all files |
| `just typecheck` | Type-check all packages |
| `just check` | Run lint + typecheck |
| `just docker-up` | Start PostgreSQL container |
| `just docker-down` | Stop PostgreSQL container |
| `just db-migrate` | Run database migrations |
| `just db-studio` | Open Drizzle Studio |

### Development URLs

- **Web:** http://localhost:3000
- **API:** http://localhost:3001

## License

Private
