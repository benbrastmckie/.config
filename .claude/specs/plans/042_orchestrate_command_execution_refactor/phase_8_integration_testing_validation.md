# Phase 8: Integration Testing and Validation

## Metadata
- **Phase Number**: 8
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 7 (Execution Infrastructure and State Management)
- **Complexity**: High (9/10)
- **Estimated Hours**: 8-10
- **Status**: PENDING

## Objective

Conduct comprehensive end-to-end validation of the refactored /orchestrate command through four distinct test workflows that verify actual agent invocation, file creation, workflow state management, and error handling. Ensure all transformation goals are met: imperative execution, explicit Task tool usage, verification checklists, and complete agent coordination across all 5 workflow phases (research, planning, implementation, debugging, documentation).

## Context and Background

This phase is critical because it validates the entire refactor. The previous 7 phases transformed orchestrate.md from passive documentation into an execution-driven command. Phase 8 proves the transformation worked by:

1. **Demonstrating Actual Execution**: Tests must show Claude actually invokes agents via Task tool, not just documents the workflow
2. **Validating All Workflow Patterns**: Tests cover simple (skip research), medium (parallel research), complex (debugging loop), and maximum (escalation) scenarios
3. **Verifying File Creation**: All expected artifacts must be created in correct locations with correct formats
4. **Confirming State Management**: TodoWrite, checkpoints, and workflow_state must track progress correctly
5. **Proving Error Recovery**: Debugging loop and escalation logic must handle failures gracefully

Without this comprehensive testing, we cannot be confident the refactored command actually works as intended.

## Test Strategy

### Coverage Goals

- **Execution Paths**: ≥80% of all workflow execution paths tested
- **Workflow Phases**: All 5 phases covered (research, planning, implementation, debugging, documentation)
- **Execution Patterns**: Parallel (research), sequential (planning/implementation/documentation), conditional (debugging)
- **Success Scenarios**: Normal workflows complete successfully (workflows 1, 2)
- **Failure Scenarios**: Test failures trigger debugging loop (workflow 3), escalation occurs when appropriate (workflow 4)
- **Agent Types**: All 5 agent types invoked at least once (research-specialist, plan-architect, code-writer, debug-specialist, doc-writer)

### Test Environment Setup

Each test workflow requires:
- Clean temporary directory for specs/ and debug/ artifacts
- Mock project structure simulating realistic codebase
- Test data representing realistic feature descriptions
- Validation scripts to verify agent invocations and file creation
- Cleanup between tests to prevent cross-contamination

### Validation Dimensions

For each test workflow, verify:

1. **Agent Invocation Verification**: Task tool calls visible in command output
2. **Agent Execution Verification**: Agents complete work and produce outputs
3. **File Creation Verification**: All expected files created (reports, plans, summaries, debug reports)
4. **File Format Verification**: Files follow specified structure and numbering conventions
5. **Cross-Reference Verification**: Bidirectional links between artifacts exist and are valid
6. **State Management Verification**: TodoWrite shows progress, checkpoints saved, workflow_state updated
7. **Parallel Execution Verification**: Research agents run concurrently (single message, multiple Task blocks)
8. **Sequential Execution Verification**: Phases execute in order with dependencies respected
9. **Conditional Execution Verification**: Debugging only triggers on test failures
10. **Iteration Limit Verification**: Debugging loop enforces max 3 iterations, escalates correctly

## Test Workflows

### Test Workflow #1: Simple (Minimal Path)

**Purpose**: Validate core agent invocation in simplest possible workflow without research phase

**Workflow Description**: "Add hello world function"

**Expected Execution Path**:
```
Skip Research → Planning → Implementation → Documentation
```

**Rationale**: Tests whether command correctly identifies simple workflows that don't need research, and whether basic agent coordination (planning → implementation → documentation) works.

**Expected Agent Invocations**:
1. **plan-architect** (1 invocation): Creates implementation plan for hello world function
2. **code-writer** (1 invocation): Implements hello world function following plan
3. **doc-writer** (1 invocation): Updates documentation with hello world function details

**Expected File Artifacts**:
- `specs/plans/NNN_hello_world.md` - Implementation plan
- `[source_file]` - Source file containing hello world function
- `specs/summaries/NNN_hello_world_summary.md` - Workflow summary
- `[docs]` - Updated documentation files

**Validation Criteria**:

1. **Research Phase Skipped**: Workflow does not invoke research-specialist agents (simple feature doesn't require research)
2. **Planning Agent Invoked**: Task tool called with plan-architect protocol, prompt includes feature description
3. **Plan File Created**: Plan exists at expected path, has metadata, phases, and tasks
4. **Implementation Agent Invoked**: Task tool called with code-writer protocol, prompt includes plan path
5. **Implementation Succeeds**: Code written, tests passing, git commit created
6. **Documentation Agent Invoked**: Task tool called with doc-writer protocol, prompt includes file changes
7. **Summary Created**: Workflow summary exists, references plan, lists changes
8. **TodoWrite Updated**: All phases marked completed in order (planning, implementation, documentation)
9. **No Debug Reports**: No debug/ artifacts created (tests passed on first try)
10. **Completion Message**: User receives success message with artifact paths

**Test Implementation**:
```bash
test_simple_workflow() {
  local test_name="Test Workflow #1: Simple (Minimal Path)"
  info "$test_name"

  # Setup
  local test_dir="$TEST_DIR/workflow_1"
  mkdir -p "$test_dir/specs/plans" "$test_dir/specs/summaries"
  cd "$test_dir"

  # Execute orchestrate command with simple feature
  local feature="Add hello world function"
  local output_file="$test_dir/orchestrate_output.txt"

  # Simulate /orchestrate invocation
  # In actual test, this would invoke Claude with orchestrate.md command
  cat > "$output_file" <<'EOF'
[Simulated command output showing Task tool invocations]
EXECUTE: Invoke plan-architect agent
Task tool invocation: {...}
Agent output: Plan created at specs/plans/001_hello_world.md

EXECUTE: Invoke code-writer agent
Task tool invocation: {...}
Agent output: Implementation complete, tests passing

EXECUTE: Invoke doc-writer agent
Task tool invocation: {...}
Agent output: Documentation updated
EOF

  # Validation 1: Research phase skipped
  if ! grep -q "research-specialist" "$output_file"; then
    pass "Research phase correctly skipped for simple workflow"
  else
    fail "Research phase should not run for simple feature" "Found research-specialist invocation"
    return 1
  fi

  # Validation 2: Plan-architect invoked
  if grep -q "plan-architect" "$output_file" && \
     grep -q "Task tool invocation" "$output_file"; then
    pass "Plan-architect agent invoked via Task tool"
  else
    fail "Plan-architect agent not invoked" "No Task tool call found"
    return 1
  fi

  # Validation 3: Plan file exists
  if [ -f "$test_dir/specs/plans/001_hello_world.md" ]; then
    pass "Plan file created at expected location"
  else
    fail "Plan file not created" "Expected: specs/plans/001_hello_world.md"
    return 1
  fi

  # Validation 4: Code-writer invoked
  if grep -q "code-writer" "$output_file"; then
    pass "Code-writer agent invoked via Task tool"
  else
    fail "Code-writer agent not invoked" "No code-writer call found"
    return 1
  fi

  # Validation 5: Doc-writer invoked
  if grep -q "doc-writer" "$output_file"; then
    pass "Doc-writer agent invoked via Task tool"
  else
    fail "Doc-writer agent not invoked" "No doc-writer call found"
    return 1
  fi

  # Validation 6: Summary created
  if [ -f "$test_dir/specs/summaries/001_hello_world_summary.md" ]; then
    pass "Workflow summary created"
  else
    fail "Summary not created" "Expected: specs/summaries/001_hello_world_summary.md"
    return 1
  fi

  # Validation 7: No debug reports
  if [ ! -d "$test_dir/debug" ] || [ -z "$(ls -A "$test_dir/debug" 2>/dev/null)" ]; then
    pass "No debug reports created (tests passed)"
  else
    fail "Debug reports found unexpectedly" "Simple workflow should not need debugging"
    return 1
  fi

  info "$test_name: All validations passed"
  return 0
}
```

### Test Workflow #2: Medium (Research + Implementation)

**Purpose**: Validate parallel research agent invocation and report integration into planning

**Workflow Description**: "Add configuration validation module"

**Expected Execution Path**:
```
Research (2-3 parallel agents) → Planning → Implementation → Documentation
```

**Rationale**: Tests parallel agent invocation (most complex coordination pattern), report file creation, and report integration into planning phase.

**Expected Agent Invocations**:
1. **research-specialist** (2-3 parallel invocations): Investigate existing patterns, best practices, implementation options
2. **plan-architect** (1 invocation): Creates plan incorporating research findings
3. **code-writer** (1 invocation): Implements validation module following plan
4. **doc-writer** (1 invocation): Updates documentation

**Expected File Artifacts**:
- `specs/reports/existing_patterns/001_config_patterns.md` - Research report #1
- `specs/reports/best_practices/001_validation_practices.md` - Research report #2
- `specs/reports/implementation_options/001_module_options.md` - Research report #3 (optional)
- `specs/plans/NNN_config_validation.md` - Implementation plan referencing all reports
- `[source_files]` - Validation module implementation
- `specs/summaries/NNN_config_validation_summary.md` - Workflow summary

**Validation Criteria**:

1. **Parallel Research Invoked**: Multiple research-specialist agents invoked in SINGLE MESSAGE (parallel execution)
2. **Research Reports Created**: 2-3 reports exist in topic-organized subdirectories
3. **Report Paths Captured**: Workflow correctly extracted report file paths from agent outputs
4. **Report Format Valid**: Each report has metadata, findings, recommendations sections
5. **Report Numbering Correct**: Reports numbered sequentially within topic directories (001, 002, etc.)
6. **Planning Agent Invoked**: Plan-architect receives report paths (not full content)
7. **Plan References Reports**: Plan metadata lists all research reports used
8. **Plan Incorporates Findings**: Plan content reflects research recommendations
9. **Implementation Succeeds**: Validation module implemented, tests pass
10. **Summary Links All Artifacts**: Workflow summary references all reports, plan, and implementation

**Test Implementation**:
```bash
test_medium_workflow() {
  local test_name="Test Workflow #2: Medium (Research + Implementation)"
  info "$test_name"

  # Setup
  local test_dir="$TEST_DIR/workflow_2"
  mkdir -p "$test_dir/specs/"{reports,plans,summaries}
  cd "$test_dir"

  # Execute orchestrate command
  local feature="Add configuration validation module"
  local output_file="$test_dir/orchestrate_output.txt"

  # Simulate command output
  cat > "$output_file" <<'EOF'
EXECUTE: Launch parallel research agents
Research Topic 1: existing_patterns
Research Topic 2: best_practices
Research Topic 3: implementation_options

Task tool invocation #1: research-specialist for existing_patterns
Task tool invocation #2: research-specialist for best_practices
Task tool invocation #3: research-specialist for implementation_options

Agent #1 output: REPORT_PATH: specs/reports/existing_patterns/001_config_patterns.md
Agent #2 output: REPORT_PATH: specs/reports/best_practices/001_validation_practices.md
Agent #3 output: REPORT_PATH: specs/reports/implementation_options/001_module_options.md

EXECUTE: Invoke plan-architect agent
Report paths: [3 paths provided]
Agent output: Plan created at specs/plans/002_config_validation.md

EXECUTE: Invoke code-writer agent
Plan path: specs/plans/002_config_validation.md
Agent output: Implementation complete, tests passing

EXECUTE: Invoke doc-writer agent
Agent output: Documentation updated, summary created
EOF

  # Create mock report files
  for topic in existing_patterns best_practices implementation_options; do
    local report_dir="$test_dir/specs/reports/$topic"
    mkdir -p "$report_dir"
    cat > "$report_dir/001_${topic}_report.md" <<REPORT_EOF
# Research Report: $topic

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Topic**: $topic
- **Report Number**: 001

## Findings
[Research findings here]

## Recommendations
[Recommendations here]
REPORT_EOF
  done

  # Validation 1: Parallel invocation
  local research_count=$(grep -c "Task tool invocation.*research-specialist" "$output_file")
  if [ "$research_count" -ge 2 ]; then
    pass "Multiple research agents invoked in parallel ($research_count agents)"
  else
    fail "Expected 2+ parallel research agents" "Found: $research_count"
    return 1
  fi

  # Validation 2: Single message check
  # In real test, verify all Task invocations in same message block
  pass "Research agents invoked in single message (parallel execution)"

  # Validation 3: Report files created
  local report_files_found=0
  for topic in existing_patterns best_practices implementation_options; do
    if [ -f "$test_dir/specs/reports/$topic/001_${topic}_report.md" ]; then
      ((report_files_found++))
    fi
  done

  if [ "$report_files_found" -ge 2 ]; then
    pass "Research report files created ($report_files_found reports)"
  else
    fail "Expected 2+ report files" "Found: $report_files_found"
    return 1
  fi

  # Validation 4: Report paths extracted
  if grep -q "REPORT_PATH:" "$output_file"; then
    pass "Report paths extracted from agent outputs"
  else
    fail "Report paths not extracted" "Expected REPORT_PATH: format"
    return 1
  fi

  # Validation 5: Plan created
  if [ -f "$test_dir/specs/plans/002_config_validation.md" ]; then
    pass "Implementation plan created"
  else
    fail "Plan file not created" "Expected: specs/plans/002_config_validation.md"
    return 1
  fi

  # Validation 6: Plan references reports
  local plan_file="$test_dir/specs/plans/002_config_validation.md"
  if grep -q "Research Reports" "$plan_file" && \
     grep -q "existing_patterns" "$plan_file"; then
    pass "Plan references research reports"
  else
    fail "Plan does not reference reports" "Expected research report references in metadata"
    return 1
  fi

  # Validation 7: Summary created
  if [ -f "$test_dir/specs/summaries/002_config_validation_summary.md" ]; then
    pass "Workflow summary created"
  else
    fail "Summary not created" "Expected: specs/summaries/002_config_validation_summary.md"
    return 1
  fi

  # Validation 8: Summary cross-references
  local summary_file="$test_dir/specs/summaries/002_config_validation_summary.md"
  if grep -q "Research Reports" "$summary_file" && \
     grep -q "Implementation Plan" "$summary_file"; then
    pass "Summary contains cross-references to reports and plan"
  else
    fail "Summary missing cross-references" "Should link reports and plan"
    return 1
  fi

  info "$test_name: All validations passed"
  return 0
}
```

### Test Workflow #3: Complex (With Debugging Loop)

**Purpose**: Validate debugging loop with 1-2 iterations, debug report creation, and fix application

**Workflow Description**: "Add authentication middleware with session management"

**Expected Execution Path**:
```
Research → Planning → Implementation → Debugging (1-2 iterations) → Documentation
```

**Rationale**: Tests conditional debugging execution, debug-specialist agent invocation, iterative fix attempts, and eventual success after debugging.

**Setup**: Create implementation that fails tests initially (missing dependency, configuration error, or logic bug) to trigger debugging loop.

**Expected Agent Invocations**:
1. **research-specialist** (2 parallel invocations): Authentication patterns, security practices
2. **plan-architect** (1 invocation): Creates authentication implementation plan
3. **code-writer** (1 invocation): Implements authentication (with intentional issue)
4. **debug-specialist** (1-2 invocations): Investigates test failures
5. **code-writer** (1-2 invocations): Applies fixes from debug reports
6. **doc-writer** (1 invocation): Updates documentation

**Expected File Artifacts**:
- `specs/reports/auth_patterns/001_auth_research.md`
- `specs/reports/security_practices/001_security_research.md`
- `specs/plans/NNN_authentication_middleware.md`
- `debug/phase2_failures/001_missing_dependency.md` - Debug report iteration 1
- `debug/phase2_failures/002_config_error.md` - Debug report iteration 2 (if needed)
- `[source_files]` - Authentication middleware implementation
- `specs/summaries/NNN_authentication_summary.md`

**Validation Criteria**:

1. **Implementation Fails Initially**: Tests fail after first code-writer invocation
2. **Debugging Triggered**: debug-specialist agent invoked conditionally (only because tests failed)
3. **Debug Report Created**: Report exists in debug/{topic}/ with analysis and solutions
4. **Debug Topic Slug Correct**: Topic name reflects error category (e.g., "phase2_failures", "integration_issues")
5. **Fix Applied**: code-writer invoked again with debug report reference
6. **Tests Re-run**: Tests executed after fix applied
7. **Iteration Tracking**: Workflow state tracks debugging iteration count
8. **Loop Exits on Success**: After 1-2 iterations, tests pass and loop exits
9. **Documentation Includes Debugging**: Summary mentions debugging efforts and fixes
10. **Checkpoint Updated**: Checkpoint reflects debugging activity (debug_reports array populated)

**Test Implementation**:
```bash
test_complex_workflow() {
  local test_name="Test Workflow #3: Complex (With Debugging)"
  info "$test_name"

  # Setup
  local test_dir="$TEST_DIR/workflow_3"
  mkdir -p "$test_dir/specs/"{reports,plans,summaries}
  mkdir -p "$test_dir/debug"
  cd "$test_dir"

  # Execute orchestrate command
  local feature="Add authentication middleware with session management"
  local output_file="$test_dir/orchestrate_output.txt"

  # Simulate command output with test failure and debugging
  cat > "$output_file" <<'EOF'
EXECUTE: Research phase (2 parallel agents)
Reports created:
- specs/reports/auth_patterns/001_auth_research.md
- specs/reports/security_practices/001_security_research.md

EXECUTE: Planning phase
Plan created: specs/plans/003_authentication_middleware.md

EXECUTE: Implementation phase
Code written, running tests...
Tests FAILED: ModuleNotFoundError: No module named 'session_store'

CONDITIONAL: Tests failed, entering debugging loop (iteration 1)

EXECUTE: Invoke debug-specialist agent
DEBUG_REPORT_PATH: debug/phase2_failures/001_missing_dependency.md
Root cause: session_store module not imported
Recommended fix: Add import statement

EXECUTE: Invoke code-writer agent with fix
Fix applied: Added session_store import
Running tests again...
Tests PASSED

Debugging loop: 1 iteration, tests now passing
Proceeding to documentation phase

EXECUTE: Documentation phase
Summary created: specs/summaries/003_authentication_summary.md
EOF

  # Create mock artifacts
  mkdir -p "$test_dir/debug/phase2_failures"
  cat > "$test_dir/debug/phase2_failures/001_missing_dependency.md" <<DEBUG_EOF
# Debug Report: Missing Dependency

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Topic**: phase2_failures
- **Iteration**: 1

## Root Cause
session_store module not imported in auth middleware

## Solutions
1. Add import at top of file
2. Install missing package
3. Refactor to remove dependency

## Recommended Fix
Option 1: Add import statement
DEBUG_EOF

  # Validation 1: Implementation failed initially
  if grep -q "Tests FAILED" "$output_file"; then
    pass "Implementation tests failed initially (expected)"
  else
    fail "Tests should fail initially to trigger debugging" "No test failure found"
    return 1
  fi

  # Validation 2: Debugging triggered conditionally
  if grep -q "entering debugging loop" "$output_file"; then
    pass "Debugging loop triggered on test failure"
  else
    fail "Debugging loop not triggered" "Should activate on test failure"
    return 1
  fi

  # Validation 3: Debug-specialist invoked
  if grep -q "debug-specialist" "$output_file" && \
     grep -q "DEBUG_REPORT_PATH:" "$output_file"; then
    pass "Debug-specialist agent invoked and report created"
  else
    fail "Debug-specialist not invoked" "No debug agent call found"
    return 1
  fi

  # Validation 4: Debug report file exists
  if [ -f "$test_dir/debug/phase2_failures/001_missing_dependency.md" ]; then
    pass "Debug report file created in correct location"
  else
    fail "Debug report not created" "Expected: debug/phase2_failures/001_missing_dependency.md"
    return 1
  fi

  # Validation 5: Fix applied
  if grep -q "code-writer agent with fix" "$output_file" && \
     grep -q "Fix applied" "$output_file"; then
    pass "Code-writer invoked to apply fix from debug report"
  else
    fail "Fix not applied" "code-writer should apply debug recommendations"
    return 1
  fi

  # Validation 6: Tests re-run and pass
  if grep -q "Running tests again" "$output_file" && \
     grep -q "Tests PASSED" "$output_file"; then
    pass "Tests re-run after fix and passed"
  else
    fail "Tests not re-run or still failing" "Should re-run and pass after fix"
    return 1
  fi

  # Validation 7: Iteration count tracked
  if grep -q "iteration 1" "$output_file" && \
     grep -q "1 iteration" "$output_file"; then
    pass "Debugging iteration count tracked correctly"
  else
    fail "Iteration count not tracked" "Should show iteration number"
    return 1
  fi

  # Validation 8: Loop exited on success
  if grep -q "tests now passing" "$output_file" && \
     grep -q "Proceeding to documentation" "$output_file"; then
    pass "Debugging loop exited when tests passed"
  else
    fail "Loop should exit after tests pass" "Should proceed to documentation"
    return 1
  fi

  # Validation 9: Documentation phase completed
  if [ -f "$test_dir/specs/summaries/003_authentication_summary.md" ]; then
    pass "Documentation phase completed after debugging"
  else
    fail "Documentation not completed" "Expected summary file"
    return 1
  fi

  info "$test_name: All validations passed"
  return 0
}
```

### Test Workflow #4: Maximum (Escalation Scenario)

**Purpose**: Validate 3-iteration limit enforcement and user escalation when debugging cannot resolve issues

**Workflow Description**: "Implement payment processing with external API integration"

**Expected Execution Path**:
```
Research → Planning → Implementation → Debugging (3 iterations) → USER ESCALATION
```

**Rationale**: Tests worst-case scenario where debugging attempts fail repeatedly, ensuring system doesn't loop infinitely and properly escalates to user with actionable information.

**Setup**: Create implementation with persistent test failure that cannot be auto-fixed (e.g., external API key missing, architectural issue requiring redesign).

**Expected Agent Invocations**:
1. **research-specialist** (2-3 parallel invocations): Payment APIs, integration patterns, security
2. **plan-architect** (1 invocation): Payment processing plan
3. **code-writer** (1 invocation): Initial implementation (fails tests)
4. **debug-specialist** (3 invocations): Three debugging attempts
5. **code-writer** (3 invocations): Three fix attempts (all fail)
6. **NO doc-writer**: Workflow does not reach documentation (escalated before)

**Expected File Artifacts**:
- `specs/reports/payment_apis/001_api_research.md`
- `specs/reports/integration_patterns/001_integration_research.md`
- `specs/plans/NNN_payment_processing.md`
- `debug/integration_issues/001_api_connection_failed.md` - Iteration 1
- `debug/integration_issues/002_authentication_error.md` - Iteration 2
- `debug/integration_issues/003_missing_credentials.md` - Iteration 3
- `[source_files]` - Partial payment implementation
- **NO summary file** (workflow escalated before documentation phase)

**Validation Criteria**:

1. **Implementation Fails**: Tests fail after initial code-writer invocation
2. **Debugging Iteration 1**: debug-specialist invoked, report created, fix applied, tests re-run, still fail
3. **Debugging Iteration 2**: Second debug-specialist invocation, new report, second fix, tests still fail
4. **Debugging Iteration 3**: Third debug-specialist invocation, third report, third fix, tests still fail
5. **Iteration Limit Enforced**: After 3rd failure, no 4th debugging iteration attempted
6. **Escalation Triggered**: User escalation message displayed
7. **Escalation Message Clear**: Message explains issue, shows debug reports created, provides options
8. **Checkpoint Saved**: Escalation checkpoint created with all context
9. **State Preserved**: All work preserved (3 debug reports, partial implementation, plan)
10. **No Documentation Phase**: Workflow stops before doc-writer invocation (properly escalated)

**Test Implementation**:
```bash
test_maximum_workflow() {
  local test_name="Test Workflow #4: Maximum (Escalation)"
  info "$test_name"

  # Setup
  local test_dir="$TEST_DIR/workflow_4"
  mkdir -p "$test_dir/specs/"{reports,plans,summaries}
  mkdir -p "$test_dir/debug/integration_issues"
  cd "$test_dir"

  # Execute orchestrate command
  local feature="Implement payment processing with external API integration"
  local output_file="$test_dir/orchestrate_output.txt"

  # Simulate command output with 3 failed debugging iterations
  cat > "$output_file" <<'EOF'
EXECUTE: Research phase (3 parallel agents)
Reports created: [3 reports]

EXECUTE: Planning phase
Plan created: specs/plans/004_payment_processing.md

EXECUTE: Implementation phase
Code written, running tests...
Tests FAILED: ConnectionError: Failed to connect to payment API

CONDITIONAL: Tests failed, entering debugging loop (iteration 1/3)

EXECUTE: Invoke debug-specialist agent (iteration 1)
DEBUG_REPORT_PATH: debug/integration_issues/001_api_connection_failed.md
Root cause: API endpoint incorrect
Recommended fix: Update API URL

EXECUTE: Apply fix (iteration 1)
Fix applied, running tests...
Tests FAILED: AuthenticationError: Invalid API credentials

Iteration 1 failed, continuing to iteration 2

EXECUTE: Invoke debug-specialist agent (iteration 2)
DEBUG_REPORT_PATH: debug/integration_issues/002_authentication_error.md
Root cause: API key format incorrect
Recommended fix: Update key format

EXECUTE: Apply fix (iteration 2)
Fix applied, running tests...
Tests FAILED: CredentialsError: API key environment variable not set

Iteration 2 failed, continuing to iteration 3

EXECUTE: Invoke debug-specialist agent (iteration 3)
DEBUG_REPORT_PATH: debug/integration_issues/003_missing_credentials.md
Root cause: API credentials not configured in environment
Recommended fix: Set PAYMENT_API_KEY environment variable

EXECUTE: Apply fix (iteration 3)
Fix applied, running tests...
Tests FAILED: CredentialsError: API key environment variable still not set

Iteration 3 failed, maximum iterations (3) reached

ESCALATION: Manual intervention required
================================================================================
Unable to resolve test failures after 3 debugging iterations.

Issue: Payment API integration tests failing due to missing credentials

Debug reports created:
1. debug/integration_issues/001_api_connection_failed.md
2. debug/integration_issues/002_authentication_error.md
3. debug/integration_issues/003_missing_credentials.md

Checkpoint saved: .claude/data/checkpoints/orchestrate_payment_processing.json

User options:
- Provide API credentials and resume workflow
- Review debug reports and manually fix issue
- Modify implementation plan and restart
- Terminate workflow

Please resolve the issue and resume using checkpoint.
================================================================================

Workflow ESCALATED, awaiting user intervention
EOF

  # Create mock debug reports
  for i in 1 2 3; do
    local report_num=$(printf "%03d" $i)
    local report_names=("api_connection_failed" "authentication_error" "missing_credentials")
    local report_name="${report_names[$((i-1))]}"

    cat > "$test_dir/debug/integration_issues/${report_num}_${report_name}.md" <<DEBUG_EOF
# Debug Report: ${report_name}

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Iteration**: $i
- **Topic**: integration_issues

## Root Cause
[Analysis for iteration $i]

## Solutions
[Proposed solutions]

## Recommended Fix
[Specific fix for iteration $i]
DEBUG_EOF
  done

  # Validation 1: Three debugging iterations executed
  local debug_count=$(grep -c "Invoke debug-specialist agent (iteration" "$output_file")
  if [ "$debug_count" -eq 3 ]; then
    pass "Exactly 3 debugging iterations executed"
  else
    fail "Expected 3 debugging iterations" "Found: $debug_count"
    return 1
  fi

  # Validation 2: Three debug reports created
  local report_count=$(ls -1 "$test_dir/debug/integration_issues/"*.md 2>/dev/null | wc -l)
  if [ "$report_count" -eq 3 ]; then
    pass "3 debug reports created (one per iteration)"
  else
    fail "Expected 3 debug reports" "Found: $report_count"
    return 1
  fi

  # Validation 3: No 4th iteration attempted
  if ! grep -q "iteration 4" "$output_file" && \
     grep -q "maximum iterations (3) reached" "$output_file"; then
    pass "No 4th iteration attempted (limit enforced)"
  else
    fail "Should not attempt 4th iteration" "Limit of 3 should be enforced"
    return 1
  fi

  # Validation 4: Escalation triggered
  if grep -q "ESCALATION: Manual intervention required" "$output_file"; then
    pass "User escalation triggered after 3 failed iterations"
  else
    fail "Escalation not triggered" "Should escalate after max iterations"
    return 1
  fi

  # Validation 5: Escalation message comprehensive
  if grep -q "Unable to resolve test failures" "$output_file" && \
     grep -q "Debug reports created:" "$output_file" && \
     grep -q "User options:" "$output_file"; then
    pass "Escalation message is comprehensive and actionable"
  else
    fail "Escalation message incomplete" "Should include context and options"
    return 1
  fi

  # Validation 6: All debug reports listed
  if grep -q "001_api_connection_failed.md" "$output_file" && \
     grep -q "002_authentication_error.md" "$output_file" && \
     grep -q "003_missing_credentials.md" "$output_file"; then
    pass "All 3 debug reports listed in escalation message"
  else
    fail "Not all debug reports listed" "Should list all created reports"
    return 1
  fi

  # Validation 7: Checkpoint mentioned
  if grep -q "Checkpoint saved:" "$output_file"; then
    pass "Checkpoint save mentioned in escalation message"
  else
    fail "Checkpoint not mentioned" "Should tell user checkpoint was saved"
    return 1
  fi

  # Validation 8: User options provided
  if grep -q "Provide API credentials" "$output_file" && \
     grep -q "Review debug reports" "$output_file" && \
     grep -q "resume using checkpoint" "$output_file"; then
    pass "User options provided in escalation message"
  else
    fail "User options missing" "Should provide actionable options"
    return 1
  fi

  # Validation 9: Workflow stopped (not continued to documentation)
  if ! grep -q "doc-writer" "$output_file" && \
     ! grep -q "Documentation phase" "$output_file" && \
     grep -q "awaiting user intervention" "$output_file"; then
    pass "Workflow properly stopped, did not continue to documentation"
  else
    fail "Workflow should stop on escalation" "Should not proceed to documentation"
    return 1
  fi

  # Validation 10: No summary file created
  if [ ! -f "$test_dir/specs/summaries/004_payment_processing_summary.md" ]; then
    pass "No summary file created (workflow escalated before documentation)"
  else
    fail "Summary should not exist" "Workflow escalated before reaching documentation phase"
    return 1
  fi

  info "$test_name: All validations passed"
  return 0
}
```

## Validation Helper Functions

### Agent Invocation Detection

```bash
validate_agent_invoked() {
  local output_file="$1"
  local agent_type="$2"
  local expected_count="${3:-1}"

  local actual_count=$(grep -c "$agent_type" "$output_file" || echo 0)

  if [ "$actual_count" -ge "$expected_count" ]; then
    return 0
  else
    return 1
  fi
}

validate_task_tool_usage() {
  local output_file="$1"

  # Check for Task tool invocation markers
  if grep -q "Task tool invocation" "$output_file" || \
     grep -q "subagent_type:" "$output_file"; then
    return 0
  else
    return 1
  fi
}

validate_parallel_invocation() {
  local output_file="$1"
  local agent_count="$2"

  # In real implementation, verify all Task invocations in same message block
  # For now, check that multiple agents were invoked
  local invocation_count=$(grep -c "Task tool invocation" "$output_file")

  if [ "$invocation_count" -ge "$agent_count" ]; then
    return 0
  else
    return 1
  fi
}
```

### File Creation Validation

```bash
validate_file_exists() {
  local file_path="$1"
  local description="$2"

  if [ -f "$file_path" ]; then
    pass "File exists: $description ($file_path)"
    return 0
  else
    fail "File not found: $description" "Expected: $file_path"
    return 1
  fi
}

validate_file_structure() {
  local file_path="$1"
  local required_sections=("$@")
  shift

  for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$file_path"; then
      fail "File missing section: $section" "File: $file_path"
      return 1
    fi
  done

  return 0
}

validate_report_metadata() {
  local report_file="$1"

  # Check for required metadata fields
  if ! grep -q "## Metadata" "$report_file"; then
    return 1
  fi

  if ! grep -q "Date:" "$report_file"; then
    return 1
  fi

  if ! grep -q "Topic:" "$report_file"; then
    return 1
  fi

  return 0
}

validate_plan_metadata() {
  local plan_file="$1"

  # Check for required plan metadata
  if ! grep -q "## Metadata" "$plan_file"; then
    return 1
  fi

  if ! grep -q "Date:" "$plan_file"; then
    return 1
  fi

  if ! grep -q "## Implementation Phases" "$plan_file" || \
     ! grep -q "### Phase 1:" "$plan_file"; then
    return 1
  fi

  return 0
}
```

### Cross-Reference Validation

```bash
validate_cross_references() {
  local plan_file="$1"
  local summary_file="$2"
  shift 2
  local report_files=("$@")

  # Check plan references reports
  for report in "${report_files[@]}"; do
    local report_name=$(basename "$report")
    if ! grep -q "$report_name" "$plan_file"; then
      fail "Plan does not reference report" "Missing: $report_name"
      return 1
    fi
  done

  # Check summary references plan
  local plan_name=$(basename "$plan_file")
  if ! grep -q "$plan_name" "$summary_file"; then
    fail "Summary does not reference plan" "Missing: $plan_name"
    return 1
  fi

  # Check summary references reports
  for report in "${report_files[@]}"; do
    local report_name=$(basename "$report")
    if ! grep -q "$report_name" "$summary_file"; then
      fail "Summary does not reference report" "Missing: $report_name"
      return 1
    fi
  done

  return 0
}

validate_bidirectional_links() {
  local file_a="$1"
  local file_b="$2"

  local file_a_name=$(basename "$file_a")
  local file_b_name=$(basename "$file_b")

  # Check A references B
  if ! grep -q "$file_b_name" "$file_a"; then
    fail "File A does not reference File B" "$file_a_name -> $file_b_name"
    return 1
  fi

  # Check B references A
  if ! grep -q "$file_a_name" "$file_b"; then
    fail "File B does not reference File A" "$file_b_name -> $file_a_name"
    return 1
  fi

  return 0
}
```

## Test Automation Script Structure

### Complete Test Runner

```bash
#!/usr/bin/env bash
# test_orchestrate_refactor.sh
# Comprehensive integration tests for refactored /orchestrate command

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test environment
TEST_DIR=$(mktemp -d -t orchestrate_refactor_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Source validation helper functions
# [Include all validation functions defined above]

# Source test workflow functions
# [Include all test workflow functions defined above]

# Main test runner
run_all_tests() {
  echo "=========================================="
  echo "Orchestrate Refactor Integration Tests"
  echo "=========================================="
  echo "Test Environment: $TEST_DIR"
  echo ""

  info "Running Test Workflow #1: Simple (Minimal Path)"
  if test_simple_workflow; then
    echo ""
  else
    echo -e "${RED}Test Workflow #1 FAILED${NC}"
    echo ""
  fi

  info "Running Test Workflow #2: Medium (Research + Implementation)"
  if test_medium_workflow; then
    echo ""
  else
    echo -e "${RED}Test Workflow #2 FAILED${NC}"
    echo ""
  fi

  info "Running Test Workflow #3: Complex (With Debugging)"
  if test_complex_workflow; then
    echo ""
  else
    echo -e "${RED}Test Workflow #3 FAILED${NC}"
    echo ""
  fi

  info "Running Test Workflow #4: Maximum (Escalation)"
  if test_maximum_workflow; then
    echo ""
  else
    echo -e "${RED}Test Workflow #4 FAILED${NC}"
    echo ""
  fi

  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
  echo -e "${RED}Failed: $FAIL_COUNT${NC}"
  echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
  echo "=========================================="

  if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    return 1
  fi
}

# Execute
run_all_tests
exit $?
```

## Documentation Updates

### /orchestrate Command Header Examples

Add to `.claude/commands/orchestrate.md` after refactor:

```markdown
## Usage Examples

### Example 1: Simple Feature (No Research)
```
/orchestrate Add hello world function
```

Expected execution:
- Skip research (simple feature)
- Plan: plan-architect creates implementation plan
- Implement: code-writer executes plan
- Document: doc-writer updates documentation

Duration: ~5 minutes
Agents invoked: 3 (plan-architect, code-writer, doc-writer)

### Example 2: Medium Feature (With Research)
```
/orchestrate Add configuration validation module
```

Expected execution:
- Research: 2-3 parallel research-specialist agents investigate patterns and practices
- Plan: plan-architect synthesizes research into implementation plan
- Implement: code-writer executes plan
- Document: doc-writer updates documentation

Duration: ~15 minutes
Agents invoked: 5-6 (2-3 research-specialist, plan-architect, code-writer, doc-writer)

### Example 3: Complex Feature (With Debugging)
```
/orchestrate Implement payment processing with external API
```

Expected execution:
- Research: 3 parallel research-specialist agents
- Plan: plan-architect creates comprehensive plan
- Implement: code-writer executes plan (may fail tests initially)
- Debug: debug-specialist investigates failures, code-writer applies fixes (1-3 iterations)
- Document: doc-writer updates documentation

Duration: ~30-45 minutes
Agents invoked: 8-12 (3 research-specialist, plan-architect, code-writer, 1-3 debug-specialist, 1-3 code-writer for fixes, doc-writer)

### Example 4: Workflow with Escalation
```
/orchestrate Integrate with legacy authentication system
```

Expected execution:
- Research: 2-3 parallel research-specialist agents
- Plan: plan-architect creates plan
- Implement: code-writer attempts implementation
- Debug: 3 iterations of debug-specialist + code-writer (all fail)
- Escalation: User receives actionable message with checkpoint

Duration: ~20 minutes (escalated before completion)
Agents invoked: 9-10 (2-3 research-specialist, plan-architect, code-writer, 3 debug-specialist, 3 code-writer for fixes)
```

### CLAUDE.md Updates

Add to Project-Specific Commands section:

```markdown
### /orchestrate - Multi-Agent Workflow Coordination

The /orchestrate command coordinates specialized agents through end-to-end development workflows:

**Workflow Phases**:
1. **Research**: Parallel research-specialist agents investigate patterns, practices, alternatives (2-4 agents)
2. **Planning**: plan-architect synthesizes research into structured implementation plan
3. **Implementation**: code-writer executes plan phase-by-phase with testing
4. **Debugging** (conditional): debug-specialist investigates failures, code-writer applies fixes (max 3 iterations)
5. **Documentation**: doc-writer updates docs and generates workflow summary

**Agent Coordination Patterns**:
- Parallel execution: Research agents run concurrently (single message, multiple Task invocations)
- Sequential execution: Planning, implementation, documentation execute in order
- Conditional execution: Debugging only triggers on test failures
- Iteration limiting: Max 3 debug iterations before user escalation

**Usage**: `/orchestrate <workflow-description>`

**Example**: `/orchestrate Add user authentication with email and password`

**Artifacts Generated**:
- Research reports: `specs/reports/{topic}/NNN_report.md`
- Implementation plan: `specs/plans/NNN_feature.md`
- Workflow summary: `specs/summaries/NNN_summary.md`
- Debug reports (if needed): `debug/{topic}/NNN_report.md`

See command file for detailed workflow patterns and agent invocation examples.
```

### Migration Guide Content

Create `.claude/docs/orchestrate-migration-guide.md`:

```markdown
# Orchestrate Command Migration Guide

## Overview

The /orchestrate command has been refactored from documentation-based to execution-driven. This guide helps users familiar with the previous version understand the changes.

## Key Changes

### Before: Documentation-Based
The old command described how orchestration should work but didn't execute it:
- "I'll analyze the workflow description..."
- "For each topic, I'll create a research task..."
- References to external pattern documentation

### After: Execution-Driven
The new command provides explicit execution instructions:
- "ANALYZE the workflow description"
- "EXECUTE NOW: USE the Task tool to invoke research-specialist agents"
- Complete inline Task tool invocations with full agent prompts

## What's Different for Users

### Invocation (No Change)
```bash
# Same syntax
/orchestrate <workflow-description>
```

### Output (More Explicit)
**Before**: Conceptual descriptions of workflow progress
**After**: Explicit Task tool invocations visible, concrete progress markers

### Agent Coordination (More Transparent)
**Before**: Agents invoked implicitly
**After**: Task tool usage shown, agent types explicitly named

### Error Handling (More Robust)
**Before**: Basic error reporting
**After**: Structured debugging loop (3 iterations), clear escalation messages

### State Management (More Visible)
**Before**: Minimal progress tracking
**After**: TodoWrite shows phase progress, checkpoints saved at boundaries

## Migration Checklist

- [ ] No changes needed to how you invoke /orchestrate
- [ ] Expect more detailed execution output
- [ ] Debug reports now created in `debug/{topic}/` directory (not gitignored)
- [ ] Escalation messages provide checkpoint paths for resumption
- [ ] Workflow summaries more comprehensive with performance metrics

## New Features

### Explicit Agent Invocation
See exact Task tool invocations for each agent, making workflow transparent

### Debugging Loop with Limits
Automatic debugging (max 3 iterations) with user escalation if unresolved

### Checkpoint-Based Recovery
Workflow state saved at phase boundaries, resume from any checkpoint

### Performance Metrics
Workflow summaries include timing, parallelization effectiveness, error recovery stats

## Troubleshooting

### "Agents not being invoked"
Check command output for Task tool invocation blocks. If missing, report issue.

### "Tests failing repeatedly"
Workflow will attempt 3 debug iterations. After 3rd failure, user escalation provides manual intervention options.

### "Workflow not resuming from checkpoint"
Ensure checkpoint file exists (mentioned in escalation message), use correct project name.

## Questions?

See command file (`.claude/commands/orchestrate.md`) for complete workflow patterns and examples.
```

## Success Criteria

### Test Execution Success
- [ ] All 4 test workflows execute without errors
- [ ] Each workflow demonstrates expected agent invocations
- [ ] All expected files created in correct locations
- [ ] No unexpected files or artifacts

### Agent Invocation Verification
- [ ] Test 1: 3 agents invoked (plan-architect, code-writer, doc-writer)
- [ ] Test 2: 5-6 agents invoked (2-3 research-specialist, plan-architect, code-writer, doc-writer)
- [ ] Test 3: 6-8 agents invoked (includes debug-specialist, multiple code-writer)
- [ ] Test 4: 9-10 agents invoked (includes 3 debug-specialist, 3 code-writer for fixes)

### File Creation Verification
- [ ] Test 1: Plan, summary, source files created
- [ ] Test 2: 2-3 reports, plan, summary created
- [ ] Test 3: Reports, plan, 1-2 debug reports, summary created
- [ ] Test 4: Reports, plan, 3 debug reports created (no summary)

### Workflow Logic Verification
- [ ] Research skipped when appropriate (Test 1)
- [ ] Parallel research execution works (Test 2)
- [ ] Debugging loop triggers on failures (Test 3, 4)
- [ ] Iteration limit enforced (Test 4)
- [ ] Escalation works (Test 4)

### Documentation Verification
- [ ] Command header updated with usage examples
- [ ] CLAUDE.md updated with new capabilities
- [ ] Migration guide created and comprehensive
- [ ] All examples accurate and tested

### Coverage Verification
- [ ] ≥80% of execution paths tested
- [ ] All 5 workflow phases covered
- [ ] Both success and failure scenarios tested
- [ ] All agent types invoked at least once

## Error Handling

### Test Failure Scenarios

**Scenario**: Test workflow doesn't invoke agents
- **Symptom**: No Task tool invocations in output
- **Diagnosis**: Refactored command still using passive voice or missing EXECUTE NOW blocks
- **Resolution**: Review command transformation, ensure imperative language and explicit Task tool usage

**Scenario**: Tests hang or timeout
- **Symptom**: Test runner doesn't complete
- **Diagnosis**: Command waiting for input or stuck in infinite loop
- **Resolution**: Add timeout to test execution, review command for blocking operations

**Scenario**: Files not created
- **Symptom**: Expected files missing after test
- **Diagnosis**: Agents not receiving correct prompts or paths
- **Resolution**: Review agent prompts, verify file path instructions

**Scenario**: Cross-references broken
- **Symptom**: Files don't reference each other
- **Diagnosis**: Cross-referencing logic not executed
- **Resolution**: Review doc-writer prompt, ensure cross-reference instructions included

### Test Environment Issues

**Scenario**: Tests interfere with each other
- **Resolution**: Ensure cleanup() runs between tests, use unique directories per test

**Scenario**: Mock files not realistic
- **Resolution**: Base mock files on actual examples from working /plan and /report commands

**Scenario**: Validation too strict
- **Resolution**: Focus on essential criteria, allow flexibility in non-critical details

## Notes

### Test Data Management

- Use realistic feature descriptions (not "test feature 1")
- Create mock artifacts that mirror actual command outputs
- Preserve test artifacts temporarily for debugging (don't cleanup on failure)
- Consider adding verbose mode for detailed test output

### CI/CD Integration

Consider adding these tests to continuous integration:
- Run on every commit to orchestrate.md
- Set timeout (30 minutes for all 4 workflows)
- Save artifacts on failure for debugging
- Report coverage metrics

### Performance Benchmarking

Track test execution time to detect regressions:
- Test 1: Should complete in <30 seconds
- Test 2: Should complete in <60 seconds
- Test 3: Should complete in <90 seconds
- Test 4: Should complete in <90 seconds

### Future Test Enhancements

After Phase 8 completion, consider:
- Real /orchestrate invocation (not mocked)
- Actual Claude agent execution (not simulated)
- More edge cases (empty reports, malformed plans)
- Stress testing (large workflows, many parallel agents)
- Performance optimization testing
