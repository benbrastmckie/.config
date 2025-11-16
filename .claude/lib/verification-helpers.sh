#!/usr/bin/env bash
# verification-helpers.sh - Concise verification patterns for orchestration commands
#
# PURPOSE:
#   Provides standardized file verification functions with concise success reporting
#   and detailed failure diagnostics. Achieves 90% token reduction at checkpoints
#   by emitting single-character success indicators (✓) and verbose diagnostics only
#   on failure.
#
# Source guard: Prevent multiple sourcing
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1
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
    # Failure path: Enhanced verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo ""

    # Expected vs Actual comparison
    echo "Expected vs Actual:"
    echo "  Expected path: $file_path"
    local expected_filename=$(basename "$file_path")
    echo "  Expected filename: $expected_filename"
    echo ""

    # Specific failure reason
    if [ ! -f "$file_path" ]; then
      echo "  Status: File does not exist"
    else
      echo "  Status: File empty (0 bytes)"
    fi
    echo ""

    # Enhanced directory diagnostics with file metadata
    local dir="$(dirname "$file_path")"
    echo "Directory Analysis:"
    echo "  Parent directory: $dir"

    if [ -d "$dir" ]; then
      local file_count
      file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
      echo "  Directory status: ✓ Exists ($file_count files)"
      echo ""

      # Show actual files with metadata for mismatch diagnosis
      if [ "$file_count" -gt 0 ]; then
        echo "  Files found in directory:"
        ls -lht "$dir" | head -6 | tail -n +2 | while IFS= read -r line; do
          # Extract filename from ls output
          local filename=$(echo "$line" | awk '{print $NF}')
          local size=$(echo "$line" | awk '{print $5}')
          local date=$(echo "$line" | awk '{print $6, $7, $8}')

          # Mark if filename matches expected pattern
          if [[ "$filename" == [0-9][0-9][0-9]_*.md ]]; then
            echo "     - $filename (size: $size, modified: $date)"
          else
            echo "     - $filename (size: $size, modified: $date) [unexpected pattern]"
          fi
        done
        echo ""

        # Root cause analysis for path mismatches
        echo "  Possible causes:"
        echo "    1. Agent created descriptive filename instead of generic name"
        echo "    2. Dynamic path discovery executed after verification"
        echo "    3. State persistence incomplete (REPORT_PATHS array not populated)"
        echo "    4. Topic path calculation mismatch"
      else
        echo "  Directory is empty"
        echo ""
        echo "  Possible causes:"
        echo "    1. Agent failed to create report file"
        echo "    2. Wrong topic directory calculated"
        echo "    3. Reports directory not initialized"
      fi
    else
      echo "  Directory status: ✗ Does not exist"
      echo ""
      echo "  Fix: mkdir -p $dir"
    fi
    echo ""

    # Enhanced troubleshooting commands with explanations
    echo "TROUBLESHOOTING:"
    echo "  1. List actual files created:"
    echo "     Command: ls -la $dir"
    echo ""
    echo "  2. Check agent completion signals:"
    echo "     Command: grep -r \"REPORT_CREATED:\" \"\${CLAUDE_PROJECT_DIR}/.claude/tmp/\""
    echo ""
    echo "  3. Verify dynamic discovery executed:"
    echo "     Command: grep -A 10 \"Dynamic Report Path Discovery\" \"\${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md\""
    echo ""
    echo "  4. Check REPORT_PATHS array contents:"
    echo "     Command: declare -p REPORT_PATHS 2>/dev/null || echo \"Array not set\""
    echo ""

    return 1
  fi
}

# Export function for use in subshells
export -f verify_file_created

