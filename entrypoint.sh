#!/usr/bin/env bash
set -ex

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "Starting Ranger Usersync..."

echo "[DEBUG] Java version:"
java -version

# Hadoop CLI NOT required for usersync
echo "[DEBUG] Hadoop CLI not required for Ranger Usersync"

echo "[DEBUG] CLASSPATH:"
echo "$CLASSPATH"

rm -f /opt/ranger-usersync/run/usersync.pid || true

./ranger-usersync-services.sh start

exec tail -F /opt/ranger-usersync/logs/*.log
