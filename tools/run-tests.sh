#!/usr/bin/env bash
# Discovers and runs all unit or integration tests with coverlet coverage.
# Usage: bash tools/run-tests.sh <unit|integration>
#
# For each matching test assembly under backend/Modules/ and backend/Dostar.SharedKernel.UnitTests/:
#   - Runs coverlet wrapping dotnet test
#   - Scopes coverage to the module's assemblies only
#   - Enforces 80% line coverage threshold
#   - Service layer and infrastructure classes carry [ExcludeFromCodeCoverage] so unit tests
#     only measure pure logic (validators, domain rules); integration tests measure full stack
#
# Exits non-zero if any project fails its tests or threshold.

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

mapfile -t dlls < <(
  {
    find backend/Modules -path "*/bin/Release/net10.0/*.${suffix}.dll"
    find backend -path "*/bin/Release/net10.0/*.${suffix}.dll" ! -path "*/Modules/*"
  } | sort -u
)

if [[ ${#dlls[@]} -eq 0 ]]; then
  echo "No ${suffix} assemblies found." >&2
  exit 1
fi

echo "Found ${#dlls[@]} ${suffix} assembly(ies)."

exit_code=0

for dll in "${dlls[@]}"; do
  dll_name=$(basename "$dll" .dll)
  project_dir="${dll%%/bin/Release/*}"
  # e.g. Dostar.Todos.UnitTests -> Dostar.Todos  -> [Dostar.Todos.Implementation]*
  # e.g. Dostar.SharedKernel.UnitTests -> Dostar.SharedKernel -> [Dostar.SharedKernel*]*
  module_prefix="${dll_name%.${suffix}}"
  # Unit tests scope to Implementation only — Contracts (interfaces/DTOs) have no testable logic.
  # Integration tests scope broadly to measure the full stack.
  if [[ "$type" == "unit" ]]; then
    impl_dir="${project_dir}/../${module_prefix}.Implementation"
    if [[ -d "$impl_dir" ]]; then
      include="[${module_prefix}.Implementation]*"
    else
      include="[${module_prefix}]*"
    fi
  else
    include="[${module_prefix}*]*"
  fi
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
