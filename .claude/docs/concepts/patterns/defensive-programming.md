# Defensive Programming Patterns

**Path**: docs → concepts → patterns → defensive-programming.md

[Used by: /implement, /plan, all command and agent development]

Consolidated defensive programming patterns for building reliable, maintainable code that handles errors gracefully and prevents common failure modes.

## Purpose

This document consolidates scattered defensive programming guidance into a unified reference with clear examples and validation methods. These patterns prevent 90%+ of runtime failures through proactive error prevention rather than reactive error handling.

## 1. Input Validation

**Pattern**: Validate all inputs before use, especially file paths, environment variables, and user-provided arguments.

### Absolute Path Verification

Commands and agents must use absolute paths to avoid directory-dependent failures.

**Example - Path Validation**:
```bash
# ❌ BAD - Relative path, directory-dependent
PLAN_FILE="specs/plans/001_plan.md"
source lib/utils.sh

# ✅ GOOD - Absolute path, directory-independent
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLAN_FILE="$CLAUDE_PROJECT_DIR/.claude/specs/plans/001_plan.md"
source "$CLAUDE_PROJECT_DIR/.claude/lib/utils.sh"
```

**Example - Environment Variable Validation**:
```bash
# ❌ BAD - No validation, fails silently if unset
cd "$CLAUDE_PROJECT_DIR"

# ✅ GOOD - Validate before use
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  echo "ERROR: CLAUDE_PROJECT_DIR not set"
  exit 1
fi
cd "$CLAUDE_PROJECT_DIR"
```

**Example - Argument Validation**:
```bash
# ❌ BAD - No validation, undefined behavior if missing
process_file "$1"

# ✅ GOOD - Validate arguments exist
if [ $# -eq 0 ]; then
  echo "ERROR: Missing required argument: file_path"
  echo "Usage: $0 <file_path>"
  exit 1
fi
process_file "$1"
```

**When to Apply**:
- All file path operations
- All environment variable usage
- All user-provided arguments
- All library function parameters

**Validation**:
```bash
# Verify absolute path usage
grep -q "CLAUDE_PROJECT_DIR" script.sh

# Verify environment variable validation
grep -q "if \[ -z.*CLAUDE_PROJECT_DIR" script.sh

# Verify argument validation
grep -q "if \[ \$# " script.sh
```

**Cross-References**:
- [Code Standards](../../reference/standards/code-standards.md) → Standard 13 (Absolute Paths)
- [Robustness Framework](../robustness-framework.md) → Pattern 6 (Absolute Paths)

## 2. Null Safety

**Pattern**: Guard against null/empty values with explicit checks before dereferencing or using values.

### Nil Guards

**Example - Variable Existence Check**:
```bash
# ❌ BAD - No nil guard, crashes if variable unset
file_count=${#files[@]}

# ✅ GOOD - Nil guard before array access
if [ -z "${files+x}" ]; then
  echo "WARNING: files array not initialized"
  files=()
fi
file_count=${#files[@]}
```

**Example - File Existence Check**:
```bash
# ❌ BAD - No existence check, fails if file missing
content=$(cat "$file_path")

# ✅ GOOD - Existence check before read
if [ ! -f "$file_path" ]; then
  echo "ERROR: File not found: $file_path"
  return 1
fi
content=$(cat "$file_path")
```

### Optional/Maybe Patterns

**Example - Optional Return Values**:
```bash
# Function with optional return
find_config_file() {
  local config_path="$1/.config"

  if [ -f "$config_path" ]; then
    echo "$config_path"
    return 0
  else
    # Return empty string, signal with exit code
    echo ""
    return 1
  fi
}

# Caller handles optional value
if config_file=$(find_config_file "$HOME"); then
  source "$config_file"
else
  echo "INFO: No config file found, using defaults"
fi
```

**When to Apply**:
- Before accessing array elements
- Before reading files
- When calling functions that may return empty
- When processing user input

**Validation**:
```bash
# Verify file existence checks
grep -q "if \[ ! -f.*\]; then" script.sh

# Verify variable initialization checks
grep -q "if \[ -z.*+x.*\]; then" script.sh
```

