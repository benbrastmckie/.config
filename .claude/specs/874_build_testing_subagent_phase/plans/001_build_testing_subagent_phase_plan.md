# Build Testing Subagent Phase Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Testing Subagent Integration for /build Command
- **Scope**: Create test-executor subagent and integrate into /build command Block 2 following hierarchical agent patterns
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Complexity Score**: 44
- **Structure Level**: 0 (single file plan)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Research Reports**:
  - [Testing Subagent Research](../reports/001_testing_subagent_research.md)

## Overview

The /build command currently executes testing inline in Block 2 (lines 536-736) using basic bash test discovery and execution. This plan implements a dedicated test-executor subagent following established patterns from implementer-coordinator and debug-analyst agents, achieving isolation, structured error handling, and hierarchical agent architecture compliance.

**Goals**:
1. Create test-executor subagent with framework detection and structured output
2. Integrate subagent into /build Block 2 using Task tool invocation pattern
3. Follow behavioral injection pattern for path pre-calculation
4. Implement error return protocol matching existing agents
5. Create test result artifacts in outputs/ directory for context efficiency

## Research Summary

Research findings from testing subagent analysis:

**Current /build Testing Issues** (from research report):
- No isolation: tests run in command bash block risking state pollution
- Limited error context: only exit code captured, no structured analysis
- No retry logic: single execution attempt without intelligent failure handling
- Manual test selection: basic pattern matching instead of framework-specific detection
- No test result artifact: output stored in bash variables, not pruned

**Existing Subagent Patterns** (implementer-coordinator, debug-analyst):
- Model selection: haiku-4.5 for deterministic orchestration
- File creation protocol: Create artifact at pre-calculated path BEFORE investigation
- Completion signals: Structured YAML/JSON with metadata only
- Error return protocol: ERROR_CONTEXT JSON + TASK_ERROR signal
- Metadata-only passing: 99% context reduction through artifact files

**Key Utilities Available**:
- detect-testing.sh: Score-based framework detection (pytest, jest, vitest, plenary, bash)
- checkbox-utils.sh: Plan hierarchy update functions
- error-handling.sh: Centralized error logging with environment detection

**Recommended Approach**:
Create test-executor.md agent following implementer-coordinator pattern (haiku-4.5 model), using detect-testing.sh for framework discovery, creating structured test reports in outputs/ directory, and returning metadata-only completion signals. Integrate via Task tool in /build Block 2 replacing inline test execution (lines 679-715).

## Success Criteria

- [ ] test-executor.md agent created with complete behavioral guidelines
- [ ] Agent uses haiku-4.5 model for deterministic execution
- [ ] Agent integrates detect-testing.sh utility for framework detection
- [ ] Agent creates structured test result artifacts in outputs/ directory
- [ ] Agent returns TEST_COMPLETE signal with metadata only
- [ ] Agent implements error return protocol (ERROR_CONTEXT + TASK_ERROR)
- [ ] /build Block 2 modified to invoke test-executor via Task tool
- [ ] /build Block 2 parses test-executor response for state persistence
- [ ] /build Block 2 extracts metadata from test artifact (not full output)
- [ ] Test suite created for test-executor behavioral compliance
- [ ] Integration tests verify /build → test-executor → state persistence workflow
- [ ] Documentation updated with testing subagent architecture

## Technical Design

### Architecture Overview

```
/build Command Block 2
    ↓ [Task tool invocation]
test-executor subagent
    ↓ [framework detection]
detect-testing.sh utility
    ↓ [test execution]
Test Framework (pytest/jest/plenary/bash)
    ↓ [structured report]
outputs/test_results_NNN.md
    ↓ [metadata extraction]
/build state persistence
```

### Agent Design: test-executor.md

**Model**: haiku-4.5 (deterministic test execution, similar to implementer-coordinator)

**Input Format**:
```yaml
plan_path: /path/to/plan.md
topic_path: /path/to/specs/NNN_topic/
artifact_paths:
  outputs: /path/to/specs/NNN_topic/outputs/
  debug: /path/to/specs/NNN_topic/debug/
test_config:
  test_command: null  # null for auto-detection
  retry_on_failure: false
  isolation_mode: true
  max_retries: 2
output_path: /path/to/outputs/test_results_TIMESTAMP.md  # Pre-calculated by command
```

