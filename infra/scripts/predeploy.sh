#!/bin/bash
set -e

# Reads the postgres admin password from Key Vault if the vault already exists,
# otherwise generates a new one. Writes the result into the azd environment so
# azd passes it as a Bicep parameter on provision.

WORKLOAD="${WORKLOAD:-dostar}"
ENV_NAME="${AZURE_ENV_NAME}"
REGION="${REGION:-aue}"
INSTANCE="${INSTANCE:-001}"
KV_NAME="kv-${WORKLOAD}-${ENV_NAME}-${REGION}-${INSTANCE}"

echo "Looking for existing postgres password in Key Vault '$KV_NAME'..."

PASSWORD=$(az keyvault secret show \
  --vault-name "$KV_NAME" \
  --name "postgres-admin-password" \
  --query "value" -o tsv 2>/dev/null) || PASSWORD=""

if [ -z "$PASSWORD" ]; then
  echo "No existing password found — generating a new one for first deploy."
  PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
fi

azd env set postgresAdminPassword "$PASSWORD"
