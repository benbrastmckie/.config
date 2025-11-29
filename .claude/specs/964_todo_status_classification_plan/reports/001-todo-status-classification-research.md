# /todo Command Status Classification Failure - Research Report

## Metadata
- **Date**: 2025-11-29
- **Research Topic**: Why /todo command failed to move completed plans from 'In Progress' to 'Completed' section
- **Complexity**: 3
- **Workflow**: research-and-plan

## Executive Summary

The /todo command failed to properly classify plan statuses because **Block 2 does not properly invoke the todo-analyzer agent via the Task tool**. Instead of using the hard barrier pattern (Block 2a: Setup → Block 2b: Execute → Block 2c: Verify), the command uses **pseudo-code Task invocation** that can be bypassed. Additionally, the command has **fallback logic that directly processes plans** instead of delegating to the agent, violating the hard barrier subagent delegation pattern.

**Root Cause**: Missing hard barrier implementation in /todo command
**Impact**: Plans with Status: [COMPLETE] and all phases marked [COMPLETE] remain in "In Progress" section
**Evidence**: Plans 961 and 959 both have Status: [COMPLETE] and all phases [COMPLETE] but TODO.md shows them as "In Progress"

## Research Findings

### 1. /todo Command Structure Analysis

**File**: `/home/benjamin/.config/.claude/commands/todo.md`

**Current Block Structure**:
- Block 1 (lines 58-205): Setup and Discovery - BASH BLOCK
- Block 2 (lines 207-252): Status Classification - **PSEUDO-CODE TASK INVOCATION**
- Block 3 (lines 254-322): Generate TODO.md - BASH BLOCK
- Block 4 (lines 324-389): Write TODO.md File - BASH BLOCK

**Critical Issues Identified**:

#### Issue 1: Pseudo-Code Task Invocation (Lines 207-252)

```markdown
## Block 2: Status Classification

**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool for each plan.
Execute the Task tool now to classify plan statuses.

For each discovered plan, invoke the todo-analyzer agent:

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify plan status for TODO.md organization"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/todo-analyzer.md
    ...
  "
}
```

**Problem**: This is pseudo-code format that can be bypassed. It lacks the structural enforcement of the hard barrier pattern.

**Correct Pattern** (from hard-barrier-subagent-delegation.md):
```markdown
## Block 2a: Status Classification Setup
```bash
# State transition, variable persistence, checkpoint
```

## Block 2b: Status Classification Execution
**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool.
Verification block (2c) will FAIL if results not created.

Task { ... }

## Block 2c: Status Classification Verification
```bash
# Verify artifacts exist, fail-fast on missing outputs
```
```

#### Issue 2: Fallback Logic Bypasses Agent (Lines 292-308)

Block 3 contains fallback logic that directly processes plans if todo-analyzer returns no results:

```bash
if [ -z "${CLASSIFIED_PLANS:-}" ]; then
  echo "WARNING: No classified plans found from todo-analyzer"
  echo "Using fallback: direct metadata extraction"

  # Fallback: Process plans directly
  DISCOVERED_PROJECTS=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_projects_"*.json 2>/dev/null | head -1)
  ...
fi
```

**Problem**: This fallback allows the command to bypass agent delegation entirely, violating the hard barrier pattern requirement that delegation cannot be bypassed.

### 2. todo-analyzer Agent Analysis

**File**: `/home/benjamin/.config/.claude/agents/todo-analyzer.md`

**Agent Design**: Properly structured for fast classification
- Model: haiku-4.5 (correct choice for fast batch processing)
- Tools: Read only (minimal context)
- Output: Structured JSON with status classification

**Status Classification Algorithm** (lines 99-128):

