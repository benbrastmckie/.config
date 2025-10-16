#!/usr/bin/env bash
# Error handling and recovery utilities
# Provides functions for error classification, recovery, retry logic, and escalation

set -euo pipefail

# ==============================================================================
# Error Classification
# ==============================================================================

# Error types (matches error-handling-guidelines.md)
readonly ERROR_TYPE_TRANSIENT="transient"
readonly ERROR_TYPE_PERMANENT="permanent"
readonly ERROR_TYPE_FATAL="fatal"

# classify_error: Classify error based on error message
# Usage: classify_error <error-message>
# Returns: Error type (transient, permanent, fatal)
# Example: classify_error "File locked by another process"
classify_error() {
  local error_message="${1:-}"

  if [ -z "$error_message" ]; then
    echo "$ERROR_TYPE_PERMANENT"
    return
  fi

  # Transient error keywords
  if echo "$error_message" | grep -qiE "locked|busy|timeout|temporary|unavailable|try again"; then
    echo "$ERROR_TYPE_TRANSIENT"
    return
  fi

  # Fatal error keywords
  if echo "$error_message" | grep -qiE "out of.*space|disk.*full|permission.*denied|no such file|corrupted"; then
    echo "$ERROR_TYPE_FATAL"
    return
  fi

  # Default to permanent (code-level issues)
  echo "$ERROR_TYPE_PERMANENT"
}

# suggest_recovery: Suggest recovery action based on error type and message
# Usage: suggest_recovery <error-type> <error-message>
# Returns: Recovery suggestion text
# Example: suggest_recovery "transient" "Database connection timeout"
suggest_recovery() {
  local error_type="${1:-}"
  local error_message="${2:-}"

  case "$error_type" in
    "$ERROR_TYPE_TRANSIENT")
      echo "Retry with exponential backoff (2-3 attempts)"
      echo "Check system resources and try again"
      ;;
    "$ERROR_TYPE_PERMANENT")
      echo "Analyze error message for code-level issues"
      echo "Fix the underlying problem and retry"
      echo "Consider using /debug for investigation"
      ;;
    "$ERROR_TYPE_FATAL")
      echo "User intervention required"
      echo "Check system resources (disk space, permissions)"
      echo "Resolve environment issues before continuing"
      ;;
    *)
      echo "Unknown error type, manual investigation needed"
      ;;
  esac
}

# ==============================================================================
# Detailed Error Analysis
# ==============================================================================

# detect_error_type: Detect specific error type from error message
# Usage: detect_error_type <error-message>
# Returns: Specific error type (syntax, test_failure, file_not_found, etc.)
# Example: detect_error_type "syntax error at line 42"
detect_error_type() {
  local error="$1"

  # Syntax errors
  if echo "$error" | grep -qi "syntax error\|unexpected\|expected.*got"; then
    echo "syntax"
    return
  fi

  # Test failures
  if echo "$error" | grep -qi "test.*fail\|assertion.*fail\|expected.*actual"; then
    echo "test_failure"
    return
  fi

  # File not found
  if echo "$error" | grep -qi "no such file\|cannot find\|file not found"; then
    echo "file_not_found"
    return
  fi

  # Import/require errors
  if echo "$error" | grep -qi "cannot.*import\|module not found\|require.*failed"; then
    echo "import_error"
    return
  fi

  # Null/nil errors
  if echo "$error" | grep -qi "null pointer\|nil value\|undefined.*not.*function"; then
    echo "null_error"
    return
  fi

  # Timeout errors
  if echo "$error" | grep -qi "timeout\|timed out\|deadline exceeded"; then
    echo "timeout"
    return
  fi

  # Permission errors
  if echo "$error" | grep -qi "permission denied\|access denied\|not permitted"; then
    echo "permission"
    return
  fi

  # Default: unknown
  echo "unknown"
}

