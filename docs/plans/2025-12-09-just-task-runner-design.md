# Just Task Runner Setup

**Date:** 2025-12-09

## Summary

Added Just as a unified task runner interface for the project. Just provides a single command interface for all project operations (development, testing, docker, database) while keeping the underlying pnpm/turbo tooling intact.

## Design Decisions

### Why Just over Make?

- Modern syntax, fewer footguns (no tab-sensitivity issues)
- Built-in `--list` command shows all available recipes with descriptions
- Cross-platform support
- First-class support for recipe dependencies

### Approach: Wrap pnpm

Just recipes call pnpm scripts rather than invoking turbo/vite/biome directly.

**Rationale:**
- Single source of truth for JS build commands (package.json)
- Turbo caching continues to work through pnpm
- Just adds value for non-JS tasks (docker, database) that don't belong in package.json
- Easier maintenance - changes to build tooling only happen in package.json

### Naming Convention

Used hyphens for multi-word recipes (Just doesn't support colons):
- `test-watch`, `test-e2e`, `test-e2e-ui`
- `docker-up`, `docker-down`, `docker-logs`
- `db-generate`, `db-migrate`, `db-push`, `db-studio`

### Recipe Categories

1. **Development:** `dev`, `build`
2. **Testing:** `test`, `test-watch`, `test-coverage`, `test-e2e`, `test-e2e-ui`
3. **Code Quality:** `lint`, `format`, `typecheck`, `check`
4. **Docker:** `docker-up`, `docker-down`, `docker-logs`
5. **Database:** `db-generate`, `db-migrate`, `db-push`, `db-studio`
6. **Setup:** `install`, `setup`

## Files Changed

- `justfile` - New file with all recipes
- `README.md` - Updated to document Just commands
