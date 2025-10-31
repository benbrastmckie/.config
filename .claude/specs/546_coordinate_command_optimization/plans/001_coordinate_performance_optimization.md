# /coordinate Command Performance Optimization Plan

## Metadata
- **Date**: 2025-10-30
- **Feature**: Optimize /coordinate command for improved performance and maintainability
- **Scope**: Command file refactoring with library consolidation and code reduction
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Risk Level**: Low-Medium (modular changes with comprehensive testing)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Comprehensive analysis completed in exploration phase

## Overview

The `/coordinate` command is a production-ready orchestration system (2,500-3,000 lines) that successfully achieves <30% context usage and fail-fast error handling. However, analysis has identified 7 specific optimization opportunities that can reduce file size by 15-25% (280-600 lines) while improving Phase 0 initialization speed by 30-40%.

This plan focuses exclusively on **low-to-medium risk changes** using existing library infrastructure. All optimizations maintain 100% functionality and behavioral compatibility.

## Success Criteria

### Performance Targets
- [ ] File size reduced to 2,200-2,400 lines (from 2,500-3,000)
- [ ] Phase 0 initialization: 30-60 seconds (from 60-120 seconds)
- [ ] Verification overhead reduced by 20-30%
- [ ] Meta-instruction text reduced from 200+ lines to <50 lines

### Functional Requirements (Must Maintain)
- [ ] 100% file creation rate (no regression)
- [ ] <30% context usage throughout workflow
- [ ] Fail-fast error handling with clear diagnostics
- [ ] Wave-based parallel execution (40-60% time savings)
- [ ] Checkpoint resume capability
- [ ] All 4 workflow scope types function correctly

### Code Quality
- [ ] Zero duplication in verification patterns
- [ ] Consistent checkpoint serialization
- [ ] Reusable phase execution wrappers
- [ ] Library-based initialization (not inline code)

## Technical Design

### Architecture Principles

1. **Library Consolidation**: Move repeated patterns to reusable library functions
2. **Template Extraction**: Replace inline instruction blocks with template references
3. **Single Responsibility**: Each phase handles one concern cleanly
4. **Fail-Fast Preservation**: Maintain clear error reporting and immediate termination
5. **Backward Compatibility**: No changes to external interfaces or agent protocols

### Component Interactions

```
coordinate.md (orchestrator)
    │
    ├─→ verification-utils.sh (NEW)
    │   ├─ verify_and_report()
    │   └─ verify_multiple()
    │
    ├─→ coordinate-phase-0.sh (NEW)
    │   └─ initialize_coordinate_workflow()
    │
    ├─→ checkpoint-utils.sh (ENHANCED)
    │   └─ build_phase_checkpoint() [NEW]
    │
    └─→ agent-task-templates.md (NEW)
        ├─ Research agent template
        ├─ Planning agent template
        ├─ Implementation agent template
        └─ Debug/Test agent templates
```

### Data Flow

```
Phase 0: Library sourcing → Workflow initialization → Path pre-calculation
         │
         └─→ initialize_coordinate_workflow() consolidates STEPS 0-3

Phase 1-6: Agent invocation → Verification → Checkpoint → Pruning
           │
           ├─→ verify_and_report() handles all file checks
           └─→ build_phase_checkpoint() constructs JSON consistently
```

## Implementation Phases

### Phase 0: Preparation and Validation

**Objective**: Verify current state, audit library dependencies, and create test baseline

**Complexity**: Low

**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Create test snapshot of coordinate.md current behavior
  - Run coordinate.md with all 4 workflow scope types
  - Document output for regression testing
  - Save baseline performance metrics (Phase 0 duration, file creation rate)
  - File: `.claude/specs/546_coordinate_command_optimization/artifacts/baseline_test_results.md`

- [ ] Audit context-pruning.sh library for actual function signatures
  - Verify `store_phase_metadata()` exists and parameters
  - Verify `apply_pruning_policy()` exists and parameters
  - Check `prune_workflow_metadata()` signature
  - Document findings: `.claude/specs/546_coordinate_command_optimization/artifacts/library_audit.md`

- [ ] Verify all referenced library functions exist
  - Cross-reference coordinate.md function calls with library files
  - Check: workflow-detection.sh, error-handling.sh, checkpoint-utils.sh
  - Check: unified-logger.sh, unified-location-detection.sh, metadata-extraction.sh
  - Create compatibility matrix showing which functions are used

