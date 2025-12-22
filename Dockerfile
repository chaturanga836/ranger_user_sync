FROM eclipse-temurin:8-jdk

# ---------------------------------------------------
# Environment
# ---------------------------------------------------
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/opt/ranger-usersync/run
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV CLASSPATH=$CLASSPATH:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*

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
        wget && \
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
# Copy entire ranger-usersync directory
# ---------------------------------------------------
COPY ranger-usersync/ ${RANGER_USER_HOME}/

# ---------------------------------------------------
# Required directories
# ---------------------------------------------------
RUN mkdir -p ${RANGER_RUN_DIR} \
             ${RANGER_USER_HOME}/logs \
             ${RANGER_USER_HOME}/conf/cert

# ---------------------------------------------------
# Make all scripts executable
# ---------------------------------------------------
RUN find ${RANGER_USER_HOME} -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

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
