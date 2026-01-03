FROM eclipse-temurin:8-jdk

# ---------------------------------------------------
# Environment
# ---------------------------------------------------
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop/hadoop-3.3.6
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
# Critical: Added Ranger libs to classpath for credential tool
ENV CLASSPATH=$RANGER_USER_HOME/lib/*:$RANGER_USER_HOME/conf:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*

# ---------------------------------------------------
# OS packages
# ---------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 xmlstarlet curl bash procps net-tools iputils-ping wget ldap-utils openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Install Hadoop libraries
# ---------------------------------------------------
RUN mkdir -p $HADOOP_HOME && \
    wget -qO- https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME

# ---------------------------------------------------
# Create ranger user
# ---------------------------------------------------
RUN useradd -ms /bin/bash ranger

# ---------------------------------------------------
# Copy and Clean Ranger Files
# ---------------------------------------------------
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# IMPORTANT: Remove any pre-existing JCEKS or Checksum files from the build context
RUN rm -f ${RANGER_USER_HOME}/conf/rangerusersync.jceks \
    ${RANGER_USER_HOME}/conf/.rangerusersync.jceks.crc

# ---------------------------------------------------
# Required directories & Permissions
# ---------------------------------------------------
RUN mkdir -p ${RANGER_RUN_DIR} ${RANGER_USER_HOME}/logs ${RANGER_USER_HOME}/conf/cert /var/run/ranger && \
    find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; && \
    ln -sf /usr/bin/python3 /usr/bin/python

# ---------------------------------------------------
# SSL Setup
# ---------------------------------------------------
COPY certs/ca.crt ${RANGER_USER_HOME}/conf/cert/ca.crt
RUN keytool -importcert \
    -alias ldap-ca \
    -file ${RANGER_USER_HOME}/conf/cert/ca.crt \
    -keystore ${RANGER_USER_HOME}/conf/cert/truststore.jks \
    -storepass changeit \
    -noprompt

    # Usersync credential keystore (PKCS12) for policy manager password
RUN keytool -genseckey \
    -alias rangerUsersync_password  \
    -keyalg AES \
    -keysize 256 \
    -storetype JCEKS \
    -keystore ${RANGER_USER_HOME}/conf/rangerusersync.jceks \
    -storepass changeit \
    -keypass changeit
    
RUN chown -R ranger:ranger /opt/ranger-usersync /var/run/ranger /opt/hadoop

# ---------------------------------------------------
# Entrypoint Setup
# ---------------------------------------------------
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh
RUN chmod +x ${RANGER_USER_HOME}/entrypoint.sh

USER root
# USER ranger
WORKDIR ${RANGER_USER_HOME}
ENTRYPOINT ["./entrypoint.sh"]