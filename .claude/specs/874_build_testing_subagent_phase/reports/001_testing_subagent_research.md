# Testing Subagent Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: /build command testing phase and subagent patterns
- **Report Type**: codebase analysis

## Executive Summary

The /build command currently executes testing inline (Block 2, lines 536-736) using bash scripts to detect and run tests. Analysis of existing subagent patterns shows the implementer-coordinator and debug-analyst agents provide clear templates for testing subagent implementation. A testing subagent would improve isolation, enable test-specific error handling, and align with hierarchical agent architecture principles for context reduction and parallel execution support.

## Findings

### Current /build Testing Implementation

**Location**: `/home/benjamin/.config/.claude/commands/build.md:536-736` (Block 2)

**Current Approach**:
1. **Test Discovery** (lines 680-692): Uses inline bash logic to detect test commands
   - Searches plan file for test commands: `npm test`, `pytest`, `./.claude/run_all_tests.sh`, `:TestSuite`
   - Falls back to detecting test frameworks by file presence (package.json, pytest.ini, .claude/run_all_tests.sh)
   - Default test command determined from project structure

2. **Test Execution** (lines 694-715): Runs tests directly in bash block
   - Executes discovered test command
   - Captures exit code and output
   - Sets TESTS_PASSED boolean based on exit code

3. **State Persistence** (lines 717-735): Stores test results in workflow state
   - Persists: TESTS_PASSED, TEST_COMMAND, TEST_EXIT_CODE, COMMIT_COUNT
   - Used by Block 3 for conditional debug/documentation branching

**Issues with Current Approach**:
- **No Isolation**: Test execution happens in command bash block, risks state pollution
- **Limited Error Context**: Only captures exit code and raw output, no structured error analysis
- **No Retry Logic**: Single test execution attempt, no intelligent retry on transient failures
- **Poor Context Management**: Full test output stored in bash variable, not pruned
- **Manual Test Selection**: Basic pattern matching, doesn't leverage framework-specific features
- **No Test Result Artifact**: Test output not written to structured report file

### Existing Subagent Patterns for Comparison

#### Implementer-Coordinator Pattern

**Location**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Key Characteristics** (lines 1-578):
- **Model**: haiku-4.5 (deterministic orchestration)
- **Role**: Orchestrates wave-based parallel phase execution
- **Invocation Pattern**:
  - Receives pre-calculated paths (topic_path, artifact_paths)
  - Uses Task tool for parallel subagent invocation
  - Collects structured completion reports from executors
  - Aggregates results and returns summary

**Error Handling** (lines 249-280):
- Marks failed phases in state with error summaries
- Continues independent work after failure
- Reports failures to orchestrator for debug phase
- No automatic retry, delegates to debug workflow

**Completion Signal** (lines 372-425):
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
  work_remaining: 0|[list of incomplete phases]
```

**Error Return Protocol** (lines 502-568):
- Uses standardized error types (state_error, validation_error, agent_error, etc.)
- Returns ERROR_CONTEXT JSON for logging
- Returns TASK_ERROR signal for parent command parsing

#### Debug-Analyst Pattern

**Location**: `/home/benjamin/.config/.claude/agents/debug-analyst.md`

**Key Characteristics** (lines 1-463):
- **Model**: sonnet-4.5 (root cause analysis)
- **Role**: Investigates potential root causes in parallel
- **File Creation Protocol** (lines 40-84):
  - STEP 2: Creates report file FIRST before investigation
  - Uses Write tool at pre-calculated path
  - Updates report incrementally during investigation

**Investigation Process** (lines 85-115):
- Reproduce issue (run failing tests)
- Identify root cause (investigate hypothesis)
- Assess impact (scope analysis)
- Propose fix (specific code changes with line numbers)
- Update report file with findings

**Completion Signal** (lines 117-132):
```
DEBUG_REPORT_CREATED: [EXACT ABSOLUTE PATH]
```

**Structured Return Format** (lines 259-273):
```json
{
  "artifact_path": "specs/{topic}/debug/NNN_investigation.md",
  "metadata": {
    "title": "Debug Investigation: {issue_desc}",
    "summary": "{50-word summary of findings}",
    "root_cause": "{concise_root_cause}",
    "proposed_fix": "{brief_fix_description}",
    "hypothesis_confirmed": true|false
  }
}
```

### Hierarchical Agent Architecture Principles

**Location**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`

**Relevant Principles** (lines 33-76):
1. **Metadata-Only Passing** (lines 45-49): 99% context reduction through metadata extraction
2. **Forward Message Pattern** (lines 51-56): No-paraphrase handoffs maintain original fidelity
3. **Behavioral Injection Pattern** (lines 1439-1520): Commands pre-calculate paths, inject context
4. **Error Return Protocol** (lines 502-568 in implementer-coordinator): Structured error signals

