# Current Plan 670 Analysis Report

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Plan 670 status analysis for update planning
- **Report Type**: plan analysis
- **Plan Reviewed**: /home/benjamin/.config/.claude/specs/670_workflow_classification_improvement/plans/001_hybrid_classification_implementation.md

## Executive Summary

Plan 670 defines a 5-phase hybrid workflow classification system to replace regex-based detection with LLM-powered semantic understanding. The plan underwent Revision 3 on 2025-11-11 to integrate with Spec 672's state-based orchestration refactor, adding library sourcing patterns (source guards, detect-project-dir.sh) to Phase 1 and Phase 2 tasks. All phases remain unstarted with zero completion, making this an ideal time to incorporate findings from the recent /coordinate refactor without impacting in-progress work.

## Findings

### 1. Plan Structure and Status

**Plan Metadata** (lines 1-14):
- Plan ID: 670-001
- Status: Ready for Review
- Complexity: 7.5/10
- Estimated Time: 3-4 weeks development + 4-6 weeks rollout
- Related Documents: 4 research reports referenced

**Phase Status** (lines 150-787):
- **Phase 0**: COMPLETE (research artifacts created)
- **Phase 1**: NOT STARTED (Core LLM Classifier Library, 4 tasks)
- **Phase 2**: NOT STARTED (Hybrid Classifier Integration, 4 tasks)
- **Phase 3**: NOT STARTED (Testing and Quality Assurance, 5 tasks)
- **Phase 4**: NOT STARTED (Alpha Rollout, 4 tasks)
- **Phase 5**: NOT STARTED (Production Rollout, 5 tasks)
- **Phase 6**: NOT STARTED (Standards Review - optional, 2 tasks)

**Completion Status**: 0/24 tasks complete (excluding optional Phase 6)

### 2. Spec 672 Integration (Revision 3)

**Integration Scope** (lines 1109-1123):
Revision 3 on 2025-11-11 added Spec 672 integration requirements to ensure consistency with state-based orchestration refactor patterns:

**Phase 1 Task 1.1 Updates** (lines 193-209):
- Added requirement: "Use `source "${CLAUDE_PROJECT_DIR}/.claude/lib/detect-project-dir.sh"` for project directory detection"
- Added requirement: "Implement source guard pattern: `if [ -n "${WORKFLOW_LLM_CLASSIFIER_SOURCED:-}" ]; then return 0; fi`"
- Added acceptance criteria for CLAUDE_PROJECT_DIR detection and source guards
- Integration context: "Follow library sourcing patterns consistent with state-persistence.sh and workflow-state-machine.sh"

**Phase 2 Task 2.1 Updates** (lines 320-334):
- Added requirement: "Use `source "${CLAUDE_PROJECT_DIR}/.claude/lib/detect-project-dir.sh"` pattern for project directory detection"
- Added requirement: "Follow source guard pattern: `if [ -n "${WORKFLOW_SCOPE_DETECTION_SOURCED:-}" ]; then return 0; fi`"
- Added compatibility note: "Ensure compatibility with `workflow-state-machine.sh:16` dependency"
- Added acceptance criteria for source guards and detect-project-dir.sh usage

**Impact Assessment** (lines 1115-1120):
- Phase 1: 2 additional acceptance criteria
- Phase 2: 2 additional acceptance criteria
- No impact on estimated duration or complexity
- No breaking changes to interface or architecture

### 3. State Management References

**Workflow Scope Detection Integration** (lines 106-117):
Plan correctly identifies integration with state machine:
- `sm_init()` function already calls `detect_workflow_scope()` - no changes needed
- Maps scope to terminal states (research-only → STATE_RESEARCH, etc.)
- Function signature preserved for backward compatibility

**State Machine Library Dependency** (line 323):
Plan acknowledges dependency:
- "Ensure compatibility with `workflow-state-machine.sh:16` dependency (library uses detect_workflow_scope)"

### 4. Library Sourcing Patterns

**Current Plan Approach** (lines 193-209, 320-334):
Plan requires following Spec 672 patterns:
- Source guards to prevent duplicate sourcing
- detect-project-dir.sh for CLAUDE_PROJECT_DIR detection
- Consistency with state-persistence.sh and workflow-state-machine.sh patterns

