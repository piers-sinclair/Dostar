namespace Dostar.Todos.UnitTests;

public class PostgresContainerFixture : IAsyncLifetime
{
    private const string PostgresImage = "postgres:17-alpine";
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder(PostgresImage).Build();

    public string ConnectionString => _postgres.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        await using var db = CreateDbContext();
        await db.Database.MigrateAsync();
    }

    public async Task DisposeAsync() => await _postgres.DisposeAsync();

    public TodosDbContext CreateDbContext() =>
        new(new DbContextOptionsBuilder<TodosDbContext>()
            .UseNpgsql(ConnectionString)
            .Options);
}
