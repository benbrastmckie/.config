# Implement-Test Workflow Guide

## Overview

The implement-test workflow separates implementation from testing into two specialized commands:
- **/implement**: Executes implementation phases and writes tests (does not execute tests)
- **/test**: Executes test suite with coverage loop until quality threshold met

This separation enables independent execution, better separation of concerns, and context reduction for focused workflows.

## Workflow Architecture

### Traditional /build Workflow (Monolithic)
```
┌─────────────────────────────────────┐
│ /build plan.md                      │
│ ├─ Implementation Phase             │
│ │  └─ Write code + tests            │
│ ├─ Testing Phase                    │
│ │  └─ Run tests (coverage loop)     │
│ ├─ Debug Phase (if failures)        │
│ └─ Completion                       │
└─────────────────────────────────────┘
```

### New /implement + /test Workflow (Separated)
```
┌──────────────────────────────┐     ┌─────────────────────────────┐
│ /implement plan.md           │     │ /test plan.md               │
│ ├─ Implementation Phase      │     │ ├─ Test Execution Loop      │
│ │  └─ Write code + tests     │────>│ │  └─ Run until ≥80% cov    │
│ └─ Creates summary with      │     │ ├─ Debug Phase (failures)   │
│    Testing Strategy section  │     │ └─ Completion               │
└──────────────────────────────┘     └─────────────────────────────┘
         Terminal: IMPLEMENT               Terminal: COMPLETE
```

## Command Responsibilities

### /implement Command

**Workflow Type**: `implement-only`
**Terminal State**: `IMPLEMENT` (optionally transitions to `COMPLETE`)
**Primary Responsibility**: Write implementation AND tests

#### What /implement Does:
1. Executes implementation phases from plan
2. Writes production code
3. **Writes test files** during Testing phases
4. Creates implementation summary with Testing Strategy section
5. Updates phase checkboxes
6. Preserves state for /test handoff

#### What /implement Does NOT Do:
- Execute tests (tests written but not run)
- Calculate coverage metrics
- Invoke debug workflows for test failures
- Delete state file (preserved for /test)

#### Output Artifacts:
- Implementation summary: `{topic}/summaries/{NNN}-iteration-{N}-implementation-summary.md`
- State file: `{topic}/.state/implement_state.sh` (preserved for /test)
- Git commits: Implementation changes committed

### /test Command

**Workflow Type**: `test-and-debug`
**Terminal State**: `COMPLETE`
**Primary Responsibility**: Execute tests with coverage loop

#### What /test Does:
1. Accepts summary via `--file` flag or auto-discovers from plan
2. Executes test suite (coverage loop until ≥80% or max iterations)
3. Parses test results and coverage metrics
4. Conditionally invokes debug-analyst on failures
5. Creates test results per iteration
6. Cleans up state file on completion

#### What /test Does NOT Do:
- Write new tests (uses tests written by /implement)
- Modify implementation code
- Re-execute implementation phases

#### Output Artifacts:
- Test results (per iteration): `{topic}/outputs/test_results_iter{N}_{timestamp}.md`
- Debug reports (if failures): `{topic}/debug/debug_report_{timestamp}.md`

## Summary-Based Handoff Pattern

### Testing Strategy Section

The /implement command creates a summary with a Testing Strategy section that /test uses to execute tests correctly.

**Required Format** (in implementation summary):
```markdown
## Testing Strategy

### Test Files Created
- `/path/to/test_auth.sh` - Authentication unit tests
- `/path/to/test_api.sh` - API integration tests

### Test Execution Requirements
- **Framework**: Bash test framework (existing .claude/tests/ patterns)
- **Test Command**: `bash /path/to/test_auth.sh && bash /path/to/test_api.sh`
- **Coverage Target**: 80%
- **Expected Tests**: 15 unit tests, 8 integration tests

### Coverage Measurement
Coverage calculated via test execution output parsing.
```

### Handoff Mechanisms

#### Explicit Handoff (--file flag)
```bash
# Run implementation
/implement plan.md

# Use explicit summary path
/test --file /path/to/summaries/001-iteration-1-implementation-summary.md
```

#### Auto-Discovery (plan-based)
```bash
# Run implementation
/implement plan.md

# /test discovers latest summary from plan's topic directory
/test plan.md
```

