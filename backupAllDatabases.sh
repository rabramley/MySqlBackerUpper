#!/usr/bin/env bash

SCRIPTDIR=$(dirname "$0")

if [[ $1 == D ]]; then
    BACKUP_PERIOD="daily"
    REMOVE_TIMESPAN_DAYS=+6
elif [[ $1 == W ]]; then
    BACKUP_PERIOD="weekly"
    REMOVE_TIMESPAN_DAYS=+21
elif [[ $1 == M ]]; then
    BACKUP_PERIOD="monthly"
    REMOVE_TIMESPAN_DAYS=+93
elif [[ $1 == H ]]; then
    BACKUP_PERIOD="hourly"
    REMOVE_TIMESPAN_DAYS=+1
else
    echo "Time period parameter not supplied should be H, D, W or M"
    exit 1
fi

TIMESTAMP=$(date +"%F")
BACKUP_DIR="$SCRIPTDIR/data/$BACKUP_PERIOD"
LATEST_DIR="$SCRIPTDIR/data/latest"
OPTIONS_FILE=$SCRIPTDIR/mysql_options.cnf

mkdir -p "$BACKUP_DIR"
rm -fR "$LATEST_DIR"
mkdir -p "$LATEST_DIR"

databases=`mysql --defaults-extra-file=$OPTIONS_FILE -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`

for db in $databases; do
  mysqldump --defaults-extra-file=$OPTIONS_FILE --force --opt --databases --events --routines --triggers $db | gzip > "$BACKUP_DIR/$db-$TIMESTAMP.sql.gz"

  ln -s "$BACKUP_DIR/$db-$TIMESTAMP.gz" "$LATEST_DIR/$db-$TIMESTAMP.gz"
done

find $BACKUP_DIR -ctime $REMOVE_TIMESPAN_DAYS -exec rm {} +
