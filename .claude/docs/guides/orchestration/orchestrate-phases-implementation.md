# /orchestrate Command - Phases & Implementation

**Part 2 of 2** | [Index](orchestrate-command-index.md)

This document covers the detailed phase-by-phase implementation, examples, and troubleshooting.

---


# Context reduction: 80-90% (wave details removed, keeping summary only)
```

**Phase 3 Token Usage**: <1000 tokens
- Implementation status metadata
- Wave completion summary
- Research/planning metadata pruned

---

## Phase 4: Comprehensive Testing

### Objective

Invoke test-specialist agent to execute comprehensive test suite and report results.

### Agent Invocation

**Test-Specialist Agent Template**:
```
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests with mandatory results file"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${ARTIFACT_OUTPUTS}/test_results.txt
    - Project Standards: ${STANDARDS_FILE}
    - Plan File: ${PLAN_FILE}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}

    **CRITICAL**: Create test results file at path provided above.

    Execute testing following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
    Return: TESTS_FAILED: [number]
  "
}
```

### Verification

**Mandatory Checkpoint**: Test results file must exist

```bash
echo -n "Verifying test results: "

TEST_RESULTS_FILE="${ARTIFACT_OUTPUTS}/test_results.txt"

if [ ! -f "$TEST_RESULTS_FILE" ]; then
  echo ""
  echo "❌ ERROR: Test results file not created"
  echo "   Expected: $TEST_RESULTS_FILE"
  exit 1
fi

# Parse test status from agent output
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

echo "✓ ($TESTS_PASSED/$TESTS_TOTAL passed)"

if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi
```

### Context Optimization

**Test Metadata Only** (not full test output):
```bash
# Store minimal test metadata (pass/fail status only)
store_phase_metadata "phase_4" "complete" "test_status:$TEST_STATUS"

# Keep test output temporarily (needed for potential Phase 5 debugging)
# Will be pruned after Phase 5 or if Phase 5 skipped
```

**Phase 4 Token Usage**: <300 tokens
- Test status metadata (pass/fail counts)
- Full test output retained for potential debugging

---

## Phase 5: Debugging Loop

### Objective

Conditionally invoke debug-analyst agent if Phase 4 tests failed (max 3 iterations).

### Execution Condition

**Phase 5 ONLY executes if**:
- Tests failed in Phase 4 (`TEST_STATUS == "failing"`)
- OR workflow explicitly requests debugging (`WORKFLOW_SCOPE == "debug-only"`)

Otherwise, Phase 5 is skipped entirely.

### Debug Iteration Loop

**Pattern**: Up to 3 debug cycles

```
For iteration 1 to 3:
  Invoke debug-analyst
  ↓
  Parse debug report for proposed fixes
  ↓
  Invoke code-writer to apply fixes
  ↓
  Invoke test-specialist to re-run tests
  ↓
  If tests pass: Break loop (success)
  If tests fail: Continue to next iteration
```

### Agent Invocations

**Debug-Analyst Template** (per iteration):
```
Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures - iteration [N] of 3"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Debug Report Path: ${ARTIFACT_DEBUG}/debug_iteration_[N].md
    - Test Results: ${TEST_RESULTS_FILE}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_ANALYSIS_COMPLETE: [exact absolute path to debug report]
  "
}
```

**Code-Writer Template** (apply fixes):
```
Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes - iteration [N]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Debug Analysis: ${DEBUG_REPORT}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]
    - Task Type: Apply debug fixes

    Execute fix application following all guidelines in behavioral file.
    Return: FIXES_APPLIED: [number]
    Return: FILES_MODIFIED: [comma-separated list]
  "
}
```

**Test-Specialist Template** (re-test):
```
Task {
  subagent_type: "general-purpose"
  description: "Re-run tests after fixes - iteration [N]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${TEST_RESULTS_FILE} (append results)
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]
    - Task Type: Re-run tests after fixes

    Execute tests following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
  "
}
```

### Iteration Control

```bash
for iteration in 1 2 3; do
  # Invoke debug-analyst
  # Invoke code-writer
  # Invoke test-specialist

  # Parse updated test status
  TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)

  if [ "$TEST_STATUS" == "passing" ]; then
    TESTS_PASSING="true"
    echo "✅ Tests passing after $iteration debug iteration(s)"
    break
  fi

  if [ $iteration -eq 3 ]; then
    echo "⚠️  WARNING: Tests still failing after 3 iterations (manual intervention required)"
    TESTS_PASSING="false"
  fi
