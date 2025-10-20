# ===============================================
# Apache Ranger UserSync Dockerfile (v2.7.0)
# ===============================================
FROM openjdk:8-jdk

LABEL maintainer="buddika@example.com"
LABEL description="Apache Ranger UserSync 2.7.0"

# Set working directory
WORKDIR /opt/ranger-usersync

# Copy everything from your local artifact folder
COPY ranger-usersync/ /opt/ranger-usersync/

# Make all scripts executable
RUN chmod +x *.sh */*.sh || true

# Environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Default command: start UserSync
CMD ["./ranger-usersync-services.sh"]
