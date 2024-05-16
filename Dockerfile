FROM nextcloud:28

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /
COPY apache-status.conf /etc/apache2/conf-available/

RUN sed -i 's/combined/combined env=!dontlog/' /etc/apache2/sites-available/000-default.conf \
  && sed -i 's/vhost_combined/vhost_combined env=!dontlog/' /etc/apache2/conf-available/other-vhosts-access-log.conf \
  && a2enconf apache-status

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
