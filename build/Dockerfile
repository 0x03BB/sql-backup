FROM ubuntu:jammy

# Accept mssql-tools EULA.
ENV ACCEPT_EULA=Y
ENV PATH=/opt/mssql-tools/bin:$PATH

# Import Microsoft's public repository GPG keys.
ADD https://packages.microsoft.com/keys/microsoft.asc /root/microsoft.asc
# Install dependencies for apt-key.
RUN \
  apt-get update && \
  apt-get install -y \
  gnupg \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/* && \
  apt-key add /root/microsoft.asc

# Register the Microsoft Ubuntu repository.
ADD https://packages.microsoft.com/config/ubuntu/22.04/prod.list /etc/apt/sources.list.d/msprod.list

# Install remainder of packages.
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
  mssql-tools \
  unixodbc-dev \
  rclone \
  cron && \
  rm -rf /var/lib/apt/lists/*

# Copy backup scripts, crontab, and rclone configuration.
COPY --chmod=744 entrypoint.sh /root/entrypoint.sh
COPY --chmod=744 shared.sh /root/shared.sh
COPY --chmod=744 backup_database.sh /root/backup_database.sh
COPY --chmod=744 backup_log.sh /root/backup_log.sh
COPY --chmod=744 backup_tail_log.sh /root/backup_tail_log.sh
COPY --chmod=744 restore.sh /root/restore.sh
COPY --chmod=644 sqlbackup /etc/cron.d/sqlbackup
COPY rclone.conf /root/rclone.conf
COPY drive_key.json /root/drive_key.json
RUN mkdir -p /root/.config/rclone

# Setup the cron environment and rclone configuration, run the initial database backup, if needed, then run cron in the foreground.
ENTRYPOINT ["/root/entrypoint.sh"]
