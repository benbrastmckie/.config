# Fix coordinate.md Bash Execution Failures - Diagnostic & Resolution Plan

## Metadata
- **Date**: 2025-11-09
- **Feature**: Bug Fix - Mysterious "!: command not found" errors in coordinate.md execution
- **Scope**: Systematic diagnosis and resolution of bash execution failures
- **Estimated Phases**: 4 phases (diagnostic-first approach)
- **Estimated Hours**: 3-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - 617 (Fixed ${!...} patterns in library files - completed and verified working)
  - 613 (Fixed coordinate.md state machine errors)
  - 602 (State-based orchestration refactor)

## Problem Statement

### Error Evidence from coordinate_output.md (2025-11-09 18:33)

```
State machine initialized: scope=research-and-plan, terminal=plan
/run/current-system/sw/bin/bash: line 248: !: command not found
/run/current-system/sw/bin/bash: line 260: !: command not found

ERROR: TOPIC_PATH not set after workflow initialization
```

### Research Findings

**What We Know:**
1. ✅ Spec 617 fixed all `${!...}` patterns in library files (verified working)
2. ✅ Libraries (workflow-initialization.sh, context-pruning.sh) work correctly when tested directly
3. ✅ History expansion is OFF by default in non-interactive shells
4. ✅ `set +H` was previously tried and did NOT fix the issue
5. ✅ Error line numbers (248, 260) correspond to coordinate.md source lines
6. ✅ Lines 248/260 are inside bash blocks with no apparent `!` issues
7. ❌ Standard fixes (set +H, escaping, etc.) don't apply to this scenario

**What's Mysterious:**
- Error occurs during execution of first bash block
- But line numbers reference second bash block
- No bare `!` characters found at those lines
- Libraries work fine in isolation
- Issue is specific to coordinate.md execution through Claude's Bash tool

### Root Cause Hypothesis

The issue likely involves:
1. How Claude Code's Bash tool processes markdown and extracts bash blocks
2. Possible preprocessing/templating that introduces problematic characters
3. Interaction between bash block execution context and library sourcing
4. Potential line number reporting issues masking the true error location

## Success Criteria

- [ ] Understand exact mechanism causing "!: command not found" errors
- [ ] /coordinate executes successfully through complete workflows
- [ ] TOPIC_PATH and all workflow variables properly initialized
- [ ] Solution is robust and doesn't break other functionality
- [ ] Root cause documented to prevent future occurrences
- [ ] Diagnostic tools created for future troubleshooting

## Implementation Phases

### Phase 1: Comprehensive Diagnostics & Root Cause Identification
**Objective**: Add extensive logging to understand exact execution flow and error source
**Complexity**: Medium
**Priority**: CRITICAL (must understand before fixing)

**Tasks:**

- [ ] **Add Debug Wrapper to First Bash Block**: Instrument coordinate.md initialization
  ```bash
  # At start of first bash block (after line 23 marker):
  set -x  # Enable xtrace for detailed execution log
  echo "DEBUG: Bash version: $BASH_VERSION"
  echo "DEBUG: Shell options:"
  set -o | grep -E "history|histexpand|interactive"
  echo "DEBUG: Starting coordinate initialization..."

  # ... existing code ...

  # At end of first bash block:
  echo "DEBUG: First bash block completed"
  set +x
  ```

- [ ] **Add Library Sourcing Diagnostics**: Track which libraries are loaded
  ```bash
  # Before each 'source' command:
  echo "DEBUG: Sourcing ${LIB_DIR}/workflow-state-machine.sh"
  source "${LIB_DIR}/workflow-state-machine.sh"
  echo "DEBUG: Sourced workflow-state-machine.sh successfully"

  # Repeat for each library
  ```

- [ ] **Add Function Call Tracing**: Log all major function invocations
  ```bash
  # Before initialize_workflow_paths:
  echo "DEBUG: Calling initialize_workflow_paths"
  echo "DEBUG: Args: WORKFLOW_DESCRIPTION='$WORKFLOW_DESCRIPTION', WORKFLOW_SCOPE='$WORKFLOW_SCOPE'"

  if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
    echo "DEBUG: initialize_workflow_paths FAILED with exit code $?"
    exit 1
  fi

  echo "DEBUG: initialize_workflow_paths succeeded"
  echo "DEBUG: TOPIC_PATH='${TOPIC_PATH:-NOT_SET}'"
  ```