done
```

### Context Optimization

**Debug Metadata Only**:
```bash
# Store minimal phase metadata (debug status and final test status)
store_phase_metadata "phase_5" "complete" "tests_passing:$TESTS_PASSING"

# Prune test output now that debugging is complete
```

**Phase 5 Token Usage**: <500 tokens per iteration
- Debug status metadata
- Final test status
- Test output pruned after completion

---

## Phase 6: Documentation

### Objective

Invoke doc-writer agent to create workflow summary linking plan, research, and implementation.

### Agent Invocation

**Doc-Writer Agent Template**:
```
Task {
  subagent_type: "general-purpose"
  description: "Generate documentation and workflow summary"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Summary Path: ${ARTIFACT_SUMMARIES}/001_implementation_summary.md
    - Plan File: ${PLAN_FILE}
    - Research Reports: ${RESEARCH_REPORTS_LIST}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}
    - Test Status: ${TEST_STATUS}
    - Workflow Description: ${WORKFLOW_DESCRIPTION}

    **CRITICAL**: Create summary file at path provided above.

    Execute documentation following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: [exact absolute path to summary file]
  "
}
```

### Verification

**Mandatory Checkpoint**: Summary file must exist

```bash
echo -n "Verifying workflow summary: "

SUMMARY_FILE="${ARTIFACT_SUMMARIES}/001_implementation_summary.md"

if [ ! -f "$SUMMARY_FILE" ]; then
  echo ""
  echo "❌ ERROR: Workflow summary not created"
  echo "   Expected: $SUMMARY_FILE"
  exit 1
fi

FILE_SIZE=$(wc -c < "$SUMMARY_FILE")
echo "✓ (${FILE_SIZE} bytes)"
```

### Summary Structure

**Expected Content**:
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- Date Completed: [YYYY-MM-DD]
- Workflow Description: [original description]
- Topic Directory: [path]
- Plan Executed: [link to plan file]
- Research Reports: [links to reports]

## Implementation Overview
[Brief description of what was implemented]

## Key Changes
- [Major change 1 with file references]
- [Major change 2 with file references]

## Test Results
- Total Tests: [N]
- Passing: [N]
- Failing: [N]
- Test Coverage: [percentage]

## Wave Execution Metrics
- Total Waves: [N]
- Total Phases: [N]
- Parallel Phases: [N]
- Time Savings: [percentage]

## Debugging Summary
[Only if Phase 5 executed]
- Iterations Required: [1-3]
- Issues Fixed: [list]
- Final Test Status: [passing|failing]

## Lessons Learned
[Insights from implementation]
```

### Context Optimization

**Final Context Cleanup**:
```bash
# Store summary path only
store_phase_metadata "phase_6" "complete" "$SUMMARY_FILE"

# Prune all workflow metadata (keeping artifacts intact)
prune_workflow_metadata "orchestrate_workflow" "true"  # keep_artifacts=true
```

**Phase 6 Token Usage**: <200 tokens
- Summary path only
- All phase metadata pruned
- Context usage <30% achieved

---

## Advanced Topics

### Checkpoint Detection and Resume

**Checkpoint Schema** (`.claude/data/checkpoints/orchestrate_latest.json`):
```json
{
  "command": "orchestrate",
  "timestamp": "2025-11-07T12:00:00Z",
  "current_phase": "phase_3",
  "workflow_description": "implement user authentication",
  "topic_directory": "/path/to/specs/042_user_authentication",
  "artifact_paths": {
    "research_reports": [
      "/path/to/specs/042_user_authentication/reports/001_auth_patterns.md",
      "/path/to/specs/042_user_authentication/reports/002_security_best_practices.md"
    ],
    "plan_path": "/path/to/specs/042_user_authentication/plans/001_implementation.md",
    "test_status": "failing"
  },
  "phase_status": {
    "phase_0": "complete",
    "phase_1": "complete",
    "phase_2": "complete",
    "phase_3": "in_progress",
    "phase_4": "pending",
    "phase_5": "pending",
    "phase_6": "pending"
  }
}
```

**Resume Behavior**:
```bash
# Check for checkpoint on startup
if command -v restore_checkpoint &>/dev/null; then
  CHECKPOINT_DATA=$(restore_checkpoint "orchestrate" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    # Restore workflow state
    WORKFLOW_TOPIC_DIR=$(echo "$CHECKPOINT_DATA" | jq -r '.topic_directory')
    CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')

    echo "✓ Checkpoint detected - resuming from $CURRENT_PHASE"

    # Skip completed phases, continue from current phase
  fi
fi
```

