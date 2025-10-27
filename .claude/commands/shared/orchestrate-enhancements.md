# Orchestration Enhancements Reference

This file documents reusable patterns for the enhanced `/orchestrate` command, including automated complexity evaluation, plan expansion, and wave-based parallelization.

## Table of Contents

1. [Overview](#overview)
2. [Complexity Evaluation Patterns](#complexity-evaluation-patterns)
3. [Plan Expansion Patterns](#plan-expansion-patterns)
4. [Wave-Based Execution Patterns](#wave-based-execution-patterns)
5. [Context Preservation Patterns](#context-preservation-patterns)
6. [Progress Markers](#progress-markers)

---

## Overview

The enhanced orchestration system adds three major capabilities between planning and implementation:

1. **Complexity Evaluation**: Automated analysis of phase complexity using hybrid scoring
2. **Plan Expansion**: Automatic expansion of complex phases to separate files
3. **Wave-Based Execution**: Parallel execution of independent phases based on dependencies

These enhancements provide 40-60% time savings during implementation while maintaining <30% context usage.

---

## Complexity Evaluation Patterns

### Hybrid Evaluation Pattern

**Purpose**: Combine fast threshold scoring with accurate agent-based scoring for optimal performance and accuracy.

**Pattern**:
```bash
# Step 1: Source complexity utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Step 2: Evaluate each phase
for phase_num in $(seq 1 $PHASE_COUNT); do
  # Extract phase context
  PHASE_NAME=$(extract_phase_name "$PLAN_PATH" "$phase_num")
  TASK_LIST=$(extract_phase_tasks "$PLAN_PATH" "$phase_num")

  # Run hybrid complexity evaluation
  COMPLEXITY_JSON=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_PATH")

  # Parse results
  FINAL_SCORE=$(echo "$COMPLEXITY_JSON" | jq -r '.final_score')
  EVAL_METHOD=$(echo "$COMPLEXITY_JSON" | jq -r '.evaluation_method')

  # Check expansion recommendation
  if awk -v score="$FINAL_SCORE" 'BEGIN {exit !(score >= 8.0)}'; then
    PHASES_TO_EXPAND+=("$phase_num")
  fi
done
```

**Key Points**:
- Threshold scoring runs first (instant)
- Agent invoked only if threshold ≥7 or tasks ≥8
- Agent failure falls back to threshold
- Results include confidence scores

### Complexity Evaluation Progress Markers

**Pattern**:
```
PROGRESS: Starting Complexity Evaluation Phase
PROGRESS: Evaluating Phase N/M complexity...
PROGRESS: Phase N - score: X.X (method) - expansion decision
PROGRESS: Complexity Evaluation Phase complete - N/M phases need expansion
```

**Example**:
```
PROGRESS: Starting Complexity Evaluation Phase
PROGRESS: Evaluating Phase 1/5 complexity...
PROGRESS: Phase 1 - score: 5.0 (threshold) - no expansion
PROGRESS: Evaluating Phase 2/5 complexity...
PROGRESS: Invoking complexity-estimator agent for Phase 2...
PROGRESS: Phase 2 - score: 9.0 (agent, high confidence) - expansion recommended
PROGRESS: Evaluating Phase 3/5 complexity...
PROGRESS: Phase 3 - score: 6.5 (threshold) - no expansion
PROGRESS: Evaluating Phase 4/5 complexity...
PROGRESS: Invoking complexity-estimator agent for Phase 4...
PROGRESS: Phase 4 - score: 8.5 (agent, medium confidence) - expansion recommended
PROGRESS: Evaluating Phase 5/5 complexity...
PROGRESS: Phase 5 - score: 4.0 (threshold) - no expansion
PROGRESS: Complexity Evaluation Phase complete - 2/5 phases need expansion
```

### Error Handling Pattern

**Agent Invocation Failure**:
```bash
COMPLEXITY_JSON=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_PATH")

EVAL_METHOD=$(echo "$COMPLEXITY_JSON" | jq -r '.evaluation_method')

if [ "$EVAL_METHOD" = "threshold_fallback" ]; then
  echo "⚠ Warning: Agent evaluation failed, using threshold scoring"
  AGENT_ERROR=$(echo "$COMPLEXITY_JSON" | jq -r '.agent_error')
  echo "Agent error: $AGENT_ERROR"
  # Continue with threshold score - workflow not blocked
fi
```

**Parsing Failures**:
```bash
# Validate JSON structure
if ! echo "$COMPLEXITY_JSON" | jq empty 2>/dev/null; then
  echo "ERROR: Invalid complexity evaluation JSON"
  # Fallback: Use threshold scoring only
  THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
  COMPLEXITY_JSON=$(jq -n --argjson score "$THRESHOLD_SCORE" '{final_score:$score,evaluation_method:"threshold_fallback"}')
fi
```

---

## Plan Expansion Patterns

### Expansion Coordination Pattern

**Purpose**: Coordinate parallel or sequential expansion based on phase dependencies.

**Parallel Expansion Pattern** (independent phases):
```markdown
I'll expand 3 complex phases in parallel:

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 2"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/plan-structure-manager.md

          Operation: expand

          Task: Expand phase 2 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 2
          Complexity Score: 9.0

          Use SlashCommand tool to invoke:
          /expand phase [PLAN_PATH] 2 --auto-mode

          Return expansion validation JSON."
}

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 4"
  prompt: "... similar prompt for phase 4 ..."
}

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 5"
  prompt: "... similar prompt for phase 5 ..."
}
```

**Critical**: All Task invocations MUST be in a single message for true parallel execution.

**Sequential Expansion Pattern** (dependent phases):
```bash
# Expand phases sequentially
for phase_num in $PHASES_TO_EXPAND; do
  echo "PROGRESS: Expanding phase $phase_num..."

  # Invoke plan_expander agent
  EXPANSION_RESULT=$(invoke_plan_expander "$PLAN_PATH" "$phase_num")

  # Verify expansion succeeded
  EXPANSION_STATUS=$(echo "$EXPANSION_RESULT" | jq -r '.expansion_status')

  if [ "$EXPANSION_STATUS" != "success" ]; then
    echo "ERROR: Phase $phase_num expansion failed"
    save_checkpoint_and_escalate
    exit 1
  fi

  echo "PROGRESS: Phase $phase_num expanded successfully"
done
```

### Expansion Verification Pattern

**Purpose**: Verify all expansions completed successfully before proceeding.

**Pattern**:
```bash
# Collect expansion results
declare -a EXPANSION_RESULTS
for result in "${AGENT_OUTPUTS[@]}"; do
  EXPANSION_RESULTS+=("$result")
done

# Verify all expansions succeeded
TOTAL_EXPANSIONS=${#EXPANSION_RESULTS[@]}
SUCCESSFUL_EXPANSIONS=0

for result in "${EXPANSION_RESULTS[@]}"; do
  STATUS=$(echo "$result" | jq -r '.expansion_status')

  if [ "$STATUS" = "success" ]; then
    ((SUCCESSFUL_EXPANSIONS++))

    # Verify validation details
    FILE_EXISTS=$(echo "$result" | jq -r '.validation.file_exists')
    PARENT_UPDATED=$(echo "$result" | jq -r '.validation.parent_plan_updated')
    METADATA_CORRECT=$(echo "$result" | jq -r '.validation.metadata_correct')

    if [ "$FILE_EXISTS" = "false" ] || [ "$PARENT_UPDATED" = "false" ]; then
      echo "⚠ Warning: Validation issues detected in expansion"
    fi
  fi
done

# Summary
echo "PROGRESS: Expansion Phase complete - $SUCCESSFUL_EXPANSIONS/$TOTAL_EXPANSIONS phases expanded"

if [ $SUCCESSFUL_EXPANSIONS -ne $TOTAL_EXPANSIONS ]; then
  echo "ERROR: Some expansions failed - aborting workflow"
  save_checkpoint_and_escalate
  exit 1
fi
```

### Expansion Progress Markers

**Pattern**:
```
PROGRESS: Starting Plan Expansion Phase
PROGRESS: Complexity evaluation identified N phases for expansion
PROGRESS: Expansion strategy: parallel|sequential
PROGRESS: Invoking N plan_expander agents...
PROGRESS: Plan expander agent M/N completed (phase X)
PROGRESS: Verifying expansion results...
PROGRESS: All N expansions verified successfully
PROGRESS: Plan structure updated - now Level 1
PROGRESS: Plan Expansion Phase complete
```

---

## Wave-Based Execution Patterns

### Dependency Analysis Pattern

**Purpose**: Calculate execution waves using topological sorting for parallel execution.

**Pattern**:
```bash
# Step 1: Source dependency analysis utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/dependency-analysis.sh"

# Step 2: Validate dependencies
if ! validate_dependencies "$PLAN_PATH"; then
  echo "ERROR: Invalid dependencies found in plan"
  save_checkpoint_and_escalate
  exit 1
fi

# Step 3: Check for circular dependencies
if ! detect_circular_dependencies "$PLAN_PATH"; then
  echo "ERROR: Circular dependencies detected in plan"
  save_checkpoint_and_escalate
  exit 1
fi

# Step 4: Calculate execution waves (Kahn's algorithm)
WAVES_JSON=$(calculate_execution_waves "$PLAN_PATH")

WAVE_COUNT=$(echo "$WAVES_JSON" | jq 'length')
echo "PROGRESS: Calculated $WAVE_COUNT execution waves"

# Display wave structure
for wave_idx in $(seq 0 $((WAVE_COUNT - 1))); do
  WAVE_PHASES=$(echo "$WAVES_JSON" | jq -r ".[$wave_idx] | join(\", \")")
  echo "PROGRESS: Wave $((wave_idx + 1)): phases $WAVE_PHASES"
done
```

### Wave Execution Loop Pattern

**Purpose**: Execute phases wave-by-wave with parallel execution within waves.

**Pattern**:
```bash
# Execute each wave
for wave_idx in $(seq 0 $((WAVE_COUNT - 1))); do
  WAVE_NUM=$((wave_idx + 1))
  WAVE_PHASES=$(echo "$WAVES_JSON" | jq -r ".[$wave_idx][]")
  PHASE_COUNT=$(echo "$WAVE_PHASES" | wc -w)

  echo "PROGRESS: Starting Wave $WAVE_NUM ($PHASE_COUNT phases)"

  if [ $PHASE_COUNT -eq 1 ]; then
    # Single phase - execute sequentially
    phase_num=$WAVE_PHASES
    echo "PROGRESS: Executing phase $phase_num..."
    invoke_code_writer "$PLAN_PATH" "$phase_num"
    echo "PROGRESS: Phase $phase_num complete"
  else
    # Multiple phases - execute in parallel
    echo "PROGRESS: Executing $PHASE_COUNT phases in parallel..."
    invoke_parallel_code_writers "$WAVE_PHASES"
    echo "PROGRESS: All $PHASE_COUNT phases in wave complete"
  fi

  # Verify all phases in wave completed successfully
  for phase_num in $WAVE_PHASES; do
    if ! verify_phase_completion "$PLAN_PATH" "$phase_num"; then
      echo "ERROR: Phase $phase_num failed"
      save_checkpoint_and_escalate
      exit 1
    fi
  done

  echo "PROGRESS: Wave $WAVE_NUM complete - proceeding to next wave"
done

echo "PROGRESS: All waves complete - implementation finished"
```

### Parallel Code-Writer Invocation Pattern

**Purpose**: Invoke multiple code-writer agents in parallel for independent phases.

**Pattern**:
```markdown
I'll implement N independent phases in parallel (Wave M):

Task {
  subagent_type: "general-purpose"
  description: "Implement phase X"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/code-writer.md

          Task: Implement phase X of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: X

          Use SlashCommand tool to invoke:
          /implement [PLAN_PATH] X

          Mark phase complete and create git commit when done."
}

[... additional Task invocations for other phases in wave ...]
```

**Critical**: All Task invocations MUST be in a single message for true parallel execution.

### Wave-Based Progress Markers

**Pattern**:
```
PROGRESS: Starting Dependency Analysis Phase
PROGRESS: Validating phase dependencies...
PROGRESS: All dependencies valid ✓
PROGRESS: Checking for circular dependencies...
PROGRESS: No circular dependencies detected ✓
PROGRESS: Calculating execution waves...
PROGRESS: Calculated N execution waves
PROGRESS: Wave 1: phases [list]
PROGRESS: Wave 2: phases [list]
...
PROGRESS: Starting Wave-Based Implementation
PROGRESS: Starting Wave M (N phases)
PROGRESS: Executing N phases in parallel...
PROGRESS: Phase X complete ✓
PROGRESS: Wave M complete - proceeding to next wave
...
PROGRESS: All waves complete - implementation finished
```

### Wave Execution Error Handling

**Phase Failure in Wave**:
```bash
# If any phase in wave fails, abort wave
for phase_num in $WAVE_PHASES; do
  if ! verify_phase_completion "$PLAN_PATH" "$phase_num"; then
    echo "ERROR: Phase $phase_num failed in Wave $WAVE_NUM"

    # Check which phases succeeded
    for p in $WAVE_PHASES; do
      if verify_phase_completion "$PLAN_PATH" "$p"; then
        echo "Phase $p: SUCCESS"
      else
        echo "Phase $p: FAILED"
      fi
    done

    # Save checkpoint with partial progress
    save_checkpoint "orchestrate" "$WORKFLOW_STATE"

    # Enter debugging loop for failed phase
    echo "PROGRESS: Entering debugging loop for phase $phase_num"
    enter_debugging_loop "$phase_num"
  fi
done
```

---

## Context Preservation Patterns

### Spec Updater Invocation Pattern

**Purpose**: Maintain <30% context usage by externalizing artifacts and updating checkpoints.

**Invocation Points**:
1. After research phase
2. After planning phase
3. After complexity evaluation
4. After expansion
5. After each implementation phase
6. After documentation

**Pattern**:
```bash
# Calculate context usage
CURRENT_CONTEXT=$(estimate_context_usage)

# If approaching threshold, invoke spec updater
if awk -v context="$CURRENT_CONTEXT" 'BEGIN {exit !(context >= 25.0)}'; then
  echo "PROGRESS: Context usage at ${CURRENT_CONTEXT}% - invoking spec updater"

  # Invoke spec updater to clean context
  invoke_spec_updater "$WORKFLOW_STATE"

  # Verify context reduced
  NEW_CONTEXT=$(estimate_context_usage)
  echo "PROGRESS: Context usage reduced to ${NEW_CONTEXT}%"
fi
```

### Checkpoint-Based State Management

**Purpose**: Store workflow state in checkpoint rather than keeping in context.

**Pattern**:
```bash
# Create checkpoint with essential state
CHECKPOINT_DATA=$(jq -n \
  --arg phase "$CURRENT_PHASE" \
  --argjson reports "$(echo "${RESEARCH_REPORTS[@]}" | jq -R -s -c 'split(" ")')" \
  --arg plan "$PLAN_PATH" \
  '{
    checkpoint_type: "orchestrate",
    current_phase: $phase,
    completed_phases: ["research", "planning"],
    context_preservation: {
      research_reports: $reports,
      plan_path: $plan
    }
  }')

# Save checkpoint (state externalized)
save_checkpoint "orchestrate" "$CHECKPOINT_DATA"

# Clear research reports from context (now in checkpoint)
unset RESEARCH_REPORTS
```

### Context Usage Monitoring

**Pattern**:
```bash
# Track context usage at each phase
CONTEXT_LOG=$(jq -n \
  --arg research "$RESEARCH_CONTEXT" \
  --arg planning "$PLANNING_CONTEXT" \
  --arg complexity "$COMPLEXITY_CONTEXT" \
  '{
    research_phase_context: $research,
    planning_phase_context: $planning,
    complexity_eval_context: $complexity
  }')

# Log peak usage
PEAK_CONTEXT=$(echo "$CONTEXT_LOG" | jq -r 'to_entries | max_by(.value) | .value')
echo "PROGRESS: Peak context usage: ${PEAK_CONTEXT}%"

# Alert if exceeding target
if awk -v peak="$PEAK_CONTEXT" 'BEGIN {exit !(peak >= 30.0)}'; then
  echo "⚠ Warning: Context usage exceeded 30% target"
fi
```

---

## Progress Markers

### Standard Progress Marker Format

All progress markers use consistent format:

```
PROGRESS: [phase] - [action_description]
```

### Phase Transition Markers

```
PROGRESS: Starting [Phase Name] Phase
PROGRESS: [Phase Name] Phase complete - [summary]
```

### Agent Invocation Markers

```
PROGRESS: Invoking N [agent-type] agents [execution-mode]...
PROGRESS: [Agent type] agent M/N completed ([context])
```

### Operation Markers

```
PROGRESS: [Operation description]...
PROGRESS: [Operation result] ✓
```

### Error and Warning Markers

```
ERROR: [Error description]
⚠ Warning: [Warning description]
```

### Usage Notes

- Use `PROGRESS:` for all status updates
- Include context when helpful (phase numbers, counts, percentages)
- Mark success with ✓
- Keep messages concise (one line)
- End with ellipsis (...) for in-progress operations
- No ellipsis for completed operations

---

## Integration with Other Commands

### `/orchestrate` Integration

Reference this file from orchestrate.md:

```markdown
For complexity evaluation, expansion, and wave-based patterns, see:
`.claude/commands/shared/orchestrate-enhancements.md`
```

### `/implement` Integration

Wave-based execution uses `/implement` unchanged:
- `/implement` receives plan path and phase number
- Respects Dependencies field in phase metadata
- No modifications needed

### `/expand` Integration

Expansion uses `/expand` with `--auto-mode`:
- Returns JSON for automation
- Preserves spec updater checklist
- Non-interactive operation

### `/revise` Integration

Adaptive planning during orchestration:
- Auto-invoked if complexity exceeds estimates
- Can update dependencies
- Recalculates waves after revision

---

## Related Files

- **orchestration-patterns.md**: Agent prompt templates
- **workflow-phases.md**: Base workflow phase patterns
- **phase-execution.md**: Implementation phase execution
- **phase_dependencies.md**: Dependency syntax documentation
- **orchestration_enhancement_guide.md**: User-facing guide

---

**Last Updated**: 2025-10-16
**Used By**: /orchestrate
**Plan Reference**: specs/009_orchestration_enhancement_adapted/009_orchestration_enhancement_adapted.md
