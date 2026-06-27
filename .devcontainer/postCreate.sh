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

# Installs a global dotnet tool only if the binary is not already on PATH.
# Tools pre-installed in the image (dotnet-ef, dostar) are skipped automatically.
install_dotnet_tool() {
  local tool=$1
  local binary="${2:-$tool}"
  if command -v "$binary" > /dev/null 2>&1; then
    echo "[postCreate] $binary already on PATH — skipping install"
    return 0
  fi
  if ! dotnet tool install -g "$tool" 2>/dev/null; then
    if ! dotnet tool update -g "$tool" 2>/dev/null; then
      echo "WARNING: could not install $tool — run: dotnet tool install -g $tool"
    fi
  fi
}

# Must be first: git validates the CWD's .git pointer before any subcommand,
# even --global ones. Running from $HOME avoids that check entirely.
echo "[postCreate] Configuring git..."
git -C "$HOME" config --global --add safe.directory '*'

echo "[postCreate] Repairing git worktree pointers..."
if [ -d ".git" ]; then
  # Main repo: rewrite each linked worktree's .git file to a relative path so it
  # resolves correctly on any OS or mount point (Linux/Windows/devcontainer).
  # Do NOT run `git worktree repair` here — it rewrites gitdir files inside
  # .git/worktrees/ with container paths, which breaks host-side git and causes
  # git to auto-prune the worktrees on the next fetch.
  for wt_git in .claude/worktrees/*/.git; do
    [ -f "$wt_git" ] || continue
    wt_dir=$(dirname "$wt_git")
    printf 'gitdir: ../../../.git/worktrees/%s\n' "$(basename "$wt_dir")" > "$wt_git"
  done
else
  # Linked worktree: configure-git-mounts.{sh,ps1} (initializeCommand) mounted the
  # main repo's .git directory at /git-root inside the container.
  #
  # Create /.git → /git-root so the relative .git pointer (../../../.git/worktrees/<name>)
  # resolves correctly inside the container via the symlink:
  #   container: ../../../.git = /.git → /git-root  →  /git-root/worktrees/<name> ✓
  #   host:      ../../../.git = C:/repos/Dostar/.git  →  .../.git/worktrees/<name> ✓
  #
  # Do NOT run `git worktree repair` here — it overwrites /git-root/worktrees/<name>/gitdir
  # with the container path /workspaces/<name>/.git, which breaks host-side git and causes
  # git to auto-prune the worktree on the next fetch.
  worktree_name=$(basename "$(pwd)")
  if [ -d "/git-root/worktrees/${worktree_name}" ]; then
    sudo ln -sf /git-root /.git
    printf 'gitdir: ../../../.git/worktrees/%s\n' "$worktree_name" > .git
    echo "[postCreate] Created /.git → /git-root symlink"
    echo "[postCreate] Set .git to relative path (host-compatible)"
  else
    echo "[postCreate] WARNING: /git-root/worktrees/${worktree_name} not found"
    echo "[postCreate]   configure-git-mounts may not have run — rebuild the container"
    echo "[postCreate]   Hint: ls /git-root/ (if /git-root exists)"
  fi
fi

echo "[postCreate] Fixing permissions..."
sudo chown vscode:vscode frontend/node_modules 2>/dev/null || true
sudo chown -R vscode:vscode /home/vscode/.claude 2>/dev/null || true
ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json 2>/dev/null || true

echo "[postCreate] Installing global tools..."
# dotnet-ef, gh, az, trivy, opengrep, Dostar.Cli, claude-code are pre-installed in the image.
# Guards below are no-ops when the image is current; they catch upgrades or missing installs.
command -v bicep > /dev/null 2>&1 \
  || az bicep install \
  || echo "WARNING: az bicep install failed — run: az bicep install"
install_dotnet_tool Dostar.Cli dostar
command -v claude > /dev/null 2>&1 \
  || npm install -g @anthropic-ai/claude-code \
  || echo "WARNING: claude-code install failed — run: npm install -g @anthropic-ai/claude-code"

echo "[postCreate] Installing coverlet (local test coverage tool)..."
dotnet tool install coverlet.console --tool-path ./tools \
  || echo "WARNING: coverlet install failed — run: dotnet tool install coverlet.console --tool-path ./tools"

echo "[postCreate] Configuring shell..."
bash .devcontainer/shell-profile.sh

echo "[postCreate] Restoring backend packages..."
dotnet restore

echo "[postCreate] Installing frontend dependencies..."
cd frontend && PNPM_CONFIG_CONFIRM_MODULES_PURGE=false pnpm install
cd ..

echo "[postCreate] Installing UI test dependencies..."
cd tests/Dostar.UITests && pnpm install --frozen-lockfile
cd ../..

echo "[postCreate] Checking Playwright browsers (Chromium)..."
# The image bakes the browser binary into /home/vscode/.cache/ms-playwright.
# The playwright-cache named volume seeds from that path on first container
# create, so this check is a no-op for the typical case.
# If the volume predates the current playwright version, the binary will be
# missing and we download it here. Prune stale volume dirs manually if needed:
#   docker volume rm dostar-playwright-cache
if find /home/vscode/.cache/ms-playwright -name 'chrome' -type f 2>/dev/null | grep -q .; then
  echo "[postCreate] Chromium already present — skipping download"
else
  cd tests/Dostar.UITests
  pnpm exec playwright install chromium \
    || echo "WARNING: playwright install chromium failed — run: cd tests/Dostar.UITests && pnpm exec playwright install chromium"
  cd ../..
fi

echo "[postCreate] Setting up git hooks..."
sudo ln -sf "$(node -e "const {getExePath}=require('$(pwd)/frontend/node_modules/lefthook/get-exe.js'); process.stdout.write(getExePath())")" /usr/local/bin/lefthook || \
  echo "WARNING: lefthook symlink failed — run: lefthook install"
lefthook install || echo "WARNING: lefthook install failed — run: lefthook install"

echo "[postCreate] Done. Full log: cat .devcontainer/postCreate.log"
