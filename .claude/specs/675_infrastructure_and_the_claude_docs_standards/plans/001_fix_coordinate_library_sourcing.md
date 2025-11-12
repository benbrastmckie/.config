# Implementation Plan: Fix Library Sourcing Order in /coordinate Command

## Metadata
- **Plan ID**: 675-001
- **Created**: 2025-11-11
- **Status**: Complete
- **Complexity**: Medium (5/10)
- **Estimated Time**: 3-4 hours
- **Actual Time**: ~2 hours
- **Research Reports**:
  - `/home/benjamin/.config/.claude/specs/675_infrastructure_and_the_claude_docs_standards/reports/001_library_sourcing_order_analysis.md`
  - `/home/benjamin/.config/.claude/specs/675_infrastructure_and_the_claude_docs_standards/reports/002_verification_checkpoint_patterns.md`
  - `/home/benjamin/.config/.claude/specs/675_infrastructure_and_the_claude_docs_standards/reports/003_bash_block_execution_constraints.md`
  - `/home/benjamin/.config/.claude/specs/675_infrastructure_and_the_claude_docs_standards/reports/004_error_handling_integration.md`

## Executive Summary

The /coordinate command has a critical library sourcing order bug where `verify_state_variable()` and `handle_state_error()` functions are called before the libraries defining them are sourced. Specifically:

- **Lines 155, 164, 237**: Call `verify_state_variable()`
- **Lines 162, 167, 209**: Call `handle_state_error()`
- **Line 265**: Sources `verification-helpers.sh` (TOO LATE - after calls at lines 155, 164, 237)
- **Line 169**: Sources `error-handling.sh` via `source_required_libraries()` (TOO LATE - after calls at lines 162, 167)

This causes "command not found" errors that terminate workflow initialization immediately.

## Root Cause Analysis

### Current Problematic Sequence

```bash
# Lines 88-127: Source workflow-state-machine.sh and state-persistence.sh
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Lines 155, 162: PREMATURE CALLS - Functions not yet available
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted" 1
}

# Line 169: Source error-handling.sh (via source_required_libraries)
source_required_libraries "${REQUIRED_LIBS[@]}"

# Line 265: Source verification-helpers.sh (via direct sourcing)
source "${LIB_DIR}/verification-helpers.sh"
```

### Why This Is Critical

1. **Subprocess Isolation**: Each bash block runs in a separate process, so functions must be sourced before use
2. **Fail-Fast Philosophy**: Errors must be detected immediately with clear diagnostics
3. **State Persistence**: Verification checkpoints ensure 100% file creation reliability
4. **Workflow Blocking**: Bug prevents ALL /coordinate workflows from initializing

## Solution Strategy

Move error-handling.sh and verification-helpers.sh sourcing to immediately after state-persistence.sh (before any function calls). This ensures all three critical libraries are available for:
- State machine operations (workflow-state-machine.sh)
- State persistence (state-persistence.sh)
- Error handling (error-handling.sh)
- Verification checkpoints (verification-helpers.sh)

## Phase Overview

| Phase | Description | Dependencies | Time Est. |
|-------|-------------|--------------|-----------|
| 1 | Audit current library usage | None | 30 min |
| 2 | Implement early library sourcing | Phase 1 | 45 min |
| 3 | Update all orchestration commands | Phase 2 | 60 min |
| 4 | Create validation tests | Phase 2 | 45 min |
| 5 | Test fixes with /coordinate | Phase 2,3,4 | 30 min |
| 6 | Document sourcing best practices | Phase 5 | 30 min |

**Total Estimated Time**: 3 hours 30 minutes

---

## Phase 1: Audit Current Library Usage [COMPLETED]

**Objective**: Identify all premature function calls and current sourcing patterns across coordinate.md

**Tasks**:
- [x] 1.1: Create comprehensive function call inventory
  - Find all `verify_state_variable()` calls with line numbers
  - Find all `verify_state_variables()` calls with line numbers
  - Find all `handle_state_error()` calls with line numbers
  - Find all `verify_file_created()` calls with line numbers

- [x] 1.2: Map current library sourcing locations
  - Document line 88-105 (state machine libraries)
  - Document line 169 (source_required_libraries call)
  - Document line 265 (direct verification-helpers.sh sourcing)
  - Identify any other library sourcing patterns

