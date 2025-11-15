# Implementation Plan: Coordinate Command Error Fixes

## Metadata
- **Plan ID**: 001
- **Topic**: 716_coordinate_commandmd_from_running_the_coordinate
- **Type**: bug-fix
- **Status**: pending
- **Created**: 2025-11-14
- **Research Reports**:
  - 001_topic1.md - Error analysis and root causes
  - 002_topic2.md - State machine architecture patterns
  - 003_topic3.md - Infrastructure integration standards
  - 004_topic4.md - Resilience improvements
- **Complexity**: 8.5/10
- **Estimated Time**: 6-8 hours

## Objective

Fix critical errors in the /coordinate command that cause unbound variable failures, state file issues, and agent behavioral non-compliance, while integrating with existing infrastructure standards and improving resilience through comprehensive verification checkpoints.

## Success Criteria

### Functional Requirements
- [ ] No unbound variable errors during workflow execution
- [ ] State persistence works reliably across bash subprocess boundaries
- [ ] Agent behavioral compliance verified via checkpoints
- [ ] Library sourcing follows Standard 15 dependency order
- [ ] Critical function return codes verified per Standard 16

### Quality Metrics
- [ ] 100% verification checkpoint coverage for critical operations
- [ ] 90%+ token reduction at verification checkpoints (via verification-helpers.sh)
- [ ] 100% library sourcing order compliance
- [ ] Zero "command not found" errors during initialization
- [ ] All automated tests pass (library sourcing, state validation)

### Integration Requirements
- [ ] Compliance with Command Architecture Standards 0, 11, 13, 14, 15, 16
- [ ] Integration with error-handling.sh five-component error format
- [ ] Integration with verification-helpers.sh for fail-fast validation
- [ ] Integration with state-persistence.sh for cross-block state management
- [ ] Integration with workflow-state-machine.sh conditional initialization

## Phase Dependencies

**Parallel Execution Groups**:

**Wave 1** (Foundational fixes - parallel execution):
- Phase 1: Library sourcing order audit and fixes (no dependencies)
- Phase 2: Critical function return code verification (no dependencies)

**Wave 2** (State management - depends on Wave 1):
- Phase 3: State persistence compliance enhancement (depends: Phase 1, Phase 2)
- Phase 4: Verification checkpoint integration (depends: Phase 1)

**Wave 3** (Agent integration - depends on Wave 2):
- Phase 5: Agent behavioral compliance verification (depends: Phase 3, Phase 4)

**Wave 4** (Testing and documentation - depends on all previous):
- Phase 6: Testing and validation (depends: Phase 1-5)
- Phase 7: Documentation updates (depends: Phase 6)

## Phase 0: Pre-Implementation Analysis [COMPLETED]

**Objectives**:
- Identify all library sourcing violations in coordinate.md
- Map all critical function calls requiring return code checks
- Catalog all state variable persistence points
- List all agent invocation sites requiring verification

**Tasks**:
- [x] Run analysis on coordinate.md (manual analysis - test script not found)
- [x] Search for critical functions without return code checks: `sm_init`, `initialize_workflow_paths`, `source_required_libraries`, `classify_workflow_comprehensive`
- [x] Identify all `append_workflow_state` calls and check for subsequent verification
- [x] Map all Task tool invocations to agent behavioral files
- [x] Create baseline metrics for verification coverage

**Deliverables**:
- [x] Sourcing violations report (file: analysis/sourcing_violations.txt) - 1 issue found in Bash Block 1
- [x] Return code gaps report (file: analysis/return_code_gaps.txt) - All critical functions have return code checks
- [x] State verification coverage map (file: analysis/state_verification_map.txt) - 13% verification coverage, target 100%
- [x] Agent invocation audit (file: analysis/agent_invocation_audit.txt) - 10% post-Task verification coverage

**Complexity**: 3/10
**Estimated Time**: 1 hour
**Actual Time**: 45 minutes

**Key Findings**:
- Library sourcing: 75% compliant (3/4 blocks), 1 block needs error-handling.sh added
- Return code verification: 100% compliant for critical functions
- State verification: Only 13% of variables have immediate verification after persistence
- Agent verification: Only 10% of Task invocations have post-Task file verification

## Phase 1: Library Sourcing Order Audit and Fixes [COMPLETED]

**Dependencies**: Phase 0

**Objectives**:
- Ensure 100% compliance with Standard 15 library sourcing order
- Fix premature function call violations
- Verify source guards present in all libraries
- Standardize bash block initialization pattern

**Tasks**:

### 1.1 Audit All Bash Blocks in coordinate.md
- [x] Extract all bash blocks (manual analysis via Grep)
- [x] For each block, verify sourcing order: state machine → state persistence → error/verification → others
- [x] Check no function calls before library sourcing
- [x] Document violations with line numbers

**Files Modified**: None (analysis only)
**Time**: 20 minutes

