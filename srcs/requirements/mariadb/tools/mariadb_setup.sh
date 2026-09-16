#!/bin/bash
# =============================================================
# MariaDB initialization script
#
# Flow:
# 1. Create required directories with correct permissions
# 2. Initialize the data directory on first run
# 3. Start MariaDB temporarily (background) to run SQL setup
# 4. Create the database and user, set root password
# 5. Shut down the temporary process
# 6. Restart MariaDB in the foreground (required by Docker)
# =============================================================
set -e

echo "[MariaDB] Starting initialization..."

# Create data and log directories if they don't exist
mkdir -p /var/lib/mysql /var/log/mysql
chown -R mysql:mysql /var/lib/mysql /var/log/mysql

# Initialize the data directory only on the very first run
# On subsequent starts (data persisted via volume), this is skipped
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[MariaDB] First run: initializing data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Start MariaDB in the background temporarily so we can run SQL commands
# --skip-networking: only accepts local socket connections during setup
mysqld_safe --skip-networking &
MYSQL_PID=$!

# Wait until MariaDB is ready to accept connections (up to 30 seconds)
echo "[MariaDB] Waiting for MariaDB to be ready..."
for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        echo "[MariaDB] Ready!"
        break
    fi
    sleep 1
done

# Run SQL commands to set up the database, user and root password
# Variables come from the .env file via docker-compose env_file
echo "[MariaDB] Creating database and user..."
mysql -u root << SQLEOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQLEOF

echo "[MariaDB] Database and user created successfully."

# Shut down the temporary background process cleanly
mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown 2>/dev/null || true
wait $MYSQL_PID 2>/dev/null || true

echo "[MariaDB] Starting MariaDB in foreground (production mode)..."
# exec replaces this script with mysqld as PID 1 of the container
# This is required: Docker needs PID 1 to stay alive
# No & and no daemon mode allowed
exec mysqld
