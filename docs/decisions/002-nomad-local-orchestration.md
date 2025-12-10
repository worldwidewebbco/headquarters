# ADR 002: Nomad for Local Development Orchestration

**Date:** 2025-12-09
**Status:** Accepted

## Context

The project needed a way to orchestrate multiple services locally (PostgreSQL, API, Web, Worker). The standard approach would be docker-compose, but we wanted to evaluate options that could scale to production.

## Decision

Use HashiCorp Nomad as the local development orchestrator instead of docker-compose.

### Key Implementation Choices

1. **raw_exec driver for Node.js apps** - Runs processes directly on the host for instant hot reload without Docker image rebuilds. PostgreSQL uses the Docker driver since it doesn't need hot reload.

2. **Nomad native service discovery** - Uses `provider = "nomad"` instead of requiring Consul. Simpler setup for local dev.

3. **Nomad dev mode** - Runs as `nomad agent -dev` for zero-config local development.

## Alternatives Considered

### docker-compose
- **Pros:** Industry standard, simple YAML config, well-documented
- **Cons:** No path to production, hot reload requires volume mounts and image rebuilds

### Kubernetes (minikube/kind)
- **Pros:** Production-ready, widely adopted
- **Cons:** Heavy resource usage, complex for local dev, steep learning curve

### Nomad (chosen)
- **Pros:** Lightweight, same config for local/prod, flexible drivers, simple operations
- **Cons:** Less common than K8s, smaller ecosystem

## Consequences

### Positive
- Same orchestration tool for local dev and production
- Fast iteration with raw_exec hot reload
- Lightweight - single binary, runs in dev mode
- Simple job files (HCL) that are easy to understand
- Web UI at http://localhost:4646 for visibility

### Negative
- Team members need to install Nomad
- Less familiar than docker-compose for some developers
- Fewer community resources compared to Kubernetes

## References

- [Nomad Documentation](https://developer.hashicorp.com/nomad/docs)
- [Design Document](../plans/2025-12-09-nomad-setup-design.md)
- [GitHub Issue #4](https://github.com/worldwidewebbco/headquarters/issues/4)
