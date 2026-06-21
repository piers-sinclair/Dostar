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

echo "[postCreate] Installing Trivy (CVE scanner)..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -qq && sudo apt-get install -y trivy \
  || echo "WARNING: trivy install failed — see https://trivy.dev/latest/getting-started/installation/"

echo "[postCreate] Installing OpenGrep (SAST)..."
latest=$(curl -sf "https://api.github.com/repos/opengrep/opengrep/releases/latest" \
  | grep '"tag_name"' | head -1 | cut -d'"' -f4)
curl -fsSL "https://github.com/opengrep/opengrep/releases/download/${latest}/opengrep_manylinux_x86" \
  -o /tmp/opengrep && chmod +x /tmp/opengrep && sudo mv /tmp/opengrep /usr/local/bin/opengrep \
  || echo "WARNING: opengrep install failed — see https://github.com/opengrep/opengrep/releases"

echo "[postCreate] Restoring backend packages..."
dotnet restore

echo "[postCreate] Installing coverlet (local test coverage tool)..."
dotnet tool install coverlet.console --tool-path ./tools \
  || echo "WARNING: coverlet install failed — run: dotnet tool install coverlet.console --tool-path ./tools"

echo "[postCreate] Fixing permissions..."
git config --global --add safe.directory /workspaces/Dostar
sudo chown vscode:vscode frontend/node_modules 2>/dev/null || true
sudo chown -R vscode:vscode /home/vscode/.claude 2>/dev/null || true
ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json 2>/dev/null || true

echo "[postCreate] Repairing git worktree pointers..."
# git worktree add writes OS-absolute paths. Rewrite each .git file to a repo-relative
# path so the worktree is usable on any OS or mount point (Linux/Windows/devcontainer).
for wt_git in .claude/worktrees/*/.git; do
  wt_dir=$(dirname "$wt_git")
  # Compute depth from repo root: .claude/worktrees/<name> = 3 levels deep
  printf 'gitdir: ../../../.git/worktrees/%s\n' "$(basename "$wt_dir")" > "$wt_git"
done
# Repair the reverse pointers (.git/worktrees/<name>/gitdir) to current container paths
git worktree repair 2>/dev/null || true

echo "[postCreate] Installing frontend dependencies..."
cd frontend && pnpm install
cd ..

echo "[postCreate] Setting up git hooks..."
sudo ln -sf "$(node -e "const {getExePath}=require('$(pwd)/frontend/node_modules/lefthook/get-exe.js'); process.stdout.write(getExePath())")" /usr/local/bin/lefthook || \
  echo "WARNING: lefthook symlink failed — run: lefthook install"
lefthook install || echo "WARNING: lefthook install failed — run: lefthook install"

echo "[postCreate] Configuring shell..."
bash .devcontainer/shell-profile.sh

echo "[postCreate] Done. Full log: cat .devcontainer/postCreate.log"
