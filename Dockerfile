FROM openjdk:11-jdk-slim

# Install dependencies and the 'default-jdk' package to guarantee a linkable Java installation
RUN apt-get update && \
    apt-get install -y python3 python3-dev python3-pip bash procps net-tools default-jdk && \
    rm -rf /var/lib/apt/lists/*

# Create ranger user
RUN useradd -ms /bin/bash ranger

# Set RANGER environment variables
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

# Copy Ranger UserSync code into container
COPY ranger-usersync/ $RANGER_USER_HOME
RUN chown -R ranger:ranger $RANGER_USER_HOME

WORKDIR $RANGER_USER_HOME

# Make scripts executable
RUN chmod +x *.sh setup.py

# Run setup.sh as root during build
# Dynamically find the correct JAVA_HOME path and export it for ./setup.sh
# The dirname $(dirname ...) pattern finds the JDK root path from the 'java' executable symlink.
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java))) && \
    export PATH="$JAVA_HOME/bin:$PATH" && \
    ./setup.sh

# Expose Usersync port
EXPOSE 5151

# Entry point: create runtime directories as root, then drop privileges
ENTRYPOINT ["/bin/bash", "-c", "mkdir -p $RANGER_RUN_DIR && chown -R ranger:ranger $RANGER_RUN_DIR && exec su -s /bin/bash ranger -c '/opt/ranger-usersync/ranger-usersync-services.sh start'"]