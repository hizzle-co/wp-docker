#!/bin/bash
set -e

# Function to check if WordPress is installed
wp_is_installed() {
    wp core is-installed --path=/var/www/html --allow-root
}

# Function to check if the database is empty (only default tables)
db_is_empty() {
    local table_count=$(wp db query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${WORDPRESS_DB_NAME}'" --path=/var/www/html --allow-root --quiet --skip-column-names)
    [ "$table_count" -le 12 ]  # WordPress typically creates 12 tables by default
}

# Function to restore latest database backup
restore_latest_db() {
    /usr/local/bin/restore-db.sh --silent
}

# Function to restore latest files backup
restore_latest_files() {
    /usr/local/bin/restore-files.sh --silent
}

# Check if WordPress files are missing
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress files not found. Restoring from the latest backup..."
    restore_latest_files
fi

# Initialize WordPress if not already done
wp core is-installed --path=/var/www/html --allow-root || wp core install --path=/var/www/html --url="${WORDPRESS_URL}" --title="${WORDPRESS_TITLE}" --admin_user="${WORDPRESS_ADMIN_USER}" --admin_password="${WORDPRESS_ADMIN_PASSWORD}" --admin_email="${WORDPRESS_ADMIN_EMAIL}" --skip-email --allow-root

# Check if the database is empty and restore if necessary
if db_is_empty; then
    echo "Database appears to be empty. Restoring from the latest backup..."
    restore_latest_db
fi

# Start cron
cron

# Execute the main CMD
exec "$@"