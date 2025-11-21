# Bash History Expansion UI Errors Fix Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Fix bash history expansion UI errors in command output files
- **Scope**: Replace 52 instances of `if !` and `elif !` patterns across 8 command files with exit code capture pattern
- **Estimated Phases**: 6
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 36.0
- **Research Reports**:
  - [Bash History Expansion Analysis](../reports/001_bash_history_expansion_analysis.md)

## Overview

This plan addresses the recurring bash history expansion errors (`/run/current-system/sw/bin/bash: line XXX: !: command not found`) that appear in command output files. These errors are caused by preprocessing-stage history expansion occurring BEFORE runtime `set +H` can take effect. The solution is to replace all `if !` and `elif !` patterns with the documented exit code capture pattern, eliminating exclamation marks from preprocessing-stage visibility.

**Impact**: Eliminates all UI errors in 5 output files (debug-output.md, plan-output.md, build-output.md, research-output.md, revise-output.md) affecting user experience.

## Research Summary

Key findings from bash history expansion analysis report:

- **Root Cause**: Bash tool preprocessing triggers history expansion BEFORE `set +H` executes at runtime
- **Scope**: 52 problematic patterns across 8 command files (plan.md, debug.md, build.md, repair.md, research.md, optimize-claude.md, convert-docs.md, setup.md)
- **Pattern Categories**: State machine transitions (23), validation checks (18), file operations (6), function calls (5)
- **Solution**: Exit code capture pattern documented in bash-tool-limitations.md:329-353
- **Historical Context**: Similar fixes in specs 620, 641, 672, 685, 700, 717 with 47/47 test pass rate

Recommended approach: Phased remediation prioritizing highest-visibility errors (`elif !` patterns), followed by systematic category-based fixes.

## Success Criteria

- [ ] All 52 instances of `if !` and `elif !` patterns replaced with exit code capture pattern
- [ ] All 5 command output files free of "!: command not found" errors after running affected commands
- [ ] Automated detection test created to prevent future occurrences
- [ ] Command authoring standards updated with explicit prohibition
- [ ] All existing tests pass after changes
- [ ] No new preprocessing errors introduced

## Technical Design

### Architecture Overview

The fix operates at the bash scripting pattern level within command files:

```
Before (vulnerable):
┌────────────────────────────────────┐
│ if ! command; then                 │  ← Preprocessing sees "!"
│   error handling                   │  ← History expansion triggered
│ fi                                 │
└────────────────────────────────────┘

After (safe):
┌────────────────────────────────────┐
│ command                            │  ← No "!" in preprocessing
│ EXIT_CODE=$?                       │  ← Capture exit code
│ if [ $EXIT_CODE -ne 0 ]; then     │  ← Safe comparison
│   error handling                   │
│ fi                                 │
└────────────────────────────────────┘
```

### Pattern Transformation Rules

**Rule 1: Simple `if !` Negation**
```bash
# Before
if ! some_command arg1 arg2; then
  echo "ERROR: Command failed"
  exit 1
fi

# After
some_command arg1 arg2
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Command failed"
  exit 1
fi
```

**Rule 2: `elif !` Negation**
```bash
# Before
if [ -z "$VAR" ]; then
  VAR="default"
elif ! echo "$VAR" | grep -Eq '^pattern$'; then
  VAR="default"
fi

# After
if [ -z "$VAR" ]; then
  VAR="default"
else
  echo "$VAR" | grep -Eq '^pattern$'
  IS_VALID=$?
  if [ $IS_VALID -ne 0 ]; then
    VAR="default"
  fi
fi
```

**Rule 3: Pipe with Negation**
```bash
# Before
if ! echo "$VALUE" | command1 | command2; then
  handle_error
fi

# After
echo "$VALUE" | command1 | command2
PIPELINE_STATUS=$?
if [ $PIPELINE_STATUS -ne 0 ]; then
  handle_error
fi
```

### Component Integration

No new components required. Changes are localized to existing command files:
- `.claude/commands/plan.md`
- `.claude/commands/debug.md`
- `.claude/commands/build.md`
- `.claude/commands/repair.md`
- `.claude/commands/research.md`
- `.claude/commands/optimize-claude.md`
- `.claude/commands/convert-docs.md`
- `.claude/commands/setup.md`

