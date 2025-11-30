# Build Command Subagent Context Streamline - Implementation Plan

## Metadata
- **Date**: 2025-11-29 (Revised: 2025-11-29)
- **Feature**: Streamline /build command to delegate all substantial work to subagents
- **Scope**: Refactor /build to reduce primary agent context by 66% through comprehensive subagent delegation, fixing state persistence and standards compliance issues
- **Estimated Phases**: 5 (increased from 4)
- **Estimated Hours**: 22 (increased from 18)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 127.0
- **Research Reports**:
  - [Build Context Streamline Analysis](/home/benjamin/.config/.claude/specs/973_build_subagent_context_streamline/reports/001-build-context-streamline-analysis.md)
  - [Build Output Error Analysis](/home/benjamin/.config/.claude/specs/973_build_subagent_context_streamline/reports/002-build-output-error-analysis.md)

## Overview

The /build command currently consumes 30,000 tokens (15% of context window) in the primary agent due to substantial inline work including iteration management, test result parsing, conditional branching, and validation logic. This plan refactors the command to delegate all substantial work to specialized subagents, preserving primary agent context for coordination only.

**Goals**:
1. Reduce primary agent context consumption from 30,000 to ~10,000 tokens (66% reduction)
2. Achieve full hard barrier pattern compliance across all workflow phases
3. Consolidate command from 1,972 lines to ~1,532 lines (22% reduction)
4. Extract reusable iteration management, test parsing, and validation capabilities
5. Eliminate inline function definitions and complex logic from primary agent

## Research Summary

Analysis of build-output.md and build-output-2.md revealed critical errors and four major delegation opportunities:

**Critical Errors from build-output-2.md**:
1. **State Persistence Failures**: PLAN_FILE and TOPIC_PATH variables lost between bash blocks (empty in Block 2a), causing TEST_OUTPUT_PATH calculation failure
2. **Invalid State Transitions**: Attempted debug → document transition violating state machine (valid: debug → test or debug → complete)
3. **Defensive WARNING Patterns**: Code uses warnings instead of fail-fast validation (lines 1145-1149), allowing workflow to continue with empty variables

**Delegation Opportunities**:
1. **Iteration Management** (Block 1c, 357 lines): Primary agent performs context estimation, checkpoint saving, stuck detection, and iteration limit enforcement inline. Should be delegated to implementer-coordinator with built-in iteration management.

2. **Test Result Processing** (Block 2c, 343 lines): Primary agent parses test artifacts, executes fallback tests, and extracts metadata inline. Should be delegated to test-executor with comprehensive retry and recommendation logic.

3. **Conditional Branching** (Block 2c, 66 lines): Primary agent uses inline conditionals to determine debug vs document phase. Should leverage state machine with subagent-recommended transitions.

4. **Validation Logic** (Block 4, 48 lines): Primary agent validates predecessor states with case statements. Should delegate validation to state machine transition enforcement.

**Compliance Gaps Identified**:
- Hard barrier pattern only applied to 2 of 6 delegation opportunities
- Function definitions inline (estimate_context_usage, save_resumption_checkpoint) instead of in libraries/agents
- Primary agent acts as executor instead of pure orchestrator (violates hierarchical agent architecture)
- Conditionals inline instead of state-driven (violates state-based orchestration patterns)
- State restoration validation missing (validate_state_restoration not called in Block 2a)
- Duplicate state machine validation in primary agent (Block 4 lines 1753-1800)

**Recommended Approach**: Five-phase implementation adding Phase 0 for state signal enhancement before delegation changes, targeting state persistence fixes first (highest priority), then iteration management, test delegation, conditional consolidation, and validation delegation.

## Success Criteria

- [x] Primary agent context consumption reduced to ≤10,000 tokens (measured via token counting in build-output.md)
- [x] Hard barrier pattern enforced for all 6 delegation opportunities (iteration, test, debug, document, validation, completion)
- [x] Zero inline function definitions in build.md (all moved to agents or libraries)
- [x] Command file size reduced to ≤1,550 lines (22% reduction from 1,972 lines)
- [x] All integration tests pass (multi-iteration, test failure, debug phase, state transitions)
- [x] Backward compatibility maintained (existing plans and checkpoints work without modification)
- [x] Standards compliance: 100% hard barrier enforcement, full output formatting compliance, full hierarchical agent compliance