# verify_state_variable - Verify single variable exists in state file
#
# PURPOSE:
#   Verifies that a single state variable exists in the workflow state file
#   with correct export format. Designed for use in verification checkpoints
#   after state initialization or modifications.
#
# PARAMETERS:
#   $1 - var_name: Variable name to verify (without $ prefix)
#
# RETURNS:
#   0 - Variable exists in state file with correct format (success)
#   1 - Variable missing or state file unavailable (failure)
#
# OUTPUT:
#   Success: Silent (no output)
#   Failure: Diagnostic message showing expected format and state file path
#
# IMPLEMENTATION:
#   Uses grep pattern '^export ${var_name}=' matching state-persistence.sh format.
#   Requires STATE_FILE variable to be set (should be loaded via load_workflow_state()).
#
# USAGE EXAMPLES:
#   # Example 1: Verify WORKFLOW_SCOPE after sm_init
#   verify_state_variable "WORKFLOW_SCOPE" || exit 1
#
#   # Example 2: Verify REPORT_PATHS_COUNT after array export
#   verify_state_variable "REPORT_PATHS_COUNT" || {
#     echo "CRITICAL: REPORT_PATHS_COUNT not persisted to state"
#     exit 1
#   }
#
#   # Example 3: Verify EXISTING_PLAN_PATH for research-and-revise scope
#   if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
#     verify_state_variable "EXISTING_PLAN_PATH" || exit 1
#   fi
#
# STATE FILE FORMAT DEPENDENCY:
#   This function expects state file format from state-persistence.sh:
#     export VAR_NAME="value"
#
#   The grep pattern '^export ${var_name}=' matches this exact format.
#   Changes to state file format require updating this pattern.
#
# RELATED:
#   - Spec 644: Unbound variable bug from incorrect grep pattern
#   - verify_state_variables(): Multi-variable verification (below)
#   - state-persistence.sh: Defines state file format
verify_state_variable() {
  local var_name="$1"

  # Defensive check: STATE_FILE must be set
  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR [verify_state_variable]: STATE_FILE not set"
    echo "  Variable to verify: $var_name"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Ensure load_workflow_state() was called before verification"
    echo "  2. Check that STATE_FILE was exported in initialization block"
    echo "  3. Verify state persistence library is sourced"
    echo ""
    return 1
  fi

  # Defensive check: State file must exist
  if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR [verify_state_variable]: State file does not exist"
    echo "  Expected path: $STATE_FILE"
    echo "  Variable to verify: $var_name"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Verify init_workflow_state() was called in first bash block"
    echo "  2. Check workflow ID file exists and contains valid ID"
    echo "  3. Ensure no premature cleanup of state files"
    echo ""
    return 1
  fi

  # Main verification: Check for variable in state file with correct export format
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    return 0  # Success: Variable exists with correct format
  else
    # Failure: Variable missing or wrong format
    echo "ERROR [verify_state_variable]: Variable not found in state file"
    echo "  Variable name: $var_name"
    echo "  State file: $STATE_FILE"
    echo ""
    echo "EXPECTED FORMAT:"
    echo "  export ${var_name}=\"value\""
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Check append_workflow_state() was called for this variable:"
    echo "     append_workflow_state \"$var_name\" \"\${$var_name}\""
    echo ""
    echo "  2. Verify variable is set before append:"
    echo "     echo \"\${$var_name:-NOT SET}\""
    echo ""
    echo "  3. Check state file contents:"
    echo "     grep \"$var_name\" \"$STATE_FILE\""
    echo ""
    echo "  4. Verify export format (must start with 'export'):"
    echo "     grep \"^export\" \"$STATE_FILE\" | grep \"$var_name\""
    echo ""
    return 1
  fi
}

export -f verify_state_variable

