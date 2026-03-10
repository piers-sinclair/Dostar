namespace Dostar.Todos.Implementation;

public class TodosModule : IEndpointModule
{
    private const string ConnectionStringName = "Default";
    private const string RoutePrefix = "/api/todos";
    private const string RootRoute = "/";
    private const string IdRoute = "/{id:guid}";

    public void RegisterServices(IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<TodosDbContext>(options =>
            options.UseNpgsql(config.GetConnectionString(ConnectionStringName)));
        services.AddScoped<ITodoService, TodoService>();
        services.AddScoped<IValidator<CreateTodoRequest>, CreateTodoRequestValidator>();
        services.AddScoped<IValidator<UpdateTodoRequest>, UpdateTodoRequestValidator>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup(RoutePrefix);

        group.MapGet(RootRoute, async (ITodoService service) =>
            Results.Ok(await service.GetAllAsync()));

        group.MapGet(IdRoute, async (Guid id, ITodoService service) =>
        {
            var todo = await service.GetByIdAsync(id);
            return todo is null ? Results.NotFound() : Results.Ok(todo);
        });

        group.MapPost(RootRoute, async (CreateTodoRequest request, ITodoService service) =>
        {
            var todo = await service.CreateAsync(request.Title);
            return Results.Created($"{RoutePrefix}/{todo.Id}", todo);
        }).AddEndpointFilter<ValidationFilter<CreateTodoRequest>>();

        group.MapPut(IdRoute, async (Guid id, UpdateTodoRequest request, ITodoService service) =>
        {
            var todo = await service.UpdateAsync(id, request.Title, request.IsComplete);
            return todo is null ? Results.NotFound() : Results.Ok(todo);
        }).AddEndpointFilter<ValidationFilter<UpdateTodoRequest>>();

        group.MapDelete(IdRoute, async (Guid id, ITodoService service) =>
        {
            var deleted = await service.DeleteAsync(id);
            return deleted ? Results.NoContent() : Results.NotFound();
        });
    }
}

public record CreateTodoRequest(string Title);
public record UpdateTodoRequest(string Title, bool IsComplete);
