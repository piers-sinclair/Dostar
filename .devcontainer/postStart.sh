#!/bin/bash

echo "[postStart] Starting services..."
if ! docker compose up -d; then
  echo "WARNING: docker compose up failed — PostgreSQL may not be available"
  echo "  Check: docker ps"
  echo "  Fix:   docker compose up -d"
  exit 0
fi

NETWORK=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')_default
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
fi
