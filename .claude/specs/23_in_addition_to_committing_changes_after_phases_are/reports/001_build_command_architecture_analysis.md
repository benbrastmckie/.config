# Build Command Architecture Analysis

## Metadata
- **Date**: 2025-11-17
- **Topic**: /build Command Enhancement Research
- **Research Complexity**: 3
- **Related Files**:
  - `/home/benjamin/.config/.claude/commands/build.md`
  - `/home/benjamin/.config/.claude/commands/implement.md`
  - `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

## Executive Summary

The /build command is a build-from-plan workflow that executes existing implementation plans through implementation, testing, debugging (if needed), and documentation phases. Current architecture uses state machine orchestration with checkpoint recovery and subprocess isolation patterns.

**Key Findings**:
1. /build uses 6-part structure with bash block isolation
2. State machine transitions: INIT → IMPLEMENT → TEST → (DEBUG|DOCUMENT) → COMPLETE
3. Auto-resume capability via checkpoint recovery (<24 hours)
4. Plan updates NOT currently implemented in /build
5. Continuous execution NOT currently implemented (single-pass execution only)

## Current Architecture

### Part 1: Argument Parsing and Plan Discovery (Lines 24-148)

**Capabilities**:
- Auto-resume from checkpoint (24-hour window)
- Fallback to most recent plan in specs/*/plans/
- Starting phase selection support
- Dry-run mode for preview

**Auto-Resume Logic**:
```bash
# Strategy 1: Check checkpoint
CHECKPOINT_DATA=$(load_checkpoint "build" 2>/dev/null)
if [ -n "$CHECKPOINT_DATA" ]; then
  CHECKPOINT_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$CHECKPOINT_FILE")) / 3600 ))
  if [ "$CHECKPOINT_AGE_HOURS" -lt 24 ]; then
    PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
    STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
  fi
fi

# Strategy 2: Find most recent incomplete plan
if [ -z "$PLAN_FILE" ]; then
  PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/[0-9]*_*.md" -type f -exec ls -t {} + | head -1)
fi
```

**Plan Discovery Pattern**: Time-based sorting with numeric prefix filtering.

### Part 2: State Machine Initialization (Lines 150-180)

**State Machine Configuration**:
```bash
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"
COMMAND_NAME="build"

sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]"
```

**Library Dependencies**:
- state-persistence.sh (>=1.5.0)
- workflow-state-machine.sh (>=2.0.0)
- error-handling.sh
- checkpoint-utils.sh

**Version Checking**: Enforced via check_library_requirements() with semantic versioning.

### Part 3: Implementation Phase (Lines 182-279)

**Agent Delegation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Execute all implementation phases according to the plan
    Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
}
```

**Behavioral Injection Pattern**: References agent file rather than duplicating behavior.

**State Persistence** (Lines 269-278):
```bash
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"
append_workflow_state "COMMIT_COUNT" "$COMMIT_COUNT"

save_completed_states_to_state
```

**Checkpoint Reporting** (Lines 258-267):
```
CHECKPOINT: Implementation phase complete
- Workflow type: full-implementation
- Plan file: $PLAN_FILE
- Changes detected: yes/none
- Recent commits: $COMMIT_COUNT
- All phases verified: ✓
- Proceeding to: Testing phase
```

### Part 4: Testing Phase (Lines 281-368)

**Test Discovery**:
1. Extract test command from plan (grep pattern)
2. Auto-detect test framework (npm test, pytest, ./.claude/run_all_tests.sh)
3. Skip if no test command found

**Test Execution**:
```bash
TEST_COMMAND=$(grep -oE "(npm test|pytest|\.\/run_all_tests\.sh)" "$PLAN_FILE" | head -1)

if [ -n "$TEST_COMMAND" ]; then
  TEST_OUTPUT=$($TEST_COMMAND 2>&1)
  TEST_EXIT_CODE=$?

  if [ $TEST_EXIT_CODE -ne 0 ]; then
    TESTS_PASSED=false
  else
    TESTS_PASSED=true
  fi
fi
```

**State Persistence** (Lines 359-367):
```bash
append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "TEST_COMMAND" "$TEST_COMMAND"
append_workflow_state "TEST_EXIT_CODE" "${TEST_EXIT_CODE:-0}"
save_completed_states_to_state
```

### Part 5: Conditional Branching (Lines 370-487)

