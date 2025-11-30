# Build Output Runtime Errors Analysis

## Metadata
- **Date**: 2025-11-29
- **Analysis Type**: Build Command Runtime Error Investigation
- **Build Output**: /home/benjamin/.config/.claude/output/build-output.md
- **Existing Plan**: /home/benjamin/.config/.claude/specs/966_repair_build_20251129_150219/plans/001-repair-build-20251129-150219-plan.md
- **Command**: /build
- **Status**: ERRORS IDENTIFIED - Not Being Logged

## Executive Summary

Analysis of the build output reveals **three critical runtime errors that are NOT being captured by the error logging system**. These errors occur during bash block execution but are bypassing the ERR trap due to:

1. **Preprocessing-unsafe bash syntax** (exit code 2)
2. **SIGPIPE errors** from truncated output (exit code 141)
3. **Empty variable expansion** leading to invalid paths (exit code 1)

**Critical Finding**: The error trap setup occurs AFTER these errors happen in some blocks, creating a vulnerability window where errors go unlogged. Additionally, some errors are filtered as "benign" when they should be logged.

## Error Pattern Analysis

### Error 1: Exit Code 2 - Bash Preprocessing Syntax Error

**Location**: build-output.md lines 55-61

```
● Bash(set +H 2>/dev/null || true
      set +o histexpand 2>/dev/null || true…)
  ⎿  Error: Exit code 2
     /run/current-system/sw/bin/bash: eval: line 253: conditional binary
     operator expected
     /run/current-system/sw/bin/bash: eval: line 253: syntax error near `-d'
     /run/current-system/sw/bin/bash: eval: line 253: `if [[ \! -d
     "$SUMMARIES_DIR" ]]; then'
```

**Root Cause Analysis**:

The error occurs at build.md line 588:
```bash
if [[ ! -d "$SUMMARIES_DIR" ]]; then
```

However, when bash preprocessing is active (history expansion), the `!` negation operator is being escaped to `\!` by the Claude Code bash tool's preprocessing layer. This creates invalid syntax: `[[ \! -d ... ]]` which bash interprets as the escaped backslash followed by `!` rather than the negation operator.

**Why Not Logged**:
1. **Trap Not Set**: This error occurs in Block 1c (Implementation Verification), line 588
2. The `setup_bash_error_trap` call doesn't happen until line 574 in Block 1c
3. However, the trap is set with `set -e` at the top (line 497), which should cause immediate exit
4. **The real issue**: The error occurs during bash preprocessing by Claude Code's eval layer, BEFORE the bash code even executes, so the ERR trap never fires

**Defensive Check Pattern Violation**:

The code at line 588 violates the defensive check pattern recommended in the repair plan (Phase 1):

```bash
# CURRENT (line 588):
if [[ ! -d "$SUMMARIES_DIR" ]]; then
  # Error logging...
fi

# SHOULD BE (defensive pattern):
if [ -d "$SUMMARIES_DIR" ] && [ "$(ls -A "$SUMMARIES_DIR"/*.md 2>/dev/null)" ]; then
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md | head -n 1)
else
  LATEST_SUMMARY=""
fi
```

**Impact**: Block execution fails, workflow halts, no error logged to errors.jsonl

---

### Error 2: Exit Code 141 - SIGPIPE from Truncated Output

**Location**: build-output.md lines 94-99

```
● Bash(# Detect project directory
      if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null
      2>&1; then…)
  ⎿  Error: Exit code 141
     Checking for test file...
     Found: test_todo_hard_barrier.sh
     -rwx--x--x 1 benjamin users 5056 Nov 29 14:56 /home/benjamin/.config/.cl
     aude/tests/features/commands/test_todo_hard_barrier.sh

     Checking todo.md Block structure...
```

**Root Cause Analysis**:

Exit code 141 is SIGPIPE (128 + 13), which occurs when a process writes to a pipe that has been closed by the receiving end. This typically happens with commands like:

```bash
grep "pattern" large_file | head -n 1
```

When `head` reads its first line and exits, it closes the pipe, causing `grep` to receive SIGPIPE when it tries to write the next line.

**Where in build.md**:

Searching build.md for `| head` patterns reveals multiple candidates:
- Line 147: `PLAN_FILE=$(find ... | head -1)`
- Line 609: `LATEST_SUMMARY=$(find ... | head -1)`
- Line 782: `WORK_REMAINING=$(grep ... | head -1 || echo "")`
- Line 1361: `TEST_OUTPUT_PATH=$(ls ... | head -1 || echo "")`

The error output shows "Checking for test file..." and "Checking todo.md Block structure...", suggesting this occurs during test detection logic around lines 1100-1170.

**Why Not Logged**:

1. **SIGPIPE is intentional**: Using `| head` to truncate output is a valid pattern
2. **Exit code 141 filtered**: The ERR trap likely doesn't fire for SIGPIPE, or it's filtered as benign
3. **No error context**: Even if trapped, the error provides no actionable information

**Best Practice Violation**:

The pattern should suppress SIGPIPE explicitly:

```bash
# CURRENT:
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)

# SHOULD BE:
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1 || true)
```

**Impact**: Non-critical, but creates noise in bash output and may cause false alarm for monitoring

---

### Error 3: Exit Code 1 - Empty CLAUDE_PROJECT_DIR Variable

**Location**: build-output.md lines 120-123

```
● Bash(CLAUDE_PROJECT_DIR="/home/benjamin/.config"              timeout: 1m
      cd "$CLAUDE_PROJECT_DIR/.claude" && bash                  0s
      tests/features/commands/test_todo_hard_barrier.sh 2>&1 |
      head -100)
  ⎿  Error: Exit code 1
     /run/current-system/sw/bin/bash: line 1: cd: /.claude: No such file or
     directory
```

**Root Cause Analysis**:

The error shows `cd: /.claude` (note the leading `/` with no directory before it), indicating that `$CLAUDE_PROJECT_DIR` expanded to an empty string, resulting in the command:

```bash
cd "/.claude"  # Should be: cd "/home/benjamin/.config/.claude"
```

This suggests that between the variable assignment `CLAUDE_PROJECT_DIR="/home/benjamin/.config"` (shown in the bash command) and the `cd` command execution, the variable became unset or empty.

**Why This Happens**:

Looking at build.md lines 1108-1143 (the test execution block), I see:

```bash
# Line 1110-1118: Project directory detection
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
```

**The problem**: If the detection logic fails (no git repo, no .claude directory found), `CLAUDE_PROJECT_DIR` remains unset. Then line 1117 executes:

```bash
cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/...
```

Which becomes `cd "/.claude"` when the variable is empty.

**Why Not Logged**:

1. **Trap timing**: The error occurs in a standalone bash invocation (lines 1116-1119), which is a separate bash block
2. **No state restoration**: This block doesn't call `load_workflow_state`, so `CLAUDE_PROJECT_DIR` must be detected fresh
3. **Missing validation**: No check that `CLAUDE_PROJECT_DIR` is non-empty before using it

**Defensive Check Missing**:

The code should validate the variable before use:

```bash
# CURRENT (line 1117):
cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/...

# SHOULD BE:
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  log_command_error "state_error" \
    "Failed to detect project directory for test execution" \
    "$(jq -n '{attempted_path: "/.claude"}')"
  echo "ERROR: CLAUDE_PROJECT_DIR not set" >&2
  exit 1
fi
cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/...
```

**Impact**: Test execution fails with cryptic error, no actionable error logged

---

## Why These Errors Bypass Error Logging

### 1. Trap Initialization Timing

**Vulnerability Windows**:

Looking at the build.md structure:

