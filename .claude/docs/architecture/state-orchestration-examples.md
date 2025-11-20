# State-Based Orchestration: Examples

**Related Documents**:
- [Overview](state-orchestration-overview.md) - Architecture summary
- [States](state-orchestration-states.md) - State definitions
- [Transitions](state-orchestration-transitions.md) - State transitions

---

## Example 1: Complete Workflow

### Scenario

Implement a new authentication feature with research, planning, implementation, and documentation.

### Implementation

```bash
#!/bin/bash
set -euo pipefail

# Initialize
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

WORKFLOW_DESC="Implement OAuth 2.0 authentication"

# State: Initialize
if ! sm_init "$WORKFLOW_DESC" "coordinate"; then
  echo "ERROR: Initialization failed"
  exit 1
fi

echo "Scope: $WORKFLOW_SCOPE"
echo "Complexity: $RESEARCH_COMPLEXITY"

# Persist classification
init_workflow_state "$(uuidgen)"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# State: Research
if [ "$RESEARCH_COMPLEXITY" -gt 0 ]; then
  sm_transition "initialize" "research"

  # Launch research agents (parallel)
  # ... research execution ...

  append_workflow_state "REPORT_PATHS" "$REPORTS_JSON"
fi

# State: Planning
sm_transition "research" "planning"

# Create plan
# ... planning execution ...

append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# State: Implementation
sm_transition "planning" "implementation"

# Execute phases in waves
for wave in $(seq 1 $WAVE_COUNT); do
  # ... wave execution ...
  append_workflow_state "CURRENT_WAVE" "$wave"
done

# State: Testing
sm_transition "implementation" "testing"

# Run tests
# ... test execution ...

if [ "$TEST_STATUS" = "pass" ]; then
  # State: Documentation
  sm_transition "testing" "documentation"

  # Update docs
  # ... documentation execution ...

  # State: Complete
  sm_transition "documentation" "complete"
  echo "Workflow complete"
else
  # State: Debug
  sm_transition "testing" "debug"
  echo "Tests failed, entering debug"
fi
```

---

## Example 2: Resume from Checkpoint

### Scenario

Resume a workflow that was interrupted during implementation.

### Implementation

```bash
#!/bin/bash

# Check for existing state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${ID}.sh"

if [ -f "$STATE_FILE" ]; then
  # Resume
  CURRENT_STATE=$(load_workflow_state "CURRENT_STATE")
  echo "Resuming from: $CURRENT_STATE"

  # Load persisted state
  WORKFLOW_SCOPE=$(load_workflow_state "WORKFLOW_SCOPE")
  TOPIC_PATH=$(load_workflow_state "TOPIC_PATH")
  PLAN_PATH=$(load_workflow_state "PLAN_PATH")
  CURRENT_WAVE=$(load_workflow_state "CURRENT_WAVE")

  case "$CURRENT_STATE" in
    "implementation")
      # Resume from wave
      for wave in $(seq $CURRENT_WAVE $WAVE_COUNT); do
        execute_wave "$wave"
        append_workflow_state "CURRENT_WAVE" "$wave"
      done
      sm_transition "implementation" "testing"
      ;;
    "testing")
      run_tests
      ;;
    *)
      echo "Cannot resume from: $CURRENT_STATE"
      exit 1
      ;;
  esac
else
  # Start fresh
  sm_init "$WORKFLOW_DESC" "coordinate"
fi
```

---

## Example 3: Hierarchical Supervisor

### Scenario

Use supervisor to coordinate 4 research agents with 95% context reduction.

### Supervisor Implementation

```markdown
# Research Supervisor

## STEP 1: Parse Assignments

Extract topics from orchestrator context.

## STEP 2: Invoke Workers (Parallel)

**EXECUTE NOW**: Invoke research-specialist for each topic

Task {
  subagent_type: "general-purpose"
  description: "Research topic 1"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${TOPICS[0]}
    Output: ${PATHS[0]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research topic 2"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${TOPICS[1]}
    Output: ${PATHS[1]}
}

## STEP 3: Extract Metadata

From each output:
- Title: First heading
- Path: Created path
- Summary: First 200 chars

## STEP 4: Return Aggregation

Return:
```json
{
  "status": "complete",
  "reports": [
    {"title": "...", "path": "...", "summary": "..."},
    {"title": "...", "path": "...", "summary": "..."}
  ]
}
```
```

