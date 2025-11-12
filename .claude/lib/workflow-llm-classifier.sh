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
# Returns:
#   0: Classification successful (prints JSON to stdout)
#   1: Classification failed or confidence below threshold
# Output Format:
#   {"scope": "research-and-plan", "confidence": 0.95, "reasoning": "..."}
classify_workflow_llm() {
  local workflow_description="$1"

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

  # Invoke LLM classifier with timeout
  local llm_output
  if ! llm_output=$(invoke_llm_classifier "$llm_input"); then
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

# build_llm_classifier_input - Build JSON payload for LLM classifier
# Args:
#   $1: workflow_description - The workflow description to classify
# Returns:
#   0: Success (prints JSON to stdout)
#   1: Error building input
build_llm_classifier_input() {
  local workflow_description="$1"

  # Validate input
  if [ -z "$workflow_description" ]; then
    echo "ERROR: build_llm_classifier_input: empty workflow description" >&2
    return 1
  fi

  # Build JSON with proper escaping
  local json_input
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

  if [ -z "$json_input" ]; then
    echo "ERROR: build_llm_classifier_input: jq failed to build JSON" >&2
    return 1
  fi

  echo "$json_input"
  return 0
}

# invoke_llm_classifier - Call AI assistant via file-based signaling
# Args:
#   $1: llm_input - JSON input for classifier
# Returns:
#   0: Success (prints JSON response to stdout)
#   1: Error or timeout
invoke_llm_classifier() {
  local llm_input="$1"
  local request_file="/tmp/llm_classification_request_$$.json"
  local response_file="/tmp/llm_classification_response_$$.json"

  # Cleanup function
  cleanup_temp_files() {
    rm -f "$request_file" "$response_file"
  }

  # Set trap for cleanup
  trap cleanup_temp_files EXIT

  # Write request file
  echo "$llm_input" > "$request_file"

  # Signal to AI assistant
  echo "[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file" >&2

  # Wait for response with timeout
  local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))  # Check every 0.5s
  local count=0
  while [ $count -lt $iterations ]; do
    if [ -f "$response_file" ]; then
      # Response received - read and return
      local response
      response=$(cat "$response_file")

      if [ -z "$response" ]; then
        log_classification_debug "invoke_llm_classifier" "response file empty"
        cleanup_temp_files
        return 1
      fi

      local elapsed=$(echo "$count * 0.5" | awk '{print $1}')
      log_classification_debug "invoke_llm_classifier" "response received after ${elapsed}s"
      echo "$response"
      cleanup_temp_files
      return 0
    fi

    sleep 0.5
    count=$((count + 1))
  done

  # Timeout
  log_classification_error "invoke_llm_classifier" "timeout after ${WORKFLOW_CLASSIFICATION_TIMEOUT}s"
  cleanup_temp_files
  return 1
}

# parse_llm_classifier_response - Validate and parse LLM JSON response
# Args:
#   $1: llm_output - Raw LLM output (JSON string)
# Returns:
#   0: Success (prints validated JSON to stdout)
#   1: Invalid or malformed response
parse_llm_classifier_response() {
  local llm_output="$1"

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

  # Extract and validate required fields
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

  # Validate confidence range (0.0 to 1.0)
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

# Export functions for use by other scripts
export -f classify_workflow_llm
export -f build_llm_classifier_input
export -f invoke_llm_classifier
export -f parse_llm_classifier_response
export -f log_classification_result
export -f log_classification_error
export -f log_classification_debug
