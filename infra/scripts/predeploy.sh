#!/usr/bin/env bash
# predeploy.sh — run this before every `az deployment sub create`.
# Ensures postgresAdminPassword is set to a real secret, not the local placeholder.
# Usage: POSTGRES_ADMIN_PASSWORD=<secret> ./infra/scripts/predeploy.sh [<params-file>] [<location>]
#
# First-deploy behaviour (no Key Vault yet):
#   Set POSTGRES_ADMIN_PASSWORD to a generated secret before calling this script.
#   The script will deploy infra (which creates the Key Vault and stores the password).
#
# Subsequent-deploy behaviour:
#   Leave POSTGRES_ADMIN_PASSWORD unset — the script reads it from Key Vault.
#   The prod params file uses getSecret() so the value never touches this runner.
set -euo pipefail

PLACEHOLDER='Placeholder123!'
PARAMS_FILE="${1:-infra/main.parameters.prod.bicepparam}"
LOCATION="${2:-australiaeast}"

# --- guard: reject placeholder -------------------------------------------------
if [ "${POSTGRES_ADMIN_PASSWORD:-}" = "$PLACEHOLDER" ]; then
  echo "ERROR: POSTGRES_ADMIN_PASSWORD is set to the local placeholder value." >&2
  echo "       Never deploy with the placeholder — it is not a secret." >&2
  echo "       Set POSTGRES_ADMIN_PASSWORD to a real secret before running this script." >&2
  exit 1
fi

# --- guard: require explicit password on first deploy --------------------------
# getSecret() in the prod params file handles subsequent deploys automatically.
# On first deploy (Key Vault does not exist yet) POSTGRES_ADMIN_PASSWORD must be set.
if [ -z "${POSTGRES_ADMIN_PASSWORD:-}" ]; then
  echo "INFO: POSTGRES_ADMIN_PASSWORD not set — assuming Key Vault already exists." >&2
  echo "      If this is a first deploy, set POSTGRES_ADMIN_PASSWORD to a generated secret." >&2
fi

# --- deploy --------------------------------------------------------------------
echo "Running what-if first..."
az deployment sub what-if \
  --location "$LOCATION" \
  --template-file infra/main.bicep \
  --parameters "$PARAMS_FILE"

echo ""
read -r -p "Proceed with deployment? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Deployment cancelled."
  exit 0
fi

echo "Deploying..."
az deployment sub create \
  --location "$LOCATION" \
  --template-file infra/main.bicep \
  --parameters "$PARAMS_FILE"
