# Self-Hosted AI Workflow Automation Platform

A production-grade, self-hosted infrastructure for AI workflow automation and experimentation, deployed on Hetzner Cloud with Cloudflare integration.

## 🎯 Overview

This repository documents a complete self-hosted platform built for AI automation workflows, featuring:

- **Coolify** - Self-hosted PaaS (Platform as a Service) for easy application deployment
- **n8n** - Powerful workflow automation engine for AI agents and API integrations
- **Open WebUI** - AI experimentation interface for LLM interactions
- **Traefik** - Modern reverse proxy with automatic SSL/TLS management
- **PostgreSQL** - Persistent data storage for workflows and configurations
- **Cloudflare** - DNS management and DDoS protection

## 🏗️ Architecture
```
                                   Internet
                                      |
                                 Cloudflare
                              (DNS + Proxy)
                                      |
                                      v
                            ┌─────────────────┐
                            │  Hetzner Cloud  │
                            │   Ubuntu 24.04  │
                            │   4GB RAM       │
                            └─────────────────┘
                                      |
                        ┌─────────────┴─────────────┐
                        │      Traefik Proxy        │
                        │  (Port 80/443)            │
                        │  - Let's Encrypt SSL      │
                        │  - HTTP/2, HTTP/3         │
                        └─────────────┬─────────────┘
                                      |
                ┌─────────────────────┼─────────────────────┐
                |                     |                     |
         ┌──────▼──────┐      ┌──────▼──────┐     ┌───────▼──────┐
         │   Coolify   │      │     n8n     │     │  Open WebUI  │
         │  (Control)  │      │ (Workflows) │     │ (AI Chat)    │
         └─────────────┘      └──────┬──────┘     └──────────────┘
                                     |
                              ┌──────▼──────┐
                              │ PostgreSQL  │
                              │  (Database) │
                              └─────────────┘
```

## 🚀 Key Features

### Infrastructure Management
- **Containerized Architecture**: All services run in isolated Docker containers
- **Automated SSL/TLS**: Let's Encrypt certificates managed by Traefik
- **Zero-Downtime Deployments**: Rolling updates with health checks
- **Persistent Storage**: Docker volumes for data persistence

### Security & Networking
- **Reverse Proxy**: Traefik routing with automatic HTTPS redirect
- **DDoS Protection**: Cloudflare proxy layer
- **Internal Networks**: Isolated Docker networks per service
- **Health Monitoring**: Container health checks for all services

### Services Deployed

#### n8n - Workflow Automation
- **Purpose**: AI agent orchestration and API workflow automation
- **Database**: Dedicated PostgreSQL instance
- **Use Cases**: 
  - AI agent workflows
  - API integrations and data processing
  - Automated data pipelines
  - Webhook handling and transformations

#### Open WebUI
- **Purpose**: AI experimentation and LLM interaction interface
- **Features**: Self-hosted ChatGPT-like interface
- **Use Cases**: Testing AI models, prompt engineering, AI experiments

#### Coolify
- **Purpose**: Self-hosted PaaS for application management
- **Features**:
  - Git-based deployments
  - One-click service templates
  - Environment variable management
  - Automatic SSL provisioning

## 🔧 Example Workflows

Built and running on this infrastructure:

### [AI Motorcycle Visual Identifier](docs/workflows/motorcycle-identifier.md)
Webhook-triggered image analysis pipeline: Image upload → OpenAI Vision → Recommendation engine → Email delivery

**Skills**: Multi-API orchestration, binary data processing, webhook handling, AI integration

### [Selkokielelle - Plain Language Converter](docs/workflows/selkokielelle-converter.md)
Finnish text simplification workflow: Form submission → GPT-4 transformation → Side-by-side email

**Skills**: Form integration, compliance automation, prompt engineering, accessibility standards