- [ ] Create feature branch for optimization work
  - Branch name: `feature/coordinate-optimization`
  - Protect against direct commits to main
  - Set up checkpoint commits after each phase

**Testing**:
```bash
# Baseline test execution
cd /home/benjamin/.config
./run_test_coordinate_baseline.sh  # To be created

# Library function verification
for lib in workflow-detection error-handling checkpoint-utils unified-logger; do
  echo "=== $lib.sh ==="
  grep "^[a-z_]*() {" .claude/lib/$lib.sh
done

# Expected: List of all exported functions per library
```

**Validation**:
- All 4 workflow scope types execute successfully
- Baseline metrics recorded (Phase 0 time, total execution time)
- Library audit confirms function availability
- Feature branch created and ready for work

**Dependencies**: None (preparation phase)

---

### Phase 1: Verification Pattern Consolidation

**Objective**: Create reusable verification utilities and eliminate 120-150 lines of duplication

**Complexity**: Low

**Estimated Time**: 3-4 hours

**Tasks**:
- [ ] Create `.claude/lib/verification-utils.sh` library
  - Implement `verify_and_report()` function with parameters:
    - `file_path` (absolute path to verify)
    - `phase_num` (for progress markers)
    - `item_desc` (e.g., "Research report 1/4")
    - `detail_callback` (optional closure for phase-specific details)
  - Implement silent success (single ✓) and verbose failure patterns
  - Include fail-fast exit on verification failure
  - Export functions for sourcing

- [ ] Create `verify_multiple()` batch verification function
  - Accept array of file paths
  - Report aggregate status (N/M passed)
  - Return list of failed paths for diagnostic reporting
  - Handle partial success threshold (≥50% for research phase)

- [ ] Update coordinate.md Phase 0 STEP 0 to source verification-utils.sh
  - Add to library sourcing list in library-sourcing.sh call
  - Verify function availability after sourcing
  - Test sourcing in isolated bash session

- [ ] Replace inline verification in Phase 1 (Research)
  - Lines 902-935: Replace with `verify_multiple()` call
  - Preserve partial success logic (≥50% threshold)
  - Test with 1, 2, 3, 4 research agent scenarios

- [ ] Replace inline verification in Phase 2 (Planning)
  - Lines 1102-1117: Replace with `verify_and_report()`
  - Preserve phase count extraction and structure validation
  - Add detail_callback for phase count reporting

- [ ] Replace inline verification in Phase 3 (Implementation)
  - Lines 1302-1320: Replace with `verify_and_report()`
  - Preserve artifact count extraction
  - Test with different artifact directory structures

- [ ] Replace inline verification in Phase 4 (Testing)
  - Lines 1528-1534: Inline in agent output parsing (no separate verification)
  - Test status parsing remains functional

- [ ] Replace inline verification in Phase 5 (Debug)
  - Lines 1537-1555, 1563-1583: Replace with `verify_and_report()`
  - Test in debug iteration loop

- [ ] Replace inline verification in Phase 6 (Documentation)
  - Lines 1687-1696: Replace with `verify_and_report()`
  - Preserve file size extraction

- [ ] Remove inline `verify_file_created()` function definition
  - Lines 771-812: Delete (moved to library)
  - Verify no other usages exist in command file

**Testing**:
```bash
# Unit test verification-utils.sh
cd /home/benjamin/.config/.claude/lib
bash -c "source verification-utils.sh && verify_and_report '/tmp/test.txt' 1 'Test file'"

# Integration test with coordinate.md
cd /home/benjamin/.config
# Run coordinate with research-only workflow
/coordinate "research authentication patterns"

# Expected: Verification uses library functions, output identical to baseline
```

**Validation**:
- verification-utils.sh created and sourced successfully
- All 6 phase verification blocks replaced with library calls
- Inline verify_file_created() function removed
- File size reduced by 120-150 lines
- All 4 workflow scope types still pass baseline tests

**Dependencies**: Phase 0 (baseline established)

---

### Phase 2: Checkpoint Serialization Consolidation

**Objective**: Create reusable checkpoint builder and eliminate 40-50 lines of JSON duplication

**Complexity**: Low

**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Enhance `.claude/lib/checkpoint-utils.sh` with JSON builder
  - Implement `build_phase_checkpoint()` function with parameters:
    - `phase_num` (1-6)
    - `artifact_fields` (associative array of field→value pairs)
  - Use `jq` for safe JSON construction
  - Handle optional fields (only include if non-empty)
  - Support array fields (e.g., research_reports)

