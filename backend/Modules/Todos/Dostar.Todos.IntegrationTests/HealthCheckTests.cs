namespace Dostar.Todos.IntegrationTests;

public class HealthCheckTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private const string LiveEndpoint = "/healthz/live";
    private const string ReadyEndpoint = "/healthz/ready";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task LiveEndpoint_WhenCalled_ReturnsHealthy()
    {
        var response = await _client.GetAsync(LiveEndpoint);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
    }

    [Fact]
    public async Task ReadyEndpoint_WithRunningDatabase_ReturnsHealthy()
    {
        var response = await _client.GetAsync(ReadyEndpoint);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
    }
}