**Why this matters**: These workflows demonstrate real-world integration patterns (webhook → processing → notification) common in enterprise environments, using iPaaS platforms like n8n that translate directly to Zapier, Make, Frends, and MuleSoft.

## 📊 Technical Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Cloud Provider** | Hetzner Cloud | Cost-effective VPS hosting |
| **OS** | Ubuntu 24.04 LTS | Stable Linux distribution |
| **Containerization** | Docker & Docker Compose | Application isolation |
| **Reverse Proxy** | Traefik v3.6 | Traffic routing & SSL |
| **PaaS** | Coolify 4.0 | Application management |
| **Automation** | n8n | Workflow engine |
| **Database** | PostgreSQL 16 | Persistent storage |
| **AI Interface** | Open WebUI | LLM experimentation |
| **DNS/CDN** | Cloudflare | DNS & DDoS protection |

## 📁 Repository Structure
```
.
├── README.md                          # This file
├── docs/
│   ├── architecture.md                # Detailed architecture documentation
│   ├── deployment-guide.md            # Step-by-step deployment instructions
│   ├── services.md                    # Individual service configurations
│   ├── cloudflare-integration.md      # DNS and proxy setup
│   └── workflows/                     # Example workflow documentation
│       ├── motorcycle-identifier.md   # AI image analysis workflow
│       └── selkokielelle-converter.md # Text simplification workflow
├── configs/
│   ├── coolify/                       # Coolify configuration examples
│   ├── traefik/                       # Traefik proxy configs
│   ├── n8n/                           # n8n docker-compose examples
│   └── docker-compose/                # Service composition files
├── diagrams/
│   └── architecture.png               # Visual architecture diagram
└── scripts/
    └── backup-procedures.sh           # Backup and restore scripts
```

## 🛠️ Quick Start

See [deployment-guide.md](docs/deployment-guide.md) for complete setup instructions.

### Prerequisites
- Hetzner Cloud account
- Domain name
- Cloudflare account (free tier works)
- SSH access to server

### High-Level Steps
1. Provision Hetzner Cloud VPS (4GB RAM minimum)
2. Install Coolify via one-line installer
3. Configure Cloudflare DNS
4. Deploy n8n with PostgreSQL
5. Deploy Open WebUI
6. Configure Traefik for SSL

## 💡 Skills Demonstrated

### DevOps & Infrastructure
- Linux server administration (Ubuntu)
- Docker containerization and orchestration
- Reverse proxy configuration (Traefik)
- SSL/TLS certificate management
- Network security and isolation

### Cloud & Deployment
- Cloud infrastructure provisioning (Hetzner)
- Self-hosted PaaS management (Coolify)
- CDN and DNS configuration (Cloudflare)
- Service monitoring and health checks

### Automation & Development
- Workflow automation (n8n)
- Docker Compose service orchestration
- Environment variable management
- Database administration (PostgreSQL)

## 📈 System Specifications

**Hetzner Cloud Server:**
- **CPU**: Intel Xeon (Skylake)
- **RAM**: 4GB
- **Storage**: 40GB SSD
- **OS**: Ubuntu 24.04 LTS
- **Location**: EU datacenter

**Resource Usage:**
- Docker containers: 8 running services
- Memory utilization: ~1.7GB / 4GB
- Storage: 18GB / 38GB used

## 🔐 Security Considerations

- All HTTP traffic automatically redirects to HTTPS
- Let's Encrypt SSL certificates with auto-renewal
- Cloudflare proxy masks origin server IP
- Docker network isolation between services
- Regular security updates via Ubuntu LTS
- No exposed database ports (internal networking only)

## 📝 License

This documentation is provided as-is for educational and portfolio purposes.

## 👤 Author

**Pekka Setälä**
- GitHub: [@PekkaSetala](https://github.com/PekkaSetala)
- Location: Helsinki, Finland

---

*This infrastructure showcases modern DevOps practices, containerization, and self-hosted solutions for AI workflow automation.*
