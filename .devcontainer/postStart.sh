#!/bin/bash
exec > >(tee .devcontainer/postStart.log) 2>&1

# Fix docker socket access so `docker` commands work inside the container without sudo.
# Two cases:
#   - Non-zero GID socket: groupmod aligns the docker group GID with the host socket.
#   - Root-owned socket (GID 0): chmod a+rw opens it for all users (local dev only).
# Both run every start because the socket GID is host-specific.
if [ -S /var/run/docker.sock ]; then
  sudo chmod a+rw /var/run/docker.sock 2>/dev/null || true
  SOCK_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo "")
  if [ -n "$SOCK_GID" ] && [ "$SOCK_GID" != "0" ]; then
    CURRENT_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "")
    if [ "$SOCK_GID" != "$CURRENT_GID" ]; then
      sudo groupmod -g "$SOCK_GID" docker 2>/dev/null \
        || sudo groupadd -g "$SOCK_GID" docker 2>/dev/null \
        || true
      sudo usermod -aG docker vscode 2>/dev/null || true
    fi
  fi
fi

echo "[postStart] Starting services..."
if ! docker compose up -d; then
  echo "WARNING: docker compose up failed — PostgreSQL may not be available"
  echo "  Check: docker ps"
  echo "  Fix:   docker compose up -d"
  exit 0
fi

# Discover the compose network from the running db container instead of computing its name,
# so the correct network is used regardless of compose project name normalization.
echo "[postStart] Discovering compose network..."
DB_CONTAINER=""
for i in 1 2 3; do
  DB_CONTAINER=$(docker compose ps --quiet db 2>/dev/null | head -1)
  [ -n "$DB_CONTAINER" ] && break
  sleep 1
done

if [ -z "$DB_CONTAINER" ]; then
  echo "WARNING: db container not found — PostgreSQL may not be available"
  echo "  Check: docker compose ps"
  echo "  Fix:   docker compose up -d"
  exit 0
fi

NETWORK=$(docker inspect "$DB_CONTAINER" \
  --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null \
  | tr ' ' '\n' | grep '_default$' | head -1)

if [ -z "$NETWORK" ]; then
  echo "WARNING: could not determine compose network — PostgreSQL may not be available"
  echo "  Check: docker inspect $DB_CONTAINER"
  exit 0
fi

echo "[postStart] Connecting to network: $NETWORK"

CONNECTED=false
for i in 1 2 3 4 5; do
  RESULT=$(docker network connect "$NETWORK" "$(cat /etc/hostname)" 2>&1)
  if [ $? -eq 0 ] || echo "$RESULT" | grep -q "already exists"; then
    CONNECTED=true
    break
  fi
  echo "[postStart]   attempt $i/5: $RESULT"
  sleep 2
done

if [ "$CONNECTED" = false ]; then
  echo "WARNING: failed to connect to $NETWORK after 5 attempts — database may be unreachable"
  echo "  Check: docker network ls"
  echo "  Fix:   docker network connect $NETWORK \$(cat /etc/hostname)"
  exit 0
fi

# Wait for PostgreSQL to accept connections before running migrations.
PG_READY=false
for i in $(seq 1 15); do
  if timeout 2 bash -c 'echo > /dev/tcp/db/5432' 2>/dev/null; then
    PG_READY=true
    break
  fi
  echo "[postStart] Waiting for PostgreSQL... ($i/15)"
  sleep 2
done

if [ "$PG_READY" = false ]; then
  echo "WARNING: PostgreSQL did not become ready — skipping migrations"
  echo "  Check: docker compose ps"
  echo "  Fix:   bash tools/run-migrations.sh"
  exit 0
fi

echo "[postStart] PostgreSQL is reachable ✓"

echo "[postStart] Running database migrations..."
if ! bash tools/run-migrations.sh; then
  echo "WARNING: migrations failed — run: bash tools/run-migrations.sh"
  echo "  The app may not start correctly until migrations are applied."
fi
