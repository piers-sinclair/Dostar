# API versioning

Dostar uses URL segment versioning via [`Asp.Versioning.Http`](https://github.com/dotnet/aspnet-api-versioning).

## URL structure

All versioned endpoints follow the pattern `/api/v{version}/{resource}`:

```
GET  /api/v1/todos
POST /api/v1/todos
GET  /api/v1/todos/{id}
```

Requests without a version segment are rejected with **400 Bad Request** (`AssumeDefaultVersionWhenUnspecified = false`).

## Adding a new version

1. In `IEndpointModule`, override `Version`:
   ```csharp
   public ApiVersion Version => new(2, 0);
   ```
2. Update `RoutePrefix` in the module to the new relative path if the resource name changes.
3. `Program.cs` automatically adds the new version to the API version set by reading `module.Version` for all registered modules.

## Deprecating a version

Call `HasDeprecatedApiVersion` when building the version set in `Program.cs`:

```csharp
versionSetBuilder = versionSetBuilder.HasDeprecatedApiVersion(new ApiVersion(1, 0));
```

Deprecated versions automatically receive `Sunset` and `Deprecation` response headers (via `ReportApiVersions = true`).

## OpenAPI documents

Scalar is configured to serve the v1 document at `/openapi/v1.json` (development only).
