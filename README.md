# HQ (Headquarters)

Personal homelab dashboard and workspace.

## Tech Stack

- **Runtime:** Node.js 22 LTS
- **Package Manager:** pnpm (monorepo with workspaces)
- **Frontend:** Next.js 15, React 19, Tailwind CSS 4
- **API:** tRPC (end-to-end type safety)
- **Database:** PostgreSQL with Drizzle ORM
- **Testing:** Vitest (unit), Playwright (E2E)
- **Tooling:** Biome (lint/format), Turbo (build), Husky (git hooks)

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

### Setup

```bash
# Install dependencies
pnpm install

# Start PostgreSQL
cd docker && docker compose up -d && cd ..

# Start development servers
pnpm dev
```

### Available Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start all apps in development mode |
| `pnpm build` | Build all apps |
| `pnpm test` | Run unit tests |
| `pnpm test:e2e` | Run E2E tests |
| `pnpm lint` | Lint all files |
| `pnpm format` | Format all files |
| `pnpm typecheck` | Type-check all packages |

### Development URLs

- **Web:** http://localhost:3000
- **API:** http://localhost:3001

## License

Private
