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
