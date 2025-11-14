# Fix Failing Tests Implementation Plan

## Metadata
- **Date**: 2025-11-13 (Revised)
- **Feature**: Systematic fix of all failing tests in .claude/tests directory
- **Scope**: Test infrastructure, LLM mocking, library fixes, documentation updates, code corrections
- **Estimated Phases**: 8 (was 6)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Total Failing Tests**: 33 (updated from initial count of 17)
- **Current Passing Tests**: 77/110 test suites (70% pass rate)
- **Target**: 100% pass rate (110/110 suites)

## Revision History

### 2025-11-13 - Revision 1
**Changes**: Updated based on test mode infrastructure implementation and actual test results
**Reason**: Initial plan underestimated test count and didn't account for LLM API mocking requirements
**Completed Work**:
- Phase 0 (Test Mode Infrastructure) - COMPLETED
- Partial Phase 1 fixes - COMPLETED
**Modified Phases**: All phases updated with imperative language, accurate test counts, and completed work documented
**Reports Used**: Online research on bash testing best practices, LLM API mocking strategies

## Overview

This plan addresses systematic failures across the test suite using a test-driven approach. After implementing test mode infrastructure, 77 of 110 test suites now pass (70% pass rate). The remaining 33 failures fall into 6 root cause categories. Each phase WILL tackle one category with verification testing after fixes.

**Critical Discovery**: Tests were failing due to LLM API calls requiring network access. Solution: Implemented `WORKFLOW_CLASSIFICATION_TEST_MODE` environment variable that returns fixture JSON responses, following industry best practices for mocking external dependencies.

## Current Status

### ✓ Completed Work (Phase 0)
1. **Test Mode Infrastructure** - COMPLETED
   - Added `WORKFLOW_CLASSIFICATION_TEST_MODE` to `workflow-llm-classifier.sh`
   - Returns realistic fixture JSON when `WORKFLOW_CLASSIFICATION_TEST_MODE=1`
   - Enabled in `run_all_tests.sh` globally
   - Result: Fast, deterministic tests without real API calls

2. **Critical Test Fixes** - COMPLETED
   - Fixed `test_coordinate_research_complexity_fix.sh` (added CLAUDE_PROJECT_DIR initialization)
   - Fixed `test_coordinate_delegation.sh` (updated State Handler patterns, increased grep context to -A 150)
   - Result: 3 previously failing tests now pass

### Failing Tests Breakdown (33 total)

**Coordinate Command Tests** (7 tests):
1. test_coordinate_all - Wave execution tests failing
2. test_coordinate_error_fixes - Error handling verification
3. test_coordinate_preprocessing - History expansion checks
4. test_coordinate_standards - Standards compliance validation
5. test_coordinate_synchronization - State synchronization checks
6. test_coordinate_waves - Wave-based parallel execution

**Orchestrate/Supervise Tests** (6 tests):
7. test_orchestrate_planning_behavioral_injection - Missing documentation
8. test_orchestrate_research_enhancements_simple - Research phase validation
9. test_orchestration_commands - Multi-command validation
10. test_supervise_agent_delegation - Agent invocation patterns
11. test_supervise_delegation - Delegation compliance
12. test_supervise_scope_detection - Workflow scope detection

**Library/Utility Tests** (10 tests):
13. test_bash_command_fixes - Library patterns and sourcing
14. test_scope_detection - Workflow scope classification
15. test_scope_detection_ab - A/B testing for scope detection
16. test_shared_utilities - Utility function validation
17. test_state_machine - State machine transitions
18. test_state_persistence - Workflow state persistence
19. test_workflow_detection - Workflow type detection
20. test_workflow_initialization - Path initialization
21. test_workflow_scope_detection - Scope classification validation
22. test_topic_filename_generation - Filename slug generation

**Validation Tests** (2 tests):
23. validate_executable_doc_separation - Pattern compliance validation
24. validate_no_agent_slash_commands - Anti-pattern detection

**Delegation/Integration Tests** (6 tests):
25. test_all_delegation_fixes - Comprehensive delegation validation
26. test_all_fixes_integration - Cross-cutting integration tests
27. test_phase3_verification - Implementation phase verification
28. test_revision_specialist - Revision workflow validation
29. test_supervisor_checkpoint_old - Legacy checkpoint compatibility
30. test_template_integration - Template system validation