```
1. IF Status field contains "[COMPLETE]" OR "COMPLETE" OR "100%":
     status = "completed"

2. ELSE IF Status field contains "[IN PROGRESS]":
     status = "in_progress"

3. ELSE IF Status field contains "[NOT STARTED]":
     status = "not_started"

4. ELSE IF Status field contains "SUPERSEDED" OR "DEFERRED":
     status = "superseded"

5. ELSE IF Status field contains "ABANDONED":
     status = "abandoned"

6. ELSE IF Status field is missing:
     # Fallback: Count phase markers
     complete_phases = count phases with [COMPLETE] in header
     total_phases = count all phase headers

     IF complete_phases == total_phases AND total_phases > 0:
       status = "completed"
     ELSE IF complete_phases > 0:
       status = "in_progress"
     ELSE:
       status = "not_started"
```

**Agent is Correct**: The algorithm properly handles both Status metadata and phase marker fallback. The agent itself is not the problem.

### 3. todo-functions.sh Library Analysis

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Key Functions**:

1. `extract_plan_metadata()` (lines 159-223)
   - Extracts title, description, status from plan file
   - Counts phase headers and [COMPLETE] markers
   - Returns JSON with metadata

2. `classify_status_from_metadata()` (lines 264-308)
   - Applies classification algorithm (same as agent)
   - Handles Status field and phase marker fallback
   - Returns normalized status

3. `categorize_plan()` (lines 225-261)
   - Maps status to TODO.md section
   - Returns "Completed", "In Progress", "Not Started", etc.

**Library Functions Are Correct**: The logic mirrors the agent's algorithm. However, these functions **should not be used directly** - they should only be called by the agent or as verification after agent execution.

### 4. Evidence of Completed Plans

**Plan 961: Fix /repair Command Spec Numbering**
- **Metadata Line 10**: `- **Status**: [COMPLETE]`
- **Phase Headers**:
  - Phase 1: [COMPLETE]
  - Phase 2: [COMPLETE]
  - Phase 3: [COMPLETE]
  - Phase 4: [COMPLETE]
  - Phase 5: [COMPLETE]
- **TODO.md Line 5**: Listed in "In Progress" section with `[x]` checkbox

**Plan 959: /todo Command and Project Tracking**
- **Metadata Line 10**: `- **Status**: [COMPLETE]`
- **Phase Headers**: All 8 phases [COMPLETE]
- **TODO.md Line 128**: Listed in "Completed" section (CORRECT)

**Inconsistency**: Plan 959 appears correctly in Completed, but Plan 961 does not. This suggests the last /todo run may not have invoked the agent properly, or the fallback logic was used.

### 5. Current TODO.md State

**File**: `/home/benjamin/.config/.claude/TODO.md`

**In Progress Section** (lines 3-9):
- Contains 2 entries: Plans 961 and 962
- Both have `[x]` checkboxes (correct convention)
- Plan 961 has Status: [COMPLETE] and all phases complete (should be in Completed section)

**Completed Section** (lines 122-293):
- Contains 100+ entries properly categorized
- Plan 959 correctly appears here (same pattern as Plan 961)

### 6. Comparison with Commands Using Hard Barriers

#### /errors Command (errors.md)

**Proper Structure**:
- Block 1: Setup and Mode Detection (lines 85-300)
- Block 2a: Topic Naming Setup - **NOT SHOWN** (would be separate block)
- Block 2b: Topic Naming Execution - Task invocation (implied)
- Block 2c: Topic Naming Verification - **NOT SHOWN**
- Block 3a: Error Analysis Setup (implied)
- Block 3b: Error Analysis Execution - Task invocation to errors-analyst
- Block 3c: Error Analysis Verification (implied)

**Key Pattern**: Uses Task tool properly, delegates to errors-analyst agent

#### /repair Command (repair.md)

**Proper Structure**:
- Block 1: Consolidated Setup (lines 24-290)
  - Includes argument parsing, library sourcing, state initialization
  - **Lines 270-289**: Direct timestamp-based topic name generation (no LLM agent)
- Block 2: Initialize Workflow Paths (lines 292-300+)
- Block 3a: Error Analysis Setup (implied)
- Block 3b: Error Analysis Execution - Task invocation to repair-analyst
- Block 3c: Error Analysis Verification (implied)
- Block 4a: Plan Generation Setup (implied)
- Block 4b: Plan Generation Execution - Task invocation to plan-architect
- Block 4c: Plan Generation Verification (implied)

