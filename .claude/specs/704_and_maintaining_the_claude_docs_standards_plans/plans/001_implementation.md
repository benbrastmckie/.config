# Comprehensive Test Fixes and Infrastructure Improvements - Aggregated Implementation Plan

## Metadata
- **Date**: 2025-11-13
- **Last Revised**: 2025-11-13 (Revision 1: Simplified LLM fallback)
- **Feature**: Aggregated plan addressing all issues from Plans 702 and 703, integrating with .claude/ infrastructure cleanup
- **Scope**: LLM classification fixes, test infrastructure, library patterns, directory organization, documentation standards
- **Estimated Phases**: 10
- **Estimated Hours**: 33-40 (revised from 38-45 after simplification)
- **Structure Level**: 0
- **Complexity Score**: 167.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Directory Structure Organization Analysis](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/001_directory_structure_organization_analysis.md)
  - [Scripts/Lib Consolidation Approach](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/002_scripts_lib_consolidation_approach.md)
  - [Template Relocation Reference Updates](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/003_template_relocation_reference_updates.md)
  - [Documentation Updates Organizational Standards](/home/benjamin/.config/.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/004_documentation_updates_organizational_standards.md)
- **Source Plans**:
  - [Plan 702: /coordinate LLM Classification Fixes](/home/benjamin/.config/.claude/specs/702_coordinate_command_failure_analysis/plans/001_coordinate_classification_fixes.md)
  - [Plan 703: Failing Tests Implementation Fixes](/home/benjamin/.config/.claude/specs/703_fix_failing_tests/plans/001_test_failure_fixes_implementation.md)

## Revision History

### 2025-11-13 - Revision 1: Simplified LLM Classification Fallback

**Changes**: Replaced Phases 3-4 (Layered Network Detection + Automatic Fallback) with simplified user prompt approach

**Reason**: User requested simplification to avoid excessive complexity. Research showed that:
- Interactive user prompts are 70% simpler (100 lines vs 300+ lines)
- Handle ALL failure types (network, API, confidence) not just network issues
- Save 3-5 hours implementation time
- Preserve fail-fast philosophy while providing explicit user control

**Reports Used**:
- [LLM Classification Failure Handling Research](/home/benjamin/.config/.claude/specs/temp_research/llm_classification_failure_handling_report.md)

**Modified Phases**:
- Phase 3: Changed from "Layered Network Detection" (High complexity, 3.5h) to "User Prompt Fallback Implementation" (Low complexity, 2.5h)
- Phase 4: Changed from "Automatic Fallback and Testing" (High complexity, 6h) to "Testing and Documentation" (Low complexity, 1.5h)

**Complexity Impact**:
- Original Phases 3-4: High complexity, 9.5 hours, 300+ lines of code
- Revised Phases 3-4: Low complexity, 4 hours, ~100 lines of code
- Time savings: 5.5 hours (58% reduction)
- Code reduction: 200+ lines (67% reduction)

**Estimated Hours Update**: 38-45 hours → 33-40 hours (5.5 hour reduction)

## Overview

This aggregated plan unifies fixes from Plans 702 and 703 while integrating directory organization cleanup and documentation standardization. The plan addresses root causes systematically rather than treating symptoms in isolation.

**Key Insight**: Test failures and /coordinate classification issues share common root causes in bash block execution model, library sourcing patterns, and test mode infrastructure. The test mode infrastructure implemented in Plan 703 Phase 0 (COMPLETED) provides foundation for verifying /coordinate classification fixes.

**Strategic Integration Points**:
1. **Test Mode Infrastructure** (703 Phase 0) → Enables verification of LLM classification changes (702)
2. **Library Sourcing Patterns** (703 Phases 2-3) → Supports state persistence fixes (702 Phase 3)
3. **Directory Organization** (Research 001-002) → Clarifies where classification utilities belong
4. **Template Consolidation** (Research 003) → Streamlines agent template references
5. **Documentation Standards** (Research 004) → Ensures maintainable standards compliance

## Research Summary

**Directory Organization Analysis** (Report 001):
- scripts/ contains 7 operational CLI tools (validation, fixing, analysis)
- lib/ contains 56 sourced function libraries
- Templates split across .claude/templates/ (1 file) and .claude/commands/templates/ (11 files)
- validate_links_temp.sh misplaced at root level (should be in scripts/)
- Recommendation: Retain both scripts/ and lib/ with clarified purposes, consolidate templates

**Scripts/Lib Consolidation** (Report 002):
- Previous Spec 492 attempted complete scripts/ elimination but failed
- Directories serve fundamentally different purposes (CLI tools vs sourced libraries)
- Recommendation: Clarification over consolidation - document distinctions, don't merge
- Decision matrix needed for file placement

**Template Relocation** (Report 003):
- 119 files reference .claude/templates/ path
- sub-supervisor-template.md belongs in agents/templates/, not general templates/
- Automated migration script required for reference updates
- Estimated effort: 3-4 hours including verification

**Documentation Standards** (Report 004):
- scripts/README.md missing (critical gap)
- lib/README.md has misleading title "Standalone Utility Scripts"
- CLAUDE.md lacks directory organization standards section
- agents/templates/README.md needed after template relocation
- Estimated effort: 3 hours for comprehensive documentation

**LLM Classification Issues** (Plan 702):
- Error messages suppressed by stderr redirection in sm_init() (30% → 100% visibility needed)
- PID-based filenames incompatible with bash block execution model (file leaks confirmed)
- Single-method network detection (ping only) produces 25-30% false negatives
- No automatic fallback to regex-only mode (manual mode switching required)

