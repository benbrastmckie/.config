#!/bin/bash

# Start MCP Hub script for reliable MCP integration
# This ensures MCP Hub starts correctly with all servers

set -e

# Configuration
MCP_HUB_PORT=37373
MCP_CONFIG="/home/benjamin/.config/mcphub/servers.json"
MCP_HUB_BINARY="/home/benjamin/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/node_modules/.bin/mcp-hub"

# Check if MCP Hub is already running
if curl -s "http://localhost:$MCP_HUB_PORT/api/servers" > /dev/null 2>&1; then
    echo "MCP Hub is already running on port $MCP_HUB_PORT"
    exit 0
fi

# Kill any existing MCP processes
pkill -f "mcp-hub" || true
pkill -f "tavily-mcp" || true  
pkill -f "context7-mcp" || true
pkill -f "mcp-server-github" || true

# Wait a moment for processes to terminate
sleep 2

# Check if binary exists
if [ ! -f "$MCP_HUB_BINARY" ]; then
    echo "Error: MCP Hub binary not found at $MCP_HUB_BINARY"
    exit 1
fi

# Check if config exists
if [ ! -f "$MCP_CONFIG" ]; then
    echo "Error: MCP config not found at $MCP_CONFIG"
    exit 1
fi

# Start MCP Hub in background
echo "Starting MCP Hub on port $MCP_HUB_PORT..."
"$MCP_HUB_BINARY" \
    --port "$MCP_HUB_PORT" \
    --config "$MCP_CONFIG" \
    --auto-shutdown \
    --shutdown-delay 600000 \
    > /tmp/mcp-hub.log 2>&1 &

# Wait for startup
echo "Waiting for MCP Hub to start..."
for i in {1..30}; do
    if curl -s "http://localhost:$MCP_HUB_PORT/api/servers" > /dev/null 2>&1; then
        echo "MCP Hub started successfully!"
        # Show connected servers
        echo "Connected MCP servers:"
        curl -s "http://localhost:$MCP_HUB_PORT/api/servers" | jq -r '.servers[] | select(.status == "connected") | "- \(.displayName) (\(.name))"' 2>/dev/null || echo "  (Unable to parse server list)"
        exit 0
    fi
    sleep 1
done

echo "Error: MCP Hub failed to start within 30 seconds"
echo "Check logs at /tmp/mcp-hub.log"
exit 1