- [x] 1.3: Analyze dependency chain
  - Verify `handle_state_error()` requires `append_workflow_state()` (from state-persistence.sh)
  - Verify `verify_state_variable()` requires `STATE_FILE` variable (from state-persistence.sh)
  - Confirm no circular dependencies exist

- [x] 1.4: Create dependency graph
  - Document which functions depend on which libraries
  - Identify minimal sourcing order that satisfies all dependencies
  - Validate against bash block execution model constraints

**Completion Criteria**:
- Complete function call inventory documented
- Current sourcing pattern mapped with line numbers
- Dependency chain validated
- No circular dependencies found

**Verification**:
```bash
# Count premature calls (should be 0 after fix)
grep -n "verify_state_variable\|handle_state_error" \
  /home/benjamin/.config/.claude/commands/coordinate.md | \
  head -20

# Verify current sourcing locations
grep -n "source.*verification-helpers\|source.*error-handling" \
  /home/benjamin/.config/.claude/commands/coordinate.md
```

---

## Phase 2: Implement Early Library Sourcing in /coordinate [COMPLETED]

**Objective**: Move error-handling.sh and verification-helpers.sh sourcing to immediately after state-persistence.sh

**Dependencies**: Phase 1

**Tasks**:
- [x] 2.1: Add early library sourcing block
  - Insert after line 105 (after state-persistence.sh sourcing)
  - Add error-handling.sh sourcing with validation
  - Add verification-helpers.sh sourcing with validation
  - Include fail-fast error handling for missing libraries

- [x] 2.2: Remove duplicate sourcing
  - Remove lines 263-266 (duplicate verification-helpers.sh sourcing)
  - Verify no double-sourcing issues (source guards should handle this)
  - Keep source_required_libraries() call at line 169 for other libraries

- [x] 2.3: Update sourcing comments
  - Add comment explaining sourcing order rationale
  - Reference bash block execution model documentation
  - Note dependency requirements (state-persistence → error-handling/verification)

- [x] 2.4: Validate conditional initialization pattern
  - Ensure `WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"` pattern preserved
  - Verify state variables use conditional initialization
  - Check that library re-sourcing doesn't overwrite loaded state

**Implementation Details**:

```bash
# CURRENT CODE (lines 99-105):
if [ -f "${LIB_DIR}/state-persistence.sh" ]; then
  : # File exists, continue
else
  echo "ERROR: state-persistence.sh not found"
  exit 1
fi
source "${LIB_DIR}/state-persistence.sh"

# ADD IMMEDIATELY AFTER (new lines ~106-125):
# CRITICAL: Source error-handling.sh and verification-helpers.sh BEFORE any function calls
# These libraries must be available for verification checkpoints and error handling
# throughout initialization (lines 155+). See bash-block-execution-model.md for rationale.

# Source error handling library (provides handle_state_error)
if [ -f "${LIB_DIR}/error-handling.sh" ]; then
  source "${LIB_DIR}/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found at ${LIB_DIR}/error-handling.sh"
  echo "Cannot proceed without error handling functions"
  exit 1
fi

# Source verification helpers library (provides verify_state_variable, verify_file_created)
if [ -f "${LIB_DIR}/verification-helpers.sh" ]; then
  source "${LIB_DIR}/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found at ${LIB_DIR}/verification-helpers.sh"
  echo "Cannot proceed without verification functions"
  exit 1
fi

# EXISTING CODE CONTINUES (line 107 becomes ~127)
# Generate unique workflow ID...
```

```bash
# DELETE LINES 263-266 (duplicate sourcing):
# Source verification helpers (must be sourced BEFORE verify_state_variables is called)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
fi
```

**Completion Criteria**:
- Early sourcing block added after state-persistence.sh
- Duplicate verification-helpers.sh sourcing removed
- Comments explain sourcing order rationale
- All validation checks include fail-fast error messages

**Verification**:
```bash
# Verify sourcing order (error-handling and verification should appear early)
grep -n "^source.*\.sh" /home/benjamin/.config/.claude/commands/coordinate.md | head -15

# Verify duplicate sourcing removed
grep -c "verification-helpers.sh" /home/benjamin/.config/.claude/commands/coordinate.md
# Should return 1 (only one sourcing location remaining)

# Verify no premature calls remain before sourcing
awk '/^source.*verification-helpers/ {sourced=1}
     /verify_state_variable|verify_file_created/ {if(!sourced) print NR": "$0}' \
  /home/benjamin/.config/.claude/commands/coordinate.md
# Should return empty (no premature calls)
```

