# Use the official WordPress image as the base
FROM wordpress:latest

# Enable Apache headers module
RUN a2enmod headers

# Install the Redis PHP extension
RUN pecl install redis && docker-php-ext-enable redis

# Install cron and nano
RUN apt-get update && apt-get install -y cron nano && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup db-backup script
COPY db-backup.sh /usr/local/bin/db-backup.sh
RUN chmod +x /usr/local/bin/db-backup.sh

# Setup file-backup script
COPY file-backup.sh /usr/local/bin/file-backup.sh
RUN chmod +x /usr/local/bin/file-backup.sh

# Setup restore-db script
COPY restore-db.sh /usr/local/bin/restore-db.sh
RUN chmod +x /usr/local/bin/restore-db.sh

# Setup restore-files script
COPY restore-files.sh /usr/local/bin/restore-files.sh
RUN chmod +x /usr/local/bin/restore-files.sh

# Copy the cron job file to the cron.d directory
COPY cron.job /etc/cron.d/cron.job

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/cron.job

# Apply the cron job
RUN crontab /etc/cron.d/cron.job

# Start the cron daemon
CMD ["cron", "-f"]

# Run backup script at startup
CMD ["/usr/local/bin/backup.sh"]
