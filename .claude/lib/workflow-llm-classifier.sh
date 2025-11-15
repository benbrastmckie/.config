#!/usr/bin/env bash
# workflow-llm-classifier.sh - LLM-based workflow classification library
#
# This library provides semantic workflow classification using Claude Haiku 4.5 for high-accuracy
# intent detection. It serves as the core intelligence layer for hybrid workflow classification,
# supporting automatic fallback to regex-based classification when confidence is low.
#
# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_LLM_CLASSIFIER_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_LLM_CLASSIFIER_SOURCED=1

set -euo pipefail

# Detect and export CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  # shellcheck source=.claude/lib/detect-project-dir.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
fi

# Configuration (environment variable overrides)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD="${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD:-0.7}"
WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
WORKFLOW_CLASSIFICATION_DEBUG="${WORKFLOW_CLASSIFICATION_DEBUG:-0}"

# classify_workflow_llm - Main entry point for LLM-based workflow classification
# Args:
#   $1: workflow_description - The workflow description to classify
#   $2: workflow_id - Workflow identifier for semantic filename scoping (optional)
# Returns:
#   0: Classification successful (prints JSON to stdout)
#   1: Classification failed or confidence below threshold
# Output Format:
#   {"scope": "research-and-plan", "confidence": 0.95, "reasoning": "..."}
classify_workflow_llm() {
  local workflow_description="$1"
  local workflow_id="${2:-classify_$(date +%s)}"  # Generate default if not provided

  # Input validation
  if [ -z "$workflow_description" ]; then
    log_classification_error "classify_workflow_llm" "empty workflow description"
    return 1
  fi

  # Build LLM classifier input
  local llm_input
  if ! llm_input=$(build_llm_classifier_input "$workflow_description"); then
    log_classification_error "classify_workflow_llm" "failed to build LLM input"
    return 1
  fi

  # Invoke LLM classifier with timeout (pass workflow_id for semantic filename scoping)
  local llm_output
  if ! llm_output=$(invoke_llm_classifier "$llm_input" "$workflow_id"); then
    log_classification_error "classify_workflow_llm" "LLM invocation failed or timed out"
    return 1
  fi

  # Parse and validate LLM response
  local parsed_response
  if ! parsed_response=$(parse_llm_classifier_response "$llm_output"); then
    log_classification_error "classify_workflow_llm" "failed to parse LLM response"
    return 1
  fi

  # Check confidence threshold
  local confidence
  confidence=$(echo "$parsed_response" | jq -r '.confidence // 0')

  # Bash-native floating point comparison (convert to integer by multiplying by 100)
  local conf_int=$(echo "$confidence * 100" | awk '{printf "%.0f", $1}')
  local threshold_int=$(echo "$WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD * 100" | awk '{printf "%.0f", $1}')

  if [ "$conf_int" -lt "$threshold_int" ]; then
    log_classification_result "low-confidence" "$parsed_response"
    return 1
  fi

  # Success - log and return result
  log_classification_result "success" "$parsed_response"
  echo "$parsed_response"
  return 0
}

