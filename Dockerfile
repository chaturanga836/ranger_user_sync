FROM openjdk:11-jre-slim

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RANGER_USER_HOME=/opt/ranger-usersync

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-dev python3-pip bash procps && \
    rm -rf /var/lib/apt/lists/*

# Copy Ranger UserSync code into container
COPY . ${RANGER_USER_HOME}
WORKDIR ${RANGER_USER_HOME}

# Make setup and service scripts executable
RUN chmod +x setup.py ranger-usersync-services.sh start.sh stop.sh set_globals.sh

# Run the Ranger UserSync setup
RUN python3 setup.py

# Expose default port (not always needed but useful)
EXPOSE 5151

# Start the UserSync service
CMD ["bash", "ranger-usersync-services.sh", "start"]