**Test Infrastructure Issues** (Plan 703):
- Test mode infrastructure implemented (Phase 0 COMPLETED)
- 77/110 test suites passing (70% pass rate, up from ~60%)
- 33 failing tests across 6 categories: coordinate commands (7), orchestration (6), libraries (10), validation (2), integration (6), system (2)
- Root causes: environment initialization, library sourcing, documentation gaps, test expectations

## Success Criteria

### LLM Classification Improvements (Plan 702)
- [ ] Error visibility: 30% → 100% (users see all classification error messages)
- [ ] Network detection accuracy: 70-75% → 95%+ (layered detection handles corporate firewalls)
- [ ] Offline failure time: 10s → 1-4s (60-90% improvement)
- [ ] File leaks: Eliminated (0 orphaned temp files, workflow-scoped cleanup)
- [ ] Automatic fallback: Offline scenarios gracefully degrade to regex-only mode

### Test Infrastructure (Plan 703)
- [x] Test mode infrastructure implemented (COMPLETED)
- [x] 77/110 tests passing (70% pass rate achieved)
- [ ] All 33 remaining failing tests pass
- [ ] 100% test pass rate (110/110 suites)
- [ ] Test execution time <5 minutes

### Directory Organization (Research)
- [ ] validate_links_temp.sh relocated or deleted (root directory clean)
- [ ] scripts/README.md created with clear purpose documentation
- [ ] lib/README.md updated with corrected title
- [ ] Templates consolidated (agents/templates/ created, .claude/templates/ removed)
- [ ] All 119 template references updated

### Documentation Standards (Research)
- [ ] CLAUDE.md contains directory organization standards section
- [ ] Decision matrix documented for file placement
- [ ] All directories have up-to-date READMEs
- [ ] Link validation passes (0 broken links)

## Technical Design

### Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│ Root Issue: Bash Block Execution Model Constraints            │
│ - Subprocess isolation (each block = separate process)         │
│ - State must persist via files, not variables                  │
│ - PID-based filenames fail across blocks                       │
│ - Library sourcing required per block                          │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ Solution Layer 1: Semantic Filenames (Fixed Paths)            │
│ - Workflow-scoped: ${HOME}/.claude/tmp/llm_request_${WF_ID}   │
│ - Checkpoint files: ${CLAUDE_PROJECT_DIR}/.claude/data/...    │
│ - State persistence: Predictable paths across blocks          │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ Solution Layer 2: Test Mode Infrastructure (Deterministic)    │
│ - WORKFLOW_CLASSIFICATION_TEST_MODE=1 returns fixtures         │
│ - No real LLM API calls during testing                         │
│ - Fast execution (<5 min vs ~10 min)                          │
│ - Enabled globally in run_all_tests.sh                        │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ Solution Layer 3: Layered Network Detection                    │
│ - Layer 1: ICMP ping (1s, handles most cases)                 │
│ - Layer 2: TCP netcat (1s, corporate firewall fallback)       │
│ - Layer 3: HTTP curl (2s, respects HTTP_PROXY)                │
│ - Layer 4: IPv6 ping (1s, modern networks)                    │
│ Total: 4s worst-case, 95%+ accuracy                           │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ Solution Layer 4: Automatic Fallback (Verification Pattern)   │
│ - LLM classification fails → automatic regex-only fallback     │
│ - Warning messages maintain visibility                         │
│ - Aligns with Spec 057 verification fallback pattern          │
│ - User can still force mode with WORKFLOW_CLASSIFICATION_MODE  │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ Solution Layer 5: Directory Organization Standards            │
│ - scripts/: CLI tools (validate, fix, analyze)                │
│ - lib/: Sourced libraries (utilities, helpers)                │
│ - agents/templates/: Agent templates (sub-supervisor)         │
│ - commands/templates/: Plan templates (YAML)                  │
│ - Decision matrix prevents future misplacements               │
└────────────────────────────────────────────────────────────────┘
```

### Component Interactions

**Interaction 1: Test Mode → LLM Classification**
- Test mode fixture responses enable deterministic testing of classification logic
- Changes to classification code verified immediately without network dependency
- Performance improvements measurable (execution time tracking)

**Interaction 2: Semantic Filenames → State Persistence**
- Workflow-scoped filenames persist across bash blocks
- Checkpoint recovery works reliably with fixed paths
- Cleanup happens at workflow completion, not bash block exit

**Interaction 3: Error Visibility → Automatic Fallback**
- Captured stderr shown to users on failure
- Warning messages explain fallback activation
- Clear guidance about network issues and mode options

**Interaction 4: Library Sourcing → Test Environment**
- CLAUDE_PROJECT_DIR initialization enables library discovery
- Defensive checks (emit_progress availability) provide graceful degradation
- Unified-logger.sh sourcing follows Standard 15 (library sourcing order)

**Interaction 5: Template Organization → Agent Invocation**
- Agent templates in agents/templates/ (logical location)
- Plan templates in commands/templates/ (consumer-specific)
- Clear separation prevents template confusion

## Implementation Phases

### Phase 0: Foundation - Test Mode Verification ✓ COMPLETED
dependencies: []

**Status**: ✓ COMPLETED (Plan 703 Phase 0)

**Completed Work**:
- [x] Test mode infrastructure implemented in workflow-llm-classifier.sh
- [x] WORKFLOW_CLASSIFICATION_TEST_MODE=1 returns fixture JSON
- [x] Enabled globally in run_all_tests.sh
- [x] 77/110 test suites now passing (70% pass rate, up from ~60%)
- [x] Test execution time reduced from ~10 min to ~3 min

**Verification**:
```bash
# Verify test mode works
export WORKFLOW_CLASSIFICATION_TEST_MODE=1
source .claude/lib/workflow-llm-classifier.sh
classify_workflow_llm_comprehensive "research patterns" | jq .
# Should return fixture JSON without network call

