# syntax=docker/dockerfile:1
# ============================================================================
#  Custom Open Terminal
#  Based on the slim image with multi-user support, sudo, and custom tools.
# ============================================================================

# https://github.com/open-webui/open-terminal/blob/main/Dockerfile.slim
FROM ghcr.io/open-webui/open-terminal:0.12.5-slim

USER root

# ── sudo + multi-user prerequisites ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages pyyaml requests

RUN ARCH=$(dpkg --print-architecture) \
    && KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt) \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
       -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" \
       -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq \
    && curl -fsSL "https://github.com/regclient/regclient/releases/latest/download/regctl-linux-${ARCH}" \
       -o /usr/local/bin/regctl && chmod +x /usr/local/bin/regctl \
    && GH_VERSION=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
       | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xz -C /tmp \
    && mv "/tmp/gh_${GH_VERSION}_linux_${ARCH}/bin/gh" /usr/local/bin/gh \
    && rm -rf /tmp/gh_*

# Passwordless sudo for the default user
RUN echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Capability-bearing Python binary for multi-user setgroups().
# The system python3 stays clean so user-spawned processes remain dumpable.
RUN cp "$(readlink -f "$(which python3)")" /usr/local/bin/python3-ot \
    && setcap cap_setgid+ep /usr/local/bin/python3-ot \
    && sed -i "1s|.*|#!/usr/local/bin/python3-ot|" "$(which open-terminal)"

COPY entrypoint.sh /app/custom-entrypoint.sh
RUN chmod +x /app/custom-entrypoint.sh

USER user
ENV SHELL=/bin/bash
ENV PATH="/home/user/.local/bin:${PATH}"
WORKDIR /home/user
EXPOSE 8000

ENTRYPOINT ["/usr/bin/tini", "--", "/app/custom-entrypoint.sh"]
CMD ["run"]
