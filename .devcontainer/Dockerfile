# .devcontainer/Dockerfile

ARG VARIANT="ubuntu"
FROM mcr.microsoft.com/devcontainers/base:ubuntu


ENV DEBIAN_FRONTEND=noninteractive

# Install tooling and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release sudo git apt-transport-https \
      python3 python3-pip make build-essential \
      asciinema && \
    rm -rf /var/lib/apt/lists/*


# Install GitHub CLI (deb repo) - official packaging
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Install Git Credential Manager Core (auto-detect .deb asset)
RUN set -eux; \
    API="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"; \
    ASSET_URL=$(curl -fsSL "$API" \
      | grep '"browser_download_url"' \
      | grep 'gcm-linux_amd64.*\.deb"' \
      | cut -d '"' -f4 \
      | head -n1); \
    test -n "$ASSET_URL"; \
    echo "Downloading: $ASSET_URL"; \
    curl -fsSL -o /tmp/gcm.deb "$ASSET_URL"; \
    apt-get update; \
    apt-get install -y /tmp/gcm.deb; \
    rm -f /tmp/gcm.deb; \
    rm -rf /var/lib/apt/lists/*; \
    # Package provides 'git-credential-manager'; add compat symlink
    ln -sf "$(command -v git-credential-manager)" /usr/bin/git-credential-manager-core || true; \
    git-credential-manager --version || true    




 
# Optional: expose git/gh bin in PATH (should be default)
ENV PATH=/usr/bin:$PATH