# Use the recommended stable base image
FROM eclipse-temurin:11-jre-jammy

# Set environment variables
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

# Install minimum dependencies (using apt-get for this base image)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip xmlstarlet curl bash procps \
        net-tools iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create ranger user and initial directories
RUN useradd -ms /bin/bash ranger && \
    mkdir -p ${RANGER_USER_HOME}/logs ${RANGER_USER_HOME}/conf ${RANGER_RUN_DIR} && \
    chown -R ranger:ranger ${RANGER_USER_HOME} ${RANGER_RUN_DIR}

# Copy Ranger UserSync code and set ownership
COPY ranger-usersync/ ${RANGER_USER_HOME}/
RUN chown -R ranger:ranger ${RANGER_USER_HOME}

# Copy default config and make scripts executable
RUN cp -r ${RANGER_USER_HOME}/conf.dist/* ${RANGER_USER_HOME}/conf/
WORKDIR $RANGER_USER_HOME
# RUN chmod +x *.sh setup.py
RUN find . -type f -name "*.sh" -exec chmod +x {} \;


RUN ln -sf /usr/bin/python3 /usr/bin/python

RUN mkdir -p ${RANGER_USER_HOME}/conf/cert
# Set the entry point to simply run bash so you can take over
# CMD ["/bin/bash"]
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]