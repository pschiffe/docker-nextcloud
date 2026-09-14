#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: smoke-test.sh IMAGE}
container="nextcloud-smoke-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"

cleanup() {
  status=$?
  trap - EXIT
  if (( status != 0 )); then
    docker logs "$container" 2>&1 || true
  fi
  docker rm --force --volumes "$container" >/dev/null 2>&1 || true
  exit "$status"
}
trap cleanup EXIT

docker run --detach --name "$container" "$image" >/dev/null

for _ in $(seq 1 60); do
  if docker exec "$container" \
    curl --fail --silent --show-error http://localhost/status.php >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker exec "$container" \
  curl --fail --silent --show-error http://localhost/status.php >/dev/null

docker top "$container" | grep -q '[a]pache2'

docker exec "$container" \
  curl --head --silent http://localhost/status.php \
  | tr -d '\r' \
  | grep -qx 'Server: Apache'
docker top "$container" | grep -q '[c]rond'

docker exec "$container" \
  curl --fail --silent --show-error http://localhost/server-status \
  | grep -q 'ExtendedStatus On'

# Forwarded requests must not gain access via the proxy's private address.
status=$(docker exec "$container" curl --silent --output /dev/null --write-out '%{http_code}' \
  --header 'X-Forwarded-For: 198.51.100.23' http://localhost/server-status?auto)
[[ $status == 403 ]]

# PHP must see the connection peer, leaving proxy trust decisions to Nextcloud.
docker exec -i "$container" sh -c 'cat > /var/www/html/proxy-smoke.php' <<'PHP'
<?php echo $_SERVER['REMOTE_ADDR'];
PHP
remote_addr=$(docker exec "$container" curl --fail --silent --show-error \
  --header 'X-Real-IP: 198.51.100.23' http://127.0.0.1/proxy-smoke.php)
[[ $remote_addr == 127.0.0.1 ]]
docker exec "$container" rm /var/www/html/proxy-smoke.php
