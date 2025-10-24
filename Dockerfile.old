FROM eclipse-temurin:11-jre-jammy

# CRITICAL FIX: Base image already contains JRE, so we only need to install OS deps using APT
# The base image sets JAVA_HOME internally, no need to override unless necessary.
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

# Install dependencies using apt-get (Ubuntu package manager)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-dev python3-pip \
    which net-tools iputils-ping curl \
    xmlstarlet unzip procps && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Fix the Python interpreter path expected by setup.py
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Create ranger user and initial directories
RUN useradd -ms /bin/bash ranger && \
    mkdir -p ${RANGER_USER_HOME}/logs ${RANGER_USER_HOME}/conf ${RANGER_RUN_DIR} && \
    chown -R ranger:ranger ${RANGER_USER_HOME} ${RANGER_RUN_DIR}

# Copy Ranger UserSync code and set ownership
COPY ranger-usersync/ ${RANGER_USER_HOME}/
RUN chown -R ranger:ranger ${RANGER_USER_HOME}

# Copy default config
RUN cp -r ${RANGER_USER_HOME}/conf.dist/* ${RANGER_USER_HOME}/conf/

WORKDIR $RANGER_USER_HOME

# Make scripts executable
RUN chmod +x *.sh setup.py

# FIX: Patch configuration with xmlstarlet (using corrected policyengine.connection.url and jceks URI)
RUN xmlstarlet ed -L \
    -u "//property[name='ranger.usersync.policyengine.connection.url']/value" \
    -v "http://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:6080" \
    -s '//configuration' -t elem -n 'property' \
    -s '//property[last()]' -t elem -n 'name' -v 'ranger.usersync.credstore.filename' \
    -s '//property[last()]' -t elem -n 'value' -v 'jceks://file//opt/ranger-usersync/conf/rangerusersync.jceks' \
    ${RANGER_USER_HOME}/conf/ranger-ugsync-site.xml

# Pre-run setup script (JAVA_HOME is already correct in this base image)
RUN ./setup.sh || echo "Setup completed with non-zero exit, continuing..."

WORKDIR ${RANGER_USER_HOME}

# Expose Usersync port
EXPOSE 5151

# Entrypoint: Start usersync as ranger user and follow logs with robust wait loop
ENTRYPOINT ["/bin/bash", "-c", "\
    mkdir -p /var/run/ranger /opt/ranger-usersync/logs && \
    chown -R ranger:ranger /var/run/ranger /opt/ranger-usersync/logs && \
    echo 'Starting Apache Ranger Usersync Service...' && \
    su -s /bin/bash ranger -c '/opt/ranger-usersync/ranger-usersync-services.sh start' && \
    \
    echo 'Waiting for usersync.log to appear (max 30s)...' && \
    COUNTER=0; while [ ! -f /opt/ranger-usersync/logs/usersync.log ] && [ $COUNTER -lt 30 ]; do sleep 1; COUNTER=$((COUNTER+1)); done && \
    \
    if [ -f /opt/ranger-usersync/logs/usersync.log ]; then \
    echo 'Usersync log found. Tailing logs...' && \
    su -s /bin/bash ranger -c 'tail -F /opt/ranger-usersync/logs/usersync.log'; \
    else \
    echo 'FATAL: Usersync log file was NOT created after 30 seconds. Entering interactive shell for debugging.' && \
    /bin/bash; \
    fi"]