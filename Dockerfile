FROM openjdk:11-jdk-slim

# Install dependencies and the 'default-jdk' package to guarantee a linkable Java installation
RUN apt-get update && \
    apt-get install -y \
        python3 python3-dev python3-pip \
        bash procps net-tools default-jdk \
        xmlstarlet && \
    rm -rf /var/lib/apt/lists/*

    # Fix the Python interpreter path expected by setup.py
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Create ranger user
RUN useradd -ms /bin/bash ranger

# Set RANGER environment variables
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

# Copy Ranger UserSync code into container
COPY ranger-usersync/ $RANGER_USER_HOME
RUN chown -R ranger:ranger $RANGER_USER_HOME

# CRUCIAL FIX: Create the logs directory and ensure the 'ranger' user owns it.
RUN mkdir -p $RANGER_USER_HOME/logs && \
    chown -R ranger:ranger $RANGER_USER_HOME/logs

    # FINAL FIX: Copy configuration templates from conf.dist to the active conf directory
RUN cp -r $RANGER_USER_HOME/conf.dist/* $RANGER_USER_HOME/conf/

WORKDIR $RANGER_USER_HOME

# Make scripts executable
RUN chmod +x *.sh setup.py

# FIX: Set the missing property 'ranger.usersync.credstore.filename' to avoid KeyError during setup.py
RUN xmlstarlet ed -L -s '//configuration' -t elem -n 'property' \
    -s '//property[last()]' -t elem -n 'name' -v 'ranger.usersync.credstore.filename' \
    -s '//property[last()]' -t elem -n 'value' -v 'jceks://file/etc/ranger/usersync/conf/rangerusersync.jceks' \
    $RANGER_USER_HOME/conf/ranger-ugsync-site.xml
# Run setup.sh as root during build
# Dynamically find the correct JAVA_HOME path and export it for ./setup.sh
# The dirname $(dirname ...) pattern finds the JDK root path from the 'java' executable symlink.
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java))) && \
    export PATH="$JAVA_HOME/bin:$PATH" && \
    ./setup.sh

# Expose Usersync port
EXPOSE 5151

# Entry point: create runtime directories as root, then drop privileges
ENTRYPOINT ["/bin/bash", "-c", "\
  mkdir -p /var/run/ranger && \
  chown -R ranger:ranger /var/run/ranger && \
  su -s /bin/bash ranger -c '/opt/ranger-usersync/ranger-usersync-services.sh start' && \
  su -s /bin/bash ranger -c 'tail -F /opt/ranger-usersync/logs/usersync.log'"]