## Technical Design

### Architecture Changes

**Current Architecture**:
```
/build (Primary Agent)
├─ Block 1a: Setup (inline iteration variables)
├─ Block 1b: CRITICAL BARRIER → implementer-coordinator
├─ Block 1c: Verification (INLINE: context estimation, checkpoint saving, stuck detection)
├─ Block 1d: Phase update
├─ Block 2a: Test setup
├─ Block 2b: CRITICAL BARRIER → test-executor
├─ Block 2c: Test verification (INLINE: artifact parsing, conditional branching, phase setup)
└─ Block 4: Completion (INLINE: predecessor validation, summary generation)
```

**Target Architecture**:
```
/build (Primary Agent - Orchestrator Only)
├─ Block 1a: Setup (state initialization only)
├─ Block 1b: CRITICAL BARRIER → implementer-coordinator (with iteration management)
├─ Block 1c: Verification (SIMPLIFIED: trust subagent, no re-parsing)
├─ Block 1d: Phase update
├─ Block 2a: Test setup
├─ Block 2b: CRITICAL BARRIER → test-executor (with retry and next_state recommendation)
├─ Block 2c: Test verification (SIMPLIFIED: trust subagent, state-driven transition)
└─ Block 3: Completion (SIMPLIFIED: state machine enforces validation)
```

### Component Interactions

**Phase 1 - Iteration Management Flow**:
1. /build passes max_iterations, context_threshold to implementer-coordinator
2. Implementer-coordinator executes phases with built-in:
   - Context usage estimation after each phase
   - Checkpoint saving when context threshold exceeded
   - Stuck detection with 2-iteration tracking
   - Iteration limit enforcement
3. Implementer-coordinator returns: work_remaining, context_exhausted, context_usage_percent, checkpoint_path, requires_continuation
4. /build verifies summary exists, trusts requires_continuation signal

**Phase 2 - Test Result Flow**:
1. /build passes test_config (retry_on_failure: true, max_retries: 2) to test-executor
2. Test-executor executes tests with built-in:
   - Test framework detection and execution
   - Retry logic for flaky tests
   - Test result metadata extraction
   - Next state recommendation (DEBUG if failed, DOCUMENT if passed)
3. Test-executor returns: status, exit_code, tests_run, tests_passed, tests_failed, artifact_path, next_state
4. /build verifies artifact exists, transitions to recommended next_state

**Phase 3 - State-Driven Transitions**:
1. /build transitions to next_state recommended by test-executor (no inline conditionals)
2. If state = DEBUG: conditional invocation of debug-analyst subagent
3. If state = DOCUMENT: optional conditional invocation of doc-updater subagent
4. State machine enforces valid transitions automatically

**Phase 4 - Validation Enforcement**:
1. /build calls sm_transition("complete") without manual predecessor validation
2. State machine validates current state is valid predecessor (document or debug)
3. State machine returns error if invalid transition attempted
4. /build logs error and exits if transition rejected

### Data Structures

**Implementer-Coordinator Enhanced Return**:
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  summary_path: /path/to/summary
  work_remaining: 0|[list]
  context_exhausted: true|false
  context_usage_percent: N%
  checkpoint_path: /path/to/checkpoint (if created)
  requires_continuation: true|false
  stuck_detected: true|false (if 2 iterations with no progress)
```

**Test-Executor Enhanced Return**:
```yaml
TEST_COMPLETE:
  status: passed|failed|error
  framework: <detected>
  test_command: <executed>
  tests_run: N
  tests_passed: N
  tests_failed: N
  exit_code: N
  execution_time: <duration>
  artifact_path: /path/to/results.md
  next_state: DOCUMENT|DEBUG (recommendation)
  retry_count: N (if retry_on_failure enabled)
