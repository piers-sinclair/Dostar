namespace Dostar.Todos.Contracts;

public record TodoDto(Guid Id, string Title, bool IsCompleted, DateTimeOffset CreatedAt);