**Output Format**:
```yaml
TEST_COMPLETE:
  status: "passed"|"failed"|"skipped"
  tests_run: N
  tests_passed: N
  tests_failed: N
  test_output_path: /path/to/outputs/test_results_NNN.md
  failed_tests: [list if status=failed]
  exit_code: N
  execution_time: "Xm Ys"
```

**STEP Execution Sequence**:
1. STEP 1: Create test output artifact at provided path (before execution)
2. STEP 2: Detect test framework using detect-testing.sh utility
3. STEP 3: Execute tests with isolation and capture output
4. STEP 4: Parse test results and extract failures
5. STEP 5: Update artifact with full results
6. STEP 6: Return TEST_COMPLETE signal with metadata only

**Error Return Protocol**:
```yaml
ERROR_CONTEXT: {
  "error_type": "execution_error|validation_error|dependency_error|timeout_error",
  "message": "Brief error description",
  "details": {context object}
}

TASK_ERROR: {error_type} - {error_message}
```

### /build Block 2 Integration

**Current Structure** (lines 536-736):
- Lines 536-677: State loading and validation
- Lines 679-715: **Inline test execution (TO BE REPLACED)**
- Lines 717-736: State persistence

**New Structure**:
- Lines 536-677: State loading and validation (unchanged)
- Lines 679-690: **Task tool invocation of test-executor**
- Lines 691-715: **Parse test-executor response and extract metadata**
- Lines 717-736: State persistence (unchanged)

**Key Changes**:
1. Pre-calculate test output path before Task invocation
2. Invoke test-executor with complete context (plan, topic, paths, config)
3. Parse TEST_COMPLETE signal from agent response
4. Extract metadata from test artifact file (not agent response)
5. Persist TESTS_PASSED, TEST_EXIT_CODE to state
6. On error: Parse ERROR_CONTEXT and log via parse_subagent_error()

### Test Result Artifact Structure

```markdown
# Test Execution Report

## Metadata
- **Date**: YYYY-MM-DD HH:MM:SS
- **Plan**: specs/NNN_topic/plans/NNN_plan.md
- **Test Framework**: pytest|jest|plenary|bash
- **Test Command**: npm test
- **Exit Code**: 0|1
- **Execution Time**: 2m 34s
- **Environment**: test|production

## Summary
- **Total Tests**: 145
- **Passed**: 142
- **Failed**: 3
- **Skipped**: 0
- **Coverage**: 87%

## Failed Tests
1. tests/auth.test.js:45 - Token validation fails for expired tokens
2. tests/auth.test.js:67 - Refresh token rotation broken
3. tests/api.test.js:123 - Rate limiting not enforced

## Full Output
```
[complete test output with ANSI codes preserved]
```
```

**Context Efficiency**:
- Metadata: ~200 tokens (status, counts, failures)
- Full output: ~5000 tokens (stored in file)
- Reduction: 96% (command only reads metadata)

## Implementation Phases

### Phase 1: Test-Executor Agent Creation [COMPLETE]
dependencies: []

**Objective**: Create test-executor.md agent with complete behavioral guidelines following established patterns

**Complexity**: Medium

**Tasks**:
- [x] Create `/home/benjamin/.config/.claude/agents/test-executor.md` with frontmatter
  - Model: haiku-4.5
  - Allowed tools: Read, Bash, Grep, Glob
  - Description: Execute test suites with framework detection and structured reporting
- [x] Document STEP 1: Create test output artifact at pre-calculated path
- [x] Document STEP 2: Detect test framework using detect-testing.sh utility
  - Integration pattern: `bash /path/to/detect-testing.sh "$PROJECT_DIR"`
  - Parse JSON output for framework and test command
- [x] Document STEP 3: Execute tests with isolation and retry logic
  - Isolation: Execute in project directory with proper environment
  - Retry: Optional retry on transient failures (exit code 1, 124)
  - Capture: Full stdout/stderr with timestamps
- [x] Document STEP 4: Parse test results and extract failures
  - Framework-specific parsing: pytest JSON, jest JSON, plenary output
  - Extract: Test counts, failed test details, coverage data
- [x] Document STEP 5: Update artifact with structured results
  - Use Edit tool to update artifact with summary and full output
