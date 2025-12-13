#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

# Fix permissions (if the volume is not owned by ranger)
chown -R ranger:ranger $RANGER_USER_HOME || true
chown -R ranger:ranger $RANGER_RUN_DIR || true

# Run Usersync services script
cd $RANGER_USER_HOME
./ranger-usersync-services.sh

# Keep container alive by tailing logs
tail -F $RANGER_USER_HOME/logs/usersync.log
