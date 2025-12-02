# /test Command Guide

## Overview

The `/test` command executes test suites with an automated coverage loop, iterating until quality thresholds are met or loop exit conditions trigger. It delegates to test-executor for test execution and optionally debug-analyst for failure analysis.

**Purpose**: Execute tests (NOT write them) with coverage loop
**Workflow Type**: test-and-debug
**Terminal State**: COMPLETE
**Prerequisites**: Tests written (via `/implement` or manually)
**Output**: Test results with coverage metrics, optional debug reports

## Key Characteristics

### What /test Does
- Executes test suites written during implementation
- Measures test coverage automatically
- Iterates until coverage threshold met (coverage loop)
- Invokes debug-analyst on failures or stuck conditions
- Creates test result artifacts for each iteration
- Tracks coverage progress across iterations

### What /test Does NOT Do
- Write tests (use `/implement` for test writing)
- Implement features (testing only)
- Modify code under test (debugging workflow separate)

## Usage

### Syntax

```bash
/test [plan-file] [--file <summary>] [--coverage-threshold=N] [--max-iterations=N]
```

### Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `plan-file` | Path | Required* | Plan file path (required if --file not provided) |
| `--file <summary>` | Path | Auto-discover | Explicit summary file path |
| `--coverage-threshold` | Number | 80 | Minimum coverage % to exit loop |
| `--max-iterations` | Number | 5 | Maximum test iterations before exit |

*Required unless `--file` is provided, in which case plan extracted from summary

### Examples

**Auto-discovery** (recommended):
```bash
# /implement creates summary → /test auto-discovers it
/test .claude/specs/042_auth/plans/001-auth-plan.md
```

**Explicit summary**:
```bash
/test --file .claude/specs/042_auth/summaries/001-implementation-summary.md
```

**Custom thresholds**:
```bash
/test plan.md --coverage-threshold 90 --max-iterations 10
```

**Test-only** (no prior /implement):
```bash
# Run tests manually written
/test plan.md
# (proceeds without summary context)
```

## Workflow Architecture

### Block Structure

The `/test` command follows a 6-block architecture with coverage loop:

```
Block 1: Test Phase Setup and Summary Discovery
  - Argument capture (2-block pattern)
  - --file flag parsing OR auto-discovery
  - Plan file validation
  - Testing Strategy parsing from summary
  - State machine initialization (test-and-debug)
  - Iteration initialization (ITERATION=1)
  ↓
[COVERAGE LOOP BEGINS]
  ↓
Block 2: Test Path Pre-Calculation
  - Calculate TEST_OUTPUT_PATH (iteration-aware)
  - Validate path is absolute
  - Persist to state
  ↓
Block 3: Test Execution [CRITICAL BARRIER]
  - Invoke test-executor agent
  - Hard barrier pattern (agent MUST create output file)
  - Expected return: TEST_COMPLETE signal
  ↓
Block 4: Test Verification and Loop Decision
  - Verify output file exists (hard barrier)
  - Parse test results (passed, failed, coverage)
  - Check success criteria (all passed + coverage met)
  - Check stuck condition (no progress 2 iterations)
  - Check max iterations reached
  - DECISION:
    - Success → Exit loop, proceed to Block 6
    - Stuck/Max → Exit loop, proceed to Block 5
    - Continue → Increment ITERATION, return to Block 2
  ↓
[COVERAGE LOOP ENDS]
  ↓
Block 5: Debug Phase [CONDITIONAL]
  - Skip if NEXT_STATE="complete"
  - Invoke debug-analyst for failures/stuck
  - Issue description includes iteration summary
  - Create debug report
  ↓
Block 6: Completion
  - State transition to COMPLETE
  - Iteration-aware console summary
  - TEST_COMPLETE signal
  - State cleanup
```

### State Transitions

```
INITIALIZE → TEST → [DEBUG] → COMPLETE
```

**Coverage Loop Flow**:
```
TEST (iteration 1) →
  ├─ Success → COMPLETE
  ├─ Stuck/Max → DEBUG → COMPLETE
  └─ Continue → TEST (iteration 2) → ... → COMPLETE
```

## Summary-Based Handoff

### Auto-Discovery Pattern

When plan file is provided, `/test` auto-discovers latest summary:

```bash
/test plan.md

# Internally:
# 1. Derive TOPIC_PATH from plan
# 2. Find summaries/ directory
# 3. Find latest *.md by modification time
# 4. Load Testing Strategy from summary
```