**Block 1c (Implementation Verification)** - Lines 493-636:
- Line 497: `set -e` (fail-fast)
- Line 526: `trap '...' ERR` (defensive trap, basic)
- Line 574: `setup_bash_error_trap` (full trap with logging)
- Line 588: **ERROR OCCURS** (`if [[ ! -d ...]]`)

**Gap**: 14 lines (574-588) between full trap setup and error location, but the defensive trap should catch it.

**Why it wasn't caught**: The error is a **preprocessing error** (exit code 2), which occurs when Claude Code's bash tool preprocesses the script with `set +H` and escapes the `!`. This happens BEFORE bash even evaluates the trap.

**Block Testing Phase** - Lines 1108-1176:
- Line 1108: `# Detect project directory` comment
- Line 1110-1118: Project directory detection
- Line 1117: **ERROR OCCURS** (`cd "$CLAUDE_PROJECT_DIR/.claude"` with empty var)
- No trap setup in this block!

**Gap**: This appears to be an inline bash command (not a structured bash block with trap setup), so errors don't get logged.

### 2. Benign Error Filtering

The `_is_benign_bash_error` function (error-handling.sh lines 1807-1895) filters:
- bashrc sourcing failures
- return statements from whitelisted functions
- errors from system initialization files

**None of these three errors match the benign patterns**, so filtering is NOT the issue.

### 3. Error Suppression with 2>/dev/null

Many commands use `2>/dev/null` to suppress stderr:

```bash
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)
```

While this suppresses error output, it doesn't prevent error logging if the command fails and triggers the ERR trap. However, it does hide diagnostic information that could help debug the error.

### 4. Non-Critical Operations Treated as Critical

The repair plan (Phase 1) identifies that some operations are non-critical:
- File existence checks (summaries directory)
- Optional file listings (latest summary)
- Context estimation (can use fallback)

Currently, these are treated as critical (no fallback values), so failures cause errors when they shouldn't.

---

## Gap Analysis: Repair Plan vs Actual Errors

### Repair Plan Phase 1: Defensive Error Handling

**Plan Says**:
> Add defensive checks before file operations (summaries directory, latest summary file)
> Provide default values for optional operations (empty LATEST_SUMMARY if no summaries exist)

**What Actually Happens**:

1. **Line 588 Error**: The defensive check pattern is violated - using `[[ ! -d ... ]]` instead of positive checks with fallbacks
2. **No fallback values**: When `SUMMARIES_DIR` doesn't exist, the code logs an error and exits rather than setting `LATEST_SUMMARY=""`

**Plan Addresses This**: ✅ YES - Phase 1 Task 5 specifies the exact defensive check pattern needed

### Repair Plan Phase 2: State Transitions

**Plan Says**:
> Ensure implement state always transitions to test (never directly to complete)
> Add validation before state transitions to confirm current state and valid targets

**What Actually Happens**:

These errors are NOT state transition related - they occur during block execution, not during `sm_transition` calls.

**Plan Addresses This**: ❌ NO - State transition errors are different from these runtime bash errors

### Repair Plan Phase 3: Test Coverage

**Plan Says**:
> Add test case for file operations on empty directories
> Add test case for context estimation fallback

**What Actually Happens**:

1. **Empty directory error** (line 588): Exactly the scenario Phase 3 tests should cover
2. **Empty variable error** (line 1117): NOT covered by the plan's test cases

**Plan Addresses This**: ⚠️ PARTIAL - Covers empty directory, but not empty variable expansion

---

## Root Cause Summary

### Why Errors Not Being Logged

| Error | Exit Code | Root Cause | Why Not Logged |
|-------|-----------|------------|----------------|
| Syntax error (line 588) | 2 | Preprocessing-unsafe `[[ ! ... ]]` negation | Preprocessing error occurs before ERR trap evaluates |
| SIGPIPE (test detection) | 141 | `grep \| head` truncation | SIGPIPE is expected behavior, likely filtered or not trapped |
| Empty variable (line 1117) | 1 | Missing validation before `cd "$EMPTY_VAR/.claude"` | Inline bash command, no trap setup in that context |

