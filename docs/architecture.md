# Architecture Documentation

## System Overview

This infrastructure implements a microservices architecture using Docker containers, managed through Coolify (a self-hosted PaaS), with Traefik as the edge proxy handling SSL/TLS termination and traffic routing.

## Network Architecture

### External Layer

**Cloudflare (DNS + Proxy)**
- Handles DNS resolution for all subdomains
- Provides DDoS protection and CDN capabilities
- Proxies traffic to Hetzner server (orange cloud enabled)
- Manages DNS records:
  - `n8n.example.com` → Hetzner server IP
  - `app.example.com` → Hetzner server IP (Coolify dashboard)

### Edge Layer

**Traefik v3.6 (Reverse Proxy)**
- Container: `coolify-proxy`
- Ports exposed:
  - `80/tcp` - HTTP (redirects to HTTPS)
  - `443/tcp` - HTTPS
  - `443/udp` - HTTP/3 (QUIC)
  - `8080/tcp` - Traefik dashboard (internal)

**Features:**
- Automatic service discovery via Docker labels
- Let's Encrypt ACME HTTP challenge for SSL certificates
- HTTP/2 and HTTP/3 support
- Gzip compression middleware
- Automatic HTTPS redirect
- Certificate storage in `/data/coolify/proxy/acme.json`

### Application Layer

#### 1. Coolify (Platform Management)

**Container Stack:**
- `coolify` - Main application (PHP/Laravel)
- `coolify-db` - PostgreSQL 15
- `coolify-redis` - Redis 7
- `coolify-realtime` - Soketi (WebSocket server)

**Network:** `coolify` (internal bridge network)

**Functionality:**
- Git-based deployments
- Service templating and management
- Environment variable encryption
- Automatic SSL provisioning via Traefik
- Real-time updates via WebSockets

**Access:** `app.example.com:8000` (mapped to port 8080 internally)

#### 2. n8n (Workflow Automation)

**Container Stack:**
- `n8n-agsg4okcw8gccsk0sgwcggg4` - n8n application
- `postgresql-agsg4okcw8gccsk0sgwcggg4` - PostgreSQL 16

**Network:** `agsg4okcw8gccsk0sgwcggg4` (isolated bridge network)

**Configuration:**
- Internal port: 5678
- External access: `n8n.example.com` (via Traefik)
- Database: PostgreSQL with persistent volume
- Timezone: Europe/Berlin
- Persistent data: `/home/node/.n8n` (Docker volume)

**Traefik Integration:**
- Automatic SSL via Let's Encrypt
- Gzip compression enabled
- HTTP → HTTPS redirect
- Health checks on port 5678

**Use Cases:**
- AI agent workflow orchestration
- API integration and data transformation
- Webhook receivers and processors
- Scheduled automation tasks

## Data Persistence

### Docker Volumes

All persistent data is stored in named Docker volumes:
```
agsg4okcw8gccsk0sgwcggg4_n8n-data              # n8n workflow data
agsg4okcw8gccsk0sgwcggg4_postgresql-data       # n8n database
coolify-db                                      # Coolify database
coolify-redis                                   # Coolify cache
```

**Location:** `/var/lib/docker/volumes/`

**Backup Strategy:**
- Volumes can be backed up using `docker run --rm` with volume mounts
- Database dumps recommended for PostgreSQL containers
- Coolify provides built-in backup functionality

## Service Discovery & Routing

### Traefik Label-Based Routing

Each service uses Docker labels for automatic configuration:

**Example (n8n):**
```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.https-0-xxx-n8n.rule=Host(`n8n.example.com`)
  - traefik.http.routers.https-0-xxx-n8n.entryPoints=https
  - traefik.http.routers.https-0-xxx-n8n.tls.certresolver=letsencrypt
  - traefik.http.services.https-0-xxx-n8n.loadbalancer.server.port=5678
```

### Network Isolation

**External Network:** `coolify`
- Shared by Coolify core services
- Traefik proxy connects here

**Isolated Networks:**
- Each application gets its own bridge network
- Services within the same stack can communicate
- External access only via Traefik

## SSL/TLS Management

### Let's Encrypt Integration

**ACME Challenge:** HTTP-01
- Certificates requested automatically by Traefik
- Renewal handled 30 days before expiration
- Storage: `/data/coolify/proxy/acme.json`

**Supported Domains:**
- `n8n.example.com`
- `app.example.com`

**Configuration:**
```yaml
--certificatesresolvers.letsencrypt.acme.httpchallenge=true
--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=http
--certificatesresolvers.letsencrypt.acme.storage=/traefik/acme.json
```

## Health Checks

All services implement health checks for reliability:

**n8n:**
```yaml
healthcheck:
  test: wget -qO- http://127.0.0.1:5678/
  interval: 5s
  timeout: 20s
  retries: 10
```

**PostgreSQL:**
```yaml
healthcheck:
  test: pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
  interval: 5s
  timeout: 20s
  retries: 10
```

## Resource Allocation

**Total System:**
- RAM: 4GB (1.7GB used)
- Storage: 40GB (18GB used)
- CPU: Intel Xeon (shared)

**Container Resource Usage:**
- Coolify stack: ~600MB
- n8n + PostgreSQL: ~400MB
- Traefik: ~100MB

## Security Architecture

### Network Security
- All containers on isolated bridge networks
- No direct database access from internet
- Only Traefik exposed to public internet

### Application Security
- All traffic encrypted via SSL/TLS
- Automatic HTTP → HTTPS redirect
- Cloudflare DDoS protection
- Docker socket mounted read-only where possible

### Access Control
- Coolify dashboard requires authentication
- n8n requires authentication
- Traefik dashboard not publicly exposed

## Deployment Workflow

1. **Service Definition:** Create docker-compose.yml via Coolify UI
2. **Network Creation:** Coolify creates isolated network
3. **Container Launch:** Docker Compose brings up services
4. **Label Application:** Traefik-compatible labels added
5. **Service Discovery:** Traefik detects new service
6. **SSL Provisioning:** Let's Encrypt certificate requested
7. **Route Activation:** Service becomes accessible via HTTPS

## Monitoring & Observability

**Container Status:**
- Health checks provide automatic restart on failure
- Docker logs accessible via Coolify UI
- Traefik access logs available

**System Metrics:**
- `docker stats` for real-time resource usage
- `df -h` for disk utilization
- `free -h` for memory usage

## Scalability Considerations

**Current Setup:**
- Single-server architecture
- Suitable for personal/small team use
- ~1000-5000 requests/day capacity

**Future Scaling Options:**
- Add dedicated database server
- Implement load balancing
- Use Docker Swarm or Kubernetes
- Add monitoring (Prometheus/Grafana)
- Implement centralized logging (ELK stack)

## Disaster Recovery

**Backup Targets:**
- Docker volumes (n8n data, databases)
- Coolify configuration (`/data/coolify/`)
- SSL certificates (`/data/coolify/proxy/acme.json`)
- Docker Compose files

**Recovery Process:**
1. Provision new Hetzner server
2. Install Docker and Coolify
3. Restore `/data/coolify/` directory
4. Restore Docker volumes
5. Update Cloudflare DNS to new IP
6. Restart services

**RTO (Recovery Time Objective):** ~30 minutes
**RPO (Recovery Point Objective):** Daily backups recommended

