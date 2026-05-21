#!/bin/bash

# ==========================================
# CONFIGURATION SECTION
# ==========================================

# The computer you are connecting TO (the gateway)
REMOTE_USER="myuser"
REMOTE_HOST="server-ip-address-or-name.com"
REMOTE_PORT="22" # Usually 22, check your provider

# The type of tunnel and ports
# OPTIONS:
# 1. DYNAMIC (-D): Creates a SOCKS5 proxy. Use this to browse the web 
#    as if you were on the remote computer, or access multiple apps.
# 2. LOCAL   (-L): Opens a specific port on your computer that connects 
#    to a specific port on the remote computer.
TUNNEL_MODE="DYNAMIC" 

# SETTINGS FOR DYNAMIC TUNNEL (SOCKS Proxy)
LOCAL_SOCKS_PORT="9090"

# SETTINGS FOR LOCAL PORT FORWARD
# Example: Access a web app (localhost:80) on the remote server 
# via your local port 8000
LOCAL_FORWARD_PORT="8000"
REMOTE_DESTINATION="localhost:80" 

# SSH CONTROL
# -o options keep the connection alive and reduce disconnects
SSH_OPTIONS="-o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes"

# AUTHENTICATION
# Uncomment the line below if your key is in a specific location, 
# otherwise SSH uses ~/.ssh/id_rsa by default
# SSH_KEY="/path/to/your/private/key"

# ==========================================
# SCRIPT LOGIC (usually no need to edit below)
# ==========================================

# Check if autossh is installed
if ! command -v autossh &> /dev/null; then
    echo "Error: 'autossh' is not installed."
    echo "Install it via: brew install autossh (Mac) or apt install autossh (Linux)"
    exit 1
fi

echo "Starting SSH Tunnel..."

# Construct the SSH command dynamically based on mode
if [ "$TUNNEL_MODE" == "DYNAMIC" ]; then
    echo "Mode: Dynamic SOCKS Proxy"
    echo "Connect your browser/app to localhost:$LOCAL_SOCKS_PORT"
    
    # We use two ports for autossh: the tunnel port (local) and the monitor port
    # The monitor port must be distinct from the tunnel port
    AUTOSSH_MONITORPORT=$((LOCAL_SOCKS_PORT + 1))
    
    autossh -M $AUTOSSH_MONITORPORT \
        -N -f -i "$SSH_KEY" \
        -D $LOCAL_SOCKS_PORT \
        -p $REMOTE_PORT $SSH_OPTIONS \
        $REMOTE_USER@$REMOTE_HOST

elif [ "$TUNNEL_MODE" == "LOCAL" ]; then
    echo "Mode: Local Port Forward"
    echo "Access remote service via localhost:$LOCAL_FORWARD_PORT"
    
    AUTOSSH_MONITORPORT=$((LOCAL_FORWARD_PORT + 1))

    autossh -M $AUTOSSH_MONITORPORT \
        -N -f -i "$SSH_KEY" \
        -L $LOCAL_FORWARD_PORT:$REMOTE_DESTINATION \
        -p $REMOTE_PORT $SSH_OPTIONS \
        $REMOTE_USER@$REMOTE_HOST

else
    echo "Invalid TUNNEL_MODE in configuration. Use 'DYNAMIC' or 'LOCAL'"
    exit 1
fi

# Capture the exit code
if [ $? -eq 0 ]; then
    echo "Tunnel started successfully in the background."
else
    echo "Failed to start tunnel. Check your network/credentials."
fi