# classify_workflow_llm_comprehensive - LLM-based comprehensive workflow classification
# Provides scope, research complexity, and enhanced research topics with detailed descriptions in a single call
# Args:
#   $1: workflow_description - The workflow description to classify
# Returns:
#   0: Classification successful (prints JSON to stdout)
#   1: Classification failed or confidence below threshold
# Output Format:
#   {
#     "workflow_type": "research-and-plan",
#     "confidence": 0.95,
#     "research_complexity": 2,
#     "research_topics": [
#       {
#         "short_name": "Implementation architecture",
#         "detailed_description": "Analyze current implementation...",
#         "filename_slug": "implementation_architecture",
#         "research_focus": "Key questions: How is..."
#       }
#     ],
#     "subtopics": ["Implementation architecture"],  // Backwards compatibility
#     "reasoning": "..."
#   }
classify_workflow_llm_comprehensive() {
  local workflow_description="$1"
  local workflow_id="${2:-classify_$(date +%s)}"  # Generate default if not provided

  # Input validation
  if [ -z "$workflow_description" ]; then
    log_classification_error "classify_workflow_llm_comprehensive" "empty workflow description"
    return 1
  fi

  # TEST MODE: Return canned response for unit testing (avoids real LLM API calls)
  # This follows bash testing best practices: mock at function level using environment variables
  if [ "${WORKFLOW_CLASSIFICATION_TEST_MODE:-0}" = "1" ]; then
    # Simple keyword-based fixture selection for test mocking
    # NOTE: This is NOT production classification - just test fixture selection
    local mock_type="research-and-plan"  # Default

    # Simple keyword matching for realistic test fixtures
    # Priority order matters
    if echo "$workflow_description" | grep -qiE "^(debug|fix|troubleshoot)"; then
      mock_type="debug-only"
    elif echo "$workflow_description" | grep -qiE "(revise|update|modify).*(plan|implementation)"; then
      mock_type="research-and-revise"
    elif echo "$workflow_description" | grep -qiE "(implement|build|execute)"; then
      mock_type="full-implementation"
    elif echo "$workflow_description" | grep -qiE "create.*(module|component|feature|system)" && ! echo "$workflow_description" | grep -qiE "plan"; then
      mock_type="full-implementation"
    elif echo "$workflow_description" | grep -qiE "^research" && ! echo "$workflow_description" | grep -qiE "(plan|implement|create)"; then
      mock_type="research-only"
    fi

    # Return realistic fixture with mock workflow type
    cat <<EOF
{
  "workflow_type": "$mock_type",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Test failure analysis",
      "detailed_description": "Analyze failing tests to identify root causes, patterns, and potential fixes.",
      "filename_slug": "test_failure_analysis",
      "research_focus": "Key questions: Which tests are failing? What are the common patterns? Areas to investigate: test infrastructure, mocking, dependencies."
    },
    {
      "short_name": "Implementation review",
      "detailed_description": "Review recent implementation changes to identify potential issues introduced.",
      "filename_slug": "implementation_review",
      "research_focus": "Key questions: What changed recently? Are there breaking changes? Areas to investigate: commit history, affected modules."
    }
  ],
  "reasoning": "Test mode: returning mock response based on simple keyword matching for fixture selection"
}
EOF
    return 0
  fi

  # Build LLM classifier input for comprehensive classification
  local llm_input
  if ! llm_input=$(build_llm_classifier_input "$workflow_description" "comprehensive"); then
    log_classification_error "classify_workflow_llm_comprehensive" "failed to build LLM input"
    return 1
  fi

  # Invoke LLM classifier with timeout (pass workflow_id for semantic filename scoping)
  local llm_output
  if ! llm_output=$(invoke_llm_classifier "$llm_input" "$workflow_id"); then
    handle_llm_classification_failure "timeout" "LLM invocation failed or timed out" "$workflow_description"
    return 1
  fi

  # Parse and validate LLM response (comprehensive format)
  local parsed_response
  if ! parsed_response=$(parse_llm_classifier_response "$llm_output" "comprehensive"); then
    log_classification_error "classify_workflow_llm_comprehensive" "failed to parse LLM response"
    return 1
  fi

  # Check confidence threshold
  local confidence
  confidence=$(echo "$parsed_response" | jq -r '.confidence // 0')

  # Bash-native floating point comparison (convert to integer by multiplying by 100)
  local conf_int=$(echo "$confidence * 100" | awk '{printf "%.0f", $1}')
  local threshold_int=$(echo "$WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD * 100" | awk '{printf "%.0f", $1}')

  if [ "$conf_int" -lt "$threshold_int" ]; then
    log_classification_result "low-confidence" "$parsed_response"
    return 1
  fi

  # Success - log and return result
  log_classification_result "success" "$parsed_response"
  echo "$parsed_response"
  return 0
}

