# ADR 001: Technology Stack Upgrades

**Date:** 2024-12-09
**Status:** Accepted

## Context

During implementation of the initial monorepo setup, several dependencies were upgraded beyond what was specified in the original implementation plan to use the latest stable versions.

## Decisions

### 1. tRPC v11 (instead of v10)

**Plan specified:** `@trpc/server: ^10.45.2`, `@trpc/react-query`
**Implemented:** `@trpc/server: ^11.0.0`, `@trpc/tanstack-react-query`

**Rationale:**
- tRPC v11 is the latest stable version (released late 2024)
- Package was renamed from `@trpc/react-query` to `@trpc/tanstack-react-query`
- v11 includes performance improvements and better TypeScript inference
- Breaking changes are minimal for a greenfield project

### 2. Biome 2.x (instead of 1.9.x)

**Plan specified:** Biome schema `1.9.4`
**Implemented:** Biome schema `2.3.8`

**Rationale:**
- Biome 2.x has improved configuration structure
- Uses `includes` with exclusion patterns instead of `ignore` array
- Better VS Code integration
- Added `assist` configuration for enhanced tooling

### 3. Configuration Additions

**Not in plan, added:**
- `passWithNoTests: true` in vitest.config.ts
- `.claude-trace` exclusion in biome.json
- `.turbo` exclusion in biome.json
- `*.tsbuildinfo` in .gitignore
- Inline design decisions documentation in CI workflow

**Rationale:**
- `passWithNoTests` allows CI to pass during early development when test files don't exist yet
- `.claude-trace` exclusion prevents AI-generated trace files from being linted
- `.turbo` exclusion prevents turbo cache files from being linted
- `*.tsbuildinfo` are TypeScript incremental build artifacts that shouldn't be committed
- Inline CI documentation explains non-obvious decisions for future maintainers

## Consequences

### Positive
- Using latest stable versions reduces technical debt
- Better tooling support and performance
- Future-proofed for 2025 development

### Negative
- Minor deviation from implementation plan (documented here)
- Team members must use tRPC v11 docs, not v10

## References

- [tRPC v11 Migration Guide](https://trpc.io/docs/migrate-from-v10-to-v11)
- [Biome 2.0 Announcement](https://biomejs.dev/blog/biome-v2/)
