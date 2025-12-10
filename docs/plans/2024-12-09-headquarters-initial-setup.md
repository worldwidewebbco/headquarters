# Headquarters Initial Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up a pnpm monorepo with Next.js 15 web app, tRPC API, and all tooling configured and passing CI.

**Architecture:** Monorepo with apps/ for deployables (web, api, worker placeholder) and packages/ for shared code (db, shared, ui). Docker Compose provides PostgreSQL for local dev.

**Tech Stack:** Node 22, pnpm, Next.js 15, React 19, TypeScript 5, tRPC, Tailwind CSS 4, PostgreSQL, Drizzle, Biome, Vitest, Playwright, Husky, GitHub Actions

---

## Task 1: Initialize pnpm Workspace

**Files:**
- Create: `pnpm-workspace.yaml`
- Modify: `package.json`

**Step 1: Create pnpm-workspace.yaml**

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

**Step 2: Update root package.json**

```json
{
  "name": "headquarters",
  "private": true,
  "packageManager": "pnpm@9.15.0",
  "engines": {
    "node": ">=22.0.0"
  },
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "test": "turbo test",
    "lint": "biome check .",
    "format": "biome format --write .",
    "typecheck": "turbo typecheck"
  }
}
```

**Step 3: Create directory structure**

```bash
mkdir -p apps/web apps/api apps/worker packages/db packages/shared packages/ui docker .github/workflows
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: initialize pnpm workspace structure"
```

---

## Task 2: Configure TypeScript Base

**Files:**
- Create: `tsconfig.json`

**Step 1: Create root tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "strict": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noEmit": true
  },
  "exclude": ["node_modules", "dist", ".next", "coverage"]
}
```

**Step 2: Commit**

```bash
git add tsconfig.json
git commit -m "chore: add base TypeScript configuration"
```

---

## Task 3: Configure Biome

**Files:**
- Create: `biome.json`

**Step 1: Create biome.json**

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "correctness": {
        "noUnusedImports": "error",
        "noUnusedVariables": "error"
      },
      "style": {
        "noNonNullAssertion": "warn"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "tab",
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "asNeeded"
    }
  },
  "files": {
    "ignore": [
      "node_modules",
      "dist",
      ".next",
      "coverage",
      "*.config.js",
      "*.config.mjs"
    ]
  }
}
```

**Step 2: Install Biome**

```bash
pnpm add -D -w @biomejs/biome
```

**Step 3: Verify lint works**

```bash
pnpm lint
```

Expected: No errors (empty project)

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: add Biome configuration"
```

---

## Task 4: Configure Turbo

**Files:**
- Create: `turbo.json`

**Step 1: Create turbo.json**

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "test": {
      "dependsOn": ["^build"]
    },
    "typecheck": {
      "dependsOn": ["^build"]
    },
    "lint": {}
  }
}
```

**Step 2: Install Turbo**

```bash
pnpm add -D -w turbo
```

**Step 3: Add .gitignore entries**

Append to `.gitignore`:

```
# Turbo
.turbo

# Dependencies
node_modules

# Build outputs
dist
.next

# Environment
.env
.env.local
.env.*.local

# IDE
.idea
.vscode

# OS
.DS_Store

# Test coverage
coverage
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: add Turbo for monorepo task running"
```

---

## Task 5: Set Up packages/shared

**Files:**
- Create: `packages/shared/package.json`
- Create: `packages/shared/tsconfig.json`
- Create: `packages/shared/src/index.ts`

**Step 1: Create package.json**

```json
{
  "name": "@hq/shared",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./src/index.ts",
      "default": "./src/index.ts"
    }
  },
  "scripts": {
    "typecheck": "tsc --noEmit"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "dist"
  },
  "include": ["src"]
}
```

**Step 3: Create src/index.ts**

```typescript
// @hq/shared - Shared types and utilities
export const APP_NAME = 'Headquarters'
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: set up @hq/shared package"
```

---

## Task 6: Set Up packages/db

**Files:**
- Create: `packages/db/package.json`
- Create: `packages/db/tsconfig.json`
- Create: `packages/db/src/index.ts`
- Create: `packages/db/src/schema.ts`
- Create: `packages/db/drizzle.config.ts`

**Step 1: Create package.json**

