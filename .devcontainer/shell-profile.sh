#!/bin/bash
set -e

# Append Dostar project aliases and shell settings to the vscode user's .zshrc.
# Run once during postCreate — idempotent guard prevents duplicate appends.
MARKER="# --- Dostar project profile ---"

if grep -qF "$MARKER" /home/vscode/.zshrc 2>/dev/null; then
  exit 0
fi

cat >> /home/vscode/.zshrc << 'EOF'

# --- Dostar project profile ---
alias api='dotnet run --project backend/Dostar.Api --launch-profile http'
alias fe='cd frontend && pnpm dev'
alias build='dotnet build && (cd frontend && pnpm build)'
alias test='dotnet test'

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
EOF
