#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
cd /opt/ranger-usersync

# 1. Initialize Ranger
if [ ! -f conf/ranger-ugsync-site.jceks ]; then
    echo "[I] Initializing Ranger with setup.sh..."
    ./setup.sh
fi

# 2. HORTONWORKS METHOD 4.1: Update Global Java Truststore
# This ensures ANY Java call (LDAP, Admin, etc.) trusts your CA.
echo "[I] Importing LDAP CA into System Java Truststore..."
# We use the path we created in the Dockerfile
CACERTS_PATH="/opt/java/openjdk/lib/security/cacerts"

# Remove existing alias if it exists to prevent 'already exists' error
keytool -delete -alias ldap-ca -keystore "$CACERTS_PATH" -storepass changeit -noprompt || true

# Import the cert
keytool -import -trustcacerts -alias ldap-ca \
    -file /opt/ranger-usersync/conf/cert/ldap-ca.crt \
    -keystore "$CACERTS_PATH" \
    -storepass changeit -noprompt

# 3. PATCH XML with xmlstarlet
echo "[I] Patching XML configurations..."
CONF="conf/ranger-ugsync-site.xml"
xmlstarlet ed -L -u "//property[name='ranger.usersync.sync.source']/value" -v "ldap" $CONF
xmlstarlet ed -L -u "//property[name='ranger.usersync.ldap.url']/value" -v "ldaps://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:636" $CONF

# 4. Cleanup and Start
chown -R ranger:ranger /opt/ranger-usersync
rm -f run/usersync.pid || true

echo "[I] Starting Ranger Usersync..."
./ranger-usersync-services.sh start

exec tail -F logs/usersync-*.log