# verify_state_variables - Verify multiple variables exist in state file
#
# PARAMETERS:
#   $1 - state_file: Path to workflow state file
#   $2+ - var_names: List of variable names to verify
#
# RETURNS:
#   0 - All variables present in state file (success)
#   1 - One or more variables missing (failure)
#
# OUTPUT:
#   Success: "✓" (single character)
#   Failure: Diagnostic listing missing variables
#
# EXAMPLE:
#   verify_state_variables "$STATE_FILE" REPORT_PATHS_COUNT REPORT_PATH_0 REPORT_PATH_1
#   # Success: ✓
#   # Failure: Lists which variables are missing
verify_state_variables() {
  local state_file="$1"
  shift
  local var_names=("$@")

  # Defensive check: Verify state file exists before grep operations
  if [ ! -f "$state_file" ]; then
    echo ""
    echo "✗ ERROR: State file does not exist"
    echo "   Expected path: $state_file"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Verify init_workflow_state() was called in first bash block"
    echo "  2. Check STATE_FILE variable was saved to state correctly"
    echo "  3. Verify workflow ID file exists and contains valid ID"
    echo "  4. Ensure no premature cleanup of state files"
    echo ""
    return 1
  fi

  local missing_vars=()

  # Check each variable
  for var_name in "${var_names[@]}"; do
    if ! grep -q "^export ${var_name}=" "$state_file" 2>/dev/null; then
      missing_vars+=("$var_name")
    fi
  done

  # Success path: All variables present
  if [ ${#missing_vars[@]} -eq 0 ]; then
    echo -n "✓"
    return 0
  else
    # Failure path: Report missing variables
    echo ""
    echo "✗ ERROR: State variable verification failed"
    echo "   Expected: ${#var_names[@]} variables in state file"
    echo "   Found: $((${#var_names[@]} - ${#missing_vars[@]})) variables"
    echo ""
    echo "MISSING VARIABLES:"
    for var in "${missing_vars[@]}"; do
      echo "  ❌ $var"
    done
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - State file: $state_file"
    if [ -f "$state_file" ]; then
      local file_size
      file_size=$(stat -f%z "$state_file" 2>/dev/null || stat -c%s "$state_file" 2>/dev/null || echo "unknown")
      echo "  - File size: $file_size bytes"
      echo "  - Variables in file: $(grep -c '^export ' "$state_file" 2>/dev/null || echo 0)"
    else
      echo "  - File status: MISSING"
    fi
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Check append_workflow_state() was called for each variable"
    echo "  2. Verify set +H directive present (prevents bad substitution)"
    echo "  3. Check file permissions on state file directory"
    echo ""
    echo "State file contents (first 20 lines):"
    head -20 "$state_file" 2>/dev/null || echo "  (unable to read state file)"
    echo ""
    return 1
  fi
}

export -f verify_state_variables

# verify_files_batch - Batch verify multiple files with concise success reporting
#
# PURPOSE:
#   Verifies multiple files exist and contain content, with single-line success
#   reporting and comprehensive diagnostics only on failure. Achieves improved
#   token efficiency compared to sequential verify_file_created() calls.
#
# PARAMETERS:
#   $1 - phase_name: Phase identifier for error messages (e.g., "Phase 1")
#   $2+ - file_entries: Space-separated pairs of "path:description"
#
# RETURNS:
#   0 - All files exist and have content (success)
#   1 - One or more files missing or empty (failure)
#
# OUTPUT:
#   Success: "✓ All N files verified" (single line)
#   Failure: Comprehensive diagnostics for each failed file
#
# EXAMPLES:
#   # Verify 2 research reports
#   verify_files_batch "Phase 1" \
#     "/path/to/report1.md:Research report 1" \
#     "/path/to/report2.md:Research report 2"
#   # Success: ✓ All 2 files verified
#   # Return: 0
#
#   # Failure case (one missing file)
#   verify_files_batch "Phase 1" \
#     "/path/to/existing.md:Existing file" \
#     "/path/to/missing.md:Missing file"
#   # Output: Multi-line diagnostic for missing.md
#   # Return: 1
#
#   # Usage in workflow
#   if verify_files_batch "Phase 1" "${FILE_ENTRIES[@]}"; then
#     echo ""  # Newline after success message
#     proceed_to_phase_2
#   else
#     echo "ERROR: File verification failed"
#     exit 1
#   fi
#
# TOKEN EFFICIENCY:
#   - Sequential verify_file_created(): ~50 tokens per file (N files = 50N tokens)
#   - Batch verification: ~30 tokens total (success) or ~50N tokens (failure)
#   - Net savings: ~20 tokens per file on success path
#   - Example: 5 files = 250 tokens → 30 tokens (88% reduction)
verify_files_batch() {
  local phase_name="$1"
  shift
  local file_entries=("$@")

  local total_count="${#file_entries[@]}"
  local success_count=0
  local failed_files=()
  local failed_descs=()

  # Verify each file
  for entry in "${file_entries[@]}"; do
    # Split entry into path and description (format: "path:description")
    local file_path="${entry%%:*}"
    local item_desc="${entry#*:}"

    if [ -f "$file_path" ] && [ -s "$file_path" ]; then
      ((success_count++))
    else
      failed_files+=("$file_path")
      failed_descs+=("$item_desc")
    fi
  done

  # Success path: All files verified
  if [ "$success_count" -eq "$total_count" ]; then
    echo -n "✓ All $total_count files verified"
    return 0
  else
    # Failure path: Report failures
    echo ""
    echo "✗ ERROR [$phase_name]: Batch file verification failed"
    echo ""
    echo "Summary:"
    echo "  Expected: $total_count files"
    echo "  Success: $success_count files"
    echo "  Failed: $((total_count - success_count)) files"
    echo ""

    # Report each failed file with diagnostics
    for i in "${!failed_files[@]}"; do
      local file_path="${failed_files[$i]}"
      local item_desc="${failed_descs[$i]}"

      echo "Failed file #$((i + 1)): $item_desc"
      echo "  Expected path: $file_path"
      echo "  Expected filename: $(basename "$file_path")"
      echo ""

      # Specific failure reason
      if [ ! -f "$file_path" ]; then
        echo "  Status: File does not exist"
      else
        echo "  Status: File empty (0 bytes)"
      fi
      echo ""

      # Directory diagnostics
      local dir="$(dirname "$file_path")"
      echo "  Parent directory: $dir"

      if [ -d "$dir" ]; then
        local file_count
        file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
        echo "  Directory status: ✓ Exists ($file_count files)"

        if [ "$file_count" -gt 0 ]; then
          echo "  Recent files:"
          ls -lt "$dir" | head -4 | tail -n +2 | awk '{print "    - " $NF " (" $5 " bytes)"}'
        fi
      else
        echo "  Directory status: ✗ Does not exist"
        echo "  Fix: mkdir -p $dir"
      fi
      echo ""
    done

    # Consolidated troubleshooting
    echo "TROUBLESHOOTING:"
    echo "  1. List files in parent directory:"
    echo "     ls -la $(dirname "${failed_files[0]}")"
    echo ""
    echo "  2. Check agent completion signals:"
    echo "     grep -r \"CREATED:\" \"\${CLAUDE_PROJECT_DIR}/.claude/tmp/\""
    echo ""
    echo "  3. Verify state persistence:"
    echo "     declare -p REPORT_PATHS 2>/dev/null || echo \"Array not set\""
    echo ""

    return 1
  fi
}

export -f verify_files_batch
