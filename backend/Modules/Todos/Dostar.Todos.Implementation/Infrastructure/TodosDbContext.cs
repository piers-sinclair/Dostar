namespace Dostar.Todos.Implementation.Infrastructure;

public class TodosDbContext(DbContextOptions<TodosDbContext> options) : DbContext(options)
{
    public DbSet<Todo> Todos => Set<Todo>();
}