```

**State Machine Enhanced Validation**:
```bash
# Valid transitions enforced in sm_transition:
IMPLEMENT → TEST
TEST → DEBUG (if failures)
TEST → DOCUMENT (if passed)
DEBUG → TEST (retry after fix)
DEBUG → COMPLETE (accept failures)
DOCUMENT → COMPLETE
```

## Implementation Phases

### Phase 0: State Signal Enhancement and Validation Fixes [COMPLETE]
dependencies: []

**Objective**: Fix state persistence failures by enhancing subagent return signals to include all required state variables, and replace defensive WARNINGs with fail-fast validation.

**Complexity**: High

**Tasks**:
- [x] Enhance implementer-coordinator return signal to include plan_file and topic_path (file: .claude/agents/implementer-coordinator.md)
  - Add plan_file field to IMPLEMENTATION_COMPLETE signal
  - Add topic_path field to IMPLEMENTATION_COMPLETE signal
  - Document return signal format in agent behavioral guidelines
- [x] Update build.md Block 1c to parse state from subagent return instead of state file (file: .claude/commands/build.md, lines 486-843)
  - Parse PLAN_FILE from implementer-coordinator return signal
  - Parse TOPIC_PATH from implementer-coordinator return signal
  - Remove reliance on load_workflow_state for these variables
  - Persist parsed values via append_workflow_state for Block 2a
- [x] Replace defensive WARNINGs with fail-fast validation in Block 2a (file: .claude/commands/build.md, lines 1145-1149)
  - Replace WARNING pattern with validate_state_restoration call
  - Add PLAN_FILE, TOPIC_PATH to required variable list
  - Exit with error code 1 if validation fails
  - Add error logging via log_command_error
- [x] Add validate_state_restoration to Block 2a (file: .claude/commands/build.md, lines 929-941)
  - Call validate_state_restoration with PLAN_FILE, TOPIC_PATH, WORKFLOW_ID
  - Add fail-fast error handling if validation fails
- [x] Fix TEST_OUTPUT_PATH calculation to ensure absolute path (file: .claude/commands/build.md, line 1152)
  - Verify TOPIC_PATH is non-empty before calculation
  - Use absolute path construction: "${TOPIC_PATH}/outputs/test_results_*.md"
  - Add validation that TEST_OUTPUT_PATH starts with /

**Testing**:
```bash
# Test state persistence across bash blocks
bash .claude/tests/integration/test_build_state_persistence.sh

# Verify fail-fast validation triggers on missing variables
bash .claude/tests/integration/test_build_state_validation.sh

# Verify TEST_OUTPUT_PATH is absolute path
bash .claude/tests/integration/test_build_test_output_path.sh
```

**Expected Duration**: 4 hours

### Phase 1: Iteration Management Delegation [COMPLETE]
dependencies: [0]

**Objective**: Delegate iteration management from /build Block 1c to implementer-coordinator agent, eliminating inline context estimation, checkpoint saving, and stuck detection logic.

**Complexity**: High

**Tasks**:
- [x] Enhance implementer-coordinator.md with iteration management (file: .claude/agents/implementer-coordinator.md)
  - Add iteration_config parameter acceptance (max_iterations, context_threshold)
  - Implement estimate_context_usage() function (move from build.md Block 1c)
  - Implement save_resumption_checkpoint() function (move from build.md Block 1c)
  - Add stuck detection logic with 2-iteration tracking
  - Add iteration limit enforcement
  - Return requires_continuation, context_usage_percent, checkpoint_path
- [x] Simplify build.md Block 1c verification (file: .claude/commands/build.md, lines 486-843)
  - Remove estimate_context_usage function definition (357 lines → ~50 lines)
  - Remove save_resumption_checkpoint function definition
  - Remove context threshold check logic
  - Remove work remaining parsing logic
  - Remove stuck detection logic
  - Replace with simple verification: summary exists, trust requires_continuation
- [x] Update build.md Block 1b Task invocation (file: .claude/commands/build.md, lines 432-482)
  - Add max_iterations parameter to implementer-coordinator prompt
  - Add context_threshold parameter to implementer-coordinator prompt
  - Expect requires_continuation in subagent return signal
- [x] Update build.md continuation logic (file: .claude/commands/build.md, lines 817-837)
  - Replace inline next-iteration preparation with requires_continuation check
  - Trust subagent assessment, no re-parsing of work_remaining

**Testing**:
```bash
# Test multi-iteration plan with context exhaustion
bash .claude/tests/integration/test_build_iteration_delegation.sh