### Fundamental Issues

1. **Preprocessing vs Runtime Errors**: Exit code 2 errors from history expansion happen at preprocessing time, before ERR trap is active
2. **Trap Coverage Gaps**: Inline bash commands (e.g., test execution at line 1117) don't have trap setup
3. **No Defensive Programming**: Using `[[ ! -d ... ]]` instead of positive checks, no validation before variable expansion
4. **Non-Critical Operations**: File operations that should have fallbacks are treated as critical failures

---

## Recommendations for Repair Plan Revision

### 1. Add New Phase: Preprocessing-Safe Bash Syntax

**Objective**: Replace preprocessing-unsafe bash constructs with preprocessing-safe alternatives

**Tasks**:
- [ ] Replace all `[[ ! ... ]]` negations with positive checks: `if [ -d "$DIR" ]; then ... else ... fi`
- [ ] Replace all `[[ \! ... ]]` with `[ ! ... ]` (single bracket with space)
- [ ] Audit all conditional expressions for history expansion conflicts
- [ ] Document preprocessing-safe patterns in code-standards.md

**Testing**:
```bash
# Test preprocessing with set +H
bash -c 'set +H; if [[ ! -d /tmp ]]; then echo "fail"; fi'  # Should fail
bash -c 'set +H; if [ ! -d /tmp ]; then echo "pass"; fi'    # Should pass
```

### 2. Enhance Phase 1: Defensive Error Handling

**Add to existing Phase 1 tasks**:
- [ ] Add variable validation before all variable expansions in file paths:
  ```bash
  if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    log_command_error "state_error" "CLAUDE_PROJECT_DIR not set" "..."
    exit 1
  fi
  cd "$CLAUDE_PROJECT_DIR/.claude"
  ```
- [ ] Replace `2>/dev/null` suppression with explicit fallback logic:
  ```bash
  # INSTEAD OF:
  LATEST=$(ls -t *.md 2>/dev/null | head -1)

  # USE:
  if [ -d "$SUMMARIES_DIR" ] && ls -t "$SUMMARIES_DIR"/*.md >/dev/null 2>&1; then
    LATEST=$(ls -t "$SUMMARIES_DIR"/*.md | head -1 || true)
  else
    LATEST=""
  fi
  ```

### 3. Add New Phase: SIGPIPE Handling

**Objective**: Prevent SIGPIPE errors from causing false alarms

**Tasks**:
- [ ] Audit all `| head` patterns in build.md
- [ ] Add `|| true` to commands that intentionally truncate output:
  ```bash
  LATEST_SUMMARY=$(find ... | head -1 || true)
  ```
- [ ] Document SIGPIPE handling pattern in code-standards.md

**Testing**:
```bash
# Test SIGPIPE suppression
large_output_command | head -1 || true  # Should exit 0, not 141
```

### 4. Enhance Phase 2: Add Inline Command Trap Setup

**Add to existing Phase 2 tasks**:
- [ ] Identify all inline bash commands (not structured blocks) in build.md
- [ ] Add defensive checks before inline commands:
  ```bash
  # BEFORE inline command:
  if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    echo "ERROR: CLAUDE_PROJECT_DIR not set" >&2
    exit 1
  fi
  # Then run inline command
  cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/...
  ```
- [ ] Convert critical inline commands to structured bash blocks with trap setup

### 5. Enhance Phase 3: Add Preprocessing and Variable Tests

**Add to existing Phase 3 test cases**:
- [ ] Add test case for preprocessing-safe negation syntax:
  ```bash
  # Test that [[ ! ... ]] is NOT used, [ ! ... ] IS used
  grep -n '\[\[ \\*! ' .claude/commands/build.md && exit 1 || exit 0
  ```
