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
ENV CLASSPATH=$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*

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
        iputils-ping \
        wget ldap-utils openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Install Hadoop libraries
# ---------------------------------------------------
RUN mkdir -p $HADOOP_HOME && \
    wget -qO- https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME


RUN mkdir -p /opt/java/openjdk/lib/security && \
    ln -s /etc/ssl/certs/java/cacerts /opt/java/openjdk/lib/security/cacerts
# ---------------------------------------------------
# Create ranger user
# ---------------------------------------------------
RUN useradd -ms /bin/bash ranger

# ---------------------------------------------------
# Copy entire ranger-usersync directory
# ---------------------------------------------------
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# ---------------------------------------------------
# Required directories & Certificate Setup
# ---------------------------------------------------
# We create the folder FIRST, then run keytool
RUN mkdir -p ${RANGER_RUN_DIR} \
             ${RANGER_USER_HOME}/logs \
             ${RANGER_USER_HOME}/conf/cert \
             ${RANGER_USER_HOME}/usersync/conf/cert

             
# Copy the CA cert from your host folder to the image

COPY certs/tls.crt ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt


# FIX: Create BOTH Truststore files. 
# The log showed unixauthservice.jks failed because of a password mismatch.
# We generate them here with 'changeit' to match your XML.
RUN $JAVA_HOME/bin/keytool -import -trustcacerts -alias ldap-ca \
    -file ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt \
    -keystore ${RANGER_USER_HOME}/conf/cert/truststore.jks \
    -storepass changeit -noprompt -storetype JKS && \
    $JAVA_HOME/bin/keytool -import -trustcacerts -alias ldap-ca \
    -file ${RANGER_USER_HOME}/conf/cert/ldap-ca.crt \
    -keystore ${RANGER_USER_HOME}/conf/cert/unixauthservice.jks \
    -storepass changeit -noprompt -storetype JKS

# ---------------------------------------------------
# Permissions and Compatibility
# ---------------------------------------------------
RUN find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    # Dynamically find the cacerts path for chown
    CACERT_PATH=$(find $JAVA_HOME -name cacerts) && \
    chown -R ranger:ranger ${RANGER_USER_HOME} ${HADOOP_HOME} $CACERT_PATH

# ---------------------------------------------------
# Python compatibility
# ---------------------------------------------------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------------------------------------------------
# Set permissions
# ---------------------------------------------------
RUN chown -R ranger:ranger ${RANGER_USER_HOME} $HADOOP_HOME

# ---------------------------------------------------
# Copy and set entrypoint
# ---------------------------------------------------
COPY entrypoint.sh ${RANGER_USER_HOME}/entrypoint.sh
RUN chmod +x ${RANGER_USER_HOME}/entrypoint.sh

# ---------------------------------------------------
# Use root to generate JCEKS; drop to ranger for runtime
# ---------------------------------------------------
USER root
WORKDIR ${RANGER_USER_HOME}
ENTRYPOINT ["./entrypoint.sh"]