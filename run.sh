
                #!/bin/bash
# SSH Tunnel Script
# Usage: ./ssh_tunnel.sh [options]

# Configuration - Edit these values
REMOTE_HOST="remote.server.com"
REMOTE_USER="username"
REMOTE_PORT="22"
LOCAL_PORT="8080"
REMOTE_SERVICE_PORT="80"
SSH_KEY="~/.ssh/id_rsa"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --host     Remote host (default: $REMOTE_HOST)"
    echo "  -u, --user     Remote username (default: $REMOTE_USER)"
    echo "  -p, --port     Remote SSH port (default: $REMOTE_PORT)"
    echo "  -l, --local    Local port (default: $LOCAL_PORT)"
    echo "  -r, --rport    Remote service port (default: $REMOTE_SERVICE_PORT)"
    echo "  -k, --key      SSH key file (default: $SSH_KEY)"
    echo "  -t, --type     Tunnel type: local, remote, dynamic (default: local)"
    echo "  -b, --bg       Run in background"
    echo "  -c, --close    Close existing tunnel"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -h myserver.com -u john -l 8080 -r 80"
    echo "  $0 --type dynamic -l 9090  (SOCKS proxy)"
    exit 1
}

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0
    else
        return 1
    fi
}

# Function to close existing tunnel
close_tunnel() {
    echo -e "${YELLOW}Closing existing tunnel on port $LOCAL_PORT...${NC}"
    PID=$(lsof -ti :$LOCAL_PORT)
    if [ -n "$PID" ]; then
        kill $PID
        echo -e "${GREEN}Tunnel closed successfully!${NC}"
    else
        echo -e "${YELLOW}No tunnel found on port $LOCAL_PORT${NC}"
    fi
    exit 0
}

# Parse command line arguments
RUN_BACKGROUND=false
TUNNEL_TYPE="local"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            REMOTE_HOST="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -p|--port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        -l|--local)
            LOCAL_PORT="$2"
            shift 2
            ;;
        -r|--rport)
            REMOTE_SERVICE_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -t|--type)
            TUNNEL_TYPE="$2"
            shift 2
            ;;
        -b|--bg)
            RUN_BACKGROUND=true
            shift
            ;;
        -c|--close)
            close_tunnel
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Build SSH tunnel command based on type
case $TUNNEL_TYPE in
    local)
        # Local port forwarding: localhost:LOCAL_PORT -> remote:REMOTE_SERVICE_PORT
        SSH_CMD="ssh -i $SSH_KEY -p $REMOTE_PORT -L $LOCAL_PORT:localhost:$REMOTE_SERVICE_PORT $REMOTE_USER@$REMOTE_HOST"
        DESCRIPTION="Local tunnel: localhost:$LOCAL_PORT → $REMOTE_HOST:$REMOTE_SERVICE_PORT"
        ;;
    remote)
        # Remote port forwarding: remote:REMOTE_PORT -> localhost:LOCAL_PORT
        SSH_CMD="ssh -i $SSH_KEY -p $REMOTE_PORT -R $REMOTE_PORT:localhost:$LOCAL_PORT $REMOTE_USER@$REMOTE_HOST"
        DESCRIPTION="Remote tunnel: $REMOTE_HOST:$REMOTE_PORT → localhost:$LOCAL_PORT"
        ;;
    dynamic)
        # Dynamic port forwarding (SOCKS proxy)
        SSH_CMD="ssh -i $SSH_KEY -p $REMOTE_PORT -D $LOCAL_PORT $REMOTE_USER@$REMOTE_HOST"
        DESCRIPTION="Dynamic tunnel (SOCKS): localhost:$LOCAL_PORT"
        ;;
    *)
        echo -e "${RED}Invalid tunnel type: $TUNNEL_TYPE${NC}"
        usage
        ;;
esac

# Display tunnel information
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔐 SSH Tunnel Configuration${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Type:${NC} $TUNNEL_TYPE"
echo -e "${YELLOW}Description:${NC} $DESCRIPTION"
echo -e "${YELLOW}Remote Host:${NC} $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
echo -e "${YELLOW}SSH Key:${NC} $SSH_KEY"
echo -e "${GREEN}========================================${NC}"

# Check if port is already in use
if check_port $LOCAL_PORT; then
    echo -e "${RED}Error: Port $LOCAL_PORT is already in use!${NC}"
    echo -e "${YELLOW}Hint: Use -c to close existing tunnel or -l to specify different port${NC}"
    exit 1
fi

# Add background flag if requested
if [ "$RUN_BACKGROUND" = true ]; then
    SSH_CMD="$SSH_CMD -f -N"
    echo -e "${YELLOW}Running in background...${NC}"
else
    echo -e "${YELLOW}Press Ctrl+C to close the tunnel${NC}"
fi

# Add keep-alive options
SSH_CMD="$SSH_CMD -o ServerAliveInterval=60 -o ServerAliveCountMax=3"

# Execute SSH tunnel
echo -e "${GREEN}🚀 Starting tunnel...${NC}"
eval $SSH_CMD

if [ $? -eq 0 ]; then
    if [ "$RUN_BACKGROUND" = true ]; then
        echo -e "${GREEN}✅ Tunnel established in background!${NC}"
        echo -e "${YELLOW}To close: $0 -c${NC}"
    fi
else
    echo -e "${RED}❌ Failed to establish tunnel${NC}"
    exit 1
fi
            
