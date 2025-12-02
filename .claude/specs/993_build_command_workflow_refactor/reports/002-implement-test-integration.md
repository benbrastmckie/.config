# Implement-Test Integration Patterns Research

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Integration patterns for /implement and /test commands with summary-based handoff
- **Report Type**: Integration patterns analysis
- **Complexity**: 2
- **Workflow Type**: research-and-revise
- **Existing Plan**: /home/benjamin/.config/.claude/specs/993_build_command_workflow_refactor/plans/001-build-command-workflow-refactor-plan.md

## Executive Summary

This research analyzes integration patterns for splitting /build (1913 lines) into /implement and /test commands with summary-based handoff. Analysis reveals: (1) implementer-coordinator already creates summaries (lines 520-523) that /test can consume via `--file` pattern, (2) /implement should write tests alongside implementation (not /test), (3) /test runs test-executor in retry loop until coverage/passing threshold met, (4) existing summary format supports test requirement specification, (5) standards documentation needed for implement-test workflow, test-writing responsibility, and coverage loop patterns.

**Key Findings**:
- Summary-based handoff: implementer-coordinator returns `summary_path` in IMPLEMENTATION_COMPLETE signal (build.md:1890-1896)
- Test writing: Should occur in /implement phase (implementer-coordinator delegates to implementation-executor which writes tests)
- Test execution loops: /test should retry test-executor until coverage ≥80% AND all tests pass
- Existing summary pattern: Already includes implementation artifacts, can extend for test requirements
- Documentation gaps: No standards for implement-test workflow, test-writing responsibility, coverage loops

## Research Focus Areas

### 1. Summary-Based Handoff Mechanism

#### Current Implementation Pattern

**implementer-coordinator Return Signal** (build.md lines 555-564, agents/implementer-coordinator.md lines 519-527):

```yaml
IMPLEMENTATION_COMPLETE:
  phases_completed: {PHASE_COUNT}
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  plan_path: {PLAN_FILE}
  topic_path: {TOPIC_PATH}
  work_remaining: {WORK_REMAINING}
  context_exhausted: {CONTEXT_EXHAUSTED}
  checkpoint_path: {CHECKPOINT_PATH}
  next_command: "/test {PLAN_FILE}"
```

**Summary File Structure** (specs/004_todo_command_subagent_delegation/summaries/001-implementation-summary.md):

```markdown
# {FEATURE_NAME} - Implementation Summary

## Work Status
**Completion: X/Y phases (Z%)**

## Implementation Overview
[High-level description of what was implemented]

## Completed Phases
### Phase N: {PHASE_NAME}
**Deliverables**:
- [List of completed deliverables]

**Key Changes**:
- [List of key implementation changes]

**Artifacts Created**:
- [List of files created/modified with paths]

---

## Testing Strategy
[Test coverage requirements, test types, expected test locations]

## Known Limitations
[Edge cases, incomplete features, future work]

## Next Steps
[What should happen next - typically testing]
```

**Key Insights**:
1. Summary path already returned in IMPLEMENTATION_COMPLETE signal (no new mechanism needed)
2. Summary format supports test requirements via "Testing Strategy" section
3. Summary includes artifact paths for test execution context
4. Summary is self-contained (no dependency on /implement state)

#### Proposed /test --file Pattern

**Command Syntax**:
```bash
/test --file /path/to/summaries/001-implementation-summary.md
```

**Argument Parsing** (following commands/debug.md pattern lines 111-152):

```bash
# Parse optional --file flag for implementation summary
TEST_CONTEXT=""
if [[ "$BUILD_ARGS" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  SUMMARY_FILE="${BASH_REMATCH[1]}"

  # Validate summary file exists
  if [ ! -f "$SUMMARY_FILE" ]; then
    log_command_error "validation_error" \
      "Summary file not found" \
      "Path: $SUMMARY_FILE"
    echo "ERROR: --file path does not exist: $SUMMARY_FILE" >&2
    exit 1
  fi

  # Extract plan path from summary metadata
  PLAN_FILE=$(grep "^- \*\*Plan\*\*:" "$SUMMARY_FILE" | sed 's/.*: //')

  # Set test context flag
  TEST_CONTEXT="summary"
elif [[ "$BUILD_ARGS" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /test --file /path/to/summary.md" >&2
  exit 1
fi
```

**Alternative: Plan-Based Discovery** (if --file not provided):

```bash
# If no --file, derive summary from plan path
if [ -z "$TEST_CONTEXT" ]; then
  TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
  SUMMARIES_DIR="${TOPIC_PATH}/summaries"

  # Find most recent summary
  LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  if [ -n "$LATEST_SUMMARY" ]; then
    SUMMARY_FILE="$LATEST_SUMMARY"
    TEST_CONTEXT="auto-discovered"
  else
    TEST_CONTEXT="no-summary"
  fi
fi
```

**Integration with test-executor** (agents/test-executor.md lines 28-49):

