# Use the official WordPress image as the base
FROM wordpress:latest

# Install dependencies and wp-cli
RUN apt-get update && apt-get install -y \
    cron \
    nano \
    less \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && a2enmod headers \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
COPY cron.job /etc/cron.d/wordpress-cron

# Give execution rights on the cron job and create the log file
RUN chmod 0644 /etc/cron.d/wordpress-cron \
    && touch /var/log/cron.log

# Apply the cron job
RUN crontab /etc/cron.d/wordpress-cron

# Start the cron daemon
CMD ["cron", "-f"]

# Maybe restore backup
RUN /usr/local/bin/restore-db.sh
RUN /usr/local/bin/restore-files.sh

# Copy and set entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]
