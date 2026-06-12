namespace Dostar.Todos.IntegrationTests.Todos;

public class TodosEndpointTests(ApiFactory factory) : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private static readonly JsonSerializerOptions JsonOptions = JsonSerializerOptions.Web;
    private const string TodosUrl = "/api/v1/todos";

    private readonly HttpClient _client = factory.CreateClient();

    public async Task InitializeAsync()
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TodosDbContext>();
        await db.Todos.ExecuteDeleteAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetAllAsync_WhenEmpty_ReturnsEmptyList()
    {
        var response = await _client.GetAsync(TodosUrl);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        var todos = await response.Content.ReadFromJsonAsync<TodoDto[]>(JsonOptions);
        todos.ShouldNotBeNull();
        todos.ShouldBeEmpty();
    }

    [Fact]
    public async Task CreateAsync_WithValidTitle_Returns201WithCreatedTodo()
    {
        var response = await _client.PostAsJsonAsync(TodosUrl, new { title = "Buy milk" });

        response.StatusCode.ShouldBe(HttpStatusCode.Created);
        var todo = await response.Content.ReadFromJsonAsync<TodoDto>(JsonOptions);
        todo.ShouldNotBeNull();
        todo.Title.ShouldBe("Buy milk");
        todo.IsCompleted.ShouldBeFalse();
        todo.Id.ShouldNotBe(Guid.Empty);
        response.Headers.Location.ShouldNotBeNull();
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_Returns200WithTodo()
    {
        var created = await CreateTodoAsync("Test todo");

        var response = await _client.GetAsync($"{TodosUrl}/{created.Id}");

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        var todo = await response.Content.ReadFromJsonAsync<TodoDto>(JsonOptions);
        todo.ShouldNotBeNull();
        todo.Id.ShouldBe(created.Id);
        todo.Title.ShouldBe("Test todo");
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_Returns404()
    {
        var response = await _client.GetAsync($"{TodosUrl}/{Guid.NewGuid()}");

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_Returns200WithUpdatedTodo()
    {
        var created = await CreateTodoAsync("Original title");

        var response = await _client.PutAsJsonAsync(
            $"{TodosUrl}/{created.Id}",
            new { title = "Updated title", isComplete = true });

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        var todo = await response.Content.ReadFromJsonAsync<TodoDto>(JsonOptions);
        todo.ShouldNotBeNull();
        todo.Title.ShouldBe("Updated title");
        todo.IsCompleted.ShouldBeTrue();
    }

    [Fact]
    public async Task UpdateAsync_WhenNotFound_Returns404()
    {
        var response = await _client.PutAsJsonAsync(
            $"{TodosUrl}/{Guid.NewGuid()}",
            new { title = "Some title", isComplete = false });

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_Returns204()
    {
        var created = await CreateTodoAsync("To be deleted");

        var response = await _client.DeleteAsync($"{TodosUrl}/{created.Id}");

        response.StatusCode.ShouldBe(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_Returns404()
    {
        var response = await _client.DeleteAsync($"{TodosUrl}/{Guid.NewGuid()}");

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetAllAsync_AfterCreate_ReturnsTodo()
    {
        await CreateTodoAsync("Visible todo");

        var response = await _client.GetAsync(TodosUrl);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        var todos = await response.Content.ReadFromJsonAsync<TodoDto[]>(JsonOptions);
        todos.ShouldNotBeNull();
        todos.Length.ShouldBe(1);
        todos[0].Title.ShouldBe("Visible todo");
    }

    private async Task<TodoDto> CreateTodoAsync(string title)
    {
        var response = await _client.PostAsJsonAsync(TodosUrl, new { title });
        response.EnsureSuccessStatusCode();
        var todo = await response.Content.ReadFromJsonAsync<TodoDto>(JsonOptions);
        return todo ?? throw new InvalidOperationException("CreateTodoAsync: API returned null");
    }
}