**Cross-References**:
- [Error Enhancement Guide](../../guides/patterns/error-enhancement-guide.md) → Section on Null Handling
- [Robustness Framework](../robustness-framework.md) → Pattern 7 (Error Context)

## 3. Return Code Verification

**Pattern**: Check return codes of critical function calls and commands before proceeding.

### Critical Function Return Checking

**Example - Library Function Verification**:
```bash
# ❌ BAD - Ignores return code, continues on failure
create_topic_artifact "$topic_dir" "reports" "$topic" ""
REPORT_PATH=$CREATED_ARTIFACT_PATH

# ✅ GOOD - Verifies return code, handles failure
if ! create_topic_artifact "$topic_dir" "reports" "$topic" ""; then
  echo "ERROR: Failed to create artifact for topic: $topic"
  echo "WHICH: create_topic_artifact"
  echo "WHAT: Artifact creation failed"
  echo "WHERE: Report generation phase"
  return 1
fi
REPORT_PATH=$CREATED_ARTIFACT_PATH
```

**Example - Command Verification**:
```bash
# ❌ BAD - No verification, silent failure
mkdir "$output_dir"
cp files/* "$output_dir/"

# ✅ GOOD - Verify each critical step
if ! mkdir -p "$output_dir"; then
  echo "ERROR: Failed to create output directory: $output_dir"
  return 1
fi

if ! cp files/* "$output_dir/"; then
  echo "ERROR: Failed to copy files to: $output_dir"
  return 1
fi
```

**Example - Pipeline Verification**:
```bash
# ❌ BAD - Only checks final command in pipeline
result=$(complex_command | filter | process)

# ✅ GOOD - Use pipefail to catch failures in pipeline
set -o pipefail
if ! result=$(complex_command | filter | process); then
  echo "ERROR: Pipeline failed"
  return 1
fi
```

**When to Apply**:
- After library function calls
- After critical bash commands (mkdir, cp, mv, rm)
- In command pipelines
- When setting variables from command output

**Validation**:
```bash
# Verify return code checks
grep -q "if ! " script.sh

# Verify pipefail usage
grep -q "set -o pipefail" script.sh
```

**Cross-References**:
- [Code Standards](../../reference/standards/code-standards.md) → Standard 16 (Return Code Verification)
- [Library API Reference](../../reference/library-api/overview.md) → Return Value Documentation

## 4. Idempotent Operations

**Pattern**: Design operations that can be safely executed multiple times without changing the result beyond the initial application.

### Directory Creation

**Example - Idempotent mkdir**:
```bash
# ❌ BAD - Fails on second execution
mkdir "$output_dir"

# ✅ GOOD - Idempotent with -p flag
mkdir -p "$output_dir"
```

### File Operations

**Example - Idempotent File Write**:
```bash
# ❌ BAD - Appends on each execution, grows indefinitely
echo "export PATH=\$PATH:/custom/bin" >> ~/.bashrc

# ✅ GOOD - Check before adding, idempotent
if ! grep -q "/custom/bin" ~/.bashrc; then
  echo "export PATH=\$PATH:/custom/bin" >> ~/.bashrc
fi
```

**Example - Idempotent Configuration**:
```bash
# ❌ BAD - Creates duplicate entries
git config --global user.name "Claude"

# ✅ GOOD - Set operation is idempotent
git config --global user.name "Claude"  # Overwrites, doesn't duplicate
```

### Library Sourcing

**Example - Idempotent Source**:
```bash
# ❌ BAD - No guard, functions redefined on each source
source "$UTILS_DIR/helpers.sh"

# ✅ GOOD - Guard prevents duplicate sourcing
if [ -z "${HELPERS_SOURCED+x}" ]; then
  source "$UTILS_DIR/helpers.sh"
  HELPERS_SOURCED=1
fi
```

**When to Apply**:
- Directory creation operations
- Configuration file modifications
- Library sourcing
- State initialization
- Resumable workflows

