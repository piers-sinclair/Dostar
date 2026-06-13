#!/bin/bash

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

sleep 1
if timeout 5 bash -c 'echo > /dev/tcp/db/5432' 2>/dev/null; then
  echo "[postStart] PostgreSQL is reachable ✓"
else
  echo "[postStart] Connected to $NETWORK but postgres is still starting — run: health"
fi
