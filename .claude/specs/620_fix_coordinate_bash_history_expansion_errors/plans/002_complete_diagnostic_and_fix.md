# Complete Diagnostic and Fix Plan: /coordinate Execution Failures

## ✅ IMPLEMENTATION COMPLETE

**Status**: COMPLETE AND VALIDATED (2025-11-09)
**All Phases**: 0, 1, 2 completed with runtime testing
**Summary**: [004_implementation_summary.md](../reports/004_implementation_summary.md)

---

## Metadata
- **Date**: 2025-11-09
- **Feature**: Root Cause Diagnosis and Complete Fix for /coordinate Bash Execution Failures
- **Scope**: Systematic diagnosis and resolution with mandatory runtime validation
- **Estimated Phases**: 5 phases (diagnostic-first, test-driven approach)
- **Estimated Hours**: 6-10 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - 620 (This spec - coordinate bash execution failures)
  - 617 (Fixed ${!...} patterns in library files)
  - 613 (Fixed coordinate.md state machine errors)
  - 602 (State-based orchestration refactor)
- **Diagnostic Report**: [002_diagnostic_analysis.md](../reports/002_diagnostic_analysis.md)
- **Failed Plan**: [001_coordinate_history_expansion_fix.md](001_coordinate_history_expansion_fix.md) - Marked complete but doesn't work

## Executive Summary

**Problem**: The previous implementation plan (001) was marked COMPLETED based on code analysis alone. When `/coordinate` is actually executed, it fails with the exact errors the plan was supposed to fix.

**Root Cause**:
1. Testing was deferred and eventually replaced with code analysis instead of runtime validation
2. Fixes addressed bash block boundaries but missed first block initialization failures
3. The actual source of "!: command not found" errors was never diagnosed

**This Plan's Approach**:
1. **Phase 0**: Systematic root cause diagnosis using four hypotheses (REQUIRED before any fixes)
2. **Phase 1**: Fix first bash block based on diagnosis findings
3. **Phase 2**: Runtime validation with comprehensive test suite
4. **Phase 3**: Integration with existing infrastructure improvements
5. **Phase 4**: Documentation and process improvements

**Key Principles**:
- ✅ **MANDATORY runtime testing** at each phase completion
- ✅ **Diagnosis before fixes** - understand root cause first
- ✅ **Test-driven approach** - test fails, implement fix, test passes
- ✅ **No deferred testing** - validate immediately, not later
- ✅ **Honest status reporting** - "implemented but untested" ≠ "complete"

## Success Criteria

- [ ] Root cause of "!: command not found" identified and documented
- [ ] `/coordinate` executes successfully with test workflows (research-only, research-and-plan)
- [ ] Zero "!: command not found" errors
- [ ] handle_state_error function available in first bash block
- [ ] TOPIC_PATH properly initialized
- [ ] All library functions available across bash block boundaries
- [ ] State machine transitions work correctly
- [ ] Existing functionality preserved (no regressions)
- [ ] Comprehensive test suite passes (runtime validation)
- [ ] Process improvements documented to prevent future failures

## Phase 0: Root Cause Diagnosis (CRITICAL - DO FIRST)

**Objective**: Systematically test four hypotheses to identify exact source of "!: command not found" errors

**Complexity**: Medium-High

**Priority**: CRITICAL - DO NOT SKIP

**Why This Phase Exists**: Previous plan attempted fixes without understanding root cause. This led to implementing solutions that don't address the actual problem.

### Tasks

#### Task 0.1: Hypothesis A - Hidden/Non-printable Characters

Test whether coordinate.md or library files contain non-printable `!` characters:

**Test Commands**:
```bash
# Check coordinate.md for non-printable characters around suspected lines
od -c .claude/commands/coordinate.md | grep -C 3 '!'

# Check for hidden characters in first bash block (lines 23-163)
sed -n '23,163p' .claude/commands/coordinate.md | od -A n -t x1z | grep -E '(21|0d|0a)'
# 21 = !, 0d = CR, 0a = LF

# Check library files for non-printable characters
for lib in workflow-detection.sh workflow-scope-detection.sh unified-logger.sh \
           unified-location-detection.sh overview-synthesis.sh error-handling.sh; do
  echo "=== $lib ==="
  od -c ".claude/lib/$lib" | grep -C 2 '!' | head -20
done
```

**Expected Outcomes**:
- If hypothesis A is correct: Will find non-printable `!` (0x21) characters in unexpected locations
- If hypothesis A is wrong: Only printable `!` in expected locations (e.g., in comments, strings)

**Decision Point**:
- ✅ If non-printable chars found → Remove them, test coordinate.md, proceed to Phase 1
- ❌ If not found → Continue to Task 0.2

**Completion Criteria**:
- [ ] Ran all diagnostic commands
- [ ] Documented findings in diagnostic report section
- [ ] Made decision: hypothesis confirmed or rejected

---

#### Task 0.2: Hypothesis B - Bash Tool Transformation Error

Test whether Claude's Bash tool introduces errors during markdown processing:

**Test Procedure**:
```bash
# Extract first bash block from coordinate.md to standalone script
awk '/^```bash$/,/^```$/' .claude/commands/coordinate.md | \
  sed '1d;$d' > /tmp/coordinate_first_block.sh

# Add shebang and make executable
echo '#!/usr/bin/env bash' | cat - /tmp/coordinate_first_block.sh > /tmp/test_coordinate.sh
chmod +x /tmp/test_coordinate.sh

# Execute directly in terminal (NOT via Claude's Bash tool)
bash -x /tmp/test_coordinate.sh "Test research workflow" 2>&1 | tee /tmp/coordinate_direct_test.log

# Compare: Does it work when run directly vs via Claude?
```

**Expected Outcomes**:
- If hypothesis B is correct: Direct execution succeeds, Claude Bash tool execution fails
- If hypothesis B is wrong: Direct execution also fails with same errors

**Decision Point**:
- ✅ If direct execution works → Problem is in Bash tool processing, requires workaround in coordinate.md
- ❌ If direct execution fails → Continue to Task 0.3

**Completion Criteria**:
- [ ] Extracted bash block to standalone script
- [ ] Executed script directly in terminal
- [ ] Compared results: direct vs Claude Bash tool
- [ ] Documented findings

---

#### Task 0.3: Hypothesis C - Library File Issues

Test whether sourced libraries have `${!...}` patterns that Spec 617 missed:

**Test Procedure**:
```bash
# Source each library individually in clean shell
for lib in workflow-detection.sh workflow-scope-detection.sh unified-logger.sh \
           unified-location-detection.sh overview-synthesis.sh error-handling.sh; do
  echo "=== Testing $lib ==="

  # Test in clean subshell
  (
    set -euo pipefail
    CLAUDE_PROJECT_DIR="/home/benjamin/.config"

    if source ".claude/lib/$lib"; then
      echo "✓ $lib sourced successfully"
    else
      echo "✗ $lib failed to source (exit code: $?)"
    fi
  ) 2>&1 | tee -a /tmp/library_sourcing_test.log
done

# Search for ${!...} patterns in all libraries
echo "=== Searching for indirect expansion patterns ==="
for lib in .claude/lib/*.sh; do
  # Use grep with fixed strings to avoid regex issues
  if grep -F '$'{'{!'"" "$lib" >/dev/null 2>&1; then
    echo "Found in: $lib"
    grep -n '$'{'{!'"" "$lib" || true
  fi
done

# Test library-sourcing.sh specifically (where source_required_libraries is defined)
echo "=== Testing library-sourcing.sh function ==="
(
  set -euo pipefail
  CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  source .claude/lib/library-sourcing.sh

  # Test the function with research-and-plan scope libraries
  REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" \
                 "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")

  if source_required_libraries "${REQUIRED_LIBS[@]}"; then
    echo "✓ source_required_libraries succeeded"

    # Verify handle_state_error is available
    if declare -F handle_state_error >/dev/null; then
      echo "✓ handle_state_error function available"
    else
      echo "✗ handle_state_error NOT available (error-handling.sh didn't load)"
    fi
  else
    echo "✗ source_required_libraries failed"
  fi
) 2>&1 | tee -a /tmp/library_sourcing_test.log
```

**Expected Outcomes**:
- If hypothesis C is correct: One or more libraries fail to source, or contain ${!...} patterns
- If hypothesis C is wrong: All libraries source successfully in isolation

**Decision Point**:
- ✅ If libraries fail → Fix the failing library, re-test, proceed to Phase 1
- ❌ If all libraries work → Continue to Task 0.4

**Completion Criteria**:
- [ ] Tested each library individually
- [ ] Searched for ${!...} patterns
- [ ] Tested source_required_libraries function
- [ ] Documented which libraries work/fail

---

#### Task 0.4: Hypothesis D - Environment-Specific Bash Behavior

Test whether NixOS bash has non-standard history expansion behavior:

**Test Procedure**:
```bash
# Check bash version and configuration
echo "=== Bash Environment ==="
bash --version
echo "Bash path: $(which bash)"
echo "Bash path (full): $(readlink -f $(which bash))"

# Check if history expansion is enabled
bash -c 'set -o | grep histexpand'

# Test history expansion in non-interactive shell (should be disabled)
bash -c 'echo "test!" | cat'  # Should work without errors

# Test with coordinate.md patterns
bash -c '
  set -euo pipefail
  REQUIRED_LIBS=("workflow-detection.sh" "error-handling.sh")
  echo "Array defined: ${REQUIRED_LIBS[@]}"
'

# Check NixOS-specific bash configuration
if [ -f /etc/bashrc ]; then
  echo "=== /etc/bashrc ==="
  grep -E 'hist|expand|!' /etc/bashrc | head -20
fi

# Test same code on standard Linux (if available)
# docker run -it --rm -v "$PWD:/work" -w /work ubuntu:22.04 bash -c '
#   # Run same coordinate.md first block test
# '
```

**Expected Outcomes**:
- If hypothesis D is correct: NixOS bash has histexpand enabled or non-standard behavior
- If hypothesis D is wrong: Bash behavior is standard, history expansion is disabled

**Decision Point**:
- ✅ If NixOS-specific issue → Add environment-specific workaround (e.g., explicit set +H)
- ❌ If standard behavior → Root cause is elsewhere, requires deeper investigation

**Completion Criteria**:
- [ ] Checked bash version and configuration
- [ ] Tested history expansion behavior
- [ ] Compared with standard Linux (if possible)
- [ ] Documented environment-specific findings

---

#### Task 0.5: Consolidate Diagnosis Results

**Consolidation Steps**:
```bash
# Create diagnosis summary
cat > /tmp/diagnosis_summary.md << 'EOF'
# Root Cause Diagnosis Summary

## Hypothesis Testing Results

### Hypothesis A: Hidden/Non-printable Characters
- **Status**: [CONFIRMED / REJECTED]
- **Evidence**: [findings from Task 0.1]
- **Action**: [if confirmed: what to fix]

### Hypothesis B: Bash Tool Transformation Error
- **Status**: [CONFIRMED / REJECTED]
- **Evidence**: [findings from Task 0.2]
- **Action**: [if confirmed: workaround needed]

### Hypothesis C: Library File Issues
- **Status**: [CONFIRMED / REJECTED]
- **Evidence**: [findings from Task 0.3]
- **Action**: [if confirmed: which library to fix]

### Hypothesis D: Environment-Specific Bash Behavior
- **Status**: [CONFIRMED / REJECTED]
- **Evidence**: [findings from Task 0.4]
- **Action**: [if confirmed: environment workaround]

## Root Cause Identified

**Primary Cause**: [Based on hypothesis testing]

**Secondary Contributing Factors**: [if any]

**Recommended Fix Strategy**: [specific approach for Phase 1]

## Validation Plan

How we'll know the fix works:
1. [Test case 1]
2. [Test case 2]
3. [Test case 3]

EOF

# Update diagnostic analysis report with findings
cat /tmp/diagnosis_summary.md >> .claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md
```

**Expected Outcomes**:
- Clear identification of root cause
- Specific fix strategy for Phase 1
- Validation test cases defined

**Decision Gate**: **DO NOT PROCEED TO PHASE 1** until root cause is identified

**Completion Criteria**:
- [ ] All four hypotheses tested
- [ ] Root cause identified with confidence
- [ ] Diagnosis summary documented
- [ ] Fix strategy defined
- [ ] Validation test cases created

---

### Phase 0 Testing

**Mandatory Runtime Validation**:
```bash
# All diagnostic commands must be run and results documented
# Expected: One of the four hypotheses will be confirmed
# If none confirmed: Expand investigation (hypothesis E, F, etc.)

# Success criteria:
# ✓ Root cause identified
# ✓ Evidence documented
# ✓ Fix strategy defined
# ✗ If root cause unknown: DO NOT proceed, expand diagnosis
```

**Phase 0 Completion Checklist**:
- [ ] Task 0.1 completed (Hypothesis A tested)
- [ ] Task 0.2 completed (Hypothesis B tested)
- [ ] Task 0.3 completed (Hypothesis C tested)
- [ ] Task 0.4 completed (Hypothesis D tested)
- [ ] Task 0.5 completed (Results consolidated)
- [ ] Root cause identified with evidence
- [ ] Fix strategy documented
- [ ] Validation test cases defined
- [ ] **GATE: Root cause must be known before proceeding**

**Expected Duration**: 2-3 hours

---

## Phase 1: Implement Fix for First Bash Block

**Objective**: Apply targeted fix based on Phase 0 diagnosis to resolve first bash block initialization failures

**Complexity**: Medium (depends on root cause)

**Priority**: CRITICAL

**Dependencies**: Phase 0 complete, root cause identified

**Approach**: This phase's implementation depends entirely on Phase 0 findings. Below are conditional fix strategies:

### Task 1.1: Apply Fix Based on Root Cause

**Conditional Fix Strategies**:

#### If Hypothesis A Confirmed (Hidden Characters)

