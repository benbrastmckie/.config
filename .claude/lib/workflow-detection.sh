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
# Workflow Scope Detection (Smart Pattern Matching)
# ==============================================================================
#
# The /coordinate and /supervise commands support 4 workflow types.
#
# Detection Algorithm:
#   1. Test ALL patterns against the prompt simultaneously
#   2. Collect phase requirements from all matching patterns
#   3. Compute union of required phases
#   4. Select minimal workflow type that includes all required phases
#
# Pattern Phase Mappings:
#   - research-only:       phases {0, 1}
#   - research-and-plan:   phases {0, 1, 2}
#   - full-implementation: phases {0, 1, 2, 3, 4, 6} + conditional {5}
#   - debug-only:          phases {0, 1, 5}
#
# Selection Priority (by phase requirements):
#   1. If phases include {3} → full-implementation (largest workflow)
#   2. If phases include {5} but not {3} → debug-only
#   3. If phases include {2} → research-and-plan
#   4. If phases include only {0, 1} → research-only
#
# Conditional Phases (runtime logic, not detection):
#   - Phase 5 (Debug): Runs only if Phase 4 (Testing) fails
#   - Phase 4 (Testing): Always runs if Phase 3 (Implementation) runs
#   - Phase 6 (Documentation): Runs only if 100% of tests pass
#
# Workflow type descriptions:
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
#    - Keywords: "implement", "build", "add feature", "create [code component]"
#    - Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
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

  # ==============================================================================
  # Smart Pattern Matching Algorithm
  # ==============================================================================
  # 1. Test all patterns simultaneously
  # 2. Collect phase requirements from all matches
  # 3. Compute union of required phases
  # 4. Select minimal workflow containing all phases

  # Initialize match flags
  local match_research_only=0
  local match_research_plan=0
  local match_implementation=0
  local match_debug=0

  # Pattern 1: Research-only
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: {0, 1}
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    match_research_only=1
  fi

  # Pattern 2: Research-and-plan
  # Keywords: "research...to create plan", "analyze...for planning", "create...plan"
  # Phases: {0, 1, 2}
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)" || \
     echo "$workflow_desc" | grep -Eiq "create.*(implementation|refactor|migration|feature).*plan"; then
    match_research_plan=1
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: {0, 1, 2, 3, 4, 6} + conditional {5}
  # Note: Must check AFTER plan patterns to avoid matching "implementation plan"
  if echo "$workflow_desc" | grep -Eiq "\bimplement\b|\bbuild\b|add.*(feature|functionality)|create.*(code|component|module|system)"; then
    match_implementation=1
  fi

  # Pattern 4: Debug-only
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: {0, 1, 5}
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    match_debug=1
  fi

  # ==============================================================================
  # Phase Union Computation and Workflow Selection
  # ==============================================================================

  # Compute required phases based on matches
  local needs_implementation=0
  local needs_planning=0
  local needs_debug=0

  [ $match_implementation -eq 1 ] && needs_implementation=1
  [ $match_research_plan -eq 1 ] && needs_planning=1
  [ $match_debug -eq 1 ] && needs_debug=1

  # Selection Logic: Choose minimal workflow containing all required phases

  # If implementation needed → full-implementation (includes phases 0,1,2,3,4,6)
  # This is the largest workflow and supersedes all others
  if [ $needs_implementation -eq 1 ]; then
    echo "full-implementation"
    return
  fi

  # If debug needed but no implementation → debug-only (includes phases 0,1,5)
  if [ $needs_debug -eq 1 ]; then
    echo "debug-only"
    return
  fi

  # If planning needed → research-and-plan (includes phases 0,1,2)
  if [ $needs_planning -eq 1 ]; then
    echo "research-and-plan"
    return
  fi

  # If only research-only matched → research-only (includes phases 0,1)
  if [ $match_research_only -eq 1 ]; then
    echo "research-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan
  echo "research-and-plan"
}

# Test Examples:
# - detect_workflow_scope "research API patterns" → research-only
# - detect_workflow_scope "research auth to create plan" → research-and-plan
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
