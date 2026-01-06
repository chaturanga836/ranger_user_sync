#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
cd /opt/ranger-usersync

# 1. Load Credstore Password (Fixes the WARNING in your logs)
if [ -z "${HADOOP_CREDSTORE_PASSWORD}" ]; then
    export HADOOP_CREDSTORE_PASSWORD=$(grep '^HADOOP_CREDSTORE_PASSWORD=' install.properties | cut -d'=' -f2-)
fi

# 2. Run Setup (Uses the SSL properties we just fixed in install.properties)
if [ ! -f conf/ranger-ugsync-site.jceks ]; then
    echo "[I] Initializing Ranger with setup.sh..."
    ./setup.sh
fi

# 3. Safety Net: Import cert to Global Java Truststore (Hortonworks Method 4.1)
echo "[I] Importing LDAP CA into System Java Truststore..."
CACERTS_PATH="/opt/java/openjdk/lib/security/cacerts"
keytool -import -trustcacerts -alias ldap-ca \
    -file conf/cert/ldap-ca.crt \
    -keystore "$CACERTS_PATH" \
    -storepass changeit -noprompt || echo "Already imported"

# 4. Patch XML (Ensure LDAPS URL is set)
CONF="conf/ranger-ugsync-site.xml"
xmlstarlet ed -L -u "//property[name='ranger.usersync.ldap.url']/value" -v "ldaps://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:636" $CONF

# 4. Cleanup and Start
chown -R ranger:ranger /opt/ranger-usersync
rm -f run/usersync.pid || true

echo "[I] Starting Ranger Usersync..."
./ranger-usersync-services.sh start

exec tail -F logs/usersync-*.log