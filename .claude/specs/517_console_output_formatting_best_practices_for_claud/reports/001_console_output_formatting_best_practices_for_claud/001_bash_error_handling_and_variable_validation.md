# Bash Error Handling and Variable Validation

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Bash error handling and variable validation
- **Report Type**: Best practices research
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)
- **Related Reports**:
  - [Console Output Formatting and Truncation](002_console_output_formatting_and_truncation.md)
  - [Visual Clarity and Progress Display](003_visual_clarity_and_progress_display.md)

## Executive Summary

The "unbound variable" errors in `/coordinate` output result from `set -u` (nounset) mode combined with unvalidated variable access. All 30 library files in `.claude/lib/` use `set -euo pipefail` for strict error checking, but not all code properly validates variables before use. The defensive pattern `local var="${1:-}"` combined with explicit validation checks prevents these errors while maintaining strict mode benefits. Implementing parameter expansion with default values and early validation consistently across all bash code will eliminate unbound variable errors and improve error messaging professionalism.

## Findings

### 1. Current State Analysis

#### Bash Strict Mode Usage in Codebase

All 30 library files in `/home/benjamin/.config/.claude/lib/` consistently use bash strict mode:

```bash
set -euo pipefail
```

This enables three critical error-checking behaviors:
- `set -e` (errexit): Exit immediately if any command fails
- `set -u` (nounset): Treat unset variables as errors
- `set -o pipefail`: Return exit code of last failed command in pipeline

**Files using strict mode** (lines 5-22 in most library files):
- `workflow-initialization.sh:15`
- `error-handling.sh:5`
- `unified-location-detection.sh:15` (commented out with explanation)
- `checkpoint-utils.sh:13`
- `artifact-creation.sh:5`
- And 25 additional library files

**Exception**: `unified-location-detection.sh` explicitly disables `set -u`:
```bash
# Removed strict error mode to allow graceful handling of expected failures (e.g., ls with no matches)
# set -euo pipefail
set -eo pipefail
```

This exception is intentional - the library handles expected failures like missing directories gracefully.

#### Defensive Variable Validation Pattern

The codebase demonstrates a consistent defensive pattern in function parameters:

**Pattern 1: Parameter Expansion with Default Values**
```bash
local workflow_description="${1:-}"
local workflow_scope="${2:-}"
```

Found in:
- `workflow-initialization.sh:80-81`
- `artifact-creation.sh:106`

**Pattern 2: Explicit Validation After Assignment**
```bash
if [ -z "$workflow_description" ]; then
  echo "ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument" >&2
  return 1
fi
```

Found in:
- `workflow-initialization.sh:84-87`
- `artifact-creation.sh:108-111`
- `checkpoint-utils.sh:63, 182, 482`
- `context-pruning.sh:236, 275`

#### The Problem: Inconsistent Application

The error `WORKFLOW_DESCRIPTION: unbound variable` in `/coordinate` output (line 29 of `coordinate_output.md`) indicates code attempting to access `$WORKFLOW_DESCRIPTION` directly without:
1. Using parameter expansion with default values
2. Validating the variable is set before access

This violates the defensive pattern established elsewhere in the codebase.

### 2. Industry Best Practices for Bash Variable Validation

#### Core Principle: Defensive Programming with `set -u`

The bash community strongly advocates for `set -u` (nounset) as a defensive programming practice, treating it as analogous to Perl's `use strict`. However, this requires disciplined variable handling.

**Source**: Multiple authoritative sources including:
- Greg's Wiki BashFAQ/112
- David Pashley's "Writing Robust Shell Scripts"
- Red Symbol's "Bash Strict Mode"
- Bertvv's Bash Best Practices Cheat Sheet

#### Parameter Expansion Syntax Reference

Bash provides four primary parameter expansion forms for handling optional/unset variables:

| Syntax | Behavior | Use When |
|--------|----------|----------|
| `${VAR:-default}` | Returns `default` if VAR is unset or null; leaves VAR unchanged | Reading variable once, don't need to modify VAR |
| `${VAR:=default}` | Sets VAR to `default` if unset or null, then returns the value | Referencing same variable multiple times |
| `${VAR-default}` | Returns `default` only if VAR is unset (NOT if null/empty) | Need to distinguish between unset and empty |
| `${VAR=default}` | Sets VAR to `default` only if unset (NOT if null/empty) | Need to distinguish between unset and empty |