**Validation**:
```bash
# Verify idempotent directory creation
grep -q "mkdir -p" script.sh

# Verify conditional file operations
grep -q "if ! grep -q.*then" script.sh

# Verify source guards
grep -q "if \[ -z.*_SOURCED.*\]; then" script.sh
```

**Cross-References**:
- [Robustness Framework](../robustness-framework.md) → Pattern 8 (Idempotent Operations)
- [Command Development Guide](../../guides/development/command-development/command-development-fundamentals.md) → Resumable Workflows

## 5. Error Context

**Pattern**: Structure error messages with WHICH operation, WHAT failed, and WHERE it occurred.

### Structured Error Messages

**Example - Error with Context**:
```bash
# ❌ BAD - Vague error, no context
echo "Error: operation failed"

# ✅ GOOD - Structured error with WHICH/WHAT/WHERE
echo "ERROR: Failed to create report file"
echo "WHICH: create_topic_artifact"
echo "WHAT: File creation failed - permission denied"
echo "WHERE: Phase 2, report generation for topic '$topic'"
echo "PATH: $REPORT_PATH"
```

**Example - Error with Troubleshooting**:
```bash
# ❌ BAD - Error without guidance
echo "File not found: $config_file"
exit 1

# ✅ GOOD - Error with troubleshooting steps
echo "ERROR: Configuration file not found"
echo "WHICH: Configuration loading"
echo "WHAT: File does not exist at expected path"
echo "WHERE: Initialization phase"
echo "PATH: $config_file"
echo ""
echo "TROUBLESHOOTING:"
echo "1. Verify CLAUDE_PROJECT_DIR is set correctly: $CLAUDE_PROJECT_DIR"
echo "2. Run /setup to create default configuration"
echo "3. Check file permissions in parent directory"
exit 1
```

### Error Enhancement

**Example - Enhanced Error Diagnostics**:
```bash
# ❌ BAD - Raw command error, no enhancement
cp "$source" "$dest"

# ✅ GOOD - Enhanced error with diagnostics
if ! cp "$source" "$dest" 2>&1; then
  echo "ERROR: Failed to copy file"
  echo "WHICH: File copy operation"
  echo "WHAT: cp command failed"
  echo "WHERE: Artifact preparation phase"
  echo "SOURCE: $source (exists: $([ -f "$source" ] && echo yes || echo no))"
  echo "DEST: $dest (dir exists: $([ -d "$(dirname "$dest")" ] && echo yes || echo no))"
  exit 1
fi
```

**When to Apply**:
- All error messages
- All validation failures
- All command failures
- All agent failures

**Validation**:
```bash
# Verify structured error format
grep -q "ERROR:.*WHICH:.*WHAT:.*WHERE:" script.sh

# Verify error includes context
grep "ERROR:" script.sh | grep -q "Phase\|Step"
```

**Cross-References**:
- [Error Enhancement Guide](../../guides/patterns/error-enhancement-guide.md) → Complete error patterns
- [Robustness Framework](../robustness-framework.md) → Pattern 7 (Error Context)

## 6. Grep Output Sanitization

**Pattern**: Sanitize grep output before using in bash conditionals to prevent syntax errors from embedded newlines or non-numeric corruption.

### The Problem

`grep -c` output can contain embedded newlines (e.g., `"0\n0"`) due to grep bugs or filesystem issues, causing bash conditional syntax errors when the variable is used in comparisons:

```bash
# ❌ BAD - Vulnerable to grep output corruption
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
if [[ "$TOTAL_PHASES" -eq 3 ]]; then  # FAILS if TOTAL_PHASES="0\n0"
  echo "All phases found"
fi
# Error: [[: 0\n0: syntax error in expression
```

### The 4-Step Sanitization Pattern

Apply this defensive pattern to all grep-based numeric variables used in conditionals:

```bash
# ✅ GOOD - Apply 4-step sanitization pattern
# Step 1: Execute grep -c with fallback
COUNT=$(grep -c "pattern" "$FILE" 2>/dev/null || echo "0")

# Step 2: Strip newlines and spaces
COUNT=$(echo "$COUNT" | tr -d '\n' | tr -d ' ')

# Step 3: Apply default if empty
COUNT=${COUNT:-0}

# Step 4: Validate numeric and reset if invalid
[[ "$COUNT" =~ ^[0-9]+$ ]] || COUNT=0
```

