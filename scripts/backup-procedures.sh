#!/bin/bash

#####################################################
# Backup Script for Self-Hosted Infrastructure
# Author: Infrastructure Automation
# Purpose: Complete backup of all services and data
#####################################################

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"
RETENTION_DAYS=7

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"
log "Backup directory created: $BACKUP_DIR"

#####################################################
# 1. Backup Coolify Configuration
#####################################################
log "Backing up Coolify configuration..."

if [ -d "/data/coolify" ]; then
    tar -czf "$BACKUP_DIR/coolify-data.tar.gz" \
        --exclude='/data/coolify/source/node_modules' \
        --exclude='/data/coolify/source/vendor' \
        /data/coolify/
    log "✓ Coolify configuration backed up"
else
    warn "Coolify directory not found, skipping"
fi

#####################################################
# 2. Backup Coolify Database
#####################################################
log "Backing up Coolify database..."

if docker ps | grep -q coolify-db; then
    docker exec coolify-db pg_dump -U postgres coolify | \
        gzip > "$BACKUP_DIR/coolify-db.sql.gz"
    log "✓ Coolify database backed up"
else
    warn "Coolify database container not running, skipping"
fi

#####################################################
# 3. Backup n8n Data
#####################################################
log "Backing up n8n data and database..."

# Find n8n container (ID varies)
N8N_CONTAINER=$(docker ps --filter "name=n8n-" --format "{{.Names}}" | grep -v postgres | head -1)
POSTGRES_CONTAINER=$(docker ps --filter "name=postgresql-" --format "{{.Names}}" | head -1)

if [ -n "$N8N_CONTAINER" ]; then
    # Backup n8n data volume
    VOLUME_NAME=$(docker inspect $N8N_CONTAINER | \
        jq -r '.[0].Mounts[] | select(.Destination=="/home/node/.n8n") | .Name')
    
    if [ -n "$VOLUME_NAME" ]; then
        docker run --rm \
            -v "$VOLUME_NAME:/data" \
            -v "$BACKUP_DIR:/backup" \
            alpine tar -czf "/backup/n8n-data.tar.gz" /data
        log "✓ n8n data volume backed up"
    fi
    
    # Backup n8n database
    if [ -n "$POSTGRES_CONTAINER" ]; then
        docker exec $POSTGRES_CONTAINER pg_dump -U n8n n8n | \
            gzip > "$BACKUP_DIR/n8n-db.sql.gz"
        log "✓ n8n database backed up"
    fi
else
    warn "n8n container not found, skipping"
fi

#####################################################
# 4. Backup SSL Certificates
#####################################################
log "Backing up SSL certificates..."

if [ -f "/data/coolify/proxy/acme.json" ]; then
    cp "/data/coolify/proxy/acme.json" "$BACKUP_DIR/acme.json"
    log "✓ SSL certificates backed up"
else
    warn "acme.json not found, skipping"
fi

#####################################################
# 5. Backup Docker Volumes List
#####################################################
log "Creating Docker volumes inventory..."

docker volume ls > "$BACKUP_DIR/docker-volumes.txt"
log "✓ Docker volumes list saved"

#####################################################
# 6. Backup Running Containers Info
#####################################################
log "Saving running containers information..."

docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" \
    > "$BACKUP_DIR/docker-containers.txt"
log "✓ Container information saved"

#####################################################
# 7. Create Backup Manifest
#####################################################
log "Creating backup manifest..."

cat > "$BACKUP_DIR/MANIFEST.txt" << MANIFEST
Backup Information
==================
Date: $DATE
Hostname: $(hostname)
Server IP: $(hostname -I | awk '{print $1}')

Backup Contents:
- Coolify configuration and data
- Coolify PostgreSQL database
- n8n workflow data and database
- SSL certificates (acme.json)
- Docker volumes inventory
- Container information

Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)

To restore this backup:
1. Install Coolify on new server
2. Stop all services
3. Extract backups to appropriate locations
4. Restore databases
5. Start services
6. Update DNS records

IMPORTANT: Store this backup securely!
MANIFEST

log "✓ Manifest created"

#####################################################
# 8. Calculate Checksums
#####################################################
log "Calculating checksums..."

cd "$BACKUP_DIR"
sha256sum *.tar.gz *.sql.gz *.json 2>/dev/null > checksums.sha256 || true
log "✓ Checksums calculated"

#####################################################
# 9. Clean Old Backups
#####################################################
log "Cleaning old backups (older than $RETENTION_DAYS days)..."

find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;
log "✓ Old backups cleaned"

#####################################################
# Summary
#####################################################
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log "================================================"
log "Backup completed successfully!"
log "Location: $BACKUP_DIR"
log "Size: $BACKUP_SIZE"
log "================================================"

# Optional: Send notification (uncomment if you have a notification webhook)
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"✅ Backup completed: $BACKUP_SIZE\"}" \
#   YOUR_WEBHOOK_URL

exit 0
