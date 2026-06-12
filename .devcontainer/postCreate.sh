#!/bin/bash
set -e

az bicep install
dotnet tool install -g dotnet-ef || true
npm install -g @anthropic-ai/claude-code
dotnet restore
sudo chown vscode:vscode frontend/node_modules
sudo chown -R vscode:vscode /home/vscode/.claude
ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json
cd frontend && pnpm install
cd ..
ln -sf "$(pwd)/frontend/node_modules/.bin/lefthook" /usr/local/bin/lefthook
bash .devcontainer/shell-profile.sh
