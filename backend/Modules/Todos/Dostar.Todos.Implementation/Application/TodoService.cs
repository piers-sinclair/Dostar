namespace Dostar.Todos.Implementation.Application;

public class TodoService(TodosDbContext db) : ITodoService
{
    public async Task<IEnumerable<TodoDto>> GetAllAsync(CancellationToken cancellationToken = default) =>
        await db.Todos
            .OrderBy(t => t.CreatedAt)
            .Select(t => new TodoDto(t.Id, t.Title, t.IsComplete, t.CreatedAt))
            .ToListAsync(cancellationToken);

    public async Task<TodoDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var todo = await db.Todos.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        return todo is null ? null : ToDto(todo);
    }

    public async Task<TodoDto> CreateAsync(string title, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(title);
        var todo = new Todo
        {
            Id = Guid.CreateVersion7(),
            Title = title,
            IsComplete = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.Todos.Add(todo);
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(todo);
    }

    public async Task<TodoDto?> UpdateAsync(Guid id, string title, bool isComplete, CancellationToken cancellationToken = default)
    {
        var todo = await db.Todos.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        if (todo is null) return null;
        todo.Title = title;
        todo.IsComplete = isComplete;
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(todo);
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var todo = await db.Todos.FindAsync([id], cancellationToken);
        if (todo is null) return false;
        db.Todos.Remove(todo);
        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static TodoDto ToDto(Todo todo) =>
        new(todo.Id, todo.Title, todo.IsComplete, todo.CreatedAt);
}
