# Coordinate Command Error Fix Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Fix coordinate command errors through existing infrastructure integration
- **Scope**: Eliminate unbound variable errors, verification failures, and improve reliability
- **Estimated Phases**: 6
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.5
- **Research Reports**:
  - [Error Patterns Analysis](../reports/001_error_patterns_analysis.md)
  - [Infrastructure Analysis](../reports/002_infrastructure_analysis.md)
  - [Standards Compliance Analysis](../reports/003_standards_compliance_analysis.md)

## Overview

The /coordinate command currently fails during research phase verification due to three primary issues: (1) unbound variable errors from subprocess isolation, (2) verification checkpoint failures from filename mismatches, and (3) incomplete state persistence. This plan fixes these errors by integrating existing infrastructure patterns from .claude/lib/ and following standards from .claude/docs/ to achieve 100% reliability.

## Research Summary

Key findings from research reports inform this implementation:

**From Error Patterns Analysis (001)**:
- USE_HIERARCHICAL_RESEARCH unbound variable error blocks workflow at research verification
- Verification expects generic filenames (001_topic1.md) but agents create descriptive names
- Root cause is subprocess isolation model where exports don't persist across bash blocks
- State persistence gaps exist for variables used across multiple blocks

**From Infrastructure Analysis (002)**:
- State persistence library (state-persistence.sh) provides GitHub Actions-style file-based state
- Bash block execution model documentation validates fixed semantic filenames pattern
- Verification helpers library (verification-helpers.sh) achieves 90% token reduction
- MANDATORY VERIFICATION pattern achieves 100% file creation reliability
- Library re-sourcing pattern (6 critical libraries) prevents "command not found" errors

**From Standards Compliance Analysis (003)**:
- Standard 0 (Execution Enforcement) requires MANDATORY VERIFICATION checkpoints with correct grep patterns
- Bash block execution model requires `set +H` and library re-sourcing in every block
- State management uses selective persistence: file-based for expensive operations, stateless for fast recalculations
- Verification checkpoint grep patterns must match export format: `^export VAR_NAME=`
- Fail-fast principles require enhanced diagnostics, no silent degradation

**Recommended Approach**: Apply validated patterns from existing infrastructure systematically to eliminate all three error categories while maintaining state-based orchestration architecture compliance.

## Success Criteria

- [ ] Zero unbound variable errors in coordinate command execution
- [ ] 100% verification checkpoint success rate (all research reports verified correctly)
- [ ] Zero "command not found" errors for library functions
- [ ] Verification grep patterns match state file export format
- [ ] All bash blocks include required library re-sourcing
- [ ] State persistence covers all variables used across bash blocks
- [ ] Coordinate command completes full research → plan workflow without manual intervention
- [ ] Test suite passes: .claude/tests/test_coordinate_verification.sh

## Technical Design

### Architecture Alignment

**State-Based Orchestration Integration**:
- Maintain existing state machine usage (sm_transition, sm_load, sm_save)
- Apply selective state persistence decision matrix from coordinate-state-management.md
- Use stateless recalculation for WORKFLOW_SCOPE, PHASES_TO_EXECUTE (<1ms)
- Use file-based state for expensive variables only (following 7 criteria)

**Bash Block Execution Model Compliance**:
- Pattern 1: Fixed semantic filenames (coordinate_$(date +%s), not $$)
- Pattern 2: Save-before-source (state ID in fixed location file)
- Pattern 3: State persistence library (load_workflow_state in each block)
- Pattern 4: Library re-sourcing with source guards (all 6 critical libraries)
- Pattern 5: Cleanup traps only in completion function

