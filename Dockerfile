FROM openjdk:11-jre-slim

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RANGER_USER_HOME=/opt/ranger-usersync

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-dev python3-pip bash procps net-tools && \
    rm -rf /var/lib/apt/lists/*

# Copy Ranger UserSync code into container
COPY ranger-usersync/ ${RANGER_USER_HOME}

WORKDIR ${RANGER_USER_HOME}

# Ensure all scripts are executable
RUN chmod +x *.sh setup.py

# Run the UserSync setup script (prepares conf/ and libraries)
RUN ./setup.sh

# Expose default UserSync port
EXPOSE 5151

# Start the UserSync service when the container starts
CMD ["bash", "ranger-usersync-services.sh", "start"]
