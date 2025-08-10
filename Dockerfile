FROM python:3.13-alpine3.21 AS builder

RUN apk update \
&& apk add --no-cache curl gcc build-base linux-headers

WORKDIR /app

COPY autoremovetorrents /app/autoremove-torrents/autoremovetorrents
COPY setup.py /app/autoremove-torrents/setup.py
COPY README.rst /app/autoremove-torrents/README.rst

RUN cd autoremove-torrents \
    && pip install setuptools \
    && pip install PyYAML \
    && pip install requests \
    && pip install deluge_client \
    && pip install enum34 \
    && pip install ply \
    && pip install psutil \
    && python setup.py install

# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.34/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=e8631edc1775000d119b70fd40339a7238eece14 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

FROM python:3.13-alpine3.21

COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages

RUN addgroup -g 1000 nonroot \
    && adduser -u 1000 -G nonroot -D nonroot

USER nonroot
WORKDIR /app

COPY --from=builder /usr/local/bin/autoremove-torrents /usr/local/bin/autoremove-torrents
COPY --from=builder /usr/local/bin/supercronic /usr/local/bin/supercronic

# Configure cron
ENV ARGUMENTS="-c /app/config.yml -v"
ENV MINUTE=*
ENV HOUR=*
ENV DAY_OF_MONTH=*
ENV MONTH=*
ENV DAY_OF_WEEK=*

RUN echo "${MINUTE} ${HOUR} ${DAY_OF_MONTH} ${MONTH} ${DAY_OF_WEEK} /usr/local/bin/autoremove-torrents ${ARGUMENTS}" > /app/crontab

ENTRYPOINT ["/usr/local/bin/supercronic", "/app/crontab"]

