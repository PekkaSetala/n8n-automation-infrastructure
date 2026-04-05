# Deployment Guide

This guide walks through deploying the entire self-hosted AI workflow automation platform from scratch.

## Prerequisites

### Required Accounts
- **Hetzner Cloud Account** - [hetzner.com](https://www.hetzner.com/)
- **Domain Name** - Any registrar (Namecheap, Google Domains, etc.)
- **Cloudflare Account** - Free tier sufficient

### Required Knowledge
- Basic Linux command line
- SSH access and key management
- DNS record configuration
- Docker concepts (helpful but not required)

### Local Requirements
- SSH client installed
- Text editor for config files

## Step 1: Provision Hetzner Cloud Server

### 1.1 Create Server

1. Log into Hetzner Cloud Console
2. Click "Add Server"
3. Select location (e.g., Nuremberg, Germany)
4. Choose image: **Ubuntu 24.04**
5. Select server type: **CX22** (4GB RAM, 2 vCPU) - minimum recommended
6. Add your SSH key
7. Enable backups (optional but recommended)
8. Set server name (e.g., "ai-automation")
9. Click "Create & Buy Now"

**Cost:** ~€5.83/month for CX22

### 1.2 Initial Server Access
```bash
# SSH into your new server
ssh root@YOUR_SERVER_IP

# Update system packages
apt update && apt upgrade -y

# Set timezone (optional)
timedatectl set-timezone Europe/Helsinki
```

### 1.3 Configure Firewall (Optional but Recommended)
```bash
# Install UFW
apt install ufw -y

# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp

# Enable firewall
ufw enable
```

## Step 2: Install Coolify

Coolify is a self-hosted PaaS that simplifies Docker application management.

### 2.1 One-Line Installation
```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

**Installation Time:** 3-5 minutes

The installer will:
- Install Docker and Docker Compose
- Pull Coolify containers
- Set up PostgreSQL and Redis
- Configure Traefik proxy
- Start all services

### 2.2 Access Coolify

1. Navigate to `http://YOUR_SERVER_IP:8000`
2. Create admin account (email + password)
3. Complete initial setup wizard

### 2.3 Configure Server Settings

In Coolify dashboard:
1. Go to "Servers" → "localhost"
2. Verify server is connected and healthy
3. Note: Traefik is automatically configured

## Step 3: Configure Cloudflare DNS

### 3.1 Add Domain to Cloudflare

1. Log into Cloudflare
2. Click "Add a Site"
3. Enter your domain name
4. Select Free plan
5. Copy nameservers provided

### 3.2 Update Domain Nameservers

At your domain registrar:
1. Find DNS/Nameserver settings
2. Replace existing nameservers with Cloudflare's
3. Save changes (propagation takes 24-48 hours, usually faster)

### 3.3 Create DNS Records

In Cloudflare DNS settings, add these A records:

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | n8n | YOUR_SERVER_IP | Proxied (orange) | Auto |
| A | app | YOUR_SERVER_IP | Proxied (orange) | Auto |

**Note:** "Proxied" enables Cloudflare's CDN and DDoS protection.

### 3.4 Configure SSL/TLS Settings

In Cloudflare:
1. Go to SSL/TLS → Overview
2. Set mode to **"Full (strict)"** (recommended) or **"Full"**
3. Enable "Always Use HTTPS"
4. Enable "Automatic HTTPS Rewrites"

## Step 4: Deploy n8n Workflow Automation

### 4.1 Create n8n Service in Coolify

1. In Coolify, click "Projects" → "New Project"
2. Name: "AI Automation"
3. Click the project, then "+ New Resource"
4. Select "Service" → "n8n"
5. Configure:
   - **Name:** n8n-production
   - **Environment:** production
   - **Domain:** n8n.example.com

### 4.2 Configure n8n Settings

In the service configuration:

**Domains:**
- Add: `n8n.example.com`
- Enable: "Generate SSL certificate"

**Environment Variables:**
```
GENERIC_TIMEZONE=Europe/Helsinki
N8N_EDITOR_BASE_URL=https://n8n.example.com
WEBHOOK_URL=https://n8n.example.com
```

**Database:**
- PostgreSQL is automatically included
- Database name: `n8n`
- Username and password are auto-generated

### 4.3 Deploy n8n

1. Click "Deploy"
2. Wait for health checks to pass (~2 minutes)
3. Access n8n at `https://n8n.example.com`
4. Create admin account on first visit

### 4.4 Verify n8n Deployment
```bash
# SSH into server
ssh root@YOUR_SERVER_IP

# Check n8n container
docker ps | grep n8n

# Check logs
docker logs n8n-{ID} --tail 50

# Verify database connection
docker exec -it postgresql-{ID} psql -U n8n -d n8n -c "SELECT NOW();"
```

## Step 5: Configure Coolify Dashboard Domain

### 6.1 Set Custom Domain for Coolify

1. Go to Coolify "Settings" → "Configuration"
2. Set "Instance's domain" to: `app.example.com`
3. Save changes
4. Coolify will automatically configure Traefik

### 6.2 Update Traefik Configuration

The configuration is in `/data/coolify/proxy/dynamic/coolify.yaml`:
```yaml
http:
  routers:
    coolify-http:
      middlewares:
        - gzip
      entryPoints:
        - http
      service: coolify
      rule: Host(`app.example.com`)
```

Traefik automatically reloads configuration.

## Step 6: Verify Complete Deployment

### 6.1 Test All Services

| Service | URL | Expected Result |
|---------|-----|-----------------|
| n8n | https://n8n.example.com | n8n login page |
| Coolify | https://app.example.com:8000 | Coolify dashboard |

### 6.2 Verify SSL Certificates
```bash
# Check n8n certificate
curl -vI https://n8n.example.com 2>&1 | grep -i "subject:"
```

All should show Let's Encrypt certificates.

### 7.3 Check Container Health
```bash
# View all running containers
docker ps

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# View resource usage
docker stats --no-stream
```

## Step 7: Secure Your Setup

### 8.1 Enable Automatic Updates
```bash
# Install unattended upgrades
apt install unattended-upgrades -y

# Configure automatic security updates
dpkg-reconfigure -plow unattended-upgrades
```

### 8.2 Set Up Monitoring (Optional)

In Coolify:
1. Enable health checks for all services
2. Configure email notifications for failures
3. Set up uptime monitoring (UptimeRobot, etc.)

### 8.3 Create Backup Strategy
```bash
# Create backup script
cat > /root/backup.sh << 'BACKUP'
#!/bin/bash
BACKUP_DIR="/root/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup Coolify data
tar -czf $BACKUP_DIR/coolify-data.tar.gz /data/coolify/

# Backup Docker volumes
docker run --rm -v agsg4okcw8gccsk0sgwcggg4_n8n-data:/data \
  -v $BACKUP_DIR:/backup alpine tar -czf /backup/n8n-data.tar.gz /data

# Backup databases
docker exec postgresql-{ID} pg_dump -U n8n n8n > $BACKUP_DIR/n8n-db.sql

echo "Backup completed: $BACKUP_DIR"
BACKUP

chmod +x /root/backup.sh
```

Schedule with cron:
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /root/backup.sh
```

## Troubleshooting

### Service Won't Start
```bash
# Check Docker logs
docker logs {container_name}

# Check container status
docker inspect {container_name}

# Restart service via Coolify UI or:
docker restart {container_name}
```

### SSL Certificate Issues
```bash
# Check Traefik logs
docker logs coolify-proxy

# Verify Let's Encrypt rate limits haven't been hit
# Check acme.json
cat /data/coolify/proxy/acme.json | jq .
```

### DNS Not Resolving
```bash
# Check DNS propagation
dig n8n.example.com +short

# Verify Cloudflare proxy
dig n8n.example.com

# Should return Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Can't Access Coolify Dashboard
```bash
# Check if Coolify is running
docker ps | grep coolify

# Restart Coolify
cd /data/coolify/source
docker compose restart

# Check port 8000 is accessible
ss -tulpn | grep 8000
```

## Next Steps

### Enhance n8n Setup
- Create your first workflow
- Set up webhook endpoints
- Configure credentials for external services
- Explore workflow templates

### Production Hardening
- Set up regular backups to external storage
- Configure monitoring and alerting
- Implement log aggregation
- Create disaster recovery procedures
- Document your workflows and configurations

## Estimated Costs

| Item | Cost (Monthly) |
|------|----------------|
| Hetzner CX22 Server | €5.83 |
| Domain Name | €1-2 |
| Cloudflare | Free |
| **Total** | **~€7-8/month** |

## Deployment Checklist

- [ ] Hetzner server provisioned
- [ ] Coolify installed and accessible
- [ ] Cloudflare DNS configured
- [ ] n8n deployed and accessible
- [ ] All SSL certificates working
- [ ] Firewall rules configured
- [ ] Backup script created and scheduled
- [ ] Monitoring configured
- [ ] Documentation updated with your specific details

---

**Deployment Time:** 1-2 hours for complete setup

**Difficulty:** Intermediate

