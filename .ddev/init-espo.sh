#!/bin/bash
set -e

# EspoCRM Initialization Script
# Automatically provisions config files from templates and handles first-run setup.

INSTALL_FLAG=".ddev/.espo-initialized"
ADMIN_USER="admin"
ADMIN_PASS="toor"

echo "🚀 Starting EspoCRM Initialization..."

# 0. Ensure Directory Structure
# Essential for a fresh clone where empty dirs might be missing despite .gitkeep
mkdir -p data/cache data/logs data/upload data/preferences data/.backup data/tmp custom/Espo/Custom

# 1. Auto-Provision Configuration Files
# If config files are missing (e.g., fresh clone), create them from templates.

if [ ! -f "data/config.php" ]; then
    if [ -f "data/config.php.dist" ]; then
        echo "📝 Creating data/config.php from template..."
        cp data/config.php.dist data/config.php
    else 
        echo "⚠️  Template data/config.php.dist not found. Creating minimal default."
        echo "<?php return ['useCache' => true];" > data/config.php
    fi
     # Mark that we need a setup/rebuild because we just created a config
    NEED_SETUP=true
fi

if [ ! -f "data/config-internal.php" ]; then
    if [ -f "data/config-internal.php.dist" ]; then
        echo "📝 Creating data/config-internal.php from template..."
        cp data/config-internal.php.dist data/config-internal.php
    else
        echo "⚠️  Template data/config-internal.php.dist not found. Creating default internal config."
        cat > "data/config-internal.php" << 'EOFCONFIG'
<?php
return [
  'isInstalled' => true,
  'database' => [
    'driver' => 'pdo_mysql',
    'host' => 'db',
    'port' => '3306',
    'dbname' => 'db',
    'user' => 'db',
    'password' => 'db',
  ],
];
EOFCONFIG
    fi
    NEED_SETUP=true
fi

# 2. Set Permissions (Vital for DDEV/Docker)
# We do this EARLY to prevent permission errors during cache clearing or rebuild
echo "🔐 Verifying permissions..."
chmod 664 data/config.php data/config-internal.php 2>/dev/null || true
find data/ custom/ client/custom/ -type d -exec chmod 775 {} \; 2>/dev/null || true
find data/ custom/ client/custom/ -type f -exec chmod 664 {} \; 2>/dev/null || true

# 3. Check Database Connection
echo "⏳ Waiting for database..."
while ! mysqladmin ping -h db --silent; do
    sleep 1
done

# 4. Import Data if Empty
DB_EXISTS=$(mysql -h db -u db -pdb -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='db';" 2>/dev/null | tail -n1)

if [ "$DB_EXISTS" = "0" ] || [ -z "$DB_EXISTS" ]; then
    echo "💾 Database is empty. Importing initial data..."
    
    if [ -f ".ddev/init-db.sql.gz" ]; then
        zcat .ddev/init-db.sql.gz | mysql -h db -u db -pdb db
        echo "✓ Initial data imported."
        NEED_SETUP=true
    elif [ -f ".ddev/init-db.sql" ]; then
        mysql -h db -u db -pdb db < .ddev/init-db.sql
        echo "✓ Initial data imported."
        NEED_SETUP=true
    else
        echo "⚠️  No initial database dump found. Skipping import."
    fi
fi

# 5. Handling Setup / Rebuild
# Check flag file to see if we've already initialized this specific environment
if [ ! -f "$INSTALL_FLAG" ]; then
    NEED_SETUP=true
fi

if [ "$NEED_SETUP" = "true" ]; then
    echo "⚙️  Running setup tasks..."

    # ALWAYS clear cache before rebuild to avoid stale cache errors
    echo "🧹 Clearing cache..."
    rm -rf data/cache/*
    touch data/cache/.gitkeep # Keep git properties happy

    echo "🔨 Rebuilding EspoCRM..."
    # Capture output to check for errors, but also display it
    php rebuild.php

    # Create admin user if not exists
    echo "👤 Ensuring admin user exists..."
    php bin/command create-admin-user "$ADMIN_USER" 2>/dev/null || true
    echo "$ADMIN_PASS" | php bin/command set-password "$ADMIN_USER"

    # Ensure CSV Lead Import scheduled job exists
    echo "📅 Ensuring scheduled jobs exist..."
    SCHEDULED_JOB_EXISTS=$(mysql -h db -u db -pdb db -N -e "SELECT COUNT(*) FROM scheduled_job WHERE job = 'ImportLeadsFromCsv' AND deleted = 0;" 2>/dev/null || echo "0")
    if [ "$SCHEDULED_JOB_EXISTS" = "0" ]; then
        echo "   Creating 'Import Leads from CSV' scheduled job..."
        mysql -h db -u db -pdb db -e "INSERT INTO scheduled_job (id, name, job, status, scheduling, created_at, modified_at, deleted) VALUES (CONCAT('csv_import_', UNIX_TIMESTAMP()), 'Import Leads from CSV', 'ImportLeadsFromCsv', 'Active', '*/5 * * * *', NOW(), NOW(), 0);" 2>/dev/null || true
    fi
    
    # Mark initialization as done
    touch "$INSTALL_FLAG"
else
    echo "✓ System already initialized. Skipping rebuild."
fi

echo "✅ Initialization complete!"
