#!/usr/bin/env bash
# Workflow Detection Utilities
# Used by: /supervise
# Functions: detect_workflow_scope (from unified library), should_run_phase
#
# This library provides phase execution logic for the /supervise command.
# Workflow scope detection is now provided by the unified workflow-scope-detection.sh library.

set -euo pipefail

# Detect and export CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  # shellcheck source=.claude/lib/core/detect-project-dir.sh
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/../core/detect-project-dir.sh"
fi

# Source unified workflow scope detection library
# This provides: detect_workflow_scope()
# shellcheck source=.claude/lib/workflow/workflow-scope-detection.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-scope-detection.sh"

# ==============================================================================
# Workflow Scope Detection (Unified Library)
# ==============================================================================
#
# NOTE: detect_workflow_scope() is now provided by workflow-scope-detection.sh
# (sourced above). This library only provides should_run_phase() for /supervise.
#
# Supported workflow types:
#   - research-only: Phases {0, 1}
#   - research-and-plan: Phases {0, 1, 2}
#   - research-and-revise: Phases {0, 1, 2} with existing plan
#   - full-implementation: Phases {0, 1, 2, 3, 4, 6} + conditional {5}
#   - debug-only: Phases {0, 1, 5}
#
# For classification logic, see: .claude/lib/workflow/workflow-scope-detection.sh

# ═══════════════════════════════════════════════════════════════
# should_run_phase: Check if phase should execute for current scope
# ═══════════════════════════════════════════════════════════════
#
# Usage: should_run_phase <phase-number>
# Returns: 0 (true) if phase should execute, 1 (false) otherwise
# Example: should_run_phase 3  # Returns 0 if phase 3 in PHASES_TO_EXECUTE
#
# Requires: PHASES_TO_EXECUTE environment variable (comma-separated list)
#
should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}

# Usage Pattern in /supervise:
#
# should_run_phase 1 || {
#   echo "⏭️  Skipping Phase 1 (Research)"
#   exit 0
# }
#
# This allows conditional phase execution based on workflow scope.

# ==============================================================================
# Export Functions
# ==============================================================================

export -f should_run_phase
# detect_workflow_scope is exported by workflow-scope-detection.sh
