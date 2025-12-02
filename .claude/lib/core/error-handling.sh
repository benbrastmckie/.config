#!/usr/bin/env bash
# Error handling and recovery utilities
# Provides functions for error classification, recovery, retry logic, and escalation
#
# Test Context Detection:
#   - ERR trap automatically detects test execution contexts to prevent false positives
#   - Test context patterns: WORKFLOW_ID=test_*, /tmp/test_*.sh scripts, SUPPRESS_ERR_LOGGING=1
#   - Usage: export SUPPRESS_ERR_LOGGING=1 before running test scripts to skip error logging
#   - Effect: Intentional test failures won't be logged as real errors in errors.jsonl

# Source guard: Prevent multiple sourcing
if [ -n "${ERROR_HANDLING_SOURCED:-}" ]; then
  return 0
fi
export ERROR_HANDLING_SOURCED=1

set -euo pipefail

# ==============================================================================
# Pre-Trap Error Buffering
# ==============================================================================
# These functions capture errors that occur BEFORE the bash error trap is fully
# initialized. Errors are buffered in memory and flushed to errors.jsonl once
# the logging infrastructure is available.

# Pre-trap error buffer (array of error entries)
declare -a _EARLY_ERROR_BUFFER=()

# Maximum buffer size to prevent memory issues
readonly _MAX_EARLY_ERROR_BUFFER_SIZE=100

