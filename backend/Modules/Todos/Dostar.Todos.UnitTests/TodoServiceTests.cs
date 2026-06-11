namespace Dostar.Todos.UnitTests;

public class TodoServiceTests(PostgresContainerFixture fixture) : IClassFixture<PostgresContainerFixture>, IAsyncLifetime
{
    private readonly TodosDbContext _db = fixture.CreateDbContext();

    public Task InitializeAsync() => Task.CompletedTask;

    public async Task DisposeAsync()
    {
        await _db.Todos.ExecuteDeleteAsync();
        await _db.DisposeAsync();
    }

    [Fact]
    public async Task GetAllAsync_WhenEmpty_ReturnsEmptyList()
    {
        var service = new TodoService(_db);

        var result = await service.GetAllAsync();

        result.ShouldBeEmpty();
    }

    [Fact]
    public async Task CreateAsync_WhenCalled_ReturnsTodoDtoWithCorrectData()
    {
        var service = new TodoService(_db);

        var result = await service.CreateAsync("Buy milk");

        result.Title.ShouldBe("Buy milk");
        result.IsCompleted.ShouldBeFalse();
        result.Id.ShouldNotBe(Guid.Empty);
        result.CreatedAt.ShouldBeInRange(DateTimeOffset.UtcNow.AddSeconds(-5), DateTimeOffset.UtcNow.AddSeconds(5));
    }

    [Fact]
    public async Task GetAllAsync_AfterCreate_ReturnsTodo()
    {
        var service = new TodoService(_db);
        await service.CreateAsync("Buy milk");

        var result = await service.GetAllAsync();

        result.Count().ShouldBe(1);
        result.Single().Title.ShouldBe("Buy milk");
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ReturnsDto()
    {
        var service = new TodoService(_db);
        var created = await service.CreateAsync("Task A");

        var result = await service.GetByIdAsync(created.Id);

        result.ShouldNotBeNull();
        result.Id.ShouldBe(created.Id);
        result.Title.ShouldBe("Task A");
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ReturnsNull()
    {
        var service = new TodoService(_db);

        var result = await service.GetByIdAsync(Guid.NewGuid());

        result.ShouldBeNull();
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_UpdatesAndReturnsDto()
    {
        var service = new TodoService(_db);
        var created = await service.CreateAsync("Original");

        var result = await service.UpdateAsync(created.Id, "Updated", isComplete: true);

        result.ShouldNotBeNull();
        result.Title.ShouldBe("Updated");
        result.IsCompleted.ShouldBeTrue();
    }

    [Fact]
    public async Task UpdateAsync_WhenNotFound_ReturnsNull()
    {
        var service = new TodoService(_db);

        var result = await service.UpdateAsync(Guid.NewGuid(), "Updated", isComplete: true);

        result.ShouldBeNull();
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_DeletesAndReturnsTrue()
    {
        var service = new TodoService(_db);
        var created = await service.CreateAsync("To delete");

        var deleted = await service.DeleteAsync(created.Id);

        deleted.ShouldBeTrue();
        (await service.GetByIdAsync(created.Id)).ShouldBeNull();
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ReturnsFalse()
    {
        var service = new TodoService(_db);

        var deleted = await service.DeleteAsync(Guid.NewGuid());

        deleted.ShouldBeFalse();
    }
}
