#!/usr/bin/env bash
# Shared error handling and recovery utilities
# Provides functions for error classification, recovery, and escalation

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

# ==============================================================================
# Error Logging
# ==============================================================================

# Error log directory
readonly ERROR_LOG_DIR="${CLAUDE_PROJECT_DIR}/.claude/logs"

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
# Validation Helpers
# ==============================================================================

# check_required_tool: Check if required tool is available
# Usage: check_required_tool <tool-name> [install-suggestion]
# Returns: 0 if available, 1 if missing
# Example: check_required_tool "jq" "sudo apt install jq"
check_required_tool() {
  local tool_name="${1:-}"
  local install_suggestion="${2:-}"

  if ! command -v "$tool_name" &> /dev/null; then
    echo "Error: Required tool not found: $tool_name" >&2
    if [ -n "$install_suggestion" ]; then
      echo "Install with: $install_suggestion" >&2
    fi
    return 1
  fi

  return 0
}

# check_file_writable: Check if file/directory is writable
# Usage: check_file_writable <path>
# Returns: 0 if writable, 1 if not
# Example: check_file_writable "/protected/dir/file.txt"
check_file_writable() {
  local path="${1:-}"

  if [ -z "$path" ]; then
    echo "Error: No path provided" >&2
    return 1
  fi

  # Check if path exists
  if [ -e "$path" ]; then
    # Check if writable
    if [ -w "$path" ]; then
      return 0
    else
      echo "Error: Path not writable: $path" >&2
      return 1
    fi
  else
    # Check if parent directory is writable
    local parent_dir=$(dirname "$path")
    if [ -w "$parent_dir" ]; then
      return 0
    else
      echo "Error: Parent directory not writable: $parent_dir" >&2
      return 1
    fi
  fi
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
# Detailed Error Analysis (merged from analyze-error.sh)
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

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f classify_error
  export -f suggest_recovery
  export -f retry_with_backoff
  export -f log_error_context
  export -f escalate_to_user
  export -f try_with_fallback
  export -f format_error_report
  export -f check_required_tool
  export -f check_file_writable
  export -f cleanup_on_error
  export -f detect_error_type
  export -f extract_location
  export -f generate_suggestions
fi