# extract_location: Extract file location from error message
# Usage: extract_location <error-message>
# Returns: File location in format file:line
# Example: extract_location "Error in test.lua:42: syntax error"
extract_location() {
  local error="$1"

  # Try common patterns: file.ext:line, file.ext line, at file.ext:line
  if echo "$error" | grep -qo '[a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+'; then
    echo "$error" | grep -o '[a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+' | head -1
  elif echo "$error" | grep -qo 'at [a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+'; then
    echo "$error" | grep -o 'at [a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+' | sed 's/^at //' | head -1
  else
    echo ""
  fi
}

# generate_suggestions: Generate error-specific suggestions
# Usage: generate_suggestions <error-type> <error-output> <location>
# Returns: Formatted suggestions for fixing the error
# Example: generate_suggestions "syntax" "error msg" "file.lua:42"
generate_suggestions() {
  local error_type="$1"
  local error_output="$2"
  local location="$3"

  case "$error_type" in
    syntax)
      echo "Suggestions:"
      echo "1. Check syntax at $location - look for missing brackets, quotes, or semicolons"
      echo "2. Review language documentation for correct syntax"
      echo "3. Use linter to identify syntax issues: <leader>l in neovim"
      ;;

    test_failure)
      echo "Suggestions:"
      echo "1. Check test setup - verify mocks and fixtures are initialized correctly"
      echo "2. Review test data - ensure test inputs match expected types and values"
      echo "3. Check for race conditions - add delays or synchronization if timing-sensitive"
      echo "4. Run test in isolation: :TestNearest to isolate the failure"
      ;;

    file_not_found)
      local missing_file
      missing_file=$(echo "$error_output" | grep -o "'[^']*'" | head -1 | tr -d "'")
      echo "Suggestions:"
      echo "1. Check file path spelling and capitalization: $missing_file"
      echo "2. Verify file exists relative to current directory or project root"
      echo "3. Check gitignore - file may exist but be ignored"
      echo "4. Create missing file if needed: touch $missing_file"
      ;;

    import_error)
      local missing_module
      missing_module=$(echo "$error_output" | grep -o "'[^']*'" | head -1 | tr -d "'")
      echo "Suggestions:"
      echo "1. Install missing package: check package.json/requirements.txt/Cargo.toml"
      echo "2. Check import path - verify module name and location"
      echo "3. Rebuild project dependencies: npm install, pip install, cargo build"
      echo "4. Check module exists in node_modules/ or site-packages/"
      ;;

    null_error)
      echo "Suggestions:"
      echo "1. Add nil/null check before accessing value at $location"
      echo "2. Verify initialization - ensure variable is set before use"
      echo "3. Check function return values - ensure they return expected values"
      echo "4. Use pcall/try-catch for operations that might fail"
      ;;

    timeout)
      echo "Suggestions:"
      echo "1. Increase timeout value in test or operation configuration"
      echo "2. Optimize slow operations - check for inefficient loops or queries"
      echo "3. Check for infinite loops or blocking operations"
      echo "4. Review network calls - add retries or increase timeout"
      ;;

    permission)
      echo "Suggestions:"
      echo "1. Check file permissions: ls -la $location"
      echo "2. Verify user has necessary access rights"
      echo "3. Run with appropriate permissions if needed: sudo or ownership change"
      echo "4. Check if file is locked by another process"
      ;;

    *)
      echo "Suggestions:"
      echo "1. Review error message carefully for specific details"
      echo "2. Check recent changes that might have introduced the issue"
      echo "3. Search documentation or issues for similar errors"
      echo "4. Use /debug command for detailed investigation"
      ;;
  esac
}

# ==============================================================================
# Retry Logic
# ==============================================================================

