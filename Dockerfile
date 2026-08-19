FROM nextcloud:33

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /
COPY apache-status.conf /etc/apache2/conf-available/

RUN sed -i 's/combined/combined env=!dontlog/' /etc/apache2/sites-available/000-default.conf \
  && sed -i 's/vhost_combined/vhost_combined env=!dontlog/' /etc/apache2/conf-available/other-vhosts-access-log.conf \
  && a2enconf apache-status

ENV NEXTCLOUD_UPDATE=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl --fail --silent --show-error http://localhost/status.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
