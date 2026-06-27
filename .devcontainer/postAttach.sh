#!/bin/bash

# git rev-parse --show-toplevel correctly returns the workspace root for both
# the main repo (/workspaces/Dostar) and linked worktrees (/workspaces/<name>).
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROJECT=$(basename "$ROOT")
SEP="────────────────────────────────────────────────────"

if [ -f "$ROOT/.devcontainer/.setup-in-progress" ]; then
  echo ""
  echo "  ⏳ $PROJECT — setup still running"
  echo "$SEP"
  echo "  postCreate.sh has not finished yet."
  echo ""
  printf "  %-14s %s\n" "watch log:" "tail -f .devcontainer/postCreate.log"
  printf "  %-14s %s\n" "re-check:"  "health"
  echo ""
  exit 0
fi

if [ -f "$ROOT/.devcontainer/.setup-failed" ]; then
  echo ""
  echo "  ❌ $PROJECT — setup failed"
  echo "$SEP"
  echo "  postCreate.sh exited with an error."
  echo ""
  printf "  %-14s %s\n" "see log:"   "cat .devcontainer/postCreate.log"
  printf "  %-14s %s\n" "retry:"     "bash .devcontainer/postCreate.sh"
  echo ""
  exit 0
fi

check_tool() {
  local label=$1
  local fix=$2
  local binary=$3
  shift 3
  if command -v "$binary" > /dev/null 2>&1; then
    local version
    version=$("$binary" "$@" 2>/dev/null | head -1 | sed 's/+.*//')
    printf "  %-14s ✓  %s\n" "$label" "$version"
  else
    printf "  %-14s ✗  →  %s\n" "$label" "$fix"
  fi
}

echo ""
echo "  $PROJECT environment"
echo "$SEP"

_COMPOSE_PROJECT=$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
if timeout 2 bash -c 'echo > /dev/tcp/db/5432' 2>/dev/null; then
  printf "  %-14s ✓\n" "PostgreSQL"
elif docker compose -p "$_COMPOSE_PROJECT" ps --quiet db 2>/dev/null | grep -q .; then
  printf "  %-14s ✗  →  docker network connect %s_default \$(cat /etc/hostname)\n" "PostgreSQL" "$_COMPOSE_PROJECT"
else
  printf "  %-14s ✗  →  docker compose up -d\n" "PostgreSQL"
fi

check_tool "dostar"   "dotnet tool install -g Dostar.Cli"  dostar   --version  # @no-substitute
check_tool "lefthook" "lefthook install"                    lefthook version

# Hooks live in the git common directory (shared across all worktrees).
_git_common=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
[[ "$_git_common" != /* ]] && _git_common="$ROOT/$_git_common"
if [ -f "${_git_common}/hooks/pre-commit" ]; then
  printf "  %-14s ✓\n" "git hooks"
else
  printf "  %-14s ✗  →  lefthook install\n" "git hooks"
fi

check_tool ".NET SDK" "(reinstall devcontainer)"            dotnet   --version
check_tool "Node"     "(reinstall devcontainer)"            node     --version
check_tool "trivy"    "(rebuild devcontainer image)"        trivy    --version
check_tool "opengrep" "(rebuild devcontainer image)"        opengrep --version
if [[ -x "${ROOT}/tools/coverlet" ]]; then
  printf "  %-14s ✓\n" "coverlet"
else
  printf "  %-14s ✗  →  %s\n" "coverlet" "dotnet tool install coverlet.console --tool-path ./tools"
fi

if find /home/vscode/.cache/ms-playwright -name 'chrome' -type f 2>/dev/null | grep -q .; then
  printf "  %-14s ✓\n" "playwright"
else
  printf "  %-14s ✗  →  %s\n" "playwright" "cd tests/Dostar.UITests && pnpm exec playwright install chromium"
fi

echo "$SEP"
printf "  %-14s %s\n" "setup log:" "cat .devcontainer/postCreate.log"
printf "  %-14s %s\n" "start log:" "cat .devcontainer/postStart.log"
printf "  %-14s %s\n" "re-check:"  "health"
echo ""
