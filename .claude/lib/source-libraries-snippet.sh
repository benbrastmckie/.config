#!/usr/bin/env bash
# Library Sourcing Snippet (Documentation Only)
#
# Copy-paste this at the start of any bash block needing library functions
# Detects CLAUDE_PROJECT_DIR and sources required libraries
#
# Usage: Copy the section between "--- SNIPPET START ---" and "--- SNIPPET END ---"
#        and paste it at the start of your bash block. Customize the library list
#        as needed for your specific bash block.

# --- SNIPPET START ---
# Source required libraries for this bash block
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries "workflow-detection.sh" "unified-logger.sh" "checkpoint-utils.sh" "error-handling.sh" || exit 1
# --- SNIPPET END ---

# Rationale:
# - Self-contained (no dependencies on previous blocks)
# - Git-aware (works in worktrees and regular repos)
# - Fail-fast error handling (exits immediately if sourcing fails)
# - Explicit library list (customize per block as needed)
#
# Common Library Combinations by Phase:
# - Phase 0 (Location):        unified-location-detection.sh
# - Phase 1 (Research):        unified-logger.sh
# - Phase 2 (Planning):        checkpoint-utils.sh, unified-logger.sh
# - Phase 3 (Implementation):  dependency-analyzer.sh, unified-logger.sh, checkpoint-utils.sh
# - Phase 4 (Testing):         unified-logger.sh, checkpoint-utils.sh
# - Phase 5 (Debug):           unified-logger.sh, checkpoint-utils.sh
# - Phase 6 (Documentation):   unified-logger.sh, context-pruning.sh
# - Workflow Detection:        workflow-detection.sh
#
# Performance Impact:
# - ~0.1s per source × 12 blocks = ~1.2s total overhead (acceptable trade-off)