- [ ] Create helper: `save_phase_checkpoint()` wrapper
  - Combines `build_phase_checkpoint()` + `save_checkpoint()`
  - Single-call API for phases
  - Parameters: `workflow_name`, `phase_num`, `artifact_fields`

- [ ] Replace checkpoint serialization in Phase 1
  - Lines 994-1001: Replace with `save_phase_checkpoint()`
  - Pass research_reports array and optional overview_path
  - Test checkpoint file structure matches original

- [ ] Replace checkpoint serialization in Phase 2
  - Lines 1136-1144: Replace with `save_phase_checkpoint()`
  - Include research_reports, overview_path, plan_path
  - Verify plan metadata preserved

- [ ] Replace checkpoint serialization in Phase 3
  - Lines 1328-1346: Replace with `save_phase_checkpoint()`
  - Include wave_execution metrics structure
  - Test nested JSON structure correctness

- [ ] Replace checkpoint serialization in Phase 4
  - Lines 1443-1454: Replace with `save_phase_checkpoint()`
  - Include test_status field
  - Verify test results preserved for potential debugging

**Testing**:
```bash
# Unit test checkpoint builder
cd /home/benjamin/.config/.claude/lib
bash << 'EOF'
source checkpoint-utils.sh
declare -A fields=(
  [research_reports]='["/path/1.md", "/path/2.md"]'
  [plan_path]='"/path/plan.md"'
)
build_phase_checkpoint 2 fields | jq .
EOF

# Integration test
/coordinate "research and plan authentication feature"
# Verify checkpoint files created correctly
cat .claude/data/checkpoints/coordinate_latest.json | jq .
```

**Validation**:
- checkpoint-utils.sh enhanced with builder functions
- All 4 phase checkpoint blocks replaced
- Checkpoint JSON structure identical to original
- Resume capability still works (test with interrupted workflow)
- File size reduced by additional 40-50 lines

**Dependencies**: Phase 1 (verification consolidation complete)

---

### Phase 3: Phase Execution Wrapper and Phase 0 Simplification

**Objective**: Create phase execution wrapper and consolidate Phase 0 initialization

**Complexity**: Medium

**Estimated Time**: 5-6 hours

**Tasks**:
- [ ] Create phase execution wrapper function in coordinate.md
  - Define `execute_phase_conditional()` after library sourcing
  - Parameters: `phase_num`, `phase_name`, `action_desc`, `exit_on_skip`
  - Handles: should_run_phase check, skip message, progress marker
  - Returns 0 if phase executes, 1 if skipped

- [ ] Replace phase execution checks in Phase 1
  - Lines 827-836: Replace with `execute_phase_conditional 1 "Research" "parallel agent invocation" "true"`
  - Test skip behavior for research-only vs full-implementation workflows

- [ ] Replace phase execution checks in Phase 2
  - Lines 1028-1036: Replace with `execute_phase_conditional 2 "Planning" "plan-architect invocation" "true"`
  - Test conditional exit for research-only workflows

- [ ] Replace phase execution checks in Phase 3
  - Lines 1200-1205: Replace with `execute_phase_conditional 3 "Implementation" "wave-based execution" "false"`
  - No exit on skip (continue to Phase 4 check)

- [ ] Replace phase execution checks in Phase 4
  - Lines 1377-1384: Replace with `execute_phase_conditional 4 "Testing" "test-specialist invocation" "false"`

- [ ] Replace phase execution checks in Phase 5
  - Lines 1481-1488: Replace conditional logic (if tests failed OR debug-only)
  - Preserve custom condition

- [ ] Replace phase execution checks in Phase 6
  - Lines 1640-1649: Replace conditional logic (if implementation occurred)
  - Preserve custom condition

- [ ] Create `.claude/lib/coordinate-phase-0.sh` library
  - Implement `initialize_coordinate_workflow()` function
  - Consolidates STEPS 0-3 from current Phase 0:
    - Library sourcing (delegate to library-sourcing.sh)
    - display_brief_summary function definition (move inline)
    - Workflow description parsing and validation
    - Workflow scope detection
    - Path initialization (delegate to workflow-initialization.sh)
  - Export all Phase 0 variables (WORKFLOW_SCOPE, TOPIC_PATH, REPORT_PATHS, etc.)
  - Return 0 on success, 1 on failure with clear diagnostics

