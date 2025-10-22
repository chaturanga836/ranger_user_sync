FROM openjdk:11-jdk-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-dev python3-pip bash procps net-tools && \
    rm -rf /var/lib/apt/lists/*

# Create ranger user
RUN useradd -ms /bin/bash ranger

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RANGER_USER_HOME=/opt/ranger-usersync

# Copy Ranger UserSync code
COPY ranger-usersync/ ${RANGER_USER_HOME}

# Set ownership to ranger user
RUN chown -R ranger:ranger ${RANGER_USER_HOME}

# Switch to ranger user
USER ranger
WORKDIR ${RANGER_USER_HOME}

# Make scripts executable
RUN chmod +x *.sh setup.py

# Run setup.sh as ranger user
RUN ./setup.sh

# Expose UserSync port
EXPOSE 5151

# Start UserSync service
CMD ["bash", "ranger-usersync-services.sh", "start"]