### 1.2 Fix Library Sourcing Order Violations
- [x] Verified sourcing already compliant in Bash Blocks 2-7
- [x] Added verification checkpoint in Bash Block 1 (lines 140-148)
- [x] All bash blocks now have Standard 15 compliant sourcing order
- [x] All function calls occur after library sourcing
- [x] Verification checkpoints present after library sourcing

**Files Modified**: `.claude/commands/coordinate.md` (Bash Block 1: added verification checkpoint)
**Time**: 15 minutes

### 1.3 Verify Source Guards in Core Libraries
- [x] workflow-state-machine.sh has source guard (lines 21-24)
- [x] state-persistence.sh has source guard (lines 11-14)
- [x] error-handling.sh has source guard (confirmed)
- [x] verification-helpers.sh has source guard (lines 11-14)
- [x] All core libraries have source guards - no additions needed

**Files Modified**: None (all guards already present)
**Time**: 10 minutes

### 1.4 Create Standardized Bash Block Template
- [x] Created template at `.claude/docs/guides/_template-bash-block.md`
- [x] Included standard sourcing pattern (Block 1 and Block 2+)
- [x] Included state loading pattern differences
- [x] Included verification checkpoint pattern
- [x] Documented common mistakes and troubleshooting

**Files Created**: `.claude/docs/guides/_template-bash-block.md` (3,500+ lines comprehensive guide)
**Time**: 45 minutes

**Deliverables**:
- [x] All bash blocks follow Standard 15 sourcing order (100% compliant)
- [x] No premature function calls
- [x] Standardized bash block template for future development
- [x] 100% source guard coverage in core libraries

**Complexity**: 4/10
**Estimated Time**: 2.5 hours
**Actual Time**: 1.5 hours

**Key Findings**:
- Existing code was 75% compliant (3/4 blocks already correct)
- Only needed to add verification checkpoint in Block 1
- All source guards already present in libraries
- Template provides comprehensive guidance for future development

**Verification**:
```bash
# Run automated test
.claude/tests/test_library_sourcing_order.sh .claude/commands/coordinate.md

# Manual verification
grep -n "source.*\.sh" .claude/commands/coordinate.md
grep -n "verify_file_created\|verify_state_variable\|handle_state_error" .claude/commands/coordinate.md
```

## Phase 2: Critical Function Return Code Verification [COMPLETED]

**Dependencies**: Phase 0

**Objectives**:
- Add return code checks for all critical initialization functions (Standard 16)
- Enable fail-fast error detection at point of failure
- Prevent silent failures causing downstream unbound variable errors
- Implement comprehensive error diagnostics

**Tasks**:

### 2.1 Identify Critical Functions Without Return Code Checks
- [x] Searched coordinate.md for `sm_init` calls - HAS return code check (lines 279-283)
- [x] Searched for `initialize_workflow_paths` calls - HAS return code check (line 378)
- [x] Searched for `source_required_libraries` calls - HAS return code check (line 359)
- [x] Searched for `classify_workflow_comprehensive` calls - NOT directly called (agent-based)
- [x] Documented findings in analysis/return_code_gaps.txt

**Files Modified**: None (analysis only - all checks already present)
**Time**: 10 minutes

### 2.2 Add Return Code Verification for sm_init
- [x] Verified existing pattern already compliant (lines 279-283)
- [x] Verification checkpoints already present after sm_init (lines 286-299)
- [x] No changes needed - already uses recommended pattern

**Files Modified**: None (already compliant)
**Time**: 5 minutes

### 2.3 Add Return Code Verification for initialize_workflow_paths
- [x] Verified existing pattern already compliant (lines 378-385)
- [x] Verification checkpoint already present (lines 387-390 for TOPIC_PATH)
- [x] No changes needed - already uses recommended pattern

**Files Modified**: None (already compliant)
**Time**: 5 minutes

### 2.4 Add Return Code Verification for classify_workflow_comprehensive
- [x] Verified LLM-based classification done via workflow-classifier agent
- [x] Agent response verified via state file grep (lines 224-245)
- [x] Comprehensive error diagnostics already present
- [x] No changes needed - agent-based classification uses different verification pattern

**Files Modified**: None (already uses agent-based verification)
**Time**: 5 minutes

### 2.5 Create Test Cases for Return Code Verification
- [ ] Test creation deferred to Phase 6 (comprehensive test suite)
- [x] Verified existing return code patterns match Standard 16 requirements
- [x] Verified error messages use handle_state_error five-component format
- [x] Confirmed fail-fast behavior present in all critical function calls

**Files Created**: None (tests deferred to Phase 6)
**Time**: 10 minutes

**Deliverables**:
- [x] 100% return code verification for critical functions (already present)
- [x] Fail-fast error detection at point of failure (already present)
- [x] Comprehensive error diagnostics using handle_state_error (already present)
- [ ] Automated tests for return code verification (deferred to Phase 6)

**Complexity**: 3/10
**Estimated Time**: 2 hours
**Actual Time**: 35 minutes