### Real-World Examples

**Example - Phase Counting in implement.md**:
```bash
# Count total phases with defensive sanitization
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
TOTAL_PHASES=$(echo "$TOTAL_PHASES" | tr -d '\n' | tr -d ' ')
TOTAL_PHASES=${TOTAL_PHASES:-0}
[[ "$TOTAL_PHASES" =~ ^[0-9]+$ ]] || TOTAL_PHASES=0

# Count complete phases with defensive sanitization
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(echo "$PHASES_WITH_MARKER" | tr -d '\n' | tr -d ' ')
PHASES_WITH_MARKER=${PHASES_WITH_MARKER:-0}
[[ "$PHASES_WITH_MARKER" =~ ^[0-9]+$ ]] || PHASES_WITH_MARKER=0

# Now safe to use in conditionals
if [ "$TOTAL_PHASES" -eq 0 ]; then
  echo "No phases found"
elif [ "$PHASES_WITH_MARKER" -eq "$TOTAL_PHASES" ]; then
  echo "All phases complete"
fi
```

**Example - Function Return Value**:
```bash
check_all_phases_complete() {
  local plan_path="$1"

  # Count total phases with defensive sanitization
  local total_phases=$(grep -E -c "^##+ Phase [0-9]" "$plan_path" 2>/dev/null || echo "0")
  total_phases=$(echo "$total_phases" | tr -d '\n' | tr -d ' ')
  total_phases=${total_phases:-0}
  [[ "$total_phases" =~ ^[0-9]+$ ]] || total_phases=0

  # Count complete phases with defensive sanitization
  local complete_phases=$(grep -E -c "^##+ Phase [0-9].*\[COMPLETE\]" "$plan_path" 2>/dev/null || echo "0")
  complete_phases=$(echo "$complete_phases" | tr -d '\n' | tr -d ' ')
  complete_phases=${complete_phases:-0}
  [[ "$complete_phases" =~ ^[0-9]+$ ]] || complete_phases=0

  # Safe conditional comparison
  if [[ "$complete_phases" -eq "$total_phases" ]]; then
    return 0
  else
    return 1
  fi
}
```

### Why Each Step Is Necessary

1. **Fallback (`|| echo "0"`)**: Handles grep failures (file not found, permission denied)
2. **Strip newlines/spaces (`tr -d '\n' | tr -d ' '`)**: Removes embedded newlines that cause syntax errors
3. **Default value (`${COUNT:-0}`)**: Handles empty strings from tr if input was only whitespace
4. **Regex validation (`[[ "$COUNT" =~ ^[0-9]+$ ]]`)**: Catches non-numeric corruption (e.g., "error", "grep:")

### Edge Cases Handled

| Input | After Step 2 | After Step 3 | After Step 4 | Notes |
|-------|--------------|--------------|--------------|-------|
| `"3"` | `"3"` | `"3"` | `"3"` | Normal case |
| `"0\n0"` | `"00"` | `"00"` | `"00"` | Newline corruption → numeric |
| `"3\n0"` | `"30"` | `"30"` | `"30"` | Newline corruption → numeric |
| `" 5 "` | `"5"` | `"5"` | `"5"` | Whitespace stripped |
| `""` | `""` | `"0"` | `"0"` | Empty → default |
| `"error"` | `"error"` | `"error"` | `"0"` | Non-numeric → reset |
| `"grep: file"` | `"grep:file"` | `"grep:file"` | `"0"` | Error message → reset |

### When to Apply

**Required**:
- All grep -c output used in bash conditionals (`if`, `while`, `[[ ]]`, `[ ]`)
- All numeric variables derived from command output used in arithmetic
- All count variables used in comparisons

**Not Required**:
- grep output used only for display (echo, log messages)
- grep -c output immediately compared with grep -q result
- Variables used only in string operations (not arithmetic)

### Validation

