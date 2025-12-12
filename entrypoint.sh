#!/bin/bash
set -e

# Ensure conf files exist
if [ ! -f "$RANGER_USER_HOME/conf/install.properties" ]; then
    echo "install.properties not found!"
    exit 1
fi

# Fix permissions
chown -R ranger:ranger $RANGER_USER_HOME
chown -R ranger:ranger $RANGER_RUN_DIR

# Start Ranger Usersync
echo "Starting Ranger Usersync..."
./ranger-usersync.sh start

# Keep container alive by tailing logs
tail -F $RANGER_USER_HOME/logs/usersync.log