**Recent Refactor Context**:
Need to verify if Plan 670's understanding of Spec 672 patterns matches actual implementation after recent /coordinate refactor work.

### 5. Clean-Break Architecture

**Revision 2 Changes** (lines 1126-1145):
Major architectural simplification on 2025-11-11:
- Eliminated v2 wrapper approach in favor of complete rewrite
- Changed workflow-scope-detection.sh from "Modified" to "Rewritten" (complete replacement)
- Removed sm_init() modifications (no changes needed with clean-break)
- Updated workflow-detection.sh to source unified library
- Rewrote integration test suite (complete replacement)
- Eliminated 181 lines of technical debt

**Clean-Break Impact** (lines 1074-1078):
- Old code removed: ~101 lines (workflow-scope-detection.sh regex implementation)
- Old tests removed: ~80 lines (regex-only test cases)
- Net reduction: ~181 lines of technical debt eliminated
- Zero wrapper layers or compatibility shims

### 6. File Change Summary

**New Files** (lines 1050-1053):
- `.claude/lib/workflow-llm-classifier.sh` (~200 lines)
- `.claude/tests/test_llm_classifier.sh` (~150 lines)
- `.claude/tests/test_scope_detection_ab.sh` (~100 lines)

**Rewritten Files** (lines 1055-1058):
- `.claude/lib/workflow-scope-detection.sh` (complete rewrite: ~150 lines, old code deleted)
- `.claude/tests/test_scope_detection.sh` (complete rewrite: ~100 lines, old tests deleted)

**Modified Files** (lines 1059-1061):
- `.claude/lib/workflow-detection.sh` (~10 lines: source unified library, delete duplicated logic)
- `.claude/tests/run_all_tests.sh` (+3 lines to include new tests)

### 7. Potential Conflicts with Recent Refactor

**State ID File Persistence** (Spec 661 Phases 1-2):
Plan 670 does not reference state ID file persistence changes implemented in recent refactor:
- Phase 1: State ID File Persistence Fix
- Phase 2: State ID File Persistence Tests

**Impact**: Plan 670's workflow-llm-classifier.sh and workflow-scope-detection.sh may need to follow state ID file patterns if they interact with state management.

**Library Sourcing Order** (Spec 661 Phase 3):
Plan 670 references detect-project-dir.sh sourcing but may not be aware of library sourcing order fixes:
- Phase 3: Library Sourcing Order Fix (completed in recent refactor)

**Impact**: Plan 670 should verify its library sourcing order matches established patterns from Spec 661 Phase 3.

**Integration Tests** (Spec 661 Phase 4):
Plan 670 has comprehensive test strategy but may not align with library sourcing integration tests:
- Phase 4: Library Sourcing and Integration Tests (completed in recent refactor)

**Impact**: Plan 670's test suite should follow integration test patterns from Spec 661 Phase 4.

### 8. Standards Compliance References

**Phase 1 Task 1.1** (lines 190-193):
- Standard 13 (Project Directory Detection): Use CLAUDE_PROJECT_DIR for all paths
- Standard 14 (Executable/Documentation Separation): Separate implementation from guide
- bash-block-execution-model.md patterns for subprocess isolation

**Phase 2 Task 2.1** (lines 311-317):
- Standard 13 (Project Directory Detection) pattern
- Standard 14 (Executable/Documentation Separation)
- Clean-break philosophy (CLAUDE.md Development Philosophy section)

**Phase 5 Task 5.4** (lines 700-707):
- Standard 14 (Executable/Documentation Separation) pattern
- Single source of truth principle (Diataxis framework)
- Architectural Patterns catalog integration
- Timeless writing standards (no historical markers)

**Phase 6 Tasks 6.1-6.2** (lines 745-787):
- Review Standards 0, 11, 13, 14 compliance
- Update command_architecture_standards.md if needed
- Add hybrid classification pattern to Architectural Patterns catalog

### 9. Outdated Patterns or Approaches

