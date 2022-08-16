# SQL Backup

This Docker image will backup a chosen Dockerized Microsoft SQL Server database and copy the backup files to Google Drive using rclone. It must be run on the same machine as the SQL Server that is to be backed up. A full database backup will be done once a day at 00:05 UTC. A log backup will be done once an hour, 30 minutes past the hour. The files will be saved in subdirectories named for the current date in ISO 8601 format, e.g. `2000-12-31`. The files will be named `database-<time>.bak`, `log-<time>.bak`, or `tail-log-<time>.bak` for database, log, and tail log backups, respectively. `<time>` is the full ISO 8601 date and time with colons replaced by hyphens for file name compatibility, e.g. `database-2000-12-31T00-05-01+00-00.bak`.

Steps for use:

1. Provide a Google service account private key
2. Configure the `.env` file
3. Run on a Docker server

## 1. Service account private key

The private key file for a Google service account needs to be placed in the `build` directory with the file name `drive_key.json`. See the section under ‘Other Notes’ for more details about the service account.

## 2. Configuring

Configuration settings are specified in a file named `.env`. The provided `.env` file can be used as a template.

### Required settings

- DOCKER_VOLUME  
The name of a Docker volume attached to SQL Server. This will be used to persist the backup files. You can use the same volume that is used to persist SQL Server's data. You can view the volumes that a container is attached to by running `docker container inspect <containerName>` and looking in the `"Mounts"` section.
- REMOTE_BACKUP_DIR  
The absolute path to a directory on the above volume where the backups will be saved. A trailing `/` **must** be included. If using the same volume that SQL Server uses for its data, as described above, the path must be within that volume's mount point. For default SQL Server settings, that is `/var/opt/mssql/`, so a good location would be, e.g. `/var/opt/mssql/backup/`.
- LOCAL_BACKUP_DIR  
The relative path inside the above volume where the backups are stored. A trailing `/` **must** be included. In the above example with the volume mounted at `/var/opt/mssql/` and the backups stored at `/var/opt/mssql/backup/`, this would be `backup/`.
- DOCKER_NETWORK  
The name of a Docker network that SQL Server is connected to. You can view the networks that a container is connected to by running `docker container inspect <containerName>` and looking in the `"NetworkSettings": { "Networks" }` section.
- DB_ADDRESS  
The address of SQL Server on the above network. This can be viewed in the same section as above under `"Aliases"`.
- DB_PASSWORD  
The password of the SA account of SQL Server.
- DB_NAME  
The name of the database to be backed up.
- DRIVE_FOLDER_ID  
The Google Drive folder ID of a folder that is shared with the chosen service account with edit permission. See <https://rclone.org/drive/#root-folder-id> for instructions on how to find a folder's ID. This is required because otherwise rclone will save the files in the Google Drive of the service account, instead of a user account, and these files are not easily accessible. See the section under 'Other Notes' for more details about the service account.

### Optional settings

- DOCKER_REGISTRY  
The address of your Docker registry, from the perspective of the Docker server that the program will run on, e.g. `localhost:5000/`. If set, a trailing `/` **must** be included. If omitted, the local Docker Desktop registry is used, if present, otherwise, Docker Hub.
- DOCKER_TAG  
The tag to use when retrieving this program's image from the registry. If a tag is not provided, 'latest' will be used.

## 3. Running

Make a directory on your Docker server for this program. A good location would be the user's home directory, and a good name would be something that reflects which database this program will back up, e.g. `~/myprogram-sql-backup/`. Copy the `docker-compose.yml` and `.env` files and the entire `build` directory to this directory. Finally, run `docker-compose up -d` from within the directory. If you need to use a different `drive_key.json`, you must rebuild the image by running `docker-compose build` after replacing the file.

## Other Notes

### First backup of the day

If a database backup (not log backup) has not yet been performed for the current date, it will be done when the program is first started (upon running `docker-compose up -d`).

### Viewing logs

To view the log output of this program, run `docker logs <containerName>` or `docker logs -f <containerName>` to follow the log output. This will show the output of the backup commands which can be used to help diagnose any problems. To view the names of running containers, run `docker ps`. The container for this program should be named `<folderOfTheDocker-Compose.ymlFile>_sql-backup_1`.

### Interactive login and running scripts manually

There are 4 backup scrips under `/root/` in the image. `backup_database.sh` and `backup_log.sh` are the only two that are run on a schedule (daily and hourly, respectively). `backup_database.sh` will normally only backup the database if it hasn't yet been done for the day (to prevent multiple full backups from happening if the container is restarted), but it can be forced to backup with the `-f` flag. `backup_tail_log.sh` will backup the database log and then leave the database in the 'restoring' state, **which means it is offline and not available for use**. This is known as doing a 'tail log' backup, and the purpose is to prepare the database to be restored from a backup. `restore.sh` helps run restore operations. Run it without arguments to view help info. To connect to the container to run these scripts manually, run `docker exec -it <containerName> bash`. Note that the output of these scripts is redirected to the Docker logs, so it's advisable to follow the logs in another terminal when running them.

### Service account and Google Drive permissions

In order to enable unattended operation, rclone is configured to use a Google service account instead of a normal Google user account. Service accounts allow for perpetual unattended use while user accounts may require periodic reauthentication. See <https://rclone.org/drive/#service-account-support> for instructions on how to create and use a service account. In order for this service account to copy files to a user account, a folder in the user's Google Drive must be shared with the service account with edit permission.
