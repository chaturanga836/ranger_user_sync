#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "Running setup.sh if not already done..."
if [ ! -f /opt/ranger-usersync/run/setup_done ]; then
    chmod +x /opt/ranger-usersync/setup.sh
    ./setup.sh
    touch /opt/ranger-usersync/run/setup_done
fi

echo "Starting Ranger Usersync..."

# Cleanup stale pid
rm -f /opt/ranger-usersync/run/usersync.pid || true

# Start Usersync service
./ranger-usersync-services.sh start

# Follow logs
exec tail -F /opt/ranger-usersync/logs/*.log