# Verify checkpoint resumption works with delegated iteration management
bash .claude/tests/integration/test_build_checkpoint_resume.sh

# Verify stuck detection triggers correctly
bash .claude/tests/integration/test_build_stuck_detection.sh
```

**Expected Duration**: 6 hours

### Phase 2: Test Result Delegation [COMPLETE]
dependencies: [1]

**Objective**: Delegate test result processing from /build Block 2c to test-executor agent, eliminating inline artifact parsing, fallback test execution, and conditional branching. Fix invalid state transitions by using test-executor recommendations.

**Complexity**: High

**Tasks**:
- [x] Enhance test-executor.md with comprehensive retry and recommendation logic (file: .claude/agents/test-executor.md)
  - Add test_config parameter acceptance (retry_on_failure, max_retries)
  - Implement internal retry logic for test failures (eliminate Block 2c inline fallback)
  - Add next_state recommendation based on test results (DEBUG if failed, DOCUMENT if passed)
  - Return all metadata in structured format (no inline parsing needed)
  - Return retry_count in metadata
  - Document valid state transitions from test: DEBUG (if failures) or DOCUMENT (if passed)
- [x] Simplify build.md Block 2c test verification (file: .claude/commands/build.md, lines 1220-1563)
  - Remove inline test artifact parsing (lines 1391-1443, ~53 lines)
  - Remove fallback test execution (lines 1350-1388, ~38 lines)
  - Remove inline conditional branching (lines 1474-1539, ~66 lines)
  - Replace with simple verification: artifact exists, trust next_state recommendation (343 lines → ~40 lines)
  - Add validation that next_state is valid transition from TEST state (DEBUG or DOCUMENT only)
- [x] Update build.md Block 2b Task invocation (file: .claude/commands/build.md, lines 1162-1215)
  - Add test_config parameter with retry_on_failure: true, max_retries: 2
  - Expect next_state in subagent return signal
  - Document expected next_state values in prompt to test-executor
- [x] Update build.md state transition logic (file: .claude/commands/build.md, lines 1474-1539)
  - Replace inline conditionals with single sm_transition to recommended next_state
  - Remove debug setup inline logic (43 lines)
  - Remove documentation setup inline logic (23 lines)
  - Add error handling for invalid next_state values
  - Log transition reason: "test-executor recommended $NEXT_STATE"

**Testing**:
```bash
# Test test-executor retry logic
bash .claude/tests/integration/test_build_test_retry.sh

# Verify next_state recommendation drives transitions correctly
bash .claude/tests/integration/test_build_state_recommendation.sh

# Verify debug phase invocation on test failure
bash .claude/tests/integration/test_build_debug_invocation.sh
```

**Expected Duration**: 6 hours

### Phase 3: Conditional Branching Consolidation [COMPLETE]
dependencies: [2]

**Objective**: Consolidate inline conditional branching into state-driven subagent invocations, eliminating inline debug/document phase setup logic. Add transition reason logging to diagnose invalid transitions.

**Complexity**: Medium

**Tasks**:
- [x] Add state-driven conditional invocations to build.md (file: .claude/commands/build.md)
  - After Block 2c, add conditional debug-analyst invocation if next_state = DEBUG
  - After Block 2c, add conditional doc-updater invocation if next_state = DOCUMENT
  - Remove inline debug directory setup (43 lines)
  - Remove inline documentation phase setup (23 lines)
- [x] Enhance state machine transition logging (file: .claude/lib/workflow/workflow-state-machine.sh)
  - Add optional transition_reason parameter to sm_transition function
  - Log transition reason: "Transitioning to $next_state (reason: $transition_reason)"
  - Include reason in error messages for invalid transitions
  - Document sm_transition signature change in function header
- [x] Update build.md Block 2c to use pure state-driven logic (file: .claude/commands/build.md, lines 1474-1539)
  - Replace if/else conditionals with single state transition
  - Pass transition reason to sm_transition: "test-executor recommendation"
  - Add checkpoint reporting for state transition
  - Trust state machine to enforce valid transitions
- [x] Update all sm_transition calls in build.md to include transition reasons
  - Document why each transition is occurring (e.g., "implementation complete", "tests passed", "accepting failures")
  - Improve audit trail for debugging invalid transition attempts

**Testing**:
```bash
# Verify debug-analyst invoked only when next_state = DEBUG
bash .claude/tests/integration/test_build_conditional_debug.sh

