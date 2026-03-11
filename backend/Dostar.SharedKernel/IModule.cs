using Asp.Versioning;

namespace Dostar.SharedKernel;

public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
}

public interface IEndpointModule : IModule
{
    ApiVersion Version => new(1, 0);
    void MapEndpoints(IEndpointRouteBuilder app);
}
