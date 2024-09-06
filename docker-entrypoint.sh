#!/bin/bash
set -e

# Start cron
cron

# Execute the main CMD
exec "$@"