```json
{
  "name": "@hq/db",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./src/index.ts",
      "default": "./src/index.ts"
    },
    "./schema": {
      "types": "./src/schema.ts",
      "default": "./src/schema.ts"
    }
  },
  "scripts": {
    "typecheck": "tsc --noEmit",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:push": "drizzle-kit push",
    "db:studio": "drizzle-kit studio"
  },
  "dependencies": {
    "drizzle-orm": "^0.37.0",
    "postgres": "^3.4.5"
  },
  "devDependencies": {
    "drizzle-kit": "^0.30.0"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "dist"
  },
  "include": ["src", "drizzle.config.ts"]
}
```

**Step 3: Create src/schema.ts**

```typescript
// Database schema - add tables here as features are built
// Example:
// export const users = pgTable('users', { ... })
```

**Step 4: Create src/index.ts**

```typescript
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import * as schema from './schema'

const connectionString = process.env.DATABASE_URL ?? 'postgres://localhost:5432/headquarters'

const client = postgres(connectionString)
export const db = drizzle(client, { schema })

export * from './schema'
```

**Step 5: Create drizzle.config.ts**

```typescript
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
	schema: './src/schema.ts',
	out: './drizzle',
	dialect: 'postgresql',
	dbCredentials: {
		url: process.env.DATABASE_URL ?? 'postgres://localhost:5432/headquarters',
	},
})
```

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: set up @hq/db package with Drizzle"
```

---

## Task 7: Set Up packages/ui

**Files:**
- Create: `packages/ui/package.json`
- Create: `packages/ui/tsconfig.json`
- Create: `packages/ui/src/index.ts`

**Step 1: Create package.json**

```json
{
  "name": "@hq/ui",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./src/index.ts",
      "default": "./src/index.ts"
    }
  },
  "scripts": {
    "typecheck": "tsc --noEmit"
  },
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "jsx": "react-jsx",
    "outDir": "dist"
  },
  "include": ["src"]
}
```

**Step 3: Create src/index.ts**

```typescript
// @hq/ui - Shared React components
// Add components here as they are built
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: set up @hq/ui package"
```

---

## Task 8: Set Up apps/api with tRPC

**Files:**
- Create: `apps/api/package.json`
- Create: `apps/api/tsconfig.json`
- Create: `apps/api/src/index.ts`
- Create: `apps/api/src/routers/health.ts`
- Create: `apps/api/src/trpc.ts`

**Step 1: Create package.json**

```json
{
  "name": "@hq/api",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@hq/db": "workspace:*",
    "@hq/shared": "workspace:*",
    "@trpc/server": "^10.45.2",
    "cors": "^2.8.5",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/cors": "^2.8.17",
    "@types/node": "^22.10.1",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src",
    "noEmit": false
  },
  "include": ["src"]
}
```

**Step 3: Create src/trpc.ts**

```typescript
import { initTRPC } from '@trpc/server'

const t = initTRPC.create()

export const router = t.router
export const publicProcedure = t.procedure
```

**Step 4: Create src/routers/health.ts**

```typescript
import { publicProcedure, router } from '../trpc'

export const healthRouter = router({
	check: publicProcedure.query(() => {
		return { status: 'ok', timestamp: new Date().toISOString() }
	}),
})
```

**Step 5: Create src/index.ts**

```typescript
import { createHTTPServer } from '@trpc/server/adapters/standalone'
import cors from 'cors'
import { healthRouter } from './routers/health'
import { router } from './trpc'

const appRouter = router({
	health: healthRouter,
})

export type AppRouter = typeof appRouter

const server = createHTTPServer({
	middleware: cors(),
	router: appRouter,
})

const PORT = process.env.PORT ?? 3001

server.listen(PORT)
console.log(`🚀 API server running on http://localhost:${PORT}`)
```

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: set up tRPC API with health check endpoint"
```

---

## Task 9: Set Up apps/web with Next.js 15

**Files:**
- Create: `apps/web/package.json`
- Create: `apps/web/tsconfig.json`
- Create: `apps/web/next.config.ts`
- Create: `apps/web/tailwind.config.ts`
- Create: `apps/web/postcss.config.mjs`
- Create: `apps/web/src/app/layout.tsx`
- Create: `apps/web/src/app/page.tsx`
- Create: `apps/web/src/app/globals.css`

**Step 1: Create package.json**

