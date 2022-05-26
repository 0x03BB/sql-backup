#!/bin/bash

# Wait for SQL Server to be available. Exit after 5 failed connection attempts.
i=0
until sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "SELECT 1" -b -o /dev/null
do
	((i++ >= 4)) && echo "Entrypoint: Failed to connect to SQL Server after 5 attempts. Exiting." > /proc/1/fd/2 && exit 1
    echo "Entrypoint: Failed to connect to SQL Server. Retrying... (${i})" > /proc/1/fd/2
done
echo "Entrypoint: SQL Server connection successful." > /proc/1/fd/1

# Setup the cron environment.
declare -p | grep -E 'PATH|LOCAL_BACKUP_DIR|REMOTE_BACKUP_DIR|DB_ADDRESS|SA_PASSWORD|DB_NAME' > /root/cron.env

# Add the root folder id to the rclone configuration.
echo "root_folder_id = ${ROOT_FOLDER_ID}" >> /root/.config/rclone/rclone.conf

# Run the initial database backup, if needed.
/root/backup_database.sh

# Run cron in the foreground.
echo "Entrypoint: Starting cron." > /proc/1/fd/1
exec cron -f -l 2
