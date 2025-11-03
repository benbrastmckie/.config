#!/usr/bin/env bash
# verification-helpers.sh - Concise verification patterns for orchestration commands
#
# PURPOSE:
#   Provides standardized file verification functions with concise success reporting
#   and detailed failure diagnostics. Achieves 90% token reduction at checkpoints
#   by emitting single-character success indicators (✓) and verbose diagnostics only
#   on failure.
#
# FUNCTIONS:
#   verify_file_created() - Verify file exists and has content
#
# USAGE EXAMPLE:
#   source .claude/lib/verification-helpers.sh
#   verify_file_created "/path/to/file.md" "Research report" "Phase 1"
#   # Success: ✓ (single character)
#   # Failure: Multi-line diagnostic with actionable commands
#
# INTEGRATION:
#   - Used by /supervise, /coordinate, and other orchestration commands
#   - Replaces verbose inline verification blocks (38+ lines → 1 line)
#   - Token reduction: ~3,150 tokens saved per workflow (14 checkpoints × 225 tokens)
#
# ARCHITECTURE:
#   - Success path: Minimal output (single character ✓)
#   - Failure path: Comprehensive diagnostics (file path, directory status, fix commands)
#   - Returns: 0 on success, 1 on failure (bash convention)

# verify_file_created - Verify file exists and contains content
#
# PARAMETERS:
#   $1 - file_path: Absolute path to file that should exist
#   $2 - item_desc: Human-readable description (e.g., "Research report")
#   $3 - phase_name: Phase identifier for error messages (e.g., "Phase 1")
#
# RETURNS:
#   0 - File exists and has content (success)
#   1 - File missing or empty (failure)
#
# OUTPUT:
#   Success: "✓" (single character, no newline)
#   Failure: Multi-line diagnostic with:
#     - Error header with phase and description
#     - Expected vs found status
#     - Directory diagnostic (exists, file count, recent files)
#     - Actionable fix commands
#
# EXAMPLES:
#   # Success case
#   verify_file_created "$REPORT_PATH" "Research report" "Phase 1"
#   # Output: ✓
#   # Return: 0
#
#   # Failure case (missing file)
#   verify_file_created "/missing/file.md" "Test file" "Phase 2"
#   # Output: (38-line diagnostic)
#   # Return: 1
#
#   # Usage in workflow
#   if verify_file_created "$PLAN_PATH" "Implementation plan" "Phase 2"; then
#     echo " Plan verified"
#     proceed_to_phase_3
#   else
#     echo "ERROR: Plan verification failed"
#     exit 1
#   fi
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  # Success path: Single character output
  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # No newline - allows multiple checks on one line
    return 0
  else
    # Failure path: Verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo "   Expected: File exists at $file_path"

    # Specific failure reason
    if [ ! -f "$file_path" ]; then
      echo "   Found: File does not exist"
    else
      echo "   Found: File empty (0 bytes)"
    fi
    echo ""

    # Directory diagnostics
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $file_path"
    echo "  - Parent directory: $(dirname "$file_path")"

    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      local file_count
      file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
      echo "  - Directory status: ✓ Exists ($file_count files)"

      # Show recent files if directory not empty
      if [ "$file_count" -gt 0 ]; then
        echo "  - Recent files:"
        ls -lht "$dir" | head -4
      fi
    else
      echo "  - Directory status: ✗ Does not exist"
      echo "  - Fix: mkdir -p $dir"
    fi
    echo ""

    # Actionable diagnostic commands
    echo "Diagnostic commands:"
    echo "  ls -la $dir"
    echo "  cat .claude/agents/[agent-name].md | head -50"
    echo ""

    return 1
  fi
}

# Export function for use in subshells
export -f verify_file_created
