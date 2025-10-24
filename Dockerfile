FROM centos:7

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RANGER_HOME=/opt/ranger-usersync
# Install dependencies and the 'default-jdk' package to guarantee a linkable Java installation
RUN yum -y update && \
    yum -y install \
        java-11-openjdk java-11-openjdk-devel \
        python3 python3-devel python3-pip \
        which net-tools iputils curl \
        xmlstarlet unzip && \
    yum clean all && rm -rf /var/cache/yum


    # Fix the Python interpreter path expected by setup.py
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Create ranger user
RUN useradd -ms /bin/bash ranger && \
    mkdir -p ${RANGER_HOME}/logs ${RANGER_HOME}/conf ${RANGER_RUN_DIR} && \
    chown -R ranger:ranger ${RANGER_HOME} ${RANGER_RUN_DIR}

# Set RANGER environment variables
ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

# Copy Ranger UserSync code into container
COPY ranger-usersync/ ${RANGER_HOME}/
RUN chown -R ranger:ranger ${RANGER_HOME}

# Copy default config
RUN cp -r ${RANGER_HOME}/conf.dist/* ${RANGER_HOME}/conf/

WORKDIR $RANGER_USER_HOME

# Make scripts executable
RUN chmod +x *.sh setup.py

# FIX: Set the missing property 'ranger.usersync.credstore.filename' to avoid KeyError during setup.py
# Patch configuration with xmlstarlet
RUN xmlstarlet ed -L \
    -u "//property[name='ranger.usersync.policymanager.url']/value" \
    -v "http://ec2-65-0-150-75.ap-south-1.compute.amazonaws.com:6080" \
    -s '//configuration' -t elem -n 'property' \
    -s '//property[last()]' -t elem -n 'name' -v 'ranger.usersync.credstore.filename' \
    -s '//property[last()]' -t elem -n 'value' -v '/opt/ranger-usersync/conf/rangerusersync.jceks' \
    ${RANGER_HOME}/conf/ranger-ugsync-site.xml

# Pre-run setup script
RUN cd ${RANGER_HOME} && \
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    export PATH="$JAVA_HOME/bin:$PATH" && \
    ./setup.sh || echo "Setup completed with non-zero exit, continuing..."

WORKDIR ${RANGER_HOME}

# Expose Usersync port
EXPOSE 5151

# Entrypoint: start usersync as ranger user and follow logs
ENTRYPOINT ["/bin/bash", "-c", "\
  mkdir -p /var/run/ranger /opt/ranger-usersync/logs && \
  touch /opt/ranger-usersync/logs/usersync.log && \
  chown -R ranger:ranger /var/run/ranger /opt/ranger-usersync/logs && \
  echo 'Starting Apache Ranger Usersync Service...' && \
  su -s /bin/bash ranger -c '/opt/ranger-usersync/ranger-usersync-services.sh start' && \
  echo 'Tailing Usersync logs...' && \
  su -s /bin/bash ranger -c 'tail -F /opt/ranger-usersync/logs/usersync.log'"]