# _buffer_early_error: Buffer an error that occurred before trap initialization
# Usage: _buffer_early_error <line_number> <exit_code> <error_message>
# Returns: 0 if buffered, 1 if buffer full
# Example: _buffer_early_error "$LINENO" "$?" "Failed to source library"
_buffer_early_error() {
  local line_number="${1:-unknown}"
  local exit_code="${2:-1}"
  local error_message="${3:-Unknown error}"

  # Check buffer size limit
  if [ ${#_EARLY_ERROR_BUFFER[@]} -ge $_MAX_EARLY_ERROR_BUFFER_SIZE ]; then
    echo "WARNING: Early error buffer full (${_MAX_EARLY_ERROR_BUFFER_SIZE} entries), discarding oldest" >&2
    # Remove oldest entry (first element)
    _EARLY_ERROR_BUFFER=("${_EARLY_ERROR_BUFFER[@]:1}")
  fi

  # Create buffer entry: "timestamp|line|code|message"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
  local entry="${timestamp}|${line_number}|${exit_code}|${error_message}"

  # Add to buffer
  _EARLY_ERROR_BUFFER+=("$entry")

  return 0
}

# _flush_early_errors: Flush buffered errors to errors.jsonl
# Usage: _flush_early_errors
# Returns: 0 always (best-effort flush)
# Example: _flush_early_errors  # Call after setup_bash_error_trap
_flush_early_errors() {
  # Skip if buffer is empty
  if [ ${#_EARLY_ERROR_BUFFER[@]} -eq 0 ]; then
    return 0
  fi

  # Check if log_command_error function is available
  if ! type log_command_error >/dev/null 2>&1; then
    echo "WARNING: Cannot flush early errors - log_command_error not available" >&2
    return 0
  fi

  # Flush each buffered error
  local entry
  for entry in "${_EARLY_ERROR_BUFFER[@]}"; do
    # Parse entry: timestamp|line|code|message
    local timestamp line_number exit_code error_message
    IFS='|' read -r timestamp line_number exit_code error_message <<< "$entry"

    # Log to errors.jsonl with initialization_error type
    log_command_error \
      "${COMMAND_NAME:-/unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "initialization_error" \
      "Early error at line $line_number (exit $exit_code): $error_message" \
      "pre_trap_buffer" \
      "$(jq -n \
        --arg ts "$timestamp" \
        --arg line "$line_number" \
        --arg code "$exit_code" \
        --arg msg "$error_message" \
        '{timestamp: $ts, line: $line, exit_code: $code, message: $msg}')" 2>/dev/null || true
  done

  # Clear buffer after flush
  _EARLY_ERROR_BUFFER=()

  return 0
}

# ==============================================================================
# Defensive Trap Setup
# ==============================================================================
# These functions provide minimal error traps that can be set BEFORE library
# sourcing and state restoration, ensuring errors are captured even during
# initialization. Used in Block 2+ to prevent 40-68 line vulnerability windows.

# _setup_defensive_trap: Set minimal ERR/EXIT traps before library sourcing
# Usage: _setup_defensive_trap
# Returns: 0 always
# Example: _setup_defensive_trap  # Call before sourcing libraries in Block 2+
_setup_defensive_trap() {
  # Minimal ERR trap: Print diagnostic to stderr and exit
  # This catches errors during library sourcing and state restoration
  trap 'echo "ERROR: Block initialization failed at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2; exit 1' ERR

  # Minimal EXIT trap: Report non-zero exit during initialization
  # This catches unexpected exits during critical initialization code
  trap 'local exit_code=$?; if [ $exit_code -ne 0 ]; then echo "ERROR: Block initialization exited with code $exit_code" >&2; fi' EXIT

  return 0
}

# _clear_defensive_trap: Clear defensive traps before setting full trap
# Usage: _clear_defensive_trap
# Returns: 0 always
# Example: _clear_defensive_trap  # Call before setup_bash_error_trap
_clear_defensive_trap() {
  # Clear ERR and EXIT traps (reset to default behavior)
  trap - ERR
  trap - EXIT

  return 0
}

# ==============================================================================
# Library Sourcing Diagnostics
# ==============================================================================
# These functions replace `2>/dev/null` suppression with diagnostic wrappers
# that capture and report sourcing errors with full context.

# _source_with_diagnostics: Source a library file with error diagnostics
# Usage: _source_with_diagnostics <library_path>
# Returns: 0 if sourcing succeeded, 1 if sourcing failed
# Example: _source_with_diagnostics "$CLAUDE_LIB/core/error-handling.sh"
_source_with_diagnostics() {
  local lib_path="$1"

  # Create temporary file for stderr capture
  local stderr_file
  stderr_file=$(mktemp 2>/dev/null) || {
    echo "ERROR: Cannot create temp file for sourcing diagnostics" >&2
    _buffer_early_error "$LINENO" 1 "mktemp failed for sourcing diagnostics"
    return 1
  }

  # Attempt to source library, capturing stderr
  if source "$lib_path" 2>"$stderr_file"; then
    # Success: clean up and return
    rm -f "$stderr_file" 2>/dev/null
    return 0
  else
    # Failure: capture exit code and stderr
    local exit_code=$?
    local stderr_output
    stderr_output=$(cat "$stderr_file" 2>/dev/null)

    # Build diagnostic error message
    local error_msg="Failed to source $lib_path (exit code: $exit_code)"
    if [ -n "$stderr_output" ]; then
      error_msg="$error_msg - Error: $stderr_output"
    fi

    # Buffer error (trap may not be initialized yet)
    _buffer_early_error "$LINENO" "$exit_code" "$error_msg"

    # Also print to stderr for immediate visibility
    echo "ERROR: $error_msg" >&2

    # Clean up temp file
    rm -f "$stderr_file" 2>/dev/null

    return 1
  fi
}

# ==============================================================================
# Error Classification
# ==============================================================================

# Error types (matches error-handling-guidelines.md)
readonly ERROR_TYPE_TRANSIENT="transient"
readonly ERROR_TYPE_PERMANENT="permanent"
readonly ERROR_TYPE_FATAL="fatal"

# LLM-specific error types (Spec 688)
readonly ERROR_TYPE_LLM_TIMEOUT="llm_timeout"
readonly ERROR_TYPE_LLM_API_ERROR="llm_api_error"
readonly ERROR_TYPE_LLM_LOW_CONFIDENCE="llm_low_confidence"
readonly ERROR_TYPE_LLM_PARSE_ERROR="llm_parse_error"
readonly ERROR_TYPE_INVALID_MODE="invalid_mode"

# is_test_context: Detect if current execution context is a test framework
# Usage: is_test_context
# Returns: 0 if test context detected, 1 otherwise
# Effect: Used to suppress error logging for intentional test framework errors
# Test Detection Methods:
#   1. Workflow ID pattern: WORKFLOW_ID matches ^test_
#   2. Script path pattern: Calling script matches /tmp/test_.*\.sh$
#   3. Environment variable: SUPPRESS_ERR_LOGGING=1
# Example: if is_test_context; then skip_logging; fi
is_test_context() {
  # Check 1: Workflow ID pattern (test_*)
  if [[ "${WORKFLOW_ID:-}" =~ ^test_ ]]; then
    return 0
  fi

  # Check 2: Calling script in /tmp/test_*.sh
  # BASH_SOURCE[2] is the script that called the error trap function
  local caller_script="${BASH_SOURCE[2]:-}"
  if [[ "$caller_script" =~ /tmp/test_.*\.sh$ ]]; then
    return 0
  fi

  # Check 3: Environment variable override
  if [ "${SUPPRESS_ERR_LOGGING:-0}" = "1" ]; then
    return 0
  fi

  return 1
}

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

# Test log directory
readonly TEST_LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/tests/logs"

# Error log file (default to production, set dynamically in log_command_error)
ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.jsonl"

# Error type constants for consistency
readonly ERROR_TYPE_STATE="state_error"
readonly ERROR_TYPE_VALIDATION="validation_error"
readonly ERROR_TYPE_AGENT="agent_error"
readonly ERROR_TYPE_PARSE="parse_error"
readonly ERROR_TYPE_FILE="file_error"
readonly ERROR_TYPE_TIMEOUT_ERR="timeout_error"
readonly ERROR_TYPE_EXECUTION="execution_error"

# log_error_context: Log error with context for debugging (legacy function)
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

# log_command_error: Log command error to centralized JSONL error log
# Usage: log_command_error <command> <workflow_id> <user_args> <error_type> <message> <source> [context_json]
# Returns: 0 on success, 1 on failure
# Example: log_command_error "/build" "build_123" "plan.md 3" "state_error" "State file not found" "bash_block" '{"state_file": "/path"}'
#
# DEFENSIVE: Parameter count validation (Spec 976 Phase 4)
# Function expects 6-7 parameters. Parameter 7 (context_json) is optional.
# Accessing unset $7 causes "unbound variable" error (bash set -u mode).
log_command_error() {
  # Validate minimum parameter count (6 required, 7th optional)
  if [ $# -lt 6 ]; then
    echo "ERROR: log_command_error requires at least 6 parameters (got $#)" >&2
    echo "Usage: log_command_error <command> <workflow_id> <user_args> <error_type> <message> <source> [context_json]" >&2
    echo "Received parameters: $*" >&2
    return 1
  fi

  local command="${1:-unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"
  local error_type="${4:-unknown}"
  local message="${5:-}"
  local source="${6:-unknown}"
  local context_json="${7:-}"  # Optional parameter, default to empty string if not provided

  # Default to empty object if not provided or invalid
  if [ -z "$context_json" ]; then
    context_json="{}"
  fi

  # Validate context_json is valid JSON
  if ! echo "$context_json" | jq empty 2>/dev/null; then
    context_json="{}"
  fi

  # Enhance context with environment paths for path-related error types
  # This helps debug path mismatches between expected and actual file locations
  case "$error_type" in
    state_error|file_error)
      context_json=$(echo "$context_json" | jq \
        --arg home "${HOME:-}" \
        --arg project_dir "${CLAUDE_PROJECT_DIR:-}" \
        '. + {home: $home, claude_project_dir: $project_dir}')
      ;;
  esac

  # Detect execution environment (test vs production)
  local environment="production"

  # Check for explicit test mode, test script indicators, or test workflow ID patterns
  # Added workflow_id pattern matching for test_* prefixed IDs to isolate test errors
  if [[ -n "${CLAUDE_TEST_MODE:-}" ]] || \
     [[ "${BASH_SOURCE[2]:-}" =~ /tests/ ]] || \
     [[ "$0" =~ /tests/ ]] || \
     [[ "$workflow_id" =~ ^test_ ]]; then
    environment="test"
  fi

  # Route to appropriate log file based on environment
  if [ "$environment" = "test" ]; then
    ERROR_LOG_FILE="${TEST_LOG_DIR}/test-errors.jsonl"
    mkdir -p "$TEST_LOG_DIR"
  else
    ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.jsonl"
    mkdir -p "$ERROR_LOG_DIR"
  fi

  # Check for log rotation
  rotate_error_log

  # Generate timestamp in ISO 8601 format
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Build stack trace array
  local stack_json="[]"
  local stack_items=()
  local i=0
  while true; do
    local caller_info
    caller_info=$(caller $i 2>/dev/null) || break
    if [ -n "$caller_info" ]; then
      stack_items+=("$caller_info")
    fi
    i=$((i + 1))
    # Safety limit
    if [ $i -gt 20 ]; then
      break
    fi
  done
  if [ ${#stack_items[@]} -gt 0 ]; then
    stack_json=$(printf '%s\n' "${stack_items[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')
  fi

  # Build and append JSON entry (compact format for JSONL)
  # Include status field (default: ERROR) and status_updated_at (null for new entries)
  local json_entry
  json_entry=$(jq -c -n \
    --arg timestamp "$timestamp" \
    --arg environment "$environment" \
    --arg command "$command" \
    --arg workflow_id "$workflow_id" \
    --arg user_args "$user_args" \
    --arg error_type "$error_type" \
    --arg message "$message" \
    --arg source "$source" \
    --argjson stack "$stack_json" \
    --argjson context "$context_json" \
    '{
      timestamp: $timestamp,
      environment: $environment,
      command: $command,
      workflow_id: $workflow_id,
      user_args: $user_args,
      error_type: $error_type,
      error_message: $message,
      source: $source,
      stack: $stack,
      context: $context,
      status: "ERROR",
      status_updated_at: null,
      repair_plan_path: null
    }')

  # Append to JSONL log file
  echo "$json_entry" >> "$ERROR_LOG_FILE"
  return 0
}

# parse_subagent_error: Parse TASK_ERROR signal from subagent output
# Usage: parse_subagent_error <output>
# Returns: JSON with error_type and message, or empty {} if no error found
# Example:
#   output="TASK_ERROR: validation_error - Schema mismatch"
#   error_json=$(parse_subagent_error "$output")
#   # Returns: {"error_type": "validation_error", "message": "Schema mismatch", "found": true}
parse_subagent_error() {
  local output="${1:-}"

  # Look for TASK_ERROR signal pattern
  # Format: TASK_ERROR: error_type - message
  if echo "$output" | grep -q "TASK_ERROR:"; then
    local error_line
    error_line=$(echo "$output" | grep "TASK_ERROR:" | head -1)

    # Extract error_type and message
    local error_type message
    error_type=$(echo "$error_line" | sed -n 's/.*TASK_ERROR: *\([^ -]*\).*/\1/p')
    message=$(echo "$error_line" | sed -n 's/.*TASK_ERROR: *[^ -]* *- *\(.*\)/\1/p')

    # Also look for ERROR_CONTEXT JSON if present
    local error_context="{}"
    if echo "$output" | grep -q "ERROR_CONTEXT:"; then
      error_context=$(echo "$output" | sed -n '/ERROR_CONTEXT:/,/```/p' | sed '1d;$d' | jq -c '.' 2>/dev/null || echo "{}")
    fi

    jq -n \
      --arg error_type "$error_type" \
      --arg message "$message" \
      --argjson context "$error_context" \
      '{
        error_type: $error_type,
        message: $message,
        context: $context,
        found: true
      }'
  else
    echo '{"found": false}'
  fi
}

# rotate_error_log: Rotate error log file if it exceeds size threshold
# Usage: rotate_error_log
# Returns: 0 always
# Rotates with 5-file retention (errors.jsonl.1, .2, etc.)
rotate_error_log() {
  local log_file="$ERROR_LOG_FILE"
  local max_size_bytes=$((10 * 1024 * 1024))  # 10MB
  local max_backups=5

  # Check if log file exists
  if [ ! -f "$log_file" ]; then
    return 0
  fi

  # Check file size
  local file_size
  file_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0)

  if [ "$file_size" -ge "$max_size_bytes" ]; then
    # Rotate existing backups
    for i in $(seq $((max_backups - 1)) -1 1); do
      if [ -f "${log_file}.${i}" ]; then
        mv "${log_file}.${i}" "${log_file}.$((i + 1))"
      fi
    done

    # Move current log to .1
    mv "$log_file" "${log_file}.1"

    # Create new empty log file
    touch "$log_file"
  fi

  return 0
}

# ensure_error_log_exists: Ensure error log directory and file exist
# Usage: ensure_error_log_exists
# Returns: 0 on success
ensure_error_log_exists() {
  mkdir -p "$ERROR_LOG_DIR"
  if [ ! -f "$ERROR_LOG_FILE" ]; then
    touch "$ERROR_LOG_FILE"
  fi
  return 0
}

# log_early_error: Log error before error logging infrastructure fully initialized
# Usage: log_early_error <error_message> [error_context_json]
# Returns: Always 0 (failure is silent to avoid breaking initialization)
# Context: Used for errors before COMMAND_NAME, WORKFLOW_ID, USER_ARGS available
# Example: log_early_error "Failed to source library" '{"library":"error-handling.sh"}'
log_early_error() {
  local error_msg="${1:-Unknown early error}"
  local error_context="${2:-{}}"

  # Minimal logging without USER_ARGS dependency
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  local cmd="${COMMAND_NAME:-unknown}"
  local wf="${WORKFLOW_ID:-unknown_$(date +%s 2>/dev/null || echo 'unknown')}"

  # Ensure error log exists before writing
  local log_dir="${ERROR_LOG_DIR:-${CLAUDE_PROJECT_DIR:-.}/.claude/data/logs}"
  local log_file="${log_dir}/errors.jsonl"
  mkdir -p "$log_dir" 2>/dev/null || true

  # Build JSON and append to log (silent failure if jq unavailable)
  jq -n \
    --arg ts "$ts" \
    --arg cmd "$cmd" \
    --arg wf "$wf" \
    --arg msg "$error_msg" \
    --argjson ctx "$error_context" \
    '{
      timestamp: $ts,
      environment: "production",
      command: $cmd,
      workflow_id: $wf,
      user_args: "",
      error_type: "initialization_error",
      error_message: $msg,
      source: "early_initialization",
      stack: [],
      context: $ctx,
      status: "ERROR",
      status_updated_at: null,
      repair_plan_path: null
    }' >> "$log_file" 2>/dev/null || true

  return 0
}

# validate_state_restoration: Validate required variables restored from state file
# Usage: validate_state_restoration <var1> [var2] [var3] ...
# Returns: 0 if all variables set, 1 if any missing (logs error before return)
# Context: Call after load_workflow_state in multi-block workflows
# Example: validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "PLAN_PATH"
validate_state_restoration() {
  local required_vars=("$@")
  local missing_vars=()

  # Temporarily allow unset for variable checking
  set +u

  # Check each required variable
  for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      missing_vars+=("$var")
    fi
  done

  # Re-enable unset variable checking
  set -u

  # If any variables missing, log error and return failure
  if [ ${#missing_vars[@]} -gt 0 ]; then
    local missing_list=$(printf '%s,' "${missing_vars[@]}")
    missing_list="${missing_list%,}"  # Remove trailing comma

    log_command_error \
      "${COMMAND_NAME:-unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "state_error" \
      "State restoration incomplete: missing ${missing_list}" \
      "state_validation" \
      "$(jq -n --arg vars "$missing_list" '{missing_variables: $vars}')"

    return 1
  fi

  return 0
}

# check_unbound_vars: Check if variables are set before use (defensive pattern)
# Usage: check_unbound_vars <var1> [var2] [var3] ...
# Returns: 0 if all variables set, 1 if any missing (does NOT log error)
# Context: Use for optional variables where missing is not an error
# Example: check_unbound_vars "OPTIONAL_FILE" || OPTIONAL_FILE=""
check_unbound_vars() {
  local vars_to_check=("$@")

  # Temporarily allow unset for variable checking
  set +u

  # Check each variable
  for var in "${vars_to_check[@]}"; do
    if [ -z "${!var:-}" ]; then
      set -u
      return 1
    fi
  done

  # Re-enable unset variable checking
  set -u

  return 0
}

# query_errors: Query errors from JSONL log with filters
# Usage: query_errors [--command CMD] [--since TIME] [--type TYPE] [--status STATUS] [--limit N] [--workflow-id ID]
# Returns: Filtered JSONL entries on stdout
# Note: Backward compatible - entries missing status field are treated as "ERROR"
# Example: query_errors --command /build --status ERROR --limit 10
query_errors() {
  local command_filter=""
  local since_filter=""
  local type_filter=""
  local status_filter=""
  local workflow_filter=""
  local limit=50
  local log_file="${ERROR_LOG_DIR}/errors.jsonl"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --command)
        command_filter="$2"
        shift 2
        ;;
      --since)
        since_filter="$2"
        shift 2
        ;;
      --type)
        type_filter="$2"
        shift 2
        ;;
      --status)
        status_filter="$2"
        shift 2
        ;;
      --limit)
        limit="$2"
        shift 2
        ;;
      --workflow-id)
        workflow_filter="$2"
        shift 2
        ;;
      --log-file)
        log_file="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  # Check if log file exists
  if [ ! -f "$log_file" ]; then
    return 0
  fi

  # Build jq filter with backward compatibility for status field
  # Entries without status field default to "ERROR"
  local jq_filter=". | if .status == null then . + {status: \"ERROR\"} else . end"

  if [ -n "$command_filter" ]; then
    jq_filter="$jq_filter | select(.command == \"$command_filter\")"
  fi

  if [ -n "$type_filter" ]; then
    jq_filter="$jq_filter | select(.error_type == \"$type_filter\")"
  fi

  if [ -n "$status_filter" ]; then
    jq_filter="$jq_filter | select(.status == \"$status_filter\")"
  fi

  if [ -n "$workflow_filter" ]; then
    jq_filter="$jq_filter | select(.workflow_id == \"$workflow_filter\")"
  fi

  if [ -n "$since_filter" ]; then
    jq_filter="$jq_filter | select(.timestamp >= \"$since_filter\")"
  fi

  # Apply filter and limit
  jq -c "$jq_filter" "$log_file" 2>/dev/null | tail -n "$limit"
}

