# /supervise Phase Reference

This document provides detailed technical documentation for each phase of the `/supervise` workflow orchestration command.

## Phase Overview

| Phase | Name | Conditional | Agent | Purpose |
|-------|------|------------|-------|---------|
| 0 | Location & Paths | No | None | Pre-calculate artifact paths |
| 1 | Research | No | research-specialist | Gather information (2-4 parallel agents) |
| 2 | Planning | Yes | plan-architect | Create implementation plan |
| 3 | Implementation | Yes | code-writer | Execute implementation |
| 4 | Testing | Yes | test-runner | Run tests |
| 5 | Debug | Yes | debug-analyst | Fix test failures |
| 6 | Documentation | Yes | doc-writer | Create workflow summary |

## Phase 0: Location and Path Pre-Calculation

### Purpose

Establish topic directory structure and pre-calculate all artifact paths before any agent invocations.

### Execution Condition

**Always executes** - Required for all workflow scopes

### Implementation Pattern

1. Parse workflow description from command arguments
2. Detect workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Source required utility libraries
4. Calculate topic directory path
5. Create directory structure
6. Calculate and export all artifact paths

### Key Functions Used

- `detect_workflow_scope()` - Determine workflow type from description
- `calculate_topic_dir()` - Generate topic directory path
- `calculate_report_path()` - Generate research report paths
- `calculate_plan_path()` - Generate implementation plan path
- `calculate_summary_path()` - Generate workflow summary path

### Success Criteria

- Topic directory created successfully
- All required paths calculated and exported
- Workflow scope correctly detected

### Path Variables Exported

```bash
TOPIC_PATH           # specs/{NNN_topic}/
RESEARCH_SUBDIR      # specs/{NNN_topic}/reports/
PLANS_SUBDIR         # specs/{NNN_topic}/plans/
SUMMARIES_SUBDIR     # specs/{NNN_topic}/summaries/
DEBUG_SUBDIR         # specs/{NNN_topic}/debug/

REPORT_PATHS[]       # Array of research report paths
PLAN_PATH            # Implementation plan path
SUMMARY_PATH         # Workflow summary path
```

## Phase 1: Research

### Purpose

Gather information through parallel research agents (2-4 agents based on complexity).

### Execution Condition

**Always executes** - Required for all workflow scopes

### Implementation Pattern

1. Determine research complexity (2-4 based on workflow description)
2. Generate research topic questions
3. Calculate report paths for each research agent
4. Invoke research agents in parallel via Task tool
5. Verify all research reports created
6. Extract metadata from reports (optional overview synthesis for research-only workflows)

### Agent Used

**research-specialist** (`.claude/agents/research-specialist.md`)

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic N of M"
  prompt: "
    Read behavioral guidelines: .claude/agents/research-specialist.md
    
    Research topic: [specific question]
    Output path: [pre-calculated path]
    
    Create comprehensive research report.
    Return: REPORT_CREATED: [path]
  "
}
```

### Verification Checkpoint

**MANDATORY**: All research report files must exist before continuing to Phase 2

**Verification pattern** (fail-fast):
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    # Success - report exists
  else
    # Failure - structured 5-section diagnostic
    exit 1
  fi
done
```

### Success Criteria

- All research reports created successfully
- Reports contain valid content (>200 bytes, markdown header present)
- At least 50% of research agents succeeded (partial failure handling)

### Conditional Behavior

**research-only workflow**: Creates OVERVIEW.md to synthesize findings

**All other workflows**: No overview (planning agent will synthesize)

## Phase 2: Planning

### Purpose

Create implementation plan based on research findings.

### Execution Condition

**Conditional** - Executes if:
- Workflow scope is `research-and-plan` OR
- Workflow scope is `full-implementation`

**Skips if**:
- Workflow scope is `research-only`
- Workflow scope is `debug-only`

### Implementation Pattern

1. Check execution condition
2. Prepare planning context (research report paths)
3. Invoke plan-architect agent with context
4. Verify plan file created
5. Extract plan metadata (complexity, phase count)

### Agent Used

**plan-architect** (`.claude/agents/plan-architect.md`)

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md
    
    Plan path: [pre-calculated path]
    Research reports: [list of paths]
    Project standards: [CLAUDE.md path]
    
    Create implementation plan following project standards.
    Return: PLAN_CREATED: [path]
  "
}
```

### Verification Checkpoint

**MANDATORY**: Plan file must exist before continuing to Phase 3

**Verification pattern** (fail-fast):
```bash
if [ -f "$PLAN_PATH" ] && [ -s "$PLAN_PATH" ]; then
  # Success - plan exists