Auto-discovery logic:
1. Extract topic_path from plan file (parent directory)
2. Find summaries directory: `{topic_path}/summaries/`
3. Find latest summary: `find "$SUMMARIES_DIR" -name "*.md" -printf '%T@ %p\n' | sort -rn | head -1`
4. Extract Testing Strategy section

## Test Writing Responsibility

### During /implement

Tests are written DURING implementation phases, specifically in Testing phases of the plan.

**Example Plan Structure**:
```markdown
### Phase 2: Authentication Implementation
- [ ] Implement JWT token generation
- [ ] Implement token validation
- [ ] Add error handling

### Phase 3: Testing
- [ ] Write unit tests for token generation (test_token_gen.sh)
- [ ] Write integration tests for auth flow (test_auth_flow.sh)
- [ ] Document test execution in Testing Strategy
```

The implementer-coordinator agent (invoked by /implement) ensures:
1. Tests are written during Testing phases
2. Test files are created and committed
3. Testing Strategy section documents test requirements

### During /test

Tests are EXECUTED (not written) during /test. The test-executor agent:
1. Reads Testing Strategy from summary
2. Extracts test command and framework
3. Runs tests and captures results
4. Parses coverage metrics
5. Iterates until coverage threshold met

## Test Execution Loops

### Coverage Loop Pattern

The /test command implements a coverage loop to automatically iterate until quality threshold met.

**Configuration**:
- Coverage threshold: 80% (default, configurable via `--coverage-threshold`)
- Max iterations: 5 (default, configurable via `--max-iterations`)
- Stuck threshold: 2 iterations without progress

**Loop Flow**:
```
Iteration 1:
  └─ Run tests → Parse results (60% coverage, 2 failed)
     └─ Continue (below threshold)

Iteration 2:
  └─ Run tests → Parse results (75% coverage, 1 failed)
     └─ Continue (below threshold)

Iteration 3:
  └─ Run tests → Parse results (85% coverage, all passed)
     └─ Exit: SUCCESS (≥80% coverage AND all passed)
```

### Exit Conditions

1. **Success**: `all_passed=true` AND `coverage≥threshold`
   - Next state: COMPLETE
   - Action: Proceed to completion block
   - Console: "All tests passed with 85% coverage after 3 iterations"

2. **Stuck**: No coverage progress for 2 consecutive iterations
   - Next state: DEBUG
   - Action: Invoke debug-analyst with iteration summary
   - Console: "Coverage loop stuck (no progress). Final coverage: 75%. Debug report: {path}"

3. **Max Iterations**: Iteration count ≥ max_iterations
   - Next state: DEBUG
   - Action: Invoke debug-analyst with iteration summary
   - Console: "Max iterations (5) reached. Final coverage: 78%. Debug report: {path}"

### Iteration Artifacts

Each iteration creates a separate test result artifact:
- `test_results_iter1_{timestamp}.md`
- `test_results_iter2_{timestamp}.md`
- `test_results_iter3_{timestamp}.md`

This provides an audit trail showing coverage improvement across iterations.

## Usage Examples

### Sequential Execution (Recommended)

```bash
# Step 1: Implement features and write tests
/implement specs/042_auth/plans/001_auth_plan.md

# Review implementation summary
cat specs/042_auth/summaries/001-iteration-1-implementation-summary.md

# Step 2: Execute test suite with coverage loop
/test specs/042_auth/plans/001_auth_plan.md

# Review test results
cat specs/042_auth/outputs/test_results_iter3_*.md
```

### Manual Handoff (Explicit Summary)

```bash
# Implementation
/implement specs/042_auth/plans/001_auth_plan.md

# Test with explicit summary path
/test --file specs/042_auth/summaries/001-iteration-1-implementation-summary.md
```

### Test-Only Execution (Skip Implementation)

```bash
# If implementation already complete, run tests only
/test specs/042_auth/plans/001_auth_plan.md
```

This works if:
- Tests already exist (written in previous /implement run)
- Summary exists with Testing Strategy section
- State file preserved from /implement

### Custom Coverage Threshold

```bash
# Require 90% coverage instead of default 80%
/test plan.md --coverage-threshold 90

# Allow more iterations for complex plans
/test plan.md --max-iterations 10
```

### Debugging Failed Tests

```bash
# /test automatically invokes debug-analyst on failures
/test plan.md

# If stuck or max iterations reached, debug report created:
# specs/{topic}/debug/debug_report_{timestamp}.md
```

