namespace Dostar.Todos.Contracts;

public interface ITodoService
{
    Task<IEnumerable<TodoDto>> GetAllAsync();
    Task<TodoDto?> GetByIdAsync(Guid id);
    Task<TodoDto> CreateAsync(string title);
    Task<TodoDto?> UpdateAsync(Guid id, string title, bool isComplete);
    Task<bool> DeleteAsync(Guid id);
}