# retry_with_backoff: Retry command with exponential backoff
# Usage: retry_with_backoff <max-attempts> <base-delay-ms> <command> [args...]
# Returns: 0 if command succeeds, 1 if all retries exhausted
# Example: retry_with_backoff 3 500 curl "https://api.example.com"
retry_with_backoff() {
  local max_attempts="${1:-3}"
  local base_delay_ms="${2:-500}"
  shift 2
  local command=("$@")

  local attempt=1
  local delay_ms=$base_delay_ms

  while [ $attempt -le $max_attempts ]; do
    if "${command[@]}" 2>/dev/null; then
      return 0
    fi

    if [ $attempt -lt $max_attempts ]; then
      echo "Attempt $attempt failed, retrying in ${delay_ms}ms..." >&2
      sleep $(bc <<< "scale=3; $delay_ms / 1000") 2>/dev/null || sleep 1
      delay_ms=$((delay_ms * 2))
      attempt=$((attempt + 1))
    else
      echo "All $max_attempts attempts failed" >&2
      return 1
    fi
  done

  return 1
}

# retry_with_timeout: Generate retry metadata with extended timeout
# Usage: retry_with_timeout <operation_name> <attempt_number>
# Returns: JSON with retry metadata (new_timeout, should_retry, attempt)
# Example: retry_with_timeout "Agent invocation" 0
retry_with_timeout() {
  local operation_name="${1:-}"
  local attempt_number="${2:-0}"

  if [[ -z "$operation_name" ]]; then
    echo "ERROR: retry_with_timeout requires operation_name" >&2
    return 1
  fi

  local base_timeout=120000  # 2 minutes
  local max_attempts=3

  # Calculate new timeout (1.5x increase per attempt)
  local new_timeout=$base_timeout
  for (( i=0; i<attempt_number; i++ )); do
    new_timeout=$((new_timeout * 3 / 2))
  done

  # Determine if should retry
  local should_retry="true"
  if [[ $attempt_number -ge $max_attempts ]]; then
    should_retry="false"
  fi

  # Return JSON metadata
  jq -n \
    --arg operation "$operation_name" \
    --argjson attempt "$attempt_number" \
    --argjson new_timeout "$new_timeout" \
    --arg should_retry "$should_retry" \
    --argjson max_attempts "$max_attempts" \
    '{
      operation: $operation,
      attempt: $attempt,
      new_timeout: $new_timeout,
      should_retry: $should_retry,
      max_attempts: $max_attempts
    }'
}

# retry_with_fallback: Generate fallback retry metadata with reduced toolset
# Usage: retry_with_fallback <operation_name> <attempt_number>
# Returns: JSON with reduced toolset recommendation
# Example: retry_with_fallback "expand_phase" 1
retry_with_fallback() {
  local operation_name="${1:-}"
  local attempt_number="${2:-1}"

  if [[ -z "$operation_name" ]]; then
    echo "ERROR: retry_with_fallback requires operation_name" >&2
    return 1
  fi

  # Define toolset levels
  local full_toolset="Read,Write,Edit,Bash"
  local reduced_toolset="Read,Write"

  # Return JSON metadata
  jq -n \
    --arg operation "$operation_name" \
    --argjson attempt "$attempt_number" \
    --arg full_toolset "$full_toolset" \
    --arg reduced_toolset "$reduced_toolset" \
    --arg strategy "fallback" \
    '{
      operation: $operation,
      attempt: $attempt,
      full_toolset: $full_toolset,
      reduced_toolset: $reduced_toolset,
      strategy: $strategy,
      recommendation: "Retry with reduced toolset to avoid complex operations"
    }'
}

# ==============================================================================
# Error Logging
# ==============================================================================

# Error log directory
readonly ERROR_LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/data/logs"

# log_error_context: Log error with context for debugging
# Usage: log_error_context <error-type> <location> <message> [context-data]
# Returns: Path to error log file
# Example: log_error_context "permanent" "auth.lua:42" "nil reference" '{"phase":3}'
log_error_context() {
  local error_type="${1:-unknown}"
  local location="${2:-unknown}"
  local message="${3:-}"
  local context_data="${4:-{}}"

  # Ensure log directory exists
  mkdir -p "$ERROR_LOG_DIR"

  local timestamp=$(date -u +%Y%m%d_%H%M%S)
  local log_file="${ERROR_LOG_DIR}/error_${timestamp}.log"

  # Create structured error log
  cat > "$log_file" <<EOF
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Error Type: $error_type
Location: $location
Message: $message

Context Data:
$context_data

Stack Trace:
$(caller 0 2>/dev/null || echo "Not available")
$(caller 1 2>/dev/null || echo "")
$(caller 2 2>/dev/null || echo "")
EOF

  echo "$log_file"
}

