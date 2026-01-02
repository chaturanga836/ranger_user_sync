#!/bin/bash
set -e

# 1. Environment Setup
export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Ensure we use the Master Password from Docker Compose
export HADOOP_CREDSTORE_PASSWORD=${HADOOP_CREDSTORE_PASSWORD:-changeit}

cd /opt/ranger-usersync

# 2. Cleanup old/broken files
# We remove the old JCEKS and the hidden Hadoop checksum file 
# to prevent the "Checksum error" and "Tampered with" logs.
echo "[I] Cleaning old credential stores and checksums..."
rm -f conf/rangerusersync.jceks
rm -f conf/.rangerusersync.jceks.crc

# 3. Generate New Credentials
# We run setup.sh fresh so it uses the current HADOOP_CREDSTORE_PASSWORD
echo "[I] Running setup.sh to generate new JCEKS..."
./setup.sh

# 4. Final Permissions
# Using absolute paths to avoid variable resolution issues
echo "[I] Setting permissions..."
chown -R ranger:ranger /opt/ranger-usersync
chmod 640 /opt/ranger-usersync/conf/rangerusersync.jceks

# 5. Start Service
echo "[I] Starting Ranger Usersync..."
rm -f run/usersync.pid || true
./ranger-usersync-services.sh start

# 6. Monitor Logs
# Keep the container running by tailing the logs
exec tail -F logs/usersync.log logs/auth.log