**Debug Path** (Tests Failed):
```bash
if [ "$TESTS_PASSED" = "false" ]; then
  sm_transition "$STATE_DEBUG"

  Task {
    subagent_type: "debug-analyst"
    description: "Debug failed tests in build workflow"
    prompt: |
      Issue Description: Tests failed with exit code ${TEST_EXIT_CODE}
      Test Command: ${TEST_COMMAND}
      Debug Directory: ${DEBUG_DIR}
  }
fi
```

**Documentation Path** (Tests Passed):
```bash
else
  sm_transition "$STATE_DOCUMENT"

  # Basic documentation update
  if git diff --name-only HEAD~${COMMIT_COUNT}..HEAD | grep -qE '\.(py|js|ts|go|rs)$'; then
    echo "NOTE: Code files modified, documentation update recommended"
  fi
fi
```

### Part 6: Completion & Cleanup (Lines 490-542)

**Final State Transition**:
```bash
sm_transition "$STATE_COMPLETE"

echo "=== Build Complete ==="
echo "Workflow Type: full-implementation"
echo "Plan: $PLAN_FILE"
echo "Implementation: ✓ Complete"
echo "Testing: $([ "$TESTS_PASSED" = "true" ] && echo "✓ Passed" || echo "✗ Failed (debugged)")"
```

**Checkpoint Cleanup**:
```bash
if [ "$TESTS_PASSED" = "true" ]; then
  delete_checkpoint "build" 2>/dev/null || true
fi
```

## Subprocess Isolation Architecture

**Problem**: Bash blocks in commands execute in separate subprocesses, variables don't persist.

**Solution**: State persistence via append_workflow_state/load_workflow_state

**Pattern**:
```bash
# Part 3: Set variables
PLAN_FILE="/path/to/plan.md"
TOPIC_PATH="/path/to/topic"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
save_completed_states_to_state

# Part 4: Load variables (different subprocess)
load_workflow_state "${WORKFLOW_ID:-$$}" false
# Now PLAN_FILE and TOPIC_PATH available again
```

**Implementation**: State stored in ~/.claude/data/state/ directory as shell variables.

## Gap Analysis: Missing Features

### 1. Plan Update with [COMPLETE] Markers

**Current State**: NO plan update capability in /build

**Required Implementation**:
```bash
# After phase completion in implementer-coordinator
mark_phase_complete "$PLAN_FILE" "$PHASE_NUM"
# Updates: - [ ] Task → - [x] Task

# For phase headings
sed -i "s/^### Phase $PHASE_NUM:/### Phase $PHASE_NUM: [COMPLETE]/" "$PLAN_FILE"
```

**Invocation Point**: After each phase commits (Part 3, line 278)

### 2. Parent Plan Checkbox Updates

**Current State**: NO hierarchy update in /build

**Required Implementation**:
```bash
# After phase completion
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after phase completion"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

    Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.
    Plan: ${PLAN_FILE}
    Phase: ${PHASE_NUM}
}
```

**Timing**: Before checkpoint save (Part 3, line 275)

### 3. Task Completion Verification

**Current State**: Basic verification via git diff (line 246-255)

**Required Enhancement**:
```bash
# Enhanced verification
verify_phase_tasks_complete() {
  local plan_file="$1"
  local phase_num="$2"

  # Extract phase content
  PHASE_CONTENT=$(extract_phase_content "$plan_file" "$phase_num")

  # Count total tasks
  TOTAL_TASKS=$(echo "$PHASE_CONTENT" | grep -c "^- \[ \]" || echo "0")

  # Count completed tasks
  COMPLETED_TASKS=$(echo "$PHASE_CONTENT" | grep -c "^- \[x\]" || echo "0")

  if [ "$COMPLETED_TASKS" -ne "$TOTAL_TASKS" ]; then
    warn "Phase $phase_num incomplete: $COMPLETED_TASKS/$TOTAL_TASKS tasks"
    return 1
  fi

  return 0
}
```

**Invocation Point**: After implementation phase (Part 3, line 242)

### 4. Continuous Execution Until 75% Context

**Current State**: NO continuous execution - single-pass only

