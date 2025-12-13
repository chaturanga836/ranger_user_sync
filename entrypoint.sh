#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

cd /opt/ranger-usersync

if [ ! -f install.properties ]; then
  echo "ERROR: install.properties not found!"
  exit 1
fi

echo "Running Ranger Usersync setup..."
./setup.sh

echo "Starting Ranger Usersync..."
./start.sh

tail -F logs/usersync.log
