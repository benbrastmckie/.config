# /coordinate Error Fixes Implementation Plan

## Metadata
- **Date**: 2025-11-13
- **Feature**: Fix critical /coordinate command errors
- **Scope**: Address bash history expansion, sm_init export failures, state persistence issues, and LLM classification reliability
- **Estimated Phases**: 6
- **Estimated Hours**: 18
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Bash History Expansion Analysis](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/001_bash_history_expansion_analysis.md)
  - [sm_init Export Analysis](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/002_sm_init_export_analysis.md)
  - [State Persistence Reliability Analysis](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/003_state_persistence_reliability_analysis.md)
  - [LLM Classification Reliability Analysis](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/004_llm_classification_reliability_analysis.md)

## Overview

The /coordinate command suffers from four critical error categories that prevent reliable workflow execution:

1. **Bash History Expansion Errors**: The `!` operator in `if ! sm_init` triggers Bash tool preprocessing failures before script execution
2. **sm_init Export Failures**: Variables exported by sm_init() are lost across bash block subprocess boundaries due to missing state persistence
3. **State File Persistence Issues**: Path inconsistency between `${HOME}/.claude/tmp/` and `${CLAUDE_PROJECT_DIR}/.claude/tmp/` causes state ID file discovery failures
4. **LLM Classification Reliability**: Offline scenarios timeout after 10 seconds with suppressed error messages, requiring manual mode switch

This plan implements targeted fixes for each category with comprehensive testing and backward compatibility preservation.

## Research Summary

### Key Findings from Research Reports

**Report 1 - Bash History Expansion** (001_bash_history_expansion_analysis.md):
- Root cause: Bash tool preprocessing occurs before bash interpreter execution, making `set +H` ineffective
- Error location: coordinate.md:166 - `if ! sm_init` is unprotected bare negation
- 13 bash blocks affected, 26 total '!' operators (only 1 vulnerable)
- Solution: Capture exit code pattern instead of bare negation

**Report 2 - sm_init Export Analysis** (002_sm_init_export_analysis.md):
- Root cause: Bash block subprocess isolation prevents export propagation
- sm_init() exports correctly within its subprocess, but exports are lost when subprocess terminates
- Missing persistence: RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON never saved to state file
- Solution: Add append_workflow_state() calls for all sm_init exports

**Report 3 - State Persistence Reliability** (003_state_persistence_reliability_analysis.md):
- Root cause: Path inconsistency - state ID file uses `${HOME}/.claude/tmp/`, workflow state uses `${CLAUDE_PROJECT_DIR}/.claude/tmp/`
- Failure mechanism: Block 2 can't find state ID file, generates new workflow ID using $$, fails to load state
- When HOME != CLAUDE_PROJECT_DIR (e.g., /home/benjamin vs /home/benjamin/.config), state files fragment across two directories
- Solution: Standardize all temp files on `${CLAUDE_PROJECT_DIR}/.claude/tmp/`

**Report 4 - LLM Classification Reliability** (004_llm_classification_reliability_analysis.md):
- Root cause: stderr suppression in sm_init() hides actionable error messages
- File-based signaling timeout (10s) required for offline detection with no network pre-flight check
- Error messages suggest regex-only mode but are hidden by `2>/dev/null`
- Solution: Remove stderr suppression, add network pre-flight check, improve error visibility

### Recommended Approach

**Phase Dependencies**: This plan uses wave-based parallel execution where possible:
- Phase 1 (foundation): No dependencies - can start immediately
- Phases 2-5 (fixes): Independent implementations that can run in parallel after Phase 1
- Phase 6 (validation): Depends on all previous phases completing

**Architectural Principles**:
1. **Fail-fast error detection**: Detect issues immediately with clear diagnostics
2. **Path consistency**: All temp files use CLAUDE_PROJECT_DIR
3. **Error visibility**: Preserve actionable error messages throughout call stack
4. **Backward compatibility**: Maintain existing test suite pass rate (100%)

## Success Criteria