# Verify tests use test mode
grep -q "WORKFLOW_CLASSIFICATION_TEST_MODE=1" .claude/tests/run_all_tests.sh
echo "✓ Test mode enabled globally"
```

### Phase 1: LLM Classification - Error Visibility and Handler Integration [COMPLETED]
dependencies: []

**Objective**: Surface suppressed error messages and integrate structured error handler (Plan 702 Phases 1-2 combined)

**Complexity**: Low

**Tasks**:
- [x] Modify workflow-state-machine.sh:353 to capture stderr to temp file (file: .claude/lib/workflow-state-machine.sh, lines 353-384)
- [x] Update sm_init() failure path to display captured stderr before returning error
- [x] Add cleanup of stderr temp file on success and failure paths
- [x] Replace inline error block in classify_workflow_llm_comprehensive() with handle_llm_classification_failure() call (file: .claude/lib/workflow-llm-classifier.sh, lines 53-56)
- [x] Replace inline error block in invoke_llm_classifier() timeout path with handle_llm_classification_failure() call (file: .claude/lib/workflow-llm-classifier.sh, lines 329-332)
- [x] Update handle_llm_classification_failure() to support "network" error type (file: .claude/lib/workflow-llm-classifier.sh, lines 489-535)
- [x] Add test case for error handler integration (file: .claude/tests/test_llm_classifier.sh)

**Testing**:
```bash
# Test stderr visibility
export WORKFLOW_CLASSIFICATION_MODE=llm-only
export WORKFLOW_CLASSIFICATION_TEST_MODE=0  # Disable fixture mode
# Disconnect network or use offline environment
bash -c "source .claude/lib/workflow-state-machine.sh; sm_init 'research patterns'"
# Expected: See warning messages about network issues

# Test error handler integration
bash .claude/tests/test_llm_classifier.sh
# Expected: All tests pass including new error handler test
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(704): complete Phase 1 - Error Visibility and Handler Integration`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: LLM Classification - Semantic Filename Persistence [COMPLETED]
dependencies: [1]

**Objective**: Replace PID-based filenames with workflow-scoped semantic names (Plan 702 Phase 3)

**Complexity**: Medium

**Tasks**:
- [x] Update invoke_llm_classifier() signature to accept workflow_id parameter (file: .claude/lib/workflow-llm-classifier.sh, line 278)
- [x] Replace PID-based request_file with semantic pattern: ${HOME}/.claude/tmp/llm_request_${workflow_id}.json
- [x] Replace PID-based response_file with semantic pattern: ${HOME}/.claude/tmp/llm_response_${workflow_id}.json
- [x] Create ${HOME}/.claude/tmp directory if not exists
- [x] Update all callers of invoke_llm_classifier() to pass workflow_id
- [x] Add workflow-scoped cleanup function cleanup_workflow_classification_files()
- [x] Integrate cleanup with workflow completion in coordinate.md display_brief_summary
- [x] Remove EXIT trap from invoke_llm_classifier() (trap now premature per bash block execution model)
- [x] Update error messages to reference new file locations
- [ ] Document semantic filename pattern in bash-block-execution-model.md

**Testing**:
```bash
# Test semantic filename persistence
export WORKFLOW_CLASSIFICATION_TEST_MODE=0
WORKFLOW_ID="test_$(date +%s)"
bash -c "source .claude/lib/workflow-llm-classifier.sh; invoke_llm_classifier '{\"desc\":\"test\"}' '$WORKFLOW_ID'"
# Verify file persists
ls "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"

# Test cleanup
# Run coordinate workflow to completion
# Verify no orphaned files
ls "${HOME}/.claude/tmp/llm_*.json" | wc -l
# Should be 0 after cleanup
```

**Expected Duration**: 3 hours

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x] (except documentation task deferred)
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(704): complete Phase 2 - Semantic Filename Persistence`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: LLM Classification - Maintain Fail-Fast Approach [COMPLETED]
dependencies: [2]

**Objective**: ~~Implement user prompt fallback~~ Maintain fail-fast approach with improved error visibility

**Complexity**: Low

**Decision**: User requested to maintain fail-fast philosophy instead of implementing user prompt fallback. Errors will be used to continue improving LLM classification until it works well in all settings. This preserves the fail-fast approach while benefiting from Phase 1's improved error visibility.

**Tasks**:
- [x] Verify fail-fast behavior maintained (return 1 on classification failure)
- [x] Confirm Phase 1 error visibility improvements work correctly
- [x] Test that troubleshooting messages guide users to solutions
- [N/A] ~~Modify sm_init() to return code 2~~ (maintaining return 1 for fail-fast)
- [N/A] ~~Set CLASSIFICATION_FAILED state variables~~
- [N/A] ~~Add classification failure detection in coordinate.md~~
- [N/A] ~~Implement AskUserQuestion prompt~~
- [N/A] ~~Wire up heuristic fallback functions~~
- [N/A] ~~Add CLASSIFICATION_METHOD tracking~~

