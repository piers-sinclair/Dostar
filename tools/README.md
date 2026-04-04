# Dostar CLI (`dostar`)

The `dostar` CLI is a .NET global tool for scaffolding and managing Dostar modular monolith projects.

Source lives in `tools/Dostar.Cli/`.

## Build and install locally

```bash
# Pack the tool (from repo root or tools/Dostar.Cli/)
dotnet pack tools/Dostar.Cli

# Install globally from the local nupkg
dotnet tool install -g Dostar.Cli --add-source tools/Dostar.Cli/bin/Release/
```

After installation, the `dostar` command is available on your PATH.

## Usage

```bash
dostar --help
dostar --version
```

## Uninstall

```bash
dotnet tool uninstall -g Dostar.Cli
```