**Checkpoint Save Points** (after each phase completion):
```bash
# Save checkpoint after Phase N
CHECKPOINT_JSON=$(cat <<EOF
{
  "command": "orchestrate",
  "current_phase": "phase_N",
  "artifact_paths": {...}
}
EOF
)
save_checkpoint "orchestrate" "phase_N" "$CHECKPOINT_JSON"
```

### Dry-Run Mode Implementation

**Flag Detection**:
```bash
# Parse command-line flags
DRY_RUN="false"
PARALLEL_MODE="true"  # Default
CREATE_PR="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --sequential)
      PARALLEL_MODE="false"
      shift
      ;;
    --parallel)
      PARALLEL_MODE="true"
      shift
      ;;
    --create-pr)
      CREATE_PR="true"
      shift
      ;;
    *)
      WORKFLOW_DESCRIPTION="$1"
      shift
      ;;
  esac
done
```

**Dry-Run Behavior**:
```
If --dry-run:
  Phase 0: Location detection (execute - no side effects)
  ↓
  Phase 1: Research analysis (preview topics, NO agent invocation)
  ↓
  Phase 2: Planning preview (show what would be planned, NO agent invocation)
  ↓
  Phase 3-6: Skip entirely (preview message: "Would execute Phase N")
  ↓
  Display workflow summary:
    - Research topics identified: [list]
    - Estimated research agents: [N]
    - Estimated plan complexity: [score]
    - Estimated implementation time: [duration]
    - Files that would be created: [paths]
    - NO actual agent invocations
    - NO file creation
```

**Example Dry-Run Output**:
```
Workflow Preview (--dry-run):

Phase 0: Location Detection
  ✓ Topic directory: specs/042_user_authentication
  ✓ Artifact paths calculated

Phase 1: Research (preview)
  Would invoke 3 research agents:
    1. Authentication patterns research
    2. Security best practices research
    3. Session management research
  Would create 3 reports in: specs/042_user_authentication/reports/

Phase 2: Planning (preview)
  Would invoke plan-architect agent
  Would create plan: specs/042_user_authentication/plans/001_implementation.md
  Estimated complexity: Medium (6/10)
  Estimated time: 3-4 hours

Phase 3: Implementation (preview)
  Would invoke implementer-coordinator agent
  Would execute wave-based parallel implementation
  Estimated phases: 7
  Estimated waves: 3

Phase 4-6: Testing, Debugging, Documentation (preview)
  Would execute if implementation phase runs
  Test suite: specs/042_user_authentication/outputs/test_results.txt
  Summary: specs/042_user_authentication/summaries/001_implementation_summary.md

Total estimated workflow duration: 4-5 hours
```

### Reference Files Integration

**Orchestration Patterns Reference** (`.claude/docs/reference/workflows/orchestration-reference.md`):

Contains complete agent prompt templates for:
- research-specialist
- plan-architect
- implementer-coordinator
- test-specialist
- debug-analyst
- code-writer
- doc-writer

**Usage in Command**:
```bash
# Reference patterns file for template lookup
PATTERNS_FILE="${CLAUDE_PROJECT_DIR}/.claude/docs/reference/workflows/orchestration-reference.md"

# Extract specific agent template
AGENT_TEMPLATE=$(sed -n '/## research-specialist/,/## [^#]/p' "$PATTERNS_FILE")
```

**Benefits**:
- Centralized agent prompt management
- Consistent agent invocation across commands
- Easy template updates (single source of truth)
- Reduced command file size

---

## Troubleshooting

### Common Issues

#### Issue 1: Meta-Confusion Loops

**Symptoms**:
- Command attempts to "invoke /orchestrate"
- Recursive invocation before first bash block executes
- "Now let me use the /orchestrate command..." in output

**Cause**:
- Mixed documentation and executable content
- Extensive prose before first executable instruction

**Solution**:
- **RESOLVED**: Executable/documentation separation eliminates this issue
- Executable file (`orchestrate.md`) contains only bash blocks and agent templates
- All documentation moved to this guide file

**Verification**:
```bash
# Check executable file size (should be <300 lines)
wc -l .claude/commands/orchestrate.md

# Verify no extensive prose before first bash block
head -50 .claude/commands/orchestrate.md
```

#### Issue 2: Agent Failed to Create Expected File

**Symptoms**:
- Error message: "Agent failed to create expected file"
- Verification checkpoint fails
- Workflow terminates

**Cause**:
- Agent behavioral file missing or incorrect
- Agent misinterpreted path instructions
- File system permissions issue
- Path calculation error in Phase 0

