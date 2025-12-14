FROM eclipse-temurin:8-jdk

ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
ENV JAVA_HOME=/usr/lib/jvm/java-8-temurin
ENV PATH=$JAVA_HOME/bin:$PATH

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 xmlstarlet curl bash procps \
        net-tools iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create ranger user
RUN useradd -ms /bin/bash ranger

# Copy Usersync distribution
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# Create runtime directories and fix ownership
RUN mkdir -p \
      ${RANGER_USER_HOME}/logs \
      ${RANGER_RUN_DIR} \
      ${RANGER_USER_HOME}/conf/cert \
      /var/run/ranger && \
    chown -R ranger:ranger ${RANGER_USER_HOME} ${RANGER_RUN_DIR} /var/run/ranger

WORKDIR ${RANGER_USER_HOME}

# Make internal scripts executable (sh + py)
RUN find . -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

# Python compatibility
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Run set_globals.sh as root to create /etc, /var/log and fix permissions
USER root
RUN ./set_globals.sh

# Drop privileges for normal runtime
USER ranger

# Copy entrypoint (must be executable on host)
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh

# No chmod here — host executable bit will be used
ENTRYPOINT ["./entrypoint.sh"]
