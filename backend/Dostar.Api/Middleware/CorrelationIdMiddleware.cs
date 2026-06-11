namespace Dostar.Api.Middleware;

internal sealed class CorrelationIdMiddleware(RequestDelegate next, ILogger<CorrelationIdMiddleware> logger)
{
    private const string HeaderName = "X-Correlation-ID";

    private static readonly Func<ILogger, string, IDisposable?> BeginCorrelationScope =
        LoggerMessage.DefineScope<string>("CorrelationId: {CorrelationId}");

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers[HeaderName].FirstOrDefault()
            ?? Guid.CreateVersion7().ToString();

        context.Response.Headers[HeaderName] = correlationId;

        using var scope = BeginCorrelationScope(logger, correlationId);
        await next(context);
    }
}
