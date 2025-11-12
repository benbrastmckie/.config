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

# classify_workflow_comprehensive: Comprehensive workflow classification
# Provides scope, research complexity, and descriptive subtopic names in a single operation
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   0: Success (prints JSON to stdout)
#   1: Error
# Output Format:
#   {
#     "workflow_type": "research-and-plan",
#     "confidence": 0.95,
#     "research_complexity": 2,
#     "subtopics": ["Topic 1 description", "Topic 2 description"],
#     "reasoning": "..."
#   }
classify_workflow_comprehensive() {
  local workflow_description="$1"

  # Validation
  if [ -z "$workflow_description" ]; then
    echo "ERROR: classify_workflow_comprehensive: workflow_description parameter is empty" >&2
    fallback_comprehensive_classification "$workflow_description"
    return 1
  fi

  # Route based on classification mode
  case "$WORKFLOW_CLASSIFICATION_MODE" in
    hybrid)
      # Try LLM first, fallback to regex + heuristic on error/timeout/low-confidence
      local llm_result
      if llm_result=$(classify_workflow_llm_comprehensive "$workflow_description" 2>/dev/null); then
        # LLM classification succeeded - validate and return
        if echo "$llm_result" | jq -e '.workflow_type' >/dev/null 2>&1; then
          log_scope_detection "hybrid" "llm-comprehensive" "$(echo "$llm_result" | jq -r '.workflow_type')"
          echo "$llm_result"
          return 0
        fi
      fi

      # LLM failed - fallback to regex + heuristic
      log_scope_detection "hybrid" "comprehensive-fallback" ""
      fallback_comprehensive_classification "$workflow_description"
      return 0
      ;;

    llm-only)
      # LLM only - fail fast on errors
      if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
        echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
        fallback_comprehensive_classification "$workflow_description"
        return 1
      fi

      log_scope_detection "llm-only" "llm-comprehensive" "$(echo "$llm_result" | jq -r '.workflow_type')"
      echo "$llm_result"
      return 0
      ;;

    regex-only)
      # Regex + heuristic only - no LLM
      log_scope_detection "regex-only" "comprehensive-fallback" ""
      fallback_comprehensive_classification "$workflow_description"
      return 0
      ;;

    *)
      echo "ERROR: classify_workflow_comprehensive: invalid WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE'" >&2
      fallback_comprehensive_classification "$workflow_description"
      return 1
      ;;
  esac
}

# fallback_comprehensive_classification: Fallback for comprehensive classification
# Combines regex scope detection with heuristic complexity calculation
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints JSON to stdout
fallback_comprehensive_classification() {
  local workflow_description="$1"

  # Get scope using regex
  local scope
  scope=$(classify_workflow_regex "$workflow_description")

  # Infer complexity using heuristics
  local complexity
  complexity=$(infer_complexity_from_keywords "$workflow_description")

  # Generate generic topic names
  local subtopics_json
  subtopics_json=$(generate_generic_topics "$complexity")

  # Build JSON response
  jq -n \
    --arg scope "$scope" \
    --argjson complexity "$complexity" \
    --argjson subtopics "$subtopics_json" \
    '{
      "workflow_type": $scope,
      "confidence": 0.6,
      "research_complexity": $complexity,
      "subtopics": $subtopics,
      "reasoning": "Fallback: regex scope + heuristic complexity"
    }'
}

# infer_complexity_from_keywords: Heuristic complexity calculation
# Uses same patterns as coordinate.md:402-414 for backward compatibility
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   Prints integer 1-4 to stdout
infer_complexity_from_keywords() {
  local workflow_description="$1"
  local complexity=2  # Default moderate complexity

  # Count complexity indicators (same logic as coordinate.md pattern matching)
  local indicator_count=0

  # Check for multiple subtopics
  if echo "$workflow_description" | grep -Eiq "(and |, |; )"; then
    ((indicator_count++)) || true
  fi

  # Check for complex actions
  if echo "$workflow_description" | grep -Eiq "(analyze|research|investigate|explore)"; then
    ((indicator_count++)) || true
  fi

  # Check for implementation scope
  if echo "$workflow_description" | grep -Eiq "(implement|build|create|develop)"; then
    ((indicator_count++)) || true
  fi

  # Check for planning/design
  if echo "$workflow_description" | grep -Eiq "(plan|design|architect)"; then
    ((indicator_count++)) || true
  fi

  # Map indicators to complexity (1-4)
  if [ "$indicator_count" -eq 0 ]; then
    complexity=1  # Simple
  elif [ "$indicator_count" -eq 1 ]; then
    complexity=2  # Moderate
  elif [ "$indicator_count" -eq 2 ]; then
    complexity=3  # Complex
  else
    complexity=4  # Highly complex
  fi

  echo "$complexity"
}

# generate_generic_topics: Generate generic topic names for fallback mode
# Args:
#   $1: complexity - Number of topics to generate (1-4)
# Returns:
#   Prints JSON array to stdout
generate_generic_topics() {
  local complexity="$1"
  local topics=()

  for i in $(seq 1 "$complexity"); do
    topics+=("Topic $i")
  done

  # Convert to JSON array
  printf '%s\n' "${topics[@]}" | jq -R . | jq -s .
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

# Export functions for use by other scripts
export -f classify_workflow_comprehensive
export -f classify_workflow_regex
export -f fallback_comprehensive_classification
export -f infer_complexity_from_keywords
export -f generate_generic_topics