---

## Phase 3: Update All Orchestration Commands [COMPLETED]

**Objective**: Apply same sourcing pattern to /orchestrate and /supervise commands

**Dependencies**: Phase 2

**Tasks**:
- [x] 3.1: Audit /orchestrate command
  - Identify all function calls requiring error-handling.sh
  - Identify all function calls requiring verification-helpers.sh
  - Map current library sourcing locations
  - Document any unique patterns vs /coordinate

- [x] 3.2: Update /orchestrate sourcing pattern
  - Apply same early sourcing pattern after state-persistence.sh
  - Remove any duplicate sourcing blocks
  - Update comments to match /coordinate rationale
  - Preserve any /orchestrate-specific library requirements

- [x] 3.3: Audit /supervise command
  - Identify all function calls requiring error-handling.sh
  - Identify all function calls requiring verification-helpers.sh
  - Map current library sourcing locations
  - Document sequential vs parallel coordination patterns

- [x] 3.4: Update /supervise sourcing pattern
  - Apply same early sourcing pattern after state-persistence.sh
  - Remove any duplicate sourcing blocks
  - Update comments to match /coordinate rationale
  - Preserve /supervise-specific minimal reference architecture

- [x] 3.5: Cross-command consistency check
  - Verify all three commands use identical sourcing order
  - Confirm comments reference same documentation
  - Validate no command-specific exceptions needed

**Files to Update**:
- `/home/benjamin/.config/.claude/commands/orchestrate.md`
- `/home/benjamin/.config/.claude/commands/supervise.md`

**Standard Pattern (All Commands)**:
```bash
# 1. Source state machine core
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Source error handling and verification (BEFORE any function calls)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Source remaining libraries via consolidated function
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Completion Criteria**:
- All three orchestration commands use identical sourcing order
- No premature function calls in any command
- Comments explain rationale and reference documentation
- Command-specific requirements preserved (if any)

**Verification**:
```bash
# Verify sourcing order consistency across all commands
for cmd in coordinate orchestrate supervise; do
  echo "=== $cmd ==="
  grep -n "^source.*error-handling.sh" \
    /home/benjamin/.config/.claude/commands/${cmd}.md
  grep -n "^source.*verification-helpers.sh" \
    /home/benjamin/.config/.claude/commands/${cmd}.md
done

# Verify no premature calls in any command
for cmd in coordinate orchestrate supervise; do
  echo "=== Checking $cmd for premature calls ==="
  awk '/^source.*verification-helpers/ {sourced=1}
       /verify_state_variable|handle_state_error/ {if(!sourced) print FILENAME":"NR": "$0}' \
    /home/benjamin/.config/.claude/commands/${cmd}.md
done
```

---

## Phase 4: Create Validation Tests [COMPLETED]

**Objective**: Create automated tests to detect library sourcing order violations

**Dependencies**: Phase 2

**Tasks**:
- [x] 4.1: Create test_library_sourcing_order.sh
  - Extract all function names from library files
  - For each function, find first call line number
  - Find source line number for its defining library
  - Report violations where call line < source line

- [x] 4.2: Add test cases for known patterns
  - Test case: verify_state_variable before verification-helpers.sh sourcing
  - Test case: handle_state_error before error-handling.sh sourcing
  - Test case: verify_file_created before verification-helpers.sh sourcing
  - Test case: append_workflow_state before state-persistence.sh sourcing

- [x] 4.3: Add test to existing test suite
  - Integrate into /home/benjamin/.config/.claude/tests/
  - Add to run_all_tests.sh execution
  - Create test documentation in test file header

- [x] 4.4: Validate test detects fixed issues
  - Run test on pre-fix version (should FAIL)
  - Run test on post-fix version (should PASS)
  - Verify test output is actionable (line numbers, function names, files)

**Test Implementation**:
```bash
#!/bin/bash
# test_library_sourcing_order.sh
# Validates that library functions are sourced before being called
# Prevents "command not found" errors in orchestration commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test orchestration commands for library sourcing order violations
test_coordinate_sourcing_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Extract bash blocks and check function calls before sourcing
  # Function should be sourced before first call

  # Check verify_state_variable (from verification-helpers.sh)
  local first_call=$(grep -n "verify_state_variable" "$cmd_file" | head -1 | cut -d: -f1)
  local source_line=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)

  if [ "$first_call" -lt "$source_line" ]; then
    echo "FAIL: verify_state_variable called at line $first_call before sourcing at $source_line"
    violations=$((violations + 1))
  fi

  # Check handle_state_error (from error-handling.sh)
  first_call=$(grep -n "handle_state_error" "$cmd_file" | head -1 | cut -d: -f1)
  source_line=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)

  if [ "$first_call" -lt "$source_line" ]; then
    echo "FAIL: handle_state_error called at line $first_call before sourcing at $source_line"
    violations=$((violations + 1))
  fi

  return $violations
}

