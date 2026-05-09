#!/bin/bash
set -e

# ============================================================================
#  Custom Open Terminal — Entrypoint
#
#  Features: multi-user, runtime package installation
#  Not supported: egress firewall, docker socket
# ============================================================================

# ── Docker-secrets: resolve <VAR>_FILE → <VAR> ───────────────────────────────
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var+set}" = "set" ] && [ "${!fileVar+set}" = "set" ]; then
        printf >&2 'error: both %s and %s are set (but are exclusive)\n' "$var" "$fileVar"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

file_env 'OPEN_TERMINAL_API_KEY'

# ── Home directory setup ──────────────────────────────────────────────────────
OWNER=$(stat -c '%U' /home/user 2>/dev/null || echo "user")
if [ "$OWNER" != "user" ]; then
    sudo chown -R user:user /home/user 2>/dev/null || true
fi

if [ ! -f /home/user/.bashrc ]; then
    cp /etc/skel/.bashrc /home/user/.bashrc 2>/dev/null || true
fi
if [ ! -f /home/user/.profile ]; then
    cp /etc/skel/.profile /home/user/.profile 2>/dev/null || true
fi
mkdir -p /home/user/.local/bin

# ── Runtime package installation ──────────────────────────────────────────────
if [ -n "${OPEN_TERMINAL_PACKAGES:-}" ]; then
    echo "Installing system packages: $OPEN_TERMINAL_PACKAGES"
    sudo apt-get update -qq && apt-get install -y --no-install-recommends $OPEN_TERMINAL_PACKAGES
    sudo rm -rf /var/lib/apt/lists/*
fi

if [ -n "${OPEN_TERMINAL_PIP_PACKAGES:-}" ]; then
    echo "Installing pip packages: $OPEN_TERMINAL_PIP_PACKAGES"
    if [ "${OPEN_TERMINAL_MULTI_USER:-false}" = "true" ]; then
        sudo pip install --no-cache-dir $OPEN_TERMINAL_PIP_PACKAGES
    else
        pip install --no-cache-dir $OPEN_TERMINAL_PIP_PACKAGES
    fi
fi

# ── Launch ────────────────────────────────────────────────────────────────────
export HOME="/home/user"
export PATH="/home/user/.local/bin:${PATH}"

exec open-terminal "$@"