# Verify doc-updater invoked only when next_state = DOCUMENT
bash .claude/tests/integration/test_build_conditional_document.sh

# Verify state machine logs transition reasons
bash .claude/tests/integration/test_build_state_logging.sh
```

**Expected Duration**: 4 hours

### Phase 4: Validation Delegation [COMPLETE]
dependencies: [3]

**Objective**: Delegate predecessor state validation from /build Block 4 to state machine transition enforcement, eliminating duplicate inline case statement validation.

**Complexity**: Low

**Tasks**:
- [x] Verify state machine transition validation is comprehensive (file: .claude/lib/workflow/workflow-state-machine.sh)
  - Check that sm_transition() validates current state before transition
  - Verify transition table defines all valid state paths
  - Confirm debug state only allows transitions to test or complete (not document)
  - Document valid transition paths in function header
- [x] Simplify build.md Block 4 completion (file: .claude/commands/build.md, lines 1596-1946)
  - Remove duplicate predecessor state validation case statement (lines 1753-1800, ~48 lines)
  - Replace with single sm_transition("complete", "all phases successful") call
  - Trust state machine to reject invalid transitions (no duplicate validation)
  - Add error logging if transition fails
  - Document that state machine enforces validation automatically
- [x] Update state machine error messages (file: .claude/lib/workflow/workflow-state-machine.sh)
  - Include current state in error message
  - List valid predecessor states for attempted transition
  - Include transition reason (if provided) in error message
  - Add diagnostic guidance for invalid transition errors
- [x] Remove all duplicate validation logic from build.md
  - Search for other case statements validating state transitions
  - Replace with trust in state machine validation
  - Document single source of truth: workflow-state-machine.sh

**Testing**:
```bash
# Verify state machine rejects invalid transitions
bash .claude/tests/integration/test_build_invalid_transitions.sh

# Verify valid transitions (TEST→DEBUG, TEST→DOCUMENT, DEBUG→COMPLETE, DOCUMENT→COMPLETE) succeed
bash .claude/tests/integration/test_build_valid_transitions.sh

# Verify descriptive error messages on transition failures
bash .claude/tests/integration/test_build_transition_errors.sh
```

**Expected Duration**: 2 hours

### Phase 5: Context Estimation Defensive Handling [COMPLETE]
dependencies: [4]

**Objective**: Add defensive error handling to context estimation function to prevent failures when estimate_context_usage cannot calculate accurate token counts.

**Complexity**: Low

**Tasks**:
- [x] Review estimate_context_usage function for failure modes (file: .claude/commands/build.md or implementer-coordinator.md after Phase 1)
  - Identify scenarios where context estimation fails (missing files, empty responses, etc.)
  - Document current error handling (if any)
  - Determine impact of estimation failure on iteration management
- [x] Add defensive error handling to context estimation (file: location depends on Phase 1 delegation)
  - Wrap context calculation in error handling block
  - Return default/safe value if estimation fails (e.g., 50% context usage)
  - Log estimation failures via log_command_error with error_type: estimation_error
  - Add comment explaining defensive fallback strategy
- [x] Add retry logic for context estimation failures
  - Retry calculation once if initial attempt fails
  - Use alternate estimation method if available (e.g., file size approximation)
  - Document retry strategy in function header
- [x] Test context estimation failure scenarios
  - Test with missing summary files
  - Test with empty implementation output
  - Test with malformed agent responses
  - Verify workflow continues gracefully with default estimates

**Testing**:
```bash
# Test context estimation with missing files
bash .claude/tests/integration/test_build_context_estimation_failure.sh

# Test context estimation with malformed input
bash .claude/tests/integration/test_build_context_estimation_retry.sh