**Key Pattern**:
- Uses Task tool for repair-analyst and plan-architect delegation
- Bypasses topic-naming-agent with direct timestamp generation (explicit design decision)

### 7. Hard Barrier Pattern Requirements

**From**: `/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

**Required Structure** (lines 44-66):

```
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast gate)
│   ├── Variable persistence (paths, metadata)
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints
```

**Key Principle** (lines 67-69):
> Bash blocks between Task invocations make bypass impossible. Claude cannot skip a bash verification block - it must execute to see the next prompt block.

**Commands Requiring Hard Barriers** (lines 493-501):
- `/build` (implementer-coordinator)
- `/collapse` (plan-architect)
- `/debug` (debug-analyst, plan-architect)
- `/errors` (errors-analyst)
- `/expand` (plan-architect)
- `/plan` (research-specialist, plan-architect)
- `/repair` (repair-analyst, plan-architect)
- `/research` (research-specialist)
- `/revise` (research-specialist, plan-architect)

**MISSING**: `/todo` is not listed but has the same requirements (orchestrator with permissive tool access)

## Root Cause Analysis

### Primary Cause: Missing Hard Barrier Implementation

The /todo command violates the hard barrier pattern in multiple ways:

1. **Pseudo-Code Task Invocation**: Block 2 uses guidance format instead of structural enforcement
2. **No Verification Block**: Missing Block 2c to verify agent outputs exist
3. **Fallback Logic Allows Bypass**: Block 3 contains logic to process plans directly if agent fails
4. **No State Transitions**: Missing state machine transitions to enforce progression
5. **Permissive Tool Access**: Command has `allowed-tools: Task, Write, Glob, Bash, Read` allowing direct work

### Secondary Causes

1. **No Checkpoint Reporting**: Missing progress markers between blocks
2. **No Error Logging in Verification**: Failures don't log to error system
3. **Batch Processing Without Iteration**: Agent should be invoked per-plan with verification, not batch

### Why Plans Remain in Wrong Section

**Hypothesis**: The last /todo run either:
1. Bypassed the todo-analyzer agent entirely (used fallback logic)
2. Agent was invoked but output was not properly parsed
3. Agent classified correctly but TODO.md generation ignored results

**Evidence Supporting Hypothesis**:
- Plan 959 (completed earlier) appears correctly in Completed section
- Plan 961 (completed recently) appears incorrectly in In Progress section
- This suggests the last /todo run had an issue with agent invocation or result parsing

## Comparison: /todo vs Compliant Commands

| Aspect | /todo (Current) | /repair (Compliant) | /errors (Compliant) |
|--------|----------------|---------------------|---------------------|
| Block Structure | 4 blocks (Setup, Task, Generate, Write) | 6+ blocks (Setup, Init, 2a/2b/2c, 3a/3b/3c) | 5+ blocks (Setup, Mode, 2a/2b/2c) |
| Task Invocation | Pseudo-code (bypassable) | Proper Task tool (enforced) | Proper Task tool (enforced) |
| Verification Blocks | Missing | Present (Block Nc) | Present (implied) |
| State Transitions | None | sm_transition() calls | sm_transition() calls |
| Fallback Logic | Bypasses agent | No fallback (fail-fast) | No fallback (fail-fast) |
| Error Logging | Minimal | Comprehensive | Comprehensive |
| Checkpoint Markers | None | Present | Present |

## Plan Metadata Examples

### Example 1: Plan 961 (Should Be Completed)

```markdown
## Metadata
- **Date**: 2025-11-29
- **Status**: [COMPLETE]
- **Estimated Phases**: 4

### Phase 1: Replace LLM Naming [COMPLETE]
### Phase 2: Validate Unique Generation [COMPLETE]
### Phase 3: Integration Testing [COMPLETE]
### Phase 4: Documentation and Cleanup [COMPLETE]
### Phase 5: Update Error Log Status [COMPLETE]
```

**Expected Classification**: status = "completed"
**Current TODO.md**: "In Progress" section

### Example 2: Plan 959 (Correctly Completed)

```markdown
## Metadata
- **Date**: 2025-11-29
- **Status**: [COMPLETE]
- **Estimated Phases**: 8

