#!/usr/bin/env bash
# Analyze errors and generate fix suggestions
# Usage: analyze-error.sh <error-output> [context-file]

set -euo pipefail

ERROR_OUTPUT="${1:-}"
CONTEXT_FILE="${2:-}"

if [ -z "$ERROR_OUTPUT" ]; then
  echo "Usage: analyze-error.sh <error-output> [context-file]" >&2
  exit 1
fi

# Error type detection patterns
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

# Extract file location from error (file:line format)
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

# Generate suggestions based on error type
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

# Main analysis
ERROR_TYPE=$(detect_error_type "$ERROR_OUTPUT")
LOCATION=$(extract_location "$ERROR_OUTPUT")

# Output enhanced error message
echo "==============================================="
echo "Enhanced Error Analysis"
echo "==============================================="
echo ""
echo "Error Type: $ERROR_TYPE"
if [ -n "$LOCATION" ]; then
  echo "Location: $LOCATION"

  # If file exists, show context
  FILE_PATH=$(echo "$LOCATION" | cut -d: -f1)
  LINE_NUM=$(echo "$LOCATION" | cut -d: -f2)

  if [ -f "$FILE_PATH" ] && [ -n "$LINE_NUM" ]; then
    echo ""
    echo "Context (around line $LINE_NUM):"
    echo "---"
    # Show 3 lines before and after
    sed -n "$((LINE_NUM - 3)),$((LINE_NUM + 3))p" "$FILE_PATH" | nl -ba -v $((LINE_NUM - 3))
    echo "---"
  fi
fi

echo ""
generate_suggestions "$ERROR_TYPE" "$ERROR_OUTPUT" "$LOCATION"

echo ""
echo "Debug Commands:"
echo "- Investigate further: /debug \"<description of error>\""
if [ -n "$LOCATION" ]; then
  FILE_PATH=$(echo "$LOCATION" | cut -d: -f1)
  if [ -f "$FILE_PATH" ]; then
    echo "- View file: nvim $FILE_PATH"
  fi
fi
echo "- Run tests: :TestNearest or :TestFile"
echo ""
echo "==============================================="
