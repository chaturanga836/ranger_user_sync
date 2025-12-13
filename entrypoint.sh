#!/bin/bash
set -e

RANGER_HOME=${RANGER_USER_HOME:-/opt/ranger-usersync}
INSTALL_PROPS="$RANGER_HOME/install.properties"

echo "Starting Ranger Usersync container..."

# Allow interactive shell
if [[ "$1" == "bash" || "$1" == "/bin/bash" ]]; then
    exec "$@"
fi

# Validate install.properties
if [ ! -f "$INSTALL_PROPS" ]; then
    echo "ERROR: install.properties not found at $INSTALL_PROPS"
    echo "Dropping into shell for debugging..."
    exec /bin/bash
fi

# Fix permissions
chown -R ranger:ranger "$RANGER_HOME"
chown -R ranger:ranger "$RANGER_RUN_DIR"

cd "$RANGER_HOME"

echo "Starting Ranger Usersync..."
exec ./ranger-usersync.sh start