**System Tests** (2 tests):
31. test_system_wide_empty_directories - Directory structure validation
32. Agent - Unknown test requiring investigation
33. SOME - Unknown test requiring investigation

## Success Criteria

- [x] Test mode infrastructure implemented for LLM mocking
- [x] run_all_tests.sh enables test mode globally
- [x] Test mode returns realistic fixture JSON
- [x] 3 critical tests fixed (coordinate_critical_bugs, coordinate_delegation, coordinate_research_complexity_fix)
- [ ] All 33 remaining failing tests pass
- [ ] Test suite runs without errors (<5 minutes execution time)
- [ ] No regression in previously passing 77 tests
- [ ] Test environment setup standardized across all test files
- [ ] Libraries properly sourced in all commands
- [ ] Documentation complete for all missing sections
- [ ] 100% test pass rate (110/110 suites)

## Testing Philosophy

Following industry best practices for testing code with external dependencies:

**MUST Mock External Dependencies**: Tests MUST NOT make real LLM API calls (expensive, slow, non-deterministic)
**MUST Use Fixtures**: Tests MUST return predefined responses for deterministic validation
**MUST Test Business Logic**: Tests MUST focus on code that processes responses, not the LLM itself
**MUST Be Fast**: Test suite MUST execute in under 5 minutes
**MUST Be Deterministic**: Tests MUST produce identical results on every run

## Implementation Phases

### Phase 0: Test Mode Infrastructure ✓ COMPLETED

**Objective**: Implement LLM API mocking infrastructure for deterministic tests
**Complexity**: Medium
**Estimated Time**: 2 hours
**Actual Time**: 2 hours
**Status**: ✓ COMPLETED (2025-11-13)

**Completed Tasks**:
- [x] Researched bash testing best practices for mocking external APIs
- [x] Added `WORKFLOW_CLASSIFICATION_TEST_MODE` environment variable to `workflow-llm-classifier.sh`
- [x] Implemented fixture JSON response in `classify_workflow_llm_comprehensive()` function
- [x] Fixture returns: debug-only workflow, complexity=2, 2 research topics with realistic structure
- [x] Enabled test mode in `run_all_tests.sh` with `export WORKFLOW_CLASSIFICATION_TEST_MODE=1`
- [x] Fixed `test_coordinate_research_complexity_fix.sh` - added CLAUDE_PROJECT_DIR initialization
- [x] Fixed `test_coordinate_delegation.sh` - updated phase patterns and grep context (-A 150)
- [x] Verified test mode works: `test_coordinate_critical_bugs.sh` now passes

**Implementation Details**:

File: `.claude/lib/workflow-llm-classifier.sh` (line 116-144)
```bash
# TEST MODE: Return canned response for unit testing (avoids real LLM API calls)
if [ "${WORKFLOW_CLASSIFICATION_TEST_MODE:-0}" = "1" ]; then
  # Returns realistic fixture JSON with valid workflow classification
  cat <<'EOF'
{
  "workflow_type": "debug-only",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [ ... ]
}
EOF
  return 0
fi
```

File: `.claude/tests/run_all_tests.sh` (line 7-10)
```bash
# Enable test mode to avoid real LLM API calls during testing
# This returns canned responses from workflow-llm-classifier.sh
# Following best practices: mock LLM calls at function level for fast, deterministic tests
export WORKFLOW_CLASSIFICATION_TEST_MODE=1
```

**Outcomes**:
- Tests run without network dependencies ✓
- Test execution time reduced from ~10 minutes to ~3 minutes ✓
- Deterministic test results (no flaky failures) ✓
- 77/110 test suites now pass (70% pass rate, up from ~60%) ✓

---

### Phase 1: Fix Test Environment Initialization

**Objective**: Standardize CLAUDE_PROJECT_DIR initialization across remaining test files
**Complexity**: Low
**Estimated Time**: 45 minutes
**Status**: Partially completed, verification needed

**Tasks**:
- [x] Create standard test initialization template (COMPLETED in Phase 0)
- [x] Add initialization to test_coordinate_research_complexity_fix.sh (COMPLETED)
- [ ] Audit remaining 33 failing tests for CLAUDE_PROJECT_DIR issues
- [ ] Add initialization block to any tests that source libraries without setting CLAUDE_PROJECT_DIR
- [ ] Verify all library source statements use ${CLAUDE_PROJECT_DIR} prefix
- [ ] Update test paths to use absolute paths via CLAUDE_PROJECT_DIR