**Subagent Invocation Best Practices** (lines 1436-1758):
- Commands control orchestration, agents execute
- Commands calculate topic-based paths before invocation
- Agents create artifacts at exact paths provided
- Agents return metadata only (not full content)
- Commands verify artifacts and extract metadata
- 95% context reduction achieved

### Testing Framework Detection Utilities

**Location**: `/home/benjamin/.config/.claude/lib/util/detect-testing.sh`

**Score-Based Detection** (lines 7-100):
- Analyzes CI/CD configs (+2 points)
- Checks test directories (+1 point)
- Counts test files (+1 if >10)
- Detects coverage tools (+1 point)
- Finds test runners (+1 point)
- Maximum score: 6 points

**Framework Detection**:
- Python: pytest, unittest
- JavaScript/TypeScript: jest, vitest, mocha
- Lua/Neovim: plenary
- Bash: .claude/run_all_tests.sh

**Command Generation**: Utility can generate appropriate test commands based on detected frameworks

### Testing Protocols Documentation

**Location**: `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md`

**Test Discovery** (lines 4-8):
1. Check project root CLAUDE.md for test commands
2. Check subdirectory-specific CLAUDE.md files
3. Fall back to language-specific test patterns

**Coverage Requirements** (lines 33-37):
- >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

**Test Isolation Standards** (lines 200-260):
- Environment overrides (CLAUDE_SPECS_ROOT, CLAUDE_PROJECT_DIR)
- Temporary directories for test execution
- Cleanup traps for all exit paths
- Production directory pollution prevention

## Recommendations

### 1. Create Test-Executor Subagent Following Standard Patterns

**Create**: `/home/benjamin/.config/.claude/agents/test-executor.md`

**Model Selection**: haiku-4.5 (deterministic test execution, similar to implementer-coordinator)

**Core Responsibilities**:
1. Test framework detection (using detect-testing.sh utility)
2. Test command execution with proper isolation
3. Test output parsing and structured error extraction
4. Test result artifact creation (outputs/test_results_NNN.md)
5. Retry logic for transient test failures (optional)

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
  isolation_mode: true  # Run in temporary directory
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

**Error Return Protocol**:
```yaml
ERROR_CONTEXT: {
  "error_type": "execution_error",
  "message": "Test framework not detected",
  "details": {"project_dir": "/path", "frameworks_checked": [...]}
}

TASK_ERROR: execution_error - Test framework not detected in project
```

### 2. Integrate Test-Executor into /build Command Block 2

**Modification**: Replace inline test execution (lines 679-715) with Task tool invocation

**New Block 2 Structure**:
```bash
# Lines 536-677: State loading and validation (unchanged)

# NEW: Invoke test-executor subagent
echo "=== Phase 2: Testing ==="
echo ""

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite for implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    You are executing the testing phase for: build workflow

    Input:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - artifact_paths:
      outputs: ${TOPIC_PATH}/outputs/
      debug: ${TOPIC_PATH}/debug/
    - test_config:
      test_command: null  # Auto-detect from plan and project
      retry_on_failure: false
      isolation_mode: true

    Execute test suite, parse results, create structured report.

    Return: TEST_COMPLETE with status, counts, and artifact path
}

# Lines 717-736: Parse test-executor response and persist state
```

**Benefits of This Integration**:
- **Isolation**: Test execution in dedicated agent context, not command bash block
- **Structured Output**: Test results in artifact file, not bash variable
- **Error Context**: Detailed error analysis in outputs/ artifact for debugging
- **Context Reduction**: Metadata-only response (status + counts), full output in file
- **Retry Support**: Agent can implement intelligent retry logic internally
- **Framework Detection**: Leverages detect-testing.sh utility for automatic test discovery

### 3. Follow Behavioral Injection Pattern for Path Pre-Calculation

**Command Responsibilities**:
1. Calculate test output path before invoking test-executor:
   ```bash
   TEST_OUTPUT_PATH="${TOPIC_PATH}/outputs/test_results_$(date +%s).md"
   ```

2. Inject complete context in Task tool prompt:
   - Plan path
   - Topic path (for artifact organization)
   - Pre-calculated output path
   - Test configuration

3. Verify artifact creation after agent completes:
   ```bash
   if [ ! -f "$TEST_OUTPUT_PATH" ]; then
     echo "ERROR: Test output artifact not created"
     exit 1
   fi
   ```

4. Extract metadata only (not full test output):
   ```bash
   TESTS_PASSED=$(grep "^status:" "$TEST_OUTPUT_PATH" | awk '{print $2}')
   TEST_EXIT_CODE=$(grep "^exit_code:" "$TEST_OUTPUT_PATH" | awk '{print $2}')
   ```

**Agent Responsibilities**:
1. Receive pre-calculated paths from command
2. Use detect-testing.sh for framework detection
3. Execute tests with proper isolation
4. Parse test output and extract failures
5. Write structured report to provided path
6. Return metadata only (TEST_COMPLETE signal)

