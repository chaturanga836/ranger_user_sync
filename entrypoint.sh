#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
cd /opt/ranger-usersync

# 1. Let setup.sh run first
if [ ! -f conf/ranger-ugsync-site.jceks ]; then
    echo "[I] Initializing Ranger with setup.sh..."
    ./setup.sh
fi

# 2. ONLY update the specific TRUSTSTORE (Not all JKS files)
echo "[I] Updating LDAP Truststore..."
TRUSTSTORE="conf/cert/truststore.jks"
mkdir -p conf/cert

# We recreate it to ensure it's fresh with the CA cert
rm -f "$TRUSTSTORE"
keytool -import -trustcacerts -alias ldap-ca \
    -file /opt/ranger-usersync/conf/cert/ldap-ca.crt \
    -keystore "$TRUSTSTORE" \
    -storepass changeit -noprompt -storetype JKS

# 3. Update the Global Java Cacerts
echo "[I] Updating global Java truststore..."
# Note: Use the dynamic path we found in the Dockerfile if possible
keytool -import -trustcacerts -alias ldap-aws \
    -file /opt/ranger-usersync/conf/cert/ldap-ca.crt \
    -keystore $JAVA_HOME/lib/security/cacerts \
    -storepass changeit -noprompt

# 4. Patch XML with xmlstarlet
echo "[I] Patching XML configurations..."
CONF="conf/ranger-ugsync-site.xml"
xmlstarlet ed -L -u "//property[name='ranger.usersync.sync.source']/value" -v "ldap" $CONF
xmlstarlet ed -L -u "//property[name='ranger.usersync.ldap.url']/value" -v "ldaps://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:636" $CONF

# Ensure the XML points to the correct truststore
xmlstarlet ed -L -u "//property[name='ranger.usersync.truststore.file']/value" -v "/opt/ranger-usersync/conf/cert/truststore.jks" $CONF
xmlstarlet ed -L -u "//property[name='ranger.usersync.truststore.password']/value" -v "changeit" $CONF

# 5. Permissions and Start
chown -R ranger:ranger /opt/ranger-usersync
rm -f run/usersync.pid || true

echo "[I] Starting Ranger Usersync..."
./ranger-usersync-services.sh start

exec tail -F logs/usersync-*.log