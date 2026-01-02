# #!/usr/bin/env bash
# set -e

# export JAVA_HOME=/opt/java/openjdk
# export PATH=$JAVA_HOME/bin:$PATH

# cd /opt/ranger-usersync

# # Run setup ONCE
# if [ ! -f conf/rangerusersync.jceks ]; then
#   echo "[I] JCEKS file not found, running setup.sh"
#   ./setup.sh
# fi

# echo "[I] Starting Ranger Usersync..."

# rm -f run/usersync.pid || true
# ./ranger-usersync-services.sh start

# exec tail -F logs/*.log

#!/bin/bash
set -e

# 1. Environment Setup
export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
# Use the password from Docker Compose, default to changeit
export HADOOP_CREDSTORE_PASSWORD=${HADOOP_CREDSTORE_PASSWORD:-changeit}

cd /opt/ranger-usersync

# 2. THE FIX: If the password changed, the old JCEKS is useless.
# We delete the old JCEKS and the Hadoop Checksum to start fresh.
echo "[I] Cleaning old credential stores and checksums..."
rm -f conf/rangerusersync.jceks
rm -f conf/.rangerusersync.jceks.crc

# 3. Run setup or manual build
# If you want to use the standard Ranger setup:
echo "[I] Running setup.sh to generate new JCEKS with current password..."
./setup.sh

# 4. Permissions
chown -R ranger:ranger ${RANGER_USER_HOME}
chmod 640 conf/rangerusersync.jceks

echo "[I] Starting Ranger Usersync..."
rm -f run/usersync.pid || true
./ranger-usersync-services.sh start

exec tail -F logs/usersync.log logs/auth.log