**AskUserQuestion Prompt Structure**:
```markdown
AskUserQuestion {
  questions: [
    {
      question: "LLM classification unavailable. Which workflow type matches your intent for: \"$WORKFLOW_DESCRIPTION_FOR_PROMPT\"?",
      header: "Workflow",
      multiSelect: false,
      options: [
        {label: "Research Only", description: "Research topics without creating a plan (no implementation)"},
        {label: "Research + Plan", description: "Research topics and create an implementation plan (no execution)"},
        {label: "Revise Plan", description: "Research to update/revise an existing implementation plan"},
        {label: "Full Implementation", description: "Research, plan, implement, test, and document (complete workflow)"},
        {label: "Debug Only", description: "Debug and analyze issues without creating new implementation"}
      ]
    }
  ]
}
```

**Testing**:
```bash
# Test fail-fast behavior with improved error visibility
export WORKFLOW_CLASSIFICATION_TEST_MODE=0
export WORKFLOW_CLASSIFICATION_MODE=llm-only
source .claude/lib/workflow-state-machine.sh
sm_init "test workflow" "test" 2>&1
# Expected: Clear error messages with troubleshooting steps, return code 1

# Verify error visibility improvements from Phase 1
# Expected output includes:
# - "Classification Error Details:" section
# - "CRITICAL ERROR: Comprehensive classification failed"
# - Troubleshooting steps (network, timeout, regex-only mode)

# Test with regex-only mode (should work offline)
export WORKFLOW_CLASSIFICATION_MODE=regex-only
sm_init "research authentication patterns" "test" 2>&1
# Expected: Success with regex classification
```

**Expected Duration**: 0.5 hours (simplified from original 2.5 hours)

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x] or [N/A]
- [x] Fail-fast behavior verified
- [x] Tests passing (error visibility confirmed)
- [x] Git commit created: `feat(704): complete Phase 3 - Maintain Fail-Fast Approach`
- [x] Update this plan file with phase completion status

### Phase 4: LLM Classification - Testing and Documentation
dependencies: [3]

**Objective**: ~~Comprehensive testing of user prompt fallback~~ Test fail-fast behavior and update documentation

**Complexity**: Low

**Decision**: Phase 4 simplified to test fail-fast approach and document error visibility improvements.

**Tasks**:
- [N/A] ~~Create test_sm_init_classification_failure.sh~~ (fail-fast returns 1, not 2)
- [N/A] ~~Create test_user_prompt_workflow.sh~~ (no user prompt implementation)
- [N/A] ~~Test heuristic fallback functions~~ (no automatic fallback)
- [ ] Run existing test suite to verify no regressions
- [ ] Update coordinate-command-guide.md with Phase 1 error visibility improvements
- [ ] Document troubleshooting workflow for classification failures
- [ ] Verify regex-only mode works as offline alternative
- [ ] Test error messages provide actionable guidance

**Testing**:
```bash
# Unit tests
bash .claude/tests/test_sm_init_classification_failure.sh
# Expected: Verify return code 2, state variables, error messages

# Integration tests
bash .claude/tests/test_user_prompt_workflow.sh
# Expected: Test all 5 workflow type selections end-to-end

# Heuristic fallback verification
bash -c "source .claude/lib/workflow-scope-detection.sh; \
  infer_complexity_from_keywords 'simple bug fix'; \
  echo 'Expected: 1'"

bash -c "source .claude/lib/workflow-scope-detection.sh; \
  infer_complexity_from_keywords 'research authentication patterns and implement OAuth flow'; \
  echo 'Expected: 3-4'"

# Generic topic generation
bash -c "source .claude/lib/workflow-scope-detection.sh; \
  generate_generic_topics 3 | jq 'length'; \
  echo 'Expected: 3'"

# Full test suite
bash .claude/tests/run_all_tests.sh
# Expected: All tests pass including new classification fallback tests
```

**Documentation Updates**:
- coordinate-command-guide.md: Section on "Classification Fallback Behavior"
- CLAUDE.md: Update "LLM Classification" section with fallback approach
- Add user prompt UX mockup to guide

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 4 - Testing and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Test Infrastructure - Environment and Library Fixes
dependencies: [1, 2]

**Objective**: Fix test environment initialization and library sourcing patterns (Plan 703 Phases 1-4 combined)

**Complexity**: Medium

**Tasks**:
- [ ] Audit remaining 33 failing tests for CLAUDE_PROJECT_DIR issues
- [ ] Add initialization block to tests that source libraries without setting CLAUDE_PROJECT_DIR
- [ ] Verify all library source statements use ${CLAUDE_PROJECT_DIR} prefix
- [ ] Add unified-logger.sh to REQUIRED_LIBS array in coordinate.md for all scopes
- [ ] Add defensive check pattern for emit_progress calls (if command -v emit_progress...)
- [ ] Apply fallback pattern to all emit_progress calls in coordinate.md (6-8 locations)
- [ ] Add dependency-analyzer.sh to REQUIRED_LIBS for full-implementation scope
- [ ] Investigate test_bash_command_fixes.sh nameref requirement (decide: add pattern OR update test)
- [ ] Fix test_state_machine.sh, test_state_persistence.sh, test_workflow_initialization.sh failures
- [ ] Fix test_shared_utilities.sh and test_topic_filename_generation.sh failures