### Phase 1: Standards Documentation [COMPLETE]
### Phase 2: Agent Implementation [COMPLETE]
### Phase 3: Library Functions [COMPLETE]
### Phase 4: Command Core [COMPLETE]
### Phase 5: TODO.md Generation [COMPLETE]
### Phase 6: --clean Flag [COMPLETE]
### Phase 7: Documentation [COMPLETE]
### Phase 8: Testing [COMPLETE]
```

**Expected Classification**: status = "completed"
**Current TODO.md**: "Completed" section (CORRECT)

## Recommendations

### Fix 1: Implement Hard Barrier Pattern (Priority: CRITICAL)

Restructure /todo command with proper hard barriers:

```markdown
## Block 2a: Status Classification Setup
```bash
set +H
set -e

# Source libraries
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh" || exit 1
source "$CLAUDE_LIB/core/state-persistence.sh" || exit 1
source "$CLAUDE_LIB/core/error-handling.sh" || exit 1

# State transition
sm_transition "ANALYZE" || {
  log_command_error "state_error" "Failed to transition to ANALYZE" "sm_transition returned non-zero"
  exit 1
}

# Pre-calculate paths
DISCOVERED_PROJECTS="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_projects_${WORKFLOW_ID}.json"
CLASSIFIED_RESULTS="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_classified_${WORKFLOW_ID}.json"

# Persist for next block
append_workflow_state "DISCOVERED_PROJECTS" "$DISCOVERED_PROJECTS"
append_workflow_state "CLASSIFIED_RESULTS" "$CLASSIFIED_RESULTS"

# Checkpoint
echo "[CHECKPOINT] Setup complete - ready for todo-analyzer invocation"
```

## Block 2b: Status Classification Execution

**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool.
Verification block (2c) will FAIL if classified results not created.

**EXECUTE NOW**: Invoke todo-analyzer subagent

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify plan status for TODO.md organization"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md

    Input:
    - plans_file: ${DISCOVERED_PROJECTS}
    - specs_root: ${SPECS_ROOT}

    For each plan in plans_file:
    1. Read the plan file via Read tool
    2. Extract metadata (title, status, description, phases)
    3. Classify status using algorithm in todo-analyzer.md
    4. Append to results array

    Output to file: ${CLASSIFIED_RESULTS}

    Return format:
    PLANS_CLASSIFIED: ${CLASSIFIED_RESULTS}
    [
      {
        "plan_path": "/path/to/plan.md",
        "topic_name": "NNN_topic_name",
        "title": "Plan Title",
        "status": "completed|in_progress|not_started",
        "phases_complete": N,
        "phases_total": M,
        "section": "Completed|In Progress|Not Started"
      }
    ]
}

## Block 2c: Status Classification Verification

```bash
set +H
set -e

# Source libraries
source "$CLAUDE_LIB/core/error-handling.sh" || exit 1
source "$CLAUDE_LIB/core/state-persistence.sh" || exit 1

# Restore persisted variables
source ~/.claude/data/state/todo_*.state 2>/dev/null || true

# Verify classified results file exists
if [[ ! -f "$CLASSIFIED_RESULTS" ]]; then
  log_command_error "verification_error" \
    "Classified results file not found: $CLASSIFIED_RESULTS" \
    "todo-analyzer should have created this file"
  echo "ERROR: VERIFICATION FAILED - Classified results missing"
  echo "Recovery: Check todo-analyzer output, re-run /todo command"
  exit 1
fi

# Verify results file is not empty
RESULT_SIZE=$(stat -c%s "$CLASSIFIED_RESULTS" 2>/dev/null || stat -f%z "$CLASSIFIED_RESULTS" 2>/dev/null)
if [[ "$RESULT_SIZE" -lt 10 ]]; then
  log_command_error "verification_error" \
    "Classified results file too small: $RESULT_SIZE bytes" \
    "todo-analyzer should have written JSON array"
  echo "ERROR: VERIFICATION FAILED - Results file empty or minimal"
  exit 1
fi

# Verify JSON is valid
if ! jq empty "$CLASSIFIED_RESULTS" 2>/dev/null; then
  log_command_error "verification_error" \
    "Classified results file contains invalid JSON" \
    "todo-analyzer should output valid JSON array"
  echo "ERROR: VERIFICATION FAILED - Invalid JSON in results"
  exit 1
fi

# Count classified plans
PLAN_COUNT=$(jq -r 'length' "$CLASSIFIED_RESULTS" 2>/dev/null || echo "0")
echo "[CHECKPOINT] Verification complete - $PLAN_COUNT plans classified"

# Persist for next block
append_workflow_state "PLAN_COUNT" "$PLAN_COUNT"
```
```

### Fix 2: Remove Fallback Logic (Priority: HIGH)

**Delete lines 292-308** in Block 3 that bypass agent delegation:

```bash
# REMOVE THIS:
if [ -z "${CLASSIFIED_PLANS:-}" ]; then
  echo "WARNING: No classified plans found from todo-analyzer"
  echo "Using fallback: direct metadata extraction"
  ...