- [x] Document STEP 6: Return TEST_COMPLETE signal with metadata only
  - Format: YAML with status, counts, path, execution_time
  - No full output in signal (stored in artifact)
- [x] Document error return protocol
  - Error types: execution_error, validation_error, dependency_error, timeout_error
  - Return format: ERROR_CONTEXT JSON + TASK_ERROR signal
- [x] Add completion criteria checklist (following plan-architect pattern)
  - [x] Artifact created at pre-calculated path
  - [x] TEST_COMPLETE signal returned in correct format
  - [x] Metadata only in signal (no full output)
  - [x] Error protocol implemented for all failure cases

**Testing**:
```bash
# Unit test: Verify agent behavioral file structure
.claude/tests/test_agent_behavioral_compliance.sh test-executor

# Integration test: Invoke agent with mock plan
bash -c 'source .claude/lib/core/test-helpers.sh && test_agent_invocation test-executor'
```

**Expected Duration**: 3 hours

### Phase 2: detect-testing.sh Integration [COMPLETE]
dependencies: [1]

**Objective**: Integrate detect-testing.sh utility into test-executor for automatic framework detection

**Complexity**: Low

**Tasks**:
- [x] Review `/home/benjamin/.config/.claude/lib/util/detect-testing.sh` implementation
  - Understand score-based detection algorithm
  - Review framework detection patterns (pytest, jest, vitest, mocha, plenary)
  - Understand JSON output format
- [x] Document utility invocation pattern in test-executor.md STEP 2
  - Command: `bash /path/to/detect-testing.sh "$PROJECT_DIR" 2>/dev/null`
  - Parse JSON: `jq -r '.framework'` and `jq -r '.test_command'`
  - Fallback: If detection fails, check plan file for test commands
- [x] Add error handling for detection failures
  - Log dependency_error if no framework detected
  - Return TASK_ERROR with details (frameworks_checked, project_dir)
- [x] Document test command override capability
  - If test_config.test_command provided, skip detection
  - Validate provided command exists and is executable

**Testing**:
```bash
# Test framework detection across projects
.claude/tests/test_framework_detection.sh

# Verify test-executor uses detection utility
.claude/tests/test_test_executor_detection.sh
```

**Expected Duration**: 1.5 hours

### Phase 3: /build Block 2 Integration [COMPLETE]
dependencies: [1, 2]

**Objective**: Modify /build Block 2 to invoke test-executor subagent via Task tool

**Complexity**: High

**Tasks**:
- [x] Read current `/home/benjamin/.config/.claude/commands/build.md` Block 2 (lines 536-736)
- [x] Replace inline test execution (lines 679-715) with Task tool invocation
  - Pre-calculate test output path: `${TOPIC_PATH}/outputs/test_results_$(date +%s).md`
  - Construct Task tool prompt with complete context:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - artifact_paths: outputs, debug directories
    - test_config: {test_command: null, retry_on_failure: false, isolation_mode: true}
    - output_path: pre-calculated path
  - Include behavioral injection: "Read and follow behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md"
- [x] Add test-executor response parsing after Task tool invocation
  - Extract TEST_COMPLETE signal from agent output
  - Parse status, exit_code, test_output_path from signal
  - Validate artifact file exists at reported path
- [x] Add metadata extraction from test artifact (not agent response)
  - Use grep/sed to extract Summary section metadata
  - Extract: TESTS_PASSED, TESTS_FAILED, TEST_EXIT_CODE
  - Store in bash variables for state persistence
- [x] Add error handling for test-executor failures
  - Check for ERROR_CONTEXT in agent response
  - Use parse_subagent_error() to log error via error-handling.sh
  - Set TESTS_PASSED=false and continue to Block 3 debug phase
- [x] Update state persistence section (lines 717-736)
  - Persist: TESTS_PASSED, TEST_COMMAND, TEST_EXIT_CODE, TEST_OUTPUT_PATH
  - Ensure state saved before Block 3 execution

**Testing**:
```bash
# Integration test: /build with test-executor
.claude/tests/test_build_testing_phase.sh

# Verify state persistence after testing phase
.claude/tests/test_build_state_persistence.sh
```

**Expected Duration**: 4 hours

### Phase 4: Error Handling and Retry Logic [COMPLETE]
dependencies: [3]

