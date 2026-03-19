#!/bin/bash
set -e

az bicep install
dotnet tool install -g dotnet-ef || true
dotnet restore
sudo chown vscode:vscode frontend/node_modules
sudo chown -R vscode:vscode /home/vscode/.claude
cd frontend && pnpm install
