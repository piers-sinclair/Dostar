namespace Dostar.Api.Middleware;

internal sealed class SecurityHeadersMiddleware(RequestDelegate next, IWebHostEnvironment env)
{
    private const string ContentTypeOptionsHeader = "X-Content-Type-Options";
    private const string FrameOptionsHeader = "X-Frame-Options";
    private const string ReferrerPolicyHeader = "Referrer-Policy";
    private const string XssProtectionHeader = "X-XSS-Protection";
    private const string ContentSecurityPolicyHeader = "Content-Security-Policy";
    private const string StrictTransportSecurityHeader = "Strict-Transport-Security";

    private const string ContentTypeOptionsValue = "nosniff";
    private const string FrameOptionsValue = "DENY";
    private const string ReferrerPolicyValue = "strict-origin-when-cross-origin";
    private const string XssProtectionValue = "0";
    private const string ContentSecurityPolicyValue = "default-src 'self'";
    private const string StrictTransportSecurityValue = "max-age=31536000; includeSubDomains";

    public async Task InvokeAsync(HttpContext context)
    {
        context.Response.Headers[ContentTypeOptionsHeader] = ContentTypeOptionsValue;
        context.Response.Headers[FrameOptionsHeader] = FrameOptionsValue;
        context.Response.Headers[ReferrerPolicyHeader] = ReferrerPolicyValue;
        context.Response.Headers[XssProtectionHeader] = XssProtectionValue;
        context.Response.Headers[ContentSecurityPolicyHeader] = ContentSecurityPolicyValue;

        if (!env.IsDevelopment())
            context.Response.Headers[StrictTransportSecurityHeader] = StrictTransportSecurityValue;

        await next(context);
    }
}