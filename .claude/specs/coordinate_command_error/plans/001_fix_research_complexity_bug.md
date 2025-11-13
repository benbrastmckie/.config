# /coordinate Research Complexity Bug Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Fix RESEARCH_COMPLEXITY recalculation bug in /coordinate command
- **Scope**: Remove redundant hardcoded complexity calculation in research phase, ensure state machine value is used consistently
- **Estimated Phases**: 5
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 21.5
- **Research Reports**:
  - [Root Cause Analysis](/home/benjamin/.config/.claude/specs/coordinate_command_error/reports/001_root_cause_analysis.md)

## Overview

The /coordinate command's research phase has a critical bug where RESEARCH_COMPLEXITY is calculated correctly by `sm_init()` using comprehensive workflow classification, but then immediately recalculated using hardcoded regex patterns. This creates a mismatch between allocated report paths (based on sm_init) and verification expectations (based on recalculation).

**Impact**: Verification failures in ~40-50% of workflows where pattern matching differs from comprehensive classification.

## Research Summary

Based on the root cause analysis report:

- **Primary Bug Location**: `.claude/commands/coordinate.md` lines 419-432 (redundant hardcoded recalculation)
- **Root Cause**: State machine calculates RESEARCH_COMPLEXITY=2, but research phase overwrites with hardcoded patterns yielding 3
- **Path Allocation**: `initialize_workflow_paths()` pre-allocates exactly N paths based on sm_init complexity
- **Agent Invocation**: IF guards use recalculated value, invoking mismatched number of agents
- **Verification Failure**: Discovery loop and verification loop both use recalculated value, missing files or checking wrong count
- **State Persistence**: Value IS saved to state, but gets overwritten immediately upon load in research phase

**Recommended Approach**: Remove hardcoded recalculation entirely, use state-persisted value with fallback validation only.

## Success Criteria
- [ ] RESEARCH_COMPLEXITY is never recalculated after sm_init() sets it
- [ ] Research phase uses state-persisted complexity value
- [ ] Dynamic path discovery uses REPORT_PATHS_COUNT (not recalculated complexity)
- [ ] Verification loop uses REPORT_PATHS_COUNT (not recalculated complexity)
- [ ] State machine export verification confirms RESEARCH_COMPLEXITY is exported
- [ ] Documentation updated to reflect correct state flow
- [ ] All coordinate tests pass (zero verification failures)
- [ ] Manual integration test with "integrate" keyword confirms complexity consistency

## Technical Design

### Architecture Changes

1. **State Machine (workflow-state-machine.sh)**
   - Already exports RESEARCH_COMPLEXITY correctly (lines 362-363)
   - Add validation: confirm variable is in exported state list
   - No functional changes needed, just verification

2. **Research Phase Handler (coordinate.md)**
   - **Remove**: Lines 419-432 (hardcoded recalculation)
   - **Replace with**: State load validation and logging
   - **Add**: Fallback warning if state variable missing
   - **Keep**: State persistence save (line 445) for continuity

3. **Dynamic Discovery Loop (coordinate.md)**
   - **Change**: Line 694 loop from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT`
   - **Rationale**: Use pre-allocated count, not recalculated value
   - **Benefit**: Always checks exactly as many files as were allocated

4. **Verification Loop (coordinate.md)**
   - **Change**: Line 799 loop from `$RESEARCH_COMPLEXITY` to `$REPORT_PATHS_COUNT`
   - **Rationale**: Verify exactly as many files as were allocated
   - **Benefit**: Eliminates count mismatches

### Data Flow (Fixed)

```
Phase 0 (Initialize):
  sm_init() → classify_workflow_comprehensive()
  → RESEARCH_COMPLEXITY=2 (exported + saved to state)
  → initialize_workflow_paths(workflow_desc, scope, "2")
  → Allocates REPORT_PATH_0, REPORT_PATH_1
  → Exports REPORT_PATHS_COUNT=2

