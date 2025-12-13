#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

cd /opt/ranger-usersync

# Sanity check
if [ ! -f install.properties ]; then
  echo "ERROR: install.properties not found at /opt/ranger-usersync/install.properties"
  exit 1
fi

# Ensure cert dir exists (setup.sh expects it)
mkdir -p conf/cert logs

# Run setup (idempotent)
echo "Running Ranger Usersync setup..."
./setup.sh

# Start Usersync
echo "Starting Ranger Usersync..."
./start.sh

# Keep container alive
tail -F logs/usersync.log