```bash
# Strategy: Remove non-printable characters from affected files

# 1. Clean coordinate.md
# Use sed/tr to remove non-printable characters except newlines/tabs
sed 's/[^[:print:]\t\n]//g' .claude/commands/coordinate.md > /tmp/coordinate_cleaned.md

# 2. Verify cleaning worked
diff -u .claude/commands/coordinate.md /tmp/coordinate_cleaned.md

# 3. Replace if clean
if [ $? -eq 0 ]; then
  echo "No hidden characters found"
else
  echo "Cleaned file differs - review changes"
  # Manual review required
fi

# 4. Clean affected library files
for lib in [libraries identified in Phase 0]; do
  sed 's/[^[:print:]\t\n]//g' ".claude/lib/$lib" > "/tmp/$lib.cleaned"
  # Review and replace
done
```

**Files Modified**: coordinate.md, identified library files

**Testing**: Run coordinate.md first bash block directly, verify no "!:" errors

---

#### If Hypothesis B Confirmed (Bash Tool Transformation)

```bash
# Strategy: Add defensive coding to work around Bash tool processing issues

# Modify coordinate.md first bash block (lines 23-163):

# 1. Add at very start (line 24, right after ```bash)
set +H  # Disable history expansion explicitly
set -euo pipefail  # Defensive error handling

# 2. Quote all variable expansions defensively
# Before: if [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
# After:  if [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
# (already quoted, verify all are)

# 3. Add diagnostic output (temporary, for validation)
echo "DEBUG: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR" >&2
echo "DEBUG: WORKFLOW_SCOPE=$WORKFLOW_SCOPE" >&2

# 4. Test library sourcing with verbose error output
# Temporarily remove 2>/dev/null from library-sourcing.sh:96
# Change: if ! source "$lib_path" 2>/dev/null; then
# To:     if ! source "$lib_path"; then
```

**Files Modified**: coordinate.md (first bash block), library-sourcing.sh (temporarily)

**Testing**: Run via Claude's Bash tool, verify no transformation errors

---

#### If Hypothesis C Confirmed (Library File Issues)

```bash
# Strategy: Fix ${!...} patterns in identified library files

# For each library with issues (identified in Phase 0):

# Example fix for indirect expansion:
# Before: local keys="${!STATE_TRANSITIONS[@]}"
# After:  local keys; keys=$(eval echo \"\${!STATE_TRANSITIONS[@]}\")
#   OR:   local -a keys=("${!STATE_TRANSITIONS[@]}")  # If bash 4.3+

