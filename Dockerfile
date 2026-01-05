FROM eclipse-temurin:8-jdk

# ---------------------------------------------------
# Environment
# ---------------------------------------------------
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
ENV JAVA_HOME=/opt/java/openjdk
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop/hadoop-3.3.6
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV CLASSPATH=$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*

# ---------------------------------------------------
# OS packages
# ---------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 xmlstarlet curl bash procps net-tools iputils-ping wget ldap-utils openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Fix Java cacerts path - THE BULLET-PROOF FIX
# ---------------------------------------------------
# 1. Create the directory Ranger's hardcoded script expects
# 2. Find the REAL cacerts in Temurin and COPY it there (not a link)
RUN mkdir -p /opt/java/openjdk/lib/security && \
    REAL_CACERT=$(find $JAVA_HOME -name cacerts) && \
    cp "$REAL_CACERT" /opt/java/openjdk/lib/security/cacerts

# ---------------------------------------------------
# Install Hadoop libraries
# ---------------------------------------------------
RUN mkdir -p $HADOOP_HOME && \
    wget -qO- https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION}/* $HADOOP_HOME/ || true

# ---------------------------------------------------
# Create ranger user & Copy Source
# ---------------------------------------------------
RUN useradd -ms /bin/bash ranger
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# ---------------------------------------------------
# Required directories & Certificate Setup
# ---------------------------------------------------
RUN mkdir -p ${RANGER_RUN_DIR} \
             ${RANGER_USER_HOME}/logs \
             ${RANGER_USER_HOME}/conf/cert \
             ${RANGER_USER_HOME}/usersync/conf/cert

COPY certs/tls.crt ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt

# Pre-populate JKS stores
RUN $JAVA_HOME/bin/keytool -import -trustcacerts \
    -alias ldap-ca \
    -file ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt \
    -keystore ${RANGER_USER_HOME}/conf/cert/truststore.jks \
    -storepass changeit \
    -noprompt \
    -storetype JKS
    
# RUN $JAVA_HOME/bin/keytool -import -trustcacerts -alias ldap-ca \
#     -file ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt \
#     -keystore ${RANGER_USER_HOME}/conf/cert/truststore.jks \
#     -storepass changeit -noprompt -storetype JKS && \
#     $JAVA_HOME/bin/keytool -import -trustcacerts -alias ldap-ca \
#     -file ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt \
#     -keystore ${RANGER_USER_HOME}/conf/cert/unixauthservice.jks \
#     -storepass changeit -noprompt -storetype JKS

    # RUN rm /tmp/ldap-ca.crt
# ---------------------------------------------------
# Permissions and Compatibility
# ---------------------------------------------------
RUN find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    # Ensure ranger user owns the source AND the new cacerts file we copied
    chown -R ranger:ranger ${RANGER_USER_HOME} ${HADOOP_HOME} /opt/java/openjdk/lib/security/cacerts

# ---------------------------------------------------
# Entrypoint Setup
# ---------------------------------------------------
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh
RUN chmod +x ${RANGER_USER_HOME}/entrypoint.sh

USER root
WORKDIR ${RANGER_USER_HOME}
ENTRYPOINT ["./entrypoint.sh"]