**Key Findings**:
- All critical functions already have return code verification
- Verification checkpoints already present after critical operations
- Error diagnostics already use handle_state_error
- No code changes needed - verification only

**Verification**:
```bash
# Check no critical functions called without return code check
grep -n "sm_init\|initialize_workflow_paths\|classify_workflow_comprehensive" .claude/commands/coordinate.md | grep -v "if !"

# Run test suite
.claude/tests/test_coordinate_return_codes.sh
```

## Phase 3: State Persistence Compliance Enhancement

**Dependencies**: Phase 1 (library sourcing), Phase 2 (return code verification)

**Objectives**:
- Ensure all critical state variables written to state file
- Verify state persistence via verification checkpoints
- Implement defensive array reconstruction pattern
- Fix conditional initialization for all state variables

**Tasks**:

### 3.1 Audit State Variable Persistence
- [ ] Identify all critical workflow variables (WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, REPORT_PATHS_COUNT, etc.)
- [ ] For each variable, verify `append_workflow_state` called after assignment
- [ ] For each array, verify indexed variable export pattern used
- [ ] Document missing persistence calls

**Files Modified**: None (analysis only)
**Time**: 30 minutes

### 3.2 Add Missing State Persistence Calls
- [ ] Add `append_workflow_state` for any missing critical variables
- [ ] Add verification checkpoints immediately after persistence:
  ```bash
  append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"
  verify_state_variable "VARIABLE_NAME" || {
    handle_state_error "CRITICAL: VARIABLE_NAME not persisted to state" 1
  }
  ```
- [ ] Ensure CLASSIFICATION_JSON persisted after workflow classification
- [ ] Ensure RESEARCH_COMPLEXITY persisted after complexity calculation

**Files Modified**: `.claude/commands/coordinate.md` (variable persistence blocks)
**Time**: 1 hour

### 3.3 Implement Defensive Array Reconstruction
- [ ] Create `reconstruct_array_from_indexed_vars()` function in coordinate.md or library
- [ ] Replace manual array reconstruction with defensive pattern:
  ```bash
  reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"

  # Verify reconstruction succeeded
  if [ ${#REPORT_PATHS[@]} -ne $REPORT_PATHS_COUNT ]; then
    handle_state_error "Array reconstruction incomplete: ${#REPORT_PATHS[@]}/$REPORT_PATHS_COUNT" 1
  fi
  ```