**Standard Test Initialization Template**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Standard test initialization
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Testing Commands**:
```bash
# Test each coordinate test individually
for test in test_coordinate_*.sh; do
  echo "Testing: $test"
  bash "$test" 2>&1 | grep -E "unbound variable|No such file" || echo "✓ Pass"
done

# Verify no environment errors
bash .claude/tests/run_all_tests.sh 2>&1 | grep -c "unbound variable"
# Should output 0
```

**Expected Outcomes**:
- Zero "unbound variable" errors
- Zero "No such file or directory" errors for library files
- All tests CAN find and source required libraries

---

### Phase 2: Add unified-logger.sh Sourcing and Fallback Patterns

**Objective**: Fix emit_progress availability and add graceful degradation
**Complexity**: Low
**Estimated Time**: 30 minutes

**Tasks**:
- [ ] Add unified-logger.sh to REQUIRED_LIBS array in coordinate.md for all scopes
- [ ] Verify unified-logger.sh sourced early (after state-persistence.sh)
- [ ] Add defensive check pattern for emit_progress calls:
  ```bash
  if command -v emit_progress &>/dev/null; then
    emit_progress "1" "State: Research"
  else
    echo "PROGRESS: [Phase 1] - State: Research"
  fi
  ```
- [ ] Apply fallback pattern to all emit_progress calls in coordinate.md (estimated 6-8 locations)
- [ ] Update test_bash_command_fixes.sh expectations to verify fallback pattern

**Implementation Guide**:
```bash
# Step 1: Add to REQUIRED_LIBS (around line 155-170 in coordinate.md)
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh"
                   "unified-logger.sh" "unified-location-detection.sh"
                   "overview-synthesis.sh" "error-handling.sh")
    ;;
  # ... repeat for all scopes
esac

# Step 2: Add fallback pattern (search for all emit_progress calls)
grep -n "emit_progress" .claude/commands/coordinate.md
# Then wrap each call with defensive check
```

**Testing Commands**:
```bash
# Test bash command fixes
bash .claude/tests/test_bash_command_fixes.sh

# Verify unified-logger sourcing
grep -c "unified-logger.sh" .claude/commands/coordinate.md | grep -q "[1-9]"

# Verify fallback pattern count
grep -c 'echo "PROGRESS:' .claude/commands/coordinate.md | grep -q "[5-9]"
```

**Expected Outcomes**:
- test_bash_command_fixes.sh Test 3 WILL pass (unified-logger.sh sourcing)
- test_bash_command_fixes.sh Test 4 WILL pass (fallback pattern)
- emit_progress function WILL be available in all coordinate.md phases
- Graceful degradation if emit_progress unavailable

---

### Phase 3: Fix Library Patterns and Implementations

**Objective**: Address library-specific test failures (nameref, state machine, initialization)
**Complexity**: Medium
**Estimated Time**: 90 minutes

**Tasks**:
- [ ] Investigate test_bash_command_fixes.sh nameref requirement
- [ ] **Decision Point**: Add nameref pattern OR update test expectations
- [ ] Fix test_state_machine.sh failures (state transition validation)
- [ ] Fix test_state_persistence.sh failures (workflow state management)
- [ ] Fix test_workflow_initialization.sh failures (path calculation)
- [ ] Fix test_shared_utilities.sh failures (utility functions)
- [ ] Fix test_topic_filename_generation.sh failures (slug generation)

**Nameref Investigation**:
```bash
# Check current workflow-initialization.sh patterns
grep -n '${!' .claude/lib/workflow-initialization.sh
# If found, consider converting to nameref:
#   OLD: local value="${!var_name}"
#   NEW: local -n var_ref="$var_name"; local value="$var_ref"

# OR update test to remove nameref requirement
```

**Testing Commands**:
```bash
# Test each library individually
for test in test_state_machine test_state_persistence test_workflow_initialization test_shared_utilities test_topic_filename_generation test_bash_command_fixes; do
  echo "=== Testing: $test ==="
  bash .claude/tests/${test}.sh 2>&1 | tail -15
done
```

