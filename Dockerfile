# syntax=docker/dockerfile:1
# ============================================================================
#  Custom Open Terminal
#  Based on the slim image with multi-user support, sudo, and custom tools.
# ============================================================================

FROM ghcr.io/open-webui/open-terminal:0.11.34-slim

USER root

# ── sudo + multi-user prerequisites ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        python3-pip \
        # ── Add your custom tools below this line ──
        kubectl \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages pyyaml

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