**Objective**: Implement robust error handling and optional retry logic in test-executor

**Complexity**: Medium

**Tasks**:
- [x] Implement error classification in test-executor STEP 3
  - execution_error: Test command failed to execute (command not found, permission denied)
  - timeout_error: Test execution exceeded time limit (default: 30 minutes)
  - dependency_error: Test framework not installed or misconfigured
  - validation_error: Invalid test configuration provided
- [x] Add retry logic for transient failures (optional, controlled by test_config)
  - Retry on exit codes: 1 (test failure), 124 (timeout)
  - Max retries: test_config.max_retries (default: 2)
  - Retry delay: 5 seconds between attempts
  - Log each retry attempt to test artifact
- [x] Implement timeout mechanism
  - Use `timeout` command with configurable duration
  - Default: 30 minutes for test execution
  - Log timeout_error if exceeded
- [x] Add error context enrichment
  - Capture stderr preview (first 500 chars)
  - Include test command, exit code, execution time
  - Log to centralized error log via log_command_error()
- [x] Update test artifact on error
  - Add Error section with error type, message, context
  - Include troubleshooting steps based on error type
  - Mark status as "failed" with error details

**Testing**:
```bash
# Test error scenarios
.claude/tests/test_test_executor_errors.sh

# Verify retry logic
.claude/tests/test_test_executor_retry.sh

# Verify timeout handling
.claude/tests/test_test_executor_timeout.sh
```

**Expected Duration**: 2.5 hours

### Phase 5: Testing and Documentation [COMPLETE]
dependencies: [4]

**Objective**: Create comprehensive test suite and update documentation

**Complexity**: Low

**Tasks**:
- [x] Create `/home/benjamin/.config/.claude/tests/test_test_executor_behavioral_compliance.sh`
  - Test file creation at pre-calculated path
  - Test TEST_COMPLETE signal format validation
  - Test STEP execution sequence (verify each STEP checkpoint)
  - Test metadata-only return (no full output in signal)
  - Test error protocol (ERROR_CONTEXT + TASK_ERROR format)
- [x] Create `/home/benjamin/.config/.claude/tests/test_build_testing_integration.sh`
  - Test /build → test-executor → state persistence workflow
  - Test metadata extraction from artifact file
  - Test error path: failed tests → debug phase transition
  - Test success path: passed tests → documentation phase transition
- [x] Create `/home/benjamin/.config/.claude/tests/test_test_executor_framework_support.sh`
  - Test pytest framework detection and execution
  - Test jest framework detection and execution
  - Test plenary framework detection and execution
  - Test bash test script detection and execution
- [x] Update `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`
  - Add test-executor to agent hierarchy examples
  - Document testing subagent pattern
  - Add diagram: /build → test-executor → test artifact
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md`
  - Document testing phase subagent invocation
  - Add test result artifact structure
  - Add troubleshooting: test-executor errors
- [x] Create `/home/benjamin/.config/.claude/docs/guides/development/agent-development/test-executor-pattern.md`
  - Document test-executor agent pattern
  - Include framework detection integration
  - Include test artifact structure and metadata extraction
  - Add example invocation from /build command

**Testing**:
```bash
# Run full test suite
./.claude/run_all_tests.sh

# Verify test coverage
bash .claude/scripts/check_test_coverage.sh
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Tests

**Test-Executor Agent Behavioral Compliance**:
- File creation: Verify artifact created at exact pre-calculated path
- Signal format: Validate TEST_COMPLETE YAML structure
- STEP sequence: Confirm agent follows documented STEP order
- Error protocol: Verify ERROR_CONTEXT + TASK_ERROR on failures

**Framework Detection**:
- Pytest detection: Verify pytest.ini, setup.py, conftest.py detection
- Jest detection: Verify package.json test script detection
- Plenary detection: Verify lua test files and plenary.nvim
- Bash detection: Verify .claude/run_all_tests.sh discovery

### Integration Tests

**/build → test-executor Workflow**:
- Success path: Tests pass → documentation phase
- Failure path: Tests fail → debug phase
- State persistence: Verify TEST_PASSED, TEST_EXIT_CODE persisted
- Metadata extraction: Confirm only metadata read from artifact