**No Subprocess Isolation Updates**:
Plan 670 references bash-block-execution-model.md (line 193) but doesn't detail specific subprocess isolation patterns discovered during Spec 661 implementation (save-before-source, fixed semantic filenames, etc.).

**No State Persistence Library References**:
Plan 670 references state-persistence.sh patterns (line 198) but doesn't specify which state persistence patterns to follow (selective file-based persistence, graceful degradation, 7 critical items pattern).

**No Verification Checkpoint Pattern**:
Plan 670 doesn't reference verification checkpoint pattern for file creation operations (Standard 0 enforcement pattern from recent refactor work).

## Recommendations

### 1. Update Spec 672 Integration Context

**Action**: Revise Phase 1 Task 1.1 and Phase 2 Task 2.1 to reference actual Spec 661 implementation instead of planned Spec 672 work.

**Rationale**: Revision 3 added Spec 672 integration requirements, but recent work was done under Spec 661. Plan should reference actual completed work, not planned work.

**Specific Changes**:
- Line 195: Change "Spec 672 Integration" to "Spec 661 Integration (state-based orchestration refactor)"
- Line 196: Update reference path to match actual implementation plan (likely in .claude/specs/661_* directory)
- Line 320: Update "Spec 672 Integration" section similarly

### 2. Add State ID File Persistence Considerations

**Action**: Add acceptance criteria to Phase 1 Task 1.1 for state ID file persistence compatibility.

**Rationale**: Recent refactor implemented state ID file persistence fixes (Spec 661 Phases 1-2). If workflow-llm-classifier.sh interacts with state management, it should follow established patterns.

**Specific Addition** (after line 208):
```
- [ ] State ID file persistence compatibility (if library stores state)
- [ ] Follow fixed semantic filename pattern from state-persistence.sh
```

### 3. Verify Library Sourcing Order

**Action**: Add explicit library sourcing order verification to Phase 2 Task 2.1 acceptance criteria.

**Rationale**: Recent refactor fixed library sourcing order issues (Spec 661 Phase 3). Plan should explicitly verify new libraries follow established order.

**Specific Addition** (after line 333):
```
- [ ] Library sourcing order verified (detect-project-dir.sh before state-persistence.sh before workflow-state-machine.sh)
- [ ] No circular dependencies introduced
```

### 4. Align Integration Tests with Spec 661 Patterns

**Action**: Update Phase 3 Task 3.5 to reference Spec 661 Phase 4 integration test patterns.

**Rationale**: Recent refactor established integration test patterns for library sourcing. Plan 670's tests should follow same patterns for consistency.

**Specific Addition** (after line 536):
```
**Integration Test Pattern Reference**:
- Follow test patterns from Spec 661 Phase 4 (Library Sourcing and Integration Tests)
- Verify library sourcing order in integration tests
- Test source guard behavior (duplicate sourcing prevention)
```

### 5. Add Subprocess Isolation Pattern Details

**Action**: Expand Phase 1 Task 1.1 subprocess isolation requirements with specific patterns from bash-block-execution-model.md.

**Rationale**: Plan references bash-block-execution-model.md but doesn't specify which patterns to follow. Recent refactor validated specific patterns (save-before-source, fixed semantic filenames, library re-sourcing).

**Specific Addition** (after line 193):
```
**Subprocess Isolation Patterns** (per bash-block-execution-model.md):
- Use fixed semantic filenames for state files (not $$-based temporary files)
- Apply save-before-source pattern for cross-block state
- Re-source libraries in each bash block (no export assumptions)
- Avoid premature traps (cleanup only at end of final block)
```

### 6. Reference State Persistence Patterns

**Action**: Add state persistence pattern details to Phase 1 Task 1.1 if workflow-llm-classifier.sh needs state management.

**Rationale**: Plan references state-persistence.sh patterns (line 198) but doesn't specify which patterns to follow. Recent refactor established selective file-based persistence patterns.

**Specific Addition** (conditional, after line 208 if state management needed):
```
**State Persistence Patterns** (if classifier needs state):
- Follow selective file-based persistence (7 critical items pattern)
- Implement graceful degradation to stateless recalculation
- Use GitHub Actions-style workflow state files
- 67% performance improvement target for cached operations
```

