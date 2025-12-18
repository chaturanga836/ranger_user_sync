#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

SETUP_MARKER="/opt/ranger-usersync/.setup_done"

if [ "$(id -u)" = "0" ] && [ ! -f "$SETUP_MARKER" ]; then
  echo "Running Ranger Usersync setup (one-time)..."
  ./setup.sh
  chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger
  touch "$SETUP_MARKER"
fi

echo "Starting Ranger Usersync service..."
exec su -s /bin/bash ranger -c "./ranger-usersync-services.sh start"
