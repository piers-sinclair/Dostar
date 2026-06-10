#!/usr/bin/env bash
# Discovers and runs EF Core migrations for all modules that have a Migrations directory.
# Usage: bash tools/run-migrations.sh
#
# Relies on the module naming convention: Dostar.<Name>.Implementation -> <Name>DbContext.
# A module is skipped if its Implementation project has no Migrations directory.

set -euo pipefail

found=0

for project_dir in backend/Modules/*/Dostar.*.Implementation; do
  [ -d "$project_dir/Migrations" ] || continue

  # Dostar.Todos.Implementation -> TodosDbContext
  project_name=$(basename "$project_dir")
  module_name="${project_name#Dostar.}"
  module_name="${module_name%.Implementation}"
  context="${module_name}DbContext"

  echo "=== $context ==="
  dotnet ef database update \
    --project "$project_dir" \
    --startup-project backend/Dostar.Api \
    --context "$context"

  found=1
done

if [ "$found" -eq 0 ]; then
  echo "No modules with migrations found." >&2
  exit 1
fi
