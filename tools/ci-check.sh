#!/usr/bin/env bash
# Runs the same checks as the CI pipeline locally.
# Usage: bash tools/ci-check.sh
#
# Use this before opening a PR when GitHub Actions minutes are unavailable,
# or as a manual pre-flight check before pushing.
#
# Prerequisites: dotnet, pnpm, trivy, opengrep must be on PATH.
#   trivy:    https://trivy.dev/latest/getting-started/installation/
#   opengrep: https://github.com/opengrep/opengrep/releases

set -euo pipefail

echo "=== Backend: build ==="
dotnet build -c Release

echo ""
echo "=== Backend: install coverlet ==="
[[ -x ./tools/coverlet ]] || dotnet tool install coverlet.console --tool-path ./tools

echo ""
echo "=== Backend: unit tests ==="
bash tools/run-tests.sh unit

echo ""
echo "=== Backend: integration tests ==="
bash tools/run-tests.sh integration

echo ""
echo "=== Frontend: install ==="
(cd frontend && pnpm install --frozen-lockfile)

echo ""
echo "=== Frontend: lint ==="
(cd frontend && pnpm lint)

echo ""
echo "=== Frontend: format ==="
(cd frontend && pnpm format:check)

echo ""
echo "=== Frontend: generated API ==="
(cd frontend && pnpm generate:api && git diff --exit-code src/shared/api/generated/)

echo ""
echo "=== Frontend: unit tests ==="
(cd frontend && pnpm test)

echo ""
echo "=== Frontend: build ==="
(cd frontend && pnpm build)

echo ""
echo "=== UI: Playwright ==="
mkdir -p TestResults
(cd tests/Dostar.UITests && pnpm install --frozen-lockfile && pnpm exec playwright install chromium)

(cd frontend && pnpm preview --port 5173 > ../TestResults/frontend-preview.log 2>&1) &
preview_pid=$!
trap 'kill ${preview_pid} 2>/dev/null || true' EXIT

for i in $(seq 1 10); do
  if curl -sf http://localhost:5173 >/dev/null; then
    break
  fi
  if [[ "$i" == "10" ]]; then
    echo "Frontend never started on port 5173" >&2
    exit 1
  fi
  echo "Waiting for frontend... (${i}/10)"
  sleep 2
done

(cd tests/Dostar.UITests && UI_BASE_URL=http://localhost:5173 pnpm exec playwright test)
kill "${preview_pid}" 2>/dev/null || true
trap - EXIT

echo ""
echo "=== Security: Trivy ==="
trivy fs --exit-code 1 .

echo ""
echo "=== Security: OpenGrep ==="
opengrep ci --config auto

echo ""
echo "All checks passed."
