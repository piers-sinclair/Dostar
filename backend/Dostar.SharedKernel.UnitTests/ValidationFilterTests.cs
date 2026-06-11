namespace Dostar.SharedKernel.UnitTests;

internal sealed record TestRequest(string Name);

public class ValidationFilterTests
{
    private static EndpointFilterInvocationContext CreateContext(params object?[] arguments)
    {
        var httpContext = Substitute.For<HttpContext>();
        httpContext.RequestAborted.Returns(CancellationToken.None);

        var context = Substitute.For<EndpointFilterInvocationContext>();
        context.Arguments.Returns(new List<object?>(arguments));
        context.HttpContext.Returns(httpContext);

        return context;
    }

    [Fact]
    public async Task InvokeAsync_WhenValidationSucceeds_CallsNextAndReturnsItsResult()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        validator
            .ValidateAsync(Arg.Any<TestRequest>(), CancellationToken.None)
            .Returns(new ValidationResult());

        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext(new TestRequest("Alice"));
        EndpointFilterDelegate next = _ => ValueTask.FromResult<object?>("next-result");

        var result = await filter.InvokeAsync(context, next);

        result.ShouldBe("next-result");
        await validator.Received(1).ValidateAsync(Arg.Any<TestRequest>(), CancellationToken.None);
    }

    [Fact]
    public async Task InvokeAsync_WhenValidationFails_ReturnsValidationProblemWithErrorsAndDoesNotCallNext()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        List<ValidationFailure> failures =
        [
            new("Name", "Name is required"),
            new("Name", "Name is too short"),
        ];
        validator
            .ValidateAsync(Arg.Any<TestRequest>(), CancellationToken.None)
            .Returns(new ValidationResult(failures));

        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext(new TestRequest(""));
        var nextCalled = false;
        EndpointFilterDelegate next = _ => { nextCalled = true; return ValueTask.FromResult<object?>(null); };

        var result = await filter.InvokeAsync(context, next);

        nextCalled.ShouldBeFalse();
        var problemResult = result.ShouldBeAssignableTo<ProblemHttpResult>();
        var validationDetails = problemResult!.ProblemDetails.ShouldBeOfType<HttpValidationProblemDetails>();
        validationDetails.Errors["Name"].ShouldContain("Name is required");
        validationDetails.Errors["Name"].ShouldContain("Name is too short");
    }
}