# recent_errors: Display recent errors in human-readable format
# Usage: recent_errors [count]
# Returns: Formatted error list on stdout
# Note: Displays status field with backward compatibility (defaults to "ERROR" if missing)
# Example: recent_errors 5
recent_errors() {
  local count="${1:-10}"

  # Check if log file exists
  if [ ! -f "$ERROR_LOG_FILE" ]; then
    echo "No error log found."
    return 0
  fi

  # Check if log file is empty
  if [ ! -s "$ERROR_LOG_FILE" ]; then
    echo "No errors logged."
    return 0
  fi

  echo "Recent Errors (last $count):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  tail -n "$count" "$ERROR_LOG_FILE" | while IFS= read -r line; do
    if [ -n "$line" ]; then
      local timestamp command error_type message user_args workflow_id status repair_plan
      timestamp=$(echo "$line" | jq -r '.timestamp // "unknown"' 2>/dev/null)
      command=$(echo "$line" | jq -r '.command // "unknown"' 2>/dev/null)
      error_type=$(echo "$line" | jq -r '.error_type // "unknown"' 2>/dev/null)
      message=$(echo "$line" | jq -r '.error_message // "No message"' 2>/dev/null)
      user_args=$(echo "$line" | jq -r '.user_args // ""' 2>/dev/null)
      workflow_id=$(echo "$line" | jq -r '.workflow_id // "unknown"' 2>/dev/null)
      # Backward compatibility: default to ERROR if status field missing
      status=$(echo "$line" | jq -r '.status // "ERROR"' 2>/dev/null)
      repair_plan=$(echo "$line" | jq -r '.repair_plan_path // ""' 2>/dev/null)

      echo ""
      echo "[$timestamp] $command"
      echo "  Type: $error_type"
      echo "  Status: $status"
      echo "  Message: $message"
      if [ -n "$user_args" ]; then
        # Truncate long args
        if [ ${#user_args} -gt 50 ]; then
          user_args="${user_args:0:47}..."
        fi
        echo "  Args: $user_args"
      fi
      echo "  Workflow: $workflow_id"
      if [ -n "$repair_plan" ] && [ "$repair_plan" != "null" ]; then
        echo "  Repair Plan: $repair_plan"
      fi
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# error_summary: Display error summary with counts by command and type
# Usage: error_summary
# Returns: Formatted summary on stdout
error_summary() {
  # Check if log file exists
  if [ ! -f "$ERROR_LOG_FILE" ]; then
    echo "No error log found."
    return 0
  fi

  # Check if log file is empty
  if [ ! -s "$ERROR_LOG_FILE" ]; then
    echo "No errors logged."
    return 0
  fi

  local total_errors
  total_errors=$(wc -l < "$ERROR_LOG_FILE")

  echo "Error Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Total Errors: $total_errors"
  echo ""

  echo "By Command:"
  jq -r '.command' "$ERROR_LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | while read -r count cmd; do
    printf "  %-20s %s\n" "$cmd" "$count"
  done

  echo ""
  echo "By Type:"
  jq -r '.error_type' "$ERROR_LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | while read -r count type; do
    printf "  %-20s %s\n" "$type" "$count"
  done

  echo ""

  # Show time range
  local first_error last_error
  first_error=$(head -1 "$ERROR_LOG_FILE" | jq -r '.timestamp // "unknown"' 2>/dev/null)
  last_error=$(tail -1 "$ERROR_LOG_FILE" | jq -r '.timestamp // "unknown"' 2>/dev/null)

  echo "Time Range:"
  echo "  First: $first_error"
  echo "  Last:  $last_error"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ==============================================================================
# Error Status Updates
# ==============================================================================

# Status constants for error lifecycle
readonly ERROR_STATUS_ERROR="ERROR"
readonly ERROR_STATUS_FIX_PLANNED="FIX_PLANNED"
readonly ERROR_STATUS_RESOLVED="RESOLVED"

# update_error_status: Update a single error entry by workflow_id and timestamp
# Usage: update_error_status <workflow_id> <timestamp> <new_status> [repair_plan_path]
# Returns: 0 on success, 1 on failure
# Example: update_error_status "build_123" "2025-11-23T10:00:00Z" "FIX_PLANNED" "/path/to/plan.md"
update_error_status() {
  local workflow_id="${1:-}"
  local timestamp="${2:-}"
  local new_status="${3:-}"
  local repair_plan_path="${4:-}"

  # Validate required arguments
  if [[ -z "$workflow_id" ]] || [[ -z "$timestamp" ]] || [[ -z "$new_status" ]]; then
    echo "ERROR: update_error_status requires workflow_id, timestamp, and new_status" >&2
    return 1
  fi

  # Validate status value
  case "$new_status" in
    "$ERROR_STATUS_ERROR"|"$ERROR_STATUS_FIX_PLANNED"|"$ERROR_STATUS_RESOLVED")
      ;;
    *)
      echo "ERROR: Invalid status '$new_status'. Must be ERROR, FIX_PLANNED, or RESOLVED" >&2
      return 1
      ;;
  esac

  local log_file="${ERROR_LOG_FILE:-$ERROR_LOG_DIR/errors.jsonl}"

  # Check if log file exists
  if [[ ! -f "$log_file" ]]; then
    echo "ERROR: Log file not found: $log_file" >&2
    return 1
  fi

  # Generate status update timestamp
  local status_updated_at
  status_updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Create temporary file for atomic update
  local temp_file="${log_file}.tmp.$$"

  # Process each line, updating matching entries
  local updated=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      continue
    fi

    local entry_workflow entry_timestamp
    entry_workflow=$(echo "$line" | jq -r '.workflow_id // ""' 2>/dev/null)
    entry_timestamp=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)

    if [[ "$entry_workflow" == "$workflow_id" ]] && [[ "$entry_timestamp" == "$timestamp" ]]; then
      # Update this entry
      local updated_entry
      if [[ -n "$repair_plan_path" ]]; then
        updated_entry=$(echo "$line" | jq -c \
          --arg status "$new_status" \
          --arg updated_at "$status_updated_at" \
          --arg plan_path "$repair_plan_path" \
          '. + {status: $status, status_updated_at: $updated_at, repair_plan_path: $plan_path}')
      else
        updated_entry=$(echo "$line" | jq -c \
          --arg status "$new_status" \
          --arg updated_at "$status_updated_at" \
          '. + {status: $status, status_updated_at: $updated_at}')
      fi
      echo "$updated_entry" >> "$temp_file"
      updated=1
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$log_file"

  if [[ $updated -eq 0 ]]; then
    rm -f "$temp_file"
    echo "WARNING: No matching entry found for workflow_id=$workflow_id, timestamp=$timestamp" >&2
    return 1
  fi

  # Atomic rename
  mv "$temp_file" "$log_file"
  return 0
}

# mark_errors_fix_planned: Bulk update errors matching filter criteria with FIX_PLANNED status
# Usage: mark_errors_fix_planned <plan_path> [--command CMD] [--type TYPE] [--since TIME]
# Returns: Number of updated entries (stdout), 0 on no matches
# Example: mark_errors_fix_planned "/path/to/plan.md" --command /build --since 2025-11-23
mark_errors_fix_planned() {
  local plan_path="${1:-}"
  shift

  # Validate plan path
  if [[ -z "$plan_path" ]]; then
    echo "ERROR: mark_errors_fix_planned requires plan_path as first argument" >&2
    return 1
  fi

  # Parse filter arguments
  local command_filter=""
  local type_filter=""
  local since_filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --command)
        command_filter="$2"
        shift 2
        ;;
      --type)
        type_filter="$2"
        shift 2
        ;;
      --since)
        since_filter="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  local log_file="${ERROR_LOG_FILE:-$ERROR_LOG_DIR/errors.jsonl}"

  # Check if log file exists
  if [[ ! -f "$log_file" ]]; then
    echo "0"
    return 0
  fi

  # Generate status update timestamp
  local status_updated_at
  status_updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Create temporary file for atomic update
  local temp_file="${log_file}.tmp.$$"

  # Process each line, updating matching entries
  local updated_count=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      continue
    fi

    # Extract fields for filtering
    local entry_command entry_type entry_timestamp entry_status
    entry_command=$(echo "$line" | jq -r '.command // ""' 2>/dev/null)
    entry_type=$(echo "$line" | jq -r '.error_type // ""' 2>/dev/null)
    entry_timestamp=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
    entry_status=$(echo "$line" | jq -r '.status // "ERROR"' 2>/dev/null)

    # Only update entries with ERROR status (not already planned/resolved)
    local matches=true
    if [[ "$entry_status" != "ERROR" ]]; then
      matches=false
    fi

    # Apply command filter
    if [[ -n "$command_filter" ]] && [[ "$entry_command" != "$command_filter" ]]; then
      matches=false
    fi

    # Apply type filter
    if [[ -n "$type_filter" ]] && [[ "$entry_type" != "$type_filter" ]]; then
      matches=false
    fi

    # Apply since filter (timestamp comparison)
    if [[ -n "$since_filter" ]] && [[ "$entry_timestamp" < "$since_filter" ]]; then
      matches=false
    fi

    if [[ "$matches" == "true" ]]; then
      # Update this entry
      local updated_entry
      updated_entry=$(echo "$line" | jq -c \
        --arg status "$ERROR_STATUS_FIX_PLANNED" \
        --arg updated_at "$status_updated_at" \
        --arg plan_path "$plan_path" \
        '. + {status: $status, status_updated_at: $updated_at, repair_plan_path: $plan_path}')
      echo "$updated_entry" >> "$temp_file"
      updated_count=$((updated_count + 1))
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$log_file"

  # Atomic rename
  mv "$temp_file" "$log_file"

  # Return count of updated entries
  echo "$updated_count"
  return 0
}