# build_llm_classifier_input - Build JSON payload for LLM classifier
# Args:
#   $1: workflow_description - The workflow description to classify
#   $2: classification_type - "scope" (default) or "comprehensive"
# Returns:
#   0: Success (prints JSON to stdout)
#   1: Error building input
build_llm_classifier_input() {
  local workflow_description="$1"
  local classification_type="${2:-scope}"

  # Validate input
  if [ -z "$workflow_description" ]; then
    echo "ERROR: build_llm_classifier_input: empty workflow description" >&2
    return 1
  fi

  # Build JSON with proper escaping
  local json_input
  if [ "$classification_type" = "comprehensive" ]; then
    # Comprehensive classification: request workflow_type, research_complexity, and enhanced research_topics
    json_input=$(jq -n \
      --arg desc "$workflow_description" \
      '{
        "task": "classify_workflow_comprehensive",
        "description": $desc,
        "valid_scopes": [
          "research-only",
          "research-and-plan",
          "research-and-revise",
          "full-implementation",
          "debug-only"
        ],
        "instructions": "Analyze the workflow description and provide comprehensive classification. Return a JSON object with: workflow_type (one of valid_scopes), confidence (0.0-1.0), research_complexity (integer 1-4 indicating number of research subtopics needed), research_topics (array of objects, one per subtopic, each containing: {short_name: string (concise topic name), detailed_description: string (150-250 words providing comprehensive research context about what to investigate and why), filename_slug: string (filesystem-safe lowercase alphanumeric + underscores, max 50 chars, must match ^[a-z0-9_]{1,50}$), research_focus: string (specific questions to answer and areas to investigate)}), reasoning (brief explanation). Focus on INTENT, not keywords - e.g., '\''research the research-and-revise workflow'\'' is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan). For research_complexity: 1=simple/focused, 2=moderate, 3=complex, 4=highly complex. The research_topics array length must match research_complexity exactly. Each topic should provide rich context for research agents."
      }')
  else
    # Scope-only classification (backward compatibility)
    json_input=$(jq -n \
      --arg desc "$workflow_description" \
      '{
        "task": "classify_workflow_scope",
        "description": $desc,
        "valid_scopes": [
          "research-only",
          "research-and-plan",
          "research-and-revise",
          "full-implementation",
          "debug-only"
        ],
        "instructions": "Analyze the workflow description and determine the user intent. Return a JSON object with: scope (one of valid_scopes), confidence (0.0-1.0), reasoning (brief explanation). Focus on INTENT, not keywords - e.g., '\''research the research-and-revise workflow'\'' is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan)."
      }')
  fi

  if [ -z "$json_input" ]; then
    echo "ERROR: build_llm_classifier_input: jq failed to build JSON" >&2
    return 1
  fi

  echo "$json_input"
  return 0
}

# check_network_connectivity - Fast pre-flight check for network availability
# Returns:
#   0: Network available
#   1: Network unavailable (offline scenario)
# Added: Spec 700 Phase 5 - Fast-fail for offline scenarios
check_network_connectivity() {
  # Check for localhost-only environment
  # Use ping as lightweight network test (fallback if ping unavailable: return 0)
  if command -v ping >/dev/null 2>&1; then
    if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      echo "WARNING: No network connectivity detected" >&2
      echo "  Suggestion: Check network connection or increase timeout" >&2
      return 1
    fi
  fi

  return 0
}

# NOTE (Spec 1763161992 Phase 3): invoke_llm_classifier function removed
# Classification now performed by workflow-classifier agent (invoked via Task tool in commands)
# This eliminates file-based signaling timeout issues (100% timeout rate)
# See: .claude/agents/workflow-classifier.md

