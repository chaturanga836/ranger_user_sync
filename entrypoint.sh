#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

cd /opt/ranger-usersync

# Validate install.properties
if [ ! -f install.properties ]; then
  echo "ERROR: install.properties not found!"
  exit 1
fi

# Run setup (safe to re-run)
echo "Running Ranger Usersync setup..."
./setup.sh

# Start Usersync
echo "Starting Ranger Usersync..."
./start.sh

# Keep container alive
tail -F logs/usersync.log
