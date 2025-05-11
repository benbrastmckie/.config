#!/bin/bash
# Advanced MCP-Hub installation script for NixOS
# This script handles all aspects of installing MCP-Hub on NixOS
# with detailed error handling and diagnostics.

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with colors
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Define directories
PLUGIN_DIR="$HOME/.local/share/nvim/lazy/mcphub.nvim"
BUNDLED_DIR="$PLUGIN_DIR/bundled"
MCP_DIR="$BUNDLED_DIR/mcp-hub"
NODE_PATH=$(which node)
NPM_PATH=$(which npm)

# Print header
echo "================================================"
echo "  MCP-Hub NixOS Installation Script"
echo "================================================"
echo

# Check environment
info "Checking environment..."
echo " - NixOS: $(test -f /etc/NIXOS && echo 'Yes' || echo 'No')"
echo " - Node.js: $NODE_PATH ($(node --version 2>/dev/null || echo 'Not found'))"
echo " - npm: $NPM_PATH ($(npm --version 2>/dev/null || echo 'Not found'))"

if [ ! -x "$NODE_PATH" ]; then
    error "Node.js not found or not executable. Please install Node.js first."
    echo "Add this to your NixOS configuration:"
    echo "  environment.systemPackages = with pkgs; [ nodejs ];"
    exit 1
fi

if [ ! -x "$NPM_PATH" ]; then
    warn "npm not found, will try to use the one bundled with Node.js"
fi

# Create directories
info "Creating directories..."
mkdir -p "$MCP_DIR"
mkdir -p "$MCP_DIR/.npm"
mkdir -p "$MCP_DIR/.npm-cache"
mkdir -p "$MCP_DIR/.npm-tmp"
success "Created all required directories"

# Create package.json
info "Creating package.json..."
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
success "Created package.json"

# Create .npmrc for NixOS
info "Creating .npmrc for NixOS..."
cat > "$MCP_DIR/.npmrc" << 'EOF'
prefix=${PWD}/.npm
cache=${PWD}/.npm-cache
tmp=${PWD}/.npm-tmp
EOF
success "Created .npmrc configuration"

# Install mcp-hub
info "Installing mcp-hub with npm..."
cd "$MCP_DIR"
npm install --no-global 2>&1
success "npm install completed"

# Check for the binary
BINARY_PATH="$MCP_DIR/node_modules/.bin/mcp-hub"
if [ -f "$BINARY_PATH" ]; then
    info "Making binary executable..."
    chmod +x "$BINARY_PATH"
    success "Binary installed at: $BINARY_PATH"
else
    warn "Binary not found at expected path: $BINARY_PATH"
    info "Searching for binary..."
    FOUND_BINARY=$(find "$MCP_DIR" -name 'mcp-hub' -type f | head -n 1)
    if [ -n "$FOUND_BINARY" ]; then
        info "Found binary at: $FOUND_BINARY"
        chmod +x "$FOUND_BINARY"
        BINARY_PATH="$FOUND_BINARY"
        success "Made binary executable"
    else
        error "MCP-Hub binary not found! Installation failed."
        exit 1
    fi
fi

# Create wrapper script
info "Creating wrapper script with absolute Node.js path..."
cat > "$MCP_DIR/mcp-hub-wrapper" << EOF
#!/bin/sh
# MCP-Hub wrapper for NixOS
# Created by installation script on $(date)

export NODE_PATH="$NODE_PATH"
exec "$NODE_PATH" "\$(readlink -f "$BINARY_PATH")" "\$@"
EOF
chmod +x "$MCP_DIR/mcp-hub-wrapper"
success "Created wrapper script at: $MCP_DIR/mcp-hub-wrapper"

# Update plugin configuration
info "Checking plugin configuration..."
MCP_HUB_LUA="$HOME/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua"
if [ -f "$MCP_HUB_LUA" ]; then
    info "Plugin configuration found at: $MCP_HUB_LUA"
    echo
    info "You may need to update your configuration to use the wrapper script:"
    echo
    echo "In $MCP_HUB_LUA, update the setup_config to:"
    echo
    echo "local setup_config = {"
    echo "  use_bundled_binary = false,"
    echo "  cmd = vim.fn.expand(\"~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub/mcp-hub-wrapper\"),"
    echo "  cmdArgs = {},"
    echo "  -- other settings..."
    echo "}"
fi

# Final instructions
echo
echo "================================================"
success "Installation complete!"
echo "================================================"
echo
echo "To use MCP-Hub in Neovim:"
echo "1. Run :MCPHub command"
echo "2. If still having issues, run :MCPHubDiagnose for diagnostics"
echo "3. For debugging, check Neovim messages with :messages"
echo
echo "Wrapper script path (use this in your config):"
echo "$MCP_DIR/mcp-hub-wrapper"