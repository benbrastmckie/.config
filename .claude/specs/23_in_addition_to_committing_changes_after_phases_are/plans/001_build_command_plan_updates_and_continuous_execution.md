# Implementation Plan: /build Command Plan Updates and Continuous Execution

## Metadata
- **Date**: 2025-11-17
- **Complexity**: 7/10
- **Structure Level**: 0
- **Total Phases**: 6
- **Estimated Effort**: 18-22 hours
- **Risk Level**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Dependencies**: checkbox-utils.sh, spec-updater agent, state-persistence.sh, checkpoint-utils.sh

## Executive Summary

Enhance the /build command to automatically update plan files with [COMPLETE] markers and checkbox completion, verify task completion, and execute phases continuously until 75% context window usage with user confirmation prompts. All required infrastructure exists; implementation focuses on integration and orchestration.

## Research Foundation

**Research Reports Referenced**:
- `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/OVERVIEW.md`
- `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/001_build_command_architecture_analysis.md`
- `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/002_plan_structure_and_update_mechanisms.md`
- `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/003_continuous_execution_and_context_tracking.md`

**Key Findings**:
1. /build uses 6-part state machine structure with subprocess isolation
2. Checkbox update utilities fully support hierarchy propagation (checkbox-utils.sh)
3. spec-updater agent supports plan management and bidirectional linking
4. Context budget patterns documented (30% target, 4-layer architecture)
5. Checkpoint recovery supports 24-hour auto-resume window
6. /build requires continuous execution capability (single-pass currently)

## Implementation Phases

### Phase 1: Context Estimation Library Foundation

**Objective**: Create reusable context tracking library for budget monitoring

**Duration**: 3 hours

**Dependencies**: []

