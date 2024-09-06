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

# Function to get the latest backup file
get_latest_backup() {
    AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/files/" --endpoint-url "$R2_ENDPOINT" | sort -r | head -n 1 | awk '{print $4}'
}

# Check if running in silent mode
if [ "$1" = "--silent" ]; then
    BACKUP_FILE=$(get_latest_backup)
    if [ -z "$BACKUP_FILE" ]; then
        echo "ERROR: No backup files found." >&2
        exit 1
    fi
else
    # List available backups
    echo "Available file backups:"
    AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/files/" --endpoint-url "$R2_ENDPOINT" | sort -r
    
    # Prompt user to select a backup
    read -p "Enter the filename of the backup you want to restore (or press Enter for the latest): " BACKUP_FILE
    
    # If no input, use the latest backup
    if [ -z "$BACKUP_FILE" ]; then
        BACKUP_FILE=$(get_latest_backup)
    fi
fi

# Download the selected backup
TEMP_FILE="/tmp/wordpress_files_restore.tar.gz"
echo "Downloading backup: $BACKUP_FILE"
if AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 cp "s3://$R2_BUCKET/files/$BACKUP_FILE" "$TEMP_FILE" --endpoint-url "$R2_ENDPOINT"; then
    echo "Download successful."
else
    echo "ERROR: Failed to download the backup file." >&2
    exit 1
fi

# Restore files
echo "Restoring WordPress files..."
if tar -xzf "$TEMP_FILE" -C /var/www/html; then
    echo "Files restored successfully."
else
    echo "ERROR: Failed to restore files." >&2
    exit 1
fi

# Clean up
echo "Cleaning up..."
rm "$TEMP_FILE"

echo "File restoration completed successfully!"