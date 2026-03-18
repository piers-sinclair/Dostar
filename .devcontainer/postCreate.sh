#!/bin/bash
set -e

az bicep install
dotnet tool install -g dotnet-ef || true
dotnet restore
sudo chown vscode:vscode frontend/node_modules
cd frontend && pnpm install