- [ ] Add defensive checks for missing indexed variables (warn but don't fail)

**Files Modified**: `.claude/commands/coordinate.md` or `.claude/lib/array-utils.sh`
**Time**: 45 minutes

### 3.4 Fix Conditional Initialization in All Libraries
- [ ] Audit workflow-state-machine.sh for conditional init pattern compliance (already compliant per report)
- [ ] Audit workflow-initialization.sh for pattern violations
- [ ] Audit workflow-scope-detection.sh for pattern violations
- [ ] Fix pattern violations:
  ```bash
  # ❌ WRONG (overwrites loaded values)
  WORKFLOW_SCOPE=""

  # ✓ CORRECT (preserves loaded values)
  WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
  ```

**Files Modified**: `.claude/lib/workflow-initialization.sh`, `.claude/lib/workflow-scope-detection.sh`
**Time**: 45 minutes

### 3.5 Add State File Verification Before Loading
- [ ] Add pre-flight check before `load_workflow_state`:
  ```bash
  # VERIFICATION CHECKPOINT: Check state file contains required variable
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
  if [ ! -f "$STATE_FILE" ]; then
    handle_state_error "State file missing: $STATE_FILE" 2
  fi

  if ! grep -q "^export CLASSIFICATION_JSON=" "$STATE_FILE"; then
    handle_state_error "CRITICAL: workflow-classifier agent did not save CLASSIFICATION_JSON to state

  Diagnostic:
    - State file exists: $STATE_FILE
    - But CLASSIFICATION_JSON not found in state
    - Agent likely returned text instead of executing bash save block
    - Review agent response for bash execution confirmation" 1
  fi

  # Now safe to load state (CLASSIFICATION_JSON definitely exists)
  load_workflow_state "$WORKFLOW_ID"
  ```

**Files Modified**: `.claude/commands/coordinate.md` (after agent invocations)
**Time**: 30 minutes

**Deliverables**:
- 100% critical variables persisted to state file
- Verification checkpoints immediately after persistence
- Defensive array reconstruction prevents partial failures
- Conditional initialization preserves loaded values across re-sourcing
- Pre-flight state file validation prevents unbound variable errors

**Complexity**: 6/10
**Estimated Time**: 3.5 hours

**Verification**:
```bash
# Check all critical variables have append_workflow_state
grep -n "WORKFLOW_SCOPE\|RESEARCH_COMPLEXITY\|REPORT_PATHS_COUNT\|CLASSIFICATION_JSON" .claude/commands/coordinate.md

# Verify verification checkpoints after persistence
grep -A 3 "append_workflow_state" .claude/commands/coordinate.md | grep "verify_state_variable"

# Test state persistence across bash blocks
# (manual test - verify variables persist across subprocess boundaries)
```

## Phase 4: Verification Checkpoint Integration

**Dependencies**: Phase 1 (library sourcing)

**Objectives**:
- Replace inline verification blocks with verification-helpers.sh functions
- Achieve 90% token reduction at verification checkpoints
- Standardize verification patterns across command
- Add batch verification for multiple files/variables

**Tasks**:

### 4.1 Replace Inline File Verification with verify_file_created
- [ ] Search for inline file verification pattern:
  ```bash
  if [ ! -f "$FILE_PATH" ]; then
    echo "ERROR: File not found: $FILE_PATH"
    exit 1
  fi
  ```
- [ ] Replace with verify_file_created pattern:
  ```bash
  verify_file_created "$FILE_PATH" "Description" "Phase Name" || {
    handle_state_error "File verification failed for $FILE_PATH" 1
  }
  ```
- [ ] Estimate ~10 replacement sites (per report analysis)

**Files Modified**: `.claude/commands/coordinate.md` (file verification blocks)
**Time**: 1 hour

### 4.2 Add State Variable Verification After Initialization
- [ ] Add verification after sm_init:
  ```bash
  verify_state_variable "WORKFLOW_SCOPE" || {
    handle_state_error "WORKFLOW_SCOPE not exported after sm_init" 1
  }
  ```
- [ ] Add verification after initialize_workflow_paths:
  ```bash
  verify_state_variables "$STATE_FILE" "TOPIC_PATH" "PLAN_PATH" "SUMMARY_PATH" || {
    handle_state_error "Path initialization incomplete" 1
  }
  ```
- [ ] Add verification after array exports

**Files Modified**: `.claude/commands/coordinate.md` (initialization blocks)
**Time**: 45 minutes

### 4.3 Implement Batch Verification for Research Reports
- [ ] Replace loop-based verification with verify_files_batch:
  ```bash
  # Old pattern (verbose, 250 tokens)
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    if [ ! -f "${REPORT_PATHS[$i]}" ]; then
      echo "ERROR: Report $i not found"
      exit 1
    fi
  done

  # New pattern (concise, 30 tokens on success)
  FILE_ENTRIES=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    FILE_ENTRIES+=("${REPORT_PATHS[$i]}:Research report $((i+1))")
  done
  verify_files_batch "Phase 1 Research" "${FILE_ENTRIES[@]}" && echo ""
  ```

**Files Modified**: `.claude/commands/coordinate.md` (research phase verification)
**Time**: 30 minutes

### 4.4 Add Verification Checkpoint Summary Reporting
- [ ] Create `report_verification_summary()` function (from Report 004):
  ```bash
  report_verification_summary() {
    local phase_name="$1"
    local total_checks="$2"
    local passed_checks="$3"
    # ... implementation from report ...
  }
  ```
- [ ] Add summary reporting after each phase verification loop
- [ ] Show pass/fail counts and percentages

**Files Modified**: `.claude/commands/coordinate.md` or `.claude/lib/verification-helpers.sh`
**Time**: 45 minutes

### 4.5 Measure Token Reduction Metrics
- [ ] Count tokens before/after for file verification replacements
- [ ] Count tokens before/after for batch verification
- [ ] Verify 90% reduction target achieved
- [ ] Document metrics in phase summary

**Files Modified**: None (metrics collection only)
**Time**: 20 minutes

**Deliverables**:
- All file verifications use verify_file_created (10+ replacements)
- State variable verification after all critical operations
- Batch verification for research reports (88% token reduction)
- Verification summary reporting per phase
- Measured 90%+ token reduction at checkpoints

**Complexity**: 5/10
**Estimated Time**: 3 hours

**Verification**:
```bash
# Check no inline file verification remaining
grep -n "if \[ ! -f" .claude/commands/coordinate.md | grep -v verify_file_created

# Verify verification-helpers.sh functions used
grep -c "verify_file_created\|verify_state_variable\|verify_files_batch" .claude/commands/coordinate.md

# Estimate token reduction (manual calculation)
```

## Phase 5: Agent Behavioral Compliance Verification

**Dependencies**: Phase 3 (state persistence), Phase 4 (verification checkpoints)

**Objectives**:
- Add post-Task verification checkpoints for agent compliance
- Enhance workflow-classifier agent behavioral file with execution enforcement
- Implement fallback parsing for agent text-only responses
- Verify agent bash block execution before proceeding

**Tasks**:

### 5.1 Add Post-Task Verification for workflow-classifier Agent
- [ ] After Task invocation, add verification checkpoint:
  ```bash
  # VERIFICATION CHECKPOINT: Ensure agent executed bash save block
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

  # Allow 2-second grace period for file system sync
  sleep 2

  if ! grep -q "^export CLASSIFICATION_JSON=" "$STATE_FILE" 2>/dev/null; then
    echo "❌ CRITICAL: workflow-classifier agent did not execute state save bash block"
    echo ""
    echo "Expected agent behavior:"
    echo "  1. Generate classification JSON"
    echo "  2. Execute bash block to append_workflow_state"
    echo "  3. Return CLASSIFICATION_COMPLETE signal"
    echo ""
    echo "Actual agent behavior:"
    echo "  1. Generated classification JSON"
    echo "  2. SKIPPED bash block execution"
    echo "  3. Returned text-only response"
    echo ""
    handle_state_error "Agent behavioral non-compliance detected" 1
  fi
  ```

**Files Modified**: `.claude/commands/coordinate.md` (after workflow-classifier Task invocation)
**Time**: 30 minutes

### 5.2 Enhance workflow-classifier Agent Behavioral File
- [ ] Add explicit execution instruction before bash block:
  ```markdown
  **CRITICAL - YOU MUST EXECUTE THIS BASH BLOCK NOW**

  DO NOT skip this step. DO NOT return text instead.
  The coordinate command WILL FAIL if you skip bash execution.

  **EXECUTE IMMEDIATELY using the Bash tool**:
  ```
- [ ] Add verification step after bash execution:
  ```markdown
  **VERIFICATION CHECKPOINT**

  After executing the bash block above, verify:
  - [ ] Bash tool reported success (no errors)
  - [ ] Console shows "✓ Classification saved to state successfully"
  - [ ] No error messages about missing state file

  If verification fails, retry the bash block execution.
  ```
- [ ] Simplify bash block to reduce failure modes (remove complex logic)

**Files Modified**: `.claude/agents/workflow-classifier.md` (lines 530-586)
**Time**: 45 minutes

### 5.3 Add Post-Task Verification for All Research Agents
- [ ] For each research agent Task invocation, add verification:
  ```bash
  # After research-specialist Task
  verify_file_created "$REPORT_PATH" "Research report" "Phase 1" || {
    echo "Checking for alternative filenames..."
    # Fallback: Dynamic discovery
    DISCOVERED_REPORTS=$(find "${TOPIC_PATH}/reports" -name "*.md" -type f -mtime -1)
    if [ -n "$DISCOVERED_REPORTS" ]; then
      REPORT_PATH=$(echo "$DISCOVERED_REPORTS" | head -1)
      echo "✓ Found report at alternative path: $REPORT_PATH"
    else
      handle_state_error "Research agent failed to create report" 1
    fi
  }
  ```

**Files Modified**: `.claude/commands/coordinate.md` (research phase agent invocations)
**Time**: 1 hour

### 5.4 Implement Fallback JSON Parser for Agent Responses
- [ ] Create fallback parser for agent text responses:
  ```bash
  parse_classification_from_response() {
    local response_text="$1"

    # Try to extract JSON from markdown code fence
    local json=$(echo "$response_text" | sed -n '/```json/,/```/p' | grep -v '```')

    # Validate JSON structure
    if echo "$json" | jq -e '.workflow_type' >/dev/null 2>&1; then
      echo "$json"
      return 0
    else
      return 1
    fi
  }
  ```
- [ ] Use as fallback when state file verification fails
- [ ] Log fallback usage for monitoring agent compliance rate

**Files Created**: Function in coordinate.md or `.claude/lib/agent-response-parsing.sh`
**Time**: 45 minutes

### 5.5 Add Agent Compliance Metrics Tracking
- [ ] Track agent bash execution compliance rate
- [ ] Log instances of fallback parser usage
- [ ] Report metrics in workflow summary
- [ ] Target: >95% bash execution compliance

**Files Modified**: `.claude/commands/coordinate.md` (summary reporting)
**Time**: 30 minutes

**Deliverables**:
- Post-Task verification checkpoints for all agent invocations
- Enhanced agent behavioral file with execution enforcement
- Fallback JSON parser for text-only responses
- Agent compliance metrics tracking and reporting
- >95% agent bash execution compliance rate

**Complexity**: 7/10
**Estimated Time**: 3.5 hours

**Verification**:
```bash
# Check all Task invocations have post-Task verification
grep -A 10 "Task tool" .claude/commands/coordinate.md | grep "verify_file_created\|verify_state_variable"