# Run tests
echo "Testing library sourcing order in orchestration commands..."
test_coordinate_sourcing_order
if [ $? -eq 0 ]; then
  echo "PASS: All functions sourced before use"
  exit 0
else
  echo "FAIL: Library sourcing order violations detected"
  exit 1
fi
```

**Completion Criteria**:
- Test script created and executable
- Test cases cover all critical functions
- Test integrated into run_all_tests.sh
- Test passes on fixed code, fails on buggy code

**Verification**:
```bash
# Run new test
bash /home/benjamin/.config/.claude/tests/test_library_sourcing_order.sh

# Verify integration into test suite
grep -q "test_library_sourcing_order" \
  /home/benjamin/.config/.claude/tests/run_all_tests.sh
echo "Integration: $?"  # Should print 0 (found)

# Verify test output is actionable
bash /home/benjamin/.config/.claude/tests/test_library_sourcing_order.sh 2>&1 | \
  grep -E "line [0-9]+"
```

---

## Phase 5: Test Fixes with /coordinate Command [COMPLETED]

**Objective**: Validate that /coordinate initializes successfully with all workflow scopes

**Dependencies**: Phase 2, 3, 4

**Tasks**:
- [x] 5.1: Test research-only workflow
  - Execute: `/coordinate "research authentication patterns"`
  - Verify initialization completes without "command not found" errors
  - Verify state persistence verification succeeds
  - Verify workflow reaches research state
  - Check that all verification checkpoints pass

- [x] 5.2: Test research-and-plan workflow
  - Execute: `/coordinate "research and plan authentication feature"`
  - Verify initialization completes successfully
  - Verify workflow transitions through research → plan states
  - Verify all verification checkpoints pass
  - Check terminal state reached correctly

- [x] 5.3: Test full-implementation workflow
  - Execute: `/coordinate "implement user authentication with JWT tokens"`
  - Verify initialization completes successfully
  - Verify workflow scope detection: full-implementation
  - Verify all required libraries loaded
  - Check Phase 0 optimization (artifact path calculation)

- [x] 5.4: Test research-and-revise workflow
  - Create a test plan file first
  - Execute: `/coordinate "revise authentication plan at /path/to/plan.md"`
  - Verify EXISTING_PLAN_PATH extraction and persistence
  - Verify all verification checkpoints pass
  - Check revision-specific logic works

- [x] 5.5: Test debug-only workflow
  - Execute: `/coordinate "debug test failures in authentication module"`
  - Verify initialization completes successfully
  - Verify workflow scope detection: debug-only
  - Check correct libraries loaded for debug scope

- [x] 5.6: Error handling validation
  - Verify `handle_state_error()` available during initialization
  - Test error handling for missing files
  - Test error handling for invalid state transitions
  - Verify retry counter tracking works correctly

**Test Cases**:

```bash
# Test Case 1: Research-only workflow
/coordinate "research bash subprocess isolation patterns"
# Expected: Initializes successfully, reaches research state, no "command not found" errors

# Test Case 2: Research-and-plan workflow
/coordinate "research and plan implementation of state persistence"
# Expected: Initializes successfully, transitions research → plan → complete

# Test Case 3: Full-implementation workflow
/coordinate "implement library sourcing order validation tests"
# Expected: Initializes successfully, scope=full-implementation, all libraries loaded

# Test Case 4: Verification checkpoint failure (simulate)
# Temporarily rename a required library to test error handling
mv .claude/lib/verification-helpers.sh{,.backup}
/coordinate "test workflow"
# Expected: Clear error message, fail-fast behavior
mv .claude/lib/verification-helpers.sh{.backup,}

