# Phase 6: Comprehensive Testing - Dedicated Test Suite Execution

## Metadata
- **Phase Number**: 6
- **Phase Name**: Comprehensive Testing - Dedicated Test Suite Execution
- **Plan Level**: Level 1 (Phase Expansion)
- **Parent Plan**: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- **Complexity Score**: 7/10
- **Priority**: HIGH
- **Expansion Reason**: Workflow restructuring, conditional logic, and multi-file updates for dedicated testing phase

## Dependencies
- **depends_on**: [phase_0]
- **Rationale**: Requires [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) fix from Phase 0 to ensure test-specialist receives artifact context correctly

## Overview

This phase adds a dedicated Testing phase (Phase 4 in the /orchestrate workflow) that executes comprehensive test suites using the test-specialist agent. Currently, /orchestrate conflates implementation and testing in Phase 3, making failure analysis unclear and missing integration test coverage. This phase separates testing into a distinct workflow stage with proper artifact management and conditional debugging.

### Current Problem
The existing /orchestrate implementation embeds testing within the Implementation phase:
- **Unclear Separation**: Implementation and testing are conflated, making it hard to identify whether failures stem from implementation errors or test issues
- **No Comprehensive Suite**: Only phase-specific tests run, missing integration tests and full test suite execution
- **Poor Failure Reporting**: Test failures are mixed with implementation progress, reducing clarity
- **No Test Metrics**: Overall test statistics (pass rate, coverage, duration) are not reported to orchestrator

### Solution Architecture
Add dedicated Phase 4 (Testing) that:
1. Runs after Implementation phase completes (Phase 3)
2. Executes comprehensive test suite using test-specialist agent (NOT /test-all command)
3. Reports detailed test results: pass/fail counts, duration, coverage if available
4. Only proceeds to Debugging (Phase 5) if tests fail
5. Skips Debugging entirely if all tests pass
6. Saves full test output to `{topic_path}/outputs/test_results.txt` for artifact organization
7. Returns only metadata summary to orchestrator for context efficiency

### Infrastructure Already Available
- **test-specialist agent** (`.claude/agents/test-specialist.md`): Discovers test commands from CLAUDE.md, executes tests, analyzes failures
- **Testing protocols** (CLAUDE.md section): Project-specific test commands and patterns
- **testing-patterns.md** (`.claude/commands/shared/testing-patterns.md`): Standardized testing integration patterns
- **analyze-error.sh** (`.claude/utils/analyze-error.sh`): Enhanced error analysis with code context and fix suggestions

## Implementation Stages

### Stage 1: Create Phase 4 in orchestrate.md Workflow Structure

**Objective**: Insert Testing phase between Implementation (Phase 3) and Debugging (Phase 5) in the /orchestrate workflow.

**Tasks**:
- [ ] **Update orchestrate.md phase numbering**
 - Locate orchestrate.md workflow section (typically has markdown headers for each phase)
 - Current structure: 7 phases (Research → Planning → Implementation → Debugging → Documentation → GitHub → Summary)
 - New structure: 8 phases (Research → Planning → Implementation → **Testing** → Debugging → Documentation → GitHub → Summary)
 - Renumber existing phases:
  - Current Phase 4 (Debugging) → New Phase 5 (Debugging)
  - Current Phase 5 (Documentation) → New Phase 6 (Documentation)
  - Current Phase 6 (GitHub) → New Phase 7 (GitHub)
  - Current Phase 7 (Summary) → New Phase 8 (Summary)
 - Verify all phase references updated (headers, dependencies, cross-references)

- [ ] **Add Phase 4 section header in orchestrate.md**
 - Insert after Phase 3 (Implementation) section
 - Use consistent markdown formatting with other phases
 - Section structure:
  ```markdown
  ## Phase 4: Comprehensive Testing

  **Objective**: Execute comprehensive test suite to validate implementation before debugging
  **Timing**: After implementation completes, before debugging
  **Conditional**: Always run, but debugging (Phase 5) only invoked if tests fail
  ```

- [ ] **Update workflow diagram to show 8 phases**
 - Locate workflow visualization in orchestrate.md (ASCII diagram or mermaid chart)
 - Add Testing phase between Implementation and Debugging
 - Show conditional flow: Testing → [if pass] → Documentation, [if fail] → Debugging
 - Example ASCII diagram update:
  ```
  Phase 3: Implementation
     |
     v
  Phase 4: Testing ──┬─[PASSED]──> Phase 6: Documentation
     |       │
     |       └─[FAILED]──> Phase 5: Debugging ──> Phase 6: Documentation
  ```

- [ ] **Update TodoWrite task list in orchestrate.md**
 - Find TodoWrite tool invocation that creates initial task list
 - Add Testing phase task to workflow checklist:
  ```markdown
  - [ ] Phase 4: Execute comprehensive test suite
  - [ ] Phase 4: Analyze test results and failures
  - [ ] Phase 4: Conditionally invoke debugging if tests fail
  ```
 - Ensure task ordering reflects new phase sequence

- [ ] **Update phase dependency comments**
 - Add dependency annotations for new phase:
  ```markdown
  ## Dependencies
  - Phase 4 depends on: Phase 3 (Implementation must complete first)
  - Phase 5 depends on: Phase 4 (Only if tests fail)
  - Phase 6 depends on: Phase 4 or Phase 5 (whichever completed last)
  ```

