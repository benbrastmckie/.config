#!/usr/bin/env bash
# Detects and exports CLAUDE_PROJECT_DIR dynamically
# This utility provides centralized project directory detection for all Claude Code
# commands and utilities, enabling proper git worktree isolation.
#
# Detection Strategy:
#   1. Respect existing CLAUDE_PROJECT_DIR if already set (manual override)
#   2. Use git repository root (primary method, handles worktrees correctly)
#   3. Fallback to current directory (when not in git repo)
#
# Usage:
#   source "${BASH_SOURCE%/*}/../lib/detect-project-dir.sh"
#   # CLAUDE_PROJECT_DIR is now set and exported
#
# Returns:
#   0 on success, sets and exports CLAUDE_PROJECT_DIR
#   0 even on fallback (graceful degradation)

set -euo pipefail

# Skip detection if CLAUDE_PROJECT_DIR already set by user
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  # Already set, respect user's choice
  export CLAUDE_PROJECT_DIR
  return 0
fi

# Method 1: Git repository root (primary detection method)
# This correctly handles:
#   - Main git repositories
#   - Git worktrees (returns worktree root, not main repo)
#   - Submodules
#   - Symbolic links
if command -v git &>/dev/null; then
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    export CLAUDE_PROJECT_DIR
    return 0
  fi
fi

# Method 2: Fallback to current directory
# Used when:
#   - Not inside a git repository
#   - git command not available
#   - git command fails for any reason
CLAUDE_PROJECT_DIR="$(pwd)"
export CLAUDE_PROJECT_DIR

return 0
