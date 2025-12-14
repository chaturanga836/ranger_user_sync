FROM eclipse-temurin:11-jre-jammy

ENV RANGER_HOME=/opt/ranger
ENV USERSYNC_HOME=/opt/ranger-usersync
ENV RANGER_USER=ranger

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 xmlstarlet curl bash procps \
        net-tools iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create ranger user & group
RUN groupadd -r ranger && \
    useradd -r -g ranger -d /home/ranger -s /bin/bash ranger && \
    mkdir -p /home/ranger && \
    chown -R ranger:ranger /home/ranger

# Copy usersync distribution
COPY ranger-usersync /opt/ranger-usersync

# Ownership check logs (BUILD-TIME proof)
RUN echo "==== BUILD OWNERSHIP CHECK ====" && \
    ls -ld /opt/ranger-usersync && \
    ls -l /opt/ranger-usersync | head -n 20

# Ensure executable bits (safe)
RUN chmod +x /opt/ranger-usersync/*.sh

# Final ownership fix
RUN chown -R ranger:ranger /opt/ranger-usersync

# DO NOT RUN ANY SCRIPT
USER ranger
WORKDIR /opt/ranger-usersync

CMD ["sleep", "infinity"]