- [ ] Move `display_brief_summary()` to coordinate-phase-0.sh
  - Lines 570-605: Extract function definition
  - Define in library instead of inline
  - Export for use throughout workflow

- [ ] Replace Phase 0 STEPS 0-3 with library call
  - Lines 522-745: Replace with:
    ```bash
    source .claude/lib/coordinate-phase-0.sh || {
      echo "ERROR: Phase 0 initialization library not found"
      exit 1
    }
    initialize_coordinate_workflow "$@" || exit 1
    ```
  - Test library sourcing and initialization

- [ ] Verify Phase 0 optimization
  - Measure Phase 0 duration before and after
  - Target: 30-60 seconds (from 60-120 seconds)
  - Confirm all variables exported correctly

**Testing**:
```bash
# Test phase execution wrapper
cd /home/benjamin/.config
/coordinate "research authentication"  # Should execute Phase 1 only
/coordinate "implement OAuth"  # Should execute Phases 1-6

# Test Phase 0 library
time bash << 'EOF'
source .claude/lib/coordinate-phase-0.sh
initialize_coordinate_workflow "research API patterns"
echo "WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
echo "TOPIC_PATH=$TOPIC_PATH"
EOF

# Measure Phase 0 duration
time /coordinate "research minimal test case" 2>&1 | head -20
# Expected: <60 seconds for Phase 0 completion
```

**Validation**:
- execute_phase_conditional() defined and replaces 6 check blocks
- coordinate-phase-0.sh created with initialization logic
- display_brief_summary() moved to library
- Phase 0 duration reduced by 30-40%
- All workflow scope types initialize correctly
- File size reduced by additional 80-120 lines

**Dependencies**: Phase 2 (checkpoint consolidation complete)

---

### Phase 4: Agent Task Template Extraction and Final Cleanup

**Objective**: Extract agent invocation instructions to template library and audit pruning calls

**Complexity**: Medium

**Estimated Time**: 4-5 hours

**Tasks**:
- [ ] Create `.claude/templates/agent-task-invocations.md` template library
  - Research agent template with variable substitution guide
  - Plan-architect agent template
  - Implementer-coordinator agent template
  - Test-specialist agent template
  - Debug-analyst agent template
  - Code-writer agent template
  - Doc-writer agent template

- [ ] Add template usage guide section
  - Explain variable substitution pattern: `[VARIABLE_NAME]`
  - Show example of template → actual Task invocation
  - Document required vs optional parameters

- [ ] Update coordinate.md to reference templates instead of inline instructions
  - Replace "**EXECUTE NOW**" blocks with template references
  - Phase 1: "See agent-task-invocations.md → Research Agent Template"
  - Phase 2: "See agent-task-invocations.md → Plan-Architect Template"
  - Phase 3: "See agent-task-invocations.md → Implementer-Coordinator Template"
  - Phase 4: "See agent-task-invocations.md → Test-Specialist Template"
  - Phase 5: "See agent-task-invocations.md → Debug-Analyst Template"
  - Phase 6: "See agent-task-invocations.md → Doc-Writer Template"

- [ ] Simplify Phase 5 debug iteration loop Task invocations
  - Lines 1501-1521, 1537-1555, 1563-1583: Replace with template references
  - Keep variable substitution inline (iteration-specific)

- [ ] Audit context pruning function calls
  - Lines 1003-1009, 1146-1152, 1348-1358, 1456-1461, 1615-1620, 1698-1701
  - Verify if `store_phase_metadata()`, `apply_pruning_policy()`, `prune_workflow_metadata()` exist
  - Check function signatures match invocation parameters
  - If functions missing: Remove calls or create stub implementations
  - If functions exist but unused: Verify actual context reduction effect

- [ ] Consolidate progress reporting
  - Create `report_progress()` wrapper if beneficial
  - Combines echo + emit_progress into single call
  - Replace redundant dual reporting patterns
  - Estimate: 20-30 line reduction

- [ ] Final code review and cleanup
  - Remove any remaining duplicate comments
  - Ensure consistent formatting
  - Verify all library functions are used
  - Check for unused variables or dead code paths

**Testing**:
```bash
# Test template library readability
cat .claude/templates/agent-task-invocations.md
# Expected: Clear templates with [VARIABLE] substitution markers

# Test coordinate.md with template references
/coordinate "implement feature with all phases"
# Verify all phases execute correctly

# Verify context pruning (if functions exist)
# Monitor bash variable count throughout workflow execution

# Final regression test suite
cd /home/benjamin/.config/.claude/tests
./test_coordinate_all_workflows.sh  # To be created in this phase
```

