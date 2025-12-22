#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

cd /opt/ranger-usersync

# Run setup ONCE
if [ ! -f conf/rangerusersync.jceks ]; then
  echo "[I] JCEKS file not found, running setup.sh"
  ./setup.sh
fi

echo "[I] Starting Ranger Usersync..."

rm -f run/usersync.pid || true
./ranger-usersync-services.sh start

exec tail -F logs/*.log
