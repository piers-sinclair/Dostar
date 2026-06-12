namespace Dostar.Todos.Implementation.Infrastructure;

[ExcludeFromCodeCoverage]
public class TodosDbContext(DbContextOptions<TodosDbContext> options) : DbContext(options)
{
    internal DbSet<Todo> Todos => Set<Todo>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Todo>(entity =>
        {
            entity.ToTable(t => t.HasCheckConstraint("CK_Todos_Title_NotEmpty", "\"Title\" <> ''"));
            entity.Property(t => t.IsCompleted).HasColumnName("IsComplete");
        });
    }
}