## Implementation Phases

### Phase 1: Fix Critical `elif !` Patterns [COMPLETE]
dependencies: []

**Objective**: Eliminate the 4 highest-visibility `elif !` patterns causing most UI errors

**Complexity**: Low

Tasks:
- [x] Fix `elif !` pattern in `.claude/commands/plan.md:337` (topic name validation)
- [x] Fix `elif !` pattern in `.claude/commands/debug.md:366` (topic name validation)
- [x] Fix `elif !` pattern in `.claude/commands/research.md:314` (topic name validation)
- [x] Fix `elif !` pattern in `.claude/commands/optimize-claude.md:278` (topic name validation)
- [x] Verify plan-output.md shows no "!: command not found" errors after running /plan
- [x] Verify debug-output.md shows no "!: command not found" errors after running /debug

Testing:
```bash
# Run commands with output suppression, capture exit codes
/plan "test feature" --complexity 1 >/dev/null 2>&1
PLAN_EXIT=$?

/debug "test issue" --complexity 1 >/dev/null 2>&1
DEBUG_EXIT=$?

# Verify no history expansion errors (single summary line)
PLAN_ERRORS=$(grep -c "!: command not found" .claude/plan-output.md 2>/dev/null || echo 0)
DEBUG_ERRORS=$(grep -c "!: command not found" .claude/debug-output.md 2>/dev/null || echo 0)

if [ "$PLAN_ERRORS" -eq 0 ] && [ "$DEBUG_ERRORS" -eq 0 ]; then
  echo "✓ Phase 1 validation passed (0 errors in plan/debug output)"
else
  echo "❌ Phase 1 validation failed ($PLAN_ERRORS plan errors, $DEBUG_ERRORS debug errors)"
  exit 1
fi
```

**Expected Duration**: 1 hour

### Phase 2: Fix State Machine Transition Patterns [COMPLETE]
dependencies: [1]

**Objective**: Replace 23 `if !` patterns in state machine transitions across all command files

**Complexity**: Medium

Tasks:
- [x] Fix `if ! sm_transition` patterns in `.claude/commands/plan.md` (5 instances)
- [x] Fix `if ! sm_transition` patterns in `.claude/commands/debug.md` (4 instances)
- [x] Fix `if ! sm_transition` patterns in `.claude/commands/build.md` (8 instances)
- [x] Fix `if ! sm_transition` patterns in `.claude/commands/repair.md` (4 instances)
- [x] Fix `if ! sm_init` patterns in `.claude/commands/research.md` (3 instances)
- [x] Fix `if ! sm_init` patterns in `.claude/commands/revise.md` (4 instances)
- [x] Test each modified command with validation workflow
- [x] Verify no state transition errors in output files

Testing:
```bash
# Test state machine transitions with output suppression
errors=0
for cmd in plan debug build repair research; do
  /$cmd "test workflow" --complexity 1 >/dev/null 2>&1
  error_count=$(grep -c "!: command not found" .claude/${cmd}-output.md 2>/dev/null || echo 0)
  [ "$error_count" -gt 0 ] && errors=$((errors + error_count))
done

# Single summary line
if [ $errors -eq 0 ]; then
  echo "✓ Phase 2 validation passed (0 history expansion errors across 5 commands)"
else
  echo "❌ Phase 2 validation failed ($errors total errors)"
  exit 1
fi
```

**Expected Duration**: 2 hours

### Phase 3: Fix Validation Check Patterns [COMPLETE]
dependencies: [2]

**Objective**: Replace complexity validation `if !` patterns in validation checks

**Complexity**: Medium

Tasks:
- [x] Fix complexity validation pattern in `.claude/commands/plan.md` (1 instance)
- [x] Fix complexity validation pattern in `.claude/commands/debug.md` (1 instance)
- [x] Fix complexity validation pattern in `.claude/commands/build.md` (1 instance: phase validation)
- [x] Fix complexity validation pattern in `.claude/commands/research.md` (1 instance)
- [x] Fix complexity validation pattern in `.claude/commands/repair.md` (1 instance)
- [x] Fix complexity validation pattern in `.claude/commands/revise.md` (1 instance)
- [x] Test each command with invalid inputs to trigger validation paths
- [x] Verify validation error messages display correctly without preprocessing errors