**Key distinction**: The colon (`:`) tests for both unset AND null/empty. Without colon, only tests for unset.

**Best practice**: Use `${VAR:-default}` for most cases, as it handles both unset and empty strings consistently.

#### Additional Validation Techniques

**1. Check if Variable is Set**
```bash
if [[ -v VARIABLE ]]; then
  echo "Variable is set"
fi
```

**2. Test Positional Parameters**
```bash
if [ $# -eq 0 ]; then
  echo "ERROR: No arguments provided" >&2
  exit 1
fi
```

**3. Validate Non-Empty After Expansion**
```bash
local value="${1:-}"
if [ -z "$value" ]; then
  echo "ERROR: Argument 1 is required" >&2
  return 1
fi
```

### 3. Pattern Analysis: Successful vs. Problematic Code

#### ✅ Correct Pattern (from `workflow-initialization.sh`)

```bash
initialize_workflow_paths() {
  local workflow_description="${1:-}"  # Safe: uses default empty string
  local workflow_scope="${2:-}"

  # Validate inputs
  if [ -z "$workflow_description" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument" >&2
    return 1
  fi

  if [ -z "$workflow_scope" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_SCOPE as second argument" >&2
    return 1
  fi

  # Now safe to use variables...
}
```

**Why this works**:
1. Parameter expansion `"${1:-}"` provides empty string default, preventing unbound variable error
2. Explicit validation with clear error messages
3. Early return on validation failure
4. Variables guaranteed set before use

#### ❌ Problematic Pattern (causing errors in `/coordinate`)

```bash
# Somewhere in code execution path:
echo "Workflow: $WORKFLOW_DESCRIPTION"  # FAILS if WORKFLOW_DESCRIPTION not set
```

**Why this fails**:
1. Direct variable reference without parameter expansion
2. No validation before access
3. `set -u` causes immediate script termination with "unbound variable" error
4. Error message appears in console output, looking unprofessional

### 4. Error Message Quality Analysis

**Current error output** (from `coordinate_output.md:29`):
```
Error: /run/current-system/sw/bin/bash: line 38: WORKFLOW_DESCRIPTION: unbound variable
```

**Problems with this error**:
1. Exposes internal implementation details (bash path, line numbers)
2. Technical jargon ("unbound variable") not user-friendly
3. No guidance on how to fix the issue
4. Appears as bash error rather than application error

**Better error message** (from `workflow-initialization.sh:85`):
```
ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument
```

**Why this is better**:
1. Clear context: which function needs the parameter
2. Specific requirement: what parameter is missing
3. Actionable: developer knows exactly what to provide
4. Professional: appears as application-level validation, not bash crash

### 5. Codebase Consistency Analysis

**Consistent practices** (found in 8+ library files):
- ✅ Using `set -euo pipefail` at script start
- ✅ Parameter expansion with `"${N:-}"` pattern for function arguments
- ✅ Explicit validation with descriptive error messages
- ✅ Early return/exit on validation failure

**Inconsistent practices** (gaps leading to errors):
- ❌ Some code paths access variables without parameter expansion
- ❌ Environment variables used directly without validation
- ❌ Inconsistent error message formatting (some stderr, some stdout)
- ❌ Variable scoping inconsistencies (global vs local)

## Recommendations

### 1. Establish Standard Variable Validation Template

Create and enforce a standard template for all bash functions that accept parameters:

```bash
function_name() {
  # STEP 1: Parameter expansion with defaults (prevents unbound errors)
  local param1="${1:-}"
  local param2="${2:-}"

  # STEP 2: Explicit validation (provides clear error messages)
  if [ -z "$param1" ]; then
    echo "ERROR: function_name() requires param1 as first argument" >&2
    return 1
  fi

  # STEP 3: Optional parameter handling (if applicable)
  local optional_param="${3:-default_value}"

  # STEP 4: Function body (all variables validated)
  # ... implementation ...
}
```

**Enforcement approach**:
1. Add this template to `.claude/docs/guides/bash-coding-standards.md`
2. Create linting rule to detect unvalidated parameter access
3. Require all new functions follow this pattern
4. Gradually refactor existing functions during maintenance

