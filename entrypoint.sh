#!/usr/bin/env bash
set -e

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

RANGER_HOME=/opt/ranger-usersync
JCEKS_FILE="$RANGER_HOME/conf/rangerusersync.jceks"
POLICY_ALIAS="ranger.usersync.policymgr.password"

echo "Starting Ranger Usersync..."

# -------------------------------
# Ensure run and logs directories exist
# -------------------------------
mkdir -p $RANGER_HOME/run
mkdir -p $RANGER_HOME/logs

# -------------------------------
# Cleanup stale pid
# -------------------------------
rm -f $RANGER_HOME/run/usersync.pid || true

# -------------------------------
# Generate JCEKS if missing
# -------------------------------
if [ ! -f "$JCEKS_FILE" ]; then
    echo "[I] JCEKS file not found, creating..."
    
    # Prompt for policy manager password if not passed as env variable
    if [ -z "$RANGER_POLICYMGR_PASSWORD" ]; then
        read -s -p "Enter Ranger Usersync policy manager password: " RANGER_POLICYMGR_PASSWORD
        echo
    fi

    # Run updatepolicymgrpassword.py to create JCEKS
    python3 $RANGER_HOME/updatepolicymgrpassword.py rangerusersync "$RANGER_POLICYMGR_PASSWORD"

    # Ensure correct ownership
    chown ranger:ranger "$JCEKS_FILE"
    echo "[I] JCEKS file created at $JCEKS_FILE"
else
    echo "[I] JCEKS file already exists at $JCEKS_FILE"
fi

# -------------------------------
# Start Usersync service
# -------------------------------
$RANGER_HOME/ranger-usersync-services.sh start

# -------------------------------
# Follow Usersync logs
# -------------------------------
exec tail -F $RANGER_HOME/logs/*.log
