# Command Patterns Reference

This document contains common patterns used across Claude Code commands. Commands reference these patterns to reduce duplication and maintain consistency.

## Table of Contents

- [Agent Invocation Patterns](#agent-invocation-patterns)
- [Checkpoint Management Patterns](#checkpoint-management-patterns)
- [Error Recovery Patterns](#error-recovery-patterns)
- [Artifact Referencing Patterns](#artifact-referencing-patterns)
- [Testing Integration Patterns](#testing-integration-patterns)
- [Progress Streaming Patterns](#progress-streaming-patterns)

---

## Agent Invocation Patterns

### Basic Agent Invocation

Commands use the Task tool to invoke specialized agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief task description (3-5 words)"
  prompt: "Read and follow behavioral guidelines from:
          /path/to/.claude/agents/agent-name.md

          You are acting as [Agent Name] with the tools and constraints
          defined in that file.

          [Specific task instructions]

          Context:
          - [Context item 1]
          - [Context item 2]
  "
}
```

### Parallel Agent Invocation

For independent tasks, invoke multiple agents in parallel:

```yaml
# Agent 1: Research
Task {
  subagent_type: "general-purpose"
  description: "Research existing patterns"
  prompt: "Read /path/to/.claude/agents/research-specialist.md

          Research existing [component] implementations..."
}

# Agent 2: Analysis (runs in parallel)
Task {
  subagent_type: "general-purpose"
  description: "Analyze architecture"
  prompt: "Read /path/to/.claude/agents/code-analyzer.md

          Analyze current architecture..."
}
```

### Sequential Agent Chain

For dependent tasks, chain agents sequentially:

```yaml
# Stage 1: Research
research_result = Task { ... }

# Stage 2: Planning (uses research results)
plan_result = Task {
  prompt: "...
          Research findings: {research_result}
          ..."
}

# Stage 3: Implementation (uses plan)
Task {
  prompt: "...
          Plan: {plan_result}
          ..."
}
```

### Agent Selection Criteria

**research-specialist**
- Use for: Codebase analysis, best practices research
- Tools: Read, Grep, Glob, WebSearch, WebFetch
- When: Complex features requiring understanding existing code

**plan-architect**
- Use for: Structured implementation plans
- Tools: Read, Write, Bash, Grep, Glob
- When: Creating phased, testable plans

**code-writer**
- Use for: Implementation of specific features
- Tools: Read, Edit, Write, Bash
- When: Writing or modifying code

**test-specialist**
- Use for: Test creation and execution
- Tools: Read, Write, Bash
- When: Adding test coverage

**doc-writer**
- Use for: Documentation updates
- Tools: Read, Edit, Write
- When: Synchronizing docs with code changes

---

## Checkpoint Management Patterns

### Saving Checkpoints

Save implementation state for resumability:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Save checkpoint
CHECKPOINT_DATA=$(jq -n \
  --arg phase "$current_phase" \
  --arg plan "$plan_path" \
  --arg status "$phase_status" \
  '{
    phase: $phase,
    plan_path: $plan,
    status: $status,
    timestamp: now | todate
  }')

save_checkpoint "$workflow_id" "$CHECKPOINT_DATA"
```

### Restoring Checkpoints

Resume from saved state:

```bash
# Check for existing checkpoint
if checkpoint_exists "$workflow_id"; then
  CHECKPOINT=$(load_checkpoint "$workflow_id")

  # Extract saved state
  saved_phase=$(echo "$CHECKPOINT" | jq -r '.phase')
  saved_plan=$(echo "$CHECKPOINT" | jq -r '.plan_path')

  echo "Resuming from Phase $saved_phase"
  current_phase="$saved_phase"
else
  echo "Starting fresh implementation"
  current_phase=1
fi
```

### Checkpoint File Structure

Checkpoints are stored in `.claude/checkpoints/`:

```
.claude/checkpoints/
  workflow-001.json
  workflow-002.json
  implement-plan-025.json
```

Format:
```json
{
  "workflow_id": "implement-plan-025",
  "phase": 3,
  "plan_path": "specs/plans/025_feature.md",
  "status": "in_progress",
  "completed_tasks": ["task1", "task2"],
  "timestamp": "2025-10-09T16:45:00Z"
}
```

---

## Error Recovery Patterns

### Retry with Exponential Backoff

For transient failures:

```bash
MAX_RETRIES=3
RETRY_DELAY=2

for attempt in $(seq 1 $MAX_RETRIES); do
  if execute_operation; then
    echo "Success on attempt $attempt"
    break
  else
    if [ $attempt -lt $MAX_RETRIES ]; then
      echo "Attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
      sleep $RETRY_DELAY
      RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
    else
      echo "ERROR: All $MAX_RETRIES attempts failed"
      return 1
    fi
  fi
done
```

### Graceful Degradation

Continue with reduced functionality on non-critical failures:

```bash
# Try optimal path
if command -v jq &>/dev/null; then
  result=$(jq '.field' data.json)
else
  # Fallback to basic parsing
  echo "WARNING: jq not available, using fallback parser"
  result=$(grep '"field"' data.json | cut -d':' -f2)
fi
```

### Error Escalation

Escalate to user when automated recovery fails:

```bash
if ! critical_operation; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: Critical operation failed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Issue: [Specific error description]"
  echo "Context: [What was being attempted]"
  echo ""
  echo "Options:"
  echo "1. Fix the issue manually and re-run command"
  echo "2. Skip this step (may cause issues later)"
  echo "3. Abort and rollback changes"
  echo ""
  read -p "Choice (1-3): " choice

  case $choice in
    1) return 1 ;;  # Exit for manual fix
    2) echo "Skipping step..." ;;  # Continue with warning
    3) rollback_changes; exit 1 ;;  # Abort
  esac
fi
```

### Rollback Patterns

Revert changes on failure:

```bash
# Save original state
ORIGINAL_STATE=$(git stash create)

# Attempt operation
if ! risky_operation; then
  echo "Operation failed, rolling back..."

  if [ -n "$ORIGINAL_STATE" ]; then
    git reset --hard "$ORIGINAL_STATE"
    echo "Rollback complete"
  fi

  return 1
fi
```

---

## Artifact Referencing Patterns

### Pass-by-Reference

Reference artifacts without duplicating content:

```yaml
# Create artifact
artifact_path = "specs/artifacts/feature/analysis.md"
Write(artifact_path, analysis_content)

# Reference in plan
plan_content = "
## Related Artifacts
- [Analysis]({artifact_path})
- [Best Practices](../artifacts/feature/best_practices.md)
"
```

### Cross-Linking

Link between related documents:

```markdown
## Related Documentation

### Research Phase
- [Research Report](../../reports/025_authentication_research.md)

### Planning Phase
- [Implementation Plan](../../plans/026_authentication_implementation.md)

### Implementation Phase
- [Implementation Summary](../../summaries/026_implementation_summary.md)
```

### Artifact Metadata

Include metadata for traceability:

```markdown
# Analysis Report

## Metadata
- **Date**: 2025-10-09
- **Related Plan**: [../plans/025_feature.md](../plans/025_feature.md)
- **Related Reports**: [024_research.md](024_research.md)
- **Author**: research-specialist agent
- **Status**: Complete

## Content
[Analysis content...]
```

---

## Testing Integration Patterns

### Phase-Level Testing

Test after each implementation phase:

```bash
# Read phase testing requirements from plan
PHASE_TESTS=$(grep -A 10 "^### Phase $phase_num:" "$plan_file" | \
              grep -A 5 "^Testing:" | \
              grep "^-" | sed 's/^- //')

# Execute phase tests
echo "Running Phase $phase_num tests..."
while IFS= read -r test_cmd; do
  echo "Test: $test_cmd"

  if eval "$test_cmd"; then
    echo "✓ Test passed"
  else
    echo "✗ Test failed"
    return 1
  fi
done <<< "$PHASE_TESTS"
```

### Test Discovery

Auto-detect tests based on project type:

```bash
# Detect test framework
if [ -f "package.json" ]; then
  TEST_CMD="npm test"
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  TEST_CMD="pytest"
elif [ -f "Makefile" ] && grep -q "^test:" Makefile; then
  TEST_CMD="make test"
elif [ -f ".claude/tests/run_all_tests.sh" ]; then
  TEST_CMD=".claude/tests/run_all_tests.sh"
else
  echo "WARNING: No test framework detected"
  TEST_CMD=""
fi

# Run tests if available
if [ -n "$TEST_CMD" ]; then
  $TEST_CMD || return 1
fi
```

### Test Validation

Verify test results meet criteria:

```bash
# Run tests with coverage
coverage_output=$(pytest --cov=. --cov-report=term)

# Extract coverage percentage
coverage_pct=$(echo "$coverage_output" | grep "^TOTAL" | awk '{print $NF}' | sed 's/%//')

# Validate against threshold
COVERAGE_THRESHOLD=80
if [ "$coverage_pct" -lt "$COVERAGE_THRESHOLD" ]; then
  echo "ERROR: Coverage $coverage_pct% below threshold ${COVERAGE_THRESHOLD}%"
  return 1
fi
```

---

## Progress Streaming Patterns

### TodoWrite Integration

Update task progress in real-time:

```bash
# Initialize task list
TodoWrite(todos: [
  {content: "Phase 1: Setup", status: "pending", activeForm: "Setting up Phase 1"},
  {content: "Phase 2: Implementation", status: "pending", activeForm: "Implementing Phase 2"},
  {content: "Phase 3: Testing", status: "pending", activeForm: "Testing Phase 3"}
])

# Mark task as in progress
TodoWrite(todos: [
  {content: "Phase 1: Setup", status: "in_progress", activeForm: "Setting up Phase 1"},
  {content: "Phase 2: Implementation", status: "pending", activeForm: "Implementing Phase 2"},
  {content: "Phase 3: Testing", status: "pending", activeForm: "Testing Phase 3"}
])

# Complete task
TodoWrite(todos: [
  {content: "Phase 1: Setup", status: "completed", activeForm: "Setting up Phase 1"},
  {content: "Phase 2: Implementation", status: "in_progress", activeForm: "Implementing Phase 2"},
  {content: "Phase 3: Testing", status: "pending", activeForm: "Testing Phase 3"}
])
```

### Status Reporting

Report progress to user:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IMPLEMENTATION PROGRESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Phase: $current_phase/$total_phases"
echo "Tasks: $completed_tasks/$total_tasks completed"
echo "Status: $phase_status"
echo ""

# Progress bar
progress=$((completed_tasks * 100 / total_tasks))
bar_length=$((progress / 2))
bar=$(printf '%*s' "$bar_length" | tr ' ' '█')
echo "Progress: [$bar$(printf '%*s' $((50 - bar_length)))] $progress%"
echo ""
```

### Streaming Updates

Stream updates during long operations:

```bash
# Long-running operation with progress
total_steps=10
for step in $(seq 1 $total_steps); do
  echo "Processing step $step/$total_steps..."

  # Do work
  process_step "$step"

  # Update progress
  progress=$((step * 100 / total_steps))
  echo "Progress: $progress%"
done
```

---

## Usage Examples

### Example 1: Implement with Checkpoints

```bash
# In /implement command
source .claude/lib/checkpoint-utils.sh

# Check for resumable state
if checkpoint_exists "implement-$plan_num"; then
  CHECKPOINT=$(load_checkpoint "implement-$plan_num")
  start_phase=$(echo "$CHECKPOINT" | jq -r '.phase')
  echo "Resuming from Phase $start_phase"
else
  start_phase=1
fi

# Implement phases
for phase in $(seq $start_phase $total_phases); do
  # Save checkpoint before phase
  save_checkpoint "implement-$plan_num" "{\"phase\": $phase, ...}"

  # Implement phase
  implement_phase "$phase"

  # Test phase
  test_phase "$phase"

  # Update progress
  TodoWrite(todos: [...])
done
```

### Example 2: Orchestrate with Agents

```bash
# In /orchestrate command

# Stage 1: Research (parallel agents)
research_results = [
  Task {
    subagent_type: "general-purpose"
    description: "Research existing patterns"
    prompt: "Read .claude/agents/research-specialist.md..."
  },
  Task {
    subagent_type: "general-purpose"
    description: "Research best practices"
    prompt: "Read .claude/agents/research-specialist.md..."
  }
]

# Stage 2: Planning (uses research)
plan_result = Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "Read .claude/agents/plan-architect.md

          Research findings: {research_results}
          ..."
}

# Stage 3: Implementation
Task {
  subagent_type: "general-purpose"
  description: "Implement feature"
  prompt: "Read .claude/agents/code-writer.md

          Plan: {plan_result}
          ..."
}
```

### Example 3: Error Recovery Flow

```bash
# Try operation with retry
MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
  if risky_operation; then
    break
  elif [ $attempt -eq $MAX_RETRIES ]; then
    # Final attempt failed, escalate to user
    echo "ERROR: Operation failed after $MAX_RETRIES attempts"
    echo "Would you like to:"
    echo "1. Continue anyway (may cause issues)"
    echo "2. Abort"
    read -p "Choice: " choice

    case $choice in
      1) echo "Continuing with degraded functionality..." ;;
      2) rollback_changes; exit 1 ;;
    esac
  else
    sleep 2
  fi
done
```

---

## Pattern Updates

When updating patterns:
1. Update this document first
2. Update all referencing commands
3. Test changes with example workflows
4. Document breaking changes in CHANGELOG

## References

- [Agent Registry](../agents/agent-registry.json) - Available agents
- [Checkpoint Utils](../lib/checkpoint-utils.sh) - Checkpoint management
- [Error Utils](../lib/error-utils.sh) - Error handling utilities
- [Testing Guide](../../docs/TESTING.md) - Testing standards
