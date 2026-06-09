# Strip everything except project/solution/props files so the restore layer is
# cached independently of source changes. New modules are picked up automatically.
FROM alpine AS project-files
WORKDIR /src
COPY . .
RUN find . -type f \
    ! -name "*.csproj" \
    ! -name "*.slnx" \
    ! -name "*.props" \
    ! -name "*.targets" \
    -delete \
  && find . -mindepth 1 -empty -type d -delete

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore — cached until project/props files change
COPY --from=project-files /src .
RUN dotnet restore backend/Dostar.Api/Dostar.Api.csproj

COPY backend/ backend/
RUN dotnet publish backend/Dostar.Api/Dostar.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

USER app
ENTRYPOINT ["dotnet", "Dostar.Api.dll"]
