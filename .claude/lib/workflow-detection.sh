#!/usr/bin/env bash
# Workflow Detection Utilities
# Used by: /supervise
# Functions: detect_workflow_scope, should_run_phase
#
# This library provides workflow scope detection and phase execution logic
# for the /supervise command. It determines which phases should run based
# on workflow keywords and patterns.

set -euo pipefail

# ==============================================================================
# Workflow Scope Detection
# ==============================================================================
#
# The /supervise command supports 4 workflow types:
#
# 1. research-only
#    - Keywords: "research [topic]" without "plan" or "implement"
#    - Phases: 0 (Location) → 1 (Research) → STOP
#    - No plan created, no summary
#
# 2. research-and-plan (MOST COMMON)
#    - Keywords: "research...to create plan", "analyze...for planning"
#    - Phases: 0 → 1 (Research) → 2 (Planning) → STOP
#    - Creates research reports + implementation plan
#
# 3. full-implementation
#    - Keywords: "implement", "build", "add feature"
#    - Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 6 (Documentation)
#    - Phase 5 conditional on test failures
#
# 4. debug-only
#    - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
#    - Phases: 0 → 1 (Research) → 5 (Debug) → STOP
#    - No new plan or summary

# ═══════════════════════════════════════════════════════════════
# detect_workflow_scope: Detect workflow type from description
# ═══════════════════════════════════════════════════════════════
#
# Usage: detect_workflow_scope <workflow-description>
# Returns: workflow scope (research-only|research-and-plan|full-implementation|debug-only)
# Example: detect_workflow_scope "research authentication to create plan"
#
detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 0: Compound workflow (all three keywords present)
  # Keywords: "research...plan...implement" or "research...create...plan...implement"
  # This must be checked FIRST before individual patterns
  # Phases: 0 → 1 (Research) → 2 (Planning) → 3 (Implementation) → 4 (Testing) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "research.*(plan|planning|create.*plan).*(implement|build)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 1: Research-only (no planning or implementation)
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: 0 (Location) → 1 (Research) → STOP
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common case)
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only (fix existing code)
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: 0 → 1 (Research) → 5 (Debug) → STOP (no new implementation)
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan (safest for ambiguous cases)
  echo "research-and-plan"
}

# Test Examples:
# - detect_workflow_scope "research API patterns" → research-only
# - detect_workflow_scope "research auth to create plan" → research-and-plan
# - detect_workflow_scope "research auth to create plan to implement feature" → full-implementation (compound)
# - detect_workflow_scope "implement OAuth2 authentication" → full-implementation
# - detect_workflow_scope "fix token refresh bug" → debug-only

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

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f detect_workflow_scope
  export -f should_run_phase
fi