# Test Case 5: State variable verification
/coordinate "test state persistence"
# Check STATE_FILE for WORKFLOW_SCOPE variable
grep "WORKFLOW_SCOPE" ~/.claude/tmp/coordinate_state_*.sh
# Expected: Variable persisted correctly
```

**Completion Criteria**:
- All 5 workflow scope tests pass
- No "command not found" errors during initialization
- All verification checkpoints pass
- Error handling validation confirms functions available
- State persistence works across bash block boundaries

**Verification**:
```bash
# Check for any "command not found" errors in recent test runs
grep -r "command not found" /home/benjamin/.config/.claude/specs/coordinate_output.md
# Should return no matches (or only historical examples)

# Verify state file contains expected variables
ls -la ~/.claude/tmp/coordinate_state_*.sh
cat ~/.claude/tmp/coordinate_state_*.sh | grep -E "WORKFLOW_SCOPE|TERMINAL_STATE|CURRENT_STATE"

# Verify all test suite tests still pass
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh
```

---

## Phase 6: Document Library Sourcing Best Practices [COMPLETED]

**Objective**: Update documentation with library sourcing standards and patterns

**Dependencies**: Phase 5

**Tasks**:
- [x] 6.1: Update bash-block-execution-model.md
  - Add section on "Function Availability and Sourcing Order"
  - Document standard sourcing pattern for orchestration commands
  - Include anti-pattern examples (calling functions before sourcing)
  - Add detection guidance (use validation scripts)

- [x] 6.2: Update coordinate-command-guide.md
  - Add troubleshooting section for "command not found" errors
  - Document correct library sourcing order
  - Explain dependency chain (state-persistence → error-handling/verification)
  - Link to bash block execution model documentation

- [x] 6.3: Update command-architecture-standards.md
  - Add standard for library sourcing order in orchestration commands
  - Specify required libraries and their dependencies
  - Document source guard pattern and why re-sourcing is safe
  - Add validation requirements (automated testing)

- [x] 6.4: Create sourcing order reference diagram
  - Visual representation of dependency chain
  - Timeline showing when each library must be available
  - Annotate with line number examples from /coordinate
  - Include in architecture documentation

**Documentation Additions**:

**bash-block-execution-model.md** (new section after line 441):
```markdown
## Function Availability and Sourcing Order