**Fallback**: If no summary found, proceeds without summary context (manual test discovery required)

### Explicit --file Flag

For precise control, specify summary file directly:

```bash
/test --file summaries/001-implementation-summary.md

# Internally:
# 1. Load summary from --file path
# 2. Extract PLAN_FILE from summary metadata
# 3. Parse Testing Strategy section
```

### Testing Strategy Section

The summary's Testing Strategy section provides test execution context:

```markdown
## Testing Strategy

- **Test Files**: /path/to/tests/test_auth.sh, /path/to/tests/test_login.sh
- **Test Execution Requirements**: bash /path/to/tests/run_all.sh
- **Expected Tests**: 12
- **Coverage Target**: 80%
- **Test Framework**: bash
- **Coverage Measurement**: kcov /path/to/coverage
```

**Fields Used by /test**:
- **Test Files**: Tests to execute
- **Test Execution Requirements**: Command to run tests
- **Expected Tests**: Validation (warn if mismatch)
- **Coverage Target**: Override --coverage-threshold if specified
- **Test Framework**: Auto-detection hint
- **Coverage Measurement**: Coverage tool configuration

## Coverage Loop

### Loop Principle

The coverage loop iterates test execution until quality criteria are met:

```
Iteration 1: Coverage 60% → Continue
Iteration 2: Coverage 75% → Continue
Iteration 3: Coverage 85% → Success (≥80% threshold)
```

### Exit Conditions

**1. Success** (ideal exit):
```
ALL tests passed (failed = 0)
AND
Coverage ≥ threshold
→ NEXT_STATE="complete"
```

**2. Stuck** (no progress):
```
Coverage same or decreased for 2 consecutive iterations
→ NEXT_STATE="debug"
```

**3. Max Iterations** (safety exit):
```
Iteration count ≥ max iterations (default: 5)
→ NEXT_STATE="debug"
```

**4. Continue** (normal loop):
```
Coverage < threshold
AND
Progress made (coverage increased)
AND
Iteration < max iterations
→ NEXT_STATE="continue"
→ Increment ITERATION
→ Return to Block 2
```

### Iteration Artifacts

Each iteration creates a separate test result file:

```
outputs/test_results_iter1_1733001234.md
outputs/test_results_iter2_1733001456.md
outputs/test_results_iter3_1733001678.md
```

**Audit Trail**: Review all iterations to understand coverage progression

### Progress Tracking

Variables tracked across iterations:

- `ITERATION`: Current iteration number (1, 2, 3, ...)
- `PREVIOUS_COVERAGE`: Coverage from last iteration
- `STUCK_COUNT`: Consecutive iterations without progress
- `COVERAGE_DELTA`: Change in coverage (current - previous)

## Test Execution

### Test-Executor Agent

**Agent**: `test-executor.md`

**Input Contract**:
```yaml
plan_path: /path/to/plan.md
topic_path: /path/to/topic
summary_file: /path/to/summary.md (or "none")
artifact_paths:
  outputs: /path/to/outputs
  debug: /path/to/debug
test_config:
  coverage_threshold: 80
  iteration: 1 (or N)
  max_iterations: 5
output_path: /path/to/test_results_iterN_timestamp.md
```

**Return Signal**:
```yaml
TEST_COMPLETE:
  status: "passed" | "failed" | "error"
  framework: "bash" | "pytest" | "jest" | etc
  test_command: "bash test.sh"
  tests_passed: 10
  tests_failed: 2
  coverage: 75% (or "N/A")
  next_state: "complete" | "debug" | "continue"
  output_path: /path/to/test_results.md
```

### Hard Barrier Pattern

Block 2 pre-calculates output path:
```bash
TEST_OUTPUT_PATH="${OUTPUTS_DIR}/test_results_iter${ITERATION}_${TIMESTAMP}.md"
```

Block 3 invokes test-executor (CRITICAL BARRIER):
```
Agent MUST create file at TEST_OUTPUT_PATH
```

Block 4 verifies (hard barrier check):
```bash
[ -f "$TEST_OUTPUT_PATH" ] || exit 1
```

If file missing → Hard barrier failure → Command exits with error

## Debug Workflow

### Conditional Debug Invocation

Block 5 runs only if `NEXT_STATE="debug"`:

**Triggers**:
- Loop exited stuck (2 iterations no progress)
- Loop exited at max iterations (threshold not met)
- Test failures detected

### Debug-Analyst Agent

**Agent**: `debug-analyst.md`

