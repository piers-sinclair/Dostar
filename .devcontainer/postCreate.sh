#!/bin/bash
set -e

az bicep install || true
dotnet tool install -g dotnet-ef || true
dotnet tool install -g Dostar.Cli || true
npm install -g @anthropic-ai/claude-code || true
dotnet restore
sudo chown vscode:vscode frontend/node_modules || true
sudo chown -R vscode:vscode /home/vscode/.claude || true
ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json || true
cd frontend && pnpm install
cd ..
sudo ln -sf "$(pwd)/frontend/node_modules/.bin/lefthook" /usr/local/bin/lefthook || true
bash .devcontainer/shell-profile.sh