```yaml
# test-executor input contract already supports plan_path
test-executor input:
  plan_path: {PLAN_FILE}           # Derived from summary
  topic_path: {TOPIC_PATH}         # Derived from summary
  artifact_paths:
    outputs: {TOPIC_PATH}/outputs/
    debug: {TOPIC_PATH}/debug/
  test_config:
    test_command: null             # Auto-detect
    retry_on_failure: true         # NEW: Enable coverage loop
    coverage_threshold: 80         # NEW: Minimum coverage %
    max_test_iterations: 5         # NEW: Loop limit
  output_path: {TEST_OUTPUT_PATH}  # Pre-calculated
```

**Summary Consumption Pattern**:
- /test reads summary file (if provided via --file)
- Extracts plan_path, topic_path from summary metadata
- Passes test requirements from "Testing Strategy" section to test-executor
- test-executor uses plan_path for framework detection, artifact discovery

**Advantages**:
1. Decouples /test from /implement state (summary is self-contained)
2. Supports manual /test invocation (user provides --file)
3. Supports auto-resume (discover latest summary from plan path)
4. No state file dependency across command boundary

### 2. Test Writing Responsibility

#### Current Pattern Analysis

**implementer-coordinator Delegation Chain** (agents/implementer-coordinator.md lines 200-280):

```
implementer-coordinator
  └─> implementation-executor (for each phase)
      ├─> Execute phase tasks
      ├─> Write implementation code
      ├─> Write tests (if Testing phase or test-writing task)
      └─> Return phase completion
```

**implementation-executor Test Writing** (agents/implementation-executor.md lines 227-241):

```yaml
# Phase completion signal includes test artifacts
PHASE_COMPLETE:
  phase_number: {PHASE}
  phase_name: {NAME}
  tasks_completed: {COUNT}
  files_modified: [list]
  tests_created: [list]          # NEW: Track test files
  summary_path: /path/to/summary.md
```

**Testing Phase Pattern** (docs/guides/patterns/implementation-guide.md lines 14-26):

```markdown
### Phase 3: Testing [EXAMPLE]
**Objective**: Add comprehensive test coverage

**Tasks**:
- [ ] Write unit tests for authentication module
- [ ] Write integration tests for login flow
- [ ] Add test fixtures for user creation
- [ ] Configure test runner in CI/CD

**Testing**:
npm test
```

**Key Insights**:
1. Tests should be written DURING implementation (by implementation-executor)
2. Testing phases should write tests, not run them
3. Test-writing is a task like any other implementation task
4. /test command runs existing tests, doesn't write new ones

#### Proposed Pattern: /implement Writes Tests

**Implementation-Executor Enhancement**:

```markdown
### STEP 4: Execute Phase Tasks

For each task in phase:
1. **Identify task type**:
   - Code implementation → Write production code
   - Test writing → Write test files
   - Documentation → Write docs
   - Configuration → Update config files

2. **Test-writing detection**:
   - Task contains "write test", "add test", "test coverage"
   - Phase name contains "Testing", "Test"
   - Testing section in phase contains test commands

3. **Test file creation**:
   - Follow testing-protocols.md patterns
   - Place tests according to language conventions:
     - Python: tests/test_*.py
     - JavaScript: *.test.js, *.spec.js
     - Bash: tests/test_*.sh
     - Lua: tests/*_spec.lua
   - Use framework detected by detect-testing.sh

4. **Test framework selection** (from testing-protocols.md):
   - Python: pytest (preferred), unittest
   - JavaScript: jest (preferred), vitest, mocha
   - Bash: Custom test scripts following PASS/FAIL pattern
   - Lua: plenary.nvim

5. **Coverage targets** (from testing-protocols.md lines 34-38):
   - Aim for >80% coverage on new code
   - All public APIs must have tests
   - Critical paths require integration tests
   - Regression tests for all bug fixes
```

**Summary Enhancement** (include test artifacts):

```markdown
## Completed Phases

### Phase 3: Testing
**Deliverables**:
- Unit tests for authentication module
- Integration tests for login flow
- Test fixtures for user creation

**Test Files Created**:
- tests/test_auth.py (15 tests)
- tests/test_login_flow.py (8 tests)
- tests/fixtures/users.py

**Coverage Baseline**: N/A (tests written, not yet executed)

---

## Testing Strategy

### Test Execution Requirements
- **Framework**: pytest (auto-detected)
- **Command**: `python -m pytest -v --cov=src --cov-report=term`
- **Coverage Target**: ≥80%
- **Expected Tests**: 23 tests (15 + 8)
- **Expected Behavior**: All tests should pass on first run

### Known Test Gaps
- No tests for password reset flow (deferred to next phase)
- Integration tests require database setup (documented in README)
```

**Advantages**:
1. /implement creates complete implementation (code + tests)
2. /test focuses on execution and debugging (single responsibility)
3. Summary documents what tests exist and how to run them
4. Clear handoff: /implement writes, /test runs

**Documentation Standard Needed**:
- Update testing-protocols.md: "Tests should be written during implementation phases"
- Add section: "Test Writing vs Test Execution Separation"
- Document test file naming conventions per language
- Add examples of test-writing tasks in plans

### 3. Test Execution Loops

#### Current test-executor Pattern (No Loop)