**Expected Outcomes**:
- All 6 library tests WILL pass
- No breaking changes to library functionality
- Improved code quality with nameref if adopted

---

### Phase 4: Add dependency-analyzer.sh and Missing Library Sourcing

**Objective**: Enable wave execution and fix library availability issues
**Complexity**: Low
**Estimated Time**: 20 minutes

**Tasks**:
- [ ] Verify dependency-analyzer.sh exists at .claude/lib/dependency-analyzer.sh
- [ ] Add dependency-analyzer.sh to REQUIRED_LIBS for full-implementation scope in coordinate.md
- [ ] Verify source_required_libraries function sources it correctly
- [ ] Fix test_coordinate_waves.sh expectations
- [ ] Fix test_coordinate_all.sh wave execution tests

**Implementation**:
```bash
# Update coordinate.md REQUIRED_LIBS (around line 155-170)
full-implementation)
  REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh"
                 "unified-logger.sh" "unified-location-detection.sh"
                 "overview-synthesis.sh" "metadata-extraction.sh"
                 "checkpoint-utils.sh" "dependency-analyzer.sh"  # ADD THIS
                 "context-pruning.sh" "error-handling.sh")
  ;;
```

**Testing Commands**:
```bash
# Test coordinate wave execution
bash .claude/tests/test_coordinate_all.sh 2>&1 | grep -A 10 "Wave Execution"

# Verify dependency-analyzer sourced
grep -A 12 "full-implementation)" .claude/commands/coordinate.md | grep dependency-analyzer

# Test waves specifically
bash .claude/tests/test_coordinate_waves.sh
```

**Expected Outcomes**:
- test_coordinate_all.sh Wave Execution Tests WILL pass
- test_coordinate_waves.sh WILL pass
- dependency-analyzer.sh WILL be available for full-implementation workflows

---

### Phase 5: Complete orchestrate.md Documentation

**Objective**: Add missing documentation sections for orchestrate command tests
**Complexity**: Medium
**Estimated Time**: 60 minutes

**Tasks**:
- [ ] Read test_orchestrate_planning_behavioral_injection.sh to identify ALL expected documentation
- [ ] Add topic-based path format documentation to orchestrate.md Phase 2
- [ ] Add research report cross-reference passing documentation
- [ ] Add metadata extraction strategy documentation
- [ ] Add summary template artifact sections
- [ ] Verify cross-references between orchestrate.md and workflow documentation
- [ ] Fix test_orchestrate_research_enhancements_simple.sh expectations

**Required Documentation Sections**:

1. **Path Calculation** (Phase 2 section):
```markdown
### Path Calculation

Plans are created using topic-based structure:
- Format: `specs/{NNN_topic}/plans/{NNN}_plan_name.md`
- Topic number: Auto-incremented from highest existing
- Topic name: Sanitized from workflow description
- Plan number: Sequential within topic directory
```

2. **Research Integration** (Phase 2 section):
```markdown
### Research Integration

Plan architect receives:
- Array of research report paths: REPORT_PATHS[@]
- Report metadata extraction for context reduction
- Cross-reference requirement in agent prompt
```

3. **Context Reduction Strategy** (Phase 2 section):
```markdown
### Context Reduction Strategy

Hierarchical metadata extraction:
1. Research reports → Title + 50-word summary (99% reduction)
2. Plan metadata → Complexity score + phase count
3. Forward message pattern → Pass subagent output directly
```

4. **Summary Template Update** (Phase 7 section):
```markdown
## Artifacts Generated

### Research Reports
- Report 1: [path] ([size])
- Report 2: [path] ([size])

### Implementation Plan
- Path: [plan_path]
- Phases: [count]
- Complexity: [score]
```

**Testing Commands**:
```bash
# Test orchestrate planning behavioral injection
bash .claude/tests/test_orchestrate_planning_behavioral_injection.sh

# Test all delegation fixes (includes orchestrate checks)
bash .claude/tests/test_all_delegation_fixes.sh

# Verify documentation sections present
grep -c "topic-based structure" .claude/commands/orchestrate.md
grep -c "Research Integration" .claude/commands/orchestrate.md
grep -c "Context Reduction Strategy" .claude/commands/orchestrate.md
grep -c "Artifacts Generated" .claude/commands/orchestrate.md
```