**Required Architecture**:
```bash
# Continuous execution loop
CONTEXT_LIMIT_PERCENT=75
CURRENT_CONTEXT_PERCENT=0

while [ "$CURRENT_CONTEXT_PERCENT" -lt "$CONTEXT_LIMIT_PERCENT" ]; do
  # Execute next phase
  CURRENT_PHASE=$((CURRENT_PHASE + 1))

  # Check if more phases available
  if [ "$CURRENT_PHASE" -gt "$TOTAL_PHASES" ]; then
    echo "All phases complete"
    break
  fi

  # Execute phase (Parts 3-5)
  execute_phase "$CURRENT_PHASE"

  # Estimate context usage
  CURRENT_CONTEXT_PERCENT=$(estimate_context_usage)

  echo "Context usage: $CURRENT_CONTEXT_PERCENT% of limit"
done

# Context limit check
if [ "$CURRENT_CONTEXT_PERCENT" -ge "$CONTEXT_LIMIT_PERCENT" ]; then
  echo "⚠️  Approaching context limit ($CURRENT_CONTEXT_PERCENT%)"
  echo "Stopping for user confirmation..."

  # Save checkpoint for resume
  save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE}"
fi
```

**Context Estimation**: Use token count estimation from context-budget-management.md

### 5. User Confirmation on Context Limit

**Current State**: NO user prompts in /build

**Required Implementation**:
```bash
# Prompt user for continuation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Context Budget Alert"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current context usage: $CURRENT_CONTEXT_PERCENT% of 75% limit"
echo "Completed phases: $CURRENT_PHASE / $TOTAL_PHASES"
echo "Remaining phases: $(($TOTAL_PHASES - $CURRENT_PHASE))"
echo ""
echo "Options:"
echo "  (c) Continue execution (may exceed limit)"
echo "  (s) Stop and save checkpoint"
echo "  (f) Force complete remaining phases (aggressive pruning)"
echo ""
read -p "Choose action [c/s/f]: " USER_CHOICE

case "$USER_CHOICE" in
  c|C) echo "Continuing execution..." ;;
  s|S) echo "Stopping execution, checkpoint saved"; exit 0 ;;
  f|F) echo "Forcing completion with aggressive pruning"; AGGRESSIVE_PRUNING=true ;;
  *) echo "Invalid choice, stopping"; exit 1 ;;
esac
```

## Implementation Recommendations

### Recommendation 1: Extract Phase Execution to Function

**Rationale**: Enable loop-based continuous execution

**Implementation**:
```bash
execute_phase() {
  local phase_num="$1"
  local plan_file="$2"

  # Implementation phase execution (Part 3)
  sm_transition "$STATE_IMPLEMENT"
  # ... agent invocation ...

  # Testing phase execution (Part 4)
  sm_transition "$STATE_TEST"
  # ... test execution ...

  # Conditional branching (Part 5)
  if [ "$TESTS_PASSED" = "false" ]; then
    sm_transition "$STATE_DEBUG"
  else
    sm_transition "$STATE_DOCUMENT"
  fi

  # Plan updates
  mark_phase_complete "$plan_file" "$phase_num"
  update_plan_hierarchy "$plan_file" "$phase_num"
}

# Main loop
for phase in $(seq $STARTING_PHASE $TOTAL_PHASES); do
  execute_phase "$phase" "$PLAN_FILE"

  # Check context limit
  if [ $(estimate_context_usage) -ge 75 ]; then
    prompt_user_continuation
  fi
done
```

### Recommendation 2: Add Context Estimation Library

**Location**: /home/benjamin/.config/.claude/lib/context-estimation.sh

**Functions**:
```bash
estimate_context_tokens() {
  # Rough estimation: 1 token ≈ 4 characters
  local total_chars=0

  # Count state file sizes
  for state_file in ~/.claude/data/state/*; do
    if [ -f "$state_file" ]; then
      total_chars=$((total_chars + $(wc -c < "$state_file")))
    fi
  done

  echo $((total_chars / 4))
}

estimate_context_percentage() {
  local current_tokens=$(estimate_context_tokens)
  local total_budget=25000  # Claude 3 Sonnet baseline
  echo $(( current_tokens * 100 / total_budget ))
}
```

### Recommendation 3: Integrate spec-updater Agent