Testing:
```bash
# Test validation paths with invalid inputs (suppressed output)
/plan --complexity 5 >/dev/null 2>&1
/debug --file /nonexistent/path >/dev/null 2>&1

# Verify no preprocessing errors in validation output
PLAN_ERRORS=$(grep -c "!: command not found" .claude/plan-output.md 2>/dev/null || echo 0)
DEBUG_ERRORS=$(grep -c "!: command not found" .claude/debug-output.md 2>/dev/null || echo 0)

if [ "$PLAN_ERRORS" -eq 0 ] && [ "$DEBUG_ERRORS" -eq 0 ]; then
  echo "✓ Phase 3 validation passed (0 errors in validation output)"
else
  echo "❌ Phase 3 validation failed ($PLAN_ERRORS plan errors, $DEBUG_ERRORS debug errors)"
  exit 1
fi
```

**Expected Duration**: 2 hours

### Phase 4: Fix File Operations and Function Call Patterns [COMPLETE]
dependencies: [3]

**Objective**: Replace all remaining `if !` patterns in file operations, function calls, and grep checks

**Complexity**: Low

Tasks:
- [x] Fix save_completed_states_to_state patterns (10 instances: build:3, debug:3, plan:2, repair:2, research:1, revise:2)
- [x] Fix initialize_workflow_paths patterns (5 instances: debug:1, optimize-claude:1, plan:1, repair:1, research:1)
- [x] Fix grep -q patterns (11 instances: build:1, expand:8, plan:1, setup:1)
- [x] Fix main_conversion pattern in convert-docs.md (1 instance)
- [x] Verify all if ! and elif ! patterns eliminated (0 remaining)
- [x] Run comprehensive validation across all command files

Testing:
```bash
# Test file operations and function calls (suppressed output)
/build test-plan.md --dry-run >/dev/null 2>&1
/repair --since 1h >/dev/null 2>&1
/convert-docs test-input test-output >/dev/null 2>&1
/setup --force >/dev/null 2>&1

# Verify no preprocessing errors (single summary)
total_errors=0
for file in .claude/*-output.md; do
  [ -f "$file" ] || continue
  count=$(grep -c "!: command not found" "$file" 2>/dev/null || echo 0)
  total_errors=$((total_errors + count))
done

if [ $total_errors -eq 0 ]; then
  echo "✓ Phase 4 validation passed (0 errors across all output files)"
else
  echo "❌ Phase 4 validation failed ($total_errors total errors)"
  exit 1
fi
```

**Expected Duration**: 1.5 hours

### Phase 5: Create Automated Detection Test [COMPLETE]
dependencies: [4]

**Objective**: Implement test to detect prohibited patterns and prevent future regressions

**Complexity**: Low

Tasks:
- [x] Create `.claude/tests/test_no_if_negation_patterns.sh` with grep-based detection
- [x] Source error-handling.sh and initialize error log in test script
- [x] Set CLAUDE_TEST_MODE=1 to route errors to test log
- [x] Implement test isolation with CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR overrides
- [x] Add cleanup trap to ensure test directory removal on all exit paths
- [x] Export COMMAND_NAME="test_no_if_negation_patterns" for error context
- [x] Log violations via log_command_error() with file/line context
- [x] Test script detects `if !` patterns in command files
- [x] Test script detects `elif !` patterns in command files
- [x] Test script reports file names and line numbers for violations
- [x] Update `.claude/tests/README.md` to document test purpose and usage
- [x] Add test to `.claude/tests/run_all_tests.sh` test suite (if applicable)
- [x] Run test to verify zero violations after all fixes
- [x] Verify test isolation (no production directory pollution)