# mark_errors_resolved_for_plan: Update all FIX_PLANNED errors linked to a plan to RESOLVED
# Usage: mark_errors_resolved_for_plan <plan_path>
# Returns: Number of resolved entries (stdout), 0 on no matches
# Example: mark_errors_resolved_for_plan "/path/to/repair-plan.md"
mark_errors_resolved_for_plan() {
  local plan_path="${1:-}"

  if [[ -z "$plan_path" ]]; then
    echo "ERROR: mark_errors_resolved_for_plan requires plan_path argument" >&2
    return 1
  fi

  local log_file="${ERROR_LOG_FILE:-$ERROR_LOG_DIR/errors.jsonl}"

  if [[ ! -f "$log_file" ]]; then
    echo "0"
    return 0
  fi

  local count=0
  local temp_file="${log_file}.tmp.$$"
  local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  while IFS= read -r line; do
    local entry_plan=$(echo "$line" | jq -r '.repair_plan_path // ""')
    local entry_status=$(echo "$line" | jq -r '.status // "ERROR"')

    if [[ "$entry_plan" == "$plan_path" ]] && [[ "$entry_status" == "FIX_PLANNED" ]]; then
      echo "$line" | jq --arg status "RESOLVED" --arg ts "$now" \
        '.status = $status | .status_updated_at = $ts' >> "$temp_file"
      ((count++))
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$log_file"

  mv "$temp_file" "$log_file"
  echo "$count"
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

# ==============================================================================
# State Machine Error Handler (Five-Component Format)
# ==============================================================================

# handle_state_error: Workflow error handler with state context and retry logic
# Usage: handle_state_error <error-message> [exit-code]
# Returns: Never (exits with specified exit code)
#
# Five-Component Error Message Format:
# 1. What failed
# 2. Expected state/behavior
# 3. Diagnostic commands
# 4. Context (workflow phase, state)
# 5. Recommended action
#
# Features:
# - State-aware error messages with workflow context
# - Retry counter tracking (max 2 retries per state)
# - State persistence for resume support
# - Five-component diagnostic format for faster troubleshooting
#
# Example:
#   handle_state_error "Research phase failed verification - 1 reports not created" 1
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"

  # Component 1: What failed
  echo ""
  echo "✗ ERROR in state '$current_state': $error_message"
  echo ""

  # Component 2: Expected state/behavior
  echo "Expected behavior:"
  case "$current_state" in
    research)
      echo "  - All research agents should complete successfully"
      echo "  - All report files created in \$TOPIC_PATH/reports/"
      ;;
    plan)
      echo "  - Implementation plan created successfully"
      echo "  - Plan file created in \$TOPIC_PATH/plans/"
      ;;
    implement|test|debug|document)
      echo "  - State '$current_state' should complete without errors"
      echo "  - Workflow should transition to next valid state"
      ;;
    *)
      echo "  - Workflow should progress to state: $current_state"
      ;;
  esac
  echo ""

  # Component 3: Diagnostic commands
  echo "Diagnostic commands:"
  echo "  # Check workflow state"
  echo "  cat \"\$STATE_FILE\""
  echo ""
  echo "  # Check topic directory"
  echo "  ls -la \"\${TOPIC_PATH:-<not set>}\""
  echo ""
  echo "  # Check library sourcing"
  echo "  bash -n \"\${LIB_DIR}/workflow-state-machine.sh\""
  echo "  bash -n \"\${LIB_DIR}/workflow-initialization.sh\""
  echo ""

  # Component 4: Context (workflow phase, state)
  echo "Context:"
  echo "  - Workflow: ${WORKFLOW_DESCRIPTION:-<not set>}"
  echo "  - Scope: ${WORKFLOW_SCOPE:-<not set>}"
  echo "  - Current State: $current_state"
  echo "  - Terminal State: ${TERMINAL_STATE:-<not set>}"
  echo "  - Topic Path: ${TOPIC_PATH:-<not set>}"
  echo ""

  # Save failed state to workflow state for retry
  if command -v append_workflow_state &>/dev/null; then
    append_workflow_state "FAILED_STATE" "$current_state"
    append_workflow_state "LAST_ERROR" "$error_message"

    # Increment retry counter for this state
    # Use eval for indirect variable expansion (safe: VAR constructed from known state name)
    RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
    RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
    RETRY_COUNT=$((RETRY_COUNT + 1))
    append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"

    # Component 5: Recommended action
    if [ $RETRY_COUNT -ge 2 ]; then
      echo "Recommended action:"
      echo "  - Max retries (2) reached for state '$current_state'"
      echo "  - Review diagnostic output above"
      echo "  - Fix underlying issue before retrying"
      echo "  - Check logs: .claude/data/logs/adaptive-planning.log"
      echo "  - Workflow cannot proceed automatically"
      echo ""
    else
      echo "Recommended action:"
      echo "  - Retry $RETRY_COUNT/2 available for state '$current_state'"
      echo "  - Fix the issue identified in diagnostic output"
      echo "  - Re-run: /coordinate \"${WORKFLOW_DESCRIPTION}\""
      echo "  - State machine will resume from failed state"
      echo ""
    fi
  else
    # State persistence not available (bootstrap phase)
    echo "Recommended action:"
    echo "  - Fix the issue identified in diagnostic output"
    echo "  - Re-run the workflow"
    echo ""
  fi

  exit $exit_code
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f is_test_context
  export -f classify_error
  export -f suggest_recovery
  export -f detect_error_type
  export -f extract_location
  export -f generate_suggestions
