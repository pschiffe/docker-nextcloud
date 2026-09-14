# Nextcloud Docker Image with Cron

Based on the official example from https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/cron/apache

## Reverse proxy trust

Apache's `remoteip` configuration and module are disabled in this image.
PHP receives the connection peer address; Nextcloud alone resolves the client
address using `TRUSTED_PROXIES` and forwarded headers. This also applies when
Supervisor starts Apache: it does not depend on the upstream entrypoint's
`APACHE_DISABLE_REWRITE_IP` switch.

Set `TRUSTED_PROXIES` to a space-separated list of exact proxy addresses. With
host-networked Traefik connecting to a Docker bridge, these are that bridge's
host-side gateway addresses, not Traefik's container IP. Discover IPv4 and IPv6
gateways from Docker rather than trusting private address ranges. Pin
`traefik.docker.network` to the same backend network.

Apache access logs now report the connection peer (typically the bridge gateway).
Use Nextcloud's application logs or Traefik's access logs for the resolved client
IP. `/server-status` permits direct local/private scrapers, but rejects requests
carrying `X-Forwarded-For` or `X-Real-IP`, so proxying through an allowed gateway
does not expose the status endpoint.
