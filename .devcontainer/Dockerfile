# Prebuilt devcontainer image for Dostar.
# Published to ghcr.io/piers-sinclair/dostar-devcontainer.
#
# What IS in this image (stable tooling that doesn't change per repo or user):
#   .NET SDK, Node.js, pnpm, PostgreSQL client tools, Docker CLI,
#   GitHub CLI, Azure CLI, dotnet-ef, Dostar.Cli, claude-code,
#   Trivy, OpenGrep, Playwright OS deps + Chromium binary.
#
# What is NOT in this image (applied at container setup time):
#   Repo source, NuGet/npm packages, Playwright browsers (named volume),
#   GitHub tokens, database data, .env files, coverlet.
#
# Rebuild triggers: .devcontainer/Dockerfile, .github/workflows/devcontainer-image.yml
# See docs/devcontainer.md for the full architecture.

ARG DOTNET_VERSION=10.0.200
ARG NODE_MAJOR=22
ARG PNPM_VERSION=10.34.4

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG DOTNET_VERSION
ARG NODE_MAJOR
ARG PNPM_VERSION

LABEL org.opencontainers.image.source="https://github.com/piers-sinclair/Dostar"
LABEL org.opencontainers.image.description="Dostar devcontainer — .NET 10 + Node 22 + PostgreSQL client + dev tooling"

# ── OS packages ───────────────────────────────────────────────────────────────
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    postgresql-client \
    python3 \
    unzip \
  && rm -rf /var/lib/apt/lists/*

# ── .NET SDK ──────────────────────────────────────────────────────────────────
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh \
    | bash -s -- --version ${DOTNET_VERSION} --install-dir /usr/share/dotnet \
  && ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet

ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="/usr/share/dotnet:${PATH}"
ENV DOTNET_NOLOGO=true
ENV NUGET_XMLDOC_MODE=skip

# Warm up the SDK (first-run telemetry, etc.) so postCreate dotnet restore is faster.
RUN dotnet help > /dev/null 2>&1 || true

# ── dotnet-ef + Dostar.Cli (pre-installed system-wide) ───────────────────────
RUN dotnet tool install --tool-path /usr/local/dotnet-tools dotnet-ef \
  && dotnet tool install --tool-path /usr/local/dotnet-tools Dostar.Cli \
  && chmod -R a+rx /usr/local/dotnet-tools

ENV PATH="/usr/local/dotnet-tools:${PATH}"

# ── Node.js + pnpm ────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g pnpm@${PNPM_VERSION}

# ── claude-code (pre-installed system-wide) ───────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── GitHub CLI ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list \
  && apt-get update -qq && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# ── Azure CLI ─────────────────────────────────────────────────────────────────
RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

# ── Docker CLI (docker-outside-of-docker) ────────────────────────────────────
# postStart.sh fixes the docker group GID to match the host socket at runtime.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list \
  && apt-get update -qq && apt-get install -y docker-ce-cli docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd docker 2>/dev/null || true \
  && usermod -aG docker vscode

# ── Trivy (CVE scanner) ───────────────────────────────────────────────────────
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null \
  && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    | tee /etc/apt/sources.list.d/trivy.list \
  && apt-get update -qq && apt-get install -y trivy \
  && rm -rf /var/lib/apt/lists/*

# ── OpenGrep (SAST) ───────────────────────────────────────────────────────────
RUN LATEST=$(curl -sf "https://api.github.com/repos/opengrep/opengrep/releases/latest" \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4) \
  && curl -fsSL \
    "https://github.com/opengrep/opengrep/releases/download/${LATEST}/opengrep_manylinux_x86" \
    -o /usr/local/bin/opengrep \
  && chmod +x /usr/local/bin/opengrep

# ── Playwright OS dependencies for Chromium ───────────────────────────────────
# OS-level packages only (browser binary installed later as USER vscode).
RUN npx -y playwright@latest install-deps chromium \
  && rm -rf /var/lib/apt/lists/*

# ── Pre-warm pnpm store ────────────────────────────────────────────────────────
# `pnpm fetch` downloads all lockfile packages into PNPM_HOME during the image
# build so postCreate `pnpm install` hard-links from the store instead of
# hitting the registry. The pnpm-store named volume seeds from this image
# content on first container create and accumulates new packages thereafter.
ENV PNPM_HOME=/usr/local/pnpm-store
RUN mkdir -p /usr/local/pnpm-store && chmod a+rwx /usr/local/pnpm-store
COPY frontend/package.json frontend/pnpm-lock.yaml /tmp/pnpm-pre/fe/
COPY tests/Dostar.UITests/package.json tests/Dostar.UITests/pnpm-lock.yaml /tmp/pnpm-pre/uit/
RUN cd /tmp/pnpm-pre/fe && pnpm fetch \
  && cd /tmp/pnpm-pre/uit && pnpm fetch \
  && rm -rf /tmp/pnpm-pre \
  && chmod -R a+rwx /usr/local/pnpm-store

# ── Pre-warm NuGet cache ───────────────────────────────────────────────────────
# `dotnet restore` as vscode populates /home/vscode/.nuget/packages during the
# image build. The nuget-packages named volume seeds from this on first create.
USER vscode
COPY --chown=vscode:vscode Dostar.slnx Directory.Build.props /tmp/nuget-pre/
COPY --chown=vscode:vscode backend/ /tmp/nuget-pre/backend/
RUN dotnet restore /tmp/nuget-pre/Dostar.slnx \
  && rm -rf /tmp/nuget-pre

# ── Bicep CLI ─────────────────────────────────────────────────────────────────
RUN az bicep install
USER root

# ── Playwright browser (Chromium) ─────────────────────────────────────────────
# Must run as root: pnpm store files are root-owned hard links; only root can
# chmod them. PLAYWRIGHT_BROWSERS_PATH directs the binary to vscode's cache dir.
# The playwright-cache named volume seeds from that path on first container create,
# so postCreate finds the binary and skips the ~130 MB download.
COPY tests/Dostar.UITests/package.json tests/Dostar.UITests/pnpm-lock.yaml /tmp/pw-install/
RUN cd /tmp/pw-install \
  && pnpm install --frozen-lockfile \
  && PLAYWRIGHT_BROWSERS_PATH=/home/vscode/.cache/ms-playwright pnpm exec playwright install chromium \
  && chown -R vscode:vscode /home/vscode/.cache/ms-playwright \
  && rm -rf /tmp/pw-install
