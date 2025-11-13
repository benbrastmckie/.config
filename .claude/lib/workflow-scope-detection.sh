#!/usr/bin/env bash
# Unified Workflow Scope Detection Library
# Provides LLM-based classification with fail-fast error handling
#
# This library serves all workflow commands (/coordinate, /supervise, custom orchestrators)
# with a single unified implementation following the clean-break philosophy.
#
# Classification Mode:
#   - llm-only (only mode): LLM classification with fail-fast on errors
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

# Configuration (Clean-Break: default changed from hybrid to llm-only)
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"
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
    echo "  Context: Empty workflow description provided" >&2
    echo "  Suggestion: Provide a non-empty workflow description" >&2
    return 1
  fi

  # LLM-only classification - fail fast on errors (no fallback)
  local llm_result
  if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
    echo "ERROR: classify_workflow_comprehensive: LLM classification failed" >&2
    echo "  Context: Workflow description: $workflow_description" >&2
    echo "  Suggestion: Check network connection or increase WORKFLOW_CLASSIFICATION_TIMEOUT" >&2
    return 1
  fi

  log_scope_detection "llm-only" "llm-comprehensive" "$(echo "$llm_result" | jq -r '.workflow_type')"
  echo "$llm_result"
  return 0
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

# log_scope_detection: Structured logging for scope detection decisions
# Args:
#   $1: mode - Classification mode (llm-only)
#   $2: method - Classification method used (llm-comprehensive)
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

# Backward compatibility wrapper for tests
# Uses simple regex-based pattern matching for basic workflow type detection
# This provides fast, deterministic results for testing and simple cases
detect_workflow_scope() {
  local workflow_description="$1"
  local detected_scope

  # Priority 1: Revise/Update/Modify patterns with "plan" keyword
  if echo "$workflow_description" | grep -Eiq "(revise|update|modify).*(plan|implementation)"; then
    detected_scope="research-and-revise"
  # Priority 2: Plan path patterns (implement/execute with path to plans/)
  elif echo "$workflow_description" | grep -Eq "(implement|execute).*(/|specs/|\.claude/).*plans/.*\.md"; then
    detected_scope="full-implementation"
  # Priority 3: Debug/Fix/Troubleshoot patterns
  elif echo "$workflow_description" | grep -Eiq "^(debug|fix|troubleshoot)"; then
    detected_scope="debug-only"
  # Priority 4: Plan creation keywords (specific phrases only to avoid false matches)
  # Match "create a plan", "create an implementation plan", "design a plan" etc.
  # But NOT "create and implement" or "plan and implement"
  elif echo "$workflow_description" | grep -Eiq "create (a |an |the )?((comprehensive |implementation )?plan|design)" && \
       ! echo "$workflow_description" | grep -Eiq "(and|then) implement"; then
    detected_scope="research-and-plan"
  elif echo "$workflow_description" | grep -Eiq "(plan|design).*(plan|for)" && \
       ! echo "$workflow_description" | grep -Eiq "(and|then) implement"; then
    detected_scope="research-and-plan"
  # Priority 5: Implementation action keywords (check anywhere in string for multi-intent)
  elif echo "$workflow_description" | grep -Eiq "(implement|build|execute)"; then
    detected_scope="full-implementation"
  # Priority 6: Create keyword (for code components, but not plans)
  elif echo "$workflow_description" | grep -Eiq "create" && \
       ! echo "$workflow_description" | grep -Eiq "plan"; then
    detected_scope="full-implementation"
  # Priority 7: Research-only (research without other action keywords)
  elif echo "$workflow_description" | grep -Eiq "^research" && \
     ! echo "$workflow_description" | grep -Eiq "(implement|build|create|plan|execute)"; then
    detected_scope="research-only"
  # Default: research-and-plan (safest assumption for ambiguous inputs)
  else
    detected_scope="research-and-plan"
  fi

  # Log the detection for debugging
  log_scope_detection "regex-fallback" "detect_workflow_scope" "$detected_scope"

  echo "$detected_scope"
  return 0
}

# Export functions for use by other scripts
export -f classify_workflow_comprehensive
export -f infer_complexity_from_keywords
export -f generate_generic_topics
export -f detect_workflow_scope  # Backward compatibility wrapper
