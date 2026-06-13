---
description: Add integration tests for a Dostar module endpoint using WebApplicationFactory and Testcontainers.
argument-hint: <Module> <description>
allowed-tools: Bash(dotnet *) Read Write Edit Glob Grep
---

# integration-tests

Add integration tests for a Dostar module endpoint.

## Usage

```
/integration-tests <Module> <description>
```

Example: `/integration-tests Todos CreateTodo endpoint`

## Context

Integration tests live in `backend/Modules/<Name>/Dostar.<Name>.IntegrationTests/`. They use:

- **`WebApplicationFactory<Program>`** from `Microsoft.AspNetCore.Mvc.Testing` — spins up the real API in-process
- **Testcontainers** (`Testcontainers.PostgreSql`) — starts a real PostgreSQL container per test class run
- **Shouldly** for assertions — never `Assert.*` or FluentAssertions
- Method naming: `MethodName_Condition_ExpectedOutcome`

## Steps

### 1. Identify the target module

From `$ARGUMENTS`, determine:
- Module name (PascalCase, e.g. `Orders`)
- Which endpoint(s) to test (GET all, GET by id, POST, PUT, DELETE)
- The DTO types from `<Module>.Contracts`

### 2. Create or extend the `ApiFactory`

If the module's integration test project already has an `ApiFactory.cs`, read it. Otherwise create one following this pattern exactly:

```csharp
namespace Dostar.<Name>.IntegrationTests;

public class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private const string PostgresImage = "postgres:17-alpine";
    private const string TestEnvironment = "Test";
    private const string ConnectionStringKey = "ConnectionStrings:Default";

    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder(PostgresImage).Build();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment(TestEnvironment);
        builder.ConfigureAppConfiguration((_, config) =>
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                [ConnectionStringKey] = _postgres.GetConnectionString()
            }));
    }

    async Task IAsyncLifetime.InitializeAsync()
    {
        await _postgres.StartAsync();
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<<Name>DbContext>();
        await db.Database.MigrateAsync();
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await _postgres.DisposeAsync();
    }
}
```

### 3. Create `GlobalUsings.cs`

If the integration test project does not already have a `GlobalUsings.cs`, create one at the project root. Include global usings for every namespace used across multiple files — at minimum:

```csharp
global using System.Net;
global using System.Net.Http.Json;
global using System.Text.Json;
global using Microsoft.AspNetCore.Mvc.Testing;
global using Microsoft.EntityFrameworkCore;
global using Microsoft.Extensions.DependencyInjection;
global using Shouldly;
global using Dostar.<Name>.Implementation;
```

Add any additional namespaces from `.Contracts` or the module's entities as needed.

### 4. Write the test class

Create `backend/Modules/<Name>/Dostar.<Name>.IntegrationTests/<Name>/<Name>EndpointTests.cs`:

```csharp
namespace Dostar.<Name>.IntegrationTests.<Name>;

public class <Name>EndpointTests(ApiFactory factory) : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private static readonly JsonSerializerOptions JsonOptions = JsonSerializerOptions.Web;
    private const string BaseUrl = "/api/v1/<route>";

    private readonly HttpClient _client = factory.CreateClient();

    public async Task InitializeAsync()
    {
        // Clear the table between tests to keep each test independent
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<<Name>DbContext>();
        await db.<Entities>.ExecuteDeleteAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    // One test per endpoint behaviour — use naming: MethodName_Condition_ExpectedOutcome
}
```

### 5. Add test methods

For each endpoint, write a test. Follow these rules:
- Each test is fully self-contained — `InitializeAsync` clears the DB before each test
- Use `Shouldly` for assertions: `result.ShouldBe(...)`, `response.StatusCode.ShouldBe(HttpStatusCode.OK)`
- Use `ReadFromJsonAsync<T>(JsonOptions)` to deserialise responses
- Test both happy path and key error cases (404, 422 for bad input)

Example test:

```csharp
[Fact]
public async Task GetAllAsync_WhenEmpty_ReturnsEmptyList()
{
    var response = await _client.GetAsync(BaseUrl);

    response.StatusCode.ShouldBe(HttpStatusCode.OK);
    var items = await response.Content.ReadFromJsonAsync<<Name>Dto[]>(JsonOptions);
    items.ShouldNotBeNull();
    items.ShouldBeEmpty();
}
```

### 6. Run the tests

```bash
dotnet test backend/Modules/<Name>/Dostar.<Name>.IntegrationTests
```

Fix any failures before reporting complete. Integration tests require Docker to be running.

## Reference

- [docs/module-pattern.md](../../docs/module-pattern.md) — module structure guide