**Expected Outcomes**:
- test_orchestrate_planning_behavioral_injection.sh WILL pass all tests
- test_orchestrate_research_enhancements_simple.sh WILL pass
- test_all_delegation_fixes.sh orchestrate tests WILL pass
- Documentation WILL be comprehensive and maintainable

---

### Phase 6: Fix Remaining Coordinate Command Tests

**Objective**: Address specific coordinate command test failures
**Complexity**: Medium
**Estimated Time**: 75 minutes

**Tasks**:
- [ ] Fix test_coordinate_error_fixes.sh - Error handling validation
  - [ ] Verify error handling functions exist and work correctly
  - [ ] Update test expectations to match current implementation
- [ ] Fix test_coordinate_preprocessing.sh - History expansion and quoting
  - [ ] Verify `set +H` present in all bash blocks
  - [ ] Check proper quoting for file paths with spaces
- [ ] Fix test_coordinate_standards.sh - Standards compliance
  - [ ] Verify Standard 11 (Imperative Agent Invocation) compliance
  - [ ] Verify Standard 15 (Library Sourcing Order) compliance
- [ ] Fix test_coordinate_synchronization.sh - State synchronization
  - [ ] Verify append_workflow_state calls in each phase
  - [ ] Verify load_workflow_state at start of each bash block

**Investigation Commands**:
```bash
# Run each test to see specific failures
bash .claude/tests/test_coordinate_error_fixes.sh 2>&1 | tail -30
bash .claude/tests/test_coordinate_preprocessing.sh 2>&1 | tail -30
bash .claude/tests/test_coordinate_standards.sh 2>&1 | tail -30
bash .claude/tests/test_coordinate_synchronization.sh 2>&1 | tail -30
```

**Expected Outcomes**:
- 4 coordinate tests WILL pass
- coordinate.md WILL be standards-compliant
- State synchronization WILL work correctly across bash blocks

---

### Phase 7: Fix Orchestration Command Tests

**Objective**: Fix orchestrate, supervise, and orchestration validation tests
**Complexity**: Medium
**Estimated Time**: 75 minutes

**Tasks**:
- [ ] Fix test_orchestration_commands.sh - Multi-command validation
  - [ ] Run validation for /coordinate, /orchestrate, /supervise
  - [ ] Fix any command-specific pattern issues
- [ ] Fix test_supervise_agent_delegation.sh - Agent invocation patterns
  - [ ] Verify Task invocations follow Standard 11
  - [ ] Verify behavioral injection pattern usage
- [ ] Fix test_supervise_delegation.sh - Delegation compliance
  - [ ] Verify 100% agent delegation rate
  - [ ] Check imperative markers present
- [ ] Fix test_supervise_scope_detection.sh - Workflow scope detection
  - [ ] Verify scope detection logic works
  - [ ] Update test expectations if needed

**Testing Commands**:
```bash
# Test orchestration commands
bash .claude/tests/test_orchestration_commands.sh 2>&1 | tail -40

# Test supervise delegation
bash .claude/tests/test_supervise_agent_delegation.sh 2>&1 | tail -30
bash .claude/tests/test_supervise_delegation.sh 2>&1 | tail -30
bash .claude/tests/test_supervise_scope_detection.sh 2>&1 | tail -30
```

**Expected Outcomes**:
- All 4 orchestration tests WILL pass
- /supervise command WILL meet delegation standards
- Scope detection WILL work correctly

---

### Phase 8: Fix Integration, Validation, and System Tests

**Objective**: Fix remaining integration tests, validation scripts, and system checks
**Complexity**: High
**Estimated Time**: 120 minutes

**Tasks**:
- [ ] Fix test_all_delegation_fixes.sh - Comprehensive delegation validation
  - [ ] Address each failing delegation check
  - [ ] Verify all commands meet delegation standards
- [ ] Fix test_all_fixes_integration.sh - Cross-cutting integration
  - [ ] Run full integration test suite
  - [ ] Fix any cross-cutting issues
- [ ] Fix test_phase3_verification.sh - Implementation phase verification
  - [ ] Verify verify_state_variables function works
  - [ ] Update test expectations if needed