**Solution**:
```bash
# 1. Verify agent behavioral file exists
ls -la .claude/agents/[agent-name].md

# 2. Check topic directory permissions
ls -la specs/

# 3. Verify path calculation from Phase 0
echo $WORKFLOW_TOPIC_DIR
echo $ARTIFACT_REPORTS

# 4. Check agent output for error messages
# (agent output shown before verification checkpoint)

# 5. List directory contents to see what was created
ls -la $WORKFLOW_TOPIC_DIR/reports/
```

**Diagnostic Information**:
```bash
# Check if agent completed without errors
# If yes: Agent completed but created file with wrong name/path
# If no: Agent encountered execution error

# Check for partial file creation
find $WORKFLOW_TOPIC_DIR -type f -mmin -10
# Shows files created in last 10 minutes

# Verify agent behavioral file matches expected template
diff .claude/agents/research-specialist.md .claude/agents/_template-agent.md
```

#### Issue 3: Checkpoint Resume Failure

**Symptoms**:
- Checkpoint detected but resume fails
- State variables not restored correctly
- Phases re-execute from beginning

**Cause**:
- Checkpoint file corrupted or incomplete
- JSON parsing error in checkpoint data
- Missing jq dependency

**Solution**:
```bash
# 1. Check checkpoint file exists and is valid JSON
cat .claude/data/checkpoints/orchestrate_latest.json | jq .

# 2. Verify checkpoint age (stale checkpoints ignored)
ls -lh .claude/data/checkpoints/orchestrate_latest.json

# 3. Manually inspect checkpoint content
cat .claude/data/checkpoints/orchestrate_latest.json

# 4. Delete corrupted checkpoint and restart
rm .claude/data/checkpoints/orchestrate_latest.json
/orchestrate "your workflow description"

# 5. Install jq if missing
sudo apt-get install jq  # Debian/Ubuntu
brew install jq          # macOS
```

#### Issue 4: Parallel Research Agents Not Executing

**Symptoms**:
- Only 1 research agent invoked despite complexity score >1
- Sequential execution instead of parallel
- Research phase takes longer than expected

**Cause**:
- `--sequential` flag provided
- Parallel execution disabled in configuration
- Agent invocation error (first agent failed, others skipped)

**Solution**:
```bash
# 1. Check command-line flags
# Ensure --sequential flag NOT provided

# 2. Verify RESEARCH_COMPLEXITY calculation
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"
echo $?  # Should be 0 if matched

# 3. Check agent invocation count
# Look for multiple "Task {" invocations in execution output

# 4. Force parallel mode explicitly
/orchestrate "your workflow" --parallel

# 5. Check for agent failures
# Look for error messages before "Verifying research reports" checkpoint
```

#### Issue 5: Tests Passing But Debugging Invoked

**Symptoms**:
- Phase 4 reports "All tests passing"
- Phase 5 (Debugging) executes anyway
- Unnecessary debug iterations

**Cause**:
- `TESTS_PASSING` flag not set correctly
- Test status parsing error
- Agent returned incorrect TEST_STATUS signal

**Solution**:
```bash
# 1. Verify TEST_STATUS parsing
echo "$AGENT_OUTPUT" | grep "TEST_STATUS:"
# Should show: TEST_STATUS: passing

# 2. Check TESTS_PASSING flag
echo $TESTS_PASSING
# Should be: true

# 3. Verify Phase 5 execution condition
if [ "$TESTS_PASSING" == "false" ]; then
  echo "Phase 5 will execute (tests failing)"
else
  echo "Phase 5 will be skipped (tests passing)"
fi

# 4. Check test results file content
cat $TEST_RESULTS_FILE | grep -i "fail\|error"
# If no failures found, TEST_STATUS should be "passing"
```

### Debug Mode

**Enable verbose logging**:
```bash
export ORCHESTRATE_DEBUG=1
/orchestrate "your workflow"
```

**Output**: Detailed logging of:
- Library function calls
- Agent invocations with full prompts
- Verification checkpoints
- Context pruning operations
- Checkpoint saves/restores

### Getting Help

- Check [Orchestration Best Practices Guide](./orchestration-best-practices.md) for patterns
- Review [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md)
- See [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md)
- Consult [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for agent invocation details

---

## See Also

- [Orchestration Best Practices Guide](./orchestration-best-practices.md) - Unified framework for all orchestration commands
- [Orchestration Troubleshooting Guide](./orchestration-troubleshooting.md) - Debugging procedures
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution details
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context optimization
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning techniques
- [Command Reference](../reference/standards/command-reference.md) - Quick syntax reference
- [/coordinate Command Guide](./coordinate-command-guide.md) - Related orchestration command with workflow scope detection