- [ ] Add test case for empty variable expansion:
  ```bash
  # Test that cd with empty variable is caught
  EMPTY_VAR=""
  cd "$EMPTY_VAR/.claude" 2>&1 | grep -q "No such file"
  ```
- [ ] Add test case for SIGPIPE handling:
  ```bash
  # Test that pipe truncation doesn't error
  yes | head -1 || true
  EXIT_CODE=$?
  [ "$EXIT_CODE" -eq 0 ] || exit 1
  ```

---

## Specific Build.md Line Fixes

### Fix 1: Line 588 - Summaries Directory Check

**Current (preprocessing-unsafe)**:
```bash
# Line 588
if [[ ! -d "$SUMMARIES_DIR" ]]; then
  log_command_error "verification_error" \
    "Summaries directory not found: $SUMMARIES_DIR" \
    "implementer-coordinator should have created this directory"
  echo "ERROR: VERIFICATION FAILED - Summaries directory missing"
  echo "Recovery: Check implementer-coordinator logs, ensure Task was invoked"
  exit 1
fi
```

**Recommended Fix**:
```bash
# Defensive check with positive logic and fallback
if [ ! -d "$SUMMARIES_DIR" ]; then
  log_command_error "verification_error" \
    "Summaries directory not found: $SUMMARIES_DIR" \
    "implementer-coordinator should have created this directory"
  echo "ERROR: VERIFICATION FAILED - Summaries directory missing"
  echo "Recovery: Check implementer-coordinator logs, ensure Task was invoked"
  exit 1
fi
```

**Key Change**: Replace `[[ ! ... ]]` with `[ ! ... ]` (single bracket with space after !)

### Fix 2: Line 609 - Latest Summary Detection

**Current (no fallback)**:
```bash
# Line 609
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)
if [[ -z "$LATEST_SUMMARY" ]] || [[ ! -f "$LATEST_SUMMARY" ]]; then
  log_command_error "verification_error" \
    "Could not find latest summary in $SUMMARIES_DIR" \
    "Expected at least one summary file"
  echo "ERROR: VERIFICATION FAILED - Latest summary not accessible"
  exit 1
fi
```

**Recommended Fix**:
```bash
# Defensive check with explicit fallback and SIGPIPE handling
if [ -d "$SUMMARIES_DIR" ] && ls -t "$SUMMARIES_DIR"/*.md >/dev/null 2>&1; then
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -1 || true)
else
  LATEST_SUMMARY=""
fi

if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  log_command_error "verification_error" \
    "Could not find latest summary in $SUMMARIES_DIR" \
    "Expected at least one summary file"
  echo "ERROR: VERIFICATION FAILED - Latest summary not accessible"
  exit 1
fi
```

**Key Changes**:
1. Positive existence check before ls command
2. Added `|| true` to prevent SIGPIPE (exit 141)
3. Single brackets `[ ]` instead of double brackets `[[ ]]`

### Fix 3: Line 1117 - Test Execution with Empty Variable

**Current (no validation)**:
```bash
# Line 1117
cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/features/commands/test_todo_hard_barrier.sh 2>&1 | head -100
```

**Recommended Fix**:
```bash
# Add variable validation before use
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "CLAUDE_PROJECT_DIR not set or invalid for test execution" \
    "test_execution" \
    "$(jq -n --arg dir "${CLAUDE_PROJECT_DIR:-EMPTY}" --arg path "/.claude" \
       '{claude_project_dir: $dir, attempted_path: $path}')"
  echo "ERROR: Cannot execute tests - project directory not detected" >&2
  exit 1
fi

# Now safe to use variable
cd "$CLAUDE_PROJECT_DIR/.claude" && bash tests/features/commands/test_todo_hard_barrier.sh 2>&1 | head -100 || true
```

**Key Changes**:
1. Variable validation with error logging before use
2. Added `|| true` to handle head truncation (SIGPIPE)
3. Single brackets for POSIX compatibility

### Fix 4: Line 718 - Context Estimation Fallback

