# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Brainstorming & Questions

- When asking questions during brainstorming or any interactive process, ALWAYS use the AskUserQuestion tool instead of plain text questions.

## Build & Development Commands

```bash
pnpm dev              # Start all apps (web:3000, api:3001)
pnpm build            # Build all packages
pnpm lint             # Lint with Biome
pnpm format           # Format with Biome
pnpm typecheck        # TypeScript check all packages
```

### Testing

```bash
pnpm test             # Run all unit tests (Vitest)
pnpm test:watch       # Watch mode
vitest run path/to/file.test.ts  # Run single test file
pnpm test:e2e         # Run Playwright E2E tests
pnpm test:e2e:ui      # Playwright with UI
```

### Database

```bash
just nomad-up                      # Start PostgreSQL via Nomad (recommended)
# Or standalone:
just docker-up                     # Start PostgreSQL container only
pnpm --filter @hq/db db:generate   # Generate migrations
pnpm --filter @hq/db db:migrate    # Run migrations
pnpm --filter @hq/db db:studio     # Open Drizzle Studio
```

## Architecture

**Monorepo structure using pnpm workspaces + Turbo:**

- `apps/web` - Next.js 15 frontend (React 19, Tailwind 4)
- `apps/api` - tRPC standalone server (port 3001)
- `apps/worker` - Background jobs (placeholder for Temporal)
- `packages/db` - Drizzle ORM schema and client (`@hq/db`)
- `packages/shared` - Shared types and utilities (`@hq/shared`)
- `packages/ui` - Shared React components (`@hq/ui`)

**Key patterns:**
- tRPC provides end-to-end type safety between web and api
- `AppRouter` type exported from `apps/api/src/index.ts` for client typing
- Database client exported from `@hq/db` package
- All packages use `@hq/*` namespace

## Code Style

- **Formatter:** Biome with tabs, single quotes, no semicolons
- **Line width:** 100 characters
- **Imports:** Auto-organized by Biome

## Development Practices

- **No sleep hacks:** Never use hardcoded `sleep` for timing/synchronization, even in dev scripts. Use proper health checks, polling with conditions, or dependency mechanisms instead.
- **Single source of truth:** Commands are documented in `justfile` with comments. Run `just` to see all available commands. Don't duplicate command lists in README or other docs.
- **Dynamic over hardcoded:** Prefer dynamic discovery (glob patterns, querying state) over hardcoded lists that need manual updates.
