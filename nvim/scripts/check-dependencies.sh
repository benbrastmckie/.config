#!/usr/bin/env bash
#
# Dependency Checking Script for Neovim Configuration
# This script checks for required and recommended dependencies
# Can be executed by Claude Code to provide installation guidance

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
MISSING_CORE=0
MISSING_RECOMMENDED=0

echo "Checking Neovim Configuration Dependencies..."
echo "=============================================="
echo ""

# Function to check if command exists
check_command() {
  local cmd=$1
  local name=$2
  local required=$3
  local min_version=$4

  if command -v "$cmd" &>/dev/null; then
    local version
    case "$cmd" in
      nvim)
        version=$(nvim --version | head -n1 | awk '{print $2}')
        ;;
      git)
        version=$(git --version | awk '{print $3}')
        ;;
      node)
        version=$(node --version | sed 's/v//')
        ;;
      python3)
        version=$(python3 --version | awk '{print $2}')
        ;;
      *)
        version="installed"
        ;;
    esac

    if [ "$required" = "true" ]; then
      echo -e "${GREEN}✓${NC} $name: $version"
    else
      echo -e "${GREEN}✓${NC} $name: $version (recommended)"
    fi
  else
    if [ "$required" = "true" ]; then
      echo -e "${RED}✗${NC} $name: not found (REQUIRED)"
      MISSING_CORE=$((MISSING_CORE + 1))
    else
      echo -e "${YELLOW}!${NC} $name: not found (recommended)"
      MISSING_RECOMMENDED=$((MISSING_RECOMMENDED + 1))
    fi
  fi
}

# Core Dependencies
echo "Core Dependencies:"
echo "------------------"
check_command "nvim" "Neovim >= 0.9.0" "true" "0.9.0"
check_command "git" "Git" "true" ""
check_command "node" "Node.js >= 18.0" "true" "18.0"
check_command "python3" "Python 3" "true" ""
check_command "pip3" "pip3 (Python package manager)" "true" ""
echo ""

# Recommended Tools
echo "Recommended Tools:"
echo "------------------"
check_command "rg" "ripgrep (fast search)" "false" ""
check_command "fd" "fd (fast file finding)" "false" ""
check_command "lazygit" "lazygit (Git UI)" "false" ""
check_command "fzf" "fzf (fuzzy finder)" "false" ""
echo ""

# Nerd Font Check (approximate)
echo "Font Check:"
echo "-----------"
if fc-list 2>/dev/null | grep -qi "nerd\|NF"; then
  echo -e "${GREEN}✓${NC} Nerd Font detected"
else
  echo -e "${YELLOW}!${NC} Nerd Font not detected (install for icon support)"
  MISSING_CORE=$((MISSING_CORE + 1))
fi
echo ""

# Summary
echo "=============================================="
echo "Summary:"
if [ $MISSING_CORE -eq 0 ]; then
  echo -e "${GREEN}✓${NC} All core dependencies met"
else
  echo -e "${RED}✗${NC} Missing $MISSING_CORE core dependencies"
fi

if [ $MISSING_RECOMMENDED -eq 0 ]; then
  echo -e "${GREEN}✓${NC} All recommended tools installed"
else
  echo -e "${YELLOW}!${NC} Missing $MISSING_RECOMMENDED recommended tools"
fi
echo ""

# Suggest next steps
if [ $MISSING_CORE -gt 0 ]; then
  echo "Next Steps:"
  echo "- Install missing core dependencies"
  echo "- See platform-specific guides in docs/platform/"
  echo "- Or ask Claude Code: 'Help me install missing dependencies for my platform'"
  exit 1
else
  echo "Ready to proceed with Neovim installation!"
  exit 0
fi