**Testing**:
```bash
# Verify orchestrate.md structure updated
grep -n "## Phase [0-9]:" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: 8 phase headers, Phase 4 is "Testing"

# Verify workflow diagram includes Testing phase
grep -A 10 "workflow\|diagram" /home/benjamin/.config/.claude/commands/orchestrate.md | grep -i "testing"
# Expected: Testing phase shown in diagram

# Verify TodoWrite includes Testing phase
grep "Phase 4.*test" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: Match found for Phase 4 Testing task
```

**Expected Outcomes**:
- orchestrate.md has 8 clearly numbered phases
- Phase 4 is dedicated to Testing
- Workflow diagram shows conditional flow from Testing to Debugging/Documentation
- TodoWrite task list includes Testing phase

---

### Stage 2: Invoke test-specialist Agent

**Objective**: Add test-specialist agent invocation in Phase 4 using Task tool (NOT /test-all command) with proper artifact context injection.

**Tasks**:
- [ ] **Create Phase 4 implementation block in orchestrate.md**
 - Locate Phase 4 section created in Stage 1
 - Add implementation instructions after phase header
 - Include [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) for test-specialist
 - Structure:
  ```markdown
  ## Phase 4: Comprehensive Testing

  ### Implementation

  After implementation completes, invoke test-specialist agent to execute comprehensive test suite:

  [Task tool invocation details below]
  ```

- [ ] **Add Task tool invocation for test-specialist agent**
 - Use Task tool (NOT SlashCommand tool - Phase 0 requirement)
 - Pass artifact context from Phase 0 location-specialist
 - Inject test output path for artifact organization
 - Template:
  ```yaml
  Task {
   subagent_type: "general-purpose"
   description: "Execute comprehensive test suite using test-specialist protocol"
   prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/test-specialist.md

    You are acting as a Test Specialist Agent.

    CONTEXT:
    - Implementation Phase Complete: {files_modified_list}
    - Plan Path: {plan_path_from_phase_2}
    - Topic Path: {topic_path_from_phase_0}
    - Artifact Paths: {artifact_paths_from_phase_0}

    TASK:
    Execute comprehensive test suite for the implemented feature.

    TEST SCOPE:
    - Run full test suite (not just unit tests)
    - Include integration tests if available
    - Execute regression tests for modified files

    ARTIFACT MANAGEMENT:
    - Save full test output to: {topic_path}/outputs/test_results.txt
    - Save coverage report (if available) to: {topic_path}/outputs/coverage/
    - Return ONLY metadata summary (not full output) to orchestrator

    TEST DISCOVERY:
    - Check CLAUDE.md Testing Protocols section for test commands
    - Use project-specific test patterns
    - Fall back to framework defaults only if CLAUDE.md incomplete

    REQUIRED OUTPUT:
    - tests_passing: true|false
    - total_tests: N
    - passed: N (X%)
    - failed: N (Y%)
    - skipped: N
    - duration: Xs
    - coverage: X% (if available)
    - failed_test_details: [list if tests_passing=false]
    - test_output_path: {topic_path}/outputs/test_results.txt

    Follow all test-specialist protocol requirements (5 steps).
  }
  ```

- [ ] **Inject implementation context into test-specialist prompt**
 - Pass list of modified files from Phase 3 (Implementation)
 - Include implementation summary or commit messages
 - Provide plan path for test-specialist to understand intended behavior
 - Example context structure:
  ```yaml
  Implementation Context:
   files_modified:
    - src/auth/jwt.ts (added JWT token generation)
    - src/auth/middleware.ts (added authentication middleware)
    - tests/auth/jwt.spec.ts (added unit tests)
   implementation_summary: "Implemented JWT authentication with bcrypt password hashing"
   plan_path: "specs/027_auth/plans/027_auth_implementation.md"
  ```

- [ ] **Inject artifact paths from Phase 0 location-specialist**
 - Retrieve location context from Phase 0 workflow state
 - Extract topic_path and artifact_paths
 - Pass to test-specialist for artifact organization compliance
 - [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) example:
  ```yaml
  Artifact Context:
   topic_path: "specs/027_auth"
   artifact_paths:
    outputs: "specs/027_auth/outputs/"
    debug: "specs/027_auth/debug/"
   test_output_file: "specs/027_auth/outputs/test_results.txt"
   coverage_dir: "specs/027_auth/outputs/coverage/"
  ```

- [ ] **Add explicit instructions for metadata-only return**
 - Emphasize context reduction pattern
 - test-specialist should save full output to file
 - Only return structured summary to orchestrator
 - Instruction template:
  ```markdown
  CRITICAL: Context Reduction Pattern
  - Full test output (10,000+ tokens) MUST be saved to test_output_file
  - Return ONLY structured summary (<100 tokens) to orchestrator:
   - Status: PASSED|FAILED|PARTIAL
   - Counts: total, passed, failed, skipped
   - Duration: Xs
   - Coverage: X% (if available)
   - Failed test summaries (top 3 if failures exist)
  - DO NOT include full test output or stack traces in return message
  ```

- [ ] **Verify test-specialist behavioral guidelines compliance**
 - Confirm prompt references test-specialist.md agent file
 - Ensure 5-step test execution process mentioned (discover, execute, analyze, report, return)
 - Include CLAUDE.md test discovery priority
 - Add coverage requirements if project has coverage target