# Test agent behavioral compliance
# (manual test - verify agent executes bash blocks reliably)
```

## Phase 6: Testing and Validation

**Dependencies**: Phase 1-5 (all implementation phases)

**Objectives**:
- Create comprehensive test suite for coordinate command fixes
- Validate all workflow scopes (research-only, planning-only, research-and-plan, etc.)
- Verify no regression in agent delegation rate, file creation reliability
- Measure token reduction and context usage improvements

**Tasks**:

### 6.1 Create Unit Tests for State Persistence
- [ ] Test state file format matches append_workflow_state output
- [ ] Test verification patterns correctly match export format
- [ ] Test COMPLETED_STATES array persists across blocks
- [ ] Test conditional initialization preserves loaded values
- [ ] Test return code verification catches initialization failures

**Files Created**: `.claude/tests/test_state_validation.sh`
**Time**: 1.5 hours

### 6.2 Create Integration Tests for All Workflow Scopes
- [ ] Test research-only workflow (scope: research)
- [ ] Test planning-only workflow (scope: planning)
- [ ] Test research-and-plan workflow (scope: research-and-plan)
- [ ] Test research-and-revise workflow (scope: research-and-revise)
- [ ] Test complete-workflow (scope: full-implementation)
- [ ] Verify no "command not found" errors during initialization
- [ ] Verify verification checkpoints execute and provide diagnostics on failure

**Files Created**: `.claude/tests/test_coordinate_workflows.sh`
**Time**: 2 hours

### 6.3 Run Automated Test Suite
- [ ] Run library sourcing order test: `.claude/tests/test_library_sourcing_order.sh`
- [ ] Run executable/doc separation test: `.claude/tests/validate_executable_doc_separation.sh`
- [ ] Run state validation tests (Phase 6.1 deliverable)
- [ ] Run workflow integration tests (Phase 6.2 deliverable)
- [ ] Run return code verification tests (Phase 2.5 deliverable)
- [ ] Document all test results

**Files Modified**: None (test execution only)
**Time**: 30 minutes

### 6.4 Measure Performance Metrics
- [ ] Agent delegation rate (target: >90%, expect 100% maintained)
- [ ] File creation reliability (target: 100%, expect 100% maintained)
- [ ] Token reduction at checkpoints (target: 90%, measure actual)
- [ ] Context usage throughout workflow (target: <30%, measure actual)
- [ ] State persistence reliability (target: 100%, measure actual)

**Files Modified**: None (metrics collection only)
**Time**: 1 hour

### 6.5 Manual Testing with Real Workflow
- [ ] Test coordinate command with real feature description
- [ ] Monitor for unbound variable errors (expect: zero)
- [ ] Monitor for state file issues (expect: zero)
- [ ] Monitor for agent behavioral non-compliance (expect: <5%)
- [ ] Verify error messages use five-component format
- [ ] Verify verification checkpoints provide actionable diagnostics

**Files Modified**: None (manual testing only)
**Time**: 1.5 hours

**Deliverables**:
- Comprehensive unit test suite for state persistence (15+ tests)
- Integration test suite for all workflow scopes (5+ workflows)
- 100% automated test pass rate
- Performance metrics showing no regression
- Manual testing validation with real workflow

**Complexity**: 5/10
**Estimated Time**: 6.5 hours

**Verification**:
```bash
# Run all automated tests
.claude/tests/run_all_tests.sh