**Input Contract**:
```yaml
issue_description: "Coverage loop failure: Coverage stuck at 75% for 2 iterations. Iteration summary: 3 iteration(s) executed. Final coverage: 75%."
failed_phase: "test"
test_command: "bash /path/to/tests/run_all.sh"
exit_code: 1 (or N)
debug_directory: /path/to/debug
output_path: /path/to/debug_report_timestamp.md
```

**Return Signal**:
```yaml
DEBUG_COMPLETE:
  debug_report_path: /path/to/debug_report.md
```

### Iteration Summary in Debug Report

Debug analyst receives iteration context:

```
Issue: Coverage stuck at 75% for 2 iterations
Iteration summary: 3 iteration(s) executed
Final coverage: 75%

Iteration Details:
- Iteration 1: 60% coverage, 10 passed, 2 failed
- Iteration 2: 75% coverage, 11 passed, 1 failed
- Iteration 3: 75% coverage, 11 passed, 1 failed (stuck detected)
```

This context enables targeted debugging.

## Console Summary Format

### Success Case

```
═══════════════════════════════════════════════════════
TEST EXECUTION COMPLETE
═══════════════════════════════════════════════════════

## Summary
All tests passed with 85% coverage after 3 iteration(s).
Coverage threshold 80% met successfully.

## Test Results
- Tests Passed: 12
- Tests Failed: 0
- Coverage: 85%
- Iterations: 3

## Artifacts
- Plan: /path/to/plan.md
- Test Results: /path/to/test_results_iter3_1733001678.md

## Next Steps
• Review test results: cat /path/to/test_results_iter3_1733001678.md
• Verify coverage meets project requirements
```

### Stuck Case

```
═══════════════════════════════════════════════════════
TEST EXECUTION COMPLETE
═══════════════════════════════════════════════════════

## Summary
Coverage loop stuck (no progress for 2 iterations).
Final coverage: 75% (target: 80%).
Debug report: /path/to/debug_report_1733001900.md

## Test Results
- Tests Passed: 11
- Tests Failed: 1
- Coverage: 75%
- Iterations: 3

## Artifacts
- Plan: /path/to/plan.md
- Test Results: /path/to/test_results_iter3_1733001678.md
- Debug Report: /path/to/debug_report_1733001900.md

## Next Steps
• Review debug report: cat /path/to/debug_report_1733001900.md
• Address failing tests or coverage gaps
• Re-run /test after fixes
```

### Max Iterations Case

```
═══════════════════════════════════════════════════════
TEST EXECUTION COMPLETE
═══════════════════════════════════════════════════════

## Summary
Max iterations (5) reached.
Final coverage: 78% (target: 80%).
Debug report: /path/to/debug_report_1733002100.md

## Test Results
- Tests Passed: 12
- Tests Failed: 0
- Coverage: 78%
- Iterations: 5

## Artifacts
- Plan: /path/to/plan.md
- Test Results: /path/to/test_results_iter5_1733002000.md
- Debug Report: /path/to/debug_report_1733002100.md

## Next Steps
• Review debug report: cat /path/to/debug_report_1733002100.md
• Consider lowering coverage threshold or adding more tests
• Re-run /test with --coverage-threshold 75
```

## Examples

### Example 1: Single Iteration Success

```bash
# Tests written by /implement
/implement auth-plan.md

# Execute tests
/test auth-plan.md

# Output:
# Iteration 1: 12 passed, 0 failed, 85% coverage
# Success! (threshold: 80%)
# TEST_COMPLETE signal emitted
```

### Example 2: Multiple Iterations to Threshold

```bash
# Execute tests with custom threshold
/test feature-plan.md --coverage-threshold 90

# Output:
# Iteration 1: 75% coverage → Continue
# Iteration 2: 82% coverage → Continue
# Iteration 3: 91% coverage → Success!
```

### Example 3: Stuck Detection

```bash
/test complex-plan.md

# Output:
# Iteration 1: 60% coverage → Continue
# Iteration 2: 75% coverage → Continue
# Iteration 3: 75% coverage → Continue (no progress)
# Iteration 4: 74% coverage → Stuck! (2 iterations no progress)
# Debug analyst invoked
# Debug report created
```

### Example 4: Max Iterations

```bash
/test large-plan.md --max-iterations 3

# Output:
# Iteration 1: 50% coverage → Continue
# Iteration 2: 65% coverage → Continue
# Iteration 3: 72% coverage → Max iterations reached
# Debug analyst invoked
# Debug report suggests adding more tests
```

