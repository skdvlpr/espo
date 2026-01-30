#!/bin/bash

# EspoCRM Initialization Script for Team Development

CONFIG_FILE="data/config-internal.php"
INSTALL_FLAG=".ddev/.espo-initialized"
# Default admin credentials
ADMIN_USER="admin"
ADMIN_PASS="toor"

echo "🚀 Starting EspoCRM Initialization..."

# Check if we need to run first-time setup
NEED_SETUP=false

# 1. Create DB Config
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 Creating database configuration..."
    cat > "$CONFIG_FILE" << 'EOFCONFIG'
<?php
return [
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
    chmod 644 "$CONFIG_FILE"
    NEED_SETUP=true
fi

# 2. Check Database & Import
# Wait for DB to be ready
echo "⏳ Waiting for database..."
while ! mysqladmin ping -h db --silent; do
    sleep 1
done

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
else 
    echo "✓ Database already contains data ($DB_EXISTS tables). Skipping import."
fi

# Check if previously initialized (flag file)
if [ ! -f "$INSTALL_FLAG" ]; then
    NEED_SETUP=true
fi

# 3. Operations requiring Rebuild (Only if Setup needed)
if [ "$NEED_SETUP" = "true" ]; then
    echo "⚙️  Running setup tasks..."

    echo "🧹 Clearing cache..."
    rm -rf data/cache/*

    echo "🔨 Rebuilding EspoCRM..."
    php rebuild.php

    # 4. Create Admin User
    if [ $? -eq 0 ]; then
        echo "👤 Ensuring admin user exists..."
        # Try to create user, ignore error if exists
        php bin/command create-admin-user "$ADMIN_USER" 2>/dev/null || true
        # Force password set
        echo "$ADMIN_PASS" | php bin/command set-password "$ADMIN_USER"
        echo "✓ Admin credentials ensured."
    fi
    
    # Create the flag file
    touch "$INSTALL_FLAG"
else
    echo "✓ System already initialized. Skipping rebuild."
fi

# 5. Set Permissions (Always run this to be safe)
echo "🔐 Verifying permissions..."
chown -R www-data:www-data data/ custom/ client/custom/
find data/ custom/ client/custom/ -type d -exec chmod 775 {} \;
find data/ custom/ client/custom/ -type f -exec chmod 664 {} \;

echo "✅ Initialization check complete!"
