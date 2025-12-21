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
# Copy Ranger Usersync distribution
# ---------------------------------------------------
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# ---------------------------------------------------
# Create required directories
# ---------------------------------------------------
RUN mkdir -p \
    ${RANGER_USER_HOME}/logs \
    ${RANGER_RUN_DIR} \
    ${RANGER_USER_HOME}/conf/cert \
    /var/run/ranger

# ---------------------------------------------------
# FIX: ensure correct usersync config filename
# ---------------------------------------------------
RUN if [ -f "${RANGER_USER_HOME}/conf/ranger-ugsync-site.xml" ]; then \
        mv ${RANGER_USER_HOME}/conf/ranger-ugsync-site.xml \
           ${RANGER_USER_HOME}/conf/ranger-usersync-site.xml ; \
    fi

# ---------------------------------------------------
# Permissions
# ---------------------------------------------------
RUN chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger

# ---------------------------------------------------
# Executable scripts
# ---------------------------------------------------
RUN find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

# ---------------------------------------------------
# Python compatibility
# ---------------------------------------------------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------------------------------------------------
# Entry point
# ---------------------------------------------------
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh
RUN chmod +x ${RANGER_USER_HOME}/entrypoint.sh

# ---------------------------------------------------
# Runtime user
# ---------------------------------------------------
USER ranger
WORKDIR ${RANGER_USER_HOME}

ENTRYPOINT ["./entrypoint.sh"]