# Apply Spec 617 fixes to missed patterns:
# 1. Identify all ${!...} uses in failing library
grep -n '$'{'{!'"" [failing-library].sh

# 2. Replace with safe alternatives
# Option A: Use eval with proper escaping
# Option B: Use alternative bash syntax
# Option C: Refactor to avoid indirect expansion

# 3. Add source guard if missing
if [ -n "${LIBRARY_NAME_SOURCED:-}" ]; then
  return 0
fi
export LIBRARY_NAME_SOURCED=1
```

**Files Modified**: Identified library files with ${!...} patterns

**Testing**: Source each fixed library individually, verify no errors

---

#### If Hypothesis D Confirmed (Environment-Specific)

```bash
# Strategy: Add NixOS-specific workarounds

# 1. Force history expansion off at start of first bash block
set +H  # Must be first command in block

# 2. Add environment detection and warning
if [[ -f /etc/NIXOS ]]; then
  echo "INFO: NixOS detected, applying environment workarounds" >&2
fi

# 3. Use explicit bash invocation for problematic commands
# Before: source "${LIB_DIR}/library.sh"
# After:  bash -c "source '${LIB_DIR}/library.sh'" || { echo "Failed"; exit 1; }

# 4. Document NixOS-specific requirements
# Add to coordinate-command-guide.md:
# "On NixOS, ensure bash is from nixpkgs, not from /run/current-system"
```

**Files Modified**: coordinate.md (first bash block), documentation

**Testing**: Run on NixOS and standard Linux, verify both work

---

### Task 1.2: Preserve Existing Fixes from Plan 001

**Objective**: Ensure Plan 001's valid fixes (source guards, re-sourcing) remain in place

**Validation**:
```bash
# 1. Verify source guards still present
for lib in workflow-state-machine.sh state-persistence.sh workflow-initialization.sh \
           error-handling.sh verification-helpers.sh; do
  if head -10 ".claude/lib/$lib" | grep -q "SOURCED"; then
    echo "✓ $lib has source guard"
  else
    echo "✗ $lib missing source guard"
  fi
done

# 2. Verify re-sourcing pattern in second bash block
if sed -n '176,189p' .claude/commands/coordinate.md | grep -q "Re-source libraries"; then
  echo "✓ Re-sourcing pattern present"
else
  echo "✗ Re-sourcing pattern missing"
fi

# 3. Ensure new fixes don't conflict with existing fixes
# Run full integration test (next task)
```

**Expected Outcome**: All Plan 001 fixes remain functional, new fixes complement them

**Completion Criteria**:
- [ ] Source guards verified present
- [ ] Re-sourcing pattern verified present
- [ ] No conflicts between old and new fixes

---

### Task 1.3: Add Defensive Error Handling

**Objective**: Improve error handling in first bash block to catch issues early

**Implementation**:
```bash
# Add to coordinate.md first bash block after line 93:

# Enhanced error handling for library sourcing
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
  echo "ERROR: Failed to source required libraries" >&2
  echo "" >&2
  echo "Diagnostic information:" >&2
  echo "  CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}" >&2
  echo "  LIB_DIR: ${LIB_DIR}" >&2
  echo "  WORKFLOW_SCOPE: ${WORKFLOW_SCOPE}" >&2
  echo "  REQUIRED_LIBS: ${REQUIRED_LIBS[*]}" >&2
  echo "" >&2
  echo "Please check:" >&2
  echo "  1. All library files exist in ${LIB_DIR}/" >&2
  echo "  2. Library files have no syntax errors" >&2
  echo "  3. No permission issues" >&2
  exit 1
fi

# Verify critical functions are available
if ! declare -F handle_state_error >/dev/null; then
  echo "CRITICAL ERROR: handle_state_error function not available" >&2
  echo "This indicates error-handling.sh failed to load" >&2
  echo "" >&2
  echo "Diagnostic: Test error-handling.sh directly:" >&2
  echo "  bash -c 'source ${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh && echo OK'" >&2
  exit 1
fi

echo "✓ All required libraries loaded successfully" >&2
```

**Expected Outcome**: Clear, actionable error messages if library sourcing fails

**Completion Criteria**:
- [ ] Enhanced error messages added
- [ ] Function availability verification added
- [ ] Diagnostic hints provided in error output

---

### Task 1.4: Runtime Validation (MANDATORY)

**Test Cases** (All must pass):

```bash
# Test Case 1: Library sourcing in first bash block
# Expected: No errors, handle_state_error available
/coordinate "Simple test workflow" 2>&1 | tee /tmp/test_case_1.log

# Validate output:
if grep -q "!: command not found" /tmp/test_case_1.log; then
  echo "✗ Test Case 1 FAILED: Still getting !: errors"
  exit 1
elif grep -q "handle_state_error: command not found" /tmp/test_case_1.log; then
  echo "✗ Test Case 1 FAILED: handle_state_error unavailable"
  exit 1
elif grep -q "State machine initialized" /tmp/test_case_1.log; then
  echo "✓ Test Case 1 PASSED: First bash block executes"
else
  echo "⚠ Test Case 1 UNCERTAIN: Review output manually"
fi

# Test Case 2: Research-only workflow
/coordinate "Research bash execution patterns" 2>&1 | tee /tmp/test_case_2.log

# Validate: Should complete research phase
if grep -q "ERROR:" /tmp/test_case_2.log; then
  echo "✗ Test Case 2 FAILED: Errors during execution"
elif grep -q "Research.*complete" /tmp/test_case_2.log; then
  echo "✓ Test Case 2 PASSED: Research workflow completes"
fi

# Test Case 3: Research-and-plan workflow
/coordinate "Research and plan simple feature" 2>&1 | tee /tmp/test_case_3.log

# Validate: Should complete research and plan
if grep -q "ERROR:" /tmp/test_case_3.log; then
  echo "✗ Test Case 3 FAILED: Errors during execution"
elif grep -q "plan.*created" /tmp/test_case_3.log; then
  echo "✓ Test Case 3 PASSED: Research-and-plan workflow completes"
fi

# Test Case 4: Error handling verification
# Intentionally trigger error condition
mkdir -p /tmp/coordinate_error_test
chmod 000 /tmp/coordinate_error_test  # Make unwritable
TOPIC_PATH=/tmp/coordinate_error_test /coordinate "Error test" 2>&1 | tee /tmp/test_case_4.log

# Validate: Should fail gracefully with clear error message
if grep -q "handle_state_error" /tmp/test_case_4.log && \
   grep -q "permission\|denied\|cannot" /tmp/test_case_4.log; then
  echo "✓ Test Case 4 PASSED: Error handling works"
else
  echo "✗ Test Case 4 FAILED: Error handling unclear"
fi

chmod 755 /tmp/coordinate_error_test  # Cleanup
```

**Phase 1 Completion Gate**: **ALL 4 test cases must pass** before marking Phase 1 complete

**Completion Criteria**:
- [ ] Root cause fix implemented (Task 1.1)
- [ ] Existing fixes preserved (Task 1.2)
- [ ] Defensive error handling added (Task 1.3)
- [ ] **ALL runtime tests pass** (Task 1.4)
- [ ] No "!: command not found" errors
- [ ] handle_state_error available
- [ ] TOPIC_PATH initializes correctly

**Expected Duration**: 1.5-3 hours (varies by root cause complexity)

---

## Phase 2: Comprehensive Integration Testing

**Objective**: Validate that fixes work across all workflow types and edge cases

**Complexity**: Medium

**Priority**: HIGH

**Dependencies**: Phase 1 complete with all test cases passing

### Task 2.1: Test All Workflow Scopes

**Test Matrix**:

```bash
# Scope 1: research-only
/coordinate "Research authentication patterns for web applications" 2>&1 | \
  tee /tmp/test_research_only.log

# Validation:
# - Should invoke 2-4 research agents
# - Should create reports in TOPIC_PATH/reports/
# - Should terminate at STATE_RESEARCH
# - No errors in output

# Scope 2: research-and-plan
/coordinate "Research and plan JWT authentication implementation" 2>&1 | \
  tee /tmp/test_research_and_plan.log

# Validation:
# - Should invoke research agents
# - Should create reports
# - Should generate implementation plan
# - Should terminate at STATE_PLAN
# - Plan file should exist

# Scope 3: full-implementation (if supported)
# Note: May not be fully implemented in current coordinate.md
/coordinate "Research, plan, and implement simple feature" 2>&1 | \
  tee /tmp/test_full_implementation.log || echo "Full scope may not be implemented"

# Scope 4: debug-only (if supported)
/coordinate "Debug authentication issue" 2>&1 | \
  tee /tmp/test_debug_only.log || echo "Debug scope may not be implemented"
```

**Success Criteria**:
- [ ] research-only scope completes without errors
- [ ] research-and-plan scope completes without errors
- [ ] All expected artifacts created
- [ ] State transitions correct
- [ ] No function availability errors

---

### Task 2.2: Test Edge Cases and Error Conditions

**Edge Case Tests**:

```bash
# Edge Case 1: Empty workflow description
/coordinate "" 2>&1 | tee /tmp/edge_empty.log
# Expected: Clear error message, graceful failure

# Edge Case 2: Very long workflow description
/coordinate "$(printf 'A%.0s' {1..500})" 2>&1 | tee /tmp/edge_long.log
# Expected: Either works or fails gracefully

# Edge Case 3: Special characters in description
/coordinate "Fix bug: CSS !important rules not working" 2>&1 | tee /tmp/edge_special_chars.log
# Expected: Handles ! character without history expansion errors

# Edge Case 4: Invalid CLAUDE_PROJECT_DIR
CLAUDE_PROJECT_DIR=/nonexistent /coordinate "test" 2>&1 | tee /tmp/edge_invalid_dir.log
# Expected: Clear error about invalid project directory

# Edge Case 5: Missing library file
mv .claude/lib/error-handling.sh .claude/lib/error-handling.sh.backup
/coordinate "test" 2>&1 | tee /tmp/edge_missing_lib.log
# Expected: Clear error identifying missing library
mv .claude/lib/error-handling.sh.backup .claude/lib/error-handling.sh

# Edge Case 6: Corrupted library file (syntax error)
echo "syntax error {{{" >> .claude/lib/verification-helpers.sh
/coordinate "test" 2>&1 | tee /tmp/edge_syntax_error.log
# Expected: Clear error identifying library with syntax error
git checkout .claude/lib/verification-helpers.sh  # Restore

# Edge Case 7: Concurrent coordinate invocations
/coordinate "test 1" & PID1=$!
/coordinate "test 2" & PID2=$!
wait $PID1 && echo "Test 1 complete"
wait $PID2 && echo "Test 2 complete"
# Expected: Both complete without interfering with each other
```

**Success Criteria**:
- [ ] All edge cases handled gracefully
- [ ] Error messages are clear and actionable
- [ ] No cryptic errors or stack traces
- [ ] Concurrent invocations don't interfere

---

### Task 2.3: Performance and Context Usage Validation

**Performance Metrics**:

```bash
# Measure execution time for simple workflow
time /coordinate "Quick research test" 2>&1 | tee /tmp/perf_simple.log

# Expected: <5 minutes for research-only
# If >10 minutes: Investigate performance regression

# Measure context usage (if metrics available)
# Expected: <30% context usage throughout workflow
# Based on hierarchical agent architecture targets

# Check library re-sourcing overhead
# Expected: ~2ms per bash block (negligible)
# From Phase 0 research findings
```

**Success Criteria**:
- [ ] Simple workflows complete in <5 minutes
- [ ] Complex workflows complete in <15 minutes
- [ ] Context usage <30% (if measurable)
- [ ] Library re-sourcing overhead <5ms per block

---

### Task 2.4: Regression Testing

**Regression Test Suite**:

```bash
# Check delegation rate maintained >90%
# (Research agents properly invoked, not executed inline)
/coordinate "Research three topics: auth, session, tokens" 2>&1 | \
  grep -c "Task.*research-specialist" | \
  awk '{if($1>=2) print "✓ Delegation working"; else print "✗ Delegation broken"}'

# Check state machine transitions
/coordinate "Research and plan test" 2>&1 | tee /tmp/regression_state.log
# Verify state transitions: initialize → research → plan
grep "State.*transition" /tmp/regression_state.log

# Check verification checkpoints
# Should see verification-helpers.sh being used
grep "verify_file_created" /tmp/regression_state.log || \
  echo "⚠ Verification pattern may not be active"

# Check existing test suite (if exists)
if [ -f .claude/tests/test_coordinate.sh ]; then
  bash .claude/tests/test_coordinate.sh
else
  echo "INFO: No coordinate-specific test suite found"
fi
```

**Success Criteria**:
- [ ] Delegation rate >90%
- [ ] State machine transitions correct
- [ ] Verification checkpoints active
- [ ] Existing test suite passes (if exists)

---

### Phase 2 Completion Checklist

- [ ] All workflow scopes tested (Task 2.1)
- [ ] All edge cases tested (Task 2.2)
- [ ] Performance validated (Task 2.3)
- [ ] Regression tests passed (Task 2.4)
- [ ] **Zero test failures**
- [ ] All error messages clear and actionable
- [ ] No performance regressions

**Expected Duration**: 2-3 hours

---

## Phase 3: Infrastructure Integration and Improvements

**Objective**: Integrate fixes with existing infrastructure and enhance reliability

**Complexity**: Low-Medium

**Priority**: MEDIUM

**Dependencies**: Phase 2 complete

### Task 3.1: Update Orchestration Troubleshooting Guide

**Add case study to existing infrastructure**:

**File**: `.claude/docs/guides/orchestration-troubleshooting.md`

**New Section**: "Section 6: Bash Execution Context Issues"

```markdown
## Section 6: Bash Execution Context Issues

### Symptom: "!: command not found" During Workflow Execution

**Error Pattern**:
```
/run/current-system/sw/bin/bash: line NNN: !: command not found
ERROR: handle_state_error: command not found
ERROR: TOPIC_PATH: unbound variable
```

**Root Cause**: [Insert findings from Phase 0 diagnosis]

**Why Standard Fixes Failed**:
- History expansion already disabled (non-interactive shell default)
- No hidden/non-printable characters found (or: Hidden characters were found and removed)
- Library code syntactically correct
- Problem was [specific issue from Phase 0]

**Solution** (from Spec 620):
1. [Specific fix applied based on Phase 0/Phase 1]
2. Added defensive error handling in first bash block
3. Enhanced library sourcing validation
4. [Any additional fixes]

**Prevention**:
- [Specific preventive measures based on root cause]
- Monitor bash block sizes (use awk pattern from Spec 623)
- Add source guards to all new library files
- Always test with runtime execution, not just code analysis
- Reference: [Root cause diagnosis report](../../specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md)

### Testing Procedure

To verify coordinate.md works correctly:

```bash
# Quick test
/coordinate "Test research workflow"

# Expected output:
# ✓ State machine initialized
# ✓ Libraries loaded successfully
# ✓ Workflow paths initialized
# ✓ Research agents invoked
# (No "!: command not found" errors)

# If errors persist:
# 1. Check library files exist: ls -la .claude/lib/
# 2. Test library sourcing: bash -c 'source .claude/lib/error-handling.sh && echo OK'
# 3. Review diagnostic report: specs/620_.../reports/002_diagnostic_analysis.md
```
```

**Completion Criteria**:
- [ ] Case study added to troubleshooting guide
- [ ] Root cause documented
- [ ] Solution documented
- [ ] Prevention measures documented
- [ ] Testing procedure included

---

### Task 3.2: Update Command Development Guide

**Add bash execution best practices**:

**File**: `.claude/docs/guides/command-development-guide.md`

**Section**: Add to existing "Best Practices"

```markdown
### Bash Block Execution in Orchestration Commands

Claude's markdown execution model runs bash blocks as separate processes. For orchestration commands with multiple bash blocks:

**Required Practices**:
1. **Test root cause before implementing fixes**
   - Use systematic hypothesis testing (see Spec 620)
   - Don't guess at solutions without diagnosis
   - Document findings before coding

2. **Runtime testing is mandatory**
   - Code analysis finds ~70% of issues
   - Runtime execution finds critical remaining 30%
   - NEVER mark phases complete without running the code

3. **First bash block is critical**
   - Library sourcing failures in first block cascade
   - Add defensive error handling early
   - Verify critical functions available before use

4. **Re-source libraries across bash blocks**
   - Functions lost across block boundaries
   - Add source guards to all libraries (idempotent re-sourcing)
   - Re-source at start of each bash block

**Example Pattern**:
```bash
# At start of every bash block (including first):

# Defensive settings
set +H  # Disable history expansion (if needed based on environment)
set -euo pipefail  # Fail-fast error handling

# Project directory detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Library re-sourcing (safe due to source guards)
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
# ... other libraries ...

# Validation (first block only)
if ! declare -F handle_state_error >/dev/null; then
  echo "CRITICAL: handle_state_error not available" >&2
  exit 1
fi
```

**Common Pitfalls**:
- ❌ Assuming code that "looks correct" works correctly
- ❌ Deferring testing to later phases
- ❌ Using code analysis instead of runtime validation
- ❌ Skipping root cause diagnosis
- ❌ Marking phases complete without running the code

**References**:
- [Spec 620: /coordinate Bash Execution Failures](../../specs/620_fix_coordinate_bash_history_expansion_errors/)
- [Diagnostic Analysis](../../specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md)
- [Orchestration Troubleshooting Guide](orchestration-troubleshooting.md#section-6)
```

**Completion Criteria**:
- [ ] Best practices added
- [ ] Example pattern included
- [ ] Common pitfalls documented
- [ ] References linked

---

### Task 3.3: Create Validation Script

**Create automated test script for future validation**:

**File**: `.claude/tests/test_coordinate_bash_execution.sh`

```bash
#!/usr/bin/env bash
# Test suite for /coordinate bash execution
# Validates fixes from Spec 620

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$CLAUDE_ROOT" || exit 1

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test runner
run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_pattern="$3"

  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  echo ""
  echo "Running test: $test_name"

  if eval "$test_command" | grep -q "$expected_pattern"; then
    echo "  ✓ PASSED"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAILED"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 1: First bash block executes without errors
run_test \
  "First bash block initialization" \
  "/coordinate 'Test workflow' 2>&1" \
  "State machine initialized"

# Test 2: No history expansion errors
run_test \
  "No history expansion errors" \
  "/coordinate 'Test workflow' 2>&1 | grep -v '!: command not found' | wc -l" \
  "^0$"

# Test 3: handle_state_error available
run_test \
  "Error handling function available" \
  "/coordinate 'Test workflow' 2>&1 | grep -v 'handle_state_error: command not found' | wc -l" \
  "^0$"

# Test 4: TOPIC_PATH initializes
run_test \
  "TOPIC_PATH initialization" \
  "/coordinate 'Test workflow' 2>&1 | grep -v 'TOPIC_PATH: unbound variable' | wc -l" \
  "^0$"

# Test 5: Research-only workflow completes
run_test \
  "Research-only workflow" \
  "/coordinate 'Research test topic' 2>&1" \
  "complete"

# Summary
echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Total tests:  $TESTS_TOTAL"
echo "Passed:       $TESTS_PASSED"
echo "Failed:       $TESTS_FAILED"
echo "========================================"

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
```

**Completion Criteria**:
- [ ] Validation script created
- [ ] Script is executable
- [ ] All tests pass when run
- [ ] Script added to testing infrastructure

---

### Task 3.4: Update CLAUDE.md Testing Protocols

**Add /coordinate to testing protocols**:

**File**: `/home/benjamin/.config/CLAUDE.md`

**Section**: Testing Protocols → Claude Code Testing

```markdown
- `test_coordinate_bash_execution.sh` - /coordinate bash execution validation (5 tests, Spec 620 fixes)
  - First bash block initialization
  - History expansion errors prevented
  - Error handling function availability
  - Workflow path initialization
  - Research-only workflow completion
```

**Completion Criteria**:
- [ ] CLAUDE.md updated
- [ ] Test description accurate
- [ ] Test count correct

---

### Phase 3 Completion Checklist

- [ ] Troubleshooting guide updated (Task 3.1)
- [ ] Command development guide updated (Task 3.2)
- [ ] Validation script created (Task 3.3)
- [ ] CLAUDE.md testing protocols updated (Task 3.4)
- [ ] All infrastructure improvements tested
- [ ] Documentation cross-references verified

**Expected Duration**: 1.5-2 hours

---

## Phase 4: Process Improvements and Documentation

**Objective**: Document lessons learned and improve development processes to prevent similar failures

**Complexity**: Low

**Priority**: MEDIUM

**Dependencies**: Phase 3 complete

### Task 4.1: Create Root Cause Analysis Report

**File**: `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/003_root_cause_and_resolution.md`

```markdown
# Root Cause Analysis and Resolution: /coordinate Bash Execution Failures

## Executive Summary

**Problem**: /coordinate command failed with "!: command not found" errors during first bash block execution

**Root Cause**: [Specific finding from Phase 0]

**Resolution**: [Specific fix from Phase 1]

**Status**: ✅ RESOLVED (validated with runtime testing)

## Timeline

- **2025-11-09**: Issue discovered during coordinate execution
- **2025-11-09**: Plan 001 created and marked complete (code analysis only - FAILED)
- **2025-11-09**: Diagnostic analysis revealed plan 001 didn't work
- **2025-11-09**: Plan 002 created with systematic diagnosis approach
- **2025-11-09**: [Phase 0 completion date] Root cause identified
- **2025-11-09**: [Phase 1 completion date] Fix implemented and validated
- **2025-11-09**: [Phase 2 completion date] Comprehensive testing completed

## Root Cause Details

[Detailed explanation of root cause from Phase 0]

### Why Previous Plan Failed

Plan 001 (001_coordinate_history_expansion_fix.md) failed because:

1. **No systematic diagnosis** - Applied generic fixes without identifying root cause
2. **Testing deferred** - Marked phases complete based on code analysis alone
3. **Wrong problem** - Addressed bash block boundaries, missed first block initialization
4. **False confidence** - Seeing implementations present ≠ fixes working

### What Was Different This Time

Plan 002 (this plan) succeeded because:

1. **Diagnosis first** - Phase 0 tested four hypotheses systematically
2. **Runtime testing** - Every phase validated with actual execution
3. **Targeted fix** - Applied specific solution based on root cause
4. **Honest status** - Only marked complete when tests passed

## Resolution Details

[Detailed explanation of fix from Phase 1]

## Validation Evidence

[Test results from Phase 2]

All test cases passed:
- ✓ First bash block initialization
- ✓ Research-only workflow
- ✓ Research-and-plan workflow
- ✓ Error handling
- ✓ Edge cases
- ✓ Performance metrics

## Lessons Learned

### Technical Lessons

1. [Specific technical insight from root cause]
2. First bash block failures cascade into multiple error symptoms
3. [Environment-specific findings, if applicable]

### Process Lessons

1. **Diagnosis before fixes** - Never implement without understanding root cause
2. **Runtime testing is mandatory** - Code analysis alone is insufficient
3. **Test immediately** - Don't defer testing to later phases
4. **Be honest about status** - "Untested" ≠ "Complete"

## Prevention Measures

To prevent similar issues in future:

1. **For developers**:
   - Always diagnose root cause before implementing fixes
   - Test with runtime execution, not just code review
   - Validate each phase before proceeding to next
   - Mark status honestly (implemented ≠ working ≠ tested)

2. **For orchestration commands**:
   - [Specific prevention based on root cause]
   - Add defensive error handling in first bash block
   - Verify critical functions available before use
   - Include runtime test suite in specs/tests/

3. **For process**:
   - Phase completion requires runtime validation
   - Create test cases before implementing
   - Document hypothesis testing methodology
   - Update troubleshooting guides with findings

## References

- **Diagnostic Analysis**: [002_diagnostic_analysis.md](002_diagnostic_analysis.md)
- **Failed Plan**: [001_coordinate_history_expansion_fix.md](../plans/001_coordinate_history_expansion_fix.md)
- **This Plan**: [002_complete_diagnostic_and_fix.md](../plans/002_complete_diagnostic_and_fix.md)
- **Troubleshooting Guide**: [orchestration-troubleshooting.md](../../docs/guides/orchestration-troubleshooting.md#section-6)
- **Command Development Guide**: [command-development-guide.md](../../docs/guides/command-development-guide.md)

---

**Status**: This issue is RESOLVED and validated with comprehensive testing.
```

**Completion Criteria**:
- [ ] Root cause documented
- [ ] Resolution documented
- [ ] Validation evidence included
- [ ] Lessons learned documented
- [ ] Prevention measures defined

---

### Task 4.2: Update Implementation Standards

**File**: `.claude/docs/reference/command_architecture_standards.md`

**New Standard**: "Standard 15: Runtime Validation Requirements"

```markdown
## Standard 15: Runtime Validation Requirements

**Category**: Testing and Validation

**Requirement**: All orchestration command implementations and fixes MUST include runtime validation before marking phases or tasks complete.

**Rationale**: Code analysis alone finds ~70% of issues. Runtime execution finds critical remaining 30%. Multiple failed implementations (Specs 620, others) resulted from marking work complete based on code review without execution.

**Requirements**:

1. **Phase Completion Criteria**:
   - ✅ Code review passed
   - ✅ Static analysis passed
   - ✅ **Runtime tests passed** (MANDATORY)
   - ✅ Error conditions tested
   - ✅ Integration validated

2. **Prohibited Practices**:
   - ❌ Marking phases complete based on code analysis alone
   - ❌ Deferring testing to later phases
   - ❌ Assuming "looks correct" means "works correctly"
   - ❌ Using "code analysis" instead of "runtime validation"

3. **Status Reporting**:
   - "Implemented but untested" - Code written, not yet run
   - "Tested - code analysis" - Code reviewed, not executed
   - "Tested - runtime" - Code executed successfully
   - "Complete" - Runtime tests passed, validated

4. **Test Requirements**:
   - Happy path tests (normal operation)
   - Error condition tests (failure handling)
   - Edge case tests (boundary conditions)
   - Integration tests (full workflow)
   - Performance validation (no regressions)

**Examples**:

✅ **Correct** (Spec 620, Plan 002):
```markdown
### Phase 1: Fix First Bash Block

**Status**: COMPLETE (2025-11-09)

**Validation**:
- ✓ Code review: Fix implemented correctly
- ✓ Static analysis: No syntax errors
- ✓ **Runtime tests**: All 4 test cases passed
- ✓ Error conditions: Graceful failure tested
- ✓ Integration: Works with existing infrastructure
```

❌ **Incorrect** (Spec 620, Plan 001):
```markdown
### Phase 4: Comprehensive Testing & Validation [COMPLETED]

**Validation Results** (2025-11-09 - Comprehensive Code Analysis):
**All Tests Validated** (11 total: 10 full pass, 1 partial pass)
...
**Runtime Testing Recommendation**: While code analysis predicts success, runtime execution should verify actual behavior matches predictions.
```
(Marked complete despite "runtime testing recommendation" = never ran it)

**Compliance Checking**:

```bash
# Check if plan has runtime validation
grep -E "runtime|executed|run.*test" plan.md

# Red flags:
# - "deferred to Phase N"
# - "code analysis"
# - "predicted success"
# - "should verify" (recommendation, not requirement)

# Green flags:
# - "runtime tests passed"
# - "executed successfully"
# - "test cases passed"
# - Test results included in plan
```

**References**:
- [Spec 620 Diagnostic Analysis](../../specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md) - Case study of failure from code-analysis-only validation
- [Spec 620 Plan 002](../../specs/620_fix_coordinate_bash_history_expansion_errors/plans/002_complete_diagnostic_and_fix.md) - Correct approach with runtime validation

---
```

**Completion Criteria**:
- [ ] New standard added
- [ ] Examples provided (correct and incorrect)
- [ ] Compliance checking guidance included
- [ ] References linked

---

### Task 4.3: Create Testing Checklist Template

**File**: `.claude/docs/templates/phase-completion-checklist.md`

```markdown
# Phase Completion Checklist Template

Use this checklist to ensure thorough validation before marking phases complete.

## Phase N: [Phase Name]

### 1. Implementation Checklist

- [ ] All tasks completed
- [ ] Code reviewed for correctness
- [ ] Code reviewed for standards compliance
- [ ] Files modified documented
- [ ] No syntax errors (static analysis)

### 2. Runtime Validation Checklist (MANDATORY)

- [ ] **Happy path tested** - Normal operation works
- [ ] **Error conditions tested** - Failures handled gracefully
- [ ] **Edge cases tested** - Boundary conditions work
- [ ] **Integration tested** - Works with existing code
- [ ] **Performance validated** - No regressions

### 3. Test Results Documentation

Document test results in plan:

```markdown
**Runtime Validation** (YYYY-MM-DD):

Test Case 1: [Description]
- Command: `[command executed]`
- Expected: [expected outcome]
- Actual: [actual outcome]
- Status: ✓ PASSED / ✗ FAILED

Test Case 2: [Description]
...
```

### 4. Phase Completion Criteria

Answer these questions:

- [ ] Did you actually RUN the code? (not just review it)
- [ ] Did ALL test cases PASS? (no failures deferred)
- [ ] Can you demonstrate it working? (reproducible results)
- [ ] Are error messages clear? (tested error conditions)
- [ ] Is it integrated? (tested with existing infrastructure)

**If any answer is NO**: Phase is NOT complete. Continue testing.

### 5. Status Reporting

Select accurate status:

- [ ] "Implemented but untested" - Code written, not yet run
- [ ] "Tested - code analysis only" - Reviewed but not executed
- [ ] "Tested - partial runtime" - Some tests passed, some deferred
- [ ] "Tested - comprehensive runtime" - All tests passed
- [ ] **"COMPLETE"** - Comprehensive runtime tests passed, validated ✅

**Only mark COMPLETE if all runtime tests passed.**

### 6. Failure Recovery

If tests fail:

1. **Do NOT mark phase complete**
2. **Document failure** in plan
3. **Diagnose root cause** (don't guess)
4. **Fix and re-test** (full cycle)
5. **Update plan status** when tests pass

---

## Example: Correct Phase Completion

### Phase 1: Fix First Bash Block

**Status**: COMPLETE (2025-11-09)

**Implementation**:
- [x] Root cause fix implemented
- [x] Defensive error handling added
- [x] Code reviewed and correct

**Runtime Validation** (2025-11-09):

Test Case 1: First bash block initialization
- Command: `/coordinate "Test workflow"`
- Expected: No "!: command not found" errors
- Actual: ✓ No errors, state machine initialized
- Status: ✓ PASSED

Test Case 2: handle_state_error availability
- Command: `/coordinate "Test workflow" | grep "handle_state_error"`
- Expected: Function available (no "command not found")
- Actual: ✓ Function available
- Status: ✓ PASSED

Test Case 3: Research-only workflow
- Command: `/coordinate "Research test topic"`
- Expected: Workflow completes, reports created
- Actual: ✓ Workflow complete
- Status: ✓ PASSED

Test Case 4: Error handling
- Command: `[Error trigger command]`
- Expected: Clear error message, graceful failure
- Actual: ✓ Clear error message
- Status: ✓ PASSED

**Summary**: All 4 test cases passed. Phase 1 is COMPLETE.

---

## Example: Incorrect Phase Completion (DON'T DO THIS)

### Phase 4: Comprehensive Testing & Validation [COMPLETED]

**Status**: COMPLETED (2025-11-09)

**Validation Results** (2025-11-09 - Comprehensive Code Analysis):
**All Tests Validated** (11 total: 10 full pass, 1 partial pass)

**Runtime Testing Recommendation**: While code analysis predicts success, runtime execution should verify actual behavior matches predictions.

❌ **PROBLEMS**:
1. "Code Analysis" instead of runtime execution
2. "Recommendation" instead of requirement
3. "Predicts success" instead of "tests passed"
4. No actual test results documented
5. Never actually ran /coordinate

**Consequence**: When user ran /coordinate, it failed immediately with the exact errors the phase was supposed to fix.

---

**Use this checklist for EVERY phase to ensure thorough validation.**
```

**Completion Criteria**:
- [ ] Checklist template created
- [ ] Correct example included
- [ ] Incorrect example included (what not to do)
- [ ] Template usable for future phases

---

### Phase 4 Completion Checklist

- [ ] Root cause analysis report created (Task 4.1)
- [ ] Implementation standards updated (Task 4.2)
- [ ] Testing checklist template created (Task 4.3)
- [ ] All process improvements documented
- [ ] All references linked correctly

**Expected Duration**: 1.5-2 hours

---

## Overall Success Metrics

### Technical Success

- [ ] Root cause of "!: command not found" identified
- [ ] Fix implemented based on diagnosis
- [ ] `/coordinate` executes without errors
- [ ] All test cases pass (20+ tests across phases)
- [ ] No regressions in existing functionality
- [ ] Performance within acceptable ranges

### Process Success

- [ ] Systematic diagnosis methodology demonstrated
- [ ] Runtime validation at every phase
- [ ] Honest status reporting maintained
- [ ] Process improvements documented
- [ ] Future prevention measures defined

### Documentation Success

- [ ] Diagnostic analysis complete
- [ ] Root cause report complete
- [ ] Troubleshooting guide updated
- [ ] Command development guide updated
- [ ] Implementation standards updated
- [ ] Testing checklist template created

## Testing Strategy Summary

### Phase 0: Diagnosis Validation
- 4 hypotheses tested systematically
- Root cause identified with evidence
- Fix strategy defined

### Phase 1: Fix Validation
- 4 test cases (all must pass)
- First bash block initialization
- Library function availability
- Workflow completion
- Error handling

### Phase 2: Integration Validation
- All workflow scopes tested
- 7 edge cases tested
- Performance metrics validated
- Regression tests passed

### Phase 3: Infrastructure Validation
- Documentation updates verified
- Validation script passes
- CLAUDE.md updates accurate

### Phase 4: Process Validation
- Root cause report complete
- Standards updated
- Templates usable

**Total Test Count**: 20+ runtime tests across all phases

## Risk Assessment

### Low Risk (Phase 0-1)

- Systematic diagnosis reduces uncertainty
- Targeted fix based on evidence
- Immediate runtime validation catches issues

### Medium Risk (Phase 2-3)

- Edge cases may reveal unforeseen issues
- Integration with existing infrastructure could conflict
- Performance regressions possible

### Mitigation Strategies

1. **Test incrementally** - Validate each phase before next
2. **Maintain rollback capability** - Git commits per phase
3. **Document failures** - Learn from what doesn't work
4. **Ask for help** - If root cause unclear after Phase 0
5. **Be honest** - Don't mark complete if tests fail

## Rollback Plan

```bash
# Phase-by-phase rollback

# Rollback Phase 4 (documentation only - safe)
git checkout HEAD -- .claude/docs/ .claude/specs/620_*/reports/003_*

# Rollback Phase 3 (infrastructure updates - safe)
git checkout HEAD -- .claude/docs/ .claude/tests/test_coordinate_bash_execution.sh CLAUDE.md

# Rollback Phase 2 (test infrastructure only - safe)
# No code changes in Phase 2

# Rollback Phase 1 (CRITICAL - restores broken state)
git checkout HEAD -- .claude/commands/coordinate.md .claude/lib/

# Emergency: Full rollback to before Plan 002
git log --oneline --grep="620" | head -5
git revert <commit-hash-from-phase-1>

# Nuclear option: Restore from Plan 001 backup
ls .claude/specs/620_*/plans/*.backup-*
# Note: Plan 001 implementation also doesn't work, so this is not helpful
```

## Dependencies

### Prerequisites

- Diagnostic analysis report (002_diagnostic_analysis.md) - ✅ Complete
- Failed plan for reference (001_coordinate_history_expansion_fix.md) - ✅ Available
- Access to `/coordinate` command for testing - ✅ Required
- Bash 4.3+ for testing - ✅ Required
- Git for rollback capability - ✅ Required

### External Dependencies

- Claude's Bash tool (for testing Hypothesis B)
- NixOS environment (if Hypothesis D confirmed)
- Testing infrastructure (.claude/tests/)
- Documentation infrastructure (.claude/docs/)

### No Breaking Changes Expected

- Fixes are corrective, not architectural
- Existing Plan 001 fixes preserved (source guards, re-sourcing)
- Library interfaces remain stable
- State machine architecture unchanged

## Timeline Estimate

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 0: Diagnosis | 2-3 hours | 2-3 hours |
| Phase 1: Fix Implementation | 1.5-3 hours | 3.5-6 hours |
| Phase 2: Integration Testing | 2-3 hours | 5.5-9 hours |
| Phase 3: Infrastructure | 1.5-2 hours | 7-11 hours |
| Phase 4: Documentation | 1.5-2 hours | 8.5-13 hours |

**Total Estimate**: 8.5-13 hours (more accurate: 10 hours)

**Critical Path**: Phase 0 → Phase 1 → Phase 2 (6-9 hours for functional fix)

**Optional**: Phase 3-4 can be done incrementally after critical fix validated

## Key Differences from Plan 001

| Aspect | Plan 001 (Failed) | Plan 002 (This Plan) |
|--------|-------------------|----------------------|
| **Approach** | Implement fixes, test later | Diagnose first, then fix |
| **Testing** | Deferred to Phase 4 | Runtime at every phase |
| **Validation** | Code analysis only | Actual execution required |
| **Root Cause** | Assumed from research | Systematically diagnosed |
| **Status Reporting** | "Predicted success" | "Tests passed" or "Tests failed" |
| **Phase Completion** | Code present = complete | Tests pass = complete |
| **Outcome** | Marked complete but doesn't work | Won't mark complete until it works |

## Notes for Implementer

### Critical Success Factors

1. **DO NOT skip Phase 0** - Understanding root cause is essential
2. **DO NOT defer testing** - Validate immediately at each phase
3. **DO NOT guess at fixes** - Apply targeted solution based on diagnosis
4. **DO NOT mark complete without runtime tests** - Code analysis is not enough
5. **DO be honest** - If tests fail, phase is not complete

### When to Ask for Help

- After Phase 0, if no hypothesis is confirmed (root cause unclear)
- After Phase 1, if fix doesn't resolve issue (back to Phase 0)
- After Phase 2, if regressions detected (may need architectural changes)
- Any time you're unsure - better to ask than to mark complete incorrectly

### What "Complete" Means

A phase is complete when:
1. ✅ All tasks implemented
2. ✅ **All runtime tests passed** (MANDATORY)
3. ✅ Results documented in plan
4. ✅ No failures deferred to later phases
5. ✅ Honest assessment of status

**Not complete** when:
- ❌ Code "looks correct" but not tested
- ❌ Some tests passed, some skipped
- ❌ Tests "predicted to pass" but not run
- ❌ "Will test in next phase"

### Final Checklist Before Marking Plan Complete

- [ ] Phase 0: Root cause identified (not assumed)
- [ ] Phase 1: Fix implemented and **runtime tests passed**
- [ ] Phase 2: Comprehensive testing **all passed**
- [ ] Phase 3: Infrastructure updates validated
- [ ] Phase 4: Documentation complete
- [ ] `/coordinate` works in production use
- [ ] All test cases documented with results
- [ ] No failures deferred or ignored
- [ ] Honest status throughout

**If all checked: Plan is complete. If any unchecked: Plan is not complete.**

---

## Revision History

### 2025-11-09 - Initial Version
**Created**: Complete diagnostic and fix plan based on 002_diagnostic_analysis.md findings

**Key Features**:
- Systematic 4-hypothesis diagnosis approach (Phase 0)
- Test-driven implementation (runtime validation mandatory)
- Comprehensive testing across all phases
- Process improvements to prevent future failures
- Honest status reporting requirements

**Philosophy**:
- Diagnosis before fixes
- Runtime testing before completion
- Honest assessment always
- Learn from failures (Plan 001)

**Estimated Duration**: 8.5-13 hours across 5 phases
**Critical Path**: 6-9 hours for functional fix (Phase 0-2)