**Tasks**:
- [ ] Create `/home/benjamin/.config/.claude/lib/context-estimation.sh` with 4 core functions
- [ ] Implement `estimate_context_tokens()` using 4-char-per-token approximation
- [ ] Implement `estimate_context_percentage()` with configurable budget (default: 25,000)
- [ ] Implement `check_context_threshold()` returning 0 if threshold exceeded
- [ ] Implement `print_context_report()` with formatted output showing usage/budget/remaining
- [ ] Add state file size tracking (count ~/.claude/data/state/* files)
- [ ] Add checkpoint file size tracking (count ~/.claude/data/checkpoints/*.json files)
- [ ] Export all functions for sourcing by commands
- [ ] Add error handling for missing directories (no state directory yet)
- [ ] Document library with usage examples and accuracy expectations (±20%)

**Technical Specifications**:
```bash
# Function signatures
estimate_context_tokens() -> int          # Total tokens from state + checkpoints
estimate_context_percentage() -> int      # Percentage of budget (0-100)
check_context_threshold(percent) -> 0|1   # 0 = exceeded, 1 = under
print_context_report(phase, budget, target) -> void  # Formatted output

# Token estimation formula
TOTAL_CHARS=$(wc -c < all_state_files)
TOKENS=$((TOTAL_CHARS / 4))

# Percentage calculation
PERCENTAGE=$((CURRENT_TOKENS * 100 / TOTAL_BUDGET))
```

**Acceptance Criteria**:
- Library sources without errors
- Functions return expected output types
- Token estimation within ±20% of actual (validate with sample data)
- Handles missing state directory gracefully (returns 0 tokens)
- print_context_report() shows warning at >=75%, critical at >=95%

**Testing**:
- Unit test each function with mock state files
- Validate estimation accuracy against known token counts
- Test threshold detection at 74%, 75%, 76% boundaries
- Test error handling with empty/missing directories

---

### Phase 2: Plan Update Integration with spec-updater Agent

**Objective**: Integrate spec-updater agent to update plan hierarchy after each phase completion

**Duration**: 4 hours

**Dependencies**: []

**Tasks**:
- [ ] Read current /build.md structure (Parts 1-6)
- [ ] Identify insertion point in Part 3 after implementation completes (line ~275)
- [ ] Create `update_plan_after_phase()` function accepting phase_num and plan_file
- [ ] Implement spec-updater agent invocation with Task tool
- [ ] Pass phase number and plan file to agent
- [ ] Instruct agent to mark_phase_complete() and verify_checkbox_consistency()
- [ ] Add fallback checkbox update if agent invocation fails (direct checkbox-utils.sh)
- [ ] Add [COMPLETE] heading marker update using sed (e.g., "### Phase 3:" → "### Phase 3: [COMPLETE]")
- [ ] Handle expanded phase files (Level 1/2 plans) - update phase file heading too
- [ ] Stage plan file updates for git commit with code changes
- [ ] Test with Level 0, Level 1, and Level 2 plan structures
- [ ] Verify parent plan checkbox propagation works correctly

**Agent Invocation Template**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after phase ${PHASE_NUM} completion"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

    Update plan hierarchy after Phase ${PHASE_NUM} completion.
    Plan: ${PLAN_FILE}
    Phase: ${PHASE_NUM}

    Steps:
    1. Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh
    2. Mark phase complete: mark_phase_complete "${PLAN_FILE}" ${PHASE_NUM}
    3. Add [COMPLETE] heading marker to phase heading
    4. Verify consistency: verify_checkbox_consistency "${PLAN_FILE}" ${PHASE_NUM}
    5. Report files updated (include both phase file and main plan for Level 1/2)

    Expected output:
    - List all files updated
    - Confirm all checkboxes marked complete
    - Verify hierarchy consistency
}
```

**Fallback Implementation**:
```bash
# If agent fails, use direct checkbox-utils.sh
if ! grep -q "Phase ${CURRENT_PHASE}.*\[COMPLETE\]" "$PLAN_FILE"; then
  warn "Agent update failed, using fallback"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh"
  mark_phase_complete "$PLAN_FILE" "$CURRENT_PHASE"
  sed -i "s/^### Phase ${CURRENT_PHASE}:/### Phase ${CURRENT_PHASE}: [COMPLETE]/" "$PLAN_FILE"
fi
```

**Acceptance Criteria**:
- spec-updater agent invoked successfully after each phase
- All phase checkboxes marked [x] after completion
- [COMPLETE] marker added to phase heading
- Parent plan checkboxes updated (Level 1/2)
- Git commit includes updated plan file(s)
- Fallback works if agent fails

**Testing**:
- Test with simple Level 0 plan (3 phases)
- Test with Level 1 plan (phase expansion)
- Test with Level 2 plan (stage expansion)
- Verify checkbox propagation works
- Test fallback by simulating agent failure

---

### Phase 3: Task Completion Verification

**Objective**: Add verification to confirm all tasks completed before marking phase complete

**Duration**: 3 hours

**Dependencies**: [Phase 2]

**Tasks**:
- [ ] Create `verify_phase_complete()` function with hybrid verification strategy
- [ ] Implement count-based verification (check for unchecked boxes: `- [ ]`)
- [ ] Extract phase content using awk/sed to isolate phase section
- [ ] Count total tasks and completed tasks in phase
- [ ] Implement git-based verification (check for changes and commits)
- [ ] Verify git diff shows changes (warn if no changes)
- [ ] Verify recent commit exists (within last 5 minutes)
- [ ] Implement checkbox consistency verification (call verify_checkbox_consistency)
- [ ] Add verification call in Part 3 before plan updates (line ~260)
- [ ] Handle verification failure with clear error messages
- [ ] Add diagnostic output showing incomplete tasks if verification fails
- [ ] Allow --skip-verification flag for edge cases (document in /build help)

**Verification Function**:
```bash
verify_phase_complete() {
  local plan_file="$1"
  local phase_num="$2"

  # Step 1: Count-based verification
  PHASE_CONTENT=$(extract_phase_content "$plan_file" "$phase_num")
  UNCHECKED=$(echo "$PHASE_CONTENT" | grep -c "^- \[ \]" || echo "0")

  if [ "$UNCHECKED" -gt 0 ]; then
    error "Phase $phase_num has $UNCHECKED incomplete tasks"
    echo "$PHASE_CONTENT" | grep "^- \[ \]" | head -5
    return 1
  fi

  # Step 2: Git-based verification (non-fatal warning)
  if git diff --quiet && git diff --cached --quiet; then
    warn "Phase $phase_num: No changes detected"
  fi

  RECENT_COMMITS=$(git log --oneline --since="5 minutes ago" | wc -l)
  if [ "$RECENT_COMMITS" -eq 0 ]; then
    warn "Phase $phase_num: No recent commits"
  fi

  # Step 3: Hierarchy consistency
  if ! verify_checkbox_consistency "$plan_file" "$phase_num" 2>/dev/null; then
    warn "Phase $phase_num: Checkbox hierarchy may be inconsistent"
  fi

  return 0
}

extract_phase_content() {
  local plan_file="$1"
  local phase_num="$2"

  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase) {
        in_phase = 1
        next
      } else if (in_phase) {
        exit
      }
    }
    /^### / && in_phase { exit }
    in_phase { print }
  ' "$plan_file"
}
```

**Acceptance Criteria**:
- Verification detects unchecked tasks (fails with error)
- Verification warns if no git changes detected (non-fatal)
- Verification warns if no recent commits (non-fatal)
- Verification checks hierarchy consistency
- Clear error messages with diagnostic output (show incomplete tasks)
- --skip-verification flag works (bypasses checks)

**Testing**:
- Test with phase containing unchecked tasks (should fail)
- Test with phase where all tasks checked (should pass)
- Test with no git changes (should warn but pass)
- Test with no recent commits (should warn but pass)
- Test --skip-verification flag

---

### Phase 4: Continuous Execution Loop

**Objective**: Refactor Parts 3-5 into continuous loop executing phases until context limit

**Duration**: 5 hours

**Dependencies**: [Phase 1, Phase 2, Phase 3]

**Tasks**:
- [ ] Extract Part 3 implementation logic into `execute_phase_implementation(phase_num)` function
- [ ] Extract Part 4 testing logic into `execute_phase_testing(phase_num)` function
- [ ] Extract Part 5 debug logic into `execute_phase_debug(phase_num)` function
- [ ] Extract Part 5 documentation logic into `execute_phase_documentation(phase_num)` function
- [ ] Create main execution loop: `while [ "$CURRENT_PHASE" -le "$TOTAL_PHASES" ]; do`
- [ ] Call execute_phase_implementation() in loop
- [ ] Call execute_phase_testing() after implementation
- [ ] Branch to execute_phase_debug() or execute_phase_documentation() based on test results
- [ ] Call verify_phase_complete() before plan updates
- [ ] Call update_plan_after_phase() after verification passes
- [ ] Call print_context_report() after each phase completes
- [ ] Check context threshold before starting next phase iteration
- [ ] Increment CURRENT_PHASE at end of loop
- [ ] Add state persistence for CURRENT_PHASE (append_workflow_state)
- [ ] Test with 3-phase, 6-phase, and 10-phase plans

**Continuous Execution Loop Structure**:
```bash
# Part 3-5: Continuous Phase Execution Loop

CONTEXT_LIMIT_PERCENT=75
CURRENT_PHASE=$STARTING_PHASE

# Source context estimation library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-estimation.sh"

# Load state from previous parts
load_workflow_state "${WORKFLOW_ID:-$$}" false

while [ "$CURRENT_PHASE" -le "$TOTAL_PHASES" ]; do
  echo "=== Phase $CURRENT_PHASE Execution ==="

  # Check context before starting phase
  if check_context_threshold "$CONTEXT_LIMIT_PERCENT"; then
    prompt_user_continuation  # Phase 5 function
  fi

  # Execute implementation
  execute_phase_implementation "$CURRENT_PHASE"

  # Execute testing
  execute_phase_testing "$CURRENT_PHASE"

  # Load test results from state
  load_workflow_state "${WORKFLOW_ID:-$$}" false

  # Conditional branching
  if [ "$TESTS_PASSED" = "false" ]; then
    execute_phase_debug "$CURRENT_PHASE"
  else
    execute_phase_documentation "$CURRENT_PHASE"
  fi

  # Verify completion
  if ! verify_phase_complete "$PLAN_FILE" "$CURRENT_PHASE"; then
    error "Phase $CURRENT_PHASE verification failed"
    exit 1
  fi

  # Update plan hierarchy
  update_plan_after_phase "$CURRENT_PHASE"

  # Print context report
  print_context_report "$CURRENT_PHASE" 25000 30

  # Advance to next phase
  CURRENT_PHASE=$((CURRENT_PHASE + 1))
  append_workflow_state "CURRENT_PHASE" "$CURRENT_PHASE"
  save_completed_states_to_state
done

# All phases complete
sm_transition "$STATE_COMPLETE"
echo "=== Build Complete ==="
```

**Function Signatures**:
```bash
execute_phase_implementation(phase_num) -> void
execute_phase_testing(phase_num) -> void  # Sets TESTS_PASSED state
execute_phase_debug(phase_num) -> void
execute_phase_documentation(phase_num) -> void
```

**Acceptance Criteria**:
- Loop executes all phases sequentially
- Each phase completes implementation, testing, and debug/docs
- State persistence works across function calls (TESTS_PASSED, CURRENT_PHASE)
- Context report printed after each phase
- Loop exits cleanly after last phase
- Checkpoint saved after each phase (resume capability)

**Testing**:
- Test with 3-phase plan (simple workflow)
- Test with 6-phase plan (standard workflow)
- Test with 10-phase plan (complex workflow)
- Test phase execution functions in isolation
- Verify state persistence across bash blocks

---

### Phase 5: User Confirmation and Context Limits

**Objective**: Add user confirmation prompts when 75% context threshold reached

**Duration**: 3 hours

**Dependencies**: [Phase 1, Phase 4]

**Tasks**:
- [ ] Create `prompt_user_continuation()` function
- [ ] Calculate current context percentage using estimate_context_percentage()
- [ ] Calculate completed phases and remaining phases
- [ ] Display formatted alert box with context usage summary
- [ ] Present 3 options: (c) Continue, (s) Stop and Save, (f) Force with pruning
- [ ] Use `read -p` for user input (simple bash prompt)
- [ ] Handle Continue: print message and return to loop
- [ ] Handle Stop and Save: save checkpoint with current phase, display resume instructions, exit 0
- [ ] Handle Force: enable AGGRESSIVE_PRUNING flag, call pruning functions (if exist), continue
- [ ] Handle invalid input: default to Stop and Save (safe choice)
- [ ] Add resume instructions in output: "Resume with: /build $PLAN_FILE $CURRENT_PHASE"
- [ ] Test prompt functionality with mock context usage
- [ ] Document behavior in build-command-guide.md

**User Prompt Template**:
```bash
prompt_user_continuation() {
  local current_percent=$(estimate_context_percentage)
  local completed_phases=$((CURRENT_PHASE - 1))
  local remaining_phases=$((TOTAL_PHASES - CURRENT_PHASE + 1))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Context Budget Alert"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Current context usage: $current_percent% of 75% limit"
  echo "Completed phases: $completed_phases / $TOTAL_PHASES"
  echo "Remaining phases: $remaining_phases"
  echo ""
  echo "Continuing may exceed context limits and cause errors."
  echo ""
  echo "Options:"
  echo "  (c) Continue execution (may exceed limit)"
  echo "  (s) Stop and save checkpoint (resume later)"
  echo "  (f) Force complete with aggressive pruning"
  echo ""
  read -p "Choose action [c/s/f]: " USER_CHOICE

  case "$USER_CHOICE" in
    c|C)
      echo "Continuing execution..."
      ;;
    s|S)
      echo "Stopping execution, saving checkpoint"
      save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE,\"total_phases\":$TOTAL_PHASES}"
      echo ""
      echo "Resume with: /build \"$PLAN_FILE\" $CURRENT_PHASE"
      echo ""
      exit 0
      ;;
    f|F)
      echo "Forcing completion with aggressive pruning"
      export AGGRESSIVE_PRUNING=true
      # Note: Pruning functions may not exist yet, safe to enable flag
      ;;
    *)
      echo "Invalid choice, stopping execution for safety"
      save_checkpoint "build" "{\"plan_path\":\"$PLAN_FILE\",\"current_phase\":$CURRENT_PHASE,\"total_phases\":$TOTAL_PHASES}"
      exit 1
      ;;
  esac
  echo ""
}
```

**Acceptance Criteria**:
- Prompt displayed when context exceeds 75%
- All 3 options work correctly
- Stop and Save creates checkpoint with correct current_phase
- Resume instructions show correct command syntax
- Continue option allows loop to proceed
- Force option enables AGGRESSIVE_PRUNING flag
- Invalid input defaults to safe behavior (stop)

**Testing**:
- Mock context usage at 76% (trigger prompt)
- Test each option (Continue, Stop, Force, Invalid)
- Verify checkpoint saved correctly
- Verify resume command works after stop
- Test with different phase counts (2/5, 5/10)

---

### Phase 6: End-to-End Testing and Documentation

**Objective**: Comprehensive testing and documentation updates

**Duration**: 4 hours

**Dependencies**: [Phase 1, Phase 2, Phase 3, Phase 4, Phase 5]

**Tasks**:
- [ ] Test complete workflow with Level 0 plan (3 phases)
- [ ] Verify all phase checkboxes marked complete
- [ ] Verify [COMPLETE] markers added to phase headings
- [ ] Verify continuous execution through all phases
- [ ] Test complete workflow with Level 1 plan (6 phases)
- [ ] Verify parent plan checkboxes updated correctly
- [ ] Verify phase file checkboxes updated correctly
- [ ] Test checkpoint recovery (stop at phase 4, resume)
- [ ] Verify resume works with correct starting phase
- [ ] Test context limit trigger (create plan with 10 phases to trigger 75%)
- [ ] Verify user prompt appears at correct threshold
- [ ] Test all user prompt options work
- [ ] Test test failure path (debug branch)
- [ ] Verify debug execution when tests fail
- [ ] Test verification failure (plan with incomplete tasks)
- [ ] Update `/home/benjamin/.config/.claude/docs/workflows/build-command-guide.md`
- [ ] Document new behavior: automatic plan updates, continuous execution, context limits
- [ ] Add examples showing [COMPLETE] markers
- [ ] Document user prompt options and resume instructions
- [ ] Add troubleshooting section for verification failures

**Test Scenarios**:

**Scenario 1: Simple 3-Phase Workflow (Level 0)**
```bash
# Setup: Create test plan with 3 phases
# Expected: All phases execute, checkboxes complete, [COMPLETE] markers added
# Validation: grep "Phase.*\[COMPLETE\]" plan.md shows 3 matches
```

**Scenario 2: Complex 6-Phase Workflow (Level 1)**
```bash
# Setup: Create plan with phase expansion
# Expected: Parent and phase files both updated
# Validation: Main plan shows Phase N: [COMPLETE], phase files show complete
```

**Scenario 3: Checkpoint Recovery**
```bash
# Setup: Run /build, trigger context limit at phase 4, choose Stop
# Action: Resume with /build plan.md 4
# Expected: Execution resumes from phase 4, completes remaining phases
# Validation: Phases 1-3 already marked complete, phases 4-6 newly completed
```

**Scenario 4: Context Limit Prompt**
```bash
# Setup: Create 10-phase plan to trigger 75% threshold
# Expected: User prompt appears around phase 6-7
# Validation: Prompt displays correct context percentage and remaining phases
```

**Scenario 5: Test Failure Handling**
```bash
# Setup: Plan with phase containing failing tests
# Expected: Debug path executed instead of documentation
# Validation: Debug agent invoked, debug report created
```

**Documentation Updates**:

**File**: `/home/benjamin/.config/.claude/docs/workflows/build-command-guide.md`

**Sections to Add**:
1. **Automatic Plan Updates** - Explain [COMPLETE] markers and checkbox updates
2. **Continuous Execution** - Describe phase-to-phase execution behavior
3. **Context Budget Management** - Explain 75% threshold and user prompts
4. **Resume Instructions** - How to resume after context limit stop
5. **Troubleshooting** - Common verification failures and solutions

**Acceptance Criteria**:
- All 5 test scenarios pass
- No regressions in existing /build functionality
- Plan files correctly updated with [COMPLETE] markers
- Continuous execution works for 3, 6, and 10-phase plans
- Checkpoint recovery works correctly
- User prompt appears at correct threshold
- Documentation complete and accurate
- Build command help text updated (if applicable)

---

## Technical Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    /build Command                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Part 1: Argument Parsing                                   │
│  ├─ Plan discovery                                          │
│  ├─ Auto-resume from checkpoint (<24 hours)                 │
│  └─ Starting phase selection                                │
│                                                              │
│  Part 2: State Machine Initialization                       │
│  ├─ Load libraries (state-persistence, checkpoint-utils)    │
│  ├─ Initialize workflow state                               │
│  └─ Detect plan structure level (0/1/2)                     │
│                                                              │
│  Part 3-5: Continuous Execution Loop                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ while CURRENT_PHASE <= TOTAL_PHASES:                 │  │
│  │                                                       │  │
│  │   ┌─ Check context threshold (75%) ─────────────┐   │  │
│  │   │  └─ prompt_user_continuation() if exceeded  │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ execute_phase_implementation(N) ───────────┐   │  │
│  │   │  └─ implementer-coordinator agent           │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ execute_phase_testing(N) ────────────────┐    │  │
│  │   │  └─ Run test command, set TESTS_PASSED      │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ Conditional Branching ────────────────────┐    │  │
│  │   │  if TESTS_PASSED == false:                  │   │  │
│  │   │    execute_phase_debug(N)                   │   │  │
│  │   │  else:                                       │   │  │
│  │   │    execute_phase_documentation(N)           │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ verify_phase_complete(N) ──────────────────┐   │  │
│  │   │  └─ Check unchecked tasks, git changes      │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ update_plan_after_phase(N) ────────────────┐   │  │
│  │   │  ├─ Invoke spec-updater agent               │   │  │
│  │   │  ├─ Mark checkboxes complete                │   │  │
│  │   │  ├─ Add [COMPLETE] heading marker           │   │  │
│  │   │  ├─ Update parent plan (Level 1/2)          │   │  │
│  │   │  └─ Git commit plan updates                 │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   ┌─ print_context_report(N) ───────────────────┐   │  │
│  │   │  └─ Show context usage / budget / remaining │   │  │
│  │   └─────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │   CURRENT_PHASE++                                    │  │
│  │                                                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Part 6: Completion & Cleanup                               │
│  ├─ Final state transition (STATE_COMPLETE)                 │
│  ├─ Print completion summary                                │
│  └─ Delete checkpoint on success                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              New Library: context-estimation.sh              │
├─────────────────────────────────────────────────────────────┤
│  estimate_context_tokens()      → int                       │
│  estimate_context_percentage()  → int (0-100)               │
│  check_context_threshold(%)     → 0 (exceeded) | 1 (under)  │
│  print_context_report(phase)    → formatted output          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Existing: spec-updater Agent                    │
├─────────────────────────────────────────────────────────────┤
│  mark_phase_complete(plan, phase)                           │
│  verify_checkbox_consistency(plan, phase)                   │
│  Propagates checkboxes: stage → phase → main plan           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Existing: checkbox-utils.sh                     │
├─────────────────────────────────────────────────────────────┤
│  update_checkbox(file, pattern, state)                      │
│  propagate_checkbox_update(plan, phase, pattern, state)     │
│  verify_checkbox_consistency(plan, phase)                   │
│  mark_phase_complete(plan, phase)                           │
│  mark_stage_complete(phase_file, stage)                     │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Phase Execution Flow**:
```
1. execute_phase_implementation(N)
   └─> implementer-coordinator agent executes tasks
   └─> Git commit with code changes
   └─> append_workflow_state("COMMIT_COUNT", N)

2. execute_phase_testing(N)
   └─> Run TEST_COMMAND (npm test, pytest, etc.)
   └─> append_workflow_state("TESTS_PASSED", true|false)

3. Conditional Branch
   └─> if TESTS_PASSED == false:
       └─> execute_phase_debug(N)
           └─> debug-analyst agent analyzes failures
   └─> else:
       └─> execute_phase_documentation(N)
           └─> Update documentation if code changed

4. verify_phase_complete(N)
   └─> Count unchecked tasks (fail if > 0)
   └─> Check git changes (warn if none)
   └─> Check hierarchy consistency

5. update_plan_after_phase(N)
   └─> Invoke spec-updater agent
       └─> mark_phase_complete(plan, N)
       └─> Update checkboxes: - [ ] → - [x]
   └─> Add [COMPLETE] heading marker
       └─> sed "s/### Phase N:/### Phase N: [COMPLETE]/"
   └─> Update parent plan (if Level 1/2)
       └─> propagate_checkbox_update()
   └─> Git commit plan updates
       └─> git add plan.md && git commit

6. print_context_report(N)
   └─> estimate_context_tokens() → TOKENS
   └─> Calculate percentage → PERCENT
   └─> Print formatted report

7. Check context threshold
   └─> check_context_threshold(75%)
   └─> if exceeded:
       └─> prompt_user_continuation()
           └─> User chooses: Continue | Stop | Force
           └─> Stop: save_checkpoint() and exit 0

8. Increment CURRENT_PHASE
   └─> CURRENT_PHASE=$((CURRENT_PHASE + 1))
   └─> append_workflow_state("CURRENT_PHASE", N+1)

9. Loop continues or exits
```

### State Persistence

**Persisted Variables** (across bash blocks):
- `PLAN_FILE` - Path to plan file
- `TOPIC_PATH` - Topic directory path
- `STARTING_PHASE` - Initial phase (for resume)
- `CURRENT_PHASE` - Current phase number
- `TOTAL_PHASES` - Total phase count
- `TESTS_PASSED` - Boolean test result
- `TEST_COMMAND` - Test command string
- `COMMIT_COUNT` - Number of commits made
- `AGGRESSIVE_PRUNING` - Flag for aggressive pruning mode

**Checkpoint Data** (for resume):
```json
{
  "plan_path": "/path/to/plan.md",
  "current_phase": 4,
  "total_phases": 7,
  "timestamp": "2025-11-17T10:30:00Z"
}
```

---

## Risk Assessment

### High Risk: Context Estimation Accuracy

**Probability**: 40%
**Impact**: High (may exceed limits unexpectedly)

**Description**: Token estimation using 4-char-per-token approximation has ±20% margin of error. May trigger prompt too early or too late.

**Mitigation**:
- Use conservative threshold (70% instead of 75% if inaccurate)
- Test estimation accuracy across multiple workflows
- Implement emergency pruning at 90% as fallback
- Document accuracy limitations in code comments

---

### Medium Risk: State Persistence Overhead

**Probability**: 25%
**Impact**: Medium (performance degradation)

**Description**: Continuous execution creates more state files per phase. May accumulate over time.

**Mitigation**:
- Batch state updates where possible
- Prune old state files after each phase
- Monitor state directory growth during testing
- Implement state cleanup in Part 6 (completion)

---

### Medium Risk: User Interruption Friction

**Probability**: 25%
**Impact**: Medium (workflow paused, user must respond)

**Description**: User prompt at 75% requires manual input, pausing workflow. May interrupt flow if user not actively monitoring.

**Mitigation**:
- Clear resume instructions in prompt
- Reliable checkpoint recovery (24-hour window)
- Auto-resume capability if no arguments provided
- Document expected behavior in guide

---

### Low Risk: Checkbox Update Failures

**Probability**: 15%
**Impact**: Low (plan desynchronized but recoverable)

**Description**: spec-updater agent or checkbox-utils.sh may fail to update plan files correctly.

**Mitigation**:
- Fallback to direct checkbox-utils.sh if agent fails
- Verify consistency after updates
- Log errors for manual review
- Test with all plan structure levels (0/1/2)

---

### Low Risk: Checkpoint Corruption

**Probability**: 10%
**Impact**: Medium (cannot resume, must restart)

**Description**: Checkpoint file may become corrupted due to write errors or interruptions.

**Mitigation**:
- Atomic file writes (write to temp, then mv)
- Checkpoint validation on load (check JSON format)
- Keep last 3 checkpoints (rotation strategy)
- Test checkpoint recovery extensively

---

## Performance Considerations

### Context Overhead per Phase

**Breakdown**:
- Checkpoint data: ~200 tokens
- State persistence: ~100 tokens
- Plan hierarchy updates: ~50 tokens
- Context tracking: ~50 tokens
- **Total**: ~400 tokens/phase

**6-Phase Workflow**:
- Total overhead: 2,400 tokens (9.6% of budget)
- Implementation content: ~5,000 tokens (20%)
- **Combined**: 7,400 tokens (29.6%) ✓ Within 30% target

### Checkbox Update Performance

**Timing**:
- Single update: ~10ms per file
- Hierarchy propagation (Level 1): ~30ms
- Hierarchy propagation (Level 2): ~50ms

**6-Phase Workflow**:
- Total: 6 × 30ms = 180ms overhead
- **Conclusion**: Negligible (<1% of phase execution time)

### Pruning Effectiveness

**Without Pruning**:
- 6 phases × 2,000 tokens/phase = 12,000 tokens (48%) ❌ Exceeds target

**With Aggressive Pruning**:
- 6 phases × 200 tokens/phase = 1,200 tokens (4.8%) ✓ Within target
- **Reduction**: 92% (12,000 → 1,200 tokens)

---

## Success Criteria

### Functional Requirements
- [ ] Plan updated with [COMPLETE] markers after each phase
- [ ] Parent plan checkboxes updated automatically (Level 1/2)
- [ ] All tasks verified complete before marking
- [ ] Continuous execution until 75% context usage
- [ ] User prompted for confirmation at threshold
- [ ] Checkpoint saved on stop for resume
- [ ] Resume from checkpoint works correctly

### Non-Functional Requirements
- [ ] Context estimation accurate within ±20%
- [ ] Checkbox updates <1% of phase execution time
- [ ] Total context overhead <10% of budget
- [ ] Auto-resume works within 24 hours
- [ ] No regressions in existing /build functionality

### Documentation Requirements
- [ ] context-estimation.sh documented
- [ ] Updated build-command-guide.md
- [ ] User confirmation prompt documented
- [ ] Checkpoint recovery process documented
- [ ] Troubleshooting section added

---

## Testing Strategy

### Unit Testing
1. **Context estimation functions** - Validate accuracy with mock state files
2. **Checkbox update functions** - Test all 5 functions in isolation
3. **Phase execution functions** - Test implementation, testing, debug, docs functions
4. **User confirmation handling** - Test all 3 options (Continue, Stop, Force)

### Integration Testing
1. **3-phase plan** (Level 0) - Simple workflow, verify basic functionality
2. **6-phase plan** (Level 1) - Phase expansion, verify parent updates
3. **10-phase plan** (Level 0) - Complex workflow, trigger context limit
4. **Checkpoint recovery** - Stop at phase 4, resume successfully
5. **Test failure handling** - Verify debug path execution

### End-to-End Testing
1. **Full workflow with plan updates** - Verify [COMPLETE] markers throughout
2. **Context threshold trigger** - Verify user prompt at correct threshold
3. **Stop and resume** - Verify checkpoint recovery works end-to-end
4. **Hierarchy consistency** - Verify Level 0/1/2 plans all update correctly

---

## Dependencies

### Existing Libraries (No Changes Needed)
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` ✓
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh` ✓
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` ✓
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` ✓

### New Libraries (To Be Created)
- `/home/benjamin/.config/.claude/lib/context-estimation.sh` ❌

### Existing Agents (No Changes Needed)
- `/home/benjamin/.config/.claude/agents/spec-updater.md` ✓
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` ✓
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` ✓

### Commands to Modify
- `/home/benjamin/.config/.claude/commands/build.md` - Major refactoring

---

## Timeline

**Total Estimated Effort**: 18-22 hours

**Week 1 (Days 1-2): Foundation**
- Day 1: Phase 1 (3 hours) - Context estimation library
- Day 2: Phase 2 (4 hours) - Plan update integration
- **Milestone**: Context tracking works, plan updates functional

**Week 1 (Days 3-4): Core Features**
- Day 3: Phase 3 (3 hours) - Task verification
- Day 4: Phase 4 (5 hours) - Continuous execution loop
- **Milestone**: Continuous loop functional, verification works

**Week 2 (Day 5): User Experience**
- Day 5: Phase 5 (3 hours) - User confirmation prompts
- **Milestone**: User prompts working, resume instructions clear

**Week 2 (Days 6-7): Validation**
- Days 6-7: Phase 6 (4 hours) - Testing and documentation
- **Milestone**: All tests passing, documentation complete

---

## Implementation Notes

### Compatibility Requirements

Implementation preserves existing functionality:
- /build usage patterns remain unchanged
- Auto-resume works with 24-hour window
- Plan file formats remain consistent
- Dry-run mode supported

### Graceful Degradation

If components fail:
- **spec-updater agent fails**: Fallback to checkbox-utils.sh
- **Context estimation fails**: Skip threshold check, continue execution
- **User prompt fails**: Default to Stop and Save (safe choice)
- **Checkpoint save fails**: Log error, continue execution

### Edge Cases

**Empty Plan** (0 phases):
- Skip execution loop entirely
- Transition to STATE_COMPLETE immediately

**Single Phase** (1 phase):
- Execute single iteration
- Context check likely not triggered

**All Tests Skipped** (no test command):
- TESTS_PASSED defaults to true
- Documentation path always executed

**Checkpoint Older Than 24 Hours**:
- Ignore checkpoint
- Fall back to most recent incomplete plan

---

## Conclusion

This implementation plan provides a comprehensive approach to enhancing the /build command with automatic plan updates, task verification, and continuous execution until context limits. All necessary infrastructure exists in the codebase; implementation focuses on integration and orchestration.

**Expected Outcome**: /build command with automatic [COMPLETE] markers, checkbox updates, continuous phase-to-phase execution until 75% context usage, and user confirmation prompts with reliable checkpoint recovery.

**Key Innovations**:
1. Context-aware execution (stops before exceeding limits)
2. Automatic plan synchronization (no manual updates needed)
3. Verification-driven completion (ensures tasks actually done)
4. Seamless resume capability (pick up where left off)

**Implementation Complexity**: Moderate (7/10)
- Leverages existing robust infrastructure
- No external dependencies required
- Incremental implementation possible
- Low technical risk with established patterns
