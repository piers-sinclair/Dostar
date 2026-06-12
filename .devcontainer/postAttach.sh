#!/bin/bash

SEP="────────────────────────────────────────────────────"

check_tool() {
  local label=$1
  local fix=$2
  local binary=$3
  shift 3
  if command -v "$binary" > /dev/null 2>&1; then
    local version
    version=$("$binary" "$@" 2>/dev/null | head -1)
    printf "  %-14s ✓  %s\n" "$label" "$version"
  else
    printf "  %-14s ✗  →  %s\n" "$label" "$fix"
  fi
}

echo ""
echo "  $(basename "$(pwd)") environment"
echo "$SEP"

if pg_isready -h db -U dostar -q 2>/dev/null; then
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