# _is_benign_bash_error: Check if error is a benign pre-initialization failure
# Usage: _is_benign_bash_error <failed_command> <exit_code>
# Returns: 0 if error should be filtered (not logged), 1 if error should be logged
# Note: These errors occur during bash environment pre-initialization before command code runs
_is_benign_bash_error() {
  local failed_command="${1:-}"
  local exit_code="${2:-0}"

  # Filter bashrc sourcing failures (system-level initialization, not command code)
  # These occur in Claude Code's bash environment setup, not in our commands
  case "$failed_command" in
    *"/etc/bashrc"*|*"/etc/bash.bashrc"*|*"~/.bashrc"*|*".bashrc"*)
      return 0  # Benign: bashrc sourcing failure
      ;;
    *"source /etc/bashrc"*|*". /etc/bashrc"*)
      return 0  # Benign: explicit bashrc source
      ;;
  esac

  # Filter exit code 127 (command not found) only for specific system initialization commands
  if [ "$exit_code" = "127" ]; then
    case "$failed_command" in
      *"bashrc"*|*"profile"*|*"bash_completion"*)
        return 0  # Benign: system initialization command not found
        ;;
    esac
  fi

  # Filter intentional return statements from WHITELISTED core library functions
  # Whitelist approach: Only filter return statements from specific safe functions
  # Other library functions (e.g., validate_library_functions) should be logged
  case "$failed_command" in
    "return 1"|"return 0"|"return"|"return "[0-9]*)
      # Extract caller function name from call stack
      local caller_func=""
      local j=1
      while true; do
        local lib_caller_info
        lib_caller_info=$(caller $j 2>/dev/null) || break

        # Extract function name (format: "line_num function_name file")
        caller_func=$(echo "$lib_caller_info" | awk '{print $2}')

        # Check if caller is in core library directory
        case "$lib_caller_info" in
          *"/lib/core/"*|*"/lib/workflow/"*|*"/lib/plan/"*)
            # Whitelist of safe functions where returns are intentional
            case "$caller_func" in
              classify_error|suggest_recovery|detect_error_type|extract_location|\
              _is_benign_bash_error|_buffer_early_error|_flush_early_errors|\
              _setup_defensive_trap|_clear_defensive_trap)
                return 0  # Benign: intentional return from whitelisted function
                ;;
              validate_library_functions|validate_workflow_id|validate_state_restoration)
                # Validation failures should be logged, not filtered
                return 1  # Not benign: validation error should be logged
                ;;
            esac
            ;;
        esac

        j=$((j + 1))
        if [ $j -gt 5 ]; then
          break
        fi
      done
      ;;
  esac

  # Check call stack for errors originating from bashrc/profile files
  # This catches errors from commands INSIDE these files, not just sourcing them
  local i=0
  while true; do
    local caller_info
    caller_info=$(caller $i 2>/dev/null) || break
    case "$caller_info" in
      *"/etc/bashrc"*|*"/etc/bash.bashrc"*|*"~/.bashrc"*|*".bashrc"*|*"/etc/profile"*|*".profile"*)
        return 0  # Benign: error originated from system initialization file
        ;;
    esac
    i=$((i + 1))
    # Safety limit
    if [ $i -gt 10 ]; then
      break
    fi
  done

  return 1  # Not benign: should be logged
}

