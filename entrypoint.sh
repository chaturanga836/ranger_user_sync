#!/bin/bash
set -e

# ---------------------------------------------------
# 1. Environment
# ---------------------------------------------------
export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Hadoop credential password (must match build-time)
export HADOOP_CREDSTORE_PASSWORD=${HADOOP_CREDSTORE_PASSWORD:-changeit}

cd /opt/ranger-usersync

# ---------------------------------------------------
# 2. Safety checks (NO regeneration)
# ---------------------------------------------------
if [ ! -f conf/rangerusersync.jceks ]; then
  echo "[FATAL] rangerusersync.jceks not found!"
  exit 1
fi

if [ ! -f conf/cert/truststore.jks ]; then
  echo "[FATAL] truststore.jks not found!"
  exit 1
fi

# ---------------------------------------------------
# 3. Permissions
# ---------------------------------------------------
chown -R ranger:ranger /opt/ranger-usersync
chmod 640 conf/rangerusersync.jceks

# ---------------------------------------------------
# 4. Start Usersync
# ---------------------------------------------------
rm -f run/usersync.pid || true
exec ./ranger-usersync-services.sh start