### 7. Add Verification Checkpoint Pattern

**Action**: Add verification checkpoint requirements to Phase 1 Task 1.3 (AI Assistant Integration).

**Rationale**: Recent refactor emphasized Standard 0 (Execution Enforcement) verification checkpoints. LLM invocation should verify response file creation before proceeding.

**Specific Addition** (after line 254):
```
**Verification Checkpoint** (Standard 0 Execution Enforcement):
- [ ] Verify response file exists before parsing
- [ ] Fail-fast with diagnostic message if response missing
- [ ] No silent fallbacks that hide errors
- [ ] Clear error messages for timeout vs file-not-found vs malformed-response
```

### 8. Document Refactor-Informed Architecture Decisions

**Action**: Add new section to plan documenting architectural decisions informed by recent refactor learnings.

**Rationale**: Recent refactor validated patterns that Plan 670 should adopt. Documenting these decisions prevents re-litigating solved problems.

**Specific Addition** (new section after line 117):
```
### Refactor-Informed Architecture Decisions

**Recent Refactor Context** (Spec 661 Phases 1-4 completed 2025-11-11):
- State ID file persistence fix and tests (Phases 1-2)
- Library sourcing order fix (Phase 3)
- Library sourcing and integration tests (Phase 4)

**Architectural Decisions Based on Refactor Learnings**:
1. **Library Sourcing Pattern**: Follow detect-project-dir.sh → state-persistence.sh → workflow-state-machine.sh order
2. **Source Guards**: Implement WORKFLOW_LLM_CLASSIFIER_SOURCED guard in workflow-llm-classifier.sh
3. **State File Naming**: Use fixed semantic filenames (not $$ temporaries) if classifier stores state
4. **Verification Checkpoints**: Add mandatory file existence checks before parsing LLM responses
5. **Integration Testing**: Follow Spec 661 Phase 4 test patterns for library sourcing verification
6. **Subprocess Isolation**: Apply bash-block-execution-model.md validated patterns (save-before-source, library re-sourcing)
```

### 9. Update Related Documents References

**Action**: Verify all 4 related documents referenced in plan header (line 10-13) still exist and are accurate.

**Rationale**: Plan references reports that may have been updated or superseded during recent refactor work.

**Specific Verification**:
- Line 10: Verify `../../workflow_scope_detection_analysis.md` exists
- Line 11: Verify `../reports/001_llm_based_classification_research.md` exists
- Line 12: Verify `../reports/002_comparative_analysis_and_synthesis.md` exists
- Line 13: Verify `../reports/003_implementation_architecture.md` exists

### 10. Add Cross-Reference to Recent Refactor Summary

**Action**: Add cross-reference to recent refactor implementation summary if one exists.

**Rationale**: Plan should reference completed work that impacts its implementation. Recent refactor summary would provide implementation details for patterns Plan 670 needs to follow.

**Specific Addition** (after line 13 in Related Documents):
```
- Recent Refactor: `.claude/specs/661_*/summaries/001_*.md` (state-based orchestration refactor implementation summary)
```

## References

### Plan File
- `/home/benjamin/.config/.claude/specs/670_workflow_classification_improvement/plans/001_hybrid_classification_implementation.md` (1,181 lines)

### Key Sections Referenced
- Lines 1-14: Plan metadata and status
- Lines 106-117: State machine integration
- Lines 150-787: Phase definitions (all 6 phases)
- Lines 790-817: Phase dependencies graph
- Lines 1050-1078: File change summary and clean-break impact
- Lines 1103-1145: Revision history (Revisions 2-3)

### Related Standards
- Standard 0: Execution Enforcement (verification checkpoints)
- Standard 11: Imperative Agent Invocation Pattern
- Standard 13: Project Directory Detection
- Standard 14: Executable/Documentation Separation

### Recent Refactor Context
- Spec 661 Phases 1-4: State-based orchestration refactor (completed 2025-11-11)
- bash-block-execution-model.md: Subprocess isolation patterns
- state-persistence.sh: Selective file-based persistence patterns
- workflow-state-machine.sh: State machine library patterns
