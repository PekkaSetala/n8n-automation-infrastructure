# Services Documentation

Detailed configuration and management information for each service in the platform.

## Table of Contents
- [Coolify](#coolify)
- [n8n](#n8n)
- [Traefik](#traefik)
- [PostgreSQL](#postgresql)

---

## Coolify

### Overview
Coolify is a self-hosted Platform-as-a-Service (PaaS) that simplifies Docker application deployment and management. It provides a user-friendly interface for deploying services, managing environments, and handling SSL certificates.

### Container Stack
```
coolify          - Main application (Laravel/PHP)
coolify-db       - PostgreSQL 15 database
coolify-redis    - Redis 7 cache
coolify-realtime - Soketi WebSocket server
```

### Network Configuration
- **Network:** `coolify` (bridge)
- **Port Mapping:** 8000:8080 (HTTP)
- **Internal Ports:**
  - 6001 - Soketi WebSocket
  - 6002 - Terminal WebSocket

### Key Features
- **Git Integration:** Deploy from GitHub, GitLab, Bitbucket
- **Service Templates:** One-click deployments for popular services
- **Environment Management:** Secure variable storage with encryption
- **SSL Automation:** Automatic Let's Encrypt certificate provisioning
- **Real-time Updates:** WebSocket-based live updates
- **Docker Management:** Full Docker Compose support

### Access
- **URL:** `https://app.example.com:8000`
- **Authentication:** Email + Password (set during installation)
- **API:** Available for programmatic access

### Configuration Files
```
/data/coolify/
├── source/
│   ├── docker-compose.yml
│   └── docker-compose.prod.yml
├── proxy/
│   ├── docker-compose.yml
│   └── dynamic/
│       ├── coolify.yaml
│       └── default_redirect_503.yaml
└── services/
    └── {service-id}/
        └── docker-compose.yml
```

### Management Commands
```bash
# View Coolify logs
docker logs coolify -f

# Restart Coolify
cd /data/coolify/source
docker compose restart

# Update Coolify
docker compose pull
docker compose up -d

# Check Coolify database
docker exec -it coolify-db psql -U postgres -d coolify

# Backup Coolify data
tar -czf coolify-backup.tar.gz /data/coolify/
```

### Environment Variables
Stored in: `/data/coolify/source/.env`

Key variables:
- `APP_URL` - Coolify instance URL
- `DB_*` - Database connection details
- `REDIS_*` - Redis connection details

---

## n8n

### Overview
n8n is a fair-code licensed workflow automation tool that enables you to connect APIs, databases, and services to build automation workflows.

### Container Stack
```
n8n-{id}        - n8n workflow engine
postgresql-{id} - PostgreSQL 16 database
```

### Network Configuration
- **Network:** `agsg4okcw8gccsk0sgwcggg4` (isolated bridge)
- **Internal Port:** 5678
- **External Access:** Via Traefik (HTTPS only)

### Key Features
- **Visual Workflow Builder:** Drag-and-drop interface
- **400+ Integrations:** Pre-built nodes for popular services
- **Custom Code:** JavaScript/Python code execution
- **Webhook Support:** HTTP endpoints for external triggers
- **Database Backend:** PostgreSQL for workflow persistence
- **Cron Scheduling:** Time-based workflow triggers
- **Error Handling:** Retry logic and error workflows

### Access
- **URL:** `https://n8n.example.com`
- **Authentication:** Built-in user management
- **API:** REST API for workflow management

### Environment Variables
```bash
# Core settings
N8N_EDITOR_BASE_URL=https://n8n.example.com
WEBHOOK_URL=https://n8n.example.com
N8N_HOST=https://n8n.example.com

# Timezone
GENERIC_TIMEZONE=Europe/Helsinki
TZ=Europe/Helsinki

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_HOST=postgresql
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER={auto-generated}
DB_POSTGRESDB_PASSWORD={auto-generated}
DB_POSTGRESDB_SCHEMA=public
```

### Storage
- **Workflow Data:** `/home/node/.n8n` (Docker volume)
- **Database:** PostgreSQL volume
- **Credentials:** Encrypted in database

### Docker Compose Example
```yaml
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    environment:
      N8N_EDITOR_BASE_URL: 'https://n8n.example.com'
      WEBHOOK_URL: 'https://n8n.example.com'
      DB_TYPE: postgresdb
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_HOST: postgresql
      DB_POSTGRESDB_PORT: 5432
    volumes:
      - n8n-data:/home/node/.n8n
    depends_on:
      postgresql:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:5678/"]
      interval: 5s
      timeout: 20s
      retries: 10
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(`n8n.example.com`)
      - traefik.http.routers.n8n.tls.certresolver=letsencrypt
      - traefik.http.services.n8n.loadbalancer.server.port=5678

  postgresql:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: {secure-password}
      POSTGRES_DB: n8n
    volumes:
      - postgresql-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n -d n8n"]
      interval: 5s
      timeout: 20s
      retries: 10
```

### Management Commands
```bash
# View n8n logs
docker logs n8n-{id} -f

# Restart n8n
docker restart n8n-{id}

# Access n8n CLI
docker exec -it n8n-{id} n8n --help

# Export all workflows
docker exec n8n-{id} n8n export:workflow --all --output=/tmp/workflows.json

# Database backup
docker exec postgresql-{id} pg_dump -U n8n n8n > n8n-backup.sql

# Database restore
cat n8n-backup.sql | docker exec -i postgresql-{id} psql -U n8n -d n8n
```

### Common Use Cases

**AI Agent Workflows:**
- Webhook → Process data → Call AI API → Store results
- Scheduled data collection → AI analysis → Send notifications
- Form submission → AI validation → Database insert

**API Integrations:**
- Sync data between multiple services
- Transform and enrich data from APIs
- Build custom API endpoints with webhooks

**Data Processing:**
- ETL pipelines for data transformation
- Automated report generation
- Data quality checks and validation

---

## Traefik

### Overview
Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It automatically discovers services and manages SSL certificates.

### Container Configuration
```
coolify-proxy - Traefik v3.6
```

### Port Configuration
```
80/tcp   - HTTP (redirects to HTTPS)
443/tcp  - HTTPS
443/udp  - HTTP/3 (QUIC)
8080/tcp - Traefik dashboard (internal only)
```

### Key Features
- **Service Discovery:** Automatic via Docker labels
- **SSL/TLS:** Let's Encrypt automatic certificate management
- **HTTP/2 & HTTP/3:** Modern protocol support
- **Middleware:** Compression, redirects, auth
- **Load Balancing:** Multiple backend support
- **Dynamic Configuration:** Hot reload without restart

### Configuration Structure
```
/data/coolify/proxy/
├── docker-compose.yml       # Main configuration
├── acme.json               # Let's Encrypt certificates
├── traefik.log             # Access logs
└── dynamic/                # Dynamic configurations
    ├── coolify.yaml        # Coolify routing
    └── default_redirect_503.yaml
```

### Command Line Flags
```yaml
--api.dashboard=true
--entrypoints.http.address=:80
--entrypoints.https.address=:443
--entrypoints.https.http3
--providers.docker=true
--providers.docker.exposedbydefault=false
--providers.file.directory=/traefik/dynamic/
--certificatesresolvers.letsencrypt.acme.httpchallenge=true
--certificatesresolvers.letsencrypt.acme.storage=/traefik/acme.json
```

### Label-Based Configuration

Services expose themselves to Traefik via Docker labels:
```yaml
labels:
  - traefik.enable=true
  
  # HTTP router (redirects to HTTPS)
  - traefik.http.routers.myapp-http.entryPoints=http
  - traefik.http.routers.myapp-http.rule=Host(`app.example.com`)
  - traefik.http.routers.myapp-http.middlewares=redirect-to-https
  
  # HTTPS router
  - traefik.http.routers.myapp-https.entryPoints=https
  - traefik.http.routers.myapp-https.rule=Host(`app.example.com`)
  - traefik.http.routers.myapp-https.tls.certresolver=letsencrypt
  - traefik.http.routers.myapp-https.middlewares=gzip
  
  # Service definition
  - traefik.http.services.myapp.loadbalancer.server.port=8080
```

### Management Commands
```bash
# View Traefik logs
docker logs coolify-proxy -f

# Check certificate status
docker exec coolify-proxy cat /traefik/acme.json | jq .

# Reload dynamic configuration
docker exec coolify-proxy kill -USR1 1

# View current routes
docker exec coolify-proxy wget -qO- http://localhost:8080/api/http/routers | jq .
```

### Troubleshooting

**Certificate Issues:**
```bash
# Check ACME logs
docker logs coolify-proxy | grep acme

# Verify certificate
openssl s_client -connect n8n.example.com:443 -servername n8n.example.com

# Manual certificate renewal (if needed)
# Remove domain from acme.json and restart Traefik
```

**Routing Issues:**
```bash
# Check if service is discovered
docker inspect {container} | grep traefik

# Verify network connectivity
docker network inspect coolify
```

---

## PostgreSQL

### Overview
PostgreSQL provides persistent database storage for n8n workflows and Coolify configuration.

### Instances

**Coolify Database:**
- Container: `coolify-db`
- Image: `postgres:15-alpine`
- Purpose: Coolify application data

**n8n Database:**
- Container: `postgresql-{id}`
- Image: `postgres:16-alpine`
- Purpose: n8n workflow storage

### Configuration
```yaml
environment:
  POSTGRES_USER: {username}
  POSTGRES_PASSWORD: {secure-password}
  POSTGRES_DB: {database-name}
  
volumes:
  - postgres-data:/var/lib/postgresql/data
  
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
  interval: 5s
  timeout: 20s
  retries: 10
```

### Management Commands
```bash
# Access PostgreSQL CLI
docker exec -it postgresql-{id} psql -U {username} -d {database}

# Create backup
docker exec postgresql-{id} pg_dump -U {username} {database} > backup.sql

# Restore backup
cat backup.sql | docker exec -i postgresql-{id} psql -U {username} -d {database}

# Check database size
docker exec postgresql-{id} psql -U {username} -d {database} \
  -c "SELECT pg_size_pretty(pg_database_size('{database}'));"

# List tables
docker exec postgresql-{id} psql -U {username} -d {database} -c "\dt"

# Vacuum database (optimize)
docker exec postgresql-{id} psql -U {username} -d {database} -c "VACUUM ANALYZE;"
```

### Backup Strategy

**Automated Backups:**
```bash
#!/bin/bash
# /root/backup-postgres.sh

BACKUP_DIR="/root/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup n8n database
docker exec postgresql-{id} pg_dump -U n8n n8n | gzip > \
  $BACKUP_DIR/n8n-$DATE.sql.gz

# Backup Coolify database
docker exec coolify-db pg_dump -U postgres coolify | gzip > \
  $BACKUP_DIR/coolify-$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

### Performance Tuning

For production workloads, consider adjusting PostgreSQL settings:
```yaml
environment:
  # Increase shared buffers
  POSTGRES_SHARED_BUFFERS: 256MB
  
  # Increase work memory
  POSTGRES_WORK_MEM: 16MB
  
  # Connection pooling
  POSTGRES_MAX_CONNECTIONS: 100
```

---

## Service Health Monitoring

All services implement health checks for automatic recovery:
```bash
# Check health status of all containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# Monitor health in real-time
watch -n 5 'docker ps --format "table {{.Names}}\t{{.Status}}"'

# View health check logs for specific service
docker inspect {container-name} | jq '.[0].State.Health'
```