```json
{
  "name": "@hq/web",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@hq/shared": "workspace:*",
    "@hq/ui": "workspace:*",
    "@trpc/client": "^10.45.2",
    "@trpc/react-query": "^10.45.2",
    "@tanstack/react-query": "^5.62.7",
    "next": "^15.1.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.10.1",
    "@types/react": "^19.0.1",
    "@types/react-dom": "^19.0.1",
    "postcss": "^8.4.49",
    "tailwindcss": "^4.0.0-beta.8",
    "@tailwindcss/postcss": "^4.0.0-beta.8",
    "typescript": "^5.7.2"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src", "next.config.ts", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

**Step 3: Create next.config.ts**

```typescript
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
	transpilePackages: ['@hq/shared', '@hq/ui'],
}

export default nextConfig
```

**Step 4: Create postcss.config.mjs**

```javascript
export default {
	plugins: {
		'@tailwindcss/postcss': {},
	},
}
```

**Step 5: Create tailwind.config.ts**

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
	content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
	theme: {
		extend: {
			fontFamily: {
				sans: ['Inter', 'system-ui', 'sans-serif'],
			},
		},
	},
	plugins: [],
}

export default config
```

**Step 6: Create src/app/globals.css**

```css
@import 'tailwindcss';
```

**Step 7: Create src/app/layout.tsx**

```tsx
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
	title: 'Headquarters',
	description: 'Personal homelab dashboard and workspace',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
	return (
		<html lang="en">
			<head>
				<link
					href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
					rel="stylesheet"
				/>
			</head>
			<body className="font-sans antialiased">{children}</body>
		</html>
	)
}
```

**Step 8: Create src/app/page.tsx**

```tsx
export default function Home() {
	return (
		<main className="flex min-h-screen items-center justify-center bg-black">
			<h1 className="text-4xl font-semibold text-white">Hello HQ</h1>
		</main>
	)
}
```

**Step 9: Commit**

```bash
git add -A
git commit -m "feat: set up Next.js 15 web app with Tailwind"
```

---

## Task 10: Set Up apps/worker (Placeholder)

**Files:**
- Create: `apps/worker/package.json`
- Create: `apps/worker/README.md`

**Step 1: Create package.json**

```json
{
  "name": "@hq/worker",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "echo 'Worker not implemented yet'",
    "build": "echo 'Worker not implemented yet'",
    "typecheck": "echo 'Worker not implemented yet'"
  }
}
```

**Step 2: Create README.md**

```markdown
# @hq/worker

Temporal worker for background jobs and workflows.

**Status:** Not yet implemented. This is a placeholder.

## Future Implementation

This package will contain:
- Temporal worker setup
- Workflow definitions
- Activity implementations
```

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: add worker package placeholder"
```

---

## Task 11: Set Up Docker Compose

**Files:**
- Create: `docker/docker-compose.yml`
- Create: `docker/.env.example`

**Step 1: Create docker-compose.yml**

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: hq-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-headquarters}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

**Step 2: Create .env.example**

```bash
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=headquarters
POSTGRES_PORT=5432

# Database URL (for apps)
DATABASE_URL=postgres://postgres:postgres@localhost:5432/headquarters
```

**Step 3: Create root .env.example**

Create `.env.example` in root:

```bash
# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/headquarters

# API
PORT=3001
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: add Docker Compose for local development"
```

---

## Task 12: Set Up Vitest

**Files:**
- Create: `vitest.config.ts`
- Modify: `package.json`

**Step 1: Install Vitest**

```bash
pnpm add -D -w vitest @vitest/coverage-v8
```

**Step 2: Create vitest.config.ts**

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
	test: {
		globals: true,
		environment: 'node',
		include: ['**/*.test.ts', '**/*.test.tsx'],
		exclude: ['node_modules', 'dist', '.next'],
		coverage: {
			provider: 'v8',
			reporter: ['text', 'html'],
			exclude: ['node_modules', 'dist', '.next', '**/*.config.*'],
		},
	},
})
```

**Step 3: Update root package.json scripts**

Add to scripts:

```json
"test": "vitest run",
"test:watch": "vitest",
"test:coverage": "vitest run --coverage"
```

**Step 4: Verify test command works**

```bash
pnpm test
```

