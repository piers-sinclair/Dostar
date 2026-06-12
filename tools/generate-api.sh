#!/usr/bin/env bash
# Regenerates the committed OpenAPI spec and the orval-generated TypeScript client in one step.
# Usage: bash tools/generate-api.sh
#
# Run this after any backend API change (new endpoint, changed request/response shape, etc.)
# to keep backend/Dostar.Api.json and frontend/src/api/generated/index.ts in sync.

set -euo pipefail

echo "=== Building backend (regenerates backend/Dostar.Api.json) ==="
dotnet build backend/Dostar.Api/Dostar.Api.csproj -c Release

echo ""
echo "=== Generating frontend API client ==="
cd frontend && pnpm generate:api

echo ""
echo "Done. Commit any changes to backend/Dostar.Api.json and frontend/src/api/generated/index.ts."