# parse_llm_classifier_response - Validate and parse LLM JSON response
# Args:
#   $1: llm_output - Raw LLM output (JSON string)
#   $2: classification_type - "scope" (default) or "comprehensive"
# Returns:
#   0: Success (prints validated JSON to stdout)
#   1: Invalid or malformed response
parse_llm_classifier_response() {
  local llm_output="$1"
  local classification_type="${2:-scope}"

  # Validate input
  if [ -z "$llm_output" ]; then
    echo "ERROR: parse_llm_classifier_response: empty LLM output" >&2
    return 1
  fi

  # Validate JSON structure
  if ! echo "$llm_output" | jq -e . >/dev/null 2>&1; then
    echo "ERROR: parse_llm_classifier_response: invalid JSON" >&2
    return 1
  fi

  if [ "$classification_type" = "comprehensive" ]; then
    # Comprehensive classification validation
    local workflow_type confidence reasoning research_complexity research_topics
    workflow_type=$(echo "$llm_output" | jq -r '.workflow_type // empty')
    confidence=$(echo "$llm_output" | jq -r '.confidence // empty')
    reasoning=$(echo "$llm_output" | jq -r '.reasoning // empty')
    research_complexity=$(echo "$llm_output" | jq -r '.research_complexity // empty')
    research_topics=$(echo "$llm_output" | jq -r '.research_topics // empty')

    if [ -z "$workflow_type" ] || [ -z "$confidence" ] || [ -z "$reasoning" ] || [ -z "$research_complexity" ] || [ -z "$research_topics" ]; then
      echo "ERROR: parse_llm_classifier_response: missing required fields (workflow_type, confidence, reasoning, research_complexity, research_topics)" >&2
      return 1
    fi

    # Validate research_topics is an array
    if ! echo "$llm_output" | jq -e '.research_topics | type == "array"' >/dev/null 2>&1; then
      echo "ERROR: parse_llm_classifier_response: research_topics must be an array" >&2
      return 1
    fi

    # Validate workflow_type value
    local valid_scopes=("research-only" "research-and-plan" "research-and-revise" "full-implementation" "debug-only")
    local scope_valid=0
    for valid_scope in "${valid_scopes[@]}"; do
      if [ "$workflow_type" = "$valid_scope" ]; then
        scope_valid=1
        break
      fi
    done

    if [ $scope_valid -eq 0 ]; then
      echo "ERROR: parse_llm_classifier_response: invalid workflow_type '$workflow_type'" >&2
      return 1
    fi

    # Validate research_complexity range (1-4)
    if ! echo "$research_complexity" | grep -Eq '^[1-4]$'; then
      echo "ERROR: parse_llm_classifier_response: invalid research_complexity '$research_complexity' (must be 1-4)" >&2
      return 1
    fi

    # Validate research_topics array count matches complexity
    local topics_count
    topics_count=$(echo "$llm_output" | jq -r '.research_topics | length')
    if [ "$topics_count" -ne "$research_complexity" ]; then
      echo "ERROR: parse_llm_classifier_response: research_topics count ($topics_count) does not match research_complexity ($research_complexity)" >&2
      return 1
    fi

    # Validate each topic has required fields
    local i
    for ((i=0; i<topics_count; i++)); do
      local short_name detailed_description filename_slug research_focus
      short_name=$(echo "$llm_output" | jq -r ".research_topics[$i].short_name // empty")
      detailed_description=$(echo "$llm_output" | jq -r ".research_topics[$i].detailed_description // empty")
      filename_slug=$(echo "$llm_output" | jq -r ".research_topics[$i].filename_slug // empty")
      research_focus=$(echo "$llm_output" | jq -r ".research_topics[$i].research_focus // empty")

      if [ -z "$short_name" ]; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i] missing short_name" >&2
        return 1
      fi

      if [ -z "$detailed_description" ]; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i] missing detailed_description" >&2
        return 1
      fi

      if [ -z "$filename_slug" ]; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i] missing filename_slug" >&2
        return 1
      fi

      if [ -z "$research_focus" ]; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i] missing research_focus" >&2
        return 1
      fi

      # Validate filename_slug matches regex ^[a-z0-9_]{1,50}$
      if ! echo "$filename_slug" | grep -Eq '^[a-z0-9_]{1,50}$'; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i].filename_slug '$filename_slug' invalid (must match ^[a-z0-9_]{1,50}$)" >&2
        return 1
      fi

      # Validate detailed_description length (50-500 characters)
      local desc_length=${#detailed_description}
      if [ "$desc_length" -lt 50 ] || [ "$desc_length" -gt 500 ]; then
        echo "ERROR: parse_llm_classifier_response: research_topics[$i].detailed_description length ($desc_length chars) must be 50-500 characters" >&2
        return 1
      fi
    done

    # Extract short_name values into backwards-compatible subtopics array for existing code
    local subtopics_json
    subtopics_json=$(echo "$llm_output" | jq -c '[.research_topics[].short_name]')

    # Merge subtopics into output for backwards compatibility
    llm_output=$(echo "$llm_output" | jq --argjson subtopics "$subtopics_json" '. + {subtopics: $subtopics}')

  else
    # Scope-only validation (backward compatibility)
    local scope confidence reasoning
    scope=$(echo "$llm_output" | jq -r '.scope // empty')
    confidence=$(echo "$llm_output" | jq -r '.confidence // empty')
    reasoning=$(echo "$llm_output" | jq -r '.reasoning // empty')

    if [ -z "$scope" ] || [ -z "$confidence" ] || [ -z "$reasoning" ]; then
      echo "ERROR: parse_llm_classifier_response: missing required fields (scope, confidence, reasoning)" >&2
      return 1
    fi

    # Validate scope value
    local valid_scopes=("research-only" "research-and-plan" "research-and-revise" "full-implementation" "debug-only")
    local scope_valid=0
    for valid_scope in "${valid_scopes[@]}"; do
      if [ "$scope" = "$valid_scope" ]; then
        scope_valid=1
        break
      fi
    done

    if [ $scope_valid -eq 0 ]; then
      echo "ERROR: parse_llm_classifier_response: invalid scope '$scope'" >&2
      return 1
    fi
  fi

  # Validate confidence range (0.0 to 1.0) - applies to both modes
  local confidence
  if [ "$classification_type" = "comprehensive" ]; then
    confidence=$(echo "$llm_output" | jq -r '.confidence // empty')
  else
    confidence=$(echo "$llm_output" | jq -r '.confidence // empty')
  fi

  # Accept: 0, 0.5, 1, 1.0, 0.95, etc.
  # Reject: 1.5, 2, -0.5, abc, etc.
  if ! echo "$confidence" | grep -Eq '^(0(\.[0-9]+)?|1(\.0+)?)$'; then
    echo "ERROR: parse_llm_classifier_response: invalid confidence value '$confidence' (must be 0.0-1.0)" >&2
    return 1
  fi

  # Return validated JSON
  echo "$llm_output"
  return 0
}