**Testing**:
```bash
# Test environment initialization
for test in test_coordinate_*.sh; do
  bash "$test" 2>&1 | grep -E "unbound variable|No such file" || echo "✓ $test"
done

# Test library sourcing
bash .claude/tests/test_bash_command_fixes.sh
# Expected: Tests 3-4 pass (unified-logger sourcing, fallback pattern)

# Test dependency analyzer
bash .claude/tests/test_coordinate_waves.sh
bash .claude/tests/test_coordinate_all.sh
# Expected: Wave execution tests pass

# Test library implementations
for test in test_state_machine test_state_persistence test_workflow_initialization test_shared_utilities test_topic_filename_generation; do
  echo "=== Testing: $test ==="
  bash .claude/tests/${test}.sh
done
# Expected: All 5 library tests pass
```

**Expected Duration**: 4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 5 - Test Environment and Library Fixes`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Test Infrastructure - Orchestration and Integration Fixes
dependencies: [5]

**Objective**: Fix orchestrate, coordinate, and integration test failures (Plan 703 Phases 5-8 combined)

**Complexity**: High

**Tasks**:
- [ ] Add topic-based path format documentation to orchestrate.md Phase 2
- [ ] Add research report cross-reference passing documentation
- [ ] Add metadata extraction strategy documentation
- [ ] Add summary template artifact sections
- [ ] Fix test_coordinate_error_fixes.sh (error handling validation)
- [ ] Fix test_coordinate_preprocessing.sh (history expansion, quoting)
- [ ] Fix test_coordinate_standards.sh (Standard 11, Standard 15 compliance)
- [ ] Fix test_coordinate_synchronization.sh (state synchronization)
- [ ] Fix test_orchestration_commands.sh (multi-command validation)
- [ ] Fix test_supervise_agent_delegation.sh, test_supervise_delegation.sh, test_supervise_scope_detection.sh

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Fix test_all_delegation_fixes.sh (comprehensive delegation validation)
- [ ] Fix test_all_fixes_integration.sh (cross-cutting integration)
- [ ] Fix test_phase3_verification.sh, test_revision_specialist.sh
- [ ] Fix test_supervisor_checkpoint_old.sh, test_template_integration.sh
- [ ] Fix validate_executable_doc_separation.sh, validate_no_agent_slash_commands.sh
- [ ] Fix test_system_wide_empty_directories.sh
- [ ] Fix test_scope_detection.sh, test_scope_detection_ab.sh
- [ ] Investigate and fix "Agent" and "SOME" tests

**Testing**:
```bash
# Test orchestrate documentation
bash .claude/tests/test_orchestrate_planning_behavioral_injection.sh
bash .claude/tests/test_orchestrate_research_enhancements_simple.sh

# Test coordinate fixes
for test in test_coordinate_error_fixes test_coordinate_preprocessing test_coordinate_standards test_coordinate_synchronization; do
  echo "=== Testing: $test ==="
  bash .claude/tests/${test}.sh
done

# Test orchestration commands
bash .claude/tests/test_orchestration_commands.sh
bash .claude/tests/test_supervise_agent_delegation.sh
bash .claude/tests/test_supervise_delegation.sh

# Test integration and validation
bash .claude/tests/test_all_delegation_fixes.sh
bash .claude/tests/validate_executable_doc_separation.sh
bash .claude/tests/validate_no_agent_slash_commands.sh

# Final verification - all 110 tests
bash .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/test_results.txt
grep "Test Suites Passed:" /tmp/test_results.txt
# Expected: 110/110 (100% pass rate)
```

**Expected Duration**: 7 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 6 - Orchestration and Integration Fixes`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Directory Organization - File Relocation and Cleanup
dependencies: []

**Objective**: Relocate misplaced files and consolidate template directories (Research Reports 001, 003)

**Complexity**: Low

**Tasks**:
- [ ] Examine validate_links_temp.sh functionality vs scripts/validate-links.sh
- [ ] If unique: Move to scripts/validate-docs-links.sh, if redundant: delete
- [ ] Update any references to validate_links_temp.sh (grep search)
- [ ] Create .claude/agents/templates/ directory
- [ ] Create .claude/agents/templates/README.md (template purpose documentation)
- [ ] Use git mv to move sub-supervisor-template.md to agents/templates/
- [ ] Verify file integrity after move (line count, content check)
- [ ] Create migration script: scripts/update-template-references.sh
- [ ] Test migration script with --dry-run mode
- [ ] Execute migration script (update 119 references)
- [ ] Verify all references updated (grep for old path should return nothing)
- [ ] Remove empty .claude/templates/ directory (git rm -r)
- [ ] Verify git history preserved (git log --follow)

**Testing**:
```bash
# Verify root cleanup
test ! -f .claude/validate_links_temp.sh && echo "✓ Root cleaned"

# Verify template relocation
test -f .claude/agents/templates/sub-supervisor-template.md && echo "✓ Template moved"
test ! -d .claude/templates && echo "✓ Empty directory removed"

# Verify reference updates
REFS=$(grep -r "\.claude/templates/sub-supervisor" . --include="*.md" --include="*.sh" --exclude-dir=".git" --exclude-dir="archive" | wc -l)
[ "$REFS" -eq 0 ] && echo "✓ All references updated"

# Verify git history
git log --follow .claude/agents/templates/sub-supervisor-template.md | head -20
# Should show history from old location

# Run link validation
./scripts/validate-links.sh
# Expected: 0 broken links
```

