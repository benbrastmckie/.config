#!/usr/bin/env bash
# MCP-Hub Setup Script for NixOS
# This script handles the setup and installation of MCP-Hub for NeoVim integration
# It ensures compatibility with NixOS through uvx

set -e

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage information
print_usage() {
  echo -e "${BLUE}MCP-Hub Setup Script for NixOS${NC}"
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help        Show this help message"
  echo "  -i, --install     Install or update mcp-hub"
  echo "  -c, --check       Check if mcp-hub is installed"
  echo "  -v, --version     Show version information"
  echo "  -u, --uninstall   Uninstall mcp-hub"
  echo ""
  echo "This script manages the MCP-Hub installation for NeoVim through uvx."
}

# Check if uvx is installed
check_uvx() {
  echo -e "${BLUE}Checking for uvx...${NC}"
  if ! command -v uvx &> /dev/null; then
    echo -e "${RED}Error: uvx is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}Please install uvx first. On NixOS, you can use:${NC}"
    echo "  nix-env -iA nixpkgs.uvx"
    echo "or add it to your configuration.nix"
    exit 1
  else
    echo -e "${GREEN} uvx found: $(which uvx)${NC}"
  fi
}

# Check if mcp-hub is installed
check_mcp_hub() {
  echo -e "${BLUE}Checking if mcp-hub is installed...${NC}"
  if uvx list | grep -q "mcp-hub"; then
    MCP_HUB_VERSION=$(uvx list | grep "mcp-hub" | awk '{print $2}')
    echo -e "${GREEN} mcp-hub is installed (version: $MCP_HUB_VERSION)${NC}"
    return 0
  else
    echo -e "${YELLOW}mcp-hub is not installed${NC}"
    return 1
  fi
}

# Install or update mcp-hub
install_mcp_hub() {
  echo -e "${BLUE}Installing/updating mcp-hub...${NC}"
  
  # Check if mcp-hub is already installed
  if check_mcp_hub; then
    echo -e "${BLUE}Updating mcp-hub...${NC}"
    uvx upgrade mcp-hub
    echo -e "${GREEN} mcp-hub has been updated${NC}"
  else
    echo -e "${BLUE}Installing mcp-hub...${NC}"
    uvx install mcp-hub
    
    # Verify installation
    if check_mcp_hub; then
      echo -e "${GREEN} mcp-hub has been successfully installed${NC}"
    else
      echo -e "${RED}× Failed to install mcp-hub${NC}"
      exit 1
    fi
  fi
}

# Uninstall mcp-hub
uninstall_mcp_hub() {
  echo -e "${BLUE}Uninstalling mcp-hub...${NC}"
  if check_mcp_hub; then
    uvx uninstall mcp-hub
    echo -e "${GREEN} mcp-hub has been uninstalled${NC}"
  else
    echo -e "${YELLOW}mcp-hub is not installed, nothing to uninstall${NC}"
  fi
}

# Show version information
show_version() {
  echo -e "${BLUE}MCP-Hub Setup Script v1.0.0${NC}"
  echo -e "${BLUE}uvx version:${NC} $(uvx --version 2>&1)"
  if check_mcp_hub; then
    echo -e "${BLUE}mcp-hub version:${NC} $MCP_HUB_VERSION"
  fi
}

# Create necessary configuration directories
setup_config_dirs() {
  echo -e "${BLUE}Setting up configuration directories...${NC}"
  MCP_CONFIG_DIR="$HOME/.config/mcphub"
  
  if [ ! -d "$MCP_CONFIG_DIR" ]; then
    mkdir -p "$MCP_CONFIG_DIR"
    echo -e "${GREEN} Created $MCP_CONFIG_DIR${NC}"
  else
    echo -e "${GREEN} $MCP_CONFIG_DIR already exists${NC}"
  fi
  
  # Create a default servers.json file if it doesn't exist
  if [ ! -f "$MCP_CONFIG_DIR/servers.json" ]; then
    cat > "$MCP_CONFIG_DIR/servers.json" << EOF
{
  "servers": [
    {
      "name": "default",
      "description": "Default MCP Hub server",
      "url": "http://localhost:37373",
      "apiKey": "",
      "default": true
    }
  ]
}
EOF
    echo -e "${GREEN} Created default servers.json configuration${NC}"
  fi
}

# Main execution
if [[ $# -eq 0 ]]; then
  print_usage
  exit 0
fi

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
      ;;
    -i|--install)
      check_uvx
      install_mcp_hub
      setup_config_dirs
      exit 0
      ;;
    -c|--check)
      check_uvx
      check_mcp_hub
      exit 0
      ;;
    -v|--version)
      check_uvx
      show_version
      exit 0
      ;;
    -u|--uninstall)
      check_uvx
      uninstall_mcp_hub
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      print_usage
      exit 1
      ;;
  esac
  shift
done