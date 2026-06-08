FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY backend/Dostar.Api/Dostar.Api.csproj backend/Dostar.Api/
COPY backend/Dostar.SharedKernel/Dostar.SharedKernel.csproj backend/Dostar.SharedKernel/
COPY backend/Modules/Todos/Dostar.Todos.Contracts/Dostar.Todos.Contracts.csproj backend/Modules/Todos/Dostar.Todos.Contracts/
COPY backend/Modules/Todos/Dostar.Todos.Implementation/Dostar.Todos.Implementation.csproj backend/Modules/Todos/Dostar.Todos.Implementation/
RUN dotnet restore backend/Dostar.Api/Dostar.Api.csproj

COPY backend/ backend/
RUN dotnet publish backend/Dostar.Api/Dostar.Api.csproj \
    -c Release \
    --no-restore \
    -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

USER app
ENTRYPOINT ["dotnet", "Dostar.Api.dll"]
