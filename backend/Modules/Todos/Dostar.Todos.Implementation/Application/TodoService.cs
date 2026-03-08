namespace Dostar.Todos.Implementation.Application;

public class TodoService(TodosDbContext db) : ITodoService
{
    public async Task<IEnumerable<TodoDto>> GetAllAsync() =>
        await db.Todos
            .Select(t => new TodoDto(t.Id, t.Title, t.IsComplete, t.CreatedAt))
            .ToListAsync();

    public async Task<TodoDto?> GetByIdAsync(Guid id)
    {
        var todo = await db.Todos.FindAsync(id);
        return todo is null ? null : ToDto(todo);
    }

    public async Task<TodoDto> CreateAsync(string title)
    {
        var todo = new Todo
        {
            Id = Guid.NewGuid(),
            Title = title,
            IsComplete = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.Todos.Add(todo);
        await db.SaveChangesAsync();
        return ToDto(todo);
    }

    public async Task<TodoDto?> UpdateAsync(Guid id, string title, bool isComplete)
    {
        var todo = await db.Todos.FindAsync(id);
        if (todo is null) return null;
        todo.Title = title;
        todo.IsComplete = isComplete;
        await db.SaveChangesAsync();
        return ToDto(todo);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var todo = await db.Todos.FindAsync(id);
        if (todo is null) return false;
        db.Todos.Remove(todo);
        await db.SaveChangesAsync();
        return true;
    }

    private static TodoDto ToDto(Todo todo) =>
        new(todo.Id, todo.Title, todo.IsComplete, todo.CreatedAt);
}
