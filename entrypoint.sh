#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

# Run setup as root
if [ "$(id -u)" = "0" ]; then
  echo "Running Ranger Usersync setup as root..."
  ./setup.sh
  chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger
fi

echo "Starting Ranger Usersync service..."
exec su -s /bin/bash ranger -c "./ranger-usersync-services.sh start && tail -f /dev/null"
