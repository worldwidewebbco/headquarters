# Headquarters (HQ) - Initial Setup Design

**Date:** 2024-12-09
**Status:** Approved
**Domain:** worldwidewebb.co

## Overview

Headquarters is a multi-tenant, self-hostable homelab dashboard and personal workspace. This design covers the initial project setup - establishing the monorepo structure, tooling, and minimal running applications.

## Tech Stack

All packages use the latest stable versions:

| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 22 LTS | Runtime |
| pnpm | Latest | Package manager, workspaces |
| Next.js | 15 | Frontend framework (App Router) |
| React | 19 | UI library |
| TypeScript | 5.x | Type safety |
| tRPC | Latest | End-to-end typed API |
| Tailwind CSS | 4 | Styling |
| PostgreSQL | Latest | Database |
| Drizzle | Latest | ORM |

## Tooling

| Tool | Purpose |
|------|---------|
| Biome | Linting and formatting |
| Vitest | Unit testing |
| Playwright | E2E testing |
| Husky + lint-staged | Git hooks (pre-commit) |
| GitHub Actions | CI pipeline |

### Pre-commit Hooks

On commit, the following checks run on staged files:
- Biome format
- Biome lint
- TypeScript type-check

Tests run in CI only (to keep commits fast).

## Monorepo Structure

```
headquarters/
├── apps/
│   ├── web/                 # Next.js 15 frontend
│   ├── api/                 # tRPC server
│   └── worker/              # Placeholder for Temporal (future)
├── packages/
│   ├── db/                  # Drizzle config and schema
│   ├── shared/              # Shared types and utilities
│   └── ui/                  # Shared React components
├── docker/
│   └── docker-compose.yml   # Local development services
├── .github/
│   └── workflows/
│       └── ci.yml           # CI pipeline
├── biome.json               # Biome configuration
├── pnpm-workspace.yaml      # Workspace definition
├── package.json             # Root package.json
├── tsconfig.json            # Base TypeScript config
└── turbo.json               # Turborepo config (optional)
```

## Initial Implementation Scope

### apps/web
- Next.js 15 with App Router
- Single page: black background, "Hello HQ" centered in white Inter font
- Tailwind CSS configured
- Ready for expansion

### apps/api
- tRPC server
- Single health check endpoint: `GET /health` or `trpc.health.check`
- Ready for expansion

### apps/worker
- Empty directory placeholder
- Will contain Temporal worker and workflow definitions (future)

### packages/db
- Drizzle ORM configured
- PostgreSQL connection setup
- No schema yet (added when features require it)

### packages/shared
- Package structure in place
- Empty exports, ready for types/utils

### packages/ui
- Package structure in place
- Empty exports, ready for components

### docker/
- docker-compose.yml with PostgreSQL for local development
- Temporal services added later when worker is implemented

## Deployment

**Current:** Docker Compose for local development
**Future:** Kubernetes (when ready to deploy to homelab)

## Deferred Decisions

The following are explicitly deferred for later design:

1. **Authentication** - User accounts, sessions, password hashing
2. **Multi-tenancy** - The workspace/tenant abstraction needs more thought
3. **Temporal workflows** - Worker implementation when needed
4. **Features** - No features defined yet, just infrastructure

## Future Considerations

Topics to explore in follow-up design sessions:

1. **Nomad for orchestration** - Alternative/complement to Kubernetes for homelab deployment
2. **Secrets management** - How to handle secrets (possibly git-encrypted with SOPS/age, or Vault, or Nomad's native secrets)
3. **Environment variables strategy** - Standardized approach to `.env` files, env var naming, and configuration across all services
4. **Service configuration patterns** - Ensure all services use consistent env var patterns for configuration

## Success Criteria

The initial setup is complete when:
- [ ] `pnpm install` works
- [ ] `pnpm dev` starts all apps
- [ ] `pnpm build` succeeds
- [ ] `pnpm test` runs (even with no tests)
- [ ] `pnpm lint` passes
- [ ] `pnpm format` works
- [ ] Pre-commit hooks run on commit
- [ ] CI pipeline passes on push
- [ ] Web app shows "Hello HQ" on black background
- [ ] API responds to health check
- [ ] PostgreSQL runs in Docker
