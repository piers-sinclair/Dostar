namespace Dostar.Api.Cors;

internal static class CorsPolicy
{
    internal const string Development = "DevelopmentCors";
    internal const string Production = "ProductionCors";
    internal const string DevOrigin = "http://localhost:5173";
    internal const string ConfigSection = "Cors:AllowedOrigins";
}
