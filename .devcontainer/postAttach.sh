#!/bin/bash

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

if timeout 2 bash -c 'echo > /dev/tcp/db/5432' 2>/dev/null; then
  printf "  %-14s ✓\n" "PostgreSQL"
else
  printf "  %-14s ✗  →  docker compose up -d\n" "PostgreSQL"
fi

check_tool "dostar CLI"  "dotnet tool install -g Dostar.Cli"  dostar   --version
check_tool "lefthook"    "lefthook install"                    lefthook version
check_tool ".NET SDK"    "(reinstall devcontainer)"            dotnet   --version
check_tool "Node"        "(reinstall devcontainer)"            node     --version

echo "$SEP"
printf "  %-14s %s\n" "setup log:" "cat .devcontainer/postCreate.log"
printf "  %-14s %s\n" "re-check:"  "health"
echo ""