# _log_bash_error: Internal ERR trap handler for bash-level error capture
# Usage: Called by ERR trap, not invoked directly
# Args: exit_code, line_no, failed_command, command_name, workflow_id, user_args
# Effect: Logs bash error to centralized error log before exit
_log_bash_error() {
  local exit_code=$1
  local line_no=$2
  local failed_command=$3
  local command_name=$4
  local workflow_id=$5
  local user_args=$6

  # Check suppression flag for expected validation failures
  # This prevents cascading ERR trap logging for legitimate validation errors
  # that are already logged by library functions (e.g., state_error, validation_error)
  if [[ "${SUPPRESS_ERR_TRAP:-0}" == "1" ]]; then
    SUPPRESS_ERR_TRAP=0  # Auto-reset flag to prevent suppressing subsequent real errors
    return 0  # Return without logging or exiting
  fi

  # Skip error logging for test framework contexts
  # Prevents false positive errors from intentional test failures
  if is_test_context; then
    [ "${DEBUG:-0}" = "1" ] && echo "DEBUG: Skipping error log (test context detected)" >&2
    exit $exit_code
  fi

  # Mark that we've logged this error to prevent duplicate logging from EXIT trap
  _BASH_ERROR_LOGGED=1

  # Filter benign errors (system initialization failures that aren't actionable)
  if _is_benign_bash_error "$failed_command" "$exit_code"; then
    # Exit without logging - these are expected in some environments (e.g., NixOS)
    exit $exit_code
  fi

  # Determine error type from exit code
  local error_type="execution_error"
  case $exit_code in
    2) error_type="parse_error" ;;      # Bash syntax error
    127) error_type="execution_error" ;; # Command not found
  esac

  # Log to centralized error log
  log_command_error \
    "$command_name" \
    "$workflow_id" \
    "$user_args" \
    "$error_type" \
    "Bash error at line $line_no: exit code $exit_code" \
    "bash_trap" \
    "$(jq -n --argjson line "$line_no" --argjson code "$exit_code" --arg cmd "$failed_command" \
       '{line: $line, exit_code: $code, command: $cmd}')"

  exit $exit_code
}