# ==============================================================================
# User Escalation
# ==============================================================================

# escalate_to_user: Present error to user with recovery options
# Usage: escalate_to_user <error-message> <recovery-suggestions>
# Returns: User's choice or empty if non-interactive
# Example: escalate_to_user "Build failed" "1. Fix code\n2. Skip phase\n3. Abort"
escalate_to_user() {
  local error_message="${1:-}"
  local recovery_suggestions="${2:-}"

  echo "=========================================="
  echo "Error Encountered"
  echo "=========================================="
  echo ""
  echo "Error: $error_message"
  echo ""
  echo "Recovery Options:"
  echo -e "$recovery_suggestions"
  echo ""
  echo "=========================================="

  # Check if running interactively
  if [ -t 0 ]; then
    read -p "Choose an option: " choice
    echo "$choice"
  else
    # Non-interactive, return empty
    echo ""
  fi
}

# escalate_to_user_parallel: Format escalation message with context (parallel operations version)
# Usage: escalate_to_user_parallel <error_context_json> <recovery_options>
# Returns: User choice or recommendation
# Example: escalate_to_user_parallel '{"operation":"expand","failed":2}' "retry,skip,abort"
escalate_to_user_parallel() {
  local error_context_json="${1:-}"
  local recovery_options="${2:-retry,skip,abort}"

  if [[ -z "$error_context_json" ]]; then
    echo "ERROR: escalate_to_user_parallel requires error_context_json" >&2
    return 1
  fi

  # Parse context
  local operation failed_count total_count
  operation=$(echo "$error_context_json" | jq -r '.operation // "unknown"')
  failed_count=$(echo "$error_context_json" | jq -r '.failed // 0')
  total_count=$(echo "$error_context_json" | jq -r '.total // 0')

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "User Escalation Required" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "Operation: $operation" >&2
  echo "Failed: $failed_count/$total_count operations" >&2
  echo "" >&2
  echo "Recovery Options:" >&2

  # Parse and display options
  IFS=',' read -ra OPTIONS <<< "$recovery_options"
  local idx=1
  for option in "${OPTIONS[@]}"; do
    echo "  $idx. $option" >&2
    idx=$((idx + 1))
  done

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

  # Check if interactive
  if [[ -t 0 ]]; then
    echo -n "Choose an option (1-${#OPTIONS[@]}): " >&2
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#OPTIONS[@]} ]]; then
      echo "${OPTIONS[$((choice-1))]}"
      return 0
    else
      echo "Invalid choice, defaulting to: ${OPTIONS[0]}" >&2
      echo "${OPTIONS[0]}"
      return 0
    fi
  else
    # Non-interactive, return first option
    echo "${OPTIONS[0]}"
    return 0
  fi
}

# ==============================================================================
# Graceful Degradation
# ==============================================================================

# try_with_fallback: Try primary approach, fall back to alternative
# Usage: try_with_fallback <primary-command> <fallback-command>
# Returns: 0 if either succeeds, 1 if both fail
# Example: try_with_fallback "complex_edit file.lua" "simple_edit file.lua"
try_with_fallback() {
  local primary_command="$1"
  local fallback_command="$2"

  if eval "$primary_command" 2>/dev/null; then
    echo "Primary approach succeeded" >&2
    return 0
  fi

  echo "Primary approach failed, trying fallback..." >&2

  if eval "$fallback_command" 2>/dev/null; then
    echo "Fallback approach succeeded" >&2
    return 0
  fi

  echo "Both primary and fallback approaches failed" >&2
  return 1
}

# ==============================================================================
# Error Reporting
# ==============================================================================