**Error Scenarios**:
- Framework not detected: Verify dependency_error logged
- Test timeout: Verify timeout_error and retry attempt
- Test command not found: Verify execution_error logged
- Invalid configuration: Verify validation_error returned

### Test Isolation

All tests must follow testing-protocols.md isolation standards:
- Environment: Set CLAUDE_SPECS_ROOT to temporary directory
- Cleanup: Trap EXIT to remove temporary artifacts
- No pollution: Never write to production specs/ directory

**Test Environment Variables**:
```bash
export CLAUDE_SPECS_ROOT="${TMPDIR:-/tmp}/claude_test_$$"
export CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
export TESTING=1  # Signals error-handling.sh to use test log
```

## Documentation Requirements

### New Documentation

1. **test-executor-pattern.md**: Agent pattern guide
   - Location: `.claude/docs/guides/development/agent-development/`
   - Content: Framework detection, test execution, artifact structure
   - Examples: Invocation from /build, error handling

### Updated Documentation

1. **hierarchical-agents.md**: Add test-executor example
   - Section: Agent Hierarchy Levels
   - Content: Level 1 agent for testing phase

2. **build-command-guide.md**: Document testing subagent
   - Section: Testing Phase Architecture
   - Content: Task tool invocation, artifact structure, troubleshooting

3. **testing-protocols.md**: Reference test-executor
   - Section: Test Discovery
   - Content: Automatic framework detection via test-executor

## Dependencies

### External Dependencies

1. **detect-testing.sh**: Framework detection utility (already exists)
2. **error-handling.sh**: Error logging library (already exists)
3. **checkbox-utils.sh**: Plan update utilities (already exists)

### Library Requirements

- workflow-state-machine.sh: >=2.0.0 (already required by /build)
- state-persistence.sh: >=1.5.0 (already required by /build)

### Test Framework Dependencies

- pytest: For Python projects
- jest/vitest: For JavaScript/TypeScript projects
- plenary.nvim: For Neovim Lua projects
- bash: For .claude test scripts

**Note**: Test frameworks are optional dependencies. If not installed, test-executor will skip testing gracefully or report dependency_error.

## Risk Mitigation

### Risk: Test-executor failures block /build workflow

**Mitigation**:
- Graceful degradation: If test-executor fails, log error and continue to debug phase
- Fallback: /build can detect test-executor ERROR_CONTEXT and treat as test failure
- State persistence: TEST_PASSED=false allows Block 3 to proceed normally

### Risk: Framework detection false positives

**Mitigation**:
- Score-based detection: Requires multiple indicators (>3 points) for framework match
- Manual override: test_config.test_command allows explicit test command
- Validation: Test command existence checked before execution

### Risk: Test artifacts consume excessive disk space

**Mitigation**:
- Rotation: Implement log rotation for test artifacts (keep last 10 per topic)
- Cleanup: Add cleanup script to remove artifacts older than 30 days
- Compression: Consider gzip compression for archived test results

### Risk: Test execution timeouts in CI environments

**Mitigation**:
- Configurable timeout: Default 30 minutes, adjustable via test_config
- Early termination: Test-executor monitors execution and terminates on timeout
- Retry logic: Transient timeouts trigger automatic retry

## Rollback Plan

If test-executor integration causes /build failures:

1. **Immediate**: Comment out Task tool invocation in /build Block 2
2. **Restore**: Uncomment original inline test execution (lines 679-715)
3. **Verify**: Run /build with existing plans to confirm functionality
4. **Debug**: Review test-executor error logs in `.claude/data/logs/errors.jsonl`
5. **Fix**: Address test-executor issues in isolated environment
6. **Re-integrate**: Restore Task tool invocation after fixes verified

**Rollback Test**:
```bash
# Verify /build works with inline testing
git show HEAD:~1:.claude/commands/build.md > /tmp/build_rollback.md
# Test with rollback version
```

## Notes

**Progressive Enhancement**: This plan creates a Tier 1 (single file) structure. If complexity grows during implementation, use `/expand` to create phase-specific files.

**Context Efficiency**: Test-executor pattern achieves 96% context reduction by storing full test output in artifacts and returning only metadata (status + counts + path) to /build command.

**Compliance**: All phases include behavioral compliance verification following testing-protocols.md standards and plan-architect completion criteria.
