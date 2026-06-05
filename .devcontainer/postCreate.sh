#!/bin/bash
set -e

az bicep install
dotnet tool install -g dotnet-ef || true
dotnet restore
curl -fsSL https://aka.ms/install-azd.sh | bash
sudo chown vscode:vscode frontend/node_modules
sudo chown -R vscode:vscode /home/vscode/.claude
cd frontend && pnpm install
