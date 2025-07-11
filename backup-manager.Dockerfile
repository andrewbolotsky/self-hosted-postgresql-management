ARG BACKREST_VERSION="2.54.2"
FROM woblerr/pgbackrest:${BACKREST_VERSION}

WORKDIR /app
ARG GRAFANA_ADDRESS
ENV GRAFANA_ADDRESS=${GRAFANA_ADDRESS}

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3 \
        nano \
        python3-pip \
        postgresql-${PG_VERSION} \
        postgresql-contrib-${PG_VERSION} \
        cron \
        curl \
        unzip \
        redis-server \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN  curl -fsSL https://get.docker.com -o get-docker.sh &&\
     sh get-docker.sh


COPY --chmod=600 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./certs/pgbackrest /etc/pgbackrest/cert
COPY --chmod=755 --chown=${BACKREST_USER}:${BACKREST_GROUP} ./backup-manager/backup_prepare.sh /home/pgbackrest/backup_prepare.sh
COPY --chmod=755 --chown=${BACKREST_USER}:${BACKREST_GROUP} backup-manager .

RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

RUN mkdir -p /app/data/ && \
    chmod -R 755 /app && \
    chown -R ${BACKREST_USER}:${BACKREST_GROUP} /app/ &&  \
    chmod +x /app/scripts/*


USER ${BACKREST_USER}

ENV REDIS_URL=redis://localhost PYTHONUNBUFFERED=1

RUN reflex init && reflex export --frontend-only --no-zip && reflex db init

STOPSIGNAL SIGKILL

USER root

ENTRYPOINT ["/app/backup_prepare.sh"]