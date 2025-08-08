FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /usr/src/app

# Copy everything
COPY . .
# Restore as distinct layers
RUN dotnet restore BingusApi
# Build and publish a release
RUN dotnet publish BingusApi -c Release -o out -p:CSharpier_Bypass=true

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /usr/src/app

# Install LLamaSharp runtime dependencies
# Fix GPG/repository issues and ensure critical dependencies install
RUN apt update --fix-missing \
    && apt install -y --no-install-recommends --fix-broken \
        ca-certificates \
        apt-transport-https \
        gnupg \
    && apt update \
    && apt install -y --no-install-recommends \
        libgomp1 \
        musl \
        libsnappy1v5 \
        libjemalloc2 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks if libraries exist
RUN test -f /usr/lib/x86_64-linux-musl/libc.so && ln -s /usr/lib/x86_64-linux-musl/libc.so /lib/libc.musl-x86_64.so.1 || true
RUN test -f /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 && ln -s /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 || true

COPY --from=build-env /usr/src/app/out .
ENTRYPOINT ["./BingusApi"]