**Verification Pattern Integration**:
- MANDATORY VERIFICATION checkpoints after research phase
- Verification grep patterns: `^export VAR_NAME=` (matches state-persistence.sh format)
- Use verify_file_created() from verification-helpers.sh (90% token reduction)
- Fallback mechanism: detect errors immediately (fail-fast compliant)

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│ /coordinate Command Execution Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Bash Block 1: Initialization                               │
│ ├─ Standard 13 detection (CLAUDE_PROJECT_DIR)              │
│ ├─ Re-source 6 critical libraries                          │
│ ├─ init_workflow_state() → fixed location file             │
│ ├─ append_workflow_state() for all critical variables      │
│ └─ Export REPORT_PATH_N individually (arrays don't persist)│
│                                                             │
│ Bash Block 2: Research Phase                               │
│ ├─ Re-source libraries (functions lost)                    │
│ ├─ load_workflow_state() from fixed location               │
│ ├─ Invoke research agents with pre-calculated paths        │
│ └─ Save research completion to state                       │
│                                                             │
│ Bash Block 3: Research Verification (FIXED)                │
│ ├─ Re-source libraries                                     │
│ ├─ load_workflow_state() → all variables restored          │
│ ├─ reconstruct_report_paths_array() → array from exports   │
│ ├─ MANDATORY VERIFICATION with correct grep patterns       │
│ │  └─ grep -q "^export REPORT_PATH_0=" "$STATE_FILE"       │
│ └─ verify_file_created() for concise output                │
│                                                             │
│ Bash Block 4+: Plan Phase                                  │
│ ├─ Same pattern: re-source, load state, execute, save      │
│ └─ Consistent state management throughout                  │
└─────────────────────────────────────────────────────────────┘
```

### Error Elimination Strategy

**Category 1: Unbound Variable Errors**
- Comprehensive state variable audit (extract all $VAR references from bash blocks)
- Add missing variables to state persistence (USE_HIERARCHICAL_RESEARCH, WORKFLOW_SCOPE)
- Use append_workflow_state() pattern for all variables used across blocks

**Category 2: Verification Failures**
- Fix grep patterns: add `export ` prefix to match state-persistence.sh format
- Add clarifying comments documenting expected format
- Use verify_file_created() from verification-helpers.sh for consistent checking

**Category 3: Command Not Found Errors**
- Systematically add library re-sourcing block to every bash block
- Include all 6 critical libraries: state-machine, state-persistence, initialization, error-handling, unified-logger, verification-helpers
- Add `set +H` at start of every block (history expansion workaround)

## Implementation Phases

### Phase 1: State Persistence Audit and Fix
dependencies: []

**Objective**: Identify and fix all missing state variable persistence to eliminate unbound variable errors

**Complexity**: Medium

**Tasks**:
- [ ] Audit coordinate.md bash blocks: extract all variable references using grep pattern `\$[A-Z_]+`
- [ ] Create variable usage matrix: which blocks use which variables
- [ ] Identify cross-block variables: used in 2+ bash blocks
- [ ] Add missing variables to state persistence in initialization block (file: .claude/commands/coordinate.md, initialization section)
- [ ] Specifically add USE_HIERARCHICAL_RESEARCH to append_workflow_state calls
- [ ] Add WORKFLOW_SCOPE to state persistence (used in verification)
- [ ] Verify state file format: confirm export prefix used for all variables

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify state file contains all required variables
STATE_FILE="${HOME}/.claude/tmp/workflow_coordinate_test.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
init_workflow_state "coordinate_test"
# Manually append test variables
append_workflow_state "USE_HIERARCHICAL_RESEARCH" "false"
append_workflow_state "WORKFLOW_SCOPE" "research-only"

# Verify export format
grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE" && echo "✓ Format correct"
grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE" && echo "✓ Format correct"
```

**Expected Duration**: 1.5 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (state variable audit verification)
- [ ] Git commit created: `fix(coordinate): add missing state variable persistence (spec 648)`
- [ ] Update this plan file with phase completion status

### Phase 2: Verification Checkpoint Grep Pattern Fix
dependencies: [1]

**Objective**: Correct all verification checkpoint grep patterns to match state-persistence.sh export format

**Complexity**: Low

**Tasks**:
- [ ] Search coordinate.md for all grep patterns checking state variables (file: .claude/commands/coordinate.md)
- [ ] Update grep patterns: add `^export ` prefix to all variable checks
- [ ] Example fix: `grep -q "^REPORT_PATHS_COUNT="` → `grep -q "^export REPORT_PATHS_COUNT="`
- [ ] Add clarifying comments above each grep: "# State file format: export VAR=\"value\" (per state-persistence.sh)"
- [ ] Update USE_HIERARCHICAL_RESEARCH verification grep pattern
- [ ] Update REPORT_PATHS_COUNT verification grep pattern
- [ ] Update REPORT_PATH_N verification grep patterns
- [ ] Verify all verification checkpoints reference state-persistence.sh format in comments

**Testing**:
```bash
# Run coordinate verification test suite
bash "${CLAUDE_PROJECT_DIR}/.claude/tests/test_coordinate_verification.sh"

# Expected: All grep pattern tests pass
# Expected: State variable verification tests pass
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (test_coordinate_verification.sh)
- [ ] Git commit created: `fix(coordinate): correct verification grep patterns to match export format (spec 648)`
- [ ] Update this plan file with phase completion status

### Phase 3: Library Re-sourcing Standardization
dependencies: [1]

**Objective**: Ensure all bash blocks include complete library re-sourcing to eliminate "command not found" errors

**Complexity**: Low

**Tasks**:
- [ ] Identify all bash blocks in coordinate.md (count using grep `^```bash`)
- [ ] Create standardized library re-sourcing template from bash-block-execution-model.md
- [ ] Add re-sourcing block to every bash block that lacks it (file: .claude/commands/coordinate.md)
- [ ] Ensure `set +H` is first line in every bash block (history expansion workaround)
- [ ] Verify all 6 critical libraries sourced: workflow-state-machine.sh, state-persistence.sh, workflow-initialization.sh, error-handling.sh, unified-logger.sh, verification-helpers.sh
- [ ] Add Standard 13 detection block (CLAUDE_PROJECT_DIR) if missing
- [ ] Verify LIB_DIR path construction consistent across blocks
- [ ] Test emit_progress availability in each block (from unified-logger.sh)

