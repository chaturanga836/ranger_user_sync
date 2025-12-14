FROM eclipse-temurin:11-jre-jammy

ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 xmlstarlet curl bash procps \
        net-tools iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create ranger user
RUN useradd -ms /bin/bash ranger

# Copy Usersync distribution
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# Create runtime dirs and fix ownership
RUN mkdir -p \
      ${RANGER_USER_HOME}/logs \
      ${RANGER_RUN_DIR} \
      ${RANGER_USER_HOME}/conf/cert && \
    chown -R ranger:ranger ${RANGER_USER_HOME}

WORKDIR ${RANGER_USER_HOME}

# Make scripts executable
RUN find . -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
RUN mkdir -p /var/run/ranger && chown -R ranger:ranger /var/run/ranger
RUN mkdir -p ${RANGER_USER_HOME}/logs && chown -R ranger:ranger ${RANGER_USER_HOME}/logs

# Python compatibility
RUN ln -sf /usr/bin/python3 /usr/bin/python

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ranger
ENTRYPOINT ["/entrypoint.sh"]