else
  # Failure - structured 5-section diagnostic
  exit 1
fi
```

### Success Criteria

- Plan file created successfully
- Plan contains metadata section
- Plan contains at least 3 phases
- Plan complexity score calculated

## Phase 3: Implementation

### Purpose

Execute implementation plan phase-by-phase.

### Execution Condition

**Conditional** - Executes if:
- Workflow scope is `full-implementation`

**Skips if**:
- Workflow scope is `research-only`
- Workflow scope is `research-and-plan`
- Workflow scope is `debug-only`

### Implementation Pattern

1. Check execution condition
2. Invoke code-writer agent with plan and context
3. Verify implementation artifacts directory created
4. Check plan completion markers
5. Extract implementation status

### Agent Used

**code-writer** (`.claude/agents/code-writer.md`)

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/code-writer.md
    
    Plan file: [path]
    Implementation artifacts: [directory path]
    
    Execute implementation following plan phases.
    Return: IMPLEMENTATION_STATUS: [complete|partial]
  "
}
```

### Verification Checkpoint

**MANDATORY**: Implementation artifacts directory must exist

**Verification pattern** (fail-fast):
```bash
if [ ! -d "$IMPL_ARTIFACTS" ]; then
  # Failure - directory not created
  exit 1
else
  # Success - directory exists
fi
```

### Success Criteria

- Implementation artifacts directory exists
- Plan updated with completion markers
- Implementation status reported (complete or partial)

## Phase 4: Testing

### Purpose

Run project tests to verify implementation.

### Execution Condition

**Conditional** - Executes if:
- Workflow scope is `full-implementation`

**Skips if**:
- Workflow scope is `research-only`
- Workflow scope is `research-and-plan`
- Workflow scope is `debug-only`

### Implementation Pattern

1. Check execution condition
2. Invoke test-runner agent
3. Parse test results (status, total, passed, failed)
4. Set flag for Phase 5 based on test status

### Agent Used

**test-runner** (`.claude/agents/test-runner.md`)

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Run project tests"
  prompt: "
    Read behavioral guidelines: .claude/agents/test-runner.md
    
    Test command: [from CLAUDE.md or auto-detect]
    
    Run tests and report results.
    Return: TEST_STATUS: [passing|failing]
  "
}
```

### Verification Checkpoint

**OPTIONAL**: Test status recorded for Phase 5 decision

**Behavior**:
- Tests passing → Skip Phase 5
- Tests failing → Execute Phase 5

### Success Criteria

- Test status determined (passing or failing)
- Test metrics captured (total, passed, failed)

## Phase 5: Debug (Conditional)

### Purpose

Analyze test failures and apply fixes iteratively.

### Execution Condition

**Conditional** - Executes if:
- Tests failed in Phase 4 OR
- Workflow scope is `debug-only`

**Skips if**:
- Tests passing in Phase 4
- No implementation occurred

### Implementation Pattern

1. Check execution condition
2. Iterate debug cycle (max 3 iterations):
   a. Invoke debug-analyst to analyze failures
   b. Verify debug report created
   c. Invoke code-writer to apply fixes
   d. Re-run tests
   e. Check if tests now passing
3. Exit loop if tests pass or max iterations reached

### Agents Used

**debug-analyst** (`.claude/agents/debug-analyst.md`)
**code-writer** (`.claude/agents/code-writer.md`)
**test-runner** (`.claude/agents/test-runner.md`)

### Agent Invocation (Debug Analysis)

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures"
  prompt: "
    Read behavioral guidelines: .claude/agents/debug-analyst.md
    
    Test output: [test results]
    Debug report path: [pre-calculated path]
    
    Analyze failures and propose fixes.
    Return: DEBUG_REPORT_CREATED: [path]
  "
}
```

### Verification Checkpoint

**MANDATORY**: Debug report must exist before applying fixes

**Verification pattern** (fail-fast):
```bash
if [ -f "$DEBUG_REPORT" ] && [ -s "$DEBUG_REPORT" ]; then
  # Success - debug report exists
else
  # Failure - structured 5-section diagnostic
  exit 1
fi
```

### Success Criteria

- Debug report created for each iteration
- Fixes applied successfully
- Tests eventually pass (or max iterations reached)

