DATE=$(date -I)
TIME=$(date -Iseconds)
# Replace ':' with '-' for use in file name.
TIME=${TIME//:/-}
ARCHIVE_NAME=${DATE}/${DATE}.tar
ZIP_NAME=${ARCHIVE_NAME}.gz

archive_and_upload () {
    # Confirm file exists.
	if [[ -f ${LOCAL_BACKUP_DIR}${FILE_NAME} ]]; then
		# Add file to archive or create archive if it doesn't exist.
		if [[ -f ${LOCAL_BACKUP_DIR}${ZIP_NAME} ]]; then
			gunzip ${LOCAL_BACKUP_DIR}${ZIP_NAME} && tar -rf ${LOCAL_BACKUP_DIR}${ARCHIVE_NAME} ${LOCAL_BACKUP_DIR}${FILE_NAME} && gzip ${LOCAL_BACKUP_DIR}${ARCHIVE_NAME}
		else
			tar -czf ${LOCAL_BACKUP_DIR}${ZIP_NAME} ${LOCAL_BACKUP_DIR}${FILE_NAME}
		fi
		# Confirm file was added to archive, then delete file and copy archive to backup service.
		if [[ $? -eq 0 ]]; then
			rm ${LOCAL_BACKUP_DIR}${FILE_NAME}

			echo
			echo "$(date -Iseconds): Copying archive to backup service"
			rclone -v copy ${LOCAL_BACKUP_DIR}${ZIP_NAME} drive:/${DATE}/
		fi
	fi
}