# Verify workflow continues with default estimates
bash .claude/tests/integration/test_build_context_estimation_fallback.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Test state signal parsing from implementer-coordinator return (Phase 0)
- Test validate_state_restoration fail-fast behavior (Phase 0)
- Test implementer-coordinator iteration management in isolation (Phase 1)
- Test test-executor retry and recommendation logic in isolation (Phase 2)
- Test state machine transition validation in isolation (Phase 4)
- Test context estimation defensive handling (Phase 5)
- Mock subagent responses to verify /build verification blocks handle all return signals

### Integration Testing
- Test /build with state persistence across bash blocks (Phase 0 validation)
- Test /build with missing state variables to verify fail-fast (Phase 0 validation)
- Test /build end-to-end with multi-iteration plan (Phase 1 validation)
- Test /build with test failures to verify debug phase invocation (Phase 2 validation)
- Test /build with test passes to verify document phase invocation (Phase 3 validation)
- Test /build with invalid state transitions to verify rejection (Phase 4 validation)
- Test /build with context estimation failures (Phase 5 validation)
- Test checkpoint resumption with delegated iteration management (Phase 1 validation)

### Regression Testing
- Verify existing plans execute successfully with refactored /build
- Verify checkpoint format backward compatibility
- Verify git commit creation unchanged
- Verify summary generation unchanged
- Verify all pre-commit hooks pass

### Performance Testing
- Measure primary agent context consumption before/after each phase (target: ≤10,000 tokens)
- Measure total execution time before/after (acceptable: ≤20% increase)
- Measure subagent context consumption (target: <30% of their context window)
- Verify total token efficiency (primary + subagents) improves or remains constant

### Test Execution Commands
```bash
# Run all integration tests
bash .claude/tests/integration/test_build_all.sh

# Run specific phase tests
bash .claude/tests/integration/test_build_state_persistence.sh         # Phase 0
bash .claude/tests/integration/test_build_state_validation.sh          # Phase 0
bash .claude/tests/integration/test_build_iteration_delegation.sh      # Phase 1
bash .claude/tests/integration/test_build_test_retry.sh                # Phase 2
bash .claude/tests/integration/test_build_conditional_debug.sh         # Phase 3
bash .claude/tests/integration/test_build_invalid_transitions.sh       # Phase 4
bash .claude/tests/integration/test_build_context_estimation_failure.sh # Phase 5

# Run regression suite
bash .claude/tests/regression/test_build_backward_compat.sh

# Run performance tests
bash .claude/tests/performance/test_build_context_usage.sh
```

## Documentation Requirements

### Files to Update
- [ ] .claude/docs/guides/commands/build-command-guide.md
  - Update architecture section with new delegation patterns
  - Document iteration management delegation
  - Document test result delegation
  - Document state-driven conditional invocations
  - Add troubleshooting section for subagent delegation failures
- [ ] .claude/agents/implementer-coordinator.md
  - Document iteration management parameters (max_iterations, context_threshold)
  - Document return format with iteration metadata
  - Add behavioral guidelines for context estimation and checkpoint saving
  - Add examples of iteration management in action
- [ ] .claude/agents/test-executor.md
  - Document test_config parameter (retry_on_failure, max_retries)
  - Document next_state recommendation logic
  - Document return format with retry metadata
  - Add behavioral guidelines for retry and recommendation
- [ ] .claude/lib/workflow/README.md
  - Document state machine transition validation
  - Document valid transition paths
  - Add examples of sm_validate_transition usage
- [ ] .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
  - Add /build as comprehensive example of hard barrier pattern
  - Document all 6 hard barriers in /build (iteration, test, debug, document, validation, completion)
  - Include before/after code snippets for each delegation opportunity

### New Documentation
- [ ] .claude/docs/guides/development/iteration-management-pattern.md
  - Document iteration management as reusable pattern
  - Explain context estimation, checkpoint saving, stuck detection
  - Provide examples for other commands to adopt pattern
- [ ] .claude/docs/guides/development/state-driven-conditionals.md
  - Document state-driven conditional invocation pattern
  - Explain subagent-recommended transitions
  - Provide examples for conditional agent invocations