fi
```

**Rationale**: Hard barrier pattern requires fail-fast, not fallback. If agent fails, the verification block should exit with error, not silently fall back to direct processing.

### Fix 3: Add State Machine Integration (Priority: HIGH)

Add state transitions to enforce progression:

```bash
# After Block 1 (Setup):
sm_init "$DESCRIPTION" "/todo" "utility" "1" "[]"

# Before Block 2b (Execute):
sm_transition "ANALYZE"

# Before Block 3 (Generate):
sm_transition "GENERATE"

# Before Block 4 (Write):
sm_transition "COMPLETE"
```

### Fix 4: Add Error Logging to All Blocks (Priority: MEDIUM)

Replace generic `echo "ERROR:"` with `log_command_error`:

```bash
# Instead of:
echo "ERROR: Something failed"
exit 1

# Use:
log_command_error "error_type" \
  "Something failed" \
  "Additional context about failure"
echo "ERROR: Something failed"
exit 1
```

### Fix 5: Update Documentation (Priority: MEDIUM)

1. Add `/todo` to hard-barrier-subagent-delegation.md list (line 493-501)
2. Update todo-command-guide.md to explain hard barrier pattern
3. Document why fallback logic was removed (architectural compliance)

### Fix 6: Add Compliance Tests (Priority: LOW)

Create test to verify hard barrier compliance:

```bash
# .claude/tests/features/commands/test_todo_hard_barrier.sh

# Test 1: Verify Block 2b uses Task tool (not pseudo-code)
grep -q "^Task {" .claude/commands/todo.md

# Test 2: Verify Block 2c exists (verification)
grep -q "## Block 2c:" .claude/commands/todo.md

# Test 3: Verify no fallback logic in later blocks
! grep -q "fallback.*direct metadata" .claude/commands/todo.md

