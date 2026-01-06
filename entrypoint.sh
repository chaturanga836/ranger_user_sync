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
echo "[I] Patching XML configurations..."
CONF="conf/ranger-ugsync-site.xml"

# Function to safely update or add properties
update_prop() {
    local name=$1
    local value=$2
    if xmlstarlet sel -t -v "//property[name='$name']" "$CONF" > /dev/null 2>&1; then
        xmlstarlet ed -L -u "//property[name='$name']/value" -v "$value" "$CONF"
    else
        xmlstarlet ed -L -s "/configuration" -t elem -n "property" -v "" \
            -s "/configuration/property[last()]" -t elem -n "name" -v "$name" \
            -s "/configuration/property[last()]" -t elem -n "value" -v "$value" "$CONF"
    fi
}

# Force these critical values to kill the NPE
update_prop "ranger.usersync.ldap.sslEnabled" "true"
update_prop "ranger.usersync.ldap.url" "$LDAP_URL"
update_prop "ranger.usersync.truststore.file" "$TS_FILE"
update_prop "ranger.usersync.truststore.password" "$TS_PASS"
update_prop "ranger.usersync.ldap.ssl.truststore" "$TS_FILE"
update_prop "ranger.usersync.ldap.ssl.truststore.password" "$TS_PASS"
update_prop "ranger.usersync.ldap.ssl.truststore.type" "JK

# 4. Cleanup and Start
chown -R ranger:ranger /opt/ranger-usersync
rm -f run/usersync.pid || true

echo "[I] Starting Ranger Usersync..."
./ranger-usersync-services.sh start

exec tail -F logs/auth.log logs/usersync-*.log 