Testing:
```bash
#!/usr/bin/env bash
# test_no_if_negation_patterns.sh - Detect prohibited negation patterns

set -euo pipefail

# Enable test mode for error log isolation
export CLAUDE_TEST_MODE=1

# Setup test isolation directories
TEST_ROOT="/tmp/test_no_if_negation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap (removes test directories on all exit paths)
cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# Source error handling library (test mode routes to test log)
source "${HOME}/.config/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize error log (creates .claude/tests/logs/test-errors.jsonl)
ensure_error_log_exists

# Set metadata for error logging
COMMAND_NAME="test_no_if_negation_patterns"
WORKFLOW_ID="test_$(date +%s)"
USER_ARGS="detect if ! patterns"
export COMMAND_NAME WORKFLOW_ID USER_ARGS

# Detection logic searches REAL command files (not test directory)
violations_found=0

while IFS=: read -r file line content; do
  violations_found=$((violations_found + 1))

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Prohibited 'if !' pattern found" \
    "pattern_detection" \
    "$(jq -n --arg file "$file" --argjson line "$line" --arg pattern "$content" \
      '{file: $file, line: $line, pattern: $pattern}')"

  echo "❌ $file:$line:$content"
done < <(grep -rn "if !" "${HOME}/.config/.claude/commands/"*.md 2>/dev/null)

# Check elif ! patterns
while IFS=: read -r file line content; do
  violations_found=$((violations_found + 1))

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Prohibited 'elif !' pattern found" \
    "pattern_detection" \
    "$(jq -n --arg file "$file" --argjson line "$line" --arg pattern "$content" \
      '{file: $file, line: $line, pattern: $pattern}')"

  echo "❌ $file:$line:$content"
done < <(grep -rn "elif !" "${HOME}/.config/.claude/commands/"*.md 2>/dev/null)

# Exit based on violations
if [ $violations_found -eq 0 ]; then
  echo "✓ No prohibited negation patterns found"
  exit 0
else
  echo "❌ Found $violations_found prohibited negation patterns"
  echo "Review test errors: /errors --log-file .claude/tests/logs/test-errors.jsonl"
  exit 1
fi

# Cleanup runs automatically via trap
```

**Isolation Verification**:
```bash
# Verify test does NOT create directories in production specs/
before_count=$(find .claude/specs -type d 2>/dev/null | wc -l)
bash .claude/tests/test_no_if_negation_patterns.sh
after_count=$(find .claude/specs -type d 2>/dev/null | wc -l)

if [ "$before_count" -ne "$after_count" ]; then
  echo "❌ Test created production directories (isolation violated)"
  exit 1
else
  echo "✓ Test isolation verified (no production directory pollution)"
fi
```

**jq Filter Safety Note**:
All jq filters in error logging use explicit parentheses for pipe operations in boolean context to ensure correct operator precedence. Example:
```bash
# CORRECT: Explicit parentheses for pipe in boolean context
jq 'select(.error_type == "validation_error" and (.error_message | contains("if !")))'

# WRONG: Implicit precedence causes type error
jq 'select(.error_type == "validation_error" and .error_message | contains("if !"))'
```

**Expected Duration**: 0.5 hours

### Phase 6: Update Standards and Documentation [COMPLETE]
dependencies: [5]

**Objective**: Prevent future occurrences through documentation and standards updates

**Complexity**: Low

Tasks:
- [x] Add "Prohibited Patterns" section to `.claude/docs/reference/standards/command-authoring.md`
- [x] Document `if !` and `elif !` prohibition with rationale
- [x] Include exit code capture pattern as required alternative
- [x] Add code examples showing before/after transformations
- [x] Update `.claude/docs/troubleshooting/bash-tool-limitations.md` with reference to fixes
- [x] Update `.claude/docs/reference/standards/testing-protocols.md` with reference to new test
- [x] Document test in "Claude Code Testing" section with purpose and pattern
- [x] Document test automation in testing standards
- [x] Create implementation summary documenting 52 fixes across 8 files

