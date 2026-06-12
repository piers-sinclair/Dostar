#!/bin/bash
set -e
exec > >(tee .devcontainer/postCreate.log) 2>&1

_finish() {
  if [ $? -ne 0 ]; then
    mv .devcontainer/.setup-in-progress .devcontainer/.setup-failed 2>/dev/null || true
    echo "[postCreate] Setup FAILED — check: cat .devcontainer/postCreate.log"
  else
    rm -f .devcontainer/.setup-in-progress
  fi
}
trap _finish EXIT

touch .devcontainer/.setup-in-progress
rm -f .devcontainer/.setup-failed

install_dotnet_tool() {
  local tool=$1
  if ! dotnet tool install -g "$tool" 2>/dev/null; then
    if ! dotnet tool update -g "$tool" 2>/dev/null; then
      echo "WARNING: could not install $tool — run: dotnet tool install -g $tool"
    fi
  fi
}

echo "[postCreate] Installing global tools..."
az bicep install || echo "WARNING: az bicep install failed — run: az bicep install"
install_dotnet_tool dotnet-ef
install_dotnet_tool Dostar.Cli
npm install -g @anthropic-ai/claude-code || echo "WARNING: claude-code install failed — run: npm install -g @anthropic-ai/claude-code"

echo "[postCreate] Restoring backend packages..."
dotnet restore

echo "[postCreate] Fixing permissions..."
sudo chown vscode:vscode frontend/node_modules 2>/dev/null || true
sudo chown -R vscode:vscode /home/vscode/.claude 2>/dev/null || true
ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json 2>/dev/null || true

echo "[postCreate] Installing frontend dependencies..."
cd frontend && pnpm install
cd ..

echo "[postCreate] Setting up git hooks..."
sudo ln -sf "$(node -e "const {getExePath}=require('$(pwd)/frontend/node_modules/lefthook/get-exe.js'); process.stdout.write(getExePath())")" /usr/local/bin/lefthook || \
  echo "WARNING: lefthook symlink failed — run: lefthook install"

echo "[postCreate] Configuring shell..."
bash .devcontainer/shell-profile.sh

echo "[postCreate] Done. Full log: cat .devcontainer/postCreate.log"
