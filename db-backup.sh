#!/bin/bash

# Check for required environment variables
required_vars=(
    "R2_BUCKET"
    "R2_ACCESS_KEY_ID"
    "R2_SECRET_ACCESS_KEY"
    "R2_ENDPOINT"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Environment variable $var is not set."
        exit 1
    fi
done

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="/tmp/wordpress_db_$TIMESTAMP.sql.gz"

# Backup WordPress database
echo "Backing up WordPress database..."
if wp db export - --path=/var/www/html | gzip > "$BACKUP_FILE"; then
    echo "Database backup successful."
else
    echo "ERROR: Database backup failed" >&2
    exit 1
fi

# Function to upload file to R2 and manage retention
upload_to_r2() {
    local file=$1
    
    echo "Uploading database backup to Cloudflare R2..."
    if AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 cp "$file" "s3://$R2_BUCKET/database/" --endpoint-url "$R2_ENDPOINT"; then
        echo "Upload Successful!"
        
        # List files, sort by date, and keep only the newest 5
        echo "Managing retention for database backups..."
        old_backups=$(AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/database/" --endpoint-url "$R2_ENDPOINT" | sort -r | tail -n +6 | awk '{print $4}')
        
        for old_backup in $old_backups; do
            echo "Removing old backup: $old_backup"
            AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 rm "s3://$R2_BUCKET/database/$old_backup" --endpoint-url "$R2_ENDPOINT"
        done
    else
        echo "ERROR: Upload of database backup failed" >&2
        exit 1
    fi
}

# Upload database backup
upload_to_r2 "$BACKUP_FILE"

# Clean up temp files
echo "Cleaning up..."
rm "$BACKUP_FILE"
echo "Database backup completed successfully!"