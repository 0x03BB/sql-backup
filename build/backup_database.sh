#!/bin/bash
DATE=$(date -I)
TIME=$(date -Iseconds)
# Replace ':' with '-' for use in file name.
TIME=${TIME//:/-}
FILE_NAME=${DATE}/database${TIME}.bak

# Check for -f flag to force backup.
while getopts f option; do
	case "${option}" in
		f)
			FORCE=1;;
	esac
done

# Backup the database if it hasn't been done for the day or if -f is provided.
if ! compgen -G "${LOCAL_BACKUP_DIR}${DATE}/database*.bak" > /dev/null || [[ ${FORCE} ]]; then
	{ # Redirect output to init so it shows up in the docker log.
		echo
		echo "$(date -Iseconds): Starting database backup to ${FILE_NAME}"
		sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "BACKUP DATABASE ${DB_NAME} TO DISK='${REMOTE_BACKUP_DIR}${FILE_NAME}' WITH CHECKSUM, STATS=25"
		
		# Confirm file exists.
		if [[ -f ${LOCAL_BACKUP_DIR}${FILE_NAME} ]]; then
			# Copy backup to backup service.
			echo
			echo "$(date -Iseconds): Copying database backup to backup service"
			rclone -v copy ${LOCAL_BACKUP_DIR}${FILE_NAME} drive:/${DATE}/
		fi
	} >/proc/1/fd/1 2>/proc/1/fd/2
fi