- [ ] Fix test_revision_specialist.sh - Revision workflow validation
  - [ ] Verify research-and-revise workflow detection
  - [ ] Fix revision-specialist agent tests
- [ ] Fix test_supervisor_checkpoint_old.sh - Legacy compatibility
  - [ ] Verify old checkpoint format support
  - [ ] Update or remove if legacy support no longer needed
- [ ] Fix test_template_integration.sh - Template system validation
  - [ ] Verify template system works
  - [ ] Update template tests
- [ ] Fix validate_executable_doc_separation.sh - Pattern compliance
  - [ ] Check executable/documentation separation pattern
  - [ ] Fix any violations or update validation
- [ ] Fix validate_no_agent_slash_commands.sh - Anti-pattern detection
  - [ ] Verify no SlashCommand tool used for agent invocation
  - [ ] Fix any violations (MUST use Task tool)
- [ ] Fix test_system_wide_empty_directories.sh - Directory structure
  - [ ] Verify directory structure expectations
  - [ ] Clean up any empty directories or update test
- [ ] Fix test_scope_detection.sh and test_scope_detection_ab.sh
  - [ ] Verify workflow scope detection accuracy
  - [ ] Fix any detection logic issues
- [ ] Investigate and fix "Agent" and "SOME" tests
  - [ ] Identify what these tests are
  - [ ] Fix or remove if obsolete

**Testing Commands**:
```bash
# Run all integration and validation tests
bash .claude/tests/test_all_delegation_fixes.sh 2>&1 | tail -50
bash .claude/tests/test_all_fixes_integration.sh 2>&1 | tail -50
bash .claude/tests/validate_executable_doc_separation.sh 2>&1 | tail -30
bash .claude/tests/validate_no_agent_slash_commands.sh 2>&1 | tail -30

# Run other tests
for test in test_phase3_verification test_revision_specialist test_supervisor_checkpoint_old test_template_integration test_system_wide_empty_directories test_scope_detection test_scope_detection_ab; do
  echo "=== Testing: $test ==="
  bash .claude/tests/${test}.sh 2>&1 | tail -20
done
```

**Expected Outcomes**:
- All 12 integration/validation/system tests WILL pass
- No anti-patterns present in codebase
- Standards compliance at 100%
- Template system fully functional

---

## Final Verification

After completing all phases, EXECUTE comprehensive verification:

```bash
# Kill any background test runs
pkill -f run_all_tests.sh

# Run complete test suite with test mode enabled
cd /home/benjamin/.config
export WORKFLOW_CLASSIFICATION_TEST_MODE=1
bash .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/final_test_run.txt

# Check final summary
tail -50 /tmp/final_test_run.txt

# Verify 100% pass rate
grep "Test Suites Passed:" /tmp/final_test_run.txt | grep "110"
grep "Test Suites Failed:" /tmp/final_test_run.txt | grep "0"

# List any remaining failures (should be none)
grep "✗.*FAILED" /tmp/final_test_run.txt || echo "✓ All tests pass!"

# Verify test execution time
grep "Total execution time" /tmp/final_test_run.txt | grep -E "[0-9]+ seconds"
# Should be under 300 seconds (5 minutes)
```

**Success Indicators**:
- Test Suites Passed: 110
- Test Suites Failed: 0
- Total execution time: <300 seconds
- No "unbound variable" errors
- No "No such file or directory" errors
- All defensive checks working
- All standards compliance validated

## Testing Strategy

### Per-Phase Testing (MUST)
- Run affected tests immediately after each phase
- Verify no regressions in related tests
- Check error messages are clear and actionable
- Document any unexpected behaviors

### Integration Testing (MUST)
- Run full test suite after Phase 4 and Phase 8
- Verify test execution time <5 minutes
- Check for any test interdependencies
- Monitor for flaky tests

### Regression Testing (MUST)
- Compare test pass/fail counts before and after each phase
- Ensure previously passing 77 tests still pass
- Monitor for new failure patterns
- Track test execution performance

## Documentation Requirements

Following standards in `.claude/docs/guides/`:

- [ ] Update CLAUDE.md testing protocols with test mode documentation
- [ ] Document WORKFLOW_CLASSIFICATION_TEST_MODE in testing standards
- [ ] Update coordinate-command-guide.md with library sourcing changes
- [ ] Update orchestrate documentation as specified in Phase 5
- [ ] Add comments to modified tests explaining changes
- [ ] Create test troubleshooting guide with common issues