**Testing**:
```bash
# Verify Task tool used (not SlashCommand)
grep -n "SlashCommand.*test" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: No matches (Phase 0 requirement)

grep -n "Task.*test-specialist" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: Match found in Phase 4 section

# Verify artifact context injection
grep -B 5 -A 5 "test-specialist" /home/benjamin/.config/.claude/commands/orchestrate.md | grep "topic_path\|artifact_paths"
# Expected: Artifact context variables referenced

# Verify metadata-only return pattern documented
grep -i "context reduction\|metadata.*only" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: Match in Phase 4 section
```

**Expected Outcomes**:
- Phase 4 uses Task tool to invoke test-specialist agent (NOT /test-all command)
- test-specialist receives implementation context (modified files, plan path)
- test-specialist receives artifact context (topic_path, output paths)
- Prompt explicitly instructs metadata-only return for context efficiency
- Follows [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) from Phase 0

---

### Stage 3: Extract and Parse Test Results

**Objective**: Extract structured test results from test-specialist response and store in workflow state for conditional debugging logic.

**Tasks**:
- [ ] **Define test result data structure in orchestrate.md**
 - Document expected test-specialist return format
 - Create workflow state variable for test results
 - Structure:
  ```yaml
  test_results:
   status: "PASSED|FAILED|PARTIAL"
   tests_passing: true|false
   total_tests: N
   passed: N
   passed_pct: X.X
   failed: N
   failed_pct: Y.Y
   skipped: N
   duration: "Xs"
   coverage: "X%" # Optional
   failed_test_details: # Only if tests_passing=false
    - test_name: "test_auth_validation"
     location: "auth.lua:42"
     error_type: "assertion"
     error_message: "Expected true, got false"
    - test_name: "test_session_timeout"
     location: "session.lua:67"
     error_type: "timeout"
     error_message: "Test exceeded 5s timeout"
   test_output_path: "specs/NNN_topic/outputs/test_results.txt"
   coverage_path: "specs/NNN_topic/outputs/coverage/" # Optional
  ```

- [ ] **Add test result extraction logic after test-specialist invocation**
 - Parse test-specialist response for structured data
 - Extract required fields: status, counts, duration, failures
 - Handle optional fields: coverage, skipped tests
 - Extraction template:
  ```markdown
  After test-specialist completes:

  1. Extract test result summary from response
  2. Parse structured data:
    - Status line: "TEST_RESULTS: PASSED|FAILED|PARTIAL"
    - Counts: "Total: N tests, Passed: M (X%), Failed: F (Y%)"
    - Duration: "Duration: Xs"
    - Coverage: "Coverage: X%" (if available)
    - Failed tests: Parse "Top Failures:" section if present

  3. Store in workflow state as test_results object
  4. Verify all required fields populated
  ```

- [ ] **Implement percentage calculation for pass/fail rates**
 - Calculate passed_pct = (passed / total_tests) * 100
 - Calculate failed_pct = (failed / total_tests) * 100
 - Round to 1 decimal place for readability
 - Handle edge cases: zero total tests, all skipped
 - Calculation example:
  ```javascript
  // Pseudo-code for percentage calculation
  if (total_tests > 0) {
   passed_pct = Math.round((passed / total_tests) * 1000) / 10;
   failed_pct = Math.round((failed / total_tests) * 1000) / 10;
  } else {
   passed_pct = 0;
   failed_pct = 0;
  }
  ```

- [ ] **Parse failed test details from test-specialist response**
 - Extract top 3 failed tests (per test-specialist return format)
 - For each failure, parse:
  - Test name
  - File location (file:line)
  - Error type (assertion, exception, timeout)
  - Error message (brief summary)
 - Store in failed_test_details array
 - Parsing example:
  ```markdown
  Parse "Top Failures:" section:

  Input:
  "Top Failures:
   1. test_auth_validation - assertion error at auth.lua:42
   2. test_session_timeout - timeout after 5s at session.lua:67"

  Parsed Output:
  failed_test_details: [
   {
    test_name: "test_auth_validation",
    location: "auth.lua:42",
    error_type: "assertion",
    error_message: "assertion error"
   },
   {
    test_name: "test_session_timeout",
    location: "session.lua:67",
    error_type: "timeout",
    error_message: "timeout after 5s"
   }
  ]
  ```

- [ ] **Validate test result completeness**
 - Verify all required fields present: status, total_tests, passed, failed, duration
 - Check that percentages sum to 100% (accounting for skipped tests)
 - Ensure failed_test_details populated if status=FAILED
 - Validation checks:
  ```bash
  # Verify required fields
  required_fields=("status" "total_tests" "passed" "failed" "duration")
  for field in "${required_fields[@]}"; do
   if [ -z "${test_results[$field]}" ]; then
    echo "ERROR: Missing required field: $field"
    exit 1
   fi
  done

  # Verify percentages
  total_pct=$((passed_pct + failed_pct + skipped_pct))
  if [ "$total_pct" -ne 100 ]; then
   echo "WARNING: Percentages don't sum to 100% ($total_pct%)"
  fi

  # Verify failed_test_details if status=FAILED
  if [ "$status" = "FAILED" ] && [ ${#failed_test_details[@]} -eq 0 ]; then
   echo "ERROR: Status=FAILED but no failed_test_details provided"
   exit 1
  fi
  ```

- [ ] **Store test results in workflow state for next phases**
 - Save test_results object to workflow state
 - Make available to Phase 5 (Debugging) if needed
 - Make available to Phase 6 (Documentation) for summary
 - State management example:
  ```markdown
  Workflow State Update:

  workflow_state.test_results = {
   status: "FAILED",
   tests_passing: false,
   total_tests: 42,
   passed: 38,
   passed_pct: 90.5,
   failed: 4,
   failed_pct: 9.5,
   skipped: 0,
   duration: "3.1s",
   coverage: "85%",
   failed_test_details: [...],
   test_output_path: "specs/027_auth/outputs/test_results.txt"
  }
  ```

**Testing**:
```bash
# Test extraction with passing tests
test_specialist_response="TEST_RESULTS: PASSED
Total: 42 tests
Passed: 42 (100%)
Failed: 0 (0%)
Duration: 2.3s"

# Parse response
# Expected: status=PASSED, total_tests=42, passed=42, failed=0, duration=2.3s

# Test extraction with failing tests
test_specialist_response="TEST_RESULTS: FAILED
Total: 42 tests
Passed: 38 (90%)
Failed: 4 (10%)
Duration: 3.1s

Top Failures:
1. test_auth_validation - assertion error at auth.lua:42
2. test_session_timeout - timeout after 5s at session.lua:67"

# Parse response
# Expected: status=FAILED, failed_test_details array with 2 entries

# Verify percentage calculation
# Input: total=42, passed=38, failed=4
# Expected: passed_pct=90.5%, failed_pct=9.5%
```

**Expected Outcomes**:
- Test results extracted into structured data object
- All required fields populated: status, counts, percentages, duration
- Failed test details parsed and stored (if failures exist)
- Workflow state updated with test_results for subsequent phases
- Validation ensures data completeness before proceeding

---

### Stage 4: Implement Conditional Debugging Logic

**Objective**: Add conditional logic to skip Debugging phase (Phase 5) if all tests pass, or invoke debugging if tests fail.

**Tasks**:
- [ ] **Add conditional branching after test result extraction**
 - Check test_results.tests_passing boolean
 - If true: Skip Phase 5 (Debugging), proceed directly to Phase 6 (Documentation)
 - If false: Invoke Phase 5 (Debugging) with failed test context
 - Conditional logic template:
  ```markdown
  After Phase 4 (Testing) completes:

  if (test_results.tests_passing == true):
   # All tests passed
   Display: "✓ All tests passing, skipping debugging phase"
   Update workflow_state: debugging_skipped = true
   Proceed to: Phase 6 (Documentation)
  else:
   # Some tests failed
   Display: "⚠ {failed} tests failed, proceeding to debugging phase"
   Update workflow_state: debugging_skipped = false
   Proceed to: Phase 5 (Debugging)
   Pass to debugging: test_results.failed_test_details
  ```

- [ ] **Display test summary to user before conditional branch**
 - Show comprehensive test results regardless of pass/fail
 - Use consistent formatting for clarity
 - Include next phase indication based on results
 - Display template:
  ```markdown
  ✓ Testing Phase Complete

  Test Suite Results:
  Total Tests: {total_tests}
  ✓ Passed: {passed} ({passed_pct}%)
  ✗ Failed: {failed} ({failed_pct}%)
  ⊘ Skipped: {skipped}
  Duration: {duration}
  Coverage: {coverage} (if available)

  [If tests_passing=true]
  Next: Documentation Phase (Phase 6)

  [If tests_passing=false]
  Next: Debugging Loop (Phase 5)
  Failed Tests:
  1. {test_name_1} - {error_type} at {location}
  2. {test_name_2} - {error_type} at {location}
  3. {test_name_3} - {error_type} at {location}
  ```

- [ ] **Implement skip logic for Phase 5 when tests pass**
 - Add check at Phase 5 entry point
 - If debugging_skipped=true, skip entire Phase 5 section
 - Log skip reason for transparency
 - Skip implementation:
  ```markdown
  ## Phase 5: Debugging

  ### Conditional Execution Check

  if (workflow_state.debugging_skipped == true):
   Display: "⊘ Debugging phase skipped (all tests passing)"
   Log: "Phase 5 skipped at {timestamp} - reason: tests passing"
   Proceed to: Phase 6 (Documentation)
   Exit Phase 5

  # Only execute if debugging_skipped=false
  [Debugging implementation follows...]
  ```

- [ ] **Pass failed test context to Phase 5 (Debugging) when invoked**
 - Extract failed_test_details from test_results
 - Include test_output_path for detailed analysis
 - Pass implementation context (files modified, plan path)
 - Context injection for debugging:
  ```yaml
  Debugging Context (when tests fail):
   test_failures:
    - test_name: "test_auth_validation"
     location: "auth.lua:42"
     error_type: "assertion"
     error_message: "Expected true, got false"
    - test_name: "test_session_timeout"
     location: "session.lua:67"
     error_type: "timeout"
     error_message: "Test exceeded 5s timeout"
   test_output_path: "specs/027_auth/outputs/test_results.txt"
   files_modified: [list from Phase 3]
   plan_path: "specs/027_auth/plans/027_auth_implementation.md"
   debugging_goal: "Fix {failed} failing tests"
  ```

- [ ] **Update debug-specialist agent invocation with test context**
 - Modify Phase 5 debug-specialist prompt to receive test failures
 - Include test_output_path for detailed error analysis
 - Inject failed test details for focused debugging
 - Updated debug-specialist prompt:
  ```yaml
  Task {
   subagent_type: "general-purpose"
   description: "Debug failing tests using debug-specialist protocol"
   prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist Agent.

    CONTEXT:
    - Test Failures: {failed} tests failed in Phase 4 (Testing)
    - Failed Test Details:
     {failed_test_details_list}
    - Full Test Output: {test_output_path}
    - Implementation Files: {files_modified}
    - Plan Path: {plan_path}

    TASK:
    Investigate root causes for test failures and propose fixes.

    INVESTIGATION FOCUS:
    - Analyze each failed test for root cause
    - Check implementation against test expectations
    - Identify patterns across multiple failures
    - Prioritize fixes by failure type (assertion vs timeout vs exception)

    ARTIFACT MANAGEMENT:
    - Save debug report to: {topic_path}/debug/test_failures_{timestamp}.md
    - Include proposed fixes with code examples
    - Return fix proposals summary (not full debug report)

    Follow all debug-specialist protocol requirements.
  }
  ```

- [ ] **Add workflow state tracking for debugging invocation**
 - Track whether debugging was invoked or skipped
 - Record reason for decision (tests passing vs failing)
 - Include in workflow summary for Phase 8
 - State tracking:
  ```yaml
  workflow_state.debugging_invocation:
   invoked: true|false
   reason: "tests_passing|tests_failing"
   timestamp: "2025-10-21T14:30:00Z"
   failed_test_count: N # if invoked due to failures
  ```

**Testing**:
```bash
# Test conditional logic with passing tests
test_results.tests_passing=true
# Expected: debugging_skipped=true, proceed to Phase 6

# Test conditional logic with failing tests
test_results.tests_passing=false
test_results.failed=4
# Expected: debugging_skipped=false, invoke Phase 5 with test context

# Verify test summary displayed before branch
# Expected: Display shows total, passed, failed, next phase indication

# Verify debug-specialist receives test context when invoked
# Expected: failed_test_details, test_output_path passed to debug-specialist
```

**Expected Outcomes**:
- Conditional logic correctly skips debugging when tests pass
- Debugging invoked only when tests fail (conditional execution)
- Test summary displayed to user before branching
- debug-specialist receives complete test failure context when invoked
- Workflow state tracks debugging invocation decision
- Time saved on successful workflows (skip debugging entirely)

---

### Stage 5: Remove Inline Testing from implementation-executor

**Objective**: Update implementation-executor agent to remove inline testing, as testing now happens in dedicated Phase 4.

**Tasks**:
- [ ] **Locate implementation-executor agent file**
 - Find `.claude/agents/implementation-executor.md` (or equivalent)
 - Identify test execution sections within implementation logic
 - Document current testing approach for comparison
 - Discovery:
  ```bash
  # Find implementation-executor agent
  find .claude/agents/ -name "*implement*" -o -name "*executor*"

  # Search for test execution within agent
  grep -n "test\|Test" .claude/agents/implementation-executor.md
  ```

- [ ] **Remove test execution instructions from implementation-executor**
 - Delete sections instructing agent to run tests after task batches
 - Remove test command discovery logic (now in test-specialist)
 - Remove test result parsing logic (now in test-specialist)
 - Remove test failure handling (now in Phase 4/5)
 - Changes to make:
  ```markdown
  BEFORE (implementation-executor with inline testing):

  After every 3-5 tasks:
  1. Update plan file with completed tasks
  2. Run tests for implemented code
  3. If tests fail, analyze failures
  4. Fix issues or report to coordinator
  5. Continue implementation

  AFTER (implementation-executor without testing):

  After every 3-5 tasks:
  1. Update plan file with completed tasks
  2. Continue implementation

  Testing happens in dedicated Phase 4 after implementation completes.
  ```

- [ ] **Update implementation-executor to focus on code implementation only**
 - Clarify agent role: "Implementation only, testing in separate phase"
 - Remove test-related checkpoints and verification steps
 - Simplify completion criteria: tasks complete, plan updated, no testing
 - Updated agent description:
  ```markdown
  # Implementation Executor Agent

  **Role**: Execute implementation tasks from plan phases
  **Scope**: Code implementation ONLY (no testing)
  **Testing**: Deferred to dedicated Testing phase (Phase 4 in /orchestrate)

  ## Behavioral Changes (2025-10-21)

  **REMOVED**: Inline test execution after task batches
  **RATIONALE**: Testing now happens in dedicated workflow phase
  **BENEFIT**: Clear separation of implementation vs validation

  ## Implementation Process

  For each task in phase:
  1. Read task description and requirements
  2. Implement code changes
  3. Update plan file: mark task complete [x]
  4. Continue to next task

  NO TESTING in this agent - all testing happens in Phase 4.
  ```

- [ ] **Update implementation-executor completion criteria**
 - Remove test passing requirements from completion checklist
 - Focus on implementation completion only
 - Document that testing validation happens in Phase 4
 - Updated completion criteria:
  ```markdown
  ## Phase Completion Checklist (implementation-executor)

  - [x] All implementation tasks completed
  - [x] Plan file updated with task checkboxes [x]
  - [x] Code changes committed to git
  - [x] Parent plan hierarchy updated with progress

  REMOVED (now in Phase 4 Testing):
  - [ ] All tests passing ❌ (now in Phase 4)
  - [ ] Test coverage ≥80% ❌ (now in Phase 4)
  - [ ] No test failures ❌ (now in Phase 4)

  Testing validation happens in dedicated Phase 4 (Comprehensive Testing).
  Implementation-executor completes when code is implemented, not when tests pass.
  ```

- [ ] **Add note to implementation-executor about Phase 4 testing**
 - Clarify handoff between Implementation (Phase 3) and Testing (Phase 4)
 - Explain that test failures are debugged in Phase 5, not during implementation
 - Document workflow change rationale
 - Handoff documentation:
  ```markdown
  ## Testing Handoff to Phase 4

  implementation-executor completes when all tasks implemented, NOT when tests pass.

  Workflow:
  1. implementation-executor implements all tasks (Phase 3)
  2. implementation-executor returns: files_modified, tasks_completed, plan_updated
  3. Orchestrator invokes test-specialist (Phase 4)
  4. test-specialist runs comprehensive test suite
  5. If tests fail: Orchestrator invokes debug-specialist (Phase 5)
  6. debug-specialist fixes issues, test-specialist re-runs tests

  BENEFIT: Clear separation allows debugging phase to focus on test failures,
  not mixed with implementation progress.
  ```

- [ ] **Update orchestrate.md Phase 3 to reflect implementation-only behavior**
 - Document that Phase 3 does not include testing
 - Clarify that implementation completes when tasks done, regardless of test status
 - Update phase summary to reflect change
 - Phase 3 documentation update:
  ```markdown
  ## Phase 3: Implementation

  **Objective**: Implement all tasks from plan phases
  **Scope**: Code implementation ONLY
  **Testing**: Deferred to Phase 4 (Comprehensive Testing)

  ### Behavioral Change (2025-10-21)

  Previously: Phase 3 included inline testing after task batches
  Now: Phase 3 focuses purely on implementation, testing in Phase 4

  Rationale:
  - Clearer separation of concerns
  - Better failure analysis (implementation vs test issues)
  - Comprehensive test suite in Phase 4 includes integration tests
  - Conditional debugging in Phase 5 only if Phase 4 tests fail

  ### Implementation Process

  1. Invoke implementation-executor with plan path
  2. implementation-executor implements tasks sequentially
  3. implementation-executor updates plan hierarchy with progress
  4. implementation-executor returns: files_modified, commit_hashes
  5. Proceed to Phase 4 (Testing) regardless of implementation quality

  Phase 3 completes when implementation done, NOT when tests pass.
  ```

**Testing**:
```bash
# Verify test execution removed from implementation-executor
grep -n "run.*test\|execute.*test" .claude/agents/implementation-executor.md
# Expected: No matches (or only in "Testing in Phase 4" note)

# Verify completion criteria updated
grep -A 10 "Completion Checklist" .claude/agents/implementation-executor.md | grep "test"
# Expected: Test requirements removed or marked as "REMOVED (now in Phase 4)"

# Verify Phase 3 documentation reflects implementation-only behavior
grep -A 5 "Phase 3.*Implementation" /home/benjamin/.config/.claude/commands/orchestrate.md | grep -i "test"
# Expected: References testing deferred to Phase 4
```

**Expected Outcomes**:
- implementation-executor agent no longer executes tests
- Agent focuses purely on code implementation
- Completion criteria updated: implementation done, not tests passing
- Phase 3 (Implementation) documented as implementation-only
- Clear handoff between Phase 3 (Implementation) and Phase 4 (Testing)
- Rationale documented for workflow change

---

### Stage 6: Manage Test Output Artifacts

**Objective**: Ensure test-specialist saves full test output and coverage reports to correct artifact locations per directory protocols.

**Tasks**:
- [ ] **Verify test output path structure in test-specialist prompt**
 - Confirm test_output_file path follows topic-based organization
 - Path format: `{topic_path}/outputs/test_results.txt`
 - Ensure outputs/ subdirectory created by location-specialist (Phase 0)
 - Path verification:
  ```yaml
  Test Output Artifact Paths:
   test_results: "{topic_path}/outputs/test_results.txt"
   coverage_report: "{topic_path}/outputs/coverage/" (if available)
   test_logs: "{topic_path}/outputs/test_execution.log" (optional)

  Example:
   specs/027_auth/outputs/test_results.txt
   specs/027_auth/outputs/coverage/index.html
  ```

- [ ] **Add test output file creation instructions to test-specialist prompt**
 - Explicitly instruct test-specialist to save full test output
 - Include stdout and stderr in saved output
 - Preserve formatting for human readability
 - Instruction template:
  ```markdown
  ARTIFACT MANAGEMENT (test-specialist):

  After test execution completes:

  1. Save full test output to: {topic_path}/outputs/test_results.txt
    - Include: stdout and stderr
    - Include: all test names, pass/fail status, error messages
    - Include: stack traces for failures
    - Preserve: ANSI color codes (optional) or strip for readability

  2. If coverage available, save to: {topic_path}/outputs/coverage/
    - HTML coverage report: coverage/index.html
    - JSON coverage data: coverage/coverage.json
    - Text summary: coverage/summary.txt

  3. Verify files created successfully:
    - Check test_results.txt exists and is not empty
    - Check coverage/ directory created (if coverage available)
  ```

- [ ] **Add coverage report handling instructions**
 - If project has coverage tools (jest, pytest-cov, etc.), capture coverage
 - Save coverage reports to `{topic_path}/outputs/coverage/`
 - Include multiple formats: HTML (for viewing), JSON (for parsing), text (for summary)
 - Coverage handling:
  ```bash
  # Coverage detection and capture (pseudo-code for test-specialist)

  # Detect coverage tool
  if command_exists "jest --coverage"; then
   COVERAGE_CMD="jest --coverage"
   COVERAGE_OUTPUT="coverage/"
  elif command_exists "pytest --cov"; then
   COVERAGE_CMD="pytest --cov=src --cov-report=html --cov-report=json"
   COVERAGE_OUTPUT="htmlcov/"
  fi

  # Run tests with coverage
  $TEST_COMMAND_WITH_COVERAGE > test_output.txt 2>&1

  # Copy coverage to artifact location
  if [ -d "$COVERAGE_OUTPUT" ]; then
   mkdir -p "$TOPIC_PATH/outputs/coverage/"
   cp -r "$COVERAGE_OUTPUT"/* "$TOPIC_PATH/outputs/coverage/"
  fi
  ```

- [ ] **Implement context reduction for test output**
 - Full test output saved to file (10,000+ tokens)
 - Only metadata summary returned to orchestrator (<100 tokens)
 - Orchestrator receives: pass/fail counts, duration, coverage %, top 3 failures
 - Full output available at test_output_path for debugging if needed
 - Context reduction pattern:
  ```markdown
  Context Reduction for Test Output:

  FULL OUTPUT (saved to file):
  - All test names and results: 10,000+ tokens
  - Stack traces for all failures: 5,000+ tokens
  - Coverage report details: 3,000+ tokens
  Total: ~18,000 tokens saved to test_results.txt

  SUMMARY (returned to orchestrator):
  - Status: PASSED|FAILED|PARTIAL (1 token)
  - Counts: "42 total, 38 passed (90%), 4 failed (10%)" (15 tokens)
  - Duration: "3.1s" (2 tokens)
  - Coverage: "85%" (2 tokens)
  - Top 3 failures: 3 x 20 tokens = 60 tokens
  Total: ~80 tokens returned to orchestrator

  Reduction: 18,000 → 80 tokens (99.6% reduction)
  ```

- [ ] **Add artifact path validation after test-specialist completes**
 - Verify test_results.txt created at expected path
 - Check file is not empty (non-zero size)
 - If coverage expected, verify coverage/ directory exists
 - Log warnings for missing artifacts
 - Validation logic:
  ```bash
  # Artifact validation after Phase 4 completes

  test_output_file="$TOPIC_PATH/outputs/test_results.txt"

  # Verify test output file exists
  if [ ! -f "$test_output_file" ]; then
   echo "WARNING: Test output file not created at $test_output_file"
   echo "test-specialist may not have saved output correctly"
  fi

  # Verify file is not empty
  if [ -f "$test_output_file" ] && [ ! -s "$test_output_file" ]; then
   echo "WARNING: Test output file is empty: $test_output_file"
  fi

  # Verify coverage if expected
  if [ -n "$COVERAGE_EXPECTED" ]; then
   coverage_dir="$TOPIC_PATH/outputs/coverage/"
   if [ ! -d "$coverage_dir" ]; then
    echo "WARNING: Coverage directory not created at $coverage_dir"
   fi
  fi

  echo "✓ VERIFIED: Test output artifacts created at $TOPIC_PATH/outputs/"
  ```

- [ ] **Document artifact lifecycle for test outputs**
 - test_results.txt: Gitignored (per directory protocols)
 - coverage/: Gitignored (large, regenerable)
 - test_execution.log: Gitignored (optional)
 - Update .gitignore if not already configured
 - Lifecycle documentation:
  ```markdown
  ## Test Output Artifact Lifecycle

  Per directory protocols (CLAUDE.md):

  Artifact Type: outputs/ (test results, coverage)
  Lifecycle: Gitignored
  Rationale: Regenerable from source, large files, frequently changing

  .gitignore rules:
  specs/*/outputs/test_results.txt
  specs/*/outputs/coverage/
  specs/*/outputs/*.log

  When to commit: NEVER (always regenerate)
  When to clean: After debugging complete or before git operations
  ```

- [ ] **Add reference to test output path in orchestrator logs**
 - After Phase 4 completes, display test output path to user
 - Allows user to review full test output if needed
 - Helpful for debugging complex test failures
 - Display template:
  ```markdown
  ✓ Testing Phase Complete

  Test Suite Results:
  Total Tests: 42
  ✓ Passed: 38 (90%)
  ✗ Failed: 4 (10%)
  Duration: 3.1s
  Coverage: 85%

  Full test output: specs/027_auth/outputs/test_results.txt
  Coverage report: specs/027_auth/outputs/coverage/index.html

  Next: Debugging Loop (4 failures to investigate)
  ```

**Testing**:
```bash
# Verify test output file created after Phase 4
ls -lh specs/NNN_topic/outputs/test_results.txt
# Expected: File exists with non-zero size

# Verify coverage report created if available
ls -lh specs/NNN_topic/outputs/coverage/
# Expected: Directory exists with index.html, coverage.json

# Verify .gitignore rules
grep "outputs.*test_results\|outputs.*coverage" .gitignore
# Expected: Matches found (test outputs gitignored)

# Verify context reduction
# Expected: Orchestrator receives <100 token summary, not 10k+ token full output
```

**Expected Outcomes**:
- test-specialist saves full test output to `{topic_path}/outputs/test_results.txt`
- Coverage reports saved to `{topic_path}/outputs/coverage/` if available
- Context reduction: 99%+ reduction (18,000 tokens → <100 tokens)
- Artifact paths follow topic-based organization (directory protocols)
- Test outputs gitignored per artifact lifecycle standards
- User can access full test output at known path for debugging

---

## Phase Completion Checklist

After completing all 6 stages:

- [ ] **Workflow Structure**:
 - [x] orchestrate.md has 8 phases (added Testing as Phase 4)
 - [x] Phase numbering updated consistently (Debugging 4→5, Documentation 5→6, etc.)
 - [x] Workflow diagram shows conditional Testing → Debugging/Documentation flow
 - [x] TodoWrite task list includes Testing phase

- [ ] **Agent Invocation**:
 - [x] Phase 4 uses Task tool to invoke test-specialist (NOT /test-all command)
 - [x] test-specialist receives implementation context (files modified, plan path)
 - [x] test-specialist receives artifact context (topic_path, output paths)
 - [x] [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) followed (no SlashCommand tool)

- [ ] **Test Result Extraction**:
 - [x] Structured test result data extracted from test-specialist response
 - [x] All required fields populated: status, counts, percentages, duration
 - [x] Failed test details parsed and stored
 - [x] Workflow state updated with test_results

- [ ] **Conditional Logic**:
 - [x] Conditional branching implemented: tests pass → skip debugging, tests fail → invoke debugging
 - [x] Test summary displayed to user before branching
 - [x] debug-specialist receives test failure context when invoked
 - [x] Workflow state tracks debugging invocation decision

- [ ] **implementation-executor Updates**:
 - [x] Inline testing removed from implementation-executor agent
 - [x] Agent focuses on code implementation only
 - [x] Completion criteria updated: implementation done, not tests passing
 - [x] Phase 3 documented as implementation-only

- [ ] **Artifact Management**:
 - [x] test-specialist saves full test output to `{topic_path}/outputs/test_results.txt`
 - [x] Coverage reports saved to `{topic_path}/outputs/coverage/` if available
 - [x] Context reduction: orchestrator receives <100 token summary, not full output
 - [x] Artifact paths follow topic-based organization
 - [x] Test outputs gitignored per lifecycle standards

- [ ] **Testing and Validation**:
 - [x] Test Phase 4 with passing tests: debugging skipped, proceed to documentation
 - [x] Test Phase 4 with failing tests: debugging invoked with test context
 - [x] Verify test output artifacts created at correct paths
 - [x] Verify context reduction working (orchestrator <100 tokens, file ~18k tokens)

- [ ] **Documentation**:
 - [x] orchestrate.md Phase 4 section complete with all stages documented
 - [x] Behavioral change rationale documented (separation of implementation vs testing)
 - [x] Artifact management patterns documented
 - [x] Conditional logic clearly explained

## Integration with Other Phases

### Dependencies
- **Phase 0 (Command Isolation)**: CRITICAL dependency - [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) must work for test-specialist to receive artifact context
- **Phase 1 (Location Specialist)**: Provides topic_path and artifact_paths for test output location
- **Phase 3 (Implementation)**: Provides files_modified and implementation_summary for test scope

### Downstream Impact
- **Phase 5 (Debugging)**: Now conditionally invoked based on Phase 4 test results
- **Phase 6 (Documentation)**: Receives test results for workflow summary
- **Phase 7 (Progress Tracking)**: May track test metrics (pass rate, coverage trends)

### Workflow Changes Summary
```
BEFORE (7 phases):
Phase 3: Implementation (with inline testing) → Phase 4: Debugging → Phase 5: Documentation

AFTER (8 phases):
Phase 3: Implementation (no testing) → Phase 4: Testing → [if fail] Phase 5: Debugging → Phase 6: Documentation
                             → [if pass] Phase 6: Documentation
```

## Expected Benefits

1. **Clear Separation**: Implementation (Phase 3) and Testing (Phase 4) are distinct, making failure analysis easier
2. **Comprehensive Testing**: Full test suite executed, not just phase-specific tests
3. **Better Failure Analysis**: Test failures identified before debugging, with detailed error context
4. **Context Efficiency**: Full test output saved to file (18k+ tokens), orchestrator receives summary (<100 tokens) = 99%+ reduction
5. **Conditional Debugging**: Debugging phase only invoked if tests fail, saving time on passing workflows (40-60% time savings for successful workflows)
6. **Test Metrics**: Pass rate, coverage, duration reported to user for quality visibility
7. **Artifact Organization**: Test outputs saved to `{topic_path}/outputs/` per directory protocols standards

## Revision History

- **2025-10-21**: Phase 6 expansion created from Level 0 plan (080_orchestrate_enhancement.md)
- **Expansion Reason**: Complexity score 7/10, workflow restructuring with conditional logic across multiple files
- **Parent Plan Updated**: Summary and reference added to Level 0 plan Phase 6 section
