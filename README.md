# Hetzner Infrastructure

Production infrastructure for self-hosted AI services. Runs a multi-service stack on a single Hetzner VPS behind Cloudflare, managed through Coolify with Traefik handling TLS termination and routing.

Built this to run AI workflow automation and an LLM interface without depending on third-party platforms. Ran it as my production environment — the design reflects that: network-isolated services, automated certificate management, health checks with auto-restart, and a tested backup/restore procedure.

## Architecture

```
Internet → Cloudflare (DNS, proxy, DDoS protection)
               └── Traefik v3.6 (reverse proxy, Let's Encrypt, HTTP/3)
                       ├── Coolify 4.0    (PaaS — deployment, env management)
                       ├── n8n            (workflow automation, webhook endpoints)
                       └── Open WebUI     (multi-provider LLM interface)
                               └── PostgreSQL 16 + Redis 7
```

Each service runs in its own Docker bridge network. Databases are internal-only — no exposed ports. Traefik discovers services via Docker labels and provisions TLS certificates automatically.

## Stack

| Layer | Component | Purpose |
|-------|-----------|---------|
| Edge | Cloudflare | DNS, DDoS mitigation, origin IP masking |
| Proxy | Traefik v3.6 | Reverse proxy, automatic TLS (Let's Encrypt), HTTP/2 + HTTP/3 |
| Platform | Coolify 4.0 | Container orchestration, git-based deployments, secret management |
| Automation | n8n | Workflow engine — webhooks, multi-API orchestration, scheduling |
| AI | Open WebUI | LLM interface (OpenAI, Anthropic, Ollama) |
| Data | PostgreSQL 16, Redis 7 | Persistence and caching, per-service isolation |

**Host:** Hetzner VPS — Ubuntu 24.04 LTS, 4 GB RAM, 8 containers running at ~1.7 GB utilization. ~€7/month.

## Production Workflows

Two n8n workflows that ran in production, demonstrating multi-API orchestration, prompt engineering, and data transformation pipelines:

**[AI Motorcycle Identifier](docs/workflows/motorcycle-identifier.md)** — Webhook receives an image, passes it through OpenAI Vision for identification, enriches with market data via SerpAPI, and delivers a formatted analysis by email. Five APIs chained: webhook → GPT-4o Vision → OpenRouter → SerpAPI → Gmail.

**[Selkokielelle](docs/workflows/selkokielelle-converter.md)** — Finnish plain language converter. Form submission triggers a GPT-4 pipeline that rewrites complex Finnish into accessible selkokieli following 15+ guidelines from Finnish accessibility standards. Outputs a side-by-side comparison. Relevant to EU Accessibility Directive compliance.

## Security

- TLS everywhere — HTTP → HTTPS redirect enforced at Traefik
- Let's Encrypt certificates, auto-renewed
- Cloudflare proxy masks origin IP
- Network isolation — each service stack on its own Docker bridge
- No database ports exposed to the internet
- UFW firewall, Docker socket mounted read-only where possible
- Health checks on all containers with automatic restart

## Operations

- Automated backup/restore scripts for all Docker volumes and databases
- Health checks with configurable intervals and retry policies
- 30-minute RTO with documented recovery procedure
- Real-time resource monitoring via `docker stats` and Coolify UI

## Documentation

- [Getting Started](GETTING-STARTED.md) — Prerequisites and setup
- [Architecture](docs/architecture.md) — Network topology, service discovery, data persistence
- [Deployment Guide](docs/deployment-guide.md) — Step-by-step provisioning
- [Services](docs/services.md) — Per-service configuration and management
- [Cloudflare Integration](docs/cloudflare-integration.md) — DNS and proxy setup

## License

MIT
