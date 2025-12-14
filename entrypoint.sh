#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

# Ensure writable dirs
mkdir -p /var/run/ranger
chown -R ranger:ranger /var/run/ranger
mkdir -p /opt/ranger-usersync/logs
chown -R ranger:ranger /opt/ranger-usersync/logs

cd /opt/ranger-usersync

if [ ! -f install.properties ]; then
  echo "ERROR: install.properties not found!"
  exit 1
fi

echo "Running Ranger Usersync setup..."
./setup.sh

echo "Starting Ranger Usersync..."
./ranger-usersync-services.sh start

tail -F logs/usersync.log
