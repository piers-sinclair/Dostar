namespace Dostar.Todos.IntegrationTests;

public class CorrelationIdMiddlewareTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private const string CorrelationIdHeader = "X-Correlation-ID";
    private const string LiveEndpoint = "/healthz/live";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Request_WithCorrelationIdHeader_ReturnsSameValueInResponse()
    {
        var correlationId = Guid.NewGuid().ToString();
        using var request = new HttpRequestMessage(HttpMethod.Get, LiveEndpoint);
        request.Headers.Add(CorrelationIdHeader, correlationId);

        var response = await _client.SendAsync(request);

        response.Headers.TryGetValues(CorrelationIdHeader, out var values).ShouldBeTrue();
        values.ShouldContain(correlationId);
    }
}
