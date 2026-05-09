# Custom Open Terminal

Custom Docker image based on [open-terminal](https://github.com/open-webui/open-terminal) slim, with multi-user support, sudo access, and custom tools.

## Features

- Based on `ghcr.io/open-webui/open-terminal:<version>-slim` (~430 MB)
- Multi-user isolation (`OPEN_TERMINAL_MULTI_USER=true`)
- Sudo access for the default user
- Runtime package installation via environment variables
- Multi-arch: linux/amd64, linux/arm64
- Updated base image via Renovate

## Usage

```bash
docker run -d -p 8000:8000 \
  -e OPEN_TERMINAL_API_KEY=secret \
  ghcr.io/<your-username>/custom-open-terminal:latest
```

### Multi-user mode

```bash
docker run -d -p 8000:8000 \
  -e OPEN_TERMINAL_API_KEY=secret \
  -e OPEN_TERMINAL_MULTI_USER=true \
  ghcr.io/<your-username>/custom-open-terminal:latest
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPEN_TERMINAL_API_KEY` | API key for authentication (supports `_FILE` suffix for Docker secrets) |
| `OPEN_TERMINAL_MULTI_USER` | Set to `true` to enable per-user OS account isolation |
| `OPEN_TERMINAL_PACKAGES` | Space-separated apt packages to install at startup |
| `OPEN_TERMINAL_PIP_PACKAGES` | Space-separated pip packages to install at startup |