### Example 5: Explicit Summary

```bash
# Use specific summary (not latest)
/test --file summaries/002-iteration-2-summary.md --coverage-threshold 85

# Output:
# Testing Strategy loaded from summary
# Test files: tests/unit_tests.sh, tests/integration_tests.sh
# Test command: bash tests/run_all.sh
# Iteration 1: 88% coverage → Success!
```

## Troubleshooting

### Issue: Summary Not Found

**Symptoms**: "WARNING: No summary found" message

**Causes**:
- `/implement` not run first
- Auto-discovery failed
- Summaries directory missing

**Solutions**:
1. Run `/implement` to create summary
2. Use explicit `--file` flag with summary path
3. Verify summaries/ directory exists in topic path
4. Proceed without summary (manual test discovery)

### Issue: Coverage Loop Stuck

**Symptoms**: Loop exits after 2-3 iterations with "stuck" message

**Causes**:
- Test coverage not improving
- Coverage measurement issues
- Insufficient tests for uncovered code

**Solutions**:
1. Review debug report for coverage gaps
2. Add tests for uncovered modules
3. Verify coverage tool configured correctly
4. Lower coverage threshold temporarily

### Issue: Max Iterations Reached

**Symptoms**: Loop exits at max iterations, coverage below threshold

**Causes**:
- Coverage goal too ambitious
- Coverage improving slowly
- Complex codebase

**Solutions**:
1. Increase `--max-iterations` limit
2. Lower `--coverage-threshold` to achievable level
3. Review debug report for specific gaps
4. Add more tests incrementally

### Issue: Hard Barrier Failure

**Symptoms**: "test-executor did not create output file"

**Causes**:
- Agent invocation failed
- Output path invalid
- Permissions issue

**Solutions**:
1. Check test-executor agent logs
2. Verify outputs/ directory writable
3. Review test command in Testing Strategy
4. Check `/errors --command /test`

### Issue: Testing Strategy Not Parsed

**Symptoms**: "WARNING: Testing Strategy section incomplete"

**Causes**:
- Summary missing Testing Strategy section
- Summary from old format
- Section format incorrect

**Solutions**:
1. Verify summary has `## Testing Strategy` section
2. Re-run `/implement` to get updated summary format
3. Manually add Testing Strategy to summary
4. Proceed with manual test discovery

## Best Practices

### 1. Coverage Thresholds

- Use default 80% for most projects
- Adjust based on project requirements
- Lower threshold (60-70%) for initial iterations
- Increase threshold (85-95%) for critical code

### 2. Iteration Limits

- Default 5 iterations works for most cases
- Increase to 10 for large test suites
- Decrease to 3 for quick feedback loops
- Monitor iteration count - if >5, review tests

### 3. Summary-Based Handoff

- Prefer auto-discovery over explicit `--file`
- Use explicit `--file` for specific summaries
- Verify Testing Strategy in summary before running
- Re-run `/implement` if summary format outdated

### 4. Debug Workflow

- Always review debug report when loop exits early
- Fix failing tests before increasing iterations
- Address coverage gaps identified in debug report
- Re-run `/test` after fixes to verify

### 5. Loop Management

- Monitor stuck detection - indicates test quality issues
- Track coverage delta across iterations
- If stuck, add tests rather than lowering threshold
- If max iterations reached, review debug report first

## Design Notes

### Coverage Loop Implementation

The current implementation uses sequential block execution. Future enhancements may consolidate Blocks 2-4 into a single looping block for true automated iteration.

**Current Behavior**: Loop control indicated but not fully automated
**Workaround**: Re-run `/test` manually if `NEXT_STATE="continue"`
**Future**: Automated loop within single block

### Loop vs Manual Iteration

| Aspect | Automated Loop | Manual Iteration |
|--------|----------------|------------------|
| Execution | Single command run | Multiple command invocations |
| State | Preserved in memory | Loaded from state file |
| Audit Trail | Single workflow | Multiple workflows |
| Control | Exit conditions only | User decides when to continue |

Current implementation favors manual iteration for transparency and control.

## See Also

- [/implement Command Guide](./implement-command-guide.md) - Implementation and test writing
- [Implement-Test Workflow](../workflows/implement-test-workflow.md) - End-to-end workflow patterns
- [Testing Protocols](../../reference/standards/testing-protocols.md) - Test execution standards
- [Output Formatting](../../reference/standards/output-formatting.md) - Testing Strategy section format
- [Hard Barrier Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md) - Hard barrier details