## State Persistence

### State File Structure

The /implement command creates a state file preserved for /test:

**Location**: `{topic}/.state/implement_state.sh`

**Contents**:
```bash
PLAN_FILE="/path/to/plan.md"
TOPIC_PATH="/path/to/topic"
IMPLEMENTATION_STATUS="complete"
LATEST_SUMMARY="/path/to/summaries/001-iteration-1-implementation-summary.md"
ITERATION="1"
```

### State Lifecycle

1. **/implement creates state file**:
   - Persists PLAN_FILE, TOPIC_PATH, LATEST_SUMMARY
   - Does NOT delete on completion (preserved for /test)

2. **/test loads state file** (optional):
   - Reads PLAN_FILE and TOPIC_PATH if summary not provided
   - Uses state for auto-discovery fallback
   - Gracefully handles missing state file

3. **/test deletes state file** on completion:
   - Cleanup after successful test execution
   - State no longer needed

## Integration with Existing Workflows

### /build Command Relationship

The /build command remains available but /implement + /test is preferred for new workflows.

**Equivalence**:
```bash
# Traditional approach
/build plan.md

# Equivalent with /implement + /test
/implement plan.md
/test plan.md
```

**Benefits of Separation**:
- Run implementation without testing (faster iteration during development)
- Re-run tests without reimplementation (test-driven debugging)
- Independent checkpoint/resume for each phase
- Clearer separation of concerns

### Migration Path

Existing /build users can migrate incrementally:
1. Continue using /build for simple workflows
2. Try /implement + /test for complex workflows requiring test iteration
3. Gradually adopt /implement + /test as primary workflow

## Troubleshooting

### /test Cannot Find Summary

**Symptom**: `/test plan.md` reports "No summary found for auto-discovery"

**Cause**: /implement did not complete or summary not created

**Solution**:
```bash
# Verify /implement completed
ls {topic}/summaries/

# If no summaries, run /implement first
/implement plan.md

# If summaries exist but not found, use explicit --file flag
/test --file {topic}/summaries/001-iteration-1-implementation-summary.md
```

### Tests Not Found

**Symptom**: `/test` reports "Test files not found"

**Cause**: /implement did not write tests (no Testing phases in plan)

**Solution**:
1. Verify plan includes Testing phases
2. Re-run /implement to write tests
3. Check Testing Strategy section in summary for test file paths

### Coverage Loop Stuck

**Symptom**: `/test` exits after 2 iterations with "Coverage loop stuck"

**Cause**: Coverage not improving (same coverage for 2 consecutive iterations)

**Solution**:
1. Review debug report created by /test: `{topic}/debug/debug_report_{timestamp}.md`
2. Identify uncovered modules
3. Add tests for uncovered code
4. Re-run /test

### Max Iterations Reached

**Symptom**: `/test` exits after 5 iterations with "Max iterations reached"

**Cause**: Coverage threshold not met within iteration limit

**Solution**:
```bash
# Increase iteration limit
/test plan.md --max-iterations 10

# Or lower coverage threshold if appropriate
/test plan.md --coverage-threshold 70
```

## Advanced Patterns

### Multi-Iteration Implementation + Testing

For large plans requiring multiple /implement iterations:

```bash
# Iteration 1: Implement first batch of phases
/implement plan.md --max-iterations 2

# Test iteration 1 implementation
/test --file summaries/001-iteration-1-implementation-summary.md

# Iteration 2: Continue implementation
/implement plan.md --max-iterations 2

# Test iteration 2 implementation
/test --file summaries/002-iteration-2-implementation-summary.md
```

### Parallel Testing (Future Enhancement)

The coverage loop architecture supports future parallel test execution:

```bash
# Future: Run test suites in parallel
/test plan.md --parallel --test-groups "unit,integration,e2e"
```

## Related Documentation

- [/implement Command Guide](./../commands/implement-command-guide.md) - Complete /implement command reference
- [/test Command Guide](./../commands/test-command-guide.md) - Complete /test command reference
- [Testing Protocols](./../../reference/standards/testing-protocols.md) - Test writing standards and patterns
- [Command Authoring](./../../reference/standards/command-authoring.md) - Summary-based handoff pattern details
- [Output Formatting](./../../reference/standards/output-formatting.md) - Testing Strategy section format