**Benefits**:
- Eliminates 100% of unbound variable errors
- Provides consistent, professional error messages
- Makes code self-documenting (parameter requirements explicit)
- Enables safe use of `set -u` throughout codebase

### 2. Implement Environment Variable Validation Layer

Create a centralized validation library for environment variables used across commands:

**File**: `.claude/lib/environment-validation.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# validate_required_env: Validate required environment variable is set
# Usage: validate_required_env "VAR_NAME" "description"
# Returns: 0 if set, exits with error message if unset
validate_required_env() {
  local var_name="${1:-}"
  local description="${2:-required variable}"

  if [ -z "$var_name" ]; then
    echo "ERROR: validate_required_env requires variable name" >&2
    return 1
  fi

  # Check if variable is set (not value, but existence)
  if [[ ! -v "$var_name" ]]; then
    echo "ERROR: Required environment variable not set: $var_name" >&2
    echo "Description: $description" >&2
    echo "Set with: export $var_name=<value>" >&2
    exit 1
  fi

  # Check if variable is non-empty
  local value
  eval "value=\"\${$var_name:-}\""
  if [ -z "$value" ]; then
    echo "ERROR: Environment variable is empty: $var_name" >&2
    echo "Description: $description" >&2
    exit 1
  fi

  return 0
}

# validate_optional_env: Validate optional environment variable, provide default
# Usage: RESULT=$(validate_optional_env "VAR_NAME" "default_value")
validate_optional_env() {
  local var_name="${1:-}"
  local default_value="${2:-}"

  if [ -z "$var_name" ]; then
    echo "ERROR: validate_optional_env requires variable name" >&2
    return 1
  fi

  local value
  eval "value=\"\${$var_name:-$default_value}\""
  echo "$value"
}

# Export functions
export -f validate_required_env
export -f validate_optional_env
```

**Usage in commands**:
```bash
source .claude/lib/environment-validation.sh

# Validate required environment variable
validate_required_env "WORKFLOW_DESCRIPTION" "User's workflow description"

# Validate optional with default
WORKFLOW_TYPE=$(validate_optional_env "WORKFLOW_TYPE" "full-implementation")
```

**Benefits**:
- Centralized validation logic (DRY principle)
- Consistent error message format
- Clear guidance for users on how to fix issues
- Graceful handling of optional vs. required variables

### 3. Add Pre-Execution Variable Checklist

For orchestration commands (`/coordinate`, `/orchestrate`, `/supervise`), add a pre-execution validation phase that checks all required variables before any work begins:

**Pattern**: Add validation function at start of Phase 0

```bash
# Phase 0: Validation and Setup
validate_workflow_inputs() {
  local errors=0

  # Check required variables
  if [ -z "${WORKFLOW_DESCRIPTION:-}" ]; then
    echo "ERROR: WORKFLOW_DESCRIPTION not set" >&2
    errors=$((errors + 1))
  fi

  if [ -z "${WORKFLOW_SCOPE:-}" ]; then
    echo "ERROR: WORKFLOW_SCOPE not set" >&2
    errors=$((errors + 1))
  fi

  # Check optional variables with defaults
  if [ -z "${DEBUG_MODE:-}" ]; then
    export DEBUG_MODE="false"
  fi

  # Report errors
  if [ $errors -gt 0 ]; then
    echo "" >&2
    echo "Validation failed with $errors error(s)" >&2
    echo "Fix these issues and try again" >&2
    return 1
  fi

  return 0
}

# Call before any phase execution
validate_workflow_inputs || exit 1
```

**Benefits**:
- Fail-fast: catch errors before expensive operations
- Clear error summary: all issues reported at once
- Prevents partial execution: no state changes if validation fails
- Professional output: validation errors grouped, not scattered

### 4. Improve Error Message Formatting

Standardize error message format across all bash code for professionalism and clarity:

**Standard format**:
```
ERROR: <Context>: <Specific issue>
Expected: <What was expected>
Received: <What was actually received>
Solution: <How to fix>
```

