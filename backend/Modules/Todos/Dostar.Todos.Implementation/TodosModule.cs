namespace Dostar.Todos.Implementation;

[ExcludeFromCodeCoverage]
public class TodosModule : IEndpointModule
{
    private const string ConnectionStringName = "Default";
    private const string HealthCheckName = "todos-db";
    private const string RoutePrefix = "/todos";
    private const string RootRoute = "/";
    private const string IdRoute = "/{id:guid}";
    private const string GetTodosOperationId = "GetTodos";
    private const string GetTodoOperationId = "GetTodo";
    private const string CreateTodoOperationId = "CreateTodo";
    private const string UpdateTodoOperationId = "UpdateTodo";
    private const string DeleteTodoOperationId = "DeleteTodo";

    public void RegisterServices(IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<TodosDbContext>((sp, options) =>
            options.UseNpgsql(sp.GetRequiredService<IConfiguration>().GetConnectionString(ConnectionStringName)));
        services.AddHealthChecks().AddNpgSql(
            connectionStringFactory: sp => sp.GetRequiredService<IConfiguration>().GetConnectionString(ConnectionStringName)
                ?? throw new InvalidOperationException($"Missing connection string '{ConnectionStringName}'."),
            name: HealthCheckName);
        services.AddScoped<ITodoService, TodoService>();
        services.AddScoped<IValidator<CreateTodoRequest>, CreateTodoRequestValidator>();
        services.AddScoped<IValidator<UpdateTodoRequest>, UpdateTodoRequestValidator>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup(RoutePrefix).WithTags("Todos");

        group.MapGet(RootRoute, async (ITodoService service, CancellationToken ct) =>
            Results.Ok(await service.GetAllAsync(ct)))
            .Produces<IEnumerable<TodoDto>>()
            .WithName(GetTodosOperationId);

        group.MapGet(IdRoute, async (Guid id, ITodoService service, CancellationToken ct) =>
            Results.Ok(await service.GetByIdAsync(id, ct)))
            .Produces<TodoDto>()
            .Produces(StatusCodes.Status404NotFound)
            .WithName(GetTodoOperationId);

        group.MapPost(RootRoute, async (CreateTodoRequest request, ITodoService service, LinkGenerator links, HttpContext ctx, CancellationToken ct) =>
        {
            var todo = await service.CreateAsync(request.Title, ct);
            var uri = links.GetUriByName(ctx, GetTodoOperationId, new { id = todo.Id });
            return Results.Created(uri, todo);
        }).Produces<TodoDto>(StatusCodes.Status201Created)
          .AddEndpointFilter<ValidationFilter<CreateTodoRequest>>()
          .RequireRateLimiting(RateLimitPolicy.Strict)
          .WithName(CreateTodoOperationId);

        group.MapPut(IdRoute, async (Guid id, UpdateTodoRequest request, ITodoService service, CancellationToken ct) =>
            Results.Ok(await service.UpdateAsync(id, request.Title, request.IsCompleted, ct)))
            .Produces<TodoDto>()
            .Produces(StatusCodes.Status404NotFound)
            .AddEndpointFilter<ValidationFilter<UpdateTodoRequest>>()
            .WithName(UpdateTodoOperationId);

        group.MapDelete(IdRoute, async (Guid id, ITodoService service, CancellationToken ct) =>
        {
            await service.DeleteAsync(id, ct);
            return Results.NoContent();
        }).Produces(StatusCodes.Status204NoContent)
          .Produces(StatusCodes.Status404NotFound)
          .WithName(DeleteTodoOperationId);
    }
}
