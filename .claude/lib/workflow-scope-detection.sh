#!/bin/bash
# Scope Detection Library for /coordinate Command
# Provides centralized workflow scope detection logic

# detect_workflow_scope: Determine workflow scope from description
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints one of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
# Usage:
#   WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
detect_workflow_scope() {
  local workflow_description="$1"
  local scope="research-and-plan"  # Default fallback

  # Validation
  if [ -z "$workflow_description" ]; then
    echo "ERROR: detect_workflow_scope: workflow_description parameter is empty" >&2
    echo "research-and-plan"  # Return default on error
    return 1
  fi

  # Order matters: check more specific patterns first

  # PRIORITY 1: Research-and-revise patterns (most specific - check before plan path)
  # Check for revision-first pattern (e.g., "Revise X to Y", "Update plan to accommodate Z")
  # Pattern: ^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)
  #
  # Regex behavior explained (for maintainers):
  #   ^(revise|update|modify) - Anchors to start, matches revision verbs
  #   .*                      - Greedy match: consumes "the plan /long/path.md " etc.
  #   (plan|implementation)   - Matches "plan" or "implementation" keyword
  #   .*                      - Greedy match: consumes remaining text before trigger
  #   (accommodate|...)       - Matches trigger keywords
  #
  # Handles both:
  #   ✓ Simple: "Revise /path/to/plan.md to accommodate..."
  #   ✓ Complex: "Revise the plan /path/to/plan.md to accommodate..."
  #
  # The greedy .* allows flexible matching while still finding required keywords.
  # Fixed in commit 1984391a (Issue #661) - See test_scope_detection.sh Tests 14-19
  if echo "$workflow_description" | grep -Eiq "^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)"; then
    scope="research-and-revise"
    # If revision-first and a path is provided, extract topic from existing plan path
    # Pattern: /path/to/specs/NNN_topic/plans/001_plan.md → extract "NNN_topic"
    if echo "$workflow_description" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
      # Extract and set EXISTING_PLAN_PATH for coordinate to use
      EXISTING_PLAN_PATH=$(echo "$workflow_description" | grep -oE "/[^ ]+\.md" | head -1)
      export EXISTING_PLAN_PATH
    fi
  # Check for research-and-revise pattern (specific before general)
  # Matches: "research X and revise Y", "analyze X to update plan", etc.
  # ALSO matches revision-first patterns: "Revise plan X to accommodate Y"
  elif echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
    scope="research-and-revise"

  # PRIORITY 2: Plan path detection (for implementation, not revision)
  # If workflow description contains a path to a plan file and NOT a revision, classify as full-implementation
  # Pattern: specs/*/plans/*.md or .claude/specs/*/plans/*.md
  elif echo "$workflow_description" | grep -Eq "(^|[[:space:]])(\.|/)?(.*/)?specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md"; then
    scope="full-implementation"
    # Debug logging for plan path detection
    if [ "${DEBUG_SCOPE_DETECTION:-0}" = "1" ]; then
      echo "[DEBUG] Scope Detection: detected plan path in workflow description" >&2
    fi

  # PRIORITY 3: Research-only pattern (explicit research with no action keywords)
  elif echo "$workflow_description" | grep -Eiq "^research.*"; then
    if echo "$workflow_description" | grep -Eiq "(plan|implement|fix|debug|create|add|build)"; then
      # Has action keywords - not research-only, will be classified below
      scope="research-and-plan"  # Default for research with action keywords
    else
      # Pure research with no action keywords
      scope="research-only"
    fi

  # PRIORITY 4: Explicit keyword patterns (high priority)
  # "implement" keyword with or without "feature" - indicates full implementation intent
  elif echo "$workflow_description" | grep -Eiq "(^|[[:space:]])(implement|execute)"; then
    scope="full-implementation"

  # PRIORITY 5: Other specific patterns
  elif echo "$workflow_description" | grep -Eiq "(plan|create.*plan|design)"; then
    scope="research-and-plan"
  elif echo "$workflow_description" | grep -Eiq "(fix|debug|troubleshoot)"; then
    scope="debug-only"
  elif echo "$workflow_description" | grep -Eiq "(build|add|create).*feature"; then
    scope="full-implementation"
  fi

  # Debug logging (optional, enabled via DEBUG_SCOPE_DETECTION=1)
  if [ "${DEBUG_SCOPE_DETECTION:-0}" = "1" ]; then
    echo "[DEBUG] Scope Detection: description='$workflow_description'" >&2
    echo "[DEBUG] Scope Detection: detected scope='$scope'" >&2
    [ -n "${EXISTING_PLAN_PATH:-}" ] && echo "[DEBUG] Scope Detection: existing_plan='$EXISTING_PLAN_PATH'" >&2
  fi

  echo "$scope"
}

export -f detect_workflow_scope