# ==============================================================================
# LLM Classification Error Handling (Spec 688 Phase 4)
# ==============================================================================

# handle_llm_classification_failure - Structured error handling for LLM classification failures
# Provides fail-fast error handling with clear context and actionable suggestions
# Args:
#   $1: error_type - Type of LLM error (timeout, api_error, low_confidence, parse_error, invalid_mode, network)
#   $2: error_message - Original error message from LLM classifier
#   $3: workflow_description - Workflow description that failed classification
# Returns:
#   1 (always fails fast)
# Side effects:
#   Writes structured error message to stderr
handle_llm_classification_failure() {
  local error_type="$1"
  local error_message="$2"
  local workflow_description="$3"

  # Load error type constants if error-handling.sh available
  if [ -f "${CLAUDE_PROJECT_DIR:-.claude}/.claude/lib/error-handling.sh" ]; then
    source "${CLAUDE_PROJECT_DIR:-.claude}/.claude/lib/error-handling.sh"
  fi

  # Build structured error message
  echo "ERROR: LLM classification failed" >&2
  echo "  Error Type: $error_type" >&2
  echo "  Error Message: $error_message" >&2
  echo "  Workflow Description: $workflow_description" >&2
  echo "" >&2

  # Provide actionable suggestions based on error type
  case "$error_type" in
    timeout|"$ERROR_TYPE_LLM_TIMEOUT")
      echo "  Suggestion: Increase WORKFLOW_CLASSIFICATION_TIMEOUT (current: ${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}s)" >&2
      echo "  Alternative: Check network connection and retry" >&2
      ;;
    api_error|"$ERROR_TYPE_LLM_API_ERROR")
      echo "  Suggestion: Check network connection and API availability" >&2
      echo "  Alternative: Retry operation or check API credentials" >&2
      ;;
    network|"$ERROR_TYPE_NETWORK")
      echo "  Suggestion: Check network connectivity (ping, DNS resolution, firewall settings)" >&2
      echo "  Details: LLM classification requires internet access to reach API endpoints" >&2
      echo "  Alternative: Verify network connection and retry" >&2
      ;;
    low_confidence|"$ERROR_TYPE_LLM_LOW_CONFIDENCE")
      echo "  Suggestion: Rephrase workflow description with more specific keywords" >&2
      echo "  Example: Instead of 'research stuff', use 'research authentication patterns and security best practices'" >&2
      ;;
    parse_error|"$ERROR_TYPE_LLM_PARSE_ERROR")
      echo "  Suggestion: This is likely a temporary issue. Retry the operation" >&2
      echo "  Alternative: Check workflow description format and retry" >&2
      ;;
    invalid_mode|"$ERROR_TYPE_INVALID_MODE")
      echo "  Suggestion: WORKFLOW_CLASSIFICATION_MODE should be 'llm-only' (only valid mode)" >&2
      echo "  Note: regex-only mode has been removed to maintain LLM-only classification" >&2
      ;;
    *)
      echo "  Suggestion: Unknown error type. Check error message above and retry" >&2
      echo "  Alternative: Verify network connection and check workflow description" >&2
      ;;
  esac

  return 1
}