- [ ] **Create Minimal Reproduction Test**: Isolate the issue
  ```bash
  # Create standalone test script
  cat > /tmp/coordinate_minimal_test.sh << 'TESTSCRIPT'
  #!/usr/bin/env bash
  set -euo pipefail
  set -x

  # Simulate coordinate.md first bash block
  CLAUDE_PROJECT_DIR="/home/benjamin/.config"
  export CLAUDE_PROJECT_DIR

  WORKFLOW_DESCRIPTION="test workflow"
  export WORKFLOW_DESCRIPTION

  # Source libraries in same order as coordinate.md
  LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

  echo "Sourcing workflow-state-machine.sh..."
  source "${LIB_DIR}/workflow-state-machine.sh"

  echo "Sourcing state-persistence.sh..."
  source "${LIB_DIR}/state-persistence.sh"

  # ... continue with initialization steps ...

  echo "Test completed successfully"
  TESTSCRIPT

  bash /tmp/coordinate_minimal_test.sh
  ```

- [ ] **Check for Hidden Characters**: Scan for non-printable characters
  ```bash
  # Check coordinate.md for hidden characters around error lines
  sed -n '245,265p' .claude/commands/coordinate.md | od -c

  # Check library files
  sed -n '245,265p' .claude/lib/workflow-initialization.sh | od -c
  ```

- [ ] **Test with Different Bash Versions**: Rule out version-specific issues
  ```bash
  bash --version
  # Try with explicit bash invocation:
  /bin/bash /tmp/coordinate_minimal_test.sh
  /usr/bin/env bash /tmp/coordinate_minimal_test.sh
  ```

- [ ] **Capture Complete Error Context**: Get full error output
  ```bash
  # Run coordinate with full error capture
  /coordinate "test" 2>&1 | tee /tmp/coordinate_full_error.log

  # Analyze the log
  grep -n "!:" /tmp/coordinate_full_error.log
  grep -B5 -A5 "command not found" /tmp/coordinate_full_error.log
  ```

**Expected Outputs:**
- Detailed execution trace showing exact failure point
- Identification of which library/function causes the error
- Understanding of line number discrepancy
- Minimal reproduction case that reliably triggers the error

**Files Modified:**
- `.claude/commands/coordinate.md` (temporary diagnostic additions)
- Create: `/tmp/coordinate_minimal_test.sh`
- Create: `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/diagnostics/`

**Expected Duration**: 90-120 minutes

---

### Phase 2: Implement Targeted Fix Based on Diagnostics
**Objective**: Apply specific fix based on Phase 1 findings
**Complexity**: Medium (depends on root cause)
**Priority**: CRITICAL

**Conditional Fixes** (apply based on Phase 1 results):

#### Fix Option A: Library Sourcing Order Issue
**If diagnostics show**: Error occurs during specific library sourcing

```bash
# Reorder library sourcing
# Try loading workflow-initialization.sh earlier
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
```

#### Fix Option B: Variable Expansion Context Issue
**If diagnostics show**: Error occurs during variable expansion

```bash
# Add explicit context control
(
  # Run initialization in subshell with controlled environment
  set +H 2>/dev/null || true  # Disable history if enabled
  shopt -u histexpand 2>/dev/null || true  # Alternative disable method

  initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"

  # Export results back to parent
  echo "TOPIC_PATH=$TOPIC_PATH"
) | while IFS='=' read -r var val; do
  export "$var=$val"
done
```

#### Fix Option C: Bash Block Separation Issue
**If diagnostics show**: Problem with how bash blocks are executed

```bash
# Add explicit state preservation between blocks
# At end of first bash block:
declare -p > /tmp/coordinate_state_block1.sh

# At start of second bash block:
source /tmp/coordinate_state_block1.sh
```

#### Fix Option D: Character Encoding Issue
**If diagnostics show**: Hidden characters causing problems

```bash
# Re-save coordinate.md with clean encoding
iconv -f UTF-8 -t UTF-8 -c .claude/commands/coordinate.md > /tmp/coordinate_clean.md
mv /tmp/coordinate_clean.md .claude/commands/coordinate.md
```

#### Fix Option E: Function Definition Issue
**If diagnostics show**: Problem with how functions are exported

```bash
# Explicitly re-export functions after sourcing
export -f initialize_workflow_paths
export -f reconstruct_report_paths_array
export -f display_brief_summary
export -f handle_state_error
```

**Tasks:**
- [ ] Analyze Phase 1 diagnostic output
- [ ] Select appropriate fix option(s)
- [ ] Implement chosen fix
- [ ] Test with minimal reproduction case
- [ ] Test with full /coordinate workflow
- [ ] Document why this fix addresses the root cause

**Files Modified:**
- `.claude/commands/coordinate.md` (apply fix)
- Possibly `.claude/lib/*.sh` (if library changes needed)

