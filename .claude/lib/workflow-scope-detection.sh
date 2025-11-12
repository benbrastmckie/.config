#!/usr/bin/env bash
# Unified Workflow Scope Detection Library
# Provides hybrid LLM-based classification with automatic regex fallback
#
# This library serves all workflow commands (/coordinate, /supervise, custom orchestrators)
# with a single unified implementation following the clean-break philosophy.
#
# Classification Modes:
#   - hybrid (default): LLM first, regex fallback on timeout/low-confidence
#   - llm-only: LLM only, fail-fast on errors
#   - regex-only: Traditional regex patterns only
#
# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_SCOPE_DETECTION_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_SCOPE_DETECTION_SOURCED=1

set -euo pipefail

# Detect and export CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  # shellcheck source=.claude/lib/detect-project-dir.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
fi

# Source LLM classifier library
# shellcheck source=.claude/lib/workflow-llm-classifier.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-llm-classifier.sh"

# Configuration
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"
DEBUG_SCOPE_DETECTION="${DEBUG_SCOPE_DETECTION:-0}"

# detect_workflow_scope: Unified hybrid workflow classification
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints one of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
# Environment Variables:
#   WORKFLOW_CLASSIFICATION_MODE: hybrid (default), llm-only, regex-only
#   DEBUG_SCOPE_DETECTION: 0 (default), 1 (verbose logging)
detect_workflow_scope() {
  local workflow_description="$1"
  local scope=""

  # Validation
  if [ -z "$workflow_description" ]; then
    echo "ERROR: detect_workflow_scope: workflow_description parameter is empty" >&2
    echo "research-and-plan"  # Return default on error
    return 1
  fi

  # Route based on classification mode
  case "$WORKFLOW_CLASSIFICATION_MODE" in
    hybrid)
      # Try LLM first, fallback to regex on error/timeout/low-confidence
      if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then
        # LLM classification succeeded
        local llm_scope
        llm_scope=$(echo "$scope" | jq -r '.scope // empty')

        if [ -n "$llm_scope" ]; then
          log_scope_detection "hybrid" "llm" "$llm_scope"
          echo "$llm_scope"
          return 0
        fi
      fi

      # LLM failed - fallback to regex
      log_scope_detection "hybrid" "regex-fallback" ""
      scope=$(classify_workflow_regex "$workflow_description")
      log_scope_detection "hybrid" "regex" "$scope"
      echo "$scope"
      return 0
      ;;

    llm-only)
      # LLM only - fail fast on errors
      if ! scope=$(classify_workflow_llm "$workflow_description"); then
        echo "ERROR: detect_workflow_scope: LLM classification failed in llm-only mode" >&2
        echo "research-and-plan"  # Return default on error
        return 1
      fi

      local llm_scope
      llm_scope=$(echo "$scope" | jq -r '.scope // empty')

      if [ -z "$llm_scope" ]; then
        echo "ERROR: detect_workflow_scope: LLM returned empty scope" >&2
        echo "research-and-plan"
        return 1
      fi

      log_scope_detection "llm-only" "llm" "$llm_scope"
      echo "$llm_scope"
      return 0
      ;;

    regex-only)
      # Regex only - traditional pattern matching
      scope=$(classify_workflow_regex "$workflow_description")
      log_scope_detection "regex-only" "regex" "$scope"
      echo "$scope"
      return 0
      ;;

    *)
      echo "ERROR: detect_workflow_scope: invalid WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE'" >&2
      echo "ERROR: Valid modes: hybrid, llm-only, regex-only" >&2
      echo "research-and-plan"
      return 1
      ;;
  esac
}

# classify_workflow_regex: Traditional regex-based classification (embedded fallback)
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints one of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
classify_workflow_regex() {
  local workflow_description="$1"
  local scope="research-and-plan"  # Default fallback

  # Validation
  if [ -z "$workflow_description" ]; then
    echo "$scope"
    return 0
  fi

  # Order matters: check more specific patterns first

  # PRIORITY 1: Research-and-revise patterns (most specific)
  # Pattern: revision-first (e.g., "Revise X to Y", "Update plan to accommodate Z")
  if echo "$workflow_description" | grep -Eiq "^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)"; then
    scope="research-and-revise"
    # If revision-first and a path is provided, extract topic from existing plan path
    if echo "$workflow_description" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
      EXISTING_PLAN_PATH=$(echo "$workflow_description" | grep -oE "/[^ ]+\.md" | head -1)
      export EXISTING_PLAN_PATH
    fi

  # Pattern: research-and-revise (specific before general)
  elif echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
    scope="research-and-revise"

  # PRIORITY 2: Plan path detection (for implementation, not revision)
  elif echo "$workflow_description" | grep -Eq "(^|[[:space:]])(\.|/)?(.*/)?specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md"; then
    scope="full-implementation"

  # PRIORITY 3: Explicit keyword patterns (check before research-only to handle "research X and implement Y")
  # Note: Use \b for word boundaries to avoid matching "implementation" in "implementation plan"
  elif echo "$workflow_description" | grep -Eiq "\b(implement|execute)\b"; then
    scope="full-implementation"

  # PRIORITY 4: Research-only pattern (explicit research with no action keywords)
  elif echo "$workflow_description" | grep -Eiq "^research.*"; then
    if echo "$workflow_description" | grep -Eiq "(plan|fix|debug|create|add|build)"; then
      # Has action keywords - not research-only
      scope="research-and-plan"
    else
      # Pure research with no action keywords
      scope="research-only"
    fi

  # PRIORITY 5: Other specific patterns
  elif echo "$workflow_description" | grep -Eiq "(plan|create.*plan|design)"; then
    scope="research-and-plan"
  elif echo "$workflow_description" | grep -Eiq "(fix|debug|troubleshoot)"; then
    scope="debug-only"
  elif echo "$workflow_description" | grep -Eiq "(build|add|create).*feature"; then
    scope="full-implementation"
  fi

  echo "$scope"
  return 0
}

# log_scope_detection: Structured logging for scope detection decisions
# Args:
#   $1: mode - Classification mode (hybrid, llm-only, regex-only)
#   $2: method - Classification method used (llm, regex, regex-fallback)
#   $3: scope - Detected scope (optional)
log_scope_detection() {
  local mode="$1"
  local method="$2"
  local scope="${3:-}"

  if [ "$DEBUG_SCOPE_DETECTION" = "1" ]; then
    echo "[DEBUG] Scope Detection: mode=$mode, method=$method${scope:+, scope=$scope}" >&2
  fi

  # TODO: Integrate with unified-logger.sh for structured logging
}

# Export main function for use by other scripts
export -f detect_workflow_scope