**Testing**:
```bash
# Syntax check all bash blocks
bash -n <(grep -A 100 '^```bash' .claude/commands/coordinate.md | grep -B 100 '^```' | head -100)

# Verify library sourcing presence
grep -c "source.*workflow-state-machine.sh" .claude/commands/coordinate.md
# Expected: Count matches number of bash blocks

grep -c "source.*unified-logger.sh" .claude/commands/coordinate.md
# Expected: Count matches number of bash blocks (critical for emit_progress)
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (syntax checks and library sourcing verification)
- [ ] Git commit created: `fix(coordinate): standardize library re-sourcing in all bash blocks (spec 648)`
- [ ] Update this plan file with phase completion status

### Phase 4: Verification Helper Integration
dependencies: [2]

**Objective**: Replace verbose verification blocks with concise verify_file_created() helper for 90% token reduction

**Complexity**: Medium

**Tasks**:
- [ ] Identify verbose verification blocks in coordinate.md (search for "VERIFICATION CHECKPOINT" comments)
- [ ] For each verbose block (file: .claude/commands/coordinate.md):
  - [ ] Replace with verify_file_created() call from verification-helpers.sh
  - [ ] Format: `verify_file_created "$REPORT_PATH" "Research report" "Phase 1" && echo "✓ Report verified"`
  - [ ] Preserve verification logic (file existence, size check)
- [ ] Update research phase verification to use verify_file_created() for each report
- [ ] Ensure verification-helpers.sh sourced before verify_file_created() calls
- [ ] Test concise output format (single ✓ on success, 38-line diagnostic on failure)
- [ ] Measure token reduction: before/after comparison

**Testing**:
```bash
# Test verification helper with missing file (should show diagnostic)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
verify_file_created "/nonexistent/path.md" "Test report" "Test phase"
# Expected: 38-line diagnostic with actionable commands

# Test verification helper with existing file (should show single ✓)
TEMP_FILE=$(mktemp)
echo "test content" > "$TEMP_FILE"
verify_file_created "$TEMP_FILE" "Test report" "Test phase"
# Expected: Single ✓ character
rm "$TEMP_FILE"
```

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (verification helper integration tests)
- [ ] Git commit created: `refactor(coordinate): replace verbose verification with verification-helpers.sh (spec 648)`
- [ ] Update this plan file with phase completion status

### Phase 5: End-to-End Integration Testing
dependencies: [1, 2, 3, 4]

**Objective**: Validate all fixes work together in complete coordinate workflow execution

**Complexity**: High

**Tasks**:
- [ ] Create test workflow description for coordinate command
- [ ] Execute coordinate command with 3 research topics (full workflow)
- [ ] Monitor for unbound variable errors (should be zero)
- [ ] Monitor for verification checkpoint failures (should be zero)
- [ ] Monitor for "command not found" errors (should be zero)
- [ ] Verify state persistence: check state file contains all variables
- [ ] Verify grep patterns: all verification checkpoints pass
- [ ] Verify library availability: emit_progress works in all blocks
- [ ] Verify report path reconstruction: REPORT_PATHS array correctly rebuilt
- [ ] Capture full execution output for analysis
- [ ] Document any remaining issues for follow-up

**Testing**:
```bash
# Full integration test
cd "${CLAUDE_PROJECT_DIR}"
/coordinate "research existing authentication patterns, security best practices, and OAuth implementation options in order to create comprehensive authentication plan"

