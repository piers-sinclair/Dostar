#!/usr/bin/env bash
# Discovers and runs all module unit or integration tests with coverlet coverage.
# Usage: bash tools/run-tests.sh <unit|integration>
#
# For each matching test assembly under backend/Modules/:
#   - Runs coverlet wrapping dotnet test
#   - Scopes coverage to the module's assemblies only
#   - Enforces 80% line coverage threshold
#
# Exits non-zero if any module fails its tests or threshold.

set -uo pipefail

type=${1:-}
if [[ "$type" != "unit" && "$type" != "integration" ]]; then
  echo "Usage: $0 <unit|integration>" >&2
  exit 1
fi

if [[ "$type" == "unit" ]]; then
  suffix="UnitTests"
  results_dir="TestResults/unit"
else
  suffix="IntegrationTests"
  results_dir="TestResults/integration"
fi

mapfile -t dlls < <(find backend/Modules -path "*/bin/Release/net10.0/*.${suffix}.dll" | sort)

if [[ ${#dlls[@]} -eq 0 ]]; then
  echo "No ${suffix} assemblies found under backend/Modules/." >&2
  exit 1
fi

echo "Found ${#dlls[@]} ${suffix} assembly(ies)."

exit_code=0

for dll in "${dlls[@]}"; do
  dll_name=$(basename "$dll" .dll)
  project_dir="${dll%%/bin/Release/*}"
  # e.g. Dostar.Todos.UnitTests -> Dostar.Todos  -> [Dostar.Todos.*]*
  module_prefix="${dll_name%.${suffix}}"
  include="[${module_prefix}.*]*"
  output="${results_dir}/${dll_name}/coverage.cobertura.xml"

  echo ""
  echo "=== ${dll_name} ==="

  ./tools/coverlet "$dll" \
    --target dotnet \
    --targetargs "test ${project_dir} --no-build -c Release --logger trx --results-directory ${results_dir}" \
    --format cobertura \
    --output "$output" \
    --include "$include" \
    --exclude-by-file "**/Migrations/**" \
    --threshold 80 --threshold-type line --threshold-stat total \
    || exit_code=$?
done

exit $exit_code