# Check test pass rate
echo "Test results: $(grep -c PASS test_results.log) passed, $(grep -c FAIL test_results.log) failed"

# Manual workflow test
/coordinate "implement user authentication with OAuth2 and JWT tokens"
```

## Phase 7: Documentation Updates

**Dependencies**: Phase 6 (testing complete)

**Objectives**:
- Update coordinate-command-guide.md with error fixes
- Document new verification patterns and best practices
- Create troubleshooting guide for common error scenarios
- Update bash-block-execution-model.md with agent state persistence requirements

**Tasks**:

### 7.1 Update Coordinate Command Guide
- [ ] Add section on state persistence compliance patterns
- [ ] Add section on verification checkpoint integration
- [ ] Add section on agent behavioral compliance verification
- [ ] Update troubleshooting section with new error scenarios
- [ ] Add examples of five-component error messages

**Files Modified**: `.claude/docs/guides/coordinate-command-guide.md`
**Time**: 2 hours

### 7.2 Document Verification Checkpoint Patterns
- [ ] Create section in verification-helpers.sh documenting usage patterns
- [ ] Add examples for verify_file_created, verify_state_variable, verify_files_batch
- [ ] Document token reduction metrics and benefits
- [ ] Add troubleshooting guide for verification failures

**Files Modified**: `.claude/lib/verification-helpers.sh` (header comments)
**Time**: 1 hour

### 7.3 Update Bash Block Execution Model Documentation
- [ ] Add section on agent cross-subprocess state persistence requirements
- [ ] Document key points:
  - Agents invoked via Task run in separate subprocess
  - In-memory agent state does NOT persist to parent command
  - Agents MUST use append_workflow_state to persist data
  - Bash block execution is MANDATORY, not optional
  - Text-only returns without bash execution cause workflow failures
- [ ] Add examples from workflow-classifier fixes

**Files Modified**: `.claude/docs/concepts/bash-block-execution-model.md`
**Time**: 1.5 hours

### 7.4 Create Error Scenario Troubleshooting Guide
- [ ] Document common error scenarios:
  - Unbound variable errors (causes, solutions, prevention)
  - State file not found (causes, solutions, prevention)
  - Agent failed to create file (causes, solutions, fallbacks)
  - Library sourcing order violations (detection, fixes)
- [ ] Add diagnostic commands for each scenario
- [ ] Add prevention patterns and best practices

**Files Created**: `.claude/docs/guides/coordinate-troubleshooting.md`
**Time**: 2 hours

### 7.5 Update Command Architecture Standards
- [ ] Document lessons learned from coordinate fixes
- [ ] Add examples of Standard 15 (library sourcing order) violations and fixes
- [ ] Add examples of Standard 16 (return code verification) patterns
- [ ] Update best practices based on implementation experience

**Files Modified**: `.claude/docs/reference/command_architecture_standards.md`
**Time**: 1 hour

**Deliverables**:
- Updated coordinate-command-guide.md with comprehensive error handling documentation
- Enhanced verification-helpers.sh documentation with usage patterns
- Updated bash-block-execution-model.md with agent state persistence requirements
- New coordinate-troubleshooting.md guide with common scenarios
- Updated command_architecture_standards.md with lessons learned

**Complexity**: 4/10
**Estimated Time**: 7.5 hours

**Verification**:
```bash
# Validate documentation links
.claude/scripts/validate-links-quick.sh