# Expected outcomes:
# - Research phase completes without unbound variable errors
# - All 3 research reports verified successfully
# - Plan phase invoked with correct report paths
# - No manual intervention required
# - Workflow completes to plan creation

# Verify state file completeness
STATE_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${HOME}/.claude/tmp/workflow_${STATE_ID}.sh"
echo "Checking state file: $STATE_FILE"
grep "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE" || echo "ERROR: Missing variable"
grep "^export WORKFLOW_SCOPE=" "$STATE_FILE" || echo "ERROR: Missing variable"
grep "^export REPORT_PATHS_COUNT=" "$STATE_FILE" || echo "ERROR: Missing variable"
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (full coordinate workflow execution)
- [ ] Git commit created: `test(coordinate): verify end-to-end reliability improvements (spec 648)`
- [ ] Update this plan file with phase completion status

### Phase 6: Documentation and Validation
dependencies: [5]

**Objective**: Document fixes and validate against architectural standards

**Complexity**: Low

**Tasks**:
- [ ] Create implementation summary in specs/648/summaries/ (file: .claude/specs/648_and_standards_in_claude_docs_to_avoid_redundancy/summaries/001_implementation_summary.md)
- [ ] Document error patterns fixed (unbound variables, verification failures, command not found)
- [ ] Document patterns applied (state persistence, verification helpers, library re-sourcing)
- [ ] Document metrics: error rate before/after, token reduction from verification helpers
- [ ] Update coordinate-command-guide.md with state management best practices reference
- [ ] Update bash-block-execution-model.md with coordinate as case study (optional)
- [ ] Validate executable/documentation separation: run `.claude/tests/validate_executable_doc_separation.sh`
- [ ] Cross-reference: link implementation summary to research reports
- [ ] Add lessons learned section for future orchestration command development

**Testing**:
```bash
# Validate executable/documentation separation
bash "${CLAUDE_PROJECT_DIR}/.claude/tests/validate_executable_doc_separation.sh"

# Check coordinate.md file size (should remain under 1,200 lines)
wc -l "${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"
# Expected: <1,200 lines (lean executable)

# Verify test suite still passes
bash "${CLAUDE_PROJECT_DIR}/.claude/tests/test_coordinate_verification.sh"
# Expected: All tests pass
```

**Expected Duration**: 1.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (validation scripts)
- [ ] Git commit created: `docs(648): add implementation summary for coordinate error fixes`
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- State persistence: Verify all variables saved/loaded correctly
- Grep patterns: Verify patterns match export format
- Library sourcing: Verify all libraries available in all blocks
- Verification helpers: Verify concise output and correct diagnostics

### Integration Testing
- End-to-end coordinate workflow: research → plan without errors
- State file completeness: All required variables present
- Report path reconstruction: Arrays correctly rebuilt from exports
- Verification checkpoint success: All reports verified correctly

### Regression Testing
- Existing test suites: .claude/tests/test_coordinate_verification.sh
- State machine tests: .claude/tests/test_state_machine.sh (50 tests)
- Orchestration tests: .claude/tests/test_orchestration_commands.sh

### Validation Testing
- Executable/documentation separation: validate_executable_doc_separation.sh
- Command architecture standards compliance (Standards 0, 11, 13, 14)
- Bash block execution model compliance (5 patterns)

## Documentation Requirements

### Code Documentation
- Inline comments for all verification grep patterns explaining export format
- Comments for state persistence calls explaining subprocess isolation
- Library re-sourcing blocks documented with bash-block-execution-model.md reference

### External Documentation
- Implementation summary in specs/648/summaries/
- Coordinate-command-guide.md update with state management patterns
- Cross-references to bash-block-execution-model.md patterns

### Standard Compliance Documentation
- Verification checkpoint format documentation
- State persistence decision matrix application notes
- Library re-sourcing pattern documentation

