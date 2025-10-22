FROM openjdk:11-jre-slim

# Set environment
ENV RANGER_USERSYNC_HOME=/opt/ranger-usersync
ENV JAVA_HOME=/usr/local/openjdk-11

# Install Python3
RUN apt-get update && apt-get install -y python3 python3-pip sudo && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p $RANGER_USERSYNC_HOME

# Copy UserSync source code into container
COPY . $RANGER_USERSYNC_HOME

WORKDIR $RANGER_USERSYNC_HOME

# Set executable permissions
RUN chmod +x setup.py ranger-usersync-services.sh

# Run setup.py to initialize UserSync
RUN python3 setup.py

# Expose logs or any ports if needed (usually UserSync doesn't serve ports)
VOLUME ["/var/log/ranger/usersync", "/var/run/ranger"]

# Start UserSync service
CMD ["./ranger-usersync-services.sh", "start"]