**Expected Duration**: 3.5 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 7 - Directory Organization and File Relocation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 8: Documentation - README Creation and Updates
dependencies: [7]

**Objective**: Create missing READMEs and update documentation (Research Reports 002, 004)

**Complexity**: Low

**Tasks**:
- [ ] Create scripts/README.md with purpose, current scripts, usage examples, vs lib/ comparison (file: .claude/scripts/README.md, new file)
- [ ] Update lib/README.md title from "Standalone Utility Scripts" to "Sourced Function Libraries"
- [ ] Add "vs scripts/" section to lib/README.md with comparison table
- [ ] Add decision matrix to lib/README.md (when to use lib/ vs scripts/)
- [ ] Update .claude/README.md directory structure section (add agents/templates/, remove templates/)
- [ ] Add organization principles note to .claude/README.md
- [ ] Update link validation documentation references (file: .claude/docs/troubleshooting/broken-links-troubleshooting.md)

**Testing**:
```bash
# Verify README files created
test -f .claude/scripts/README.md && echo "✓ scripts/README.md created"
test -f .claude/agents/templates/README.md && echo "✓ agents/templates/README.md created"

# Verify lib/README.md updated
grep "Sourced Function Libraries" .claude/lib/README.md && echo "✓ Title fixed"
grep "vs scripts/" .claude/lib/README.md && echo "✓ Distinction documented"

# Verify .claude/README.md updated
grep "agents/templates/" .claude/README.md && echo "✓ Structure updated"

# Run link validation
./scripts/validate-links.sh
# Expected: 0 broken links
```

**Expected Duration**: 2.5 hours

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 8 - Documentation README Creation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 9: Documentation - CLAUDE.md Standards Section
dependencies: [8]

**Objective**: Add comprehensive directory organization standards to CLAUDE.md (Research Report 004)

**Complexity**: Low

**Tasks**:
- [ ] Add directory_organization section to CLAUDE.md after code_standards section
- [ ] Document scripts/ purpose, characteristics, naming, examples
- [ ] Document lib/ purpose, characteristics, naming, examples
- [ ] Document commands/ structure and purpose
- [ ] Document agents/ structure and templates/ subdirectory
- [ ] Add file placement decision matrix table
- [ ] Add anti-patterns section (wrong locations, naming violations)
- [ ] Add directory README requirements
- [ ] Verify section is properly marked with SECTION comments for discoverability

**Testing**:
```bash
# Verify section added
grep "directory_organization" CLAUDE.md && echo "✓ Section exists"
grep "Decision Matrix" CLAUDE.md && echo "✓ Decision matrix documented"
grep "Anti-Patterns" CLAUDE.md && echo "✓ Anti-patterns documented"

# Verify section markers
grep "<!-- SECTION: directory_organization -->" CLAUDE.md && echo "✓ Start marker"
grep "<!-- END_SECTION: directory_organization -->" CLAUDE.md && echo "✓ End marker"

# Run link validation
./scripts/validate-links.sh
# Expected: 0 broken links
```

**Expected Duration**: 1.5 hours

**Phase 9 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 9 - CLAUDE.md Standards Section`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 10: Integration Testing and Final Verification
dependencies: [4, 6, 9]

**Objective**: Comprehensive end-to-end testing and documentation updates (Plan 702 Phase 7 + final verification)

**Complexity**: Medium

**Tasks**:
- [ ] Update CLAUDE.md with WORKFLOW_CLASSIFICATION_MODE documentation
- [ ] Document layered network detection in workflow-classification-guide.md
- [ ] Update coordinate-command-guide.md troubleshooting section
- [ ] Add semantic filename pattern to bash-block-execution-model.md examples
- [ ] Run end-to-end test: Offline development scenario (network disconnected)
- [ ] Run end-to-end test: Corporate firewall scenario (ICMP blocked)
- [ ] Run end-to-end test: Transient network failure (disconnect mid-workflow)
- [ ] Run end-to-end test: Multi-block workflow with semantic files
- [ ] Verify success criterion: Error visibility 100%
- [ ] Verify success criterion: Network detection 95%+
- [ ] Verify success criterion: File leaks eliminated
- [ ] Verify success criterion: Test coverage 110/110 (100% pass rate)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Verify success criterion: All 119 template references updated
- [ ] Verify success criterion: Zero broken links
- [ ] Verify success criterion: Directory organization standards documented
- [ ] Run full test suite with performance tracking
- [ ] Verify test execution time <5 minutes
- [ ] Create implementation summary document

**Testing**:
```bash
# End-to-end integration tests
export WORKFLOW_CLASSIFICATION_TEST_MODE=0  # Use real classification

# Test 1: Offline scenario
# Disconnect network
/coordinate "research authentication patterns"
# Expected: Automatic fallback to regex-only, workflow succeeds

# Test 2: Corporate firewall scenario
# Block ICMP but allow TCP/HTTP
/coordinate "research authentication patterns"
# Expected: Layer 2 detection succeeds, workflow normal

# Test 3: Multi-block semantic files
WORKFLOW_ID="test_$(date +%s)"
# Run classification, verify files persist
ls "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"

# Test 4: File cleanup
# Complete workflow
ls "${HOME}/.claude/tmp/llm_*.json" | wc -l
# Expected: 0 (all cleaned up)

# Final test suite run
bash .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/final_verification.txt

