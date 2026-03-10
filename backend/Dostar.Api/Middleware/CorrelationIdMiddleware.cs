namespace Dostar.Api.Middleware;

public class CorrelationIdMiddleware(RequestDelegate next, ILogger<CorrelationIdMiddleware> logger)
{
    private const string HeaderName = "X-Correlation-ID";
    private const string ScopeTemplate = "CorrelationId: {CorrelationId}";

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers[HeaderName].FirstOrDefault()
            ?? Guid.CreateVersion7().ToString();

        context.Response.Headers[HeaderName] = correlationId;

        using var scope = logger.BeginScope(ScopeTemplate, correlationId);
        await next(context);
    }
}