# _log_bash_exit: Internal EXIT trap handler for errors not caught by ERR trap
# Usage: Called by EXIT trap, not invoked directly
# Args: Same as _log_bash_error, captured from trap context
# Effect: Logs bash errors that don't trigger ERR (e.g., unbound variables with set -u)
_log_bash_exit() {
  local exit_code=$?
  local line_no=$1
  local failed_command=$2
  local command_name=$3
  local workflow_id=$4
  local user_args=$5

  # Only log if error occurred AND not already logged by ERR trap
  if [ $exit_code -ne 0 ] && [ -z "${_BASH_ERROR_LOGGED:-}" ]; then
    # Skip error logging for test framework contexts
    # Prevents false positive errors from intentional test failures
    if is_test_context; then
      [ "${DEBUG:-0}" = "1" ] && echo "DEBUG: Skipping error log (test context detected)" >&2
      return
    fi

    # Filter benign errors (system initialization failures that aren't actionable)
    if _is_benign_bash_error "$failed_command" "$exit_code"; then
      return  # Skip logging for benign errors
    fi

    # Determine error type from exit code
    local error_type="execution_error"
    case $exit_code in
      1) error_type="execution_error" ;;   # General error (includes unbound variables)
      2) error_type="parse_error" ;;       # Bash syntax error
      127) error_type="execution_error" ;; # Command not found
    esac

    # Log to centralized error log
    log_command_error \
      "$command_name" \
      "$workflow_id" \
      "$user_args" \
      "$error_type" \
      "Bash error at line $line_no: exit code $exit_code" \
      "bash_trap" \
      "$(jq -n --argjson line "$line_no" --argjson code "$exit_code" --arg cmd "$failed_command" \
         '{line: $line, exit_code: $code, command: $cmd}')"
  fi
}