# log_classification_result - Structured logging for classification results
# Args:
#   $1: result_type - success, low-confidence, error
#   $2: result_data - JSON result data (optional)
log_classification_result() {
  local result_type="$1"
  local result_data="${2:-}"

  if [ "$WORKFLOW_CLASSIFICATION_DEBUG" = "1" ]; then
    echo "[DEBUG] LLM Classification Result: type=$result_type" >&2
    if [ -n "$result_data" ]; then
      echo "[DEBUG] LLM Classification Data: $result_data" >&2
    fi
  fi

  # TODO: Integrate with unified-logger.sh if available
  # For now, basic stderr logging
}

# log_classification_error - Log classification errors
# Args:
#   $1: function_name - Name of function where error occurred
#   $2: error_message - Error description
log_classification_error() {
  local function_name="$1"
  local error_message="$2"

  echo "[ERROR] LLM Classifier: $function_name: $error_message" >&2

  if [ "$WORKFLOW_CLASSIFICATION_DEBUG" = "1" ]; then
    # In debug mode, print stack trace context
    echo "[DEBUG] Call stack: ${FUNCNAME[*]}" >&2
  fi
}

# log_classification_debug - Debug logging helper
# Args:
#   $1: function_name - Name of calling function
#   $2: debug_message - Debug message
log_classification_debug() {
  local function_name="$1"
  local debug_message="$2"

  if [ "$WORKFLOW_CLASSIFICATION_DEBUG" = "1" ]; then
    echo "[DEBUG] LLM Classifier: $function_name: $debug_message" >&2
  fi
}

# ==============================================================================
# Workflow-Scoped Cleanup (Spec 704 Phase 2)
# ==============================================================================

# NOTE (Spec 1763161992 Phase 3): cleanup_workflow_classification_files function removed
# No temp files created by agent-based classification (Task tool handles lifecycle)
# File-based signaling removed, no cleanup needed

# Export functions for use by other scripts
# NOTE (Spec 1763161992 Phase 3): Removed exports for deleted file-based functions:
#   - invoke_llm_classifier (replaced by workflow-classifier agent)
#   - cleanup_workflow_classification_files (no temp files with agent-based approach)
export -f classify_workflow_llm
export -f classify_workflow_llm_comprehensive
export -f build_llm_classifier_input
export -f parse_llm_classifier_response
export -f handle_llm_classification_failure
export -f log_classification_result
export -f log_classification_error
export -f log_classification_debug
