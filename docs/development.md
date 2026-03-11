# Development guide

## Running locally

### Backend

```bash
dotnet run --project backend/Dostar.Api --launch-profile http
```

- Health check: `http://localhost:5000/healthz`
- API docs (Scalar): `http://localhost:5000/scalar/v1`

### Frontend

```bash
cd frontend && pnpm dev
```

- Dev server: `http://localhost:5173`

### VS Code

Press `F5` to build and start `Dostar.Api`; Scalar opens automatically.

---

## CORS configuration

CORS is configured with two named policies in `Program.cs`:

| Policy | Environment | Allowed origins |
|--------|-------------|-----------------|
| `DevelopmentCors` | Development | `http://localhost:5173` (Vite dev server) — hardcoded |
| `ProductionCors` | All other | Read from `Cors:AllowedOrigins` in `appsettings.json` |

`UseCors` is applied **before** routing middleware so it runs on every request.

### Local development

`appsettings.Development.json` pre-populates the array with the Vite origin so `pnpm dev` can call the API without CORS errors:

```json
"Cors": {
  "AllowedOrigins": [ "http://localhost:5173" ]
}
```

### Production

Set `Cors:AllowedOrigins` to your Azure Static Web App hostname(s). Requests from any unlisted origin are rejected with a CORS error (the browser blocks them; the server returns no CORS headers for unlisted origins).

Example `appsettings.json` override or environment variable:

```json
"Cors": {
  "AllowedOrigins": [ "https://your-app.azurestaticapps.net" ]
}
```

You can also supply the value via an environment variable using the standard .NET configuration key separator:

```
Cors__AllowedOrigins__0=https://your-app.azurestaticapps.net
```