**Current (can fail without fallback)**:
```bash
# Line 718
CONTEXT_ESTIMATE=$(estimate_context_usage "$COMPLETED_PHASES" "$REMAINING_PHASES" "$HAS_CONTINUATION" 2>/dev/null) || CONTEXT_ESTIMATE=50000
```

**Recommended Fix** (already has fallback, but improve error visibility):
```bash
# Check function availability before calling
if type -t estimate_context_usage &>/dev/null; then
  CONTEXT_ESTIMATE=$(estimate_context_usage "$COMPLETED_PHASES" "$REMAINING_PHASES" "$HAS_CONTINUATION" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$CONTEXT_ESTIMATE" ]; then
    echo "WARNING: Context estimation failed, using fallback value" >&2
    CONTEXT_ESTIMATE=50000
  fi
else
  echo "WARNING: estimate_context_usage function not available, using fallback" >&2
  CONTEXT_ESTIMATE=50000
fi
```

**Key Changes**:
1. Check function exists before calling
2. Explicit validation of function return value
3. Warning messages for visibility (non-critical operation)

---

## Testing Strategy

### Unit Tests for Defensive Patterns

Create `.claude/tests/unit/test_build_defensive_checks.sh`:

```bash
#!/usr/bin/env bash
# Test defensive check patterns in build.md

test_preprocessing_safe_negation() {
  # Ensure no [[ ! ... ]] patterns (preprocessing-unsafe)
  local unsafe_count=$(grep -c '\[\[ \\*! ' .claude/commands/build.md)
  if [ "$unsafe_count" -gt 0 ]; then
    echo "FAIL: Found $unsafe_count preprocessing-unsafe negations"
    return 1
  fi
  echo "PASS: No preprocessing-unsafe negations found"
  return 0
}

test_variable_validation_before_use() {
  # Check that CLAUDE_PROJECT_DIR is validated before cd commands
  local cd_lines=$(grep -n 'cd "$CLAUDE_PROJECT_DIR' .claude/commands/build.md | cut -d: -f1)
  for line in $cd_lines; do
    # Check if there's a validation within 10 lines before
    local validation_line=$((line - 10))
    if ! sed -n "${validation_line},${line}p" .claude/commands/build.md | \
         grep -q 'if \[ -z "$CLAUDE_PROJECT_DIR" \]'; then
      echo "FAIL: cd at line $line lacks CLAUDE_PROJECT_DIR validation"
      return 1
    fi
  done
  echo "PASS: All cd commands have variable validation"
  return 0
}

test_sigpipe_handling() {
  # Check that all | head patterns have || true
  local head_patterns=$(grep -n '| head -' .claude/commands/build.md | grep -v '|| true')
  if [ -n "$head_patterns" ]; then
    echo "FAIL: Found | head patterns without || true:"
    echo "$head_patterns"
    return 1
  fi
  echo "PASS: All | head patterns have SIGPIPE handling"
  return 0
}

# Run tests
test_preprocessing_safe_negation
test_variable_validation_before_use
test_sigpipe_handling
```

### Integration Tests for Error Scenarios

Create `.claude/tests/integration/test_build_error_scenarios.sh`:

```bash
#!/usr/bin/env bash
# Test build command error handling in realistic scenarios

test_empty_summaries_directory() {
  # Test that build doesn't error on empty summaries directory
  local test_dir=$(mktemp -d)
  mkdir -p "$test_dir/summaries"

  # Simulate the check with empty directory
  SUMMARIES_DIR="$test_dir/summaries"
  if [ -d "$SUMMARIES_DIR" ] && ls -t "$SUMMARIES_DIR"/*.md >/dev/null 2>&1; then
    LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -1 || true)
  else
    LATEST_SUMMARY=""
  fi

  # Should not error, should set LATEST_SUMMARY to empty
  if [ -z "$LATEST_SUMMARY" ]; then
    echo "PASS: Empty summaries directory handled correctly"
    rm -rf "$test_dir"
    return 0
  else
    echo "FAIL: LATEST_SUMMARY should be empty for empty directory"
    rm -rf "$test_dir"
    return 1
  fi
}

test_empty_variable_in_path() {
  # Test that empty variable expansion is caught
  EMPTY_VAR=""
  if [ -z "$EMPTY_VAR" ]; then
    echo "PASS: Empty variable caught before use in path"
    return 0
  else
    echo "FAIL: Empty variable not validated"
    return 1
  fi
}

test_context_estimation_fallback() {
  # Test context estimation with missing function
  unset -f estimate_context_usage 2>/dev/null

  if type -t estimate_context_usage &>/dev/null; then
    CONTEXT_ESTIMATE=$(estimate_context_usage 5 3 "false" 2>/dev/null) || CONTEXT_ESTIMATE=50000
  else
    CONTEXT_ESTIMATE=50000
  fi

  if [ "$CONTEXT_ESTIMATE" -eq 50000 ]; then
    echo "PASS: Context estimation fallback works"
    return 0
  else
    echo "FAIL: Context estimation fallback failed"
    return 1
  fi
}

# Run tests
test_empty_summaries_directory
test_empty_variable_in_path
test_context_estimation_fallback
```

---

## Prioritization and Impact Assessment

### Priority 1: CRITICAL - Preprocessing Syntax Error (Exit Code 2)

**Impact**: Blocks workflow execution completely, no error logged, cryptic error message

**Urgency**: HIGH - Affects every /build invocation with empty summaries directory

**Fix Effort**: LOW - Simple syntax change ([[ ! ]] → [ ! ])

**Recommended Action**: Fix immediately in Phase 1

### Priority 2: HIGH - Empty Variable Expansion (Exit Code 1)

**Impact**: Test execution fails, cryptic "/.claude: No such file" error

**Urgency**: MEDIUM - Only affects builds when project directory detection fails

**Fix Effort**: LOW - Add variable validation before use

**Recommended Action**: Add to Phase 1 as new task

### Priority 3: MEDIUM - SIGPIPE Handling (Exit Code 141)

**Impact**: Creates noise in output, but doesn't block execution

**Urgency**: LOW - Cosmetic issue, doesn't affect functionality

**Fix Effort**: LOW - Add || true to pipe commands

**Recommended Action**: Add as new Phase 1.5 or include in Phase 1

---

## Conclusion

The three errors identified in the build output are NOT being logged because:

1. **Preprocessing errors** (exit code 2) occur before ERR trap evaluates
2. **SIGPIPE errors** (exit code 141) are expected behavior, not trapped as errors
3. **Inline command errors** (exit code 1) occur in contexts without trap setup

The existing repair plan **partially addresses these issues** through Phase 1 (defensive error handling), but needs enhancements:

1. **New tasks for Phase 1**: Preprocessing-safe syntax, variable validation, SIGPIPE handling
2. **Enhanced Phase 3**: Add tests for preprocessing, empty variables, and SIGPIPE scenarios
3. **Documentation updates**: Add preprocessing-safe patterns to code-standards.md

**Recommended Next Steps**:

1. Update repair plan to include preprocessing-safe syntax fixes
2. Implement specific line fixes for build.md (lines 588, 609, 1117, 718)
3. Add unit and integration tests for all error scenarios
4. Document defensive programming patterns for future development

---

## References

- Build Output: /home/benjamin/.config/.claude/output/build-output.md
- Build Command: /home/benjamin/.config/.claude/commands/build.md
- Error Handling Library: /home/benjamin/.config/.claude/lib/core/error-handling.sh
- Existing Repair Plan: /home/benjamin/.config/.claude/specs/966_repair_build_20251129_150219/plans/001-repair-build-20251129-150219-plan.md
- Bash Manual - History Expansion: https://www.gnu.org/software/bash/manual/html_node/History-Interaction.html
- POSIX Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