Testing:
```bash
# Verify documentation updates (suppressed output)
grep -q "Prohibited Patterns" .claude/docs/reference/standards/command-authoring.md 2>/dev/null
AUTHORING_CHECK=$?

grep -q "if !" .claude/docs/reference/standards/command-authoring.md 2>/dev/null
IF_CHECK=$?

grep -A 5 "exit code capture" .claude/docs/reference/standards/command-authoring.md >/dev/null 2>&1
EXAMPLE_CHECK=$?

grep -q "test_no_if_negation_patterns" .claude/docs/reference/standards/testing-protocols.md 2>/dev/null
TEST_DOC_CHECK=$?

# Single summary line
if [ $AUTHORING_CHECK -eq 0 ] && [ $IF_CHECK -eq 0 ] && [ $EXAMPLE_CHECK -eq 0 ] && [ $TEST_DOC_CHECK -eq 0 ]; then
  echo "✓ Phase 6 documentation validation passed (all required updates present)"
else
  echo "❌ Phase 6 documentation validation failed (authoring:$AUTHORING_CHECK if:$IF_CHECK example:$EXAMPLE_CHECK test:$TEST_DOC_CHECK)"
  exit 1
fi
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Each command file modification validated independently
- Specific test cases for state transitions, validations, file operations
- Exit code capture pattern correctness verified

### Integration Testing
- Run complete workflows through each modified command
- Verify output files contain zero "!: command not found" errors
- Test error paths and validation failures

### Regression Testing
- Run existing test suite to ensure no breakage
- Verify all state machine transitions still work correctly
- Confirm error handling behavior unchanged

### Error Recovery Workflow
If validation failures occur during implementation:

1. **Query Error Log**: Use `/errors --command validate_bash_history_fix` to view validation errors
2. **Analyze Patterns**: Review error details to identify systematic issues
3. **Debug Specific Files**: Focus remediation on files with highest error counts
4. **Re-test Incrementally**: Run detection test after each fix to verify progress
5. **Repair Workflow**: If systematic issues found, use `/repair --type validation_error` to create fix plan

**Error Log Queries**:
```bash
# View all validation errors from this implementation
/errors --command validate_bash_history_fix --summary

# View test detection errors
/errors --command test_no_if_negation_patterns --limit 20

