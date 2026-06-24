#!/usr/bin/env bash
# Discovers and runs backend .NET unit or integration tests.
# Usage: bash tools/run-tests.sh <unit|integration>
#
# This script is used by the backend CI workflow. It intentionally does not run
# frontend Vitest tests or Playwright UI tests; use tools/ci-check.sh for the
# full local preflight across backend, frontend, UI, and security checks.
#
# For each matching test assembly under backend/Modules/ and backend/Dostar.SharedKernel.UnitTests/:
#   - Unit tests run through coverlet, scoped to implementation assemblies, with an 80% line threshold.
#   - Integration tests run through dotnet test without a coverage gate; they protect HTTP/DB behavior.
#
# Exits non-zero if any project fails its tests or, for unit tests, the coverage threshold.

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

  echo ""
  echo "=== ${dll_name} ==="

  if [[ "$type" == "integration" ]]; then
    dotnet test "${project_dir}" \
      --no-build \
      -c Release \
      --logger trx \
      --results-directory "${results_dir}" \
      || exit_code=$?
    continue
  fi

  # e.g. Dostar.Todos.UnitTests -> Dostar.Todos  -> [Dostar.Todos.Implementation]*
  # e.g. Dostar.SharedKernel.UnitTests -> Dostar.SharedKernel -> [Dostar.SharedKernel*]*
  module_prefix="${dll_name%.${suffix}}"
  # Unit tests scope to Implementation only — Contracts (interfaces/DTOs) have no testable logic.
  impl_dir="${project_dir}/../${module_prefix}.Implementation"
  if [[ -d "$impl_dir" ]]; then
    include="[${module_prefix}.Implementation]*"
  else
    include="[${module_prefix}]*"
  fi
  output="${results_dir}/${dll_name}/coverage.cobertura.xml"

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