**Validation**:
- agent-task-invocations.md created with all 7 agent templates
- coordinate.md references templates instead of inline "**EXECUTE NOW**" blocks
- Context pruning calls audited and corrected or removed
- Progress reporting consolidated
- File size target achieved: 2,200-2,400 lines (15-25% reduction)
- All functional requirements maintained (see Success Criteria)

**Dependencies**: Phase 3 (Phase 0 simplification complete)

---

## Testing Strategy

### Unit Testing
- **verification-utils.sh**: Test verify_and_report() with success/failure cases
- **checkpoint-utils.sh**: Test build_phase_checkpoint() JSON structure
- **coordinate-phase-0.sh**: Test initialize_coordinate_workflow() with all scope types
- **Phase execution wrapper**: Test execute_phase_conditional() skip logic

### Integration Testing
- **All 4 workflow scope types**:
  - research-only: Phases 0-1
  - research-and-plan: Phases 0-2
  - full-implementation: Phases 0-4, 6
  - debug-only: Phases 0, 1, 5
- **Checkpoint resume**: Interrupt workflow, verify auto-resume
- **Wave-based execution**: Test parallel phase execution in Phase 3
- **Error handling**: Trigger verification failures, confirm fail-fast

### Performance Testing
- **Phase 0 duration**: Measure before/after (target: 30-60s from 60-120s)
- **Total execution time**: Compare baseline vs optimized for each workflow type
- **File creation rate**: Verify 100% success rate maintained
- **Context usage**: Monitor throughout workflow (target: <30%)

### Regression Testing
- **Baseline comparison**: Output from optimized version matches baseline functionality
- **Agent invocations**: All agents still receive correct context and create artifacts
- **Checkpoint format**: Serialization matches expected structure
- **Error messages**: Diagnostic quality maintained

## Documentation Requirements

### Updated Files
- [ ] `.claude/lib/verification-utils.sh` - New library with function documentation
- [ ] `.claude/lib/checkpoint-utils.sh` - Enhanced with build_phase_checkpoint()
- [ ] `.claude/lib/coordinate-phase-0.sh` - New Phase 0 initialization library
- [ ] `.claude/templates/agent-task-invocations.md` - Agent invocation template library
- [ ] `.claude/commands/coordinate.md` - Optimized command file with library references
- [ ] `.claude/docs/reference/library-api.md` - Document new library functions
- [ ] `.claude/specs/546_coordinate_command_optimization/SUMMARY.md` - Implementation summary

### Documentation Updates
- [ ] Update library-api.md with new verification and checkpoint functions
- [ ] Add template usage guide to agent-task-invocations.md
- [ ] Document Phase 0 optimization pattern in phase-0-optimization-guide.md
- [ ] Update orchestration-best-practices.md with verification pattern examples

## Dependencies

### External Dependencies
- All required libraries already exist (verified in Phase 0):
  - workflow-detection.sh ✓
  - error-handling.sh ✓
  - checkpoint-utils.sh ✓ (to be enhanced)
  - unified-logger.sh ✓
  - unified-location-detection.sh ✓
  - metadata-extraction.sh ✓
  - context-pruning.sh ✓ (to be audited)
  - dependency-analyzer.sh ✓

### New Libraries Created
- verification-utils.sh (Phase 1)
- coordinate-phase-0.sh (Phase 3)

### New Templates Created
- agent-task-invocations.md (Phase 4)

### Prerequisites
- Git feature branch for safe experimentation
- Baseline test results for regression comparison
- Library audit confirming function availability

## Risk Assessment and Mitigation

### Low Risk Changes
- **Verification consolidation** (Phase 1): Pure wrapper functions, no behavior change
- **Checkpoint serialization** (Phase 2): JSON structure identical, just consolidated
- **Phase execution wrapper** (Phase 3, part 1): Simple conditional logic extraction
- **Template extraction** (Phase 4): Documentation refactor, no code behavior change

**Mitigation**: Comprehensive unit tests, side-by-side output comparison

### Medium Risk Changes
- **Phase 0 initialization library** (Phase 3, part 2): Consolidates critical startup logic
- **Context pruning audit** (Phase 4): May remove non-functional code

**Mitigation**:
- Test all 4 workflow scope types after Phase 0 changes
- Verify library sourcing in isolation before integration
- Audit context pruning functions before removing calls
- Feature branch allows rollback if issues discovered