# Verify success criteria
grep "Test Suites Passed: 110" /tmp/final_verification.txt
grep "Test Suites Failed: 0" /tmp/final_verification.txt
tail -20 /tmp/final_verification.txt | grep -E "Total execution time.*[0-9]+ seconds"
# Should be <300 seconds (5 minutes)

# Verify documentation
./scripts/validate-links.sh
# Expected: 0 broken links

# Verify no orphaned files
find .claude -name "*_temp.sh" | wc -l
# Should be 0
```

**Expected Duration**: 3.5 hours

**Phase 10 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(704): complete Phase 10 - Integration Testing and Final Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **LLM Classification**: 25 new tests (network: 7, persistence: 8, fallback: 10)
- **Test Infrastructure**: 33 failing tests → all passing
- **Total**: 110 test suites (100% pass rate target)

### Integration Testing
- **Offline Development**: Network disconnected, automatic fallback works
- **Corporate Firewall**: ICMP blocked, TCP/HTTP detection succeeds
- **Transient Failure**: Network drops mid-workflow, retry recovers
- **Multi-Block Workflow**: Semantic files persist across bash blocks
- **High-Latency Network**: Timeout adjustments prevent false positives

### Regression Testing
- **Existing Tests**: All 77 currently passing tests must continue passing
- **Backward Compatibility**: Explicit WORKFLOW_CLASSIFICATION_MODE=regex-only still works
- **Performance**: Online classification maintains <3.1s performance
- **No Breaking Changes**: Commands, agents, libraries function normally

### Performance Testing
- **Test Execution**: <5 minutes total (down from ~10 minutes)
- **Offline Classification**: 10s → 1-4s (60-90% improvement)
- **Online Classification**: <100ms overhead from layered detection
- **Corporate Firewall**: <2s (Layer 2 TCP detection)

## Documentation Requirements

### User-Facing Documentation
- **CLAUDE.md**: Directory organization standards section, WORKFLOW_CLASSIFICATION_MODE variable
- **workflow-classification-guide.md**: Layered network detection explanation
- **coordinate-command-guide.md**: Updated troubleshooting section
- **scripts/README.md**: Purpose, usage, vs lib/ comparison (NEW)
- **agents/templates/README.md**: Template usage guide (NEW)

### Developer Documentation
- **bash-block-execution-model.md**: Semantic filename pattern example
- **lib/README.md**: Fixed title, vs scripts/ distinction
- **workflow-llm-classifier.sh**: Inline comments for layered detection
- **.claude/README.md**: Updated directory structure

### Cross-References
- Link bash-block-execution-model.md → workflow-llm-classifier.sh (semantic filename usage)
- Link Spec 057 fail-fast policy → automatic fallback implementation
- Link state-persistence.sh → semantic filename precedent
- Link directory organization standards → individual directory READMEs

## Dependencies

### External Dependencies
- **jq**: JSON parsing (already required)
- **ping**: Layer 1 network detection (graceful fallback if missing)
- **nc (netcat)**: Layer 2 network detection (graceful fallback if missing)
- **curl**: Layer 3 network detection (already available, graceful fallback)
- **git**: For CLAUDE_PROJECT_DIR detection and template relocation

### Internal Dependencies
- **workflow-state-machine.sh**: sm_init() error capture mechanism
- **state-persistence.sh**: Semantic filename pattern precedent
- **workflow-llm-classifier.sh**: Test mode infrastructure (COMPLETED)
- **unified-logger.sh**: Progress markers, emit_progress function
- **dependency-analyzer.sh**: Wave-based parallel execution

### Architectural Dependencies
- **Bash Block Execution Model**: Subprocess isolation, semantic filenames required
- **Fail-Fast Policy (Spec 057)**: Verification fallback taxonomy
- **Clean-Break Philosophy**: Automatic fallback with visibility via warnings
- **State-Based Orchestration**: Workflow-scoped cleanup, checkpoint recovery

## Risk Assessment

### Technical Risks

**Risk 1: Large Reference Update Surface**
- **Likelihood**: Medium (119 template references)
- **Impact**: Medium (broken links if incomplete)
- **Mitigation**: Automated migration script with --dry-run, comprehensive verification

**Risk 2: Test Interdependencies**
- **Likelihood**: Medium (33 failing tests across multiple categories)
- **Impact**: High (cascading failures)
- **Mitigation**: Fix by category, verify no regressions between phases

**Risk 3: Layered Detection Timeout Accumulation**
- **Likelihood**: Low (4s worst-case is acceptable)
- **Impact**: Low (still faster than 10s LLM timeout)
- **Mitigation**: Fast-fail on first success, each layer has tight timeout

### Operational Risks

**Risk 4: Automatic Fallback Masks Configuration Issues**
- **Likelihood**: Low (warnings are explicit)
- **Impact**: Medium (users unaware of LLM classification problems)
- **Mitigation**: Explicit warnings, log fallback events, user can force mode

**Risk 5: Directory Reorganization Confusion**
- **Likelihood**: Low (comprehensive documentation)
- **Impact**: Medium (files placed in wrong locations)
- **Mitigation**: Decision matrix, examples, anti-patterns documentation

### Mitigation Strategy
1. Phased rollout (critical fixes first, organizational cleanup later)
2. Comprehensive testing between phases
3. Automated migration scripts with verification
4. Detailed documentation with examples
5. Rollback procedures documented per phase

## Rollback Plan

### Phase-by-Phase Rollback

**Phases 1-4 (LLM Classification)**:
- Revert workflow-llm-classifier.sh changes
- Revert workflow-state-machine.sh stderr capture
- Revert network detection to single-method ping
- Remove automatic fallback logic
- Remove new test files

**Phases 5-6 (Test Infrastructure)**:
- Revert library sourcing changes in coordinate.md
- Restore inline error handling (remove defensive checks)
- Revert test file changes
- Remove orchestrate.md documentation additions

**Phases 7-9 (Directory Organization)**:
- Move sub-supervisor-template.md back to .claude/templates/
- Restore .claude/templates/ directory
- Revert reference updates (use rollback script)
- Delete new README files
- Remove CLAUDE.md directory organization section

**Phase 10 (Integration)**:
- Revert documentation updates
- No code changes to rollback (verification phase only)

### Emergency Rollback Procedure

```bash
# Immediate: Revert last commit
git revert HEAD

