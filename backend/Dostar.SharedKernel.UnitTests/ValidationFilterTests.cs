namespace Dostar.SharedKernel.UnitTests;

public sealed record TestRequest(string Name);

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
    public async Task InvokeAsync_WhenArgumentNotFound_CallsNext()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext();
        var nextCalled = false;
        EndpointFilterDelegate next = _ => { nextCalled = true; return ValueTask.FromResult<object?>("ok"); };

        await filter.InvokeAsync(context, next);

        nextCalled.ShouldBeTrue();
        await validator.DidNotReceive().ValidateAsync(Arg.Any<TestRequest>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task InvokeAsync_WhenValidationFails_ReturnsValidationProblemAndDoesNotCallNext()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        validator
            .ValidateAsync(Arg.Any<TestRequest>(), Arg.Any<CancellationToken>())
            .Returns(new ValidationResult([new ValidationFailure("Name", "Name is required")]));

        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext(new TestRequest(""));
        var nextCalled = false;
        EndpointFilterDelegate next = _ => { nextCalled = true; return ValueTask.FromResult<object?>("ok"); };

        var result = await filter.InvokeAsync(context, next);

        nextCalled.ShouldBeFalse();
        result.ShouldBeAssignableTo<IResult>();
    }

    [Fact]
    public async Task InvokeAsync_WhenValidationSucceeds_CallsNextAndReturnsItsResult()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        validator
            .ValidateAsync(Arg.Any<TestRequest>(), Arg.Any<CancellationToken>())
            .Returns(new ValidationResult());

        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext(new TestRequest("Alice"));
        EndpointFilterDelegate next = _ => ValueTask.FromResult<object?>("next-result");

        var result = await filter.InvokeAsync(context, next);

        result.ShouldBe("next-result");
        await validator.Received(1).ValidateAsync(Arg.Any<TestRequest>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task InvokeAsync_WhenValidationFails_PassesErrorsToDictionary()
    {
        var validator = Substitute.For<IValidator<TestRequest>>();
        var failures = new List<ValidationFailure>
        {
            new("Name", "Name is required"),
            new("Name", "Name is too short"),
        };
        validator
            .ValidateAsync(Arg.Any<TestRequest>(), Arg.Any<CancellationToken>())
            .Returns(new ValidationResult(failures));

        var filter = new ValidationFilter<TestRequest>(validator);
        var context = CreateContext(new TestRequest(""));
        EndpointFilterDelegate next = _ => ValueTask.FromResult<object?>(null);

        var result = await filter.InvokeAsync(context, next);

        var problemResult = result.ShouldBeAssignableTo<Microsoft.AspNetCore.Http.HttpResults.ProblemHttpResult>();
        var validationDetails = problemResult!.ProblemDetails.ShouldBeOfType<HttpValidationProblemDetails>();
        validationDetails.Errors["Name"].ShouldContain("Name is required");
        validationDetails.Errors["Name"].ShouldContain("Name is too short");
    }
}
