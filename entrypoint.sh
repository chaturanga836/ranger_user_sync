#!/bin/bash
set -e

echo "Starting Ranger Usersync container..."

# Ensure JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

cd /opt/ranger-usersync

if [ ! -f install.properties ]; then
  echo "ERROR: install.properties not found!"
  exit 1
fi

echo "Running Ranger Usersync setup..."
./setup.sh

echo "Starting Ranger Usersync service..."
./ranger-usersync-services.sh stop || true
./ranger-usersync-services.sh start

# Ensure log exists and tail it
touch logs/usersync.log
tail -F logs/usersync.log
