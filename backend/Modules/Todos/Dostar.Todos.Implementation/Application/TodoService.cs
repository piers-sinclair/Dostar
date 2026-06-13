namespace Dostar.Todos.Implementation.Application;

[ExcludeFromCodeCoverage]
public class TodoService(TodosDbContext db) : ITodoService
{
    public async Task<IEnumerable<TodoDto>> GetAllAsync(CancellationToken cancellationToken = default) =>
        await db.Todos
            .OrderBy(t => t.CreatedAt)
            .Select(t => new TodoDto(t.Id, t.Title, t.IsCompleted, t.CreatedAt))
            .ToListAsync(cancellationToken);

    public async Task<TodoDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var todo = await db.Todos.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        if (todo is null) throw new NotFoundException($"Todo {id} not found.");
        return ToDto(todo);
    }

    public async Task<TodoDto> CreateAsync(string title, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(title);
        var todo = new Todo
        {
            Id = Guid.CreateVersion7(),
            Title = title,
            IsCompleted = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.Todos.Add(todo);
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(todo);
    }

    public async Task<TodoDto> UpdateAsync(Guid id, string title, bool isCompleted, CancellationToken cancellationToken = default)
    {
        var todo = await db.Todos.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        if (todo is null) throw new NotFoundException($"Todo {id} not found.");
        todo.Title = title;
        todo.IsCompleted = isCompleted;
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(todo);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var deleted = await db.Todos
            .Where(t => t.Id == id)
            .ExecuteDeleteAsync(cancellationToken);
        if (deleted == 0) throw new NotFoundException($"Todo {id} not found.");
    }

    private static TodoDto ToDto(Todo todo) =>
        new(todo.Id, todo.Title, todo.IsCompleted, todo.CreatedAt);
}
