#!/bin/bash

source /root/shared.sh

FILE_NAME=${DATE}/database-${TIME}.bak

# Check for -f flag to force backup.
while getopts f option; do
	case "${option}" in
		f)
			FORCE=1;;
		*)
			;;
	esac
done

# Backup the database if it hasn't been done for the day or if -f is provided.
if [[ ! -f ${LOCAL_BACKUP_DIR}${ZIP_NAME} || ${FORCE} ]]; then
	{ # Redirect output to init so it shows up in the docker log.
		echo
		echo "$(date -Iseconds): Starting database backup to ${FILE_NAME}"
		sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "BACKUP DATABASE ${DB_NAME} TO DISK='${REMOTE_BACKUP_DIR}${FILE_NAME}' WITH CHECKSUM, STATS=25"
		
		archive_and_upload
	} >/proc/1/fd/1 2>/proc/1/fd/2
fi