### Iteration Limits

- **Maximum iterations**: 3
- **Exit conditions**: Tests pass OR max iterations reached

## Phase 6: Documentation

### Purpose

Create workflow summary documenting all artifacts and results.

### Execution Condition

**Conditional** - Executes if:
- Implementation occurred in Phase 3

**Skips if**:
- Workflow scope is `research-only`
- Workflow scope is `research-and-plan`
- No implementation in Phase 3

### Implementation Pattern

1. Check execution condition (implementation occurred)
2. Prepare summary context (all artifact paths, statuses)
3. Invoke doc-writer agent
4. Verify summary file created

### Agent Used

**doc-writer** (`.claude/agents/doc-writer.md`)

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: "
    Read behavioral guidelines: .claude/agents/doc-writer.md
    
    Summary path: [pre-calculated path]
    Plan file: [path]
    Research reports: [list]
    Implementation artifacts: [directory]
    Test status: [passing|failing]
    
    Create workflow summary linking all artifacts.
    Return: SUMMARY_CREATED: [path]
  "
}
```

### Verification Checkpoint

**MANDATORY**: Summary file must exist to complete workflow

**Verification pattern** (fail-fast):
```bash
if [ -f "$SUMMARY_PATH" ] && [ -s "$SUMMARY_PATH" ]; then
  # Success - summary exists
else
  # Failure - structured 5-section diagnostic
  exit 1
fi
```

### Success Criteria

- Summary file created successfully
- Summary links all workflow artifacts
- Summary documents implementation results

## Fail-Fast Error Handling

All verification checkpoints use the **fail-fast pattern** with structured diagnostics:

### 5-Section Diagnostic Format

1. **ERROR**: Clear description of what failed
2. **Expected/Found**: What was supposed to happen vs what actually happened
3. **DIAGNOSTIC INFORMATION**: Paths, directory status, agent details
4. **Diagnostic Commands**: Example commands to debug the issue
5. **Most Likely Causes**: Common reasons for this failure

### Example Diagnostic Output

```
❌ ERROR [Phase 1, Research]: Report file verification failed
   Expected: File exists and has content
   Found: File does not exist

DIAGNOSTIC INFORMATION:
  - Expected path: /path/to/report.md
  - Directory: /path/to/reports/
  - Agent: research-specialist (agent 1/3)

Directory Status:
  ✓ Reports directory exists (2 files)
  Recent files:
    -rw-r--r-- 1 user user 4.2K Oct 28 10:30 001_report.md

Diagnostic Commands:
  # Check directory and permissions
  ls -la /path/to/reports/
  # Check agent behavioral file
  cat .claude/agents/research-specialist.md | head -50
  # Review agent invocation above for errors

Most Likely Causes:
  1. Agent failed to write file (check agent output above for errors)
  2. Path mismatch (agent used different path than expected)
  3. Permission denied (run diagnostic commands to verify)
```

## Partial Failure Handling

**Phase 1 (Research) Only**: Allows continuation if ≥50% of parallel agents succeed

**All Other Phases**: Require 100% success (fail-fast on any error)

### Research Partial Failure Logic

```bash
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  DECISION=$(handle_partial_research_failure $RESEARCH_COMPLEXITY $SUCCESSFUL_REPORT_COUNT)
  if [ "$DECISION" == "terminate" ]; then
    exit 1
  fi
  # Continue with partial results
fi
```

**Termination Condition**: Less than 50% of research agents succeeded

**Continuation Condition**: At least 50% of research agents succeeded

## Checkpoint Recovery

The command supports resumable workflows via checkpoints:

### Checkpoint Saves

- After Phase 1: Research complete
- After Phase 2: Planning complete
- After Phase 3: Implementation complete
- After Phase 4: Testing complete
- After Phase 5: Debug complete

### Checkpoint Data

```json
{
  "workflow_scope": "full-implementation",
  "current_phase": "3",
  "research_reports": ["path1", "path2"],
  "plan_path": "path/to/plan.md",
  "impl_artifacts": "path/to/artifacts/",
  "test_status": "passing"
}
```

### Resume Behavior

Currently, checkpoints are saved but automatic resume is not yet implemented. Checkpoints are cleaned up on successful workflow completion.

## See Also

- [/supervise Usage Guide](../guides/supervise-guide.md) - Usage patterns and examples
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation details
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - Fail-fast error handling
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