## Dependencies

### External Dependencies
None (all changes internal to .claude/ system)

### Internal Dependencies
- implementer-coordinator.md agent file (enhancement target)
- test-executor.md agent file (enhancement target)
- workflow-state-machine.sh library (enhancement target)
- build.md command file (refactor target)

### Prerequisite Standards
- Hard Barrier Subagent Delegation Pattern (.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- Output Formatting Standards (.claude/docs/reference/standards/output-formatting.md)
- Hierarchical Agent Architecture (.claude/docs/concepts/hierarchical-agents-overview.md)
- State-Based Orchestration (.claude/docs/architecture/state-based-orchestration-overview.md)
- Error Logging Standards (.claude/docs/concepts/patterns/error-handling.md)

## Risk Management

### Technical Risks

**Risk: Increased subagent context consumption**
- Probability: Medium
- Impact: Medium
- Mitigation: Careful interface design, return metadata-only, avoid verbose instructions
- Acceptance: Monitor subagent context <30% of window, validate with token counting

**Risk: Subagent reliability issues**
- Probability: Low
- Impact: High
- Mitigation: Comprehensive testing, fail-fast error handling, descriptive error messages
- Acceptance: Maintain >95% subagent success rate in integration tests

**Risk: Checkpoint format breaking changes**
- Probability: Low
- Impact: High
- Mitigation: Maintain backward compatibility, test with existing checkpoints
- Acceptance: All existing checkpoints resume successfully with refactored /build

### Workflow Risks

**Risk: Breaking changes to /build UX**
- Probability: Low
- Impact: High
- Mitigation: Maintain backward compatibility for plan format, checkpoint format
- Acceptance: Existing users see no change in /build behavior

**Risk: Performance regression**
- Probability: Medium
- Impact: Medium
- Mitigation: Measure execution time before/after each phase, rollback if >20% increase
- Acceptance: Total execution time remains within 20% of baseline

### Rollback Strategy

**Trigger Conditions**:
- Primary agent context consumption increases (regression)
- Command execution time increases by >20%
- Test failure rate increases
- Subagent success rate drops below 95%

**Rollback Steps**:
1. Identify problematic phase (1, 2, 3, or 4)
2. Revert commit for that phase
3. Re-run integration test suite
4. Document issue for future resolution
5. Create follow-up spec to address root cause

**Phase Independence**: Each phase can be rolled back independently without affecting prior phases.

## Complexity Calculation

```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
Score = (24 × 1.0) + (6 × 5.0) + (22 × 0.5) + (4 × 2.0)
Score = 24 + 30 + 11 + 8
Score = 73.0
```

**Tier Selection**: Medium complexity (50-200) - Level 0 structure appropriate. If implementation complexity increases during execution, consider using `/expand` to create phase-specific detail files.

**Revision Notes**: Complexity increased from 51.0 to 73.0 due to addition of Phase 0 (state signal enhancement) and Phase 5 (defensive error handling), based on error analysis from build-output-2.md. Total phases increased from 4 to 6, tasks from 16 to 24, hours from 18 to 22.

## Notes

- This refactor achieves full hard barrier pattern compliance across all /build workflow phases
- Context reduction benefits compound: Primary agent becomes pure orchestrator with minimal context overhead
- Extracted iteration management and test retry logic become reusable patterns for other commands (/plan, /debug, /orchestrate)
- State-driven conditional invocations establish pattern for complex workflow branching in future commands
- Performance testing critical: Ensure context efficiency gains don't introduce execution time regression

**Revision History**:
- 2025-11-29 17:32: Added Phase 0 (State Signal Enhancement) and Phase 5 (Defensive Error Handling) based on error analysis from build-output-2.md
- Key findings from error analysis: state persistence failures, invalid state transitions (debug → document), defensive WARNING patterns
- Added second research report: 002-build-output-error-analysis.md
- Increased estimated hours from 18 to 22, phases from 4 to 6
- Enhanced Phase 2 with invalid transition fix documentation
- Enhanced Phase 3 with transition reason logging
- Enhanced Phase 4 to remove duplicate validation logic
