#!/usr/bin/env bash
# open_reverse_tunnel.sh
# Creates a *reverse* SSH tunnel so you can reach THIS computer from another one
# via a public “jump” server.

set -euo pipefail

# --- CONFIG (edit these) ---
JUMP_HOST="your.public.server.com"   # Publicly reachable SSH server
JUMP_USER="youruser"                # User on the jump server

REMOTE_BIND_ADDR="127.0.0.1"        # Use 127.0.0.1 for safer default.
                                   # Use 0.0.0.0 ONLY if you want other computers
                                   # to connect directly to the port on the jump server
                                   # (requires sshd GatewayPorts, see notes).

REMOTE_PORT="2222"                  # Port that will open on the jump server
LOCAL_HOST="127.0.0.1"              # Where the service is on THIS computer
LOCAL_PORT="22"                     # Service port on THIS computer (22 = SSH)
# ----------------------------

# Prefer autossh if installed (keeps tunnel alive), otherwise fall back to ssh.
if command -v autossh >/dev/null 2>&1; then
  exec autossh -M 0 \
    -N \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -R "${REMOTE_BIND_ADDR}:${REMOTE_PORT}:${LOCAL_HOST}:${LOCAL_PORT}" \
    "${JUMP_USER}@${JUMP_HOST}"
else
  exec ssh \
    -N \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -R "${REMOTE_BIND_ADDR}:${REMOTE_PORT}:${LOCAL_HOST}:${LOCAL_PORT}" \
    "${JUMP_USER}@${JUMP_HOST}"
fi
