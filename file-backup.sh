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
BACKUP_FILE="/tmp/wordpress_files_$TIMESTAMP.tar.gz"

# Backup WordPress files
echo "Backing up WordPress files..."
if tar -czf "$BACKUP_FILE" -C /var/www/html .; then
    echo "Files backup successful."
else
    echo "ERROR: Files backup failed" >&2
    exit 1
fi

# Function to upload file to R2 and manage retention
upload_to_r2() {
    local file=$1
    
    echo "Uploading files backup to Cloudflare R2..."
    if AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 cp "$file" "s3://$R2_BUCKET/files/" --endpoint-url "$R2_ENDPOINT"; then
        echo "Upload Successful!"
        
        # List files, sort by date, and keep only the newest 5
        echo "Managing retention for files backups..."
        old_backups=$(AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/files/" --endpoint-url "$R2_ENDPOINT" | sort -r | tail -n +6 | awk '{print $4}')
        
        for old_backup in $old_backups; do
            echo "Removing old backup: $old_backup"
            AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 rm "s3://$R2_BUCKET/files/$old_backup" --endpoint-url "$R2_ENDPOINT"
        done
    else
        echo "ERROR: Upload of files backup failed" >&2
        exit 1
    fi
}

# Upload files backup
upload_to_r2 "$BACKUP_FILE"

# Clean up temp files
echo "Cleaning up..."
rm "$BACKUP_FILE"
echo "Files backup completed successfully!"