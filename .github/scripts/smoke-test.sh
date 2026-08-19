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
  docker rm --force "$container" >/dev/null 2>&1 || true
  exit "$status"
}
trap cleanup EXIT

docker image inspect "$image" --format '{{json .Config.Healthcheck.Test}}' \
  | grep -q 'status.php'

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
