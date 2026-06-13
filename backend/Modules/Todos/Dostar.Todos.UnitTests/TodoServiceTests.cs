namespace Dostar.Todos.UnitTests;

public class TodoServiceTests
{
    private static TodosDbContext CreateDbContext() =>
        new(new DbContextOptionsBuilder<TodosDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options);

    [Fact]
    public async Task GetByIdAsync_WhenTodoNotFound_LogsWarning()
    {
        var logger = new FakeLogger<TodoService>();
        using var db = CreateDbContext();
        var sut = new TodoService(db, logger);

        await sut.GetByIdAsync(Guid.NewGuid());

        logger.Logs.ShouldContain(e => e.Level == LogLevel.Warning);
    }
}
