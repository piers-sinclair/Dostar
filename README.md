# Dostar

A production-ready fullstack starter — .NET modular monolith backend + React/Vite frontend.

## Prerequisites

| Tool | Version |
|------|---------|
| .NET SDK | 10 (`global.json` pins the exact version) |
| Node.js | 20+ |
| pnpm | 10+ (`npm install -g pnpm`) |
| Docker Desktop | Latest |

## Quick start

```bash
# 1. Clone
git clone https://github.com/piers-sinclair/Dostar.git
cd Dostar

# 2. Start the database
docker compose up -d

# 3. Apply migrations (first time, and after pulling new migrations)
dotnet tool install --global dotnet-ef   # skip if already installed
dotnet ef database update \
  --project backend/Modules/Todos/Dostar.Todos.Implementation \
  --startup-project backend/Dostar.Api \
  --context TodosDbContext

# 4. Start the backend
dotnet run --project backend/Dostar.Api --launch-profile http

# 5. Start the frontend (new terminal)
cd frontend
pnpm install
pnpm dev
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| Backend health | http://localhost:5000/healthz |
| API docs (Scalar) | http://localhost:5000/scalar/v1 |