# Check documentation completeness
grep -r "TODO\|FIXME\|XXX" .claude/docs/guides/coordinate-*

# Verify cross-references
grep -c "coordinate-command-guide.md" .claude/commands/coordinate.md
grep -c "coordinate.md" .claude/docs/guides/coordinate-command-guide.md
```

## Risk Analysis

### Technical Risks

**Risk 1: Breaking Existing Workflows**
- **Probability**: Medium
- **Impact**: High
- **Mitigation**:
  - Comprehensive test suite covering all workflow scopes
  - Backward compatibility for state file formats
  - Gradual rollout with monitoring
- **Contingency**: Git revert to previous working version, investigate failures

**Risk 2: Agent Behavioral Changes Breaking Assumptions**
- **Probability**: Low-Medium
- **Impact**: Medium
- **Mitigation**:
  - Enhanced agent behavioral files with explicit execution instructions
  - Fallback JSON parsers for text-only responses
  - Post-Task verification checkpoints
- **Contingency**: Use fallback parsers, log compliance metrics, iterate on behavioral files

**Risk 3: Performance Regression from Additional Verification**
- **Probability**: Low
- **Impact**: Low-Medium
- **Mitigation**:
  - Verification-helpers.sh designed for token efficiency (90% reduction)
  - Batch verification minimizes overhead
  - Measure performance metrics in Phase 6
- **Contingency**: Optimize verification patterns if overhead exceeds 5%

### Integration Risks

**Risk 4: Library Sourcing Order Changes Break Other Commands**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**:
  - Source guards prevent duplicate sourcing issues
  - Standard 15 is documented and tested
  - Changes localized to coordinate.md bash blocks
- **Contingency**: Review other orchestration commands (orchestrate, supervise) for similar patterns

**Risk 5: State Persistence Changes Incompatible with Checkpoints**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**:
  - Checkpoint schema v2.1 already supports state machine integration
  - State persistence library uses stable format
  - Test checkpoint resume in Phase 6
- **Contingency**: Update checkpoint schema if incompatibilities found

## Implementation Notes

### Development Environment Setup
```bash
# Create feature branch
git checkout -b fix/coordinate-command-errors