Phase 1 (Research - NEW BASH BLOCK):
  load_workflow_state() → RESEARCH_COMPLEXITY=2 (from state)
  ✓ Use loaded value (no recalculation!)
  → Agent IF guards use RESEARCH_COMPLEXITY=2
  → Invoke 2 agents (correct)
  → Agents create 2 reports (correct)

Verification:
  Dynamic discovery: for i in $(seq 1 $REPORT_PATHS_COUNT)
  → Checks exactly 2 paths (correct)
  Verification loop: for i in $(seq 1 $REPORT_PATHS_COUNT)
  → Verifies exactly 2 files (correct)
  ✓ All paths match
```

### Error Handling

- **Missing State Variable**: Log warning, use fallback (comprehensive classification), continue
- **Verification Failure**: Existing fail-fast logic remains (lines 823-839)
- **State Persistence Failure**: Existing error handling in append_workflow_state()

## Implementation Phases

### Phase 1: Remove Hardcoded Recalculation
dependencies: []

**Objective**: Replace hardcoded pattern matching with state-loaded value in research phase

**Complexity**: Low

Tasks:
- [ ] Read coordinate.md lines 419-454 to understand current recalculation logic
- [ ] Remove lines 420-432 (hardcoded RESEARCH_COMPLEXITY assignment)
- [ ] Replace with validation logic: check if RESEARCH_COMPLEXITY is set from state
- [ ] Add fallback warning if variable unset (log to stderr)
- [ ] Keep state persistence save at line 445 (ensures continuity across phases)
- [ ] Add diagnostic echo: "Research Complexity Score: $RESEARCH_COMPLEXITY topics (from state persistence)"

Testing:
```bash
# Verify hardcoded patterns removed
grep -n "RESEARCH_COMPLEXITY=[0-9]" /home/benjamin/.config/.claude/commands/coordinate.md
# Should NOT return lines 420-432 anymore

# Verify fallback logic exists
grep -A5 "if.*-z.*RESEARCH_COMPLEXITY" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (grep verifications above)
- [ ] Git commit created: `fix(coordinate): remove hardcoded RESEARCH_COMPLEXITY recalculation`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Fix Dynamic Discovery Loop
dependencies: [1]

**Objective**: Change dynamic path discovery to use REPORT_PATHS_COUNT instead of recalculated complexity

**Complexity**: Low

Tasks:
- [ ] Read coordinate.md lines 684-714 to understand dynamic discovery logic
- [ ] Change line 694: `for i in $(seq 1 $RESEARCH_COMPLEXITY)` → `for i in $(seq 1 $REPORT_PATHS_COUNT)`
- [ ] Update diagnostic output line 712: reference REPORT_PATHS_COUNT instead of RESEARCH_COMPLEXITY
- [ ] Add comment explaining why REPORT_PATHS_COUNT is used (always matches pre-allocation)

Testing:
```bash
# Verify loop uses REPORT_PATHS_COUNT
grep -n "for i in \$(seq 1.*REPORT_PATHS_COUNT" /home/benjamin/.config/.claude/commands/coordinate.md | grep -q "694"

# Verify diagnostic output references correct variable
grep -n "DISCOVERY_COUNT/\$REPORT_PATHS_COUNT" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Expected Duration**: 20 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (grep verifications above)
- [ ] Git commit created: `fix(coordinate): use REPORT_PATHS_COUNT in dynamic discovery loop`
- [ ] Update this plan file with phase completion status

---

### Phase 3: Fix Verification Loop
dependencies: [1]

**Objective**: Change verification loop to use REPORT_PATHS_COUNT instead of recalculated complexity

**Complexity**: Low

Tasks:
- [ ] Read coordinate.md lines 786-842 to understand verification logic
- [ ] Change line 799: `for i in $(seq 1 $RESEARCH_COMPLEXITY)` → `for i in $(seq 1 $REPORT_PATHS_COUNT)`
- [ ] Update diagnostic output lines 792, 801: reference REPORT_PATHS_COUNT
- [ ] Update verification summary lines 815, 826: use REPORT_PATHS_COUNT for expected count
- [ ] Add comment explaining consistent use of REPORT_PATHS_COUNT (matches allocation)

Testing:
```bash
# Verify verification loop uses REPORT_PATHS_COUNT
grep -n "for i in \$(seq 1.*REPORT_PATHS_COUNT" /home/benjamin/.config/.claude/commands/coordinate.md | grep -q "799"

