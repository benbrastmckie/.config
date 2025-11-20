# Workflow Phases: Planning

**Related Documents**:
- [Overview](workflow-phases-overview.md) - Phase coordination
- [Research](workflow-phases-research.md) - Research phase
- [Implementation](workflow-phases-implementation.md) - Code execution

---

## Planning Phase (Sequential Execution)

The planning phase creates a structured implementation plan based on research outputs, organizing work into phases with dependencies for wave-based parallel execution.

## When to Use

- Always after research phase (if performed)
- For any workflow that requires structured implementation
- Skip only for trivial single-file changes

## Quick Overview

1. Load research reports from checkpoint
2. Invoke plan-architect agent with research context
3. Verify plan created at expected path
4. Parse plan for phase count and dependencies
5. Calculate execution waves
6. Save checkpoint with plan data

## Execution Procedure

### Step 1: Load Research Context

```bash
CHECKPOINT=$(load_checkpoint "orchestrate")
RESEARCH_REPORTS=$(echo "$CHECKPOINT" | jq -r '.research.reports[]')
THINKING_MODE=$(echo "$CHECKPOINT" | jq -r '.research.thinking_mode')
```

### Step 2: Pre-Calculate Plan Path

```bash
TOPIC_DIR=$(echo "$CHECKPOINT" | jq -r '.topic_dir')
PLAN_PATH="${TOPIC_DIR}/plans/001_implementation.md"

mkdir -p "$(dirname "$PLAN_PATH")"
```

### Step 3: Invoke Plan Architect

```markdown
**EXECUTE NOW**: Create implementation plan

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    **Context**:
    Feature: ${FEATURE_DESCRIPTION}
    Research Reports:
    ${RESEARCH_REPORTS}

    **Output**:
    Plan Path: ${PLAN_PATH}

    **Requirements**:
    - Structure plan into phases
    - Define dependencies between phases
    - Enable wave-based parallel execution

    Return: PLAN_CREATED: ${PLAN_PATH}
}
```

### Step 4: Verify Plan Created

```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL: Plan not created at $PLAN_PATH"
  exit 1
fi

# Verify plan structure
if ! grep -q "^## Phase" "$PLAN_PATH"; then
  echo "WARN: Plan may be missing phase structure"
fi

echo "Verified: Plan created at $PLAN_PATH"
```

### Step 5: Parse Plan Structure

```bash
# Count phases
PHASE_COUNT=$(grep -c "^## Phase\|^### Phase" "$PLAN_PATH")

# Extract dependencies
DEPENDENCIES=$(grep -A1 "Dependencies:" "$PLAN_PATH" | grep -v "Dependencies:" | tr -d ' ')

echo "Plan has $PHASE_COUNT phases"
```

### Step 6: Calculate Execution Waves

Organize phases into waves based on dependencies:

```bash
# Wave 1: Phases with no dependencies
# Wave 2: Phases depending on Wave 1
# Wave 3: Phases depending on Wave 2

calculate_waves() {
  local plan="$1"

  # Extract phase dependencies
  # Group by dependency level
  # Return wave assignments
}

WAVE_COUNT=$(calculate_waves "$PLAN_PATH")
```

### Step 7: Save Checkpoint

```bash
CHECKPOINT=$(echo "$CHECKPOINT" | jq --arg plan "$PLAN_PATH" \
  --argjson phases "$PHASE_COUNT" \
  --argjson waves "$WAVE_COUNT" '
  .current_phase = "implementation" |
  .planning = {
    plan_path: $plan,
    phase_count: $phases,
    wave_count: $waves
  }
')

save_checkpoint "orchestrate" "$CHECKPOINT"
```

## Plan Structure

Expected plan format:

```markdown
# Implementation Plan: [Feature Name]

## Overview
[Summary of implementation approach]

## Phases

### Phase 1: Core Infrastructure [NOT STARTED]
- **Dependencies**: []
- **Tasks**:
  - [ ] Create base module
  - [ ] Setup configuration

### Phase 2: Main Feature [NOT STARTED]
- **Dependencies**: ["Phase 1"]
- **Tasks**:
  - [ ] Implement core logic
  - [ ] Add error handling

### Phase 3: Testing [NOT STARTED]
- **Dependencies**: ["Phase 2"]
- **Tasks**:
  - [ ] Unit tests
  - [ ] Integration tests

**Note**: Phase headings include status markers (`[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`) for progress tracking. These are managed automatically by /plan and /build commands. See [Plan Progress Tracking](plan-progress-tracking.md) for details.

## Execution Waves
- Wave 1: Phase 1
- Wave 2: Phase 2
- Wave 3: Phase 3
```

## Wave Calculation

### Dependency Graph

```
Phase 1 (no deps) ────┐
                      ├──> Phase 3 (depends on 1, 2)
Phase 2 (no deps) ────┘

Wave 1: [Phase 1, Phase 2] (parallel)
Wave 2: [Phase 3]
```

### Algorithm

```bash
# 1. Find phases with no dependencies -> Wave 1
# 2. Mark Wave 1 as complete
# 3. Find phases whose dependencies are all complete -> Wave 2
# 4. Repeat until all phases assigned
```

## Example Timing

```
Load Research: 1s
Path Calculation: 1s
Agent Invocation: 30s
Verification: 2s
Wave Calculation: 3s
Checkpoint: 1s

Total: ~38s
```

## Key Requirements

1. **Use research context** - Base plan on research findings
2. **Define dependencies** - Enable parallel execution
3. **Calculate waves** - Optimize execution time
4. **Verify structure** - Ensure plan is parseable

---

## Related Documentation

- [Overview](workflow-phases-overview.md)
- [Implementation Phase](workflow-phases-implementation.md)
- [Plan Architect Agent](../../agents/plan-architect.md)
