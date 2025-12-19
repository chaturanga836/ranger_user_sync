#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

USER_SYNC_HOME="/opt/ranger-usersync"
SETUP_MARKER="${USER_SYNC_HOME}/.setup_done"

cd "$USER_SYNC_HOME"

if [ "$(id -u)" = "0" ] && [ ! -f "$SETUP_MARKER" ]; then
  echo "Running Ranger Usersync setup (one-time)..."
  ./setup.sh
  chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger
  touch "$SETUP_MARKER"
fi

echo "Starting Ranger Usersync service..."

exec su -s /bin/bash ranger -c "
  cd $USER_SYNC_HOME && \
  ./ranger-usersync-services.sh start && \
  tail -F /opt/ranger-usersync/logs/*.log
"
