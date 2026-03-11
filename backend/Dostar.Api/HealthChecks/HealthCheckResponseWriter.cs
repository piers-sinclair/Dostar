using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Dostar.Api.HealthChecks;

internal static class HealthCheckResponseWriter
{
    internal static Task WriteResponse(HttpContext context, HealthReport report)
    {
        context.Response.ContentType = "application/json";
        var response = new
        {
            status = report.Status.ToString(),
            duration = report.TotalDuration,
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                duration = e.Value.Duration
            })
        };
        return context.Response.WriteAsJsonAsync(response);
    }
}
