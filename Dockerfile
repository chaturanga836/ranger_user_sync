FROM eclipse-temurin:8-jdk

ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
# ENV JAVA_HOME=JAVA_HOME=/opt/java/openjdk
# ENV PATH=$JAVA_HOME/bin:$PATH

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

# Create runtime directories
RUN mkdir -p \
      ${RANGER_USER_HOME}/logs \
      ${RANGER_RUN_DIR} \
      ${RANGER_USER_HOME}/conf/cert \
      /var/run/ranger

WORKDIR ${RANGER_USER_HOME}

# Make scripts executable
RUN find . -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

# Python compatibility
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Run setup as root
USER root
RUN ./set_globals.sh && \
    chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger

# Entrypoint
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh
RUN chmod +x ${RANGER_USER_HOME}/entrypoint.sh

# Drop privileges
USER ranger
ENTRYPOINT ["./entrypoint.sh"]