## Dependencies

### Internal Dependencies
- State persistence library: .claude/lib/state-persistence.sh
- Verification helpers library: .claude/lib/verification-helpers.sh
- Unified logger library: .claude/lib/unified-logger.sh (for emit_progress)
- Error handling library: .claude/lib/error-handling.sh
- Workflow state machine library: .claude/lib/workflow-state-machine.sh
- Workflow initialization library: .claude/lib/workflow-initialization.sh

### External Dependencies
None (all fixes use existing infrastructure)

### Standards Dependencies
- Bash block execution model: .claude/docs/concepts/bash-block-execution-model.md
- State management patterns: .claude/docs/architecture/coordinate-state-management.md
- Verification and fallback pattern: .claude/docs/concepts/patterns/verification-fallback.md
- Command architecture standards: .claude/docs/reference/command_architecture_standards.md (Standards 0, 11, 13, 14)

## Risk Management

### Technical Risks
- **Risk**: State file corruption during high concurrency
  - **Mitigation**: Use atomic writes (temp file + mv) from state-persistence.sh
  - **Likelihood**: Low (pattern already validated)

- **Risk**: Grep pattern changes in future state-persistence.sh updates
  - **Mitigation**: Document dependency on export format, add tests
  - **Likelihood**: Very Low (export format is stable pattern)

- **Risk**: Library sourcing performance overhead
  - **Mitigation**: Source guards prevent redundant execution, <1ms per source
  - **Likelihood**: Low (validated in bash-block-execution-model.md)

### Implementation Risks
- **Risk**: Missing edge cases in variable usage audit
  - **Mitigation**: Systematic grep-based extraction, comprehensive testing
  - **Likelihood**: Medium (manual audit process)

- **Risk**: Breaking existing checkpoint compatibility
  - **Mitigation**: Test with existing test suites, maintain checkpoint schema
  - **Likelihood**: Low (additive changes only)

### Rollback Strategy
If critical issues discovered:
1. Git revert to pre-fix state
2. Isolate specific fix causing issue
3. Apply remaining fixes individually
4. Create bug report for problematic fix
5. Re-test each fix in isolation before re-applying

## Complexity Analysis

### Complexity Score Calculation
```
Score = Base(fix) + Tasks/2 + Files*3 + Integrations*5
      = 3 + 42/2 + 1*3 + 2*5
      = 3 + 21 + 3 + 10
      = 37
```

**Justification**:
- Base: 3 (bug fix, not new feature)
- Tasks: 42 tasks across 6 phases
- Files: 1 primary file modified (coordinate.md)
- Integrations: 2 (state-persistence.sh, verification-helpers.sh)

**Tier Selection**: Tier 1 (Score: 37 < 50) - Single file plan structure appropriate

### Time Estimate Breakdown
- Phase 1: 1.5 hours (state audit and persistence fix)
- Phase 2: 1 hour (grep pattern corrections)
- Phase 3: 1.5 hours (library re-sourcing standardization)
- Phase 4: 1.5 hours (verification helper integration)
- Phase 5: 2 hours (end-to-end testing)
- Phase 6: 1.5 hours (documentation and validation)
- **Total**: 9 hours (within 8-10 hour estimate)

## Notes

### Pattern Application Strategy
This plan systematically applies validated patterns from existing infrastructure:
1. **State Persistence Pattern**: From specs 620/630 fixes (100% test pass rate)
2. **Verification Helper Pattern**: From verification-helpers.sh (90% token reduction)
3. **Library Re-sourcing Pattern**: From bash-block-execution-model.md (validated)
4. **MANDATORY VERIFICATION Pattern**: From verification-fallback.md (100% file creation)

### Architectural Compliance
All fixes maintain alignment with:
- State-based orchestration architecture (state machine, selective persistence)
- Command architecture standards (Standards 0, 11, 13, 14)
- Bash block execution model (5 validated patterns)
- Fail-fast principles (verification fallbacks detect errors, not mask them)

### Success Metrics
- Unbound variable error rate: 100% → 0% (elimination)
- Verification checkpoint success rate: 0% → 100% (complete reliability)
- Command not found error rate: 100% → 0% (elimination)
- Token reduction from verification helpers: ~2,850 → ~225 per checkpoint (92%)
- Manual intervention required: 100% → 0% (full automation)
