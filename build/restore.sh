#!/bin/bash
NAME=$0

usage() {
	echo "Usage: "${NAME}" ((-d|-l) -f file [-t time]) | -r | -h"
	echo "  -d       Restore a database file"
	echo "  -l       Restore a log file"
	echo "  -f file  The file to restore; path must be from the perspective of the SQL Server container (e.g. /var/opt/mssql/backup/<date>/<file>)"
	echo "  -t time  The time for a point-in-time restore (STOPAT) in a valid SQL Server format (e.g. 2000-12-31T01:23:45); the time zone is the system time zone"
	echo "  -r       Finish restore and recover"
	echo "  -h       Print this help"
	exit $1
}

while getopts dlrf:t:h option; do
	case "${option}" in
		d)
			[[ ${TYPE} ]] || [[ ${RECOVERY} ]] && usage 1 || TYPE=DATABASE;;
		l)
			[[ ${TYPE} ]] || [[ ${RECOVERY} ]] && usage 1 || TYPE=LOG;;
		r)
			[[ ${TYPE} ]] || [[ ${FILE} ]] || [[ ${TIME} ]] && usage 1 || RECOVERY=1;;
		f)
			[[ ${RECOVERY} ]] && usage 1 || FILE="$OPTARG";;
		t)
			[[ ${RECOVERY} ]] && usage 1 || TIME="$OPTARG";;
		h)
			usage 0;;
		*)
			usage 1;;
	esac
done

if [[ ${TYPE} ]]; then 
	# Create STOPAT argument if $TIME is defined.
	[[ ${TIME} ]] && STOPAT_ARG="STOPAT='${TIME}', "
	{ # Redirect output to init so it shows up in the docker log.
		echo
		echo "$(date -Iseconds): Starting ${TYPE} restore from ${FILE}"
		sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "RESTORE DATABASE ${DB_NAME} FROM DISK='${FILE}' WITH ${STOPAT_ARG}NORECOVERY, STATS=25"
	} >/proc/1/fd/1 2>/proc/1/fd/2
elif [[ ${RECOVERY} ]]; then
	{ # Redirect output to init so it shows up in the docker log.
		echo
		echo "$(date -Iseconds): Starting restore with recovery"
		sqlcmd -S "${DB_ADDRESS}" -U SA -P "${SA_PASSWORD}" -Q "RESTORE DATABASE ${DB_NAME} WITH RECOVERY"
	} >/proc/1/fd/1 2>/proc/1/fd/2
else
	usage 1
fi