# format_error_report: Format error message with context and suggestions
# Usage: format_error_report <error-type> <operation> <file> <message> <attempts>
# Returns: Formatted error report
# Example: format_error_report "transient" "Write test file" "test.lua" "locked" 3
format_error_report() {
  local error_type="${1:-}"
  local operation="${2:-}"
  local file="${3:-}"
  local message="${4:-}"
  local attempts="${5:-1}"

  cat <<EOF
$(echo "$error_type" | tr '[:lower:]' '[:upper:]') Error: $message

Context:
- Operation: $operation
- File/Location: $file
- Attempts: $attempts

$(suggest_recovery "$error_type" "$message")
EOF
}

# ==============================================================================
# Parallel Operation Error Recovery
# ==============================================================================

# handle_partial_failure: Process successful ops, report failures
# Usage: handle_partial_failure <aggregation_json>
# Returns: JSON with successful and failed operations separated
# Example: handle_partial_failure '{"total":3,"successful":2,"failed":1,"artifacts":[...]}'
handle_partial_failure() {
  local aggregation_json="${1:-}"

  if [[ -z "$aggregation_json" ]]; then
    echo "ERROR: handle_partial_failure requires aggregation_json" >&2
    return 1
  fi

  # Validate JSON
  if ! echo "$aggregation_json" | jq empty 2>/dev/null; then
    echo "ERROR: Invalid JSON provided to handle_partial_failure" >&2
    return 1
  fi

  local total successful failed
  total=$(echo "$aggregation_json" | jq '.total // 0')
  successful=$(echo "$aggregation_json" | jq '.successful // 0')
  failed=$(echo "$aggregation_json" | jq '.failed // 0')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Partial Failure Handling" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "Total operations: $total" >&2
  echo "Successful: $successful" >&2
  echo "Failed: $failed" >&2
  echo "" >&2

  if [[ $failed -eq 0 ]]; then
    echo "All operations succeeded" >&2
    # Return enhanced JSON with can_continue and requires_retry fields
    local report
    report=$(echo "$aggregation_json" | jq '. + {can_continue: true, requires_retry: false}')
    echo "$report"
    return 0
  fi

  # Extract successful and failed operations
  local successful_ops failed_ops
  successful_ops=$(echo "$aggregation_json" | jq -c '[.artifacts[] | select(.status == "success")]')
  failed_ops=$(echo "$aggregation_json" | jq -c '[.artifacts[] | select(.status != "success")]')

  echo "Failed operations:" >&2
  echo "$failed_ops" | jq -r '.[] | "  - \(.item_id): \(.error // "Unknown error")"' >&2
  echo "" >&2

  # Build report with separated operations
  local report
  report=$(jq -n \
    --argjson total "$total" \
    --argjson successful "$successful" \
    --argjson failed "$failed" \
    --argjson successful_ops "$successful_ops" \
    --argjson failed_ops "$failed_ops" \
    '{
      total: $total,
      successful: $successful,
      failed: $failed,
      successful_operations: $successful_ops,
      failed_operations: $failed_ops,
      can_continue: ($successful > 0),
      requires_retry: ($failed > 0)
    }')

  echo "$report"
  return 0
}

# ==============================================================================
# Cleanup Helpers
# ==============================================================================

# cleanup_on_error: Cleanup temp files and partial state on error
# Usage: cleanup_on_error <temp-files-pattern>
# Returns: 0 always
# Example: cleanup_on_error "/tmp/claude-*.tmp"
cleanup_on_error() {
  local pattern="${1:-}"

  if [ -n "$pattern" ]; then
    rm -f $pattern 2>/dev/null || true
    echo "Cleaned up temporary files: $pattern" >&2
  fi

  return 0
}

# ==============================================================================
# Orchestrate-Specific Error Contexts
# ==============================================================================