Expected: "No test files found" (that's fine for now)

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: add Vitest configuration"
```

---

## Task 13: Set Up Playwright

**Files:**
- Create: `playwright.config.ts`
- Create: `e2e/example.spec.ts`

**Step 1: Install Playwright**

```bash
pnpm add -D -w @playwright/test
pnpm exec playwright install
```

**Step 2: Create playwright.config.ts**

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
	testDir: './e2e',
	fullyParallel: true,
	forbidOnly: !!process.env.CI,
	retries: process.env.CI ? 2 : 0,
	workers: process.env.CI ? 1 : undefined,
	reporter: 'html',
	use: {
		baseURL: 'http://localhost:3000',
		trace: 'on-first-retry',
	},
	projects: [
		{
			name: 'chromium',
			use: { ...devices['Desktop Chrome'] },
		},
	],
	webServer: {
		command: 'pnpm --filter @hq/web dev',
		url: 'http://localhost:3000',
		reuseExistingServer: !process.env.CI,
	},
})
```

**Step 3: Create e2e/example.spec.ts**

```typescript
import { expect, test } from '@playwright/test'

test('homepage shows Hello HQ', async ({ page }) => {
	await page.goto('/')
	await expect(page.getByRole('heading', { name: 'Hello HQ' })).toBeVisible()
})
```

**Step 4: Add scripts to root package.json**

```json
"test:e2e": "playwright test",
"test:e2e:ui": "playwright test --ui"
```

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: add Playwright E2E testing setup"
```

---

## Task 14: Set Up Husky and lint-staged

**Files:**
- Create: `.husky/pre-commit`
- Modify: `package.json`

**Step 1: Install Husky and lint-staged**

```bash
pnpm add -D -w husky lint-staged
```

**Step 2: Initialize Husky**

```bash
pnpm exec husky init
```

**Step 3: Create pre-commit hook**

```bash
echo 'pnpm lint-staged' > .husky/pre-commit
```

**Step 4: Add lint-staged config to package.json**

Add to root package.json:

```json
"lint-staged": {
  "*.{js,jsx,ts,tsx,json,css,md}": [
    "biome check --write"
  ]
}
```

**Step 5: Add prepare script**

Ensure package.json has:

```json
"scripts": {
  "prepare": "husky"
}
```

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: add Husky pre-commit hooks with lint-staged"
```

---

## Task 15: Set Up GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1: Create ci.yml**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm test

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm build

  e2e:
    name: E2E Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm test:e2e
```

**Step 2: Commit**

```bash
git add -A
git commit -m "chore: add GitHub Actions CI workflow"
```

---

## Task 16: Install All Dependencies

**Step 1: Run pnpm install**

```bash
pnpm install
```

**Step 2: Verify installation**

```bash
pnpm ls --depth 0
```

**Step 3: Commit lockfile**

```bash
git add pnpm-lock.yaml
git commit -m "chore: add pnpm lockfile"
```

---

## Task 17: Verify Everything Works

**Step 1: Start Docker services**

```bash
cd docker && docker compose up -d && cd ..
```

**Step 2: Run lint**

```bash
pnpm lint
```

Expected: No errors

**Step 3: Run typecheck**

```bash
pnpm typecheck
```

Expected: No errors

**Step 4: Run tests**

```bash
pnpm test
```

Expected: No test files found (that's OK)

**Step 5: Build**

```bash
pnpm build
```

Expected: Builds successfully

**Step 6: Start dev servers**

In separate terminals:

```bash
pnpm --filter @hq/api dev
pnpm --filter @hq/web dev
```

**Step 7: Verify web app**

Open http://localhost:3000 - should see "Hello HQ" on black background

**Step 8: Verify API**

```bash
curl http://localhost:3001/health.check
```

Expected: `{"result":{"data":{"status":"ok","timestamp":"..."}}}`

**Step 9: Run E2E test**

```bash
pnpm test:e2e
```

Expected: 1 test passes

---

## Task 18: Final Commit and Push

**Step 1: Ensure everything is committed**

```bash
git status
```

**Step 2: Push to origin**

```bash
git push origin main
```

**Step 3: Verify CI passes**

Check GitHub Actions for green checkmarks.

---

## Success Criteria Checklist

- [ ] `pnpm install` works
- [ ] `pnpm dev` starts all apps (via turbo)
- [ ] `pnpm build` succeeds
- [ ] `pnpm test` runs (even with no tests)
- [ ] `pnpm lint` passes
- [ ] `pnpm format` works
- [ ] Pre-commit hooks run on commit
- [ ] CI pipeline passes on push
- [ ] Web app shows "Hello HQ" on black background
- [ ] API responds to health check
- [ ] PostgreSQL runs in Docker
- [ ] E2E test passes
