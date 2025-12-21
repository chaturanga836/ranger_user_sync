FROM eclipse-temurin:8-jdk

# ---------------------------------------------------
# Environment
# ---------------------------------------------------
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# ---------------------------------------------------
# OS packages
# ---------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        xmlstarlet \
        curl \
        bash \
        procps \
        net-tools \
        iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Create ranger user
# ---------------------------------------------------
RUN useradd -ms /bin/bash ranger

# ---------------------------------------------------
# Copy Ranger Usersync
# ---------------------------------------------------
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# ---------------------------------------------------
# Copy the template with correct filename
# ---------------------------------------------------
COPY templates/ranger-ugsync-template.xml ${RANGER_USER_HOME}/conf/ranger-ugsync-site.xml

# ---------------------------------------------------
# Required directories (DOCKER SAFE)
# ---------------------------------------------------
RUN mkdir -p \
    ${RANGER_USER_HOME}/logs \
    ${RANGER_RUN_DIR} \
    ${RANGER_USER_HOME}/conf/cert

# ---------------------------------------------------
# Patch Ranger scripts for Docker
# ---------------------------------------------------
RUN sed -i \
    -e 's|/var/run/ranger|/opt/ranger-usersync/run|g' \
    -e '/chown ${UNIX_USERSYNC_USER}/d' \
    ${RANGER_USER_HOME}/ranger-usersync-services.sh

# ---------------------------------------------------
# Permissions
# ---------------------------------------------------
RUN chown -R ranger:ranger ${RANGER_USER_HOME} && \
    chmod 600 ${RANGER_USER_HOME}/conf/ranger-ugsync-site.xml

# ---------------------------------------------------
# Executables
# ---------------------------------------------------
RUN find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

# ---------------------------------------------------
# Python compatibility
# ---------------------------------------------------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------------------------------------------------
# Entrypoint (NO su, NO start.sh)
# ---------------------------------------------------
COPY entrypoint.sh ${RANGER_USER_HOME}/en
