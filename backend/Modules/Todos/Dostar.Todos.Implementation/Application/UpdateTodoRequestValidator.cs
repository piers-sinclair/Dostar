namespace Dostar.Todos.Implementation.Application;

[ExcludeFromCodeCoverage]
public class UpdateTodoRequestValidator : AbstractValidator<UpdateTodoRequest>
{
    public UpdateTodoRequestValidator()
    {
        RuleFor(x => x.Title).MustBeValidTitle();
    }
}