### Risk Mitigation Strategy
1. **Incremental phases**: Each phase is independently testable and committable
2. **Baseline comparison**: Regression tests verify output matches original behavior
3. **Feature branch**: All work isolated from main branch until fully validated
4. **Checkpoint commits**: Each phase committed separately for easy rollback
5. **Performance metrics**: Measure Phase 0 duration and total execution time

## Notes

### Design Decisions

**Why consolidate verification instead of removing it?**
- Verification is architectural requirement (Mandatory Verification Checkpoints pattern)
- Fail-fast error handling depends on clear verification points
- Consolidation reduces duplication without compromising safety

**Why create coordinate-phase-0.sh instead of generic initialization library?**
- Phase 0 logic is coordinate-specific (workflow scope detection, path pre-calculation)
- Other orchestration commands (/orchestrate, /supervise) have different initialization needs
- Coordinate-specific library allows future coordinate enhancements without affecting other commands

**Why extract templates instead of consolidating agent invocations into library?**
- Agent invocations require workflow-specific context (different per phase)
- Templates provide copy-paste-ready examples without over-abstracting
- Library consolidation would create complex parameter passing for minimal benefit

**Why audit context pruning instead of assuming it works?**
- Pruning function calls use inconsistent naming (suggests evolutionary code)
- Markdown files don't have dynamic context (pruning may be no-op)
- Verification ensures we're not maintaining dead code

### Future Optimization Opportunities (Out of Scope)

These optimizations were identified but deferred due to higher risk or lower impact:

1. **Agent invocation consolidation**: Create library function for Task tool invocation
   - Risk: HIGH (behavioral injection pattern might break)
   - Impact: MEDIUM (50-80 lines saved)
   - Defer to: Future refactor if pattern proves reusable

2. **Workflow scope detection enhancement**: Add keyword weighting for better accuracy
   - Risk: MEDIUM (may misclassify edge cases)
   - Impact: LOW (no file size reduction)
   - Defer to: User-reported misclassification issues

3. **Wave execution metrics optimization**: Store only summary, not per-phase details
   - Risk: MEDIUM (debugging capability reduced)
   - Impact: LOW (10-15 lines saved)
   - Defer to: After wave execution proves stable in production

4. **Progress marker consolidation**: Single function for all progress reporting
   - Risk: LOW (simple wrapper)
   - Impact: LOW (20-30 lines saved)
   - Include in: Phase 4 if time permits

### Success Metrics Summary

| Metric | Current | Target | Measurement Method |
|--------|---------|--------|-------------------|
| File size | 2,500-3,000 lines | 2,200-2,400 lines | `wc -l coordinate.md` |
| Phase 0 duration | 60-120 seconds | 30-60 seconds | `time` command at Phase 0 boundary |
| Verification overhead | 150+ lines | <50 lines | Count of verify_file_created usage |
| Meta-instruction text | 200+ lines | <50 lines | Count of "**EXECUTE NOW**" blocks |
| File creation rate | 100% | 100% (maintain) | Test suite pass rate |
| Context usage | <30% | <30% (maintain) | Agent output parsing |

## Implementation Timeline

- **Phase 0**: 2-3 hours (preparation and validation)
- **Phase 1**: 3-4 hours (verification consolidation)
- **Phase 2**: 2-3 hours (checkpoint serialization)
- **Phase 3**: 5-6 hours (phase wrappers and Phase 0 library)
- **Phase 4**: 4-5 hours (template extraction and cleanup)

**Total Estimated Effort**: 16-21 hours over 3-4 days

**Recommended Schedule**:
- Day 1: Phases 0-1 (preparation + verification)
- Day 2: Phases 2-3 (checkpoints + Phase 0 optimization)
- Day 3: Phase 4 (templates + cleanup)
- Day 4: Final testing and documentation

## Conclusion

This optimization plan targets 280-600 line reduction (15-25%) through systematic consolidation of repeated patterns into reusable libraries and templates. All changes are low-to-medium risk and maintain 100% functional compatibility with the current implementation.

The phased approach allows for incremental progress with checkpoint commits after each phase, ensuring that partial progress is preserved even if later phases encounter unexpected issues.

Key success factors:
- Comprehensive baseline testing before any changes
- Library audit to verify function availability
- Unit and integration testing for each phase
- Performance measurement to confirm optimization targets
- Feature branch isolation for safe experimentation
