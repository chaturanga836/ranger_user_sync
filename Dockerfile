FROM openjdk:11-jdk-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-dev python3-pip bash procps net-tools && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME dynamically based on `java` path
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RANGER_USER_HOME=/opt/ranger-usersync

# Copy Ranger UserSync code into container
COPY ranger-usersync/ ${RANGER_USER_HOME}
WORKDIR ${RANGER_USER_HOME}

# Make scripts executable
RUN chmod +x *.sh setup.py

# Run setup.sh with correct JAVA_HOME
RUN bash -c "source /etc/environment && ./setup.sh"

# Expose port
EXPOSE 5151

# Start UserSync service
CMD ["bash", "ranger-usersync-services.sh", "start"]
