#!/usr/bin/env bash
# ngrok_ssh_tunnel.sh
set -euo pipefail

PORT="${1:-22}"

# Read token from env var (recommended) or file
if [[ -z "${NGROK_AUTHTOKEN:-}" ]]; then
  echo "ERROR: Set NGROK_AUTHTOKEN env var (do not hardcode tokens in scripts)."
  exit 1
fi

if ! command -v ngrok >/dev/null 2>&1; then
  echo "ERROR: ngrok is not installed. Install it first: https://ngrok.com/download"
  exit 1
fi

# Configure token (writes to ~/.config/ngrok/ngrok.yml or equivalent)
ngrok config add-authtoken "${NGROK_AUTHTOKEN}" >/dev/null

echo "Starting ngrok TCP tunnel to localhost:${PORT} ..."
echo "When it prints something like: tcp://X.tcp.ngrok.io:YYYYY"
echo "connect from another computer with: ssh -p YYYYY <user>@X.tcp.ngrok.io"
echo

exec ngrok tcp "${PORT}" --log=stdout