**test-executor Execution** (agents/test-executor.md lines 141-184):

```markdown
### STEP 3: Execute Tests

1. Setup execution environment
2. Execute test command with timeout
3. Capture execution metadata
4. Handle exit codes (0, 1, 124, 127)
5. Retry logic (if retry_on_failure=true):
   - Retry on exit codes: 1, 124
   - Max retries: 2
   - Retry delay: 5 seconds
   - Log each retry
6. Error classification

**Return**: TEST_COMPLETE (success or failure)
```

**Key Limitation**: Retries are for transient failures (flaky tests), not coverage improvement

#### Proposed Pattern: Coverage Loop in /test Command

**High-Level Flow**:

```
/test command:
  ITERATION = 1
  WHILE ITERATION <= MAX_TEST_ITERATIONS:
    1. Invoke test-executor
    2. Parse test results (passed, failed, coverage %)
    3. IF all_passed AND coverage >= threshold:
         BREAK (success)
    4. IF no_progress (coverage same as previous iteration):
         BREAK (stuck)
    5. Generate improvement hints (which modules need tests)
    6. Log iteration results
    7. ITERATION++

  IF success:
    Return TEST_COMPLETE
  ELSE:
    Invoke debug-analyst for failure analysis
```

**Implementation Pattern** (new Block in /test):

```markdown
## Block 2: Test Execution Loop

**EXECUTE NOW**: Run tests iteratively until coverage threshold met

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# Configuration
MAX_TEST_ITERATIONS=5
COVERAGE_THRESHOLD=80
ITERATION=1
PREVIOUS_COVERAGE=0
STUCK_COUNT=0

while [ $ITERATION -le $MAX_TEST_ITERATIONS ]; do
  echo "Test Iteration: $ITERATION/$MAX_TEST_ITERATIONS"

  # Calculate test output path for this iteration
  TEST_OUTPUT_PATH="${TOPIC_PATH}/outputs/test_results_iter${ITERATION}_$(date +%s).md"
  append_workflow_state "TEST_OUTPUT_PATH_ITER${ITERATION}" "$TEST_OUTPUT_PATH"

  # State transition (first iteration only)
  if [ $ITERATION -eq 1 ]; then
    sm_transition "$STATE_TEST" "starting test phase" || exit 1
  fi

  # Persist iteration state
  append_workflow_state "TEST_ITERATION" "$ITERATION"
  append_workflow_state "PREVIOUS_COVERAGE" "$PREVIOUS_COVERAGE"

  echo "Test output (iteration $ITERATION): $TEST_OUTPUT_PATH"
  break  # Continue to Block 3 (test-executor invocation)
done
```
```

**Block 3: test-executor Invocation** (modified from build.md lines 1229-1289):

```markdown
## Block 3: Test Execution [CRITICAL BARRIER]

**EXECUTE NOW**: Invoke test-executor for current iteration

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite (iteration ${ITERATION})"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/test-executor.md

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
        outputs: ${TOPIC_PATH}/outputs/
        debug: ${TOPIC_PATH}/debug/
    - test_config:
        test_command: null
        retry_on_failure: false
        coverage_threshold: ${COVERAGE_THRESHOLD}
    - output_path: ${TEST_OUTPUT_PATH}

    Execute per behavioral guidelines.
    Return: TEST_COMPLETE signal with coverage data
}
```

**Block 4: Test Results Verification and Loop Decision**:

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# Restore iteration state
source "$STATE_FILE"

# Verify test artifact exists
if [ ! -f "$TEST_OUTPUT_PATH" ]; then
  log_command_error "agent_error" \
    "test-executor failed to create test artifact" \
    "Expected: $TEST_OUTPUT_PATH"
  exit 1
fi

# Parse test results from artifact
TESTS_PASSED=$(grep "^- \*\*Passed\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //')
TESTS_FAILED=$(grep "^- \*\*Failed\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //')
COVERAGE=$(grep "^- \*\*Coverage\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //' | sed 's/%//')

# Handle N/A coverage
if [ "$COVERAGE" = "N/A" ]; then
  echo "WARNING: Coverage data not available, assuming 0%"
  COVERAGE=0
fi

echo "Test Results (Iteration $ITERATION):"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "  Coverage: ${COVERAGE}%"

# Check success criteria
ALL_PASSED=false
[ "$TESTS_FAILED" -eq 0 ] && ALL_PASSED=true

COVERAGE_MET=false
[ "$COVERAGE" -ge "$COVERAGE_THRESHOLD" ] && COVERAGE_MET=true

# Check for progress
COVERAGE_DELTA=$((COVERAGE - PREVIOUS_COVERAGE))
if [ "$COVERAGE_DELTA" -eq 0 ] && [ $ITERATION -gt 1 ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
else
  STUCK_COUNT=0
fi

# Decision logic
if [ "$ALL_PASSED" = "true" ] && [ "$COVERAGE_MET" = "true" ]; then
  echo "SUCCESS: All tests passed with ${COVERAGE}% coverage (≥${COVERAGE_THRESHOLD}%)"
  append_workflow_state "TEST_STATUS" "success"
  append_workflow_state "NEXT_STATE" "COMPLETE"
  # Exit loop - proceed to completion
  break
elif [ $STUCK_COUNT -ge 2 ]; then
  echo "WARNING: No coverage progress for 2 iterations, stopping loop"
  append_workflow_state "TEST_STATUS" "stuck"
  append_workflow_state "NEXT_STATE" "DEBUG"
  break
elif [ $ITERATION -ge $MAX_TEST_ITERATIONS ]; then
  echo "WARNING: Max iterations reached without meeting criteria"
  append_workflow_state "TEST_STATUS" "incomplete"
  append_workflow_state "NEXT_STATE" "DEBUG"
  break
else
  # Prepare for next iteration
  echo "Tests incomplete, preparing iteration $((ITERATION + 1))"

  # Generate improvement hints
  UNCOVERED_MODULES=$(grep "^## Coverage by Module" "$TEST_OUTPUT_PATH" -A 20 | grep "< ${COVERAGE_THRESHOLD}%" || echo "N/A")

  IMPROVEMENT_HINTS="Iteration $ITERATION incomplete:
- Coverage: ${COVERAGE}% (target: ${COVERAGE_THRESHOLD}%)
- Failed Tests: ${TESTS_FAILED}
- Modules needing tests:
${UNCOVERED_MODULES}

Next iteration should:
1. Add tests for uncovered modules
2. Fix failing tests
3. Aim for ${COVERAGE_THRESHOLD}% coverage"

  append_workflow_state "IMPROVEMENT_HINTS" "$IMPROVEMENT_HINTS"
  append_workflow_state "PREVIOUS_COVERAGE" "$COVERAGE"

  ITERATION=$((ITERATION + 1))
  # Loop back to Block 2 for next iteration
fi
```

