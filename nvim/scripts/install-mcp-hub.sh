#!/bin/bash
# Script to manually install MCP-Hub for NixOS
# Run this script with: bash ~/.config/nvim/scripts/install-mcp-hub.sh

set -e  # Exit on error

# Create directories
PLUGIN_DIR="$HOME/.local/share/nvim/lazy/mcphub.nvim"
BUNDLED_DIR="$PLUGIN_DIR/bundled"
MCP_DIR="$BUNDLED_DIR/mcp-hub"

echo "Creating directories..."
mkdir -p "$MCP_DIR"
mkdir -p "$MCP_DIR/.npm"
mkdir -p "$MCP_DIR/.npm-cache"
mkdir -p "$MCP_DIR/.npm-tmp"

# Create package.json
echo "Creating package.json..."
cat > "$MCP_DIR/package.json" << 'EOF'
{
  "name": "mcp-hub-bundled",
  "version": "1.0.0", 
  "description": "Bundled MCP-Hub for NeoVim",
  "private": true,
  "dependencies": {
    "mcp-hub": "latest"
  }
}
EOF

# Create .npmrc for NixOS
echo "Creating .npmrc for NixOS..."
cat > "$MCP_DIR/.npmrc" << 'EOF'
prefix=${PWD}/.npm
cache=${PWD}/.npm-cache
tmp=${PWD}/.npm-tmp
EOF

# Install mcp-hub
echo "Installing mcp-hub with npm..."
cd "$MCP_DIR"
npm install --no-global --prefix="$MCP_DIR"

# Make binary executable
BINARY_PATH="$MCP_DIR/node_modules/.bin/mcp-hub"
if [ -f "$BINARY_PATH" ]; then
    echo "Making binary executable..."
    chmod +x "$BINARY_PATH"
    echo "Done! MCP-Hub binary installed at: $BINARY_PATH"
else
    echo "Binary not found at expected path: $BINARY_PATH"
    echo "Searching for binary..."
    FOUND_BINARY=$(find "$MCP_DIR" -name 'mcp-hub' -type f | head -n 1)
    if [ -n "$FOUND_BINARY" ]; then
        echo "Found binary at: $FOUND_BINARY"
        chmod +x "$FOUND_BINARY"
        echo "Made binary executable"
    else
        echo "Error: MCP-Hub binary not found"
        exit 1
    fi
fi

echo "Installation complete!"
echo "You can now use :MCPHub in Neovim"