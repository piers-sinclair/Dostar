namespace Dostar.Todos.Implementation.Infrastructure;

[ExcludeFromCodeCoverage]
public class TodosDbContext(DbContextOptions<TodosDbContext> options) : DbContext(options)
{
    public DbSet<Todo> Todos => Set<Todo>();
}