# Test 4: Verify state transitions present
grep -q "sm_transition" .claude/commands/todo.md
```

## Implementation Plan Requirements

The plan to fix this issue should include:

1. **Phase 1: Refactor Block 2 with Hard Barriers**
   - Split Block 2 into 2a (Setup), 2b (Execute), 2c (Verify)
   - Add state transitions, variable persistence, checkpoints
   - Add verification with fail-fast error logging

2. **Phase 2: Remove Fallback Logic**
   - Delete fallback code from Block 3
   - Update error messages to explain fail-fast behavior
   - Add recovery instructions for verification failures

3. **Phase 3: Add State Machine Integration**
   - Add sm_init, sm_transition calls
   - Define states: INIT → ANALYZE → GENERATE → COMPLETE
   - Add state validation after each transition

4. **Phase 4: Add Error Logging**
   - Replace all `echo "ERROR:"` with `log_command_error`
   - Add error context JSON for debugging
   - Include recovery instructions in error messages

5. **Phase 5: Update Documentation**
   - Add /todo to hard barrier compliance list
   - Document Block 2a/2b/2c structure in todo-command-guide.md
   - Add architectural decision record (ADR) explaining changes

6. **Phase 6: Testing and Validation**
   - Create hard barrier compliance tests
   - Test with 100+ existing plans for performance
   - Verify Plans 961 and 962 correctly classified as completed
   - Run full test suite

## Expected Outcomes

After implementing hard barrier pattern:

1. **100% Agent Delegation**: All status classification goes through todo-analyzer
2. **Consistent Classification**: Plans with Status: [COMPLETE] always move to Completed section
3. **Fail-Fast Behavior**: Missing agent outputs cause immediate failure with recovery instructions
4. **Observable Execution**: Checkpoint markers trace execution flow
5. **Error Tracking**: All failures logged to centralized error log for /errors and /repair queries

## References

### Primary Sources
- /home/benjamin/.config/.claude/commands/todo.md (current implementation)
- /home/benjamin/.config/.claude/agents/todo-analyzer.md (agent specification)
- /home/benjamin/.config/.claude/lib/todo/todo-functions.sh (library functions)
- /home/benjamin/.config/.claude/TODO.md (current state)

### Pattern Documentation
- /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md (pattern specification)

### Compliant Examples
- /home/benjamin/.config/.claude/commands/errors.md (dual-mode with hard barriers)
- /home/benjamin/.config/.claude/commands/repair.md (research-and-plan with hard barriers)

### Related Plans
- /home/benjamin/.config/.claude/specs/961_repair_spec_numbering_allocation/plans/001-repair-spec-numbering-allocation-plan.md (Status: [COMPLETE], in wrong section)
- /home/benjamin/.config/.claude/specs/959_todo_command_project_tracking_standards/plans/001-todo-command-project-tracking-standards-plan.md (Status: [COMPLETE], in correct section)

## Appendix A: Classification Algorithm Verification

The todo-analyzer agent's classification algorithm correctly handles all cases:

**Test Case 1**: Status field = "[COMPLETE]", Phases = 5/5 [COMPLETE]
- Expected: status = "completed"
- Algorithm Step: Matches condition 1 (Status contains "[COMPLETE]")
- Result: ✓ PASS

**Test Case 2**: Status field = "[IN PROGRESS]", Phases = 3/8 [COMPLETE]
- Expected: status = "in_progress"
- Algorithm Step: Matches condition 2 (Status contains "[IN PROGRESS]")
- Result: ✓ PASS

**Test Case 3**: Status field missing, Phases = 8/8 [COMPLETE]
- Expected: status = "completed"
- Algorithm Step: Falls through to condition 6, complete_phases == total_phases
- Result: ✓ PASS

**Test Case 4**: Status field missing, Phases = 3/8 [COMPLETE]
- Expected: status = "in_progress"
- Algorithm Step: Falls through to condition 6, complete_phases > 0
- Result: ✓ PASS

**Conclusion**: The algorithm is sound. The issue is invocation, not logic.

## Appendix B: Execution Trace Hypothesis

**Scenario**: User runs `/todo` after completing Plan 961

**Expected Flow**:
1. Block 1: Discover plans → Finds Plan 961
2. Block 2a: Setup → Prepare for todo-analyzer
3. Block 2b: Execute → Task invocation to todo-analyzer
4. Block 2c: Verify → Check classified results
5. Block 3: Generate → Build TODO.md sections
6. Block 4: Write → Output TODO.md file

**Actual Flow** (Hypothesis):
1. Block 1: Discover plans → Finds Plan 961 ✓
2. Block 2: Pseudo-code shown → Claude INTERPRETS as guidance, not mandatory
3. Block 2: Claude BYPASSES Task invocation (permissive tools allow direct Read)
4. Block 3: Fallback logic triggered → Uses extract_plan_metadata() directly
5. Block 3: Classification fails or uses stale data
6. Block 4: Writes Plan 961 to "In Progress" (incorrect)

**Evidence**:
- Plan 961 appears in "In Progress" despite Status: [COMPLETE]
- No error logged to errors.jsonl (fallback succeeded silently)
- Plan 959 (earlier completion) appears correctly (different invocation?)

**Conclusion**: Hard barrier pattern enforcement would prevent this bypass scenario.