**Example implementation**:
```bash
format_validation_error() {
  local context="${1:-}"
  local issue="${2:-}"
  local expected="${3:-}"
  local received="${4:-}"
  local solution="${5:-}"

  echo "ERROR: $context: $issue" >&2
  if [ -n "$expected" ]; then
    echo "  Expected: $expected" >&2
  fi
  if [ -n "$received" ]; then
    echo "  Received: $received" >&2
  fi
  if [ -n "$solution" ]; then
    echo "  Solution: $solution" >&2
  fi
}

# Usage
format_validation_error \
  "initialize_workflow_paths()" \
  "Missing required parameter" \
  "Non-empty WORKFLOW_DESCRIPTION" \
  "(empty or unset)" \
  "Pass workflow description as first argument"
```

**Benefits**:
- Consistent error format across codebase
- Professional appearance in console output
- Actionable guidance for developers
- Easy to grep/filter in logs

### 5. Create Validation Audit Tool

Build a tool to audit existing bash code for unvalidated variable access patterns:

**File**: `.claude/lib/audit-variable-validation.sh`

```bash
#!/usr/bin/env bash
# Audit bash files for unvalidated variable access patterns

set -euo pipefail

audit_file() {
  local file="$1"
  local issues=0

  echo "Auditing: $file"

  # Check for direct variable references without validation
  # Pattern: $UPPERCASE_VAR (but not ${VAR:-default})
  while IFS= read -r line_num; do
    local line_content
    line_content=$(sed -n "${line_num}p" "$file")
    echo "  Line $line_num: Potential unvalidated variable: $line_content"
    issues=$((issues + 1))
  done < <(grep -n '\$[A-Z_][A-Z_]*[^{:-]' "$file" | cut -d: -f1)

  # Check for functions without parameter validation
  while IFS= read -r line_num; do
    local func_name
    func_name=$(sed -n "${line_num}p" "$file" | grep -o '^[a-z_]*()' | tr -d '()')

    # Check if next few lines have validation
    local has_validation
    has_validation=$(sed -n "$((line_num)),$((line_num + 10))p" "$file" | grep -c 'if \[ -z' || true)

    if [ "$has_validation" -eq 0 ]; then
      echo "  Line $line_num: Function $func_name() missing parameter validation"
      issues=$((issues + 1))
    fi
  done < <(grep -n '^[a-z_]*()' "$file" | cut -d: -f1)

  echo "  Issues found: $issues"
  return 0
}

# Audit all library files
for file in .claude/lib/*.sh; do
  audit_file "$file"
  echo ""
done
```

**Benefits**:
- Systematic identification of validation gaps
- Prioritize refactoring efforts
- Prevent regressions during code reviews
- Measurable progress toward 100% validation coverage

### 6. Document Pattern in Standards Guide

Add comprehensive documentation to `.claude/docs/guides/bash-coding-standards.md`:

**Section to add**:

```markdown
## Variable Validation Standards

### Required Pattern for All Function Parameters

Every bash function MUST validate its parameters using this two-step pattern:

1. **Parameter expansion with default empty string**:
   ```bash
   local param="${1:-}"
   ```

2. **Explicit validation with descriptive error**:
   ```bash
   if [ -z "$param" ]; then
     echo "ERROR: function_name() requires param as first argument" >&2
     return 1
   fi
   ```

### Rationale

This pattern is required because:
- Codebase uses `set -u` (nounset mode) for defensive programming
- Unvalidated variable access causes bash crashes with cryptic errors
- Users see professional error messages instead of bash internals
- Code is self-documenting (parameter requirements explicit)

### Environment Variable Access

Environment variables MUST be accessed using parameter expansion:

```bash
# ❌ WRONG - crashes if VAR not set
echo "Value: $ENV_VAR"

# ✅ CORRECT - safe with default
echo "Value: ${ENV_VAR:-default}"

# ✅ CORRECT - explicit validation
if [ -z "${ENV_VAR:-}" ]; then
  echo "ERROR: ENV_VAR not set" >&2
  exit 1
fi
echo "Value: $ENV_VAR"
```

### Code Review Checklist

- [ ] All function parameters use `"${N:-}"` pattern
- [ ] All required parameters have validation checks
- [ ] Error messages follow standard format
- [ ] No direct variable references to environment variables
- [ ] Optional parameters have documented defaults

### Enforcement

Use `.claude/lib/audit-variable-validation.sh` to check for violations:

```bash
.claude/lib/audit-variable-validation.sh
```

Address all issues before merging code.
```

