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

Run `just` to see all available commands with descriptions.

### Development URLs

| Service | URL |
|---------|-----|
| Web | http://localhost:3000 |
| API | http://localhost:3001 |
| Nomad UI | http://localhost:4646 |

## License

Private
