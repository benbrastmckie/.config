#!/usr/bin/env bash
#
# Claude Code-Assisted Neovim Configuration Setup
# This script automates the setup process with Claude Code guidance
#
# Usage: bash setup-with-claude.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NVIM_CONFIG_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Claude Code-Assisted Neovim Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print section headers
print_section() {
  echo ""
  echo -e "${BLUE}>>> $1${NC}"
  echo ""
}

# Function to print success
print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

# Function to print error
print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Check if Claude Code is installed
print_section "Step 1: Checking Claude Code Installation"

if command -v claude &>/dev/null; then
  print_success "Claude Code is installed"
  claude --version
else
  print_error "Claude Code is not installed"
  echo ""
  echo "Please install Claude Code first:"
  echo ""
  echo "  macOS/Linux/WSL:"
  echo "    curl -fsSL https://claude.ai/install.sh | bash"
  echo ""
  echo "  Windows PowerShell:"
  echo "    irm https://claude.ai/install.ps1 | iex"
  echo ""
  echo "After installation, run this script again."
  exit 1
fi

# Backup existing configuration
print_section "Step 2: Backing Up Existing Configuration"

if [ -d "$NVIM_CONFIG_DIR" ]; then
  print_warning "Existing Neovim configuration found"
  echo "Backing up to: $BACKUP_DIR"
  mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
  print_success "Backup created"
else
  print_success "No existing configuration to backup"
fi

# Check if repository is already cloned
print_section "Step 3: Repository Setup"

if [ -d "$NVIM_CONFIG_DIR/.git" ]; then
  print_success "Repository already cloned at $NVIM_CONFIG_DIR"
else
  print_warning "Repository not cloned yet"
  echo ""
  echo "You need to fork and clone the repository first."
  echo ""
  echo "Recommended: Use Claude Code to help with this step"
  echo ""
  echo "Launch Claude Code and ask:"
  echo "  'Help me fork [repository URL] and clone it to ~/.config/nvim'"
  echo ""
  echo "Or manually:"
  echo "  1. Fork the repository on GitHub"
  echo "  2. Run: git clone [your-fork-url] $NVIM_CONFIG_DIR"
  echo "  3. Run: cd $NVIM_CONFIG_DIR && git remote add upstream [original-repo-url]"
  echo ""
  read -p "Press Enter after you've cloned the repository, or Ctrl+C to exit..."
fi

# Verify repository is cloned
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  print_error "Repository not found at $NVIM_CONFIG_DIR"
  echo "Please clone the repository and run this script again."
  exit 1
fi

cd "$NVIM_CONFIG_DIR"
print_success "Working in: $NVIM_CONFIG_DIR"

# Run dependency checker
print_section "Step 4: Checking Dependencies"

if [ -f "$NVIM_CONFIG_DIR/scripts/check-dependencies.sh" ]; then
  bash "$NVIM_CONFIG_DIR/scripts/check-dependencies.sh"
  DEPS_EXIT=$?

  if [ $DEPS_EXIT -ne 0 ]; then
    echo ""
    print_warning "Some dependencies are missing"
    echo ""
    echo "Options:"
    echo "  1. Use Claude Code to install dependencies"
    echo "  2. Install manually using platform guides in docs/platform/"
    echo ""
    echo "To use Claude Code:"
    echo "  Launch: claude"
    echo "  Ask: 'I'm on [platform]. Install all missing dependencies.'"
    echo ""
    read -p "Press Enter after installing dependencies, or Ctrl+C to exit..."
  else
    print_success "All dependencies met"
  fi
else
  print_warning "Dependency checker not found"
  echo "Continuing anyway..."
fi

# Configure Git remotes
print_section "Step 5: Verifying Git Remotes"

if git remote | grep -q "upstream"; then
  print_success "Upstream remote configured"
  git remote -v | grep upstream
else
  print_warning "Upstream remote not configured"
  echo ""
  echo "You should configure upstream remote to receive updates."
  echo "Use Claude Code to help:"
  echo "  'Configure upstream remote for this fork'"
fi

# First launch preparation
print_section "Step 6: Ready for First Launch"

echo "Your Neovim configuration is ready to launch!"
echo ""
echo "Next steps:"
echo "  1. Launch Neovim: nvim"
echo "  2. Wait for plugins to install (2-5 minutes)"
echo "  3. Run health check: :checkhealth"
echo "  4. Fix any issues with Claude Code's help"
echo ""
echo "For troubleshooting during first launch:"
echo "  - Keep Neovim open in one terminal"
echo "  - Open Claude Code in another terminal"
echo "  - Ask Claude for help with any errors"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""

# Offer to launch Claude Code
read -p "Would you like to launch Claude Code now for assistance? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  exec claude
fi