# format_orchestrate_agent_failure: Format agent invocation failure for orchestrate
# Usage: format_orchestrate_agent_failure <agent-type> <workflow-phase> <error-message> [checkpoint-path]
# Returns: Formatted error report with context
# Example: format_orchestrate_agent_failure "research-specialist" "research" "timeout" ".claude/checkpoints/orchestrate_*.json"
format_orchestrate_agent_failure() {
  local agent_type="${1:-unknown}"
  local workflow_phase="${2:-unknown}"
  local error_message="${3:-}"
  local checkpoint_path="${4:-}"

  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Invocation Failure
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow Context:
- Phase: $workflow_phase
- Agent Type: $agent_type
- Error: $error_message

$(if [ -n "$checkpoint_path" ] && [ -f "$checkpoint_path" ]; then
  echo "Resume Command:"
  local workflow_type=$(jq -r '.workflow_type // "orchestrate"' "$checkpoint_path")
  local workflow_desc=$(jq -r '.workflow_description // ""' "$checkpoint_path")
  echo "  /orchestrate \"$workflow_desc\" --resume"
fi)

Recovery Options:
1. Retry agent invocation (automatic retry with backoff already attempted)
2. Skip this agent and proceed with available results
3. Manual intervention: investigate logs and checkpoint state
4. Abort workflow and resolve underlying issue

Troubleshooting:
- Check agent registry: .claude/lib/agent-registry-utils.sh
- Review logs: .claude/logs/adaptive-planning.log
- Inspect checkpoint: $(if [ -n "$checkpoint_path" ]; then echo "$checkpoint_path"; else echo "Not saved"; fi)
EOF
}

# format_orchestrate_test_failure: Format test failure in orchestrate workflow
# Usage: format_orchestrate_test_failure <workflow-phase> <test-output> <checkpoint-path>
# Returns: Formatted error report with workflow context
# Example: format_orchestrate_test_failure "implementation" "Test failed: foo" ".claude/checkpoints/orchestrate_*.json"
format_orchestrate_test_failure() {
  local workflow_phase="${1:-unknown}"
  local test_output="${2:-}"
  local checkpoint_path="${3:-}"

  # Detect error type from test output
  local error_type=$(detect_error_type "$test_output")
  local location=$(extract_location "$test_output")

  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Failure in Orchestrate Workflow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow Context:
- Phase: $workflow_phase
- Error Type: $error_type
$(if [ -n "$location" ]; then echo "- Location: $location"; fi)

Test Output:
$(echo "$test_output" | head -20)

$(generate_suggestions "$error_type" "$test_output" "$location")

$(if [ -n "$checkpoint_path" ] && [ -f "$checkpoint_path" ]; then
  echo "Resume After Fix:"
  local workflow_desc=$(jq -r '.workflow_description // ""' "$checkpoint_path")
  echo "  /orchestrate \"$workflow_desc\" --resume"
fi)

Debug Options:
1. Invoke /debug for detailed analysis
2. Review implementation phase output
3. Check test configuration and setup
4. Manually fix and retry phase
EOF
}

# format_orchestrate_phase_context: Add workflow phase context to any error
# Usage: format_orchestrate_phase_context <base-error> <phase> <agent-type> [params]
# Returns: Error with orchestrate context prepended
# Example: format_orchestrate_phase_context "Connection timeout" "planning" "plan-architect" "retries:3"
format_orchestrate_phase_context() {
  local base_error="${1:-}"
  local phase="${2:-unknown}"
  local agent_type="${3:-}"
  local params="${4:-}"

  cat <<EOF
[Orchestrate Workflow Error]
Phase: $phase
$(if [ -n "$agent_type" ]; then echo "Agent: $agent_type"; fi)
$(if [ -n "$params" ]; then echo "Parameters: $params"; fi)

Error: $base_error
EOF
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f classify_error
  export -f suggest_recovery
  export -f detect_error_type
  export -f extract_location
  export -f generate_suggestions
  export -f retry_with_backoff
  export -f retry_with_timeout
  export -f retry_with_fallback
  export -f log_error_context
  export -f escalate_to_user
  export -f escalate_to_user_parallel
  export -f try_with_fallback
  export -f format_error_report
  export -f handle_partial_failure
  export -f cleanup_on_error
  export -f format_orchestrate_agent_failure
  export -f format_orchestrate_test_failure
  export -f format_orchestrate_phase_context
fi
