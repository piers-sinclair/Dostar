namespace Dostar.SharedKernel.UnitTests;

public class GlobalExceptionHandlerTests
{
    private readonly IProblemDetailsService _problemDetailsService;
    private readonly GlobalExceptionHandler _handler;
    private readonly HttpContext _httpContext;

    public GlobalExceptionHandlerTests()
    {
        _problemDetailsService = Substitute.For<IProblemDetailsService>();
        _problemDetailsService.TryWriteAsync(Arg.Any<ProblemDetailsContext>()).Returns(true);
        _handler = new GlobalExceptionHandler(_problemDetailsService);
        _httpContext = Substitute.For<HttpContext>();
        _httpContext.Response.Returns(Substitute.For<HttpResponse>());
    }

    [Fact]
    public async Task TryHandleAsync_WhenNotFoundException_Sets404AndReturnsTrue()
    {
        ProblemDetailsContext? captured = null;
        _problemDetailsService
            .TryWriteAsync(Arg.Do<ProblemDetailsContext>(ctx => captured = ctx))
            .Returns(true);

        var result = await _handler.TryHandleAsync(_httpContext, new NotFoundException("not found"), CancellationToken.None);

        result.ShouldBeTrue();
        _httpContext.Response.Received().StatusCode = StatusCodes.Status404NotFound;
        captured!.ProblemDetails.Status.ShouldBe(StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task TryHandleAsync_WhenConflictException_Sets409AndReturnsTrue()
    {
        ProblemDetailsContext? captured = null;
        _problemDetailsService
            .TryWriteAsync(Arg.Do<ProblemDetailsContext>(ctx => captured = ctx))
            .Returns(true);

        var result = await _handler.TryHandleAsync(_httpContext, new ConflictException("conflict"), CancellationToken.None);

        result.ShouldBeTrue();
        _httpContext.Response.Received().StatusCode = StatusCodes.Status409Conflict;
        captured!.ProblemDetails.Status.ShouldBe(StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task TryHandleAsync_WhenUnhandledException_Sets500AndReturnsTrue()
    {
        ProblemDetailsContext? captured = null;
        _problemDetailsService
            .TryWriteAsync(Arg.Do<ProblemDetailsContext>(ctx => captured = ctx))
            .Returns(true);

        var result = await _handler.TryHandleAsync(_httpContext, new InvalidOperationException("unexpected"), CancellationToken.None);

        result.ShouldBeTrue();
        _httpContext.Response.Received().StatusCode = StatusCodes.Status500InternalServerError;
        captured!.ProblemDetails.Status.ShouldBe(StatusCodes.Status500InternalServerError);
    }
}
