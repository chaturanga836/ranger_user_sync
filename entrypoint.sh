#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
cd /opt/ranger-usersync

# 1. Run setup if needed
if [ ! -f conf/ranger-ugsync-site.jceks ]; then
  echo "[I] JCEKS file not found, running setup.sh"
  # Note: Ensure install.properties is correctly configured or 
  # setup.sh might fail in non-interactive mode.
  ./setup.sh
fi

# 2. FORCE correct LDAP settings in XML (Prevent setup.sh overrides)
echo "[I] Patching configuration for LDAPS..."
CONF_FILE="conf/ranger-ugsync-site.xml"

# Set the Sync Source to LDAP
xmlstarlet ed -L -u "//property[name='ranger.usersync.sync.source']/value" -v "ldap" $CONF_FILE

# Set the correct AWS Hostname
xmlstarlet ed -L -u "//property[name='ranger.usersync.ldap.url']/value" -v "ldaps://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:636" $CONF_FILE

# Ensure the Truststore path is correct
xmlstarlet ed -L -u "//property[name='ranger.usersync.truststore.file']/value" -v "/opt/ranger-usersync/conf/cert/truststore.jks" $CONF_FILE

# 3. Final cleanup and start
echo "[I] Starting Ranger Usersync..."
rm -f run/usersync.pid || true

# Start service in background
./ranger-usersync-services.sh start

# Keep container alive by tailing logs
exec tail -F logs/usersync-*.log