namespace Dostar.Todos.Contracts;

public record TodoDto(Guid Id, string Title, bool IsComplete, DateTimeOffset CreatedAt);
