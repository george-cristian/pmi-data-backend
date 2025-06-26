#!/bin/bash

# PMI Reports Migration Script
set -e

# Load environment variables from .env if present
if [[ -f .env ]]; then
  source .env
fi

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-pmi_reports}"
DB_USER="${DB_USER:-pmi_user}"
DB_PASSWORD="${DB_PASSWORD:-}"  # Add default password
MIGRATIONS_DIR="./migrations"

# Set password for psql
export PGPASSWORD="$DB_PASSWORD"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test database connection
test_connection() {
    log_info "Testing database connection..."
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_info "Database connection successful"
        return 0
    else
        log_error "Database connection failed"
        return 1
    fi
}

# Get current schema version
get_current_version() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
        "SELECT COALESCE(MAX(version), 0) FROM schema_migrations;" 2>/dev/null | tr -d ' '
}

# Apply a single migration
apply_migration() {
    local migration_file="$1"
    local filename=$(basename "$migration_file")
    
    # Extract version number (001_name.sql -> 1)
    local version=$(echo "$filename" | grep -o '^[0-9]*' | sed 's/^0*//')
    
    if [[ -z "$version" ]]; then
        log_error "Could not extract version from filename: $filename"
        return 1
    fi
    
    log_info "Applying migration $version: $filename"
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file"; then
        log_info "✅ Migration $version applied successfully"
        return 0
    else
        log_error "❌ Migration $version failed"
        return 1
    fi
}

# Main migration function
migrate() {
    if ! test_connection; then
        exit 1
    fi
    
    local current_version=$(get_current_version)
    log_info "Current schema version: $current_version"
    
    # Find all migration files
    local migration_files=($(find "$MIGRATIONS_DIR" -name "*.sql" | sort))
    
    if [[ ${#migration_files[@]} -eq 0 ]]; then
        log_warn "No migration files found in $MIGRATIONS_DIR"
        return 0
    fi
    
    local applied_count=0
    
    for migration_file in "${migration_files[@]}"; do
        local filename=$(basename "$migration_file")
        local version=$(echo "$filename" | grep -o '^[0-9]*' | sed 's/^0*//')
        
        if [[ -z "$version" ]]; then
            log_warn "Skipping file with invalid format: $filename"
            continue
        fi
        
        if [[ $version -gt $current_version ]]; then
            if apply_migration "$migration_file"; then
                applied_count=$((applied_count + 1))
            else
                log_error "Migration failed, stopping"
                exit 1
            fi
        fi
    done
    
    if [[ $applied_count -eq 0 ]]; then
        log_info "No new migrations to apply"
    else
        log_info "🎉 Applied $applied_count migration(s) successfully!"
    fi
}

# Show migration status
status() {
    if ! test_connection; then
        exit 1
    fi
    
    local current_version=$(get_current_version)
    echo "Current schema version: $current_version"
    echo ""
    echo "Applied migrations:"
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
        "SELECT version, description, applied_at FROM schema_migrations ORDER BY version;"
}

# Create a new migration file
create() {
    local description="$1"
    if [[ -z "$description" ]]; then
        log_error "Migration description is required"
        echo "Usage: $0 create \"description\""
        exit 1
    fi
    
    # Get next version number
    local current_version=$(get_current_version 2>/dev/null || echo "0")
    local next_version=$((current_version + 1))
    local padded_version=$(printf "%03d" "$next_version")
    
    # Create filename
    local safe_description=$(echo "$description" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]//g')
    local filename="${padded_version}_${safe_description}.sql"
    local filepath="$MIGRATIONS_DIR/$filename"
    
    # Create migrations directory if it doesn't exist
    mkdir -p "$MIGRATIONS_DIR"
    
    # Create migration file with template
    cat > "$filepath" << EOF
-- Migration: $description
-- Version: $next_version
-- Created: $(date '+%Y-%m-%d %H:%M:%S')

DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $next_version) THEN
        
        -- Add your migration SQL here
        -- Example:
        -- ALTER TABLE pmi_reports ADD COLUMN new_field VARCHAR(100);
        -- CREATE INDEX idx_new_field ON pmi_reports(new_field);
        
        -- Record this migration
        INSERT INTO schema_migrations (version, applied_at, description)
        VALUES ($next_version, NOW(), '$description');
        
    END IF;
END \$\$;
EOF
    
    log_info "Created migration: $filepath"
    log_info "Edit the file to add your migration SQL"
}

# Rollback last migration (careful!)
rollback() {
    log_warn "⚠️  Rollback functionality not implemented"
    log_warn "Manual rollback required - create a new migration to undo changes"
}

# Main script logic
case "${1:-help}" in
    migrate)
        migrate
        ;;
    status)
        status
        ;;
    create)
        create "$2"
        ;;
    rollback)
        rollback
        ;;
    *)
        echo "Usage: $0 {migrate|status|create|rollback}"
        echo ""
        echo "Commands:"
        echo "  migrate                 - Apply pending migrations"
        echo "  status                  - Show current migration status"
        echo "  create \"description\"    - Create a new migration file"
        echo "  rollback                - Rollback last migration (not implemented)"
        echo ""
        echo "Environment variables:"
        echo "  DB_HOST                 - Database host (default: localhost)"
        echo "  DB_PORT                 - Database port (default: 5432)"
        echo "  DB_NAME                 - Database name (default: pmi_reports)"
        echo "  DB_USER                 - Database user (default: pmi_user)"
        echo "  DB_PASSWORD             - Database password (default: akL@54bnOvf)"
        exit 1
        ;;
esac