**Expected Duration**: 45-60 minutes

---

### Phase 3: Comprehensive Testing & Validation
**Objective**: Verify fix works across all scenarios
**Complexity**: Medium
**Priority**: HIGH

**Tasks:**

- [ ] **Test Minimal Cases**:
  ```bash
  # Test 1: Simple research workflow
  /coordinate "Research bash execution issues"
  # Expected: No errors, TOPIC_PATH set

  # Test 2: Research and plan workflow
  /coordinate "Research and plan a simple feature"
  # Expected: Research completes, plan created
  ```

- [ ] **Test Complex Cases**:
  ```bash
  # Test 3: Full workflow with multiple reports
  /coordinate "Research, plan, and implement authentication system"
  # Expected: All phases complete successfully

  # Test 4: Workflow with special characters in description
  /coordinate "Fix bug: handle !important CSS rules correctly"
  # Expected: Handles ! in description without errors
  ```

- [ ] **Test Error Conditions**:
  ```bash
  # Test 5: Invalid workflow description
  /coordinate ""
  # Expected: Graceful error message

  # Test 6: Missing dependencies
  # Temporarily rename a library file
  mv .claude/lib/workflow-initialization.sh .claude/lib/workflow-initialization.sh.bak
  /coordinate "test"
  # Expected: Clear error about missing library
  mv .claude/lib/workflow-initialization.sh.bak .claude/lib/workflow-initialization.sh
  ```

- [ ] **Test State Persistence**:
  ```bash
  # Test 7: Resume interrupted workflow
  # Start a workflow and intentionally interrupt it
  /coordinate "Long running workflow" &
  COORD_PID=$!
  sleep 5
  kill $COORD_PID

  # Verify state was saved
  ls -la .claude/tmp/workflow_state_*
  ```

- [ ] **Regression Testing**:
  ```bash
  # Run existing test suite
  bash .claude/tests/test_coordinate_*.sh

  # Verify no new failures
  ```

- [ ] **Performance Testing**:
  ```bash
  # Test 8: Measure execution time
  time /coordinate "Quick research task"
  # Compare with historical performance
  ```

**Expected Outcomes:**
- All test cases pass
- No regressions in existing functionality
- Clear error messages for edge cases
- Consistent performance

**Files Modified:** None (testing only)

**Expected Duration**: 60-90 minutes

---

### Phase 4: Documentation & Prevention
**Objective**: Document findings and prevent future occurrences
**Complexity**: Low
**Priority**: MEDIUM

**Tasks:**

- [ ] **Create Diagnostic Runbook**: Document troubleshooting process
  - Location: `.claude/docs/troubleshooting/coordinate-execution-errors.md`
  - Content:
    - Common error patterns
    - Diagnostic commands
    - Step-by-step troubleshooting
    - Known fixes for each error type

- [ ] **Document Root Cause**: Explain what was wrong and why
  - Location: `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/001_root_cause_analysis.md`
  - Content:
    - Initial hypothesis vs actual cause
    - Why standard fixes didn't work
    - Mechanism of failure
    - How fix addresses root cause
    - Lessons learned

- [ ] **Update Command Development Guide**:
  - Location: `.claude/docs/guides/command-development-guide.md`
  - Add section: "Bash Block Execution Considerations"
  - Document best practices learned from this issue

- [ ] **Create Prevention Checklist**:
  ```markdown
  ## Bash Block Best Practices

  - [ ] Add debug logging for complex initialization
  - [ ] Test bash blocks in isolation before integration
  - [ ] Verify library sourcing order
  - [ ] Check for character encoding issues
  - [ ] Test with multiple bash versions
  - [ ] Add error context to all critical operations
  ```

- [ ] **Update Orchestration Troubleshooting Guide**:
  - Location: `.claude/docs/guides/orchestration-troubleshooting.md`
  - Add this case study
  - Reference diagnostic runbook

- [ ] **Create Diagnostic Utility Script**:
  ```bash
  # .claude/scripts/diagnose-coordinate.sh
  #!/usr/bin/env bash
  # Quick diagnostic tool for coordinate execution issues

  echo "=== Coordinate Diagnostic Tool ==="
  echo ""

  echo "Bash Version:"
  bash --version | head -1
  echo ""

  echo "Library Files:"
  ls -lh .claude/lib/*.sh
  echo ""

  echo "Shell Options:"
  bash -c "set -o" | grep -E "history|histexpand"
  echo ""

  echo "Running minimal test..."
  # Run minimal reproduction case
  ```