### 4. Implement Consistent Error Handling Protocol

**Error Types to Use**:
- `execution_error`: Test command failed to execute
- `validation_error`: Invalid test configuration
- `timeout_error`: Test execution exceeded time limit
- `file_error`: Cannot write test output artifact
- `dependency_error`: Test framework not found

**Error Return Format** (following implementer-coordinator pattern):
```markdown
ERROR_CONTEXT: {
  "error_type": "execution_error",
  "message": "Test command failed",
  "details": {
    "test_command": "npm test",
    "exit_code": 1,
    "stderr_preview": "FAIL tests/auth.test.js..."
  }
}

TASK_ERROR: execution_error - Test command 'npm test' failed with exit code 1
```

**Parent Command Integration**:
```bash
# Parse test-executor error if present
if echo "$TEST_EXECUTOR_OUTPUT" | grep -q "TASK_ERROR"; then
  parse_subagent_error "$TEST_EXECUTOR_OUTPUT" "test-executor"
  # Error logged to errors.jsonl automatically
  # Proceed to debug phase
fi
```

### 5. Maintain Context Efficiency with Metadata Extraction

**Test Output Artifact Structure**:
```markdown
# Test Execution Report

## Metadata
- **Date**: 2025-11-20
- **Plan**: specs/NNN_topic/plans/NNN_plan.md
- **Test Command**: npm test
- **Exit Code**: 1
- **Execution Time**: 2m 34s

## Summary
- **Total Tests**: 145
- **Passed**: 142
- **Failed**: 3
- **Skipped**: 0

## Failed Tests
1. tests/auth.test.js:45 - Token validation fails for expired tokens
2. tests/auth.test.js:67 - Refresh token rotation broken
3. tests/api.test.js:123 - Rate limiting not enforced

## Full Output
```
[complete test output]
```
```

**Metadata Extraction** (in command):
```bash
# Extract only essential metadata
TESTS_PASSED=$(grep "^- \*\*Passed\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //')
TESTS_FAILED=$(grep "^- \*\*Failed\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //')
TEST_EXIT_CODE=$(grep "^- \*\*Exit Code\*\*:" "$TEST_OUTPUT_PATH" | sed 's/.*: //')

# Context: ~50 tokens (metadata) vs ~5000 tokens (full output)
# Reduction: 99%
```

### 6. Enable Conditional Test Retry Logic (Optional Enhancement)

**Retry Configuration** (in test_config):
```yaml
test_config:
  retry_on_failure: true
  max_retries: 2
  retry_delay: 5  # seconds
  retry_on_exit_codes: [1, 124]  # 1=test fail, 124=timeout
```

**Agent Implementation**:
```bash
for attempt in $(seq 1 $((MAX_RETRIES + 1))); do
  run_test_command
  if [ $? -eq 0 ]; then
    break  # Success
  elif [ $attempt -lt $((MAX_RETRIES + 1)) ]; then
    echo "Retry $attempt/$MAX_RETRIES after ${RETRY_DELAY}s delay"
    sleep "$RETRY_DELAY"
  fi
done
```

**Use Case**: Retry for flaky integration tests, network timeouts, race conditions

## References

### Primary Sources

1. **/build command**: `/home/benjamin/.config/.claude/commands/build.md`
   - Current testing phase: lines 536-736 (Block 2)
   - Test discovery logic: lines 680-692
   - Test execution: lines 694-715

2. **Implementer-Coordinator Agent**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
   - Wave orchestration pattern: lines 1-578
   - Error handling: lines 249-280
   - Completion signal format: lines 372-425
   - Error return protocol: lines 502-568

3. **Debug-Analyst Agent**: `/home/benjamin/.config/.claude/agents/debug-analyst.md`
   - File creation protocol: lines 40-84
   - Investigation process: lines 85-115
   - Completion signal: lines 117-132
   - Structured return format: lines 259-273

4. **Hierarchical Agent Architecture**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`
   - Metadata-only passing: lines 45-49
   - Forward message pattern: lines 51-56
   - Behavioral injection pattern: lines 1439-1520
   - Subagent best practices: lines 1436-1758

5. **Test Detection Utility**: `/home/benjamin/.config/.claude/lib/util/detect-testing.sh`
   - Score-based detection: lines 7-100
   - Framework detection: lines 63-100

6. **Testing Protocols**: `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md`
   - Test discovery: lines 4-8
   - Coverage requirements: lines 33-37
   - Test isolation: lines 200-260

### Related Documentation

- Error Handling Pattern: `.claude/docs/concepts/patterns/error-handling.md`
- Directory Protocols: `.claude/docs/concepts/directory-protocols.md`
- Agent Development Fundamentals: `.claude/docs/guides/development/agent-development/agent-development-fundamentals.md`