# OR revert multiple commits
git revert HEAD~N  # N = number of phase commits

# Restore specific file
git checkout HEAD~1 -- path/to/file

# Force legacy mode for classification
export WORKFLOW_CLASSIFICATION_FORCE_LEGACY=1
```

## Success Metrics

### Quantitative Metrics
- **Test Pass Rate**: 70% → 100% (110/110 suites)
- **Error Visibility**: 30% → 100% (all stderr messages shown)
- **Network Detection**: 70-75% → 95%+ (measured across 7 failure modes)
- **Offline Performance**: 10s → 1-4s (60-90% improvement)
- **File Leaks**: 7 orphaned → 0 (verified by checking tmp/)
- **Test Execution**: ~10 min → <5 min (50%+ improvement)
- **Template References**: 119 updated successfully
- **Broken Links**: 0 (validate-links.sh passes)

### Qualitative Metrics
- **Developer Clarity**: Clear understanding where to place files (decision matrix)
- **User Experience**: Automatic fallback eliminates manual mode switching
- **Error Messages**: Context-specific suggestions in all failure scenarios
- **Code Quality**: DRY principle (4 inline error blocks eliminated)
- **Architectural Alignment**: Semantic filenames follow state-persistence.sh precedent
- **Standards Compliance**: Directory organization documented comprehensively

### Acceptance Criteria
- [ ] All 10 phases completed and committed
- [ ] All 110 test suites passing (100% pass rate)
- [ ] All success criteria from Plans 702 and 703 met
- [ ] All success criteria from Research Reports met
- [ ] Documentation complete (CLAUDE.md, guides, READMEs)
- [ ] Zero broken links (validate-links.sh passes)
- [ ] Zero orphaned files (root clean, tmp/ clean)
- [ ] Performance targets met (<5 min tests, <4s offline classification)

## Complexity Score Calculation

```
Base Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
           = (112 × 1.0) + (10 × 5.0) + (42 × 0.5) + (9 × 2.0)
           = 112 + 50 + 21 + 18
           = 201

Adjusted for completed Phase 0 and parallel work opportunities: 167.5
```

Score ≥50 indicates this plan may benefit from `/expand` during implementation if phases become too complex. However, clear task breakdown, progress checkpoints, and comprehensive testing strategy should enable direct implementation.

## Notes

### Integration Rationale

This aggregated plan combines three separate concerns (classification fixes, test infrastructure, organizational cleanup) because:

1. **Shared Root Cause**: Bash block execution model affects both classification (semantic filenames) and tests (library sourcing)
2. **Foundation Dependency**: Test mode infrastructure (703 Phase 0) enables verification of classification changes (702)
3. **Efficiency**: Single comprehensive fix cycle vs three separate implementation efforts
4. **Consistency**: Unified approach to directory standards prevents future confusion
5. **Release Readiness**: All cleanup and fixes completed together for clean release state

### Implementation Order

Phases ordered by:
1. **Foundation First**: Test mode (Phase 0 COMPLETED) enables verification
2. **User Impact**: Error visibility and handler (Phase 1) before complex detection
3. **Dependencies**: Semantic filenames (Phase 2) before network detection (Phase 3)
4. **Verification**: Automatic fallback and tests (Phase 4) verify Phases 1-3
5. **Parallel Track**: Test infrastructure (Phases 5-6) can overlap with classification work
6. **Organization**: Directory cleanup (Phase 7) independent of code changes
7. **Documentation**: READMEs (Phase 8) and CLAUDE.md (Phase 9) document final state
8. **Final Verification**: Integration testing (Phase 10) validates complete system

### Related Specifications

- **Spec 700**: Coordinate error fixes (Phase 5 added network check, partial solution)
- **Spec 688**: Hybrid mode removal (created need for automatic fallback)
- **Spec 057**: Fail-fast policy analysis (verification fallback pattern)
- **Spec 620/630**: Bash block execution model (subprocess isolation, semantic filenames)
- **Spec 492**: Scripts consolidation (attempted elimination, learned directory purpose)
- **Spec 493**: Templates cleanup analysis (identified split template locations)
- **Spec 699**: Standards in coordinate command (organizational standards precedent)

### Completion Signal

Upon successful completion, this plan will have:
1. Fixed all LLM classification failures with automatic fallback
2. Achieved 100% test pass rate (110/110 suites)
3. Organized directory structure with clear standards
4. Comprehensive documentation preventing future confusion
5. Performance improvements (tests faster, offline classification faster)
6. Zero technical debt (no broken links, orphaned files, or misleading documentation)
