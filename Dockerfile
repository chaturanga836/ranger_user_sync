FROM eclipse-temurin:11-jre-jammy

ENV RANGER_USER_HOME=/opt/ranger-usersync
ENV RANGER_RUN_DIR=/var/run/ranger

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip xmlstarlet curl bash procps \
        net-tools iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash ranger && \
    mkdir -p ${RANGER_USER_HOME} ${RANGER_RUN_DIR} && \
    chown -R ranger:ranger ${RANGER_USER_HOME} ${RANGER_RUN_DIR}

COPY ranger-usersync/ ${RANGER_USER_HOME}/
RUN chown -R ranger:ranger ${RANGER_USER_HOME}

WORKDIR ${RANGER_USER_HOME}

RUN find . -type f -name "*.sh" -exec chmod +x {} \;
RUN chmod +x setup.py
RUN ln -sf /usr/bin/python3 /usr/bin/python
RUN mkdir -p conf/cert logs

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ranger
ENTRYPOINT ["/entrypoint.sh"]
