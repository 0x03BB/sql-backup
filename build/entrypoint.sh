#!/bin/bash
# Setup the cron environment.
declare -p | grep -E 'PATH|LOCAL_BACKUP_DIR|REMOTE_BACKUP_DIR|DB_ADDRESS|SA_PASSWORD|DB_NAME' > /root/cron.env

# Add the root folder id to the rclone configuration
echo "root_folder_id = ${ROOT_FOLDER_ID}" >> /root/.config/rclone/rclone.conf

# Run the initial database backup, if needed.
/root/backup_database.sh

# Run cron in the foreground
exec cron -f -l 2
