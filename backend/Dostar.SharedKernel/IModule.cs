namespace Dostar.SharedKernel;

public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
}

public interface IEndpointModule : IModule
{
    void MapEndpoints(IEndpointRouteBuilder app);
}