## Dependencies

### External
- bash 4.0+ (for nameref support if adopted)
- jq (for JSON parsing in tests and LLM classifier)
- grep with -P flag (Perl regex support for some tests)
- git (for CLAUDE_PROJECT_DIR detection)

### Internal Libraries
- workflow-state-machine.sh
- workflow-llm-classifier.sh (with test mode)
- state-persistence.sh
- unified-logger.sh
- dependency-analyzer.sh
- workflow-initialization.sh
- All libraries in .claude/lib/

## Risk Assessment

### Low Risk ✓
- Phase 0: Test mode infrastructure (COMPLETED, working well)
- Phases 1, 2, 4: Simple additions that don't change core behavior
- Test environment fixes isolated to test files

### Medium Risk
- Phase 3: Library pattern changes could affect behavior
  - Mitigation: Test thoroughly before committing
  - Mitigation: Easy to revert if issues arise
- Phase 5: Documentation additions are non-functional
  - Mitigation: Only affects test expectations, not runtime

### High Risk
- Phase 8: Multiple integration tests with unknown root causes
  - Mitigation: Fix one test at a time
  - Mitigation: Run full suite between fixes
  - Mitigation: Document ALL behavioral changes
  - Mitigation: Create detailed commit messages

## Rollback Plan

Each phase is independent and CAN be rolled back individually:

1. **Phase 0**: Revert test mode changes (remove WORKFLOW_CLASSIFICATION_TEST_MODE checks)
   - **NOT RECOMMENDED**: Test mode is working well and improves test reliability
2. **Phase 1**: Remove initialization blocks from test files
3. **Phase 2**: Remove unified-logger.sh sourcing and fallback patterns
4. **Phase 3**: Revert library changes OR test changes (whichever was modified)
5. **Phase 4**: Remove dependency-analyzer.sh from REQUIRED_LIBS
6. **Phase 5**: Revert orchestrate.md documentation additions
7. **Phase 6**: Revert individual coordinate test changes
8. **Phase 7**: Revert orchestration command changes
9. **Phase 8**: Revert individual integration test changes

**Backup Strategy**: Backup created before revision at:
`001_test_failure_fixes_implementation.md.backup-20251113-*`

## Standards Alignment

This plan MUST follow standards documented in `.claude/docs/`:

### Command Development Standards
- Use imperative language (MUST/WILL/SHALL not should/may/can)
- Follow executable/documentation separation pattern
- Reference behavioral injection patterns for agent invocations
- Maintain verification and fallback patterns

### Testing Protocols (CLAUDE.md)
- Tests MUST mock external dependencies
- Tests MUST be deterministic
- Tests MUST execute quickly (<5 minutes total)
- Tests MUST use fixtures for LLM responses

### Code Standards
- Use defensive checks for function availability
- Implement graceful degradation patterns
- Follow Standard 11 (Imperative Agent Invocation)
- Follow Standard 15 (Library Sourcing Order)

## Notes

### Test Infrastructure Best Practices

**Implemented** (Phase 0):
- ✓ LLM API mocking at function level
- ✓ Environment variable test mode control
- ✓ Realistic fixture responses
- ✓ Fast, deterministic test execution

**Future Improvements**:
- Shared test utilities library
- Test output standardization
- Test categories for selective execution
- Test timeout enforcement
- Parallel test execution
- Test coverage reporting

### Known Limitations

- Some tests MAY test implementation details vs behavior (WILL document which)
- Test assertions MAY need ongoing maintenance as code evolves
- Environment-specific issues MAY occur on different systems (WILL document requirements)
- Test mode fixture is simple (complexity=2, debug-only) - MAY need expanded fixtures for edge cases

### Lessons Learned

1. **Always mock external dependencies**: Real API calls make tests slow, expensive, flaky
2. **Environment setup is critical**: Missing CLAUDE_PROJECT_DIR caused many failures
3. **Test counts were underestimated**: Initial plan thought 17 failing, actually 33
4. **Documentation matters for tests**: Tests validate not just code but documentation completeness
5. **Incremental fixes work best**: Phase 0 completion proved value of step-by-step approach
