#!/usr/bin/env bash
# Runs the same checks as the CI pipeline locally.
# Usage: bash tools/ci-check.sh
#
# Use this before opening a PR when GitHub Actions minutes are unavailable,
# or as a manual pre-flight check before pushing.
#
# Prerequisites: dotnet, pnpm, trivy, opengrep must be on PATH.
#   trivy:    https://trivy.dev/latest/getting-started/installation/
#   opengrep: pip install opengrep

set -euo pipefail

echo "=== Backend: build ==="
dotnet build -c Release

echo ""
echo "=== Backend: unit tests ==="
bash tools/run-tests.sh unit

echo ""
echo "=== Backend: integration tests ==="
bash tools/run-tests.sh integration

echo ""
echo "=== Security: Trivy ==="
trivy fs --exit-code 1 .

echo ""
echo "=== Security: OpenGrep ==="
opengrep ci --config auto

echo ""
echo "All checks passed."