### Critical Principle
Functions must be sourced BEFORE they are called. This is obvious but frequently violated in practice due to:
1. Subprocess isolation (functions don't persist across bash blocks)
2. Implicit assumptions about library loading
3. Code review missing runtime execution order

### Standard Sourcing Order for Orchestration Commands

All orchestration commands (/coordinate, /orchestrate, /supervise) MUST use this sourcing order:

\`\`\`bash
# 1. Project directory detection (first)
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# 2. State machine core
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 3. Error handling and verification (BEFORE any checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 4. Additional libraries as needed
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# ... other libraries via source_required_libraries()
\`\`\`

### Why This Order Matters

**Dependency Chain**:
- `verify_state_variable()` requires `STATE_FILE` (from state-persistence.sh)
- `handle_state_error()` requires `append_workflow_state()` (from state-persistence.sh)
- Both functions called during initialization for verification checkpoints
- Therefore: state-persistence → error-handling/verification → checkpoints

### Anti-Pattern: Premature Function Calls

\`\`\`bash
# ❌ WRONG: Function called before library sourced
verify_state_variable "WORKFLOW_SCOPE" || exit 1

source "${LIB_DIR}/verification-helpers.sh"
\`\`\`

**Error**: `bash: verify_state_variable: command not found`

**Fix**: Source library before calling function

### Detection

Use validation script to catch sourcing order violations:
\`\`\`bash
bash .claude/tests/test_library_sourcing_order.sh
\`\`\`

See Spec 675 for complete analysis and fix implementation.
```

**coordinate-command-guide.md** (new troubleshooting section):
```markdown
## Troubleshooting

### "command not found" Errors During Initialization

**Symptom**: `/coordinate` fails with `verify_state_variable: command not found` or `handle_state_error: command not found`

**Root Cause**: Library sourcing order violation - functions called before libraries sourced

**Fix**: Verify library sourcing order in coordinate.md:
1. `workflow-state-machine.sh` and `state-persistence.sh` sourced first
2. `error-handling.sh` and `verification-helpers.sh` sourced immediately after
3. All other libraries sourced after these four
4. No function calls before library sourcing

**Verification**:
\`\`\`bash
# Check sourcing order
grep -n "^source.*error-handling.sh" .claude/commands/coordinate.md
grep -n "^source.*verification-helpers.sh" .claude/commands/coordinate.md

# Should appear before line 150 (before first function calls)
\`\`\`

**Validation**:
\`\`\`bash
bash .claude/tests/test_library_sourcing_order.sh
\`\`\`

See [Bash Block Execution Model](../concepts/bash-block-execution-model.md#function-availability-and-sourcing-order) for complete details.
```

**command-architecture-standards.md** (new Standard 15):
```markdown
## Standard 15: Library Sourcing Order

### Requirement
Orchestration commands MUST source libraries in dependency order before calling any functions from those libraries.

### Rationale
Bash block execution model enforces subprocess isolation. Functions are only available AFTER sourcing, not before. Premature function calls result in "command not found" errors.

### Standard Sourcing Pattern

\`\`\`bash
# 1. State machine foundation
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (used throughout initialization)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries as needed
source_required_libraries "${REQUIRED_LIBS[@]}"
\`\`\`

### Validation
- Automated: `test_library_sourcing_order.sh` detects violations
- Manual: Code review must verify no function calls before sourcing
- Runtime: Test with all workflow scopes before merging

### Examples
- **Compliant**: /coordinate command (Spec 675 fix)
- **Violation**: Pre-Spec-675 coordinate.md (functions called at lines 155-239 before sourcing at 265)

### References
- Spec 675: Library sourcing order fix
- bash-block-execution-model.md: Function availability section
```

**Completion Criteria**:
- bash-block-execution-model.md updated with sourcing order section
- coordinate-command-guide.md includes troubleshooting guidance
- command-architecture-standards.md defines Standard 15
- Sourcing order reference diagram created
- All documentation cross-references updated

**Verification**:
```bash
# Verify documentation additions
grep -n "Function Availability" \
  /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md

grep -n "command not found.*Troubleshooting" \
  /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md

grep -n "Standard 15.*Library Sourcing" \
  /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md

# Verify cross-references work
grep -c "Spec 675" /home/benjamin/.config/.claude/docs/**/*.md
# Should find references in multiple documentation files
```

---

## Implementation Notes

### Critical Constraints

1. **Bash Block Execution Model**:
   - Each bash block runs in separate subprocess
   - Functions don't persist across blocks
   - Libraries must be re-sourced in each block
   - Source guards make multiple sourcing safe

2. **Dependency Chain**:
   ```
   workflow-state-machine.sh
         ↓ (provides CURRENT_STATE)
   state-persistence.sh
         ↓ (provides append_workflow_state, STATE_FILE)
   error-handling.sh + verification-helpers.sh
         ↓ (use append_workflow_state, STATE_FILE)
   Verification checkpoints and error handlers
   ```

3. **Source Guard Pattern**:
   - All libraries use source guards to prevent duplicate execution
   - Multiple sourcing is safe and efficient
   - Guards check `LIBRARY_NAME_SOURCED` variable

4. **Fail-Fast Philosophy**:
   - Missing libraries must cause immediate exit with clear error
   - No silent fallbacks or graceful degradation
   - Error messages must be actionable (file paths, function names)

### Testing Strategy

**Unit Testing**:
- test_library_sourcing_order.sh validates no premature calls
- Run on all three orchestration commands
- Check for violations before and after fix

**Integration Testing**:
- Test all 5 workflow scopes (research-only, research-and-plan, full-implementation, debug-only, research-and-revise)
- Verify no "command not found" errors
- Check state persistence across bash blocks
- Validate verification checkpoints pass

**Regression Testing**:
- Existing test suite must continue passing
- No performance degradation (source guards minimize overhead)
- State machine tests validate correct transitions

**Manual Testing**:
- Execute /coordinate with various workflow descriptions
- Verify error messages are clear and actionable
- Test error handling paths (missing files, invalid state)

### Risk Assessment

**Risk Level**: LOW

**Rationale**:
- Change is localized to sourcing order (no logic changes)
- Source guards make multiple sourcing safe
- Error handling improved (functions available earlier)
- Extensive test coverage planned

**Rollback Plan**:
- Simple: revert sourcing order changes
- State: no state changes or data migrations
- Impact: isolated to initialization block

### Performance Considerations

**Initialization Overhead**:
- Early sourcing adds ~5-10ms (negligible)
- Source guards prevent redundant execution
- No impact on runtime performance after initialization

**Memory**:
- No additional memory overhead
- Functions already loaded, just earlier in sequence

**Context Window**:
- No impact on token consumption
- Verification helper functions already reduce context by 90%

### Related Specifications

- **Spec 620**: Bash history expansion fixes (subprocess isolation discovery)
- **Spec 630**: State persistence architecture (cross-block state management)
- **Spec 644**: Verification checkpoint bug patterns (grep pattern mismatch)
- **Spec 653**: WORKFLOW_SCOPE reset bug (conditional initialization)
- **Spec 672**: State-based orchestration architecture (state machine integration)

---

## Success Criteria

### Functional Requirements
- [x] All /coordinate workflow scopes initialize successfully
- [x] No "command not found" errors during initialization
- [x] All verification checkpoints pass
- [x] State persistence works across bash blocks
- [x] Error handling functions available when needed

### Non-Functional Requirements
- [x] Initialization overhead < 50ms
- [x] No regression in existing test suite
- [x] Documentation clearly explains sourcing order
- [x] Validation tests prevent future violations

### Quality Metrics
- [x] Code review: sourcing order correct
- [x] Automated tests: test_library_sourcing_order.sh passes
- [x] Integration tests: all workflow scopes work
- [x] Documentation: complete and accurate

---

## Appendix A: Function Call Inventory

### verify_state_variable() Calls
- Line 155: `verify_state_variable "WORKFLOW_SCOPE"`
- Line 164: `verify_state_variable "EXISTING_PLAN_PATH"`
- Line 237: `verify_state_variable "REPORT_PATHS_COUNT"`

### handle_state_error() Calls
- Line 140: Plan path validation failure
- Line 145: Missing plan path in description
- Line 162: Extracted plan path does not exist
- Line 167: research-and-revise requires plan path
- Line 209: Workflow initialization failure
- Line 238: REPORT_PATHS_COUNT not persisted
- Line 282: State persistence verification failure

### verify_file_created() Calls
- Lines 490-520: Research report verification (dynamic discovery pattern)
- Multiple locations in later bash blocks (research, plan, implementation phases)

### verify_state_variables() Calls
- Line 279: Multiple variable verification (REPORT_PATHS array)

---

## Appendix B: Sourcing Pattern Reference

### Standard Pattern (All Orchestration Commands)
```bash
# Lines 88-127 (coordinate.md)

# 1. State machine foundation
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (CRITICAL: before any function calls)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Workflow initialization
source "${LIB_DIR}/workflow-initialization.sh"

# 4. Additional libraries (scope-dependent)
source_required_libraries "${REQUIRED_LIBS[@]}"
```

### Re-Sourcing Pattern (Subsequent Bash Blocks)
```bash
# Lines 330-337 (coordinate.md research phase)

# Re-source libraries (functions lost across bash block boundaries)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

### Source Guard Pattern (Library Files)
```bash
# From verification-helpers.sh:11-14
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1

# ... rest of library code
```

---

## Appendix C: Error Examples

### Before Fix (Current Behavior)
```
/run/current-system/sw/bin/bash: line 368: verify_state_variable: command not found
/run/current-system/sw/bin/bash: line 369: handle_state_error: command not found
/run/current-system/sw/bin/bash: line 450: verify_state_variable: command not found

ERROR: Workflow initialization failed
```

### After Fix (Expected Behavior)
```
=== State Machine Workflow Orchestration ===

State Machine Initialized:
  Scope: research-and-plan
  Current State: research
  Terminal State: complete
  Topic Path: /home/benjamin/.config/.claude/specs/042_auth

Performance (Baseline Phase 1):
  Library loading: 145ms
  Path initialization: 52ms
  Total init overhead: 197ms

✓ Workflow description captured
✓ State machine initialized
✓ WORKFLOW_SCOPE persisted: research-and-plan
✓ REPORT_PATHS_COUNT persisted: 2
✓ State persistence verified (3 vars): verified
```

---

## Completion Checklist

- [x] Phase 1: Audit complete (function inventory, dependency graph)
- [x] Phase 2: Early sourcing implemented in /coordinate
- [x] Phase 3: All orchestration commands updated
- [x] Phase 4: Validation tests created and integrated
- [x] Phase 5: All workflow scope tests pass
- [x] Phase 6: Documentation updated with best practices
- [x] All success criteria met
- [x] Test suite passes (run_all_tests.sh)
- [x] Code review complete
- [x] Git commit with tests and documentation

**Final Verification Command**:
```bash
# Run complete validation
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh && \
  /coordinate "test research and plan workflow" && \
  echo "✓ All validations passed - ready for commit"
```
