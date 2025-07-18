#!/bin/bash
set -e

DB_NAME="$1"

./stop.sh

if [ -z "$DB_NAME" ]; then
    ./run_container.sh "pgbackrest --stanza=main --log-level-console=info --type=immediate --target-action=promote --delta restore";
else
    ./run_container.sh "pgbackrest --stanza=main --db-include=${DB_NAME} --log-level-console=info --type=immediate --target-action=promote --delta restore";
fi

./start.sh