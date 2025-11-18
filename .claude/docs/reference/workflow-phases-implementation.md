# Workflow Phases: Implementation

**Related Documents**:
- [Overview](workflow-phases-overview.md) - Phase coordination
- [Planning](workflow-phases-planning.md) - Plan creation
- [Testing](workflow-phases-testing.md) - Test execution

---

## Implementation Phase (Wave-based Execution)

The implementation phase executes the plan phases using wave-based parallel execution, running tests after each phase and saving checkpoints for resume capability.

## When to Use

- Always after planning phase
- For any code changes defined in the plan
- Skip only for documentation-only workflows

## Quick Overview

1. Load plan from checkpoint
2. Parse phases and wave assignments
3. Execute each wave (parallel within wave, sequential between waves)
4. Run tests after each phase
5. Create git commits on phase completion
6. Save checkpoint after each wave

## Execution Procedure

### Step 1: Load Plan and Checkpoint

```bash
CHECKPOINT=$(load_checkpoint "orchestrate")
PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.planning.plan_path')
WAVE_COUNT=$(echo "$CHECKPOINT" | jq -r '.planning.wave_count')
CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.implementation.current_phase // 1')
```

### Step 2: Parse Plan Structure

```bash
# Extract phases from plan
PHASES=$(parse_plan_phases "$PLAN_PATH")

# Group by wave
WAVE_1=$(echo "$PHASES" | jq -r '.[] | select(.wave == 1)')
WAVE_2=$(echo "$PHASES" | jq -r '.[] | select(.wave == 2)')
```

### Step 3: Execute Waves

For each wave, execute phases in parallel:

```markdown
## Wave 1 Execution

**EXECUTE NOW**: Execute Wave 1 phases in parallel

Task {
  subagent_type: "general-purpose"
  description: "Implement Phase 1: Core Infrastructure"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md

    Plan: ${PLAN_PATH}
    Phase: Phase 1: Core Infrastructure
    Project Root: ${CLAUDE_PROJECT_DIR}

    Return: PHASE_COMPLETE: Phase 1
}

Task {
  subagent_type: "general-purpose"
  description: "Implement Phase 2: Configuration"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md

    Plan: ${PLAN_PATH}
    Phase: Phase 2: Configuration
    Project Root: ${CLAUDE_PROJECT_DIR}

    Return: PHASE_COMPLETE: Phase 2
}

**VERIFICATION**: Wait for Wave 1 completion before Wave 2
```

### Step 4: Run Tests After Each Phase

```bash
run_phase_tests() {
  local phase="$1"

  # Run test suite
  if ! bash .claude/tests/run_tests.sh; then
    echo "CRITICAL: Tests failed after $phase"
    return 1
  fi

  echo "Tests passed for $phase"
  return 0
}
```

### Step 5: Create Git Commits

```bash
commit_phase() {
  local phase="$1"

  # Stage changes
  git add -A

  # Create commit
  git commit -m "feat: complete $phase

  - Implemented tasks per plan
  - Tests passing

  Generated with Claude Code"

  echo "Committed: $phase"
}
```

### Step 6: Save Checkpoint After Each Wave

```bash
CHECKPOINT=$(echo "$CHECKPOINT" | jq \
  --argjson wave "$CURRENT_WAVE" \
  --arg phases "$(printf '%s\n' "${COMPLETED_PHASES[@]}")" '
  .implementation.current_wave = $wave |
  .implementation.completed_phases = ($phases | split("\n"))
')

save_checkpoint "orchestrate" "$CHECKPOINT"
```

## Wave-based Execution

### Benefits

- **40-60% time savings** from parallel execution
- **Clear checkpoints** for resume capability
- **Isolated failures** - one phase doesn't break others

### Example

```
Plan Phases:
- Phase 1: Core (no deps)
- Phase 2: Auth (no deps)
- Phase 3: Logging (deps: 1, 2)
- Phase 4: Testing (deps: 3)

Wave Assignment:
- Wave 1: [Phase 1, Phase 2] - parallel
- Wave 2: [Phase 3]
- Wave 3: [Phase 4]

Execution:
1. Execute Wave 1 (Phase 1 + Phase 2 in parallel)
2. Verify, test, commit
3. Execute Wave 2 (Phase 3)
4. Verify, test, commit
5. Execute Wave 3 (Phase 4)
6. Verify, test, commit
```

## Error Handling

### Test Failure

```bash
if ! run_phase_tests "$PHASE"; then
  echo "PAUSED: Tests failed at $PHASE"

  # Save checkpoint for resume
  save_checkpoint "orchestrate" "$CHECKPOINT"

  # Exit with error
  exit 1
fi
```

### Phase Failure

```bash
if ! execute_phase "$PHASE"; then
  echo "CRITICAL: Phase $PHASE failed"

  # Attempt rollback
  git reset --hard HEAD

  # Save failure state
  CHECKPOINT=$(echo "$CHECKPOINT" | jq '.state = "failed"')
  save_checkpoint "orchestrate" "$CHECKPOINT"

  exit 1
fi
```

### Resume Capability

```bash
# Check for existing checkpoint
if CHECKPOINT=$(load_checkpoint "orchestrate" 2>/dev/null); then
  CURRENT_WAVE=$(echo "$CHECKPOINT" | jq -r '.implementation.current_wave')
  echo "Resuming from Wave $CURRENT_WAVE"
else
  CURRENT_WAVE=1
fi
```

## Example Timing

```
Without Waves (Sequential):
- Phase 1: 30s
- Phase 2: 25s
- Phase 3: 35s
- Phase 4: 20s
Total: 110s

With Waves (Parallel):
- Wave 1: 30s (Phase 1 + 2 parallel)
- Wave 2: 35s
- Wave 3: 20s
Total: 85s

Savings: 23%
```

## Key Requirements

1. **Use wave-based execution** - Maximize parallelism
2. **Run tests after each phase** - Catch errors early
3. **Create commits** - Track progress
4. **Save checkpoints** - Enable resume

---

## Related Documentation

- [Overview](workflow-phases-overview.md)
- [Testing Phase](workflow-phases-testing.md)
- [Implementation Agent](../../agents/implementation-agent.md)
