#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "Starting Ranger Usersync..."

# Cleanup stale pid
rm -f /opt/ranger-usersync/run/usersync.pid || true

# Start Usersync
./ranger-usersync-services.sh start

# Follow logs
exec tail -F /opt/ranger-usersync/logs/*.log
