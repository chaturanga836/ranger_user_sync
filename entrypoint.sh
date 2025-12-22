#!/usr/bin/env bash
set -ex   # <-- show commands + fail

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "Starting Ranger Usersync..."

echo "[DEBUG] Java version:"
java -version

echo "[DEBUG] Hadoop version:"
$HADOOP_HOME/bin/hadoop version || true

echo "[DEBUG] CLASSPATH:"
echo $CLASSPATH

rm -f /opt/ranger-usersync/run/usersync.pid || true

./ranger-usersync-services.sh start

exec tail -F /opt/ranger-usersync/logs/*.log
