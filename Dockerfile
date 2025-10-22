FROM openjdk:11-jre-slim

# Set environment
ENV RANGER_HOME=/opt/ranger-usersync
ENV JAVA_HOME=/usr/local/openjdk-11
ENV PATH=$JAVA_HOME/bin:$PATH:$RANGER_HOME

# Create directories
RUN mkdir -p $RANGER_HOME
WORKDIR $RANGER_HOME

# Copy all UserSync files
COPY ranger-usersync/ $RANGER_HOME/

# Fix permissions and line endings (if copied from Windows)
RUN apt-get update && apt-get install -y dos2unix bash sudo \
    && dos2unix *.sh setup.py \
    && chmod +x *.sh setup.py \
    && apt-get clean

# Set JAVA_HOME for setup.sh
ENV JAVA_HOME=/usr/local/openjdk-11

# Run setup during build
RUN ./setup.sh

# Expose the default UserSync port
EXPOSE 5151

# Start UserSync service
CMD ["./start.sh"]