```bash
# Find vulnerable grep -c usage (missing sanitization)
grep -n 'grep.*-c' script.sh | while read line; do
  var_name=$(echo "$line" | sed -n 's/.*\([A-Z_]*\)=\$(grep.*/\1/p')
  if ! grep -q "$var_name=.*tr -d" script.sh; then
    echo "WARNING: $var_name on line $line needs sanitization"
  fi
done

# Verify sanitization pattern applied correctly
grep -A 4 'grep -c' script.sh | grep -q 'tr -d.*tr -d.*:-0.*=~'
```

### Reference Implementation

The canonical reference implementation is in `complexity-utils.sh` (lines 55-72), which sanitizes `task_count`, `file_count`, and `code_blocks` variables:

```bash
# Reference from complexity-utils.sh
local task_count
task_count=$(echo "$phase_content" | grep -c "^- \[ \]" 2>/dev/null || echo "0")
task_count=$(echo "$task_count" | tr -d '\n' | tr -d ' ')
task_count=${task_count:-0}
[[ "$task_count" =~ ^[0-9]+$ ]] || task_count=0
```

**When to Apply**:
- All grep -c output used in conditionals
- All numeric variables from external commands
- All count operations that feed into comparisons
- Before any arithmetic operations on command output

**Cross-References**:
- [Code Standards](../../reference/standards/code-standards.md) → Defensive Programming
- [Robustness Framework](../robustness-framework.md) → Pattern 9 (Output Sanitization)
- `/home/benjamin/.config/.claude/lib/plan/complexity-utils.sh` (lines 55-72) → Reference implementation
- `/home/benjamin/.config/.claude/commands/implement.md` (Block 1d) → Production usage
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` (check_all_phases_complete) → Production usage

## Pattern Application Guide

**When building a new script**:
1. Start with Section 1 (Input Validation) for all arguments and paths
2. Add Section 3 (Return Code Verification) for all critical operations
3. Add Section 4 (Idempotent Operations) for directory and file operations
4. Add Section 5 (Error Context) for all error messages
5. Add Section 2 (Null Safety) for optional values and file operations
6. Add Section 6 (Grep Output Sanitization) for all grep -c output used in conditionals

**When refactoring existing code**:
1. Add input validation at script entry point
2. Add return code checks to critical operations
3. Convert mkdir to mkdir -p for idempotency
4. Enhance error messages with WHICH/WHAT/WHERE
5. Add null guards before file operations
6. Apply 4-step sanitization pattern to grep -c output used in conditionals

## Common Anti-Patterns

**Anti-Pattern 1: Silent Failures**
```bash
# ❌ BAD - Silent failure, continues on error
some_command || true

# ✅ GOOD - Explicit error handling
if ! some_command; then
  echo "ERROR: Command failed"
  exit 1
fi
```

**Anti-Pattern 2: Error Masking**
```bash
# ❌ BAD - Masks real errors
command 2>/dev/null || echo "Using default"

# ✅ GOOD - Captures and reports errors
if ! output=$(command 2>&1); then
  echo "WARNING: Command failed with: $output"
  echo "Using default value"
  output="default"
fi
```

**Anti-Pattern 3: Assuming Success**
```bash
# ❌ BAD - Assumes command succeeded
result=$(complex_operation)
process "$result"

# ✅ GOOD - Verifies before using result
if result=$(complex_operation); then
  process "$result"
else
  echo "ERROR: Operation failed, cannot process result"
  exit 1
fi
```

## Related Documentation

**Pattern References**:
- [Robustness Framework](../robustness-framework.md) - Unified pattern index
- [Verification and Fallback Pattern](verification-fallback.md) - File creation verification
- [Context Management](context-management.md) - Context usage optimization

**Standards**:
- [Code Standards](../../reference/standards/code-standards.md) - General coding standards
- [Command Architecture Standards](../../reference/architecture/overview.md) - Command-specific standards

**Guides**:
- [Error Enhancement Guide](../../guides/patterns/error-enhancement-guide.md) - Complete error handling patterns
- [Library API Reference](../../reference/library-api/overview.md) - Library function documentation
- [Command Development Guide](../../guides/development/command-development/command-development-fundamentals.md) - Command development practices
