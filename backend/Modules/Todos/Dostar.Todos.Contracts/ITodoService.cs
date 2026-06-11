namespace Dostar.Todos.Contracts;

public interface ITodoService
{
    Task<IEnumerable<TodoDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<TodoDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<TodoDto> CreateAsync(string title, CancellationToken cancellationToken = default);
    Task<TodoDto?> UpdateAsync(Guid id, string title, bool isComplete, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