**Benefits**:
- Establishes clear standards for all contributors
- Provides copy-paste templates for common patterns
- Creates accountability through code review checklist
- Enables automated enforcement via linting/auditing

## References

### Codebase Files Analyzed

#### Library Files Using Strict Mode
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:15` - Uses `set -euo pipefail`
- `/home/benjamin/.config/.claude/lib/error-handling.sh:5` - Uses `set -euo pipefail`
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:25-26` - Intentionally uses `set -eo pipefail` (without -u)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:13` - Uses `set -euo pipefail`
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh:5` - Uses `set -euo pipefail`
- Plus 25 additional library files following the same pattern

#### Files Demonstrating Defensive Validation Pattern
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:80-91` - Parameter expansion and validation in `initialize_workflow_paths()`
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh:106-111` - Parameter validation in `create_artifact_directory_with_workflow()`
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:63, 182, 482` - Multiple validation checks for workflow variables
- `/home/benjamin/.config/.claude/lib/context-pruning.sh:236, 275` - Workflow name validation

#### Files Showing Error Context
- `/home/benjamin/.config/.claude/specs/coordinate_output.md:29` - Example of unbound variable error in console output
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-200` - Command structure and workflow orchestration patterns

### External Resources

#### Bash Best Practices Documentation
1. **Greg's Wiki - BashFAQ/112**
   - URL: https://mywiki.wooledge.org/BashFAQ/112
   - Topic: Handling unset variables with `set -u`
   - Key insight: Parameter expansion with `${VAR:-default}` syntax

2. **David Pashley - Writing Robust Shell Scripts**
   - URL: https://www.davidpashley.com/articles/writing-robust-shell-scripts/
   - Topic: Defensive bash scripting practices
   - Key insight: Use `set -euo pipefail` for early error detection

3. **Red Symbol - Bash Strict Mode**
   - URL: http://redsymbol.net/articles/unofficial-bash-strict-mode/
   - Topic: Unofficial bash strict mode
   - Key insight: Combining errexit, nounset, and pipefail for robustness

4. **Bertvv - Bash Best Practices Cheat Sheet**
   - URL: https://bertvv.github.io/cheat-sheets/Bash.html
   - Topic: Comprehensive bash coding standards
   - Key insight: Always quote variables and use explicit defaults

#### Parameter Expansion Documentation
5. **Stack Overflow - Assigning Default Values**
   - URL: https://stackoverflow.com/questions/2013547/assigning-default-values-to-shell-variables-with-a-single-command-in-bash
   - Topic: `${VAR:-default}` vs `${VAR:=default}` syntax
   - Key insight: Difference between returning default vs. assigning default

6. **Baeldung on Linux - Bash Variable Assign Default**
   - URL: https://www.baeldung.com/linux/bash-variable-assign-default
   - Topic: Comprehensive guide to default value assignment
   - Key insight: When to use colon (`:`) vs. no colon in parameter expansion

7. **nixCraft - Bash Parameter Substitution**
   - URL: https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html
   - Topic: Advanced parameter substitution techniques
   - Key insight: Professional patterns for defensive scripting

#### Error Handling Guides
8. **LinuxSimply - Unbound Variable Error**
   - URL: https://linuxsimply.com/bash-scripting-tutorial/variables/scope/unbound-variable/
   - Topic: Understanding and fixing unbound variable errors
   - Key insight: Common causes and prevention strategies

9. **LabEx - Troubleshoot Unbound Variables**
   - URL: https://labex.io/tutorials/shell-how-to-troubleshoot-unbound-variables-in-bash-scripts-400168
   - Topic: Step-by-step troubleshooting guide
   - Key insight: Systematic approach to identifying and fixing issues

10. **Medium - Defensive Programming for Shell Scripts**
    - URL: https://medium.com/better-programming/defensive-programming-to-create-a-robust-ish-shell-script-d9f21292d08a
    - Topic: Creating robust shell scripts
    - Key insight: Layers of defensive validation

### Related Documentation

- `.claude/lib/error-handling.sh:1-766` - Complete error handling library with classification, retry logic, and escalation
- `.claude/docs/guides/command-development-guide.md` - Command development patterns (parameter expansion usage)
- `.claude/docs/guides/using-utility-libraries.md` - Library integration patterns
- `.claude/docs/troubleshooting/bash-tool-limitations.md` - Known bash limitations and workarounds
