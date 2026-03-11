namespace Dostar.Todos.Implementation;

public class TodosModule : IEndpointModule
{
    private const string ConnectionStringName = "Default";
    private const string HealthCheckName = "todos-db";
    private const string RoutePrefix = "/todos";
    private const string ResourceRoute = "/api/v1/todos";
    private const string RootRoute = "/";
    private const string IdRoute = "/{id:guid}";
    private const string GetTodosOperationId = "GetTodos";
    private const string GetTodoOperationId = "GetTodo";
    private const string CreateTodoOperationId = "CreateTodo";
    private const string UpdateTodoOperationId = "UpdateTodo";
    private const string DeleteTodoOperationId = "DeleteTodo";

    public void RegisterServices(IServiceCollection services, IConfiguration config)
    {
        var connectionString = config.GetConnectionString(ConnectionStringName) ?? string.Empty;
        services.AddDbContext<TodosDbContext>(options => options.UseNpgsql(connectionString));
        services.AddHealthChecks().AddNpgSql(connectionString, name: HealthCheckName);
        services.AddScoped<ITodoService, TodoService>();
        services.AddScoped<IValidator<CreateTodoRequest>, CreateTodoRequestValidator>();
        services.AddScoped<IValidator<UpdateTodoRequest>, UpdateTodoRequestValidator>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup(RoutePrefix).WithTags("Todos");

        group.MapGet(RootRoute, async (ITodoService service) =>
            Results.Ok(await service.GetAllAsync()))
            .WithName(GetTodosOperationId);

        group.MapGet(IdRoute, async (Guid id, ITodoService service) =>
        {
            var todo = await service.GetByIdAsync(id);
            return todo is null ? Results.NotFound() : Results.Ok(todo);
        }).WithName(GetTodoOperationId);

        group.MapPost(RootRoute, async (CreateTodoRequest request, ITodoService service) =>
        {
            var todo = await service.CreateAsync(request.Title);
            return Results.Created($"{ResourceRoute}/{todo.Id}", todo);
        }).AddEndpointFilter<ValidationFilter<CreateTodoRequest>>()
          .RequireRateLimiting(RateLimitPolicy.Strict)
          .WithName(CreateTodoOperationId);

        group.MapPut(IdRoute, async (Guid id, UpdateTodoRequest request, ITodoService service) =>
        {
            var todo = await service.UpdateAsync(id, request.Title, request.IsComplete);
            return todo is null ? Results.NotFound() : Results.Ok(todo);
        }).AddEndpointFilter<ValidationFilter<UpdateTodoRequest>>()
          .WithName(UpdateTodoOperationId);

        group.MapDelete(IdRoute, async (Guid id, ITodoService service) =>
        {
            var deleted = await service.DeleteAsync(id);
            return deleted ? Results.NoContent() : Results.NotFound();
        }).WithName(DeleteTodoOperationId);
    }
}

public record CreateTodoRequest(string Title);
public record UpdateTodoRequest(string Title, bool IsComplete);