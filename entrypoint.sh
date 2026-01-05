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

# 2. FIND AND REPLACE ALL JKS FILES
# This handles the root conf AND the nested usersync/conf
echo "[I] Replacing all discovered JKS files with Golden Certificate..."
ALL_JKS=$(find /opt/ranger-usersync -name "*.jks")

for jks in $ALL_JKS; do
    echo "Updating: $jks"
    rm -f "$jks"
    keytool -import -trustcacerts -alias ldap-ca \
        -file /opt/ranger-usersync/conf/cert/ldap-ca.crt \
        -keystore "$jks" \
        -storepass changeit -noprompt -storetype JKS
done

# 3. Update the Global Java Cacerts (Final Safety Net)
echo "[I] Updating global Java truststore..."
keytool -import -trustcacerts -alias ldap-aws \
    -file /opt/ranger-usersync/conf/cert/ldap-ca.crt \
    -keystore $JAVA_HOME/lib/security/cacerts \
    -storepass changeit -noprompt

# 4. Patch XML with xmlstarlet
echo "[I] Patching XML configurations..."
CONF="conf/ranger-ugsync-site.xml"
xmlstarlet ed -L -u "//property[name='ranger.usersync.sync.source']/value" -v "ldap" $CONF
xmlstarlet ed -L -u "//property[name='ranger.usersync.ldap.url']/value" -v "ldaps://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:636" $CONF

# 5. Permissions and Start
chown -R ranger:ranger /opt/ranger-usersync
rm -f run/usersync.pid || true

echo "[I] Starting Ranger Usersync..."
./ranger-usersync-services.sh start

exec tail -F logs/usersync-*.log