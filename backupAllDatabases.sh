#!/usr/bin/env bash

function GetMysqlDatabases {
    databases=`mysql --defaults-extra-file=$MYSQL_OPTIONS_FILE -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
}

function BackupMysql {
    mysqldump --defaults-extra-file=$MYSQL_OPTIONS_FILE --force --opt --databases --events --routines --triggers $db | gzip > "$BACKUP_DIR/$BACKUP_FILENAME"
}

function GetPsqlDatabases {
    databases=`psql -U lampuser -d postgres -c 'SELECT datname FROM pg_database WHERE datistemplate = false;' -t`
}

function BackupPsql {
    pg_dump -U lampuser $db | gzip > "$BACKUP_DIR/$BACKUP_FILENAME"
}

source ./properties.sh

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

TIMESTAMP=$(date --rfc-3339=seconds)
BACKUP_DIR="$SCRIPTDIR/data/$BACKUP_PERIOD"
LATEST_DIR="$SCRIPTDIR/data/latest"
MYSQL_OPTIONS_FILE=$SCRIPTDIR/mysql_options.cnf

mkdir -p "$BACKUP_DIR"
rm -fR "$LATEST_DIR"
mkdir -p "$LATEST_DIR"


if [ $IS_POSTGRES -eq 1 ]; then
    GetPsqlDatabases
elif
    GetMysqlDatabases
fi

for db in $databases; do
  BACKUP_FILENAME="$db-$BACKUP_PERIOD-$TIMESTAMP.sql.gz"

  if [ $IS_POSTGRES -eq 1 ]; then
    BackupPsql
  elif
    BackupMysql
  fi

  ln -s "$BACKUP_DIR/$BACKUP_FILENAME" "$LATEST_DIR/$BACKUP_FILENAME"
done

find $BACKUP_DIR -ctime $REMOVE_TIMESPAN_DAYS -exec rm {} +