**Files Created/Modified:**
- `.claude/docs/troubleshooting/coordinate-execution-errors.md` (new)
- `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/001_root_cause_analysis.md` (new)
- `.claude/docs/guides/command-development-guide.md` (update)
- `.claude/docs/guides/orchestration-troubleshooting.md` (update)
- `.claude/scripts/diagnose-coordinate.sh` (new)

**Expected Duration**: 45-60 minutes

---

## Testing Strategy

### Diagnostic Testing (Phase 1)
- Capture complete execution traces
- Test in isolation vs integrated contexts
- Compare working vs failing scenarios
- Document all findings

### Fix Validation (Phase 2)
- Test chosen fix with minimal case
- Gradually increase complexity
- Verify no side effects
- Confirm error is resolved

### Comprehensive Testing (Phase 3)
- Unit tests (individual functions)
- Integration tests (full workflows)
- Regression tests (existing functionality)
- Edge case testing
- Performance validation

## Risk Assessment

### Low Risk
- Diagnostic additions are temporary and can be removed
- Testing is non-destructive
- Changes are localized to coordinate.md

### Medium Risk
- Fix may require library modifications
- Potential for introducing new issues
- May affect other orchestration commands

### Mitigation Strategies
- Keep all diagnostic output for analysis
- Make atomic commits for easy rollback
- Test each change incrementally
- Maintain backup of working code
- Document all changes thoroughly

### Rollback Plan
```bash
# If fix causes issues:
git log --oneline --grep="620" | head -5
git revert <commit-hash>

# Or restore from backup:
cp .claude/commands/coordinate.md.backup .claude/commands/coordinate.md
```

## Dependencies

### Prerequisites
- Spec 617 completed (verified working in isolation)
- Access to test /coordinate command
- Ability to add temporary diagnostic code
- Bash 4.3+ for testing

### No Breaking Changes Expected
- Fixes should be additive or corrective
- No API changes required
- Library interfaces remain stable

## Expected Outcomes

### Phase 1 Outcomes
- Clear understanding of failure mechanism
- Identification of exact error source
- Minimal reproduction case
- Diagnostic tools for future use

### Phase 2 Outcomes
- Targeted fix that addresses root cause
- Verification that fix resolves issue
- No introduction of new problems

### Phase 3 Outcomes
- Comprehensive test coverage
- Confidence in fix robustness
- Performance validation

### Phase 4 Outcomes
- Complete documentation of issue and solution
- Prevention guidelines for future development
- Improved troubleshooting capabilities

## Notes for Implementation

### Why This Approach is Different

**Previous Attempt** (didn't work):
- Applied `set +H` based on history expansion hypothesis
- Standard fix for standard problem

**This Approach** (diagnostic-first):
- Acknowledges this is NOT a standard issue
- Requires understanding before fixing
- Systematic, evidence-based approach
- Multiple fix options based on findings

### Key Insights from Research

1. **History expansion is already OFF** - This is not the issue
2. **Libraries work in isolation** - Problem is integration/context
3. **Line numbers are mysterious** - Suggests execution context issue
4. **Standard fixes failed** - Confirms this needs deeper investigation

### Implementation Philosophy

**Measure twice, cut once:**
- Phase 1 is diagnostic heavy (intentionally)
- Don't guess at fixes
- Let evidence guide the solution
- Create reusable diagnostic tools

**Be prepared for surprises:**
- Root cause may be unexpected
- May need multiple iterations
- Document everything learned
- Build knowledge for future issues

## Success Metrics

- [ ] `/coordinate` executes without "!: command not found" errors
- [ ] TOPIC_PATH initialized successfully
- [ ] All workflow types functional (research-only, research-and-plan, full)
- [ ] No regressions in existing functionality
- [ ] Root cause fully understood and documented
- [ ] Diagnostic tools created for future troubleshooting
- [ ] Prevention guidelines established

---

## Summary

This plan takes a **diagnostic-first approach** to resolve the mysterious bash execution failures in coordinate.md. Rather than applying standard fixes that have already failed, we systematically:

1. **Diagnose** with extensive logging and testing to understand the true failure mechanism
2. **Fix** based on evidence from diagnostics, with multiple options prepared
3. **Validate** comprehensively across all use cases
4. **Document** to prevent recurrence and enable faster future troubleshooting

**Estimated Total Time**: 3.5-5 hours across 4 phases
**Risk Level**: Low-Medium (diagnostic approach minimizes risk)
**Impact**: Unblocks /coordinate and establishes robust troubleshooting methodology

**Critical Success Factor**: Phase 1 must reveal the true root cause before proceeding to Phase 2. Do not guess at fixes - let the diagnostics guide the solution.
