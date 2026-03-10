# add-package

Add a NuGet or npm package to the project after verifying its licence is permissive enough for commercial closed-source use.

## Usage

```
/add-package <package-name> [--project <csproj-path>] [--npm] [--dev]
```

- `--project` — path to the `.csproj` file (NuGet). Defaults to prompting you to specify.
- `--npm` — treat the package as an npm package instead of NuGet.
- `--dev` — (npm only) install as a dev dependency.

## What this skill does

1. **Fetch licence metadata**
   - NuGet: query `https://api.nuget.org/v3-flatcontainer/<id>/index.json` for the latest version, then fetch the `.nuspec` and extract the `<license>` element.
   - npm: query `https://registry.npmjs.org/<id>/latest` and read the `license` field.

2. **Validate the licence** against the project's allowed list:
   - Allowed: `MIT`, `Apache-2.0`, `BSD-2-Clause`, `BSD-3-Clause`, `ISC`, `0BSD`, `Unlicense`, `CC0-1.0`
   - **Block and report** any other licence (GPL, LGPL, AGPL, SSPL, BSL, EUPL, etc.)

3. **Install the package** (only if the licence check passes):
   - NuGet: `dotnet add <project> package <package-name>`
   - npm: `pnpm add [-D] <package-name>` (run from `frontend/`)

4. **Confirm** the installed version and licence to the user.

## Licence policy reminder

All dependencies must be **free for commercial use in closed-source projects**.
Acceptable: MIT, Apache-2.0, BSD-*, ISC, and equivalently permissive licences.
Blocked: GPL, LGPL, AGPL, SSPL, BSL, or any licence that restricts commercial or proprietary use.

If you are unsure about a licence not on either list, **ask the user before installing**.