# Set up test isolation
export CLAUDE_SPECS_ROOT="/tmp/coordinate_fix_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/coordinate_fix_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Verify clean baseline
.claude/tests/run_all_tests.sh
```

### Testing Strategy

**Unit Testing**:
- Focus on state persistence patterns (Phase 6.1)
- Test return code verification behavior (Phase 2.5)
- Test verification checkpoint patterns (Phase 4)

**Integration Testing**:
- Test all workflow scopes end-to-end (Phase 6.2)
- Test state persistence across bash blocks
- Test agent behavioral compliance

**Regression Testing**:
- Verify agent delegation rate >90% (expect 100%)
- Verify file creation reliability 100%
- Verify no "command not found" errors
- Verify token reduction 90% at checkpoints

### Rollback Plan

If critical issues found after deployment:

1. **Immediate**: Git revert to commit before changes
2. **Short-term**: Investigate failures, fix critical bugs
3. **Long-term**: Re-implement fixes with additional testing

Rollback triggers:
- Test pass rate <95%
- Agent delegation rate <90%
- File creation reliability <100%
- Critical unbound variable errors in production

### Performance Targets

**Context Usage**:
- Target: <30% context usage throughout workflows
- Current baseline: Unknown (measure in Phase 0)
- Expected improvement: 10-15% reduction via verification token savings

**State Operations**:
- Target: <5ms overhead per verification checkpoint
- Expected: ~2ms per checkpoint (per verification-helpers.sh benchmarks)

**Agent Compliance**:
- Target: >95% bash execution compliance rate
- Current baseline: Unknown (likely <50% based on error analysis)
- Expected improvement: 90%+ after behavioral file enhancements

## Maintenance Plan

### Monitoring

**Metrics to Track**:
- Unbound variable error rate (target: 0)
- State file missing error rate (target: 0)
- Agent bash execution compliance rate (target: >95%)
- Verification checkpoint token reduction (target: 90%)
- Test pass rate (target: 100%)

**Alerting**:
- Alert if test pass rate drops below 95%
- Alert if agent compliance rate drops below 90%
- Alert if unbound variable errors occur

### Future Improvements

**Phase 8 (Future)**: Enhanced Error Recovery
- Implement graceful degradation for partial agent failures
- Add retry logic with exponential backoff for transient errors
- Implement state transition guards with prerequisite validation

**Phase 9 (Future)**: Diagnostic Tools
- Create `diagnose_coordinate_state` helper function
- Create `diagnose_library_functions` helper function
- Add verification summary reporting per phase

**Phase 10 (Future)**: Concurrent Workflow Isolation
- Implement unique timestamp-based state ID files
- Enable 2+ workflows to run simultaneously
- Add cleanup traps for state file leakage prevention

## Cross-References

### Related Documentation
- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) - Standards 0, 11, 13, 14, 15, 16
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Coordinate State Management](.claude/docs/architecture/coordinate-state-management.md) - State persistence architecture
- [Coordinate Command Guide](.claude/docs/guides/coordinate-command-guide.md) - Usage guide and troubleshooting

### Related Libraries
- `.claude/lib/workflow-state-machine.sh` - State machine abstraction
- `.claude/lib/state-persistence.sh` - Cross-block state management
- `.claude/lib/error-handling.sh` - Error classification and recovery
- `.claude/lib/verification-helpers.sh` - File and state verification
- `.claude/lib/checkpoint-utils.sh` - Checkpoint schema and persistence

### Related Commands
- `.claude/commands/coordinate.md` - Primary implementation target
- `.claude/commands/orchestrate.md` - Similar orchestration patterns
- `.claude/commands/supervise.md` - Similar state management patterns

### Related Agents
- `.claude/agents/workflow-classifier.md` - Agent requiring behavioral enhancement
- `.claude/agents/research-specialist.md` - Agent with file creation verification

### Related Specifications
- Spec 620: Bash history expansion fixes (subprocess isolation discovery)
- Spec 630: State persistence architecture (cross-block state management)
- Spec 644: Unbound variable bug from incorrect grep pattern
- Spec 652: State transition validation and error diagnostics
- Spec 672: State persistence enhancements (COMPLETED_STATES, concurrent isolation)
- Spec 675: Library sourcing order fix (moved error-handling.sh early)
- Spec 687: Research complexity recalculation bug fix
- Spec 688: LLM-specific error types

## Completion Checklist

### Phase 1: Library Sourcing Order
- [ ] All bash blocks follow Standard 15 sourcing order
- [ ] No premature function calls
- [ ] Source guards present in all core libraries
- [ ] Standardized bash block template created
- [ ] Automated test passes

### Phase 2: Return Code Verification
- [ ] sm_init has return code check
- [ ] initialize_workflow_paths has return code check
- [ ] classify_workflow_comprehensive has return code check
- [ ] Verification checkpoints after successful calls
- [ ] Test cases for return code verification

### Phase 3: State Persistence
- [ ] All critical variables persisted to state file
- [ ] Verification checkpoints after persistence
- [ ] Defensive array reconstruction implemented
- [ ] Conditional initialization pattern compliant
- [ ] Pre-flight state file validation added

### Phase 4: Verification Checkpoints
- [ ] Inline file verification replaced with verify_file_created
- [ ] State variable verification after initialization
- [ ] Batch verification for research reports
- [ ] Verification summary reporting implemented
- [ ] 90% token reduction measured

### Phase 5: Agent Compliance
- [ ] Post-Task verification for workflow-classifier
- [ ] Enhanced agent behavioral file with execution enforcement
- [ ] Post-Task verification for research agents
- [ ] Fallback JSON parser implemented
- [ ] Agent compliance metrics tracked

### Phase 6: Testing
- [ ] Unit tests for state persistence (15+ tests)
- [ ] Integration tests for workflow scopes (5+ workflows)
- [ ] All automated tests pass (100% pass rate)
- [ ] Performance metrics measured (no regression)
- [ ] Manual testing with real workflow validated

### Phase 7: Documentation
- [ ] Coordinate command guide updated
- [ ] Verification checkpoint patterns documented
- [ ] Bash block execution model updated
- [ ] Error scenario troubleshooting guide created
- [ ] Command architecture standards updated

### Final Validation
- [ ] No unbound variable errors in any workflow scope
- [ ] No state file missing errors
- [ ] No "command not found" errors during initialization
- [ ] Agent delegation rate >90% (expect 100%)
- [ ] File creation reliability 100%
- [ ] Test pass rate 100%
- [ ] Documentation complete and cross-referenced

---

**Implementation Status**: Ready for execution

**Next Steps**:
1. Create feature branch: `git checkout -b fix/coordinate-command-errors`
2. Begin Phase 0 (Pre-Implementation Analysis)
3. Execute Wave 1 phases in parallel (Phase 1, Phase 2)