**Invocation Pattern** (from spec-updater.md lines 412-444):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after Phase N completion"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.
    Plan: ${PLAN_FILE}
    Phase: ${PHASE_NUM}

    Steps:
    1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
    2. Mark phase complete: mark_phase_complete "${PLAN_FILE}" ${PHASE_NUM}
    3. Verify consistency: verify_checkbox_consistency "${PLAN_FILE}" ${PHASE_NUM}
    4. Report: List all files updated (stage → phase → main plan)
}
```

**Timing**: After git commit, before checkpoint save (Part 3, line 275)

### Recommendation 4: Add [COMPLETE] Heading Markers

**Implementation**:
```bash
update_phase_heading_status() {
  local plan_file="$1"
  local phase_num="$2"
  local status="$3"  # "COMPLETE" or "IN_PROGRESS"

  # Update phase heading
  sed -i "s/^### Phase ${phase_num}:/### Phase ${phase_num}: [${status}]/" "$plan_file"

  # For expanded phase files
  local phase_file=$(get_phase_file "$plan_file" "$phase_num" 2>/dev/null || echo "")
  if [ -n "$phase_file" ] && [ -f "$phase_file" ]; then
    sed -i "s/^# Phase ${phase_num}:/# Phase ${phase_num}: [${status}]/" "$phase_file"
  fi
}

# Usage
update_phase_heading_status "$PLAN_FILE" "$CURRENT_PHASE" "COMPLETE"
```

## Risk Assessment

### High Risk: Context Estimation Accuracy

**Probability**: 40%
**Impact**: High (may exceed limits unexpectedly)
**Mitigation**: Use conservative 70% threshold instead of 75%, implement aggressive pruning

### Medium Risk: State Persistence Overhead

**Probability**: 25%
**Impact**: Medium (performance degradation)
**Mitigation**: Batch state updates, prune old state after each phase

### Low Risk: User Prompt Interruption

**Probability**: 15%
**Impact**: Low (workflow paused, resumes easily)
**Mitigation**: Clear resume instructions, reliable checkpoint recovery

## Performance Considerations

### Context Budget Allocation (from context-budget-management.md)

**Target**: <30% context usage (7,500 tokens of 25,000)

**Layered Architecture**:
- Layer 1 (Permanent): 500-1,000 tokens (4%)
- Layer 2 (Phase-Scoped): 2,000-4,000 tokens (12%)
- Layer 3 (Metadata): 200-300 tokens per artifact (6%)
- Layer 4 (Transient): 0 tokens after pruning

**Pruning Strategy**: Aggressive pruning for multi-phase workflows (95-97% reduction per artifact)

### Continuous Execution Overhead

**Additional Context per Phase**:
- Checkpoint data: ~200 tokens
- State persistence: ~100 tokens per phase
- Plan hierarchy updates: ~50 tokens

**Total per Phase**: ~350 tokens

**6-Phase Workflow**: 350 × 6 = 2,100 tokens overhead (8.4% of budget)

**Conclusion**: Continuous execution feasible within 30% budget target.

## Cross-References

**Related Commands**:
- `/implement` - Similar architecture, includes adaptive planning
- `/fix` - Debug-focused workflow with similar state machine

**Related Agents**:
- `implementer-coordinator.md` - Wave-based execution coordinator
- `spec-updater.md` - Plan hierarchy management
- `debug-analyst.md` - Test failure analysis

**Related Libraries**:
- `workflow-state-machine.sh` - State transitions
- `state-persistence.sh` - Variable persistence
- `checkbox-utils.sh` - Plan updates
- `checkpoint-utils.sh` - Checkpoint recovery

**Related Documentation**:
- `context-budget-management.md` - Context tracking patterns
- `bash-block-execution-model.md` - Subprocess isolation
- `execution-enforcement-guide.md` - Agent invocation patterns

## Conclusion

The /build command provides a solid foundation for enhancement with:
1. State machine orchestration (reliable transitions)
2. Checkpoint recovery (24-hour resume window)
3. Subprocess isolation handling (state persistence)
4. Agent delegation patterns (behavioral injection)

**Missing capabilities** can be added through:
1. Integration of spec-updater agent (plan hierarchy updates)
2. Context estimation library (budget tracking)
3. Continuous execution loop (phase iteration)
4. User confirmation prompts (context limit alerts)

**Estimated Implementation Effort**: 8-12 hours
- Context estimation: 2 hours
- Plan update integration: 3 hours
- Continuous execution loop: 4 hours
- User prompt integration: 1 hour
- Testing and validation: 2 hours