# setup_bash_error_trap: Register ERR and EXIT traps for bash-level error capture
# Usage: setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
# Effect: Registers ERR trap (for command failures) and EXIT trap (for unbound variables, set -u violations)
# Context: Must be called after sourcing error-handling.sh and initializing error log
# Note: Uses both ERR and EXIT traps to catch all error types - ERR for command failures, EXIT for set -u violations
setup_bash_error_trap() {
  local cmd_name="${1:-/unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"

  # ERR trap: Catches command failures (exit code 127, etc.) - logs and exits
  trap '_log_bash_error $? $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' ERR

  # EXIT trap: Catches errors that don't trigger ERR (e.g., unbound variables with set -u) - logs only if error not already logged
  trap '_log_bash_exit $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' EXIT
}

  export -f retry_with_backoff
  export -f retry_with_timeout
  export -f retry_with_fallback
  export -f log_error_context
  export -f log_command_error
  export -f parse_subagent_error
  export -f rotate_error_log
  export -f ensure_error_log_exists
  export -f log_early_error
  export -f validate_state_restoration
  export -f check_unbound_vars
# ==============================================================================
# Agent Output Validation
# ==============================================================================

# Validate agent created expected output file
# Usage: validate_agent_output <agent_name> <expected_file> [timeout_seconds]
# Returns: 0 if file exists and non-empty, 1 otherwise
validate_agent_output() {
  local agent_name="$1"
  local expected_file="$2"
  local timeout_seconds="${3:-5}"

  local elapsed=0
  while [ $elapsed -lt $timeout_seconds ]; do
    if [ -f "$expected_file" ] && [ -s "$expected_file" ]; then
      return 0  # Success: file exists and non-empty
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  # Timeout: file not created
  log_command_error \
    "${COMMAND_NAME:-/unknown}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "agent_error" \
    "Agent $agent_name did not create output file within ${timeout_seconds}s" \
    "validate_agent_output" \
    "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" '{agent: $agent, expected_file: $file}')"

  return 1
}

# Enhanced agent output validation with retry logic
# Usage: validate_agent_output_with_retry <agent_name> <expected_file> <format_validator> [timeout] [retries]
# Returns: 0 if file exists and passes validation, 1 otherwise
validate_agent_output_with_retry() {
  local agent_name="$1"
  local expected_file="$2"
  local format_validator="$3"  # Function name or "none"
  local timeout_seconds="${4:-5}"
  local max_retries="${5:-3}"

  # Track total execution time for diagnostics
  local start_time=$(date +%s)

  for retry in $(seq 1 $max_retries); do
    local elapsed=0
    while [ $elapsed -lt $timeout_seconds ]; do
      if [ -f "$expected_file" ] && [ -s "$expected_file" ]; then
        # File exists and non-empty, validate format if validator provided
        if [ "$format_validator" != "none" ]; then
          if $format_validator "$expected_file"; then
            return 0  # Success: file exists and passes validation
          else
            # Get file size for diagnostics
            local file_size=$(stat -c%s "$expected_file" 2>/dev/null || stat -f%z "$expected_file" 2>/dev/null || echo 0)
            local execution_time=$(($(date +%s) - start_time))

            log_command_error \
              "${COMMAND_NAME:-/unknown}" \
              "${WORKFLOW_ID:-unknown}" \
              "${USER_ARGS:-}" \
              "validation_error" \
              "Agent $agent_name output file failed format validation (retry $retry/$max_retries)" \
              "validate_agent_output_with_retry" \
              "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retry "$retry" \
                --argjson file_size "$file_size" --argjson exec_time "$execution_time" \
                '{agent: $agent, output_file: $file, retry: $retry, file_size_bytes: $file_size, execution_time_seconds: $exec_time}')"

            # Remove invalid file before retry
            rm -f "$expected_file" 2>/dev/null
            break  # Exit timeout loop, proceed to next retry
          fi
        else
          return 0  # Success: file exists, no format validation required
        fi
      fi
      sleep 0.5
      elapsed=$((elapsed + 1))
    done

    # If not last retry, sleep before next attempt
    if [ $retry -lt $max_retries ]; then
      sleep $((retry * 2))  # Exponential backoff: 2s, 4s, 6s
    fi
  done

  # All retries exhausted: file not created or validation failed
  local execution_time=$(($(date +%s) - start_time))
  local file_exists="false"
  local file_size=0

  if [ -f "$expected_file" ]; then
    file_exists="true"
    file_size=$(stat -c%s "$expected_file" 2>/dev/null || stat -f%z "$expected_file" 2>/dev/null || echo 0)
  fi

  log_command_error \
    "${COMMAND_NAME:-/unknown}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "agent_error" \
    "Agent $agent_name did not create valid output file after $max_retries attempts" \
    "validate_agent_output_with_retry" \
    "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retries "$max_retries" \
      --arg file_exists "$file_exists" --argjson file_size "$file_size" --argjson exec_time "$execution_time" \
      '{agent: $agent, expected_file: $file, retries: $retries, file_exists: $file_exists, file_size_bytes: $file_size, execution_time_seconds: $exec_time}')"

  return 1
}

# Topic name format validator
validate_topic_name_format() {
  local file="$1"
  local topic_name=$(cat "$file" 2>/dev/null | tr -d '\n' | tr -d ' ')

  # Validate format: lowercase alphanumeric + underscore, 5-40 chars
  if echo "$topic_name" | grep -Eq '^[a-z0-9_]{5,40}$'; then
    return 0
  fi

  return 1
}

  export -f _buffer_early_error
  export -f _flush_early_errors
  export -f _setup_defensive_trap
  export -f _clear_defensive_trap
  export -f _source_with_diagnostics
  export -f query_errors
  export -f recent_errors
  export -f error_summary
  export -f update_error_status
  export -f mark_errors_fix_planned
  export -f mark_errors_resolved_for_plan
  export -f escalate_to_user
  export -f escalate_to_user_parallel
  export -f try_with_fallback
  export -f format_error_report
  export -f handle_partial_failure
  export -f cleanup_on_error
  export -f format_orchestrate_agent_failure
  export -f format_orchestrate_test_failure
  export -f format_orchestrate_phase_context
  export -f handle_state_error
  export -f setup_bash_error_trap
  export -f _log_bash_exit
  export -f _log_bash_error
  export -f _is_benign_bash_error
  export -f validate_agent_output
  export -f validate_agent_output_with_retry
  export -f validate_topic_name_format
fi