# Analyze error trends across test runs
/errors --type validation_error --since 1h
```

### Validation Commands
```bash
# Comprehensive validation script with error logging
validate_fix() {
  # Source error handling for validation logging
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2
    exit 1
  }
  ensure_error_log_exists

  COMMAND_NAME="validate_bash_history_fix"
  WORKFLOW_ID="validate_$(date +%s)"
  USER_ARGS="validate all fixes"
  export COMMAND_NAME WORKFLOW_ID USER_ARGS

  local errors=0

  # Check for remaining prohibited patterns (log violations)
  if grep -n "if !" .claude/commands/*.md 2>/dev/null; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Found remaining 'if !' patterns after remediation" \
      "validation_script" \
      '{}'

    echo "❌ Found remaining 'if !' patterns"
    errors=$((errors + 1))
  fi

  if grep -n "elif !" .claude/commands/*.md 2>/dev/null; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Found remaining 'elif !' patterns after remediation" \
      "validation_script" \
      '{}'

    echo "❌ Found remaining 'elif !' patterns"
    errors=$((errors + 1))
  fi

  # Run automated detection test
  bash .claude/tests/test_no_if_negation_patterns.sh
  TEST_EXIT=$?
  if [ $TEST_EXIT -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Detection test failed with exit code $TEST_EXIT" \
      "validation_script" \
      "$(jq -n --argjson exit_code "$TEST_EXIT" '{exit_code: $exit_code}')"

    echo "❌ Detection test failed"
    errors=$((errors + 1))
  fi

  # Test each command and check output (with output suppression)
  for cmd in plan debug build repair research; do
    /$cmd "validation test" --complexity 1 >/dev/null 2>&1
    OUTPUT_FILE=".claude/${cmd}-output.md"

    if [ -f "$OUTPUT_FILE" ]; then
      ERROR_COUNT=$(grep -c "!: command not found" "$OUTPUT_FILE" 2>/dev/null || echo 0)
      if [ "$ERROR_COUNT" -gt 0 ]; then
        log_command_error \
          "$COMMAND_NAME" \
          "$WORKFLOW_ID" \
          "$USER_ARGS" \
          "validation_error" \
          "Found history expansion errors in command output" \
          "validation_script" \
          "$(jq -n --arg cmd "$cmd" --argjson count "$ERROR_COUNT" '{command: $cmd, error_count: $count}')"

        echo "❌ Found $ERROR_COUNT errors in $OUTPUT_FILE"
        errors=$((errors + 1))
      fi
    fi
  done

  if [ $errors -eq 0 ]; then
    echo "✓ All validations passed"
    return 0
  else
    echo "❌ $errors validation(s) failed"
    echo "Review errors: /errors --command validate_bash_history_fix"
    return 1
  fi
}

validate_fix
```

## Documentation Requirements

### Files to Update
1. `.claude/docs/reference/standards/command-authoring.md` (exists, add section)
   - Path verified in directory-organization.md:96
   - Add "Prohibited Patterns" section
   - Document exit code capture requirement
   - Include transformation examples

2. `.claude/docs/troubleshooting/bash-tool-limitations.md`
   - Add reference to this implementation
   - Link to automated detection test
   - Update historical context

3. `.claude/docs/reference/standards/testing-protocols.md`
   - Update "Claude Code Testing" section
   - Document test_no_if_negation_patterns.sh purpose and pattern
   - Add reference to test file location

4. `.claude/tests/README.md`
   - Document new test_no_if_negation_patterns.sh
   - Describe test purpose and usage
   - Link to command-authoring.md prohibited patterns section

5. `.claude/tests/test_no_if_negation_patterns.sh` (new file)
   - Header documentation with purpose
   - Error logging integration
   - Test isolation implementation
   - Usage instructions
   - Example output

6. `.claude/tests/run_all_tests.sh` (if applicable)
   - Add test_no_if_negation_patterns.sh to test suite
   - Ensure test runs in CI/CD workflow

7. Implementation summary (to be created)
   - Total fixes: 52 instances across 8 files
   - Pattern categories addressed
   - Validation methodology
   - Test results
   - Error logging integration details

### Documentation Standards
- Follow existing documentation format in .claude/docs/
- Use code blocks with bash syntax highlighting
- Include clear before/after examples
- Cross-reference related documentation

## Dependencies

### Prerequisites
- Access to all 8 command files for editing
- Bash tool for testing command execution
- Grep tool for pattern detection and validation

### External Dependencies
None - all changes are internal to command bash blocks

### Integration Points
- Command output files (debug-output.md, plan-output.md, etc.)
- State machine transition functions (sm_transition, sm_init)
- Validation functions (complexity checks, path validations)
- Test suite integration for automated detection

## Risk Assessment

### Low Risk
- Changes are localized to bash syntax patterns
- Exit code capture is well-documented standard
- No functional logic changes required
- Extensive historical precedent (specs 620, 717, 864)

### Mitigation Strategies
- Test each command individually after modification
- Verify error handling behavior unchanged
- Run complete workflow tests before proceeding to next phase
- Maintain backup of original files during edits

## Notes

This plan addresses a cosmetic but user-visible issue affecting command output quality. The fix applies a well-established pattern (exit code capture) documented in bash-tool-limitations.md and proven in multiple prior implementations. The phased approach prioritizes visible errors first, then systematically addresses all instances by category.

**Standards Conformance**:
This plan has been revised to integrate ALL .claude/docs/ standards per conformance analysis report (001_plan_conformance_analysis.md):
- ✓ Centralized error logging integration (error-handling.md)
- ✓ Output suppression patterns (output-formatting.md)
- ✓ Test isolation standards (testing-protocols.md)
- ✓ jq filter safety (testing-protocols.md)
- ✓ Documentation requirements (directory-organization.md)

**Root Cause Reference**:
The bash history expansion timing issue is documented in bash-tool-limitations.md:320-370. Preprocessing-stage history expansion occurs BEFORE runtime `set +H` can take effect, making the exit code capture pattern the ONLY viable solution. See bash-tool-limitations.md:329-353 for complete pattern documentation.

**Historical Context**:
Similar fixes implemented in Specs 620, 641, 672, 685, 700, 717 with 47/47 test pass rate. This implementation extends the pattern systematically across all remaining command files.

**Complexity Score Calculation**:
- Base (fix): 3
- Tasks: 32 / 2 = 16
- Files: 8 * 3 = 24
- Integrations: 0 * 5 = 0
- **Total**: 3 + 16 + 24 + 0 = 43

Since complexity score is <50, Level 0 (single file) structure is appropriate. However, if implementation reveals additional complexity, use `/expand` to create phase-level detail files.