### Orchestrator Invocation

```markdown
**EXECUTE NOW**: Invoke research supervisor

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - topic: "auth", path: "${PATH_1}"
    - topic: "security", path: "${PATH_2}"
    - topic: "performance", path: "${PATH_3}"
    - topic: "testing", path: "${PATH_4}"
}
```

### Context Reduction

```
Without Supervisor:
4 workers x 2,500 tokens = 10,000 tokens to orchestrator

With Supervisor:
4 workers -> Supervisor -> 110 tokens/worker = 440 tokens

Reduction: 95.6%
```

---

## Example 4: Micro Scope (Skip Research)

### Scenario

Simple bug fix that skips research phase.

### Implementation

```bash
#!/bin/bash

WORKFLOW_DESC="Fix typo in README"

# Initialize
sm_init "$WORKFLOW_DESC" "coordinate"

# Check scope
if [ "$WORKFLOW_SCOPE" = "micro" ]; then
  echo "Micro scope: skipping research"

  # Direct to planning
  sm_transition "initialize" "planning"

  # Simple plan
  PLAN_PATH="${TOPIC_PATH}/plans/001_fix.md"
  create_simple_plan "$PLAN_PATH"

  # Direct to implementation
  sm_transition "planning" "implementation"

  # Single-phase execution
  apply_fix
  run_tests

  # Skip to complete
  sm_transition "implementation" "testing"
  sm_transition "testing" "documentation"
  sm_transition "documentation" "complete"
fi
```

---

## Example 5: Error Recovery

### Scenario

Recover from test failure with debug cycle.

### Implementation

```bash
#!/bin/bash

# After implementation
sm_transition "implementation" "testing"

# Run tests
run_tests

if [ "$TEST_STATUS" = "fail" ]; then
  echo "Tests failed: $TESTS_FAILED failures"

  # Enter debug state
  sm_transition "testing" "debug"

  # Debug cycle (max 3 attempts)
  for attempt in 1 2 3; do
    echo "Debug attempt $attempt"

    # Analyze and fix
    analyze_failures
    apply_fixes

    # Return to testing
    sm_transition "debug" "testing"
    run_tests

    if [ "$TEST_STATUS" = "pass" ]; then
      break
    fi

    sm_transition "testing" "debug"
  done

  if [ "$TEST_STATUS" = "fail" ]; then
    echo "CRITICAL: Tests still failing after 3 attempts"
    exit 1
  fi
fi

# Continue to documentation
sm_transition "testing" "documentation"
```

---

## Example 6: Parallel Wave Execution

### Scenario

Execute 5 phases in 3 waves.

### Implementation

```bash
#!/bin/bash

# Phase dependencies define waves
# Wave 1: Phase 1, Phase 2 (no deps)
# Wave 2: Phase 3 (deps: 1, 2)
# Wave 3: Phase 4, Phase 5 (deps: 3)

execute_waves() {
  local plan="$1"

  # Wave 1
  echo "Executing Wave 1"
  execute_phase_parallel "Phase 1" "Phase 2"
  run_tests
  commit_wave "Wave 1"
  append_workflow_state "CURRENT_WAVE" "1"

  # Wave 2
  echo "Executing Wave 2"
  execute_phase "Phase 3"
  run_tests
  commit_wave "Wave 2"
  append_workflow_state "CURRENT_WAVE" "2"

  # Wave 3
  echo "Executing Wave 3"
  execute_phase_parallel "Phase 4" "Phase 5"
  run_tests
  commit_wave "Wave 3"
  append_workflow_state "CURRENT_WAVE" "3"
}
```

### Timing

```
Sequential: 5 phases x 30s = 150s
Waves: 30s + 30s + 30s = 90s

Savings: 40%
```

---

## Related Documentation

- [Overview](state-orchestration-overview.md)
- [States](state-orchestration-states.md)
- [Transitions](state-orchestration-transitions.md)
- [Troubleshooting](state-orchestration-troubleshooting.md)
