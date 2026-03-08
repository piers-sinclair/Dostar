namespace Dostar.Todos.Implementation.Domain;

public class Todo
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool IsComplete { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