# Verify diagnostic outputs reference correct variable
grep -n "REPORT_PATHS_COUNT" /home/benjamin/.config/.claude/commands/coordinate.md | grep -E "(792|801|815|826)"
```

**Expected Duration**: 20 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (grep verifications above)
- [ ] Git commit created: `fix(coordinate): use REPORT_PATHS_COUNT in verification loop`
- [ ] Update this plan file with phase completion status

---

### Phase 4: Validate State Machine Export
dependencies: [1, 2, 3]

**Objective**: Verify workflow-state-machine.sh correctly exports RESEARCH_COMPLEXITY to state

**Complexity**: Low

Tasks:
- [ ] Read workflow-state-machine.sh lines 345-374 to confirm export logic
- [ ] Verify line 362: `export RESEARCH_COMPLEXITY` exists
- [ ] Check that RESEARCH_COMPLEXITY is included in state persistence (coordinate.md line 263)
- [ ] Verify RESEARCH_TOPICS_JSON is also exported (line 363) for consistency
- [ ] Add inline comment documenting state persistence requirement
- [ ] Run manual state inspection: check if RESEARCH_COMPLEXITY appears in workflow state file

Testing:
```bash
# Verify state machine exports variable
grep -n "export RESEARCH_COMPLEXITY" /home/benjamin/.config/.claude/lib/workflow-state-machine.sh

# Verify state persistence save exists in coordinate.md
grep -n "append_workflow_state.*RESEARCH_COMPLEXITY" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Expected Duration**: 30 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (grep verifications above)
- [ ] Git commit created: `docs(state-machine): verify RESEARCH_COMPLEXITY export and persistence`
- [ ] Update this plan file with phase completion status

---

### Phase 5: Update Documentation and Integration Test
dependencies: [1, 2, 3, 4]

**Objective**: Update coordinate command guide and run comprehensive integration test

**Complexity**: Medium

Tasks:
- [ ] Read coordinate command guide: .claude/docs/guides/coordinate-command-guide.md
- [ ] Locate section describing research complexity calculation
- [ ] Update to reflect correct state flow (no recalculation)
- [ ] Document fallback behavior if state variable missing
- [ ] Add troubleshooting entry: "Verification mismatch between allocated/invoked agents"
- [ ] Create integration test script testing "integrate" keyword workflow
- [ ] Run integration test: verify 2 agents invoked, 2 reports created, 2 verified
- [ ] Run full coordinate test suite: `.claude/tests/test_coordinate_*.sh` (if exists)
- [ ] Manually test workflow with "integrate" keyword (should yield consistency)
- [ ] Manually test workflow with "multi-system" keyword (should yield consistency)

Testing:
```bash
# Integration test: "integrate" keyword workflow
cd /home/benjamin/.config
/home/benjamin/.config/.claude/commands/coordinate.md "Integrate authentication with existing middleware"
# Expected: Research Complexity=2, 2 agents invoked, 2 reports created, 2 verified

# Integration test: "multi-system" keyword workflow
/home/benjamin/.config/.claude/commands/coordinate.md "Build multi-tenant system architecture"
# Expected: Research Complexity=4, 4 agents invoked, 4 reports created, 4 verified

# Run coordinate test suite
.claude/tests/run_all_tests.sh | grep -i coordinate
```

