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

## Pattern Application Guide

**When building a new script**:
1. Start with Section 1 (Input Validation) for all arguments and paths
2. Add Section 3 (Return Code Verification) for all critical operations
3. Add Section 4 (Idempotent Operations) for directory and file operations
4. Add Section 5 (Error Context) for all error messages
5. Add Section 2 (Null Safety) for optional values and file operations

**When refactoring existing code**:
1. Add input validation at script entry point
2. Add return code checks to critical operations
3. Convert mkdir to mkdir -p for idempotency
4. Enhance error messages with WHICH/WHAT/WHERE
5. Add null guards before file operations

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