- [ ] Bash history expansion: All '!' operators use safe patterns (exit code capture or bracket tests)
- [ ] sm_init exports: RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON persist across bash blocks
- [ ] State persistence: 100% reliability with HOME != CLAUDE_PROJECT_DIR configurations
- [ ] LLM classification: Offline scenarios fail in <2s with clear error messages
- [ ] Test suite: All 127 state machine tests pass, all coordinate tests pass
- [ ] Backward compatibility: No breaking changes to command interface or state file format
- [ ] Documentation: All fixes documented in coordinate-command-guide.md

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Test Coverage Baseline                            │
│ - Run existing test suite                                   │
│ - Document passing/failing tests                            │
│ - Create regression detection suite                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2-5: Parallel Implementation (Wave 1)                │
├─────────────────────────────────────────────────────────────┤
│ Phase 2: Bash History   │ Phase 3: sm_init Exports         │
│ - Replace ! operators    │ - Add state persistence calls    │
│ - Exit code capture      │ - Update verification messages   │
│ - Test scan script       │ - Post-load verification         │
├─────────────────────────────────────────────────────────────┤
│ Phase 4: State Files    │ Phase 5: LLM Classification      │
│ - Path standardization   │ - Remove stderr suppression      │
│ - CLAUDE_PROJECT_DIR     │ - Network pre-flight check       │
│ - Verification checks    │ - Error message improvements     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 6: Integration and Validation (Wave 2)               │
│ - Full workflow testing                                      │
│ - Performance validation                                     │
│ - Documentation updates                                      │
└─────────────────────────────────────────────────────────────┘
```

### Component Interactions

**State Persistence Flow (Fixed)**:
```
Bash Block 1 (Initialize):
  sm_init() exports → WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
  append_workflow_state() persists → ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_$ID.sh
  echo $WORKFLOW_ID → ${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt

Bash Block 2 (Research):
  WORKFLOW_ID=$(cat ${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt)
  load_workflow_state() sources → ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_$ID.sh
  Verification checks → WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON all set
```

**Error Visibility Flow (Fixed)**:
```
classify_workflow_comprehensive() fails → stderr messages preserved
  ↓
sm_init() receives error → stderr forwarded (NOT suppressed)
  ↓
coordinate.md sees error → actionable messages visible to user
  ↓
User sees: "Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work"
```

### Integration Points

1. **coordinate.md** (primary command file):
   - Lines 166-168: sm_init invocation (Phase 2, Phase 3)
   - Lines 148-154: State ID file creation (Phase 4)
   - Lines 173-185: Export verification (Phase 3)
   - Lines 392+: State loading in subsequent blocks (Phase 4)

2. **workflow-state-machine.sh** (state machine library):
   - Line 352: stderr suppression removal (Phase 5)
   - Lines 337-383: sm_init function (Phase 3)

3. **workflow-llm-classifier.sh** (LLM classification):
   - Lines 218-273: invoke_llm_classifier timeout (Phase 5)
   - Add network pre-flight check (Phase 5)

4. **state-persistence.sh** (state management):
   - Lines 115-142: init_workflow_state (Phase 4)
   - Lines 185-227: load_workflow_state diagnostics (Phase 4)

## Implementation Phases

### Phase 1: Test Coverage Baseline and Regression Detection [COMPLETED]
dependencies: []

**Objective**: Establish test baseline and create regression detection for all four error categories

**Complexity**: Low

**Tasks**:
- [x] Run existing test suite and document results (file: .claude/tests/run_all_tests.sh)
- [x] Identify tests related to coordinate command (file: .claude/tests/test_coordinate_*.sh)
- [x] Create test_coordinate_preprocessing.sh for bash history expansion regression detection (lines from Report 1:334-376)
- [x] Create test_sm_init_state_persistence.sh for export persistence validation (lines from Report 2:359-407)
- [x] Create test_state_file_path_consistency.sh for path validation (lines from Report 3:421-469)
- [x] Create test_offline_classification.sh for LLM error visibility (lines from Report 4:363-395)
- [x] Run new test suite and establish baseline metrics
- [x] Document any existing failures for comparison after fixes

**Testing**:
```bash
# Run all new tests
cd /home/benjamin/.config/.claude/tests
./test_coordinate_preprocessing.sh
./test_sm_init_state_persistence.sh
./test_state_file_path_consistency.sh
./test_offline_classification.sh

# Verify test infrastructure
./run_all_tests.sh | tee /tmp/phase1_baseline.log
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(700): complete Phase 1 - Test Coverage Baseline`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Fix Bash History Expansion Error
dependencies: [1]

**Objective**: Replace bare '!' operator at line 166 with exit code capture pattern

**Complexity**: Low

**Tasks**:
- [ ] Analyze coordinate.md:166-168 for exact context (file: .claude/commands/coordinate.md)
- [ ] Replace `if ! sm_init` with exit code capture pattern (lines from Report 1:254-278)
- [ ] Verify stderr output is still captured via 2>&1
- [ ] Update inline comment to document workaround rationale
- [ ] Run test_coordinate_preprocessing.sh to verify no unprotected operators remain
- [ ] Run coordinate command in test environment to verify fix
- [ ] Document pattern in bash-block-execution-model.md if not already present

**Testing**:
```bash
# Verify pattern replacement
cd /home/benjamin/.config/.claude/commands
grep -n "if ! sm_init" coordinate.md  # Should return no results

# Test coordinate initialization
cd /home/benjamin/.config
export WORKFLOW_CLASSIFICATION_MODE=regex-only
echo "test workflow" | /coordinate  # Should not produce "!: command not found"

# Run regression test
.claude/tests/test_coordinate_preprocessing.sh
```

**Expected Duration**: 1.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(700): complete Phase 2 - Fix Bash History Expansion`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Fix sm_init Export Persistence
dependencies: [1]

**Objective**: Persist RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON to workflow state

**Complexity**: Medium

**Tasks**:
- [ ] Add append_workflow_state calls after sm_init verification (file: .claude/commands/coordinate.md:185-210)
- [ ] Add persistence for RESEARCH_COMPLEXITY (line from Report 2:240)
- [ ] Add persistence for RESEARCH_TOPICS_JSON (line from Report 2:241)
- [ ] Update verification error messages to remove "library bug" label (lines from Report 2:262-277)
- [ ] Move verification to research block for cross-block validation (lines from Report 2:283-311)
- [ ] Add documentation comment to sm_init() explaining export lifetime (lines from Report 2:318-342)
- [ ] Test state persistence across bash block boundaries
- [ ] Verify all three variables (WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON) load correctly

**Testing**:
```bash
# Test sm_init state persistence
.claude/tests/test_sm_init_state_persistence.sh

# Full coordinate workflow test
cd /home/benjamin/.config
export WORKFLOW_CLASSIFICATION_MODE=regex-only
echo "Research authentication patterns" > /tmp/test_workflow.txt
cat /tmp/test_workflow.txt | .claude/commands/coordinate.md

# Verify state file contains all three variables
STATE_FILE=$(cat ~/.config/.claude/tmp/coordinate_state_id.txt)
grep "RESEARCH_COMPLEXITY" ~/.config/.claude/tmp/workflow_$STATE_FILE.sh
grep "RESEARCH_TOPICS_JSON" ~/.config/.claude/tmp/workflow_$STATE_FILE.sh
```

**Expected Duration**: 3 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(700): complete Phase 3 - Fix sm_init Export Persistence`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Fix State File Path Consistency
dependencies: [1]

**Objective**: Standardize all temp file paths on CLAUDE_PROJECT_DIR

**Complexity**: Medium

**Tasks**:
- [ ] Move CLAUDE_PROJECT_DIR detection to top of Part 2 (file: .claude/commands/coordinate.md:60-62)
- [ ] Update COORDINATE_STATE_ID_FILE to use CLAUDE_PROJECT_DIR (line 148, from Report 3:232-237)
- [ ] Update all bash blocks that reference state ID file (lines 392, 657, 950, 1112, etc.)
- [ ] Update workflow description temp file handling in Part 1 (lines 36-41, from Report 3:296-311)
- [ ] Add path consistency verification checkpoint (lines from Report 3:273-285)
- [ ] Update state-persistence.sh diagnostics to mention state ID file path (lines from Report 3:379-392)
- [ ] Test with HOME != CLAUDE_PROJECT_DIR configuration
- [ ] Verify state files co-located in same directory tree

**Testing**:
```bash
# Test path consistency
.claude/tests/test_state_file_path_consistency.sh

# Test with explicit HOME mismatch
HOME=/home/benjamin CLAUDE_PROJECT_DIR=/home/benjamin/.config bash -c '
  source .claude/lib/state-persistence.sh
  WORKFLOW_ID="test_$(date +%s)"
  init_workflow_state "$WORKFLOW_ID"

  # Verify state file in CLAUDE_PROJECT_DIR
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh" ] || exit 1
  echo "✓ State file correctly placed in CLAUDE_PROJECT_DIR"
'

# Full workflow test
export WORKFLOW_CLASSIFICATION_MODE=regex-only
echo "test workflow" | /coordinate
```

**Expected Duration**: 3.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(700): complete Phase 4 - Fix State File Path Consistency`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Improve LLM Classification Error Visibility
dependencies: [1]

**Objective**: Remove stderr suppression and add network pre-flight check

**Complexity**: Medium

**Tasks**:
- [ ] Remove `2>/dev/null` from sm_init classification call (file: .claude/lib/workflow-state-machine.sh:352)
- [ ] Change to `2>&1` to preserve error messages (line from Report 4:245)
- [ ] Add check_network_connectivity() function to workflow-llm-classifier.sh (lines from Report 4:258-274)
- [ ] Integrate pre-flight check into invoke_llm_classifier() (lines from Report 4:276-282)
- [ ] Update coordinate.md verification error message (line 174, from Report 4:332-338)
- [ ] Add offline mode quick start to error messages (lines from Report 4:348-355)
- [ ] Test offline scenario (network disabled, should fail in <2s)
- [ ] Test online scenario (network available, should work normally)
- [ ] Verify error messages are visible and actionable

**Testing**:
```bash
# Test offline classification
.claude/tests/test_offline_classification.sh

# Manual offline test (disable network or set long timeout)
export WORKFLOW_CLASSIFICATION_MODE=llm-only
export WORKFLOW_CLASSIFICATION_TIMEOUT=2
output=$(echo "test" | .claude/lib/workflow-state-machine.sh 2>&1 || true)
echo "$output" | grep -q "regex-only" && echo "✓ Error message suggests offline mode"

# Manual online test
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset WORKFLOW_CLASSIFICATION_TIMEOUT
# Should work if Claude Code CLI is available
```

**Expected Duration**: 3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(700): complete Phase 5 - Improve LLM Classification Error Visibility`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Integration Testing and Documentation
dependencies: [2, 3, 4, 5]

**Objective**: Validate all fixes work together and update documentation

**Complexity**: High

**Tasks**:
- [ ] Run full coordinate workflow in online mode (file: test coordinate with network)
- [ ] Run full coordinate workflow in offline mode (test with WORKFLOW_CLASSIFICATION_MODE=regex-only)
- [ ] Run full coordinate workflow with HOME != CLAUDE_PROJECT_DIR
- [ ] Verify all 127 state machine tests still pass (file: .claude/tests/test_state_management.sh)
- [ ] Run complete test suite and compare to Phase 1 baseline
- [ ] Update coordinate-command-guide.md with all fixes documented (file: .claude/docs/guides/coordinate-command-guide.md)
- [ ] Add troubleshooting section for each error category
- [ ] Update bash-block-execution-model.md with new patterns if needed
- [ ] Create summary of changes for CHANGELOG or commit message
- [ ] Performance validation: offline fail-fast (<2s), online overhead (<1s)

**Testing**:
```bash
# Full test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh | tee /tmp/phase6_final.log

# Compare to baseline
diff /tmp/phase1_baseline.log /tmp/phase6_final.log

# Integration test scenarios
export WORKFLOW_CLASSIFICATION_MODE=regex-only
echo "Research authentication patterns and create implementation plan" | /coordinate

# Verify state persistence
STATE_ID=$(cat ~/.config/.claude/tmp/coordinate_state_id.txt)
source ~/.config/.claude/tmp/workflow_${STATE_ID}.sh
[ -n "$WORKFLOW_SCOPE" ] && echo "✓ WORKFLOW_SCOPE persisted"
[ -n "$RESEARCH_COMPLEXITY" ] && echo "✓ RESEARCH_COMPLEXITY persisted"
[ -n "$RESEARCH_TOPICS_JSON" ] && echo "✓ RESEARCH_TOPICS_JSON persisted"

# Performance test
time (export WORKFLOW_CLASSIFICATION_MODE=llm-only; export WORKFLOW_CLASSIFICATION_TIMEOUT=2; echo "test" | /coordinate 2>&1)
# Should fail in <3s total
```

**Expected Duration**: 5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(700): complete Phase 6 - Integration Testing and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **test_coordinate_preprocessing.sh**: Scan for unprotected '!' operators (Phase 1)
- **test_sm_init_state_persistence.sh**: Validate export persistence across bash blocks (Phase 1)
- **test_state_file_path_consistency.sh**: Verify CLAUDE_PROJECT_DIR path usage (Phase 1)
- **test_offline_classification.sh**: Validate error visibility in offline scenarios (Phase 1)

### Integration Testing
- Full /coordinate workflow in online mode (Phase 6)
- Full /coordinate workflow in offline mode (Phase 6)
- Cross-platform testing with HOME != CLAUDE_PROJECT_DIR (Phase 6)
- State persistence across multiple bash blocks (Phase 6)

### Regression Testing
- All existing state machine tests (127 tests, 100% pass rate required)
- All existing coordinate tests (maintain baseline)
- Performance validation (offline <2s, online overhead <1s)

### Test Coverage Targets
- Bash history expansion: 100% (1 vulnerable operator → 0 vulnerable operators)
- sm_init exports: 100% (3 exports → 3 persisted)
- State file paths: 100% (all paths use CLAUDE_PROJECT_DIR)
- LLM error visibility: 100% (actionable messages visible)

## Documentation Requirements

### Files to Update
1. **coordinate-command-guide.md** (.claude/docs/guides/):
   - Add "Known Limitations" section documenting Bash tool preprocessing
   - Add troubleshooting for each error category
   - Document offline mode quick start
   - Update architecture diagrams for state persistence flow

2. **bash-block-execution-model.md** (.claude/docs/concepts/):
   - Document exit code capture pattern as validated workaround
   - Add path consistency standard for temp files
   - Reference coordinate.md as example implementation

3. **workflow-classification-guide.md** (.claude/docs/guides/):
   - Update error handling section with network pre-flight check
   - Document fast-fail offline behavior (<2s)
   - Add troubleshooting section for offline scenarios

4. **CLAUDE.md** (project root):
   - Add temp file path standard to testing_protocols section (from Report 3:320-348)
   - Reference coordinate fixes as architectural validation

### Documentation Standards
- Use present-focused language (no historical markers)
- Include code examples for each pattern
- Cross-reference all related documentation
- Follow link conventions (relative paths from current file)

## Dependencies

### External Dependencies
- Bash 4.0+ (for array support in state persistence)
- Git (for CLAUDE_PROJECT_DIR detection)
- Network connectivity utilities (ping for pre-flight check in Phase 5)

### Internal Dependencies
- **.claude/lib/workflow-state-machine.sh**: sm_init function (modified in Phase 3, Phase 5)
- **.claude/lib/state-persistence.sh**: init_workflow_state, load_workflow_state (diagnostics updated in Phase 4)
- **.claude/lib/workflow-llm-classifier.sh**: invoke_llm_classifier (modified in Phase 5)
- **.claude/lib/verification-helpers.sh**: verify_file_created (used in Phase 4 verification)
- **.claude/commands/coordinate.md**: Primary fix location (Phases 2-5)

### Phase Dependencies
- Phase 1: No dependencies (foundation)
- Phases 2-5: Depend on Phase 1 (parallel execution possible)
- Phase 6: Depends on Phases 2, 3, 4, 5 (integration)

**Wave-Based Execution**:
- Wave 1: Phase 1 (sequential)
- Wave 2: Phases 2, 3, 4, 5 (parallel - 40-60% time savings)
- Wave 3: Phase 6 (sequential)

## Risk Assessment

### High-Risk Changes
1. **stderr suppression removal (Phase 5)**: May expose previously hidden verbose output
   - **Mitigation**: Test with existing workflows, verify only actionable errors shown

2. **Path standardization (Phase 4)**: Changes temp file locations, may break external scripts
   - **Mitigation**: Both HOME and CLAUDE_PROJECT_DIR paths checked for migration compatibility

### Medium-Risk Changes
1. **Exit code pattern change (Phase 2)**: Changes error handling flow
   - **Mitigation**: Extensive testing, pattern is well-documented in bash-block-execution-model.md

2. **State persistence additions (Phase 3)**: Changes state file format
   - **Mitigation**: Backward compatible (only adds variables, doesn't remove)

### Low-Risk Changes
1. **Network pre-flight check (Phase 5)**: Adds 1s overhead to online scenarios
   - **Mitigation**: Only runs in llm-only mode, skipped if WORKFLOW_CLASSIFICATION_MODE=regex-only

## Performance Considerations

### Expected Improvements
- **Offline detection**: 10s timeout → <2s fail-fast (80% faster)
- **Error diagnosis**: Hidden messages → visible actionable guidance (100% visibility improvement)
- **State recovery**: 100% failure rate → 100% success rate with path fix

### Performance Targets
- Offline failure detection: <2s (currently 10s)
- Online classification overhead: <1s additional (network check)
- State file operations: No measurable change (<10ms)

### Monitoring Points
- LLM classification timeout frequency
- State file discovery failures (should be 0 after Phase 4)
- Test suite execution time (should remain within 10% of baseline)

## Rollback Plan

### Rollback Triggers
- Test suite pass rate drops below 90%
- Critical workflow breakage (coordinate command unusable)
- Performance regression >20%

### Rollback Procedure
1. Revert git commits in reverse phase order (Phase 6 → Phase 5 → ... → Phase 2)
2. Verify test suite returns to baseline
3. Document rollback reason for future investigation

### Safe Rollback Points
- After each phase commit (atomic changes)
- Before Phase 6 integration (all changes tested independently)

## Success Metrics

### Quantitative Metrics
- [ ] Bash history expansion errors: 0 occurrences (currently 1)
- [ ] sm_init export persistence: 100% (currently 33% - only WORKFLOW_SCOPE)
- [ ] State file path consistency: 100% (currently 0% when HOME != CLAUDE_PROJECT_DIR)
- [ ] LLM offline fail-fast: <2s (currently 10s)
- [ ] Test suite pass rate: 100% (maintain baseline)

### Qualitative Metrics
- [ ] Error messages are actionable (user can resolve without deep debugging)
- [ ] Offline mode is discoverable (error suggests regex-only mode)
- [ ] State recovery is reliable (no manual intervention needed)
- [ ] Documentation is comprehensive (troubleshooting covers all four error categories)

## Notes

**Complexity Score Calculation**:
```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
Score = (48 × 1.0) + (6 × 5.0) + (18 × 0.5) + (5 × 2.0)
Score = 48 + 30 + 9 + 10 = 97.0
```

**Hint**: This plan has a complexity score of 97.0, which is below the expansion threshold (50.0) but still significant. Consider using `/expand phase <phase-number>` during implementation if any phase becomes more complex than estimated.

**Wave-Based Execution**: Phases 2-5 can run in parallel after Phase 1 completes, providing 40-60% time savings compared to sequential execution.

**Backward Compatibility**: All changes maintain existing command interfaces and state file formats. Migration code handles both old and new temp file paths.
