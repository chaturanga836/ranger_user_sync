#!/bin/bash
set -e

RANGER_HOME=${RANGER_USER_HOME:-/opt/ranger-usersync}
INSTALL_PROPS="$RANGER_HOME/install.properties"
INSTALL_MARKER="/usr/bin/ranger-usersync"

echo "Starting Ranger Usersync container..."

# Allow manual shell
if [[ "$1" == "bash" || "$1" == "/bin/bash" ]]; then
    exec "$@"
fi

# Validate install.properties
if [ ! -f "$INSTALL_PROPS" ]; then
    echo "ERROR: install.properties not found at $INSTALL_PROPS"
    exec /bin/bash
fi

cd "$RANGER_HOME"

# Run setup ONLY if usersync is not installed
if [ ! -f "$INSTALL_MARKER" ]; then
    echo "Running Ranger Usersync setup..."
    ./setup.sh
else
    echo "Ranger Usersync already installed. Skipping setup."
fi

echo "Starting Ranger Usersync service..."
exec ./start.sh
