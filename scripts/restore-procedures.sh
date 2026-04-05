#!/bin/bash

#####################################################
# Restore Script for Self-Hosted Infrastructure
# Author: Infrastructure Automation
# Purpose: Restore from backup
#####################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backup directory provided
if [ -z "$1" ]; then
    error "Usage: $0 /path/to/backup/directory"
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
    error "Backup directory not found: $BACKUP_DIR"
fi

log "Starting restore from: $BACKUP_DIR"

# Verify checksums
if [ -f "$BACKUP_DIR/checksums.sha256" ]; then
    log "Verifying backup integrity..."
    cd "$BACKUP_DIR"
    sha256sum -c checksums.sha256 || error "Checksum verification failed!"
    log "✓ Backup integrity verified"
fi

# Confirmation
echo ""
warn "This will restore data and may overwrite existing data!"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled"
    exit 0
fi

#####################################################
# 1. Stop Services
#####################################################
log "Stopping services..."

docker compose -f /data/coolify/source/docker-compose.yml down || true
docker stop $(docker ps -aq) 2>/dev/null || true

log "✓ Services stopped"

#####################################################
# 2. Restore Coolify Data
#####################################################
log "Restoring Coolify configuration..."

if [ -f "$BACKUP_DIR/coolify-data.tar.gz" ]; then
    tar -xzf "$BACKUP_DIR/coolify-data.tar.gz" -C /
    log "✓ Coolify configuration restored"
fi

#####################################################
# 3. Restore SSL Certificates
#####################################################
log "Restoring SSL certificates..."

if [ -f "$BACKUP_DIR/acme.json" ]; then
    mkdir -p /data/coolify/proxy
    cp "$BACKUP_DIR/acme.json" /data/coolify/proxy/
    chmod 600 /data/coolify/proxy/acme.json
    log "✓ SSL certificates restored"
fi

#####################################################
# 4. Start Coolify
#####################################################
log "Starting Coolify..."

cd /data/coolify/source
docker compose up -d

# Wait for Coolify to be ready
log "Waiting for Coolify to start..."
sleep 30

log "✓ Coolify started"

#####################################################
# 5. Restore Databases
#####################################################
log "Restoring databases..."

# Coolify database
if [ -f "$BACKUP_DIR/coolify-db.sql.gz" ]; then
    gunzip -c "$BACKUP_DIR/coolify-db.sql.gz" | \
        docker exec -i coolify-db psql -U postgres coolify
    log "✓ Coolify database restored"
fi

# n8n database
if [ -f "$BACKUP_DIR/n8n-db.sql.gz" ]; then
    POSTGRES_CONTAINER=$(docker ps --filter "name=postgresql-" --format "{{.Names}}" | head -1)
    if [ -n "$POSTGRES_CONTAINER" ]; then
        gunzip -c "$BACKUP_DIR/n8n-db.sql.gz" | \
            docker exec -i $POSTGRES_CONTAINER psql -U n8n n8n
        log "✓ n8n database restored"
    fi
fi

#####################################################
# 6. Restore Docker Volumes
#####################################################
log "Restoring Docker volumes..."

# n8n data
if [ -f "$BACKUP_DIR/n8n-data.tar.gz" ]; then
    # Find volume name from backup
    # This assumes volume exists; if not, create it first
    docker run --rm \
        -v n8n-data:/data \
        -v "$BACKUP_DIR:/backup" \
        alpine sh -c "cd / && tar -xzf /backup/n8n-data.tar.gz"
    log "✓ n8n data restored"
fi

#####################################################
# 7. Restart All Services
#####################################################
log "Restarting all services..."

# This will restart services managed by Coolify
docker restart $(docker ps -aq) 2>/dev/null || true

log "✓ All services restarted"

#####################################################
# Summary
#####################################################
log "================================================"
log "Restore completed!"
log "================================================"
log ""
log "Next steps:"
log "1. Verify services are running: docker ps"
log "2. Check service logs for errors"
log "3. Test access to all services"
log "4. Update DNS if server IP changed"
log ""

exit 0
