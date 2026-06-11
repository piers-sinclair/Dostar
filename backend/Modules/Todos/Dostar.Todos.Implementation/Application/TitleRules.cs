namespace Dostar.Todos.Implementation.Application;

internal static class TitleRules
{
    internal static IRuleBuilderOptions<T, string> MustBeValidTitle<T>(
        this IRuleBuilder<T, string> rule) =>
        rule.NotEmpty().MaximumLength(200);
}