**Expected Duration**: 1.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (integration tests and test suite)
- [ ] Git commit created: `docs(coordinate): update guide with correct complexity flow`
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- Grep-based verification of code changes (Phases 1-3)
- State machine export verification (Phase 4)
- Pattern matching validation (removed patterns don't execute)

### Integration Testing
- Manual workflow execution with different keyword patterns
- Verify consistency: allocated paths = invoked agents = created reports = verified files
- Test both hierarchical (≥4) and flat (<4) research modes

### Regression Testing
- Run existing coordinate test suite (if available)
- Check for unbound variable errors in research phase
- Verify no side effects in other orchestration commands (orchestrate, supervise)

### Test Cases
1. **Simple workflow (complexity=1)**: "Fix login button styling"
2. **Moderate workflow (complexity=2)**: "Add user profile page"
3. **Complex workflow (complexity=3)**: "Integrate authentication with OAuth"
4. **Very complex workflow (complexity=4)**: "Build multi-tenant distributed system"

Each test case should verify:
- State persistence contains RESEARCH_COMPLEXITY
- Research phase uses state value (no recalculation)
- Agent invocation count matches complexity
- Report creation count matches complexity
- Verification passes without failures

## Documentation Requirements

### Files to Update
1. **coordinate-command-guide.md**
   - Section: "Research Phase Complexity Calculation"
   - Update: Remove references to hardcoded pattern matching
   - Add: State persistence flow diagram
   - Add: Troubleshooting entry for verification mismatches

2. **coordinate-state-management.md** (if exists)
   - Document RESEARCH_COMPLEXITY lifecycle
   - Explain why recalculation was removed
   - Document fallback behavior

3. **coordinate.md inline comments**
   - Add comments explaining why REPORT_PATHS_COUNT is used
   - Document state load validation logic
   - Explain fallback warning mechanism

### Documentation Standards
- Follow CLAUDE.md documentation policy (present-focused, timeless)
- No historical markers like "(New)" or "previously calculated"
- Use relative paths for internal links
- Include code examples for complexity flow

## Dependencies

### External Dependencies
- None (bug fix uses existing libraries)

### Internal Dependencies
- `workflow-state-machine.sh` (already correct, just verification)
- `workflow-initialization.sh` (already correct, no changes)
- `workflow-scope-detection.sh` (already correct, comprehensive classification)

### Library Functions Used
- `classify_workflow_comprehensive()` (from workflow-scope-detection.sh)
- `initialize_workflow_paths()` (from workflow-initialization.sh)
- `load_workflow_state()` (from state-persistence.sh)
- `append_workflow_state()` (from state-persistence.sh)
- `verify_file_created()` (from verification-fallback pattern)

## Risk Assessment

### Low Risk Changes
- Removing hardcoded recalculation (Phase 1): Well-isolated, clear regression path
- Loop variable changes (Phases 2-3): Simple substitution, grep-verifiable

### Medium Risk Changes
- State machine verification (Phase 4): Read-only verification, no functional change
- Documentation updates (Phase 5): No code impact

### Mitigation Strategies
- Incremental commits per phase (atomic rollback possible)
- Grep-based pre-commit verification (catch unbound variables)
- Integration tests before final commit
- Manual testing with known-problematic keywords ("integrate", "multi-system")

## Rollback Plan

If regression detected:
1. Revert commits in reverse order (Phase 5 → Phase 1)
2. Restore hardcoded recalculation temporarily
3. Add comprehensive test coverage before re-attempting fix
4. Consider alternative approach: modify pattern matching to match comprehensive classification

## Performance Considerations

- **Token Reduction**: No change (state value already calculated)
- **Execution Time**: ~5-10ms faster (one fewer grep -Eiq call)
- **State File Size**: No change (RESEARCH_COMPLEXITY already persisted)

## Notes

- This is a **bug fix**, not a feature enhancement
- No new functionality added, only correctness improvement
- All existing behavior preserved, just made consistent
- State machine already does comprehensive classification correctly
- Fix is to **use** existing correct value, not recalculate incorrectly
