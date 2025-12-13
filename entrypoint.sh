#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

# Skip chown for mounted files (optional)
# chown -R ranger:ranger $RANGER_USER_HOME || true
# chown -R ranger:ranger $RANGER_RUN_DIR || true

cd $RANGER_USER_HOME

# Run Usersync setup & start
./ranger-usersync-services.sh

# Ensure the log directory exists
mkdir -p logs
tail -F logs/usersync.log
