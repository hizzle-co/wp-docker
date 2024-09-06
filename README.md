# WordPress Docker with Automated Backups and Restoration

This Docker setup provides a WordPress installation with automated backup and restoration capabilities. It uses Cloudflare R2 for storing backups and includes scripts for easy backup and restoration of both files and database.

## Features

- Automated WordPress installation
- Automatic backup of files and database
- Automatic restoration from latest backup for new installations
- Cloudflare R2 integration for backup storage
- Cron jobs for scheduled backups

## Environment Variables

The following environment variables are required:

### WordPress Configuration
- `WORDPRESS_URL`: The URL of your WordPress site (e.g., `https://example.com`)
- `WORDPRESS_TITLE`: The title of your WordPress site
- `WORDPRESS_ADMIN_USER`: Admin username
- `WORDPRESS_ADMIN_PASSWORD`: Admin password
- `WORDPRESS_ADMIN_EMAIL`: Admin email address
- `WORDPRESS_DB_HOST`: Database host
- `WORDPRESS_DB_NAME`: Database name
- `WORDPRESS_DB_USER`: Database user
- `WORDPRESS_DB_PASSWORD`: Database password

### Cloudflare R2 Configuration
- `R2_BUCKET`: Your Cloudflare R2 bucket name
- `R2_ACCESS_KEY_ID`: R2 access key ID
- `R2_SECRET_ACCESS_KEY`: R2 secret access key
- `R2_ENDPOINT`: R2 endpoint URL

## Usage

1. Clone this repository
2. Set the required environment variables
3. Build and run the Docker container


## Backup and Restore

Backups are automatically created according to the cron schedule. To manually trigger a backup or restore:

- Backup files: `docker exec -it container_name /usr/local/bin/file-backup.sh`
- Backup database: `docker exec -it container_name /usr/local/bin/db-backup.sh`
- Restore files: `docker exec -it container_name /usr/local/bin/restore-files.sh`
- Restore database: `docker exec -it container_name /usr/local/bin/restore-db.sh`

For silent operation (auto-selecting the latest backup), add the `--silent` flag to the restore commands.

## Customization

You can modify the cron schedule by editing the `cron.job` file in the Docker context directory.

## Security Note

Ensure that your environment variables, especially passwords and API keys, are kept secure and not exposed in public repositories.