**Key Design Decisions**:
1. Loop is in /test command (not test-executor agent)
2. Each iteration creates separate test artifact (audit trail)
3. Stuck detection: No coverage progress for 2 iterations
4. Max iterations: 5 (prevents infinite loops)
5. Success criteria: all_passed AND coverage ≥ threshold
6. Failure path: Invoke debug-analyst if loop exits without success

**Advantages**:
- Iterative improvement without manual intervention
- Clear audit trail (separate artifacts per iteration)
- Stuck detection prevents infinite loops
- Automatic transition to debug on failure

**Documentation Standard Needed**:
- Add testing-protocols.md section: "Test Execution Loops"
- Document coverage threshold configuration
- Document iteration limits and stuck detection
- Add examples of test loop scenarios

### 4. Existing Summary Pattern Analysis

#### implementer-coordinator Summary Format

**Source**: specs/004_todo_command_subagent_delegation/summaries/001-implementation-summary.md

**Current Sections**:
1. **Work Status**: Completion percentage (5/5 phases = 100%)
2. **Implementation Overview**: High-level description
3. **Completed Phases**: Per-phase deliverables, changes, artifacts
4. **Standards Compliance Achieved**: Compliance checklist
5. **Benefits Realized**: Impact analysis
6. **Technical Metrics**: Code changes, complexity increase
7. **Verification Evidence**: Agent capabilities validated
8. **Edge Cases Handled**: Corner case documentation
9. **Migration Path**: Backward compatibility notes
10. **Known Limitations**: Gaps and future work
11. **Testing Strategy**: Test coverage requirements ← KEY FOR /test
12. **Next Steps**: Follow-up actions

**Testing Strategy Section** (lines 549-581):

```markdown
## Testing Strategy

### Unit Tests (Agent)

**Test Cases**:
1. Classification Algorithm: Feed agent plan with each status value
2. Backlog Preservation: Provide TODO.md with Backlog content
3. Saved Preservation: Provide TODO.md with Saved content
4. Research Detection: Create test directory with reports/ but no plans/
5. Artifact Discovery: Create test directory with reports and summaries
6. 7-Section Generation: Verify all sections present
7. Checkbox Conventions: Verify correct checkboxes
8. Empty Input: Provide empty discovered projects

### Integration Tests (Command-Agent)

**Test Cases**:
1. End-to-End: Run /todo on test specs directory
2. Verification Failure: Corrupt agent output
3. Dry-Run Mode: Run /todo --dry-run
4. First Run: Delete TODO.md, run /todo
5. Migration: Provide 6-section TODO.md, run /todo
6. Backlog Modification: Manually modify Backlog
7. Atomic Replace: Verify backup created

### Regression Tests

**Test Cases**:
1. Clean Mode Integration: Verify /todo --clean still works
2. Research Auto-Detection: Verify research-only directories detected
3. Artifact Links: Verify reports and summaries linked correctly
```

**Key Insights**:
1. Testing Strategy section already exists (used by /build)
2. Provides test case enumeration (what to test)
3. Provides test organization (unit, integration, regression)
4. Does NOT provide test commands (test-executor auto-detects)

#### Proposed Summary Extension for /test

**Enhanced Testing Strategy Section**:

```markdown
## Testing Strategy

### Test Files Created
- tests/test_todo_analyzer.py (8 unit tests)
- tests/integration/test_todo_command.sh (7 integration tests)
- tests/regression/test_todo_backlog.sh (3 regression tests)

### Test Execution Requirements
- **Framework**: pytest (Python), bash (shell scripts)
- **Primary Command**: `python -m pytest -v --cov=.claude/agents --cov-report=term`
- **Secondary Command**: `bash .claude/tests/run_all_tests.sh`
- **Coverage Target**: ≥80% (agents/), ≥60% (commands/)
- **Expected Tests**: 18 total (8 unit + 7 integration + 3 regression)
- **Expected Duration**: ~45 seconds

### Test Coverage Requirements (from testing-protocols.md)
- All public APIs must have tests ✓
- Critical paths require integration tests ✓
- Regression tests for all bug fixes ✓

### Test Cases

#### Unit Tests (Agent)
1. Classification Algorithm: Feed agent plan with each status value, verify correct classification
2. Backlog Preservation: Provide TODO.md with Backlog content, verify exact preservation
[... rest of test cases ...]

### Known Test Gaps
- No performance tests for large TODO.md files (>1000 entries)
- No tests for concurrent /todo invocations (file locking)
- Agent behavioral compliance tests pending (tracking issue #123)
```

**Advantages**:
1. /test can extract test command from summary (if provided)
2. /test can validate expected test count vs actual
3. /test can use coverage targets from summary
4. Summary documents what was tested vs what should be tested (gaps)

**Documentation Standard Needed**:
- Add output-formatting.md section: "Testing Strategy Section Format"
- Document required fields: test_files_created, test_command, coverage_target
- Add examples of well-formed Testing Strategy sections

### 5. Documentation Standards Needed

#### Gap Analysis

**Current Documentation**:
- testing-protocols.md: Test discovery, frameworks, coverage requirements (150 lines)
- implementation-guide.md: Phase execution, agent selection (150 lines)
- command-authoring.md: Command structure, bash blocks (extensive)
- hard-barrier-subagent-delegation.md: Hard barrier pattern (extensive)

**Missing Documentation**:
1. **Implement-Test Workflow Standard**: How /implement and /test integrate
2. **Test Writing Responsibility Standard**: When/where tests are written
3. **Test Execution Loop Standard**: How coverage loops work
4. **Summary-Based Handoff Standard**: How summaries enable command chaining
5. **Coverage Configuration Standard**: How to set thresholds per project

#### Proposed Documentation Structure

**New File: .claude/docs/guides/workflows/implement-test-workflow.md**

```markdown
# Implement-Test Workflow Guide

## Overview

The implement-test workflow splits full implementation into two phases:
1. /implement: Code + test writing (no execution)
2. /test: Test execution + debugging loops

## Workflow Architecture

### Phase 1: Implementation (/implement)

**Command**: `/implement <plan-file> [starting-phase]`

**Responsibilities**:
- Execute implementation phases (code writing)
- Write tests during Testing phases
- Create implementation summary
- Terminal state: IMPLEMENT

**Output**:
- Implementation artifacts (code, configs, docs)
- Test files (but not executed)
- Summary file: {topic}/summaries/{NNN}-implementation-summary.md

**Example**:
```bash
/implement .claude/specs/042_auth/plans/001_auth_plan.md

# Creates:
# - src/auth.py (implementation)
# - tests/test_auth.py (tests, not run)
# - .claude/specs/042_auth/summaries/001-implementation-summary.md
```

### Phase 2: Testing (/test)

**Command**: `/test <plan-file> [--file <summary>]`

**Responsibilities**:
- Execute tests (via test-executor)
- Iterate until coverage ≥ threshold
- Debug test failures (via debug-analyst)
- Terminal state: COMPLETE

**Input**:
- Plan file (required)
- Summary file (optional, auto-discovered if not provided)

**Output**:
- Test results artifact(s): {topic}/outputs/test_results_*.md
- Debug report (if failures): {topic}/debug/{NNN}-debug-report.md

**Example**:
```bash
/test .claude/specs/042_auth/plans/001_auth_plan.md --file .claude/specs/042_auth/summaries/001-implementation-summary.md

# Runs:
# - Iteration 1: pytest → 12/15 passed, 60% coverage
# - Iteration 2: pytest → 15/15 passed, 85% coverage
# - Success (coverage ≥ 80%)
```

## Integration Patterns

### Pattern 1: Sequential Execution

```bash
# Step 1: Implement
/implement plan.md

# Step 2: Test (auto-discovers summary)
/test plan.md
```

### Pattern 2: Manual Summary Specification

```bash
# Step 1: Implement
/implement plan.md
# Returns: IMPLEMENTATION_COMPLETE summary_path: /path/to/summary.md

# Step 2: Test with explicit summary
/test --file /path/to/summary.md
```

### Pattern 3: Test-Only Execution

```bash
# Run tests without reimplementing (e.g., after manual fixes)
/test plan.md --file previous-summary.md
```

## Test Writing Responsibility

**Principle**: Tests are written DURING implementation, not during test execution.

### When to Write Tests

**During /implement**:
- Testing phases (phase name contains "Test")
- Test-writing tasks (task contains "write test", "add test")
- Coverage tasks (task contains "test coverage")

**Example Phase**:
```markdown
### Phase 3: Testing
**Tasks**:
- [ ] Write unit tests for auth module (target: 15 tests)
- [ ] Write integration tests for login flow (target: 8 tests)
- [ ] Add test fixtures for user creation
```

### Test File Conventions

**Python** (pytest):
- Location: tests/test_*.py
- Pattern: tests/test_{module_name}.py
- Fixtures: tests/conftest.py, tests/fixtures/

**JavaScript** (jest/vitest):
- Location: *.test.js, *.spec.js
- Pattern: {module_name}.test.js (adjacent to source)
- Fixtures: tests/fixtures/, __mocks__/

**Bash**:
- Location: tests/test_*.sh
- Pattern: tests/test_{feature}.sh
- Runner: .claude/tests/run_all_tests.sh

### Testing Strategy Section

**Summary should include**:
```markdown
## Testing Strategy

### Test Files Created
- tests/test_auth.py (15 unit tests)
- tests/test_login_flow.py (8 integration tests)

### Test Execution Requirements
- Framework: pytest
- Command: python -m pytest -v --cov=src
- Coverage Target: ≥80%
- Expected Tests: 23

### Known Test Gaps
- No tests for password reset (deferred)
```

## Test Execution Loops

**Principle**: /test iterates until coverage threshold met or stuck.

### Loop Configuration

**Environment Variables** (optional):
```bash
export TEST_COVERAGE_THRESHOLD=80  # Default: 80%
export TEST_MAX_ITERATIONS=5       # Default: 5
export TEST_STUCK_THRESHOLD=2      # Default: 2
```

**Per-Command Flags** (future):
```bash
/test plan.md --coverage-threshold 90 --max-iterations 10
```

### Loop Flow

```
Iteration 1:
  Run test-executor → Parse results → Check criteria
  Result: 60% coverage, 3 failed → CONTINUE

Iteration 2:
  Run test-executor → Parse results → Check criteria
  Result: 85% coverage, 0 failed → SUCCESS

Exit Loop:
  Return TEST_COMPLETE
```

### Exit Conditions

**Success** (break loop):
- All tests passed (failed = 0)
- Coverage ≥ threshold
- Return: TEST_COMPLETE, NEXT_STATE=COMPLETE

**Stuck** (break loop):
- No coverage progress for 2 iterations
- Return: TEST_COMPLETE, NEXT_STATE=DEBUG

**Max Iterations** (break loop):
- Iteration count ≥ MAX_TEST_ITERATIONS
- Return: TEST_COMPLETE, NEXT_STATE=DEBUG

### Iteration Artifacts

Each iteration creates separate artifact:
```
{topic}/outputs/test_results_iter1_{timestamp}.md
{topic}/outputs/test_results_iter2_{timestamp}.md
{topic}/outputs/test_results_iter3_{timestamp}.md
```

**Audit trail**: Review all iterations to understand coverage improvement

## Summary-Based Handoff

**Principle**: Summary file is the contract between /implement and /test.

### Summary as Contract

**Producer** (/implement):
- Creates summary at {topic}/summaries/{NNN}-{slug}.md
- Returns summary_path in IMPLEMENTATION_COMPLETE signal
- Includes Testing Strategy section with test requirements

**Consumer** (/test):
- Reads summary file (via --file or auto-discovery)
- Extracts plan_path, topic_path from summary metadata
- Uses Testing Strategy for test execution context

### Auto-Discovery Pattern

If /test invoked without --file:
1. Derive topic_path from plan_path: dirname(dirname(plan_path))
2. Find latest summary: find {topic_path}/summaries -name "*.md" | sort | tail -1
3. Use latest summary if found
4. Otherwise: Proceed without summary (use plan only)

### Summary Metadata Format

```markdown
# {Feature Name} - Implementation Summary

## Metadata
- **Date**: 2025-12-01
- **Plan**: /path/to/plan.md
- **Topic**: /path/to/topic/
- **Phases Completed**: 5/5 (100%)

[... rest of summary ...]
```

**Extraction**:
```bash
PLAN_FILE=$(grep "^- \*\*Plan\*\*:" "$SUMMARY_FILE" | sed 's/.*: //')
TOPIC_PATH=$(grep "^- \*\*Topic\*\*:" "$SUMMARY_FILE" | sed 's/.*: //')
```

## Coverage Configuration

**Project-Level Defaults** (CLAUDE.md):

```markdown
## Testing Protocols

### Coverage Requirements
- Python: ≥80% (pytest --cov)
- JavaScript: ≥80% (jest --coverage)
- Bash: ≥60% (.claude/tests/)

### Test Commands
- Python: python -m pytest -v --cov=src --cov-report=term
- JavaScript: npm test -- --coverage
- Bash: bash .claude/tests/run_all_tests.sh
```

**Per-Plan Overrides** (plan file metadata):

```markdown
## Metadata
- **Coverage Threshold**: 90%
- **Test Timeout**: 10 minutes
```

**Command-Line Overrides** (future):

```bash
/test plan.md --coverage-threshold 90
```

## Error Handling

### /implement Failures

**Agent Error** (implementer-coordinator fails):
- Error logged to error log
- Return: IMPLEMENTATION_ERROR
- Recovery: /errors --command /implement → /repair

**Verification Failure** (summary not created):
- Hard barrier fails
- Error logged with recovery hints
- Return: exit 1
- Recovery: Fix agent, retry /implement

### /test Failures

**Test Execution Error** (test-executor fails):
- Error logged to error log
- Return: TEST_ERROR
- Recovery: /errors --command /test → /repair

**Coverage Loop Stuck**:
- No progress for 2 iterations
- Invoke debug-analyst for analysis
- Return: TEST_COMPLETE, NEXT_STATE=DEBUG

**All Tests Fail**:
- Invoke debug-analyst for root cause
- Return: TEST_COMPLETE, NEXT_STATE=DEBUG

## See Also

- [Testing Protocols](.claude/docs/reference/standards/testing-protocols.md)
- [Command Authoring](.claude/docs/reference/standards/command-authoring.md)
- [Hard Barrier Pattern](.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [Build Command Guide](.claude/docs/guides/commands/build-command-guide.md)
```

**File Size**: ~350 lines (comprehensive workflow guide)

#### Proposed Updates to Existing Documentation

**testing-protocols.md Additions**:

```markdown
## Test Writing Responsibility

**Principle**: Tests are written during implementation phases, not during test execution.

### When to Write Tests
- Testing phases (phase name contains "Test")
- Test-writing tasks (explicit in task list)
- Coverage tasks (improving test coverage)

### Test File Conventions
[... language-specific patterns ...]

### Test Execution Loops

**Coverage Loop Pattern**: /test command iterates until coverage threshold met.

**Configuration**:
- Coverage threshold: 80% (default)
- Max iterations: 5 (default)
- Stuck threshold: 2 iterations without progress

**Exit Conditions**:
- Success: All passed + coverage ≥ threshold
- Stuck: No progress for 2 iterations
- Max iterations: Iteration count exceeded

### Summary-Based Test Execution

**Testing Strategy Section** (required in implementation summaries):
```markdown
## Testing Strategy
### Test Files Created
[List of test files]

### Test Execution Requirements
- Framework: {detected_framework}
- Command: {test_command}
- Coverage Target: {threshold}%
```
```

**command-authoring.md Additions**:

```markdown
## Command Integration Patterns

### Summary-Based Handoff

Commands can chain via summary files:

**Producer Command** (e.g., /implement):
- Creates summary at pre-calculated path
- Returns summary_path in completion signal
- Includes metadata for downstream commands

**Consumer Command** (e.g., /test):
- Accepts --file flag for summary path
- Auto-discovers latest summary if --file not provided
- Extracts context from summary metadata

**Example**:
```bash
# Producer
/implement plan.md
# Returns: IMPLEMENTATION_COMPLETE summary_path: /path/to/summary.md

# Consumer (explicit)
/test --file /path/to/summary.md

# Consumer (auto-discovery)
/test plan.md  # Discovers summary automatically
```
```

**output-formatting.md Additions**:

```markdown
## Testing Strategy Section Format

Implementation summaries MUST include a Testing Strategy section:

**Required Fields**:
- Test Files Created: List of test files with counts
- Test Execution Requirements: Framework, command, coverage target
- Expected Tests: Total expected test count
- Known Test Gaps: Incomplete coverage areas

**Example**:
```markdown
## Testing Strategy

### Test Files Created
- tests/test_auth.py (15 unit tests)
- tests/test_login_flow.py (8 integration tests)

### Test Execution Requirements
- Framework: pytest
- Command: python -m pytest -v --cov=src
- Coverage Target: ≥80%
- Expected Tests: 23

### Known Test Gaps
- No tests for password reset flow
```
```

## Implementation Recommendations

### Phase 0: Standards Documentation (Prerequisite)

**Deliverables**:
1. Create .claude/docs/guides/workflows/implement-test-workflow.md (~350 lines)
2. Update .claude/docs/reference/standards/testing-protocols.md (+50 lines)
3. Update .claude/docs/reference/standards/command-authoring.md (+30 lines)
4. Update .claude/docs/reference/standards/output-formatting.md (+20 lines)
5. Update CLAUDE.md section: project_commands (add /implement, /test references)

**Rationale**: Standards must exist before implementation to guide development

### Phase 1-3: /implement Command

**Summary Integration**:
- Block 1c: Verify summary includes Testing Strategy section
- Block 2: Return IMPLEMENTATION_COMPLETE with summary_path
- Completion signal: Include next_command="/test {PLAN_FILE}"

**No Changes Needed**:
- implementer-coordinator already creates summaries
- Summary format already supports Testing Strategy
- Hard barrier pattern already validates summary existence

### Phase 4-5: /test Command

**Argument Capture**:
- Add --file flag parsing (following debug.md pattern)
- Add auto-discovery logic (find latest summary)
- Extract plan_path from summary if --file provided

**Test Execution Loop**:
- Block 2: Loop initialization (iteration, thresholds)
- Block 3: test-executor invocation (CRITICAL BARRIER)
- Block 4: Results verification + loop decision
- Loop exit: Success, stuck, or max iterations

**Coverage Threshold Configuration**:
- Default: 80% (testing-protocols.md)
- Override: Read from plan metadata (future)
- Override: --coverage-threshold flag (future)

### Phase 6: Testing and Validation

**Integration Tests**:
1. /implement → /test (sequential execution)
2. /test --file summary.md (manual handoff)
3. /test plan.md (auto-discovery)
4. Coverage loop (multiple iterations to threshold)
5. Stuck detection (no progress for 2 iterations)

**End-to-End Test**:
```bash
# Create test plan with Testing phase
cat > test-plan.md <<EOF
### Phase 1: Implementation
- [ ] Implement auth module

### Phase 2: Testing
- [ ] Write unit tests (target: 15)
- [ ] Write integration tests (target: 8)
EOF

# Run /implement
/implement test-plan.md
# Verify: tests written, summary created

# Run /test
/test test-plan.md
# Verify: tests executed, coverage ≥ 80%, TEST_COMPLETE
```

### Phase 7: Documentation Finalization

**Command Guides**:
1. Create .claude/docs/guides/commands/implement-command-guide.md
2. Create .claude/docs/guides/commands/test-command-guide.md
3. Update .claude/docs/guides/commands/build-command-guide.md (deprecation notice)

**Reference Updates**:
1. Update .claude/docs/reference/standards/command-reference.md (add /implement, /test)
2. Create .claude/docs/guides/migration/build-to-implement-test.md

## Risk Analysis

### High Risk

**Coverage Loop Infinite Loops**:
- Risk: Loop never exits (test failures persist)
- Mitigation: Max iterations (5), stuck detection (2 iterations), fail-fast to debug
- Validation: Integration test with intentional test failures

**Summary Auto-Discovery Failures**:
- Risk: No summary found, /test cannot proceed
- Mitigation: Graceful fallback (use plan only), clear error messages
- Validation: Test /test without prior /implement run

### Medium Risk

**Test Writing Clarity**:
- Risk: Users unclear when to write tests (in /implement vs /test)
- Mitigation: Comprehensive documentation, examples in guides
- Validation: User testing with new developers

**Coverage Threshold Configuration**:
- Risk: Hardcoded 80% threshold not suitable for all projects
- Mitigation: Document override mechanisms (CLAUDE.md, plan metadata)
- Future: Add --coverage-threshold flag

### Low Risk

**Summary Format Changes**:
- Risk: Breaking changes to summary format
- Mitigation: Summary format already established, minimal changes needed
- Validation: Existing summaries already include Testing Strategy

## Success Criteria

**Documentation**:
- [ ] implement-test-workflow.md created (~350 lines)
- [ ] testing-protocols.md updated (+50 lines)
- [ ] command-authoring.md updated (+30 lines)
- [ ] output-formatting.md updated (+20 lines)

**Integration**:
- [ ] /implement creates summary with Testing Strategy section
- [ ] /test accepts --file flag for summary path
- [ ] /test auto-discovers summary from plan path
- [ ] /test extracts test requirements from summary

**Test Execution**:
- [ ] /test runs test-executor in loop until coverage ≥ threshold
- [ ] Loop exits on success (all passed + coverage met)
- [ ] Loop exits on stuck (no progress for 2 iterations)
- [ ] Loop exits on max iterations (5 default)

**Error Handling**:
- [ ] /test invokes debug-analyst on test failures
- [ ] Error logging integration verified via /errors command
- [ ] Clear error messages for missing summaries

**Validation**:
- [ ] Integration test: /implement → /test (sequential)
- [ ] Integration test: /test --file summary.md (manual handoff)
- [ ] Integration test: /test plan.md (auto-discovery)
- [ ] Integration test: Coverage loop (multiple iterations)
- [ ] Integration test: Stuck detection (no progress)

## Conclusion

The implement-test integration patterns are well-supported by existing infrastructure:

1. **Summary-based handoff**: implementer-coordinator already returns summary_path in IMPLEMENTATION_COMPLETE signal; summary format supports test requirements via Testing Strategy section
2. **Test writing responsibility**: Tests should be written during /implement (by implementation-executor in Testing phases); /test focuses on execution only
3. **Test execution loops**: /test should implement coverage loop (iterate until threshold met, stuck, or max iterations)
4. **Existing summary pattern**: Already includes Testing Strategy section; minor enhancements needed (test file counts, expected tests)
5. **Documentation standards**: Comprehensive documentation needed for implement-test workflow, test-writing responsibility, coverage loops, summary-based handoff

**Key Recommendation**: Prioritize Phase 0 (standards documentation) before implementation. Standards-first development ensures consistency and prevents rework.

**Next Steps**:
1. Review this research report with plan revision context
2. Update plan Phase 0 with documentation deliverables
3. Proceed with /implement and /test command development per plan
4. Validate integration via end-to-end testing
