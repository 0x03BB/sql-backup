#!/bin/bash
DATE=$(date -I)
TIME=$(date -Iseconds)
# Replace ':' with '-' for use in file name.
TIME=${TIME//:/-}
FILE_NAME=${DATE}/log${TIME}.bak

{ # Redirect output to init so it shows up in the docker log.
	# Backup the log.
	echo
	echo "$(date -Iseconds): Starting log backup to ${FILE_NAME}"
	sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "BACKUP LOG ${DB_NAME} TO DISK='${REMOTE_BACKUP_DIR}${FILE_NAME}' WITH CHECKSUM, STATS=50"
	
	# Confirm file exists.
	if [[ -f ${LOCAL_BACKUP_DIR}${FILE_NAME} ]]; then
		# Copy backup to backup service.
		echo
		echo "$(date -Iseconds): Copying log backup to backup service"
		rclone -v copy ${LOCAL_BACKUP_DIR}${FILE_NAME} drive:/${DATE}/
	fi
} >/proc/1/fd/1 2>/proc/1/fd/2
