namespace Dostar.SharedKernel;

public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
    void MapEndpoints(IEndpointRouteBuilder app);
}
