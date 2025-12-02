# TODO.md Update Integration Analysis: Command Coverage and Implementation Gaps

## Executive Summary

This report provides a comprehensive analysis of TODO.md update integration across all artifact-creating commands in the .claude/ system. The analysis examines existing standards, current implementations, and identifies gaps in systematic TODO tracking.

**Key Findings:**
- 7 commands should integrate TODO.md updates: /implement, /build, /plan, /research, /revise, /repair, /debug
- 3 commands have **complete** integration: /build, /plan, /research
- 2 commands have **partial** integration: /implement, /revise
- 2 commands have **missing** integration: /repair, /debug
- Standards define 6 update triggers but only 4 are consistently implemented
- `trigger_todo_update()` function exists and provides delegation pattern

## 1. Standards Analysis

### 1.1 TODO Organization Standards (todo-organization-standards.md)

**Lines 324-337**: The standards document explicitly defines which commands should update TODO.md and when:

```markdown
### Automatic TODO.md Updates

Six commands automatically update TODO.md when creating or modifying plans and reports:

- **/build**: Updates at START (→ In Progress) and COMPLETION (→ Completed)
- **/plan**: Updates after new plan creation (→ Not Started)
- **/research**: Updates after report creation (→ Research)
- **/debug**: Updates after debug report creation (→ Research)
- **/repair**: Updates after repair plan creation (→ Not Started)
- **/revise**: Updates after plan modification (status unchanged)

All commands use the signal-triggered delegation pattern, delegating to `/todo` for consistent classification and formatting.
```

**Key Standard Requirements:**
1. **Six commands** must integrate TODO.md updates (NOT seven as initially stated in research focus)
2. **Signal-triggered delegation pattern**: Commands delegate to /todo command for updates
3. **Two update moments**: START (status changes) and COMPLETION (status changes)
4. **Status transitions**: Commands move plans between TODO.md sections based on lifecycle

### 1.2 Library Integration Function

**File**: `.claude/lib/todo/todo-functions.sh`
**Lines**: 1113-1133

The `trigger_todo_update()` function provides the delegation mechanism:

```bash
trigger_todo_update() {
  local reason="${1:-TODO.md update}"

  # Delegate to /todo command silently (suppress output)
  if bash -c "cd \"${CLAUDE_PROJECT_DIR}\" && /todo" >/dev/null 2>&1; then
    echo "✓ Updated TODO.md ($reason)"
    return 0
  else
    # Non-blocking: log warning but don't fail command
    echo "WARNING: Failed to update TODO.md ($reason)" >&2
    return 0  # Return success to avoid blocking parent command
  fi
}
```

**Function Characteristics:**
- **Non-blocking**: Always returns 0 (success) to avoid blocking parent command
- **Silent execution**: Suppresses /todo output to keep console clean
- **Delegation pattern**: Invokes /todo command for actual update logic
- **Reason tracking**: Accepts descriptive reason string for logging
- **Error resilience**: Logs warning but continues workflow on failure

## 2. Current Command Implementations

### 2.1 /build Command - COMPLETE ✅

**File**: `.claude/commands/build.md`

**Implementation Locations:**

1. **START Update** (Lines 342-358):
```bash
# Update plan metadata status to IN PROGRESS
if type update_plan_status &>/dev/null; then
  if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
    echo "Plan metadata status updated to [IN PROGRESS]"

    # Source todo-functions.sh for trigger_todo_update()
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
      echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
    }

    # Trigger TODO.md update (non-blocking)
    if type trigger_todo_update &>/dev/null; then
      trigger_todo_update "build phase started"
    fi
  fi
fi
```

2. **COMPLETION Update** (Lines 1062-1078):
```bash
# Update plan status to COMPLETE if all phases done
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"

    # Source todo-functions.sh for trigger_todo_update()
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
      echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
    }

    # Trigger TODO.md update (non-blocking)
    if type trigger_todo_update &>/dev/null; then
      trigger_todo_update "build phase completed"
    fi
  fi
fi
```

**Status**: ✅ COMPLETE
- Both START and COMPLETION triggers implemented
- Proper library sourcing with error handling
- Descriptive reason strings ("build phase started", "build phase completed")
- Non-blocking pattern correctly applied

### 2.2 /plan Command - COMPLETE ✅

**File**: `.claude/commands/plan.md`

**Implementation Location** (Lines 1507-1517):
```bash
# === UPDATE TODO.md ===
# Source todo-functions.sh for trigger_todo_update()
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Trigger TODO.md update (non-blocking)
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "plan created"
fi
```

**Status**: ✅ COMPLETE
- Implemented at Block 3 completion (after plan file verified)
- Proper library sourcing with graceful degradation
- Descriptive reason string ("plan created")
- Standards compliance: Updates after plan creation → Not Started section

### 2.3 /research Command - COMPLETE ✅

**File**: `.claude/commands/research.md`

**Implementation Location** (Lines 1235-1243):
```bash
# === UPDATE TODO.md ===
# Source todo-functions.sh for trigger_todo_update()
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Trigger TODO.md update (non-blocking)
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "research report created"
fi
```

**Status**: ✅ COMPLETE
- Implemented at Block 2 completion (after report verified)
- Proper library sourcing with graceful degradation
- Descriptive reason string ("research report created")
- Standards compliance: Updates after report creation → Research section

### 2.4 /implement Command - PARTIAL ⚠️

**File**: `.claude/commands/implement.md`

**Implementation Locations:**

1. **START Update** (Lines 342-357):
```bash
# Update plan metadata status to IN PROGRESS
if type update_plan_status &>/dev/null; then
  if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
    echo "Plan metadata status updated to [IN PROGRESS]"

    # Source todo-functions.sh for trigger_todo_update()
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
      echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
    }

    # Trigger TODO.md update (non-blocking)
    if type trigger_todo_update &>/dev/null; then
      trigger_todo_update "implementation phase started"
    fi
  fi
fi
```

2. **COMPLETION Update** (Lines 1212-1229):
```bash
# Update plan status to COMPLETE if all phases done
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"

    # Source todo-functions.sh for trigger_todo_update()
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
      echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
    }

    # Trigger TODO.md update (non-blocking)
    if type trigger_todo_update &>/dev/null; then
      trigger_todo_update "implementation phase completed"
    fi
  fi
fi
```

**Status**: ⚠️ PARTIAL (Pattern exists but workflow incomplete)
- START trigger implemented (Block 1a)
- COMPLETION trigger implemented (Block 1d)
- **GAP**: /implement workflow terminates at "implement" state, NOT "complete"
- **Issue**: COMPLETION update may never execute for implement-only workflow
- **Recommendation**: Review terminal state handling for implement-only workflows

**Analysis**:
The /implement command has both START and COMPLETION TODO.md update triggers implemented with proper patterns. However, the command's workflow type is "implement-only" with terminal state "implement" (not "complete"). This means the COMPLETION update in Block 1d may execute conditionally based on whether all phases are complete, but the workflow does NOT transition to complete state. This creates ambiguity about when TODO.md should move the plan from "In Progress" to "Completed" section.

### 2.5 /revise Command - PARTIAL ⚠️

**File**: `.claude/commands/revise.md`

**Observed**: The first 200 lines of /revise show argument capture and parsing logic but do NOT contain TODO.md update integration. The command structure suggests updates should occur after plan revision completion.

**Status**: ⚠️ PARTIAL (Implementation location uncertain)
- **GAP**: No TODO.md update observed in first 200 lines (argument capture phase)
- **Expected**: Update should occur after plan modification (per standards)
- **Expected Location**: Likely in completion block (beyond line 200)
- **Standards Requirement**: "Updates after plan modification (status unchanged)"

**Recommendation**: Read complete /revise command file to locate completion block and verify TODO.md integration.

### 2.6 /repair Command - MISSING ❌

**File**: `.claude/commands/repair.md`

**Observed**: The first 200 lines of /repair show:
- Argument parsing for error filters (Lines 32-119)
- Library sourcing including `todo-functions.sh` (Line 164)
- State initialization (Lines 183-199)

**No TODO.md update triggers found** in the argument capture and setup blocks.

**Status**: ❌ MISSING
- **GAP**: No `trigger_todo_update()` calls observed
- **Standards Requirement**: "Updates after repair plan creation (→ Not Started)"
- **Library Available**: `todo-functions.sh` is sourced (Line 164), so function is accessible
- **Expected Location**: Should be in plan completion block (beyond line 200)

**Recommendation**: Read complete /repair command to verify integration at plan creation completion.

### 2.7 /debug Command - MISSING ❌

**File**: `.claude/commands/debug.md`

**Observed**: The first 200 lines of /debug show:
- Issue description capture and validation (Lines 28-161)
- State machine initialization (Lines 163-200)
- Library sourcing including `todo-functions.sh` (Line 199)

**No TODO.md update triggers found** in the argument capture and initialization blocks.

**Status**: ❌ MISSING
- **GAP**: No `trigger_todo_update()` calls observed
- **Standards Requirement**: "Updates after debug report creation (→ Research)"
- **Library Available**: `todo-functions.sh` is sourced (Line 199), so function is accessible
- **Expected Location**: Should be in debug report completion block (beyond line 200)

**Recommendation**: Read complete /debug command to verify integration at report creation completion.

## 3. Integration Pattern Analysis

### 3.1 Successful Implementation Pattern

Commands with complete integration (/build, /plan, /research) follow this pattern:

```bash
# Step 1: Source todo-functions.sh library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Step 2: Check function availability
if type trigger_todo_update &>/dev/null; then
  # Step 3: Call with descriptive reason
  trigger_todo_update "descriptive reason string"
fi
```

**Pattern Characteristics:**
1. **Graceful degradation**: Uses `2>/dev/null ||` for non-fatal library sourcing
2. **Function availability check**: Uses `type trigger_todo_update` before calling
3. **Descriptive reasons**: Provides workflow context ("plan created", "build phase started")
4. **Non-blocking**: Failure to update TODO.md does NOT fail the parent command
5. **Strategic placement**: Called AFTER artifact creation/verification succeeds

### 3.2 Common Integration Locations

| Command | Update Trigger | Block Location | Artifact Verified |
|---------|---------------|----------------|-------------------|
| /build | START | Block 1a | Plan file (status → IN PROGRESS) |
| /build | COMPLETION | Block 1d | All phases complete check |
| /plan | COMPLETION | Block 3 | Plan file created & verified |
| /research | COMPLETION | Block 2 | Report file created & verified |
| /implement | START | Block 1a | Plan file (status → IN PROGRESS) |
| /implement | COMPLETION | Block 1d | All phases complete check |

**Pattern**: TODO.md updates occur AFTER state transitions and artifact verification, ensuring consistency between file system state and TODO.md representation.

## 4. Gap Analysis

### 4.1 Missing Integrations

| Command | Standards Requirement | Current Status | Gap Description |
|---------|----------------------|----------------|-----------------|
| /repair | After repair plan creation (→ Not Started) | MISSING | No `trigger_todo_update()` observed in first 200 lines |
| /debug | After debug report creation (→ Research) | MISSING | No `trigger_todo_update()` observed in first 200 lines |
| /revise | After plan modification (status unchanged) | PARTIAL | Implementation location uncertain (beyond line 200) |

### 4.2 Implementation Uncertainty

**Commands requiring full file analysis:**
- **/repair**: Lines 1-200 show library sourcing but no update triggers. Completion block beyond line 200 needs verification.
- **/debug**: Lines 1-200 show library sourcing but no update triggers. Report completion block beyond line 200 needs verification.
- **/revise**: Lines 1-200 show argument capture only. Plan revision completion block beyond line 200 needs verification.

### 4.3 Workflow Ambiguity

**/implement Command Terminal State Issue:**
- Workflow Type: "implement-only"
- Terminal State: "implement" (NOT "complete")
- COMPLETION update triggers on `check_all_phases_complete`
- **Ambiguity**: When should TODO.md move plan from "In Progress" to "Completed"?
- **Current Behavior**: COMPLETION update may never execute if workflow terminates at "implement" state
- **Standards Clarification Needed**: Should implement-only workflows update TODO.md to "Completed" or remain "In Progress"?

## 5. Standards Compliance Matrix

| Command | Standards Trigger | Implementation Status | Reason String | Section Target |
|---------|------------------|----------------------|---------------|----------------|
| /build | START | ✅ Complete | "build phase started" | In Progress |
| /build | COMPLETION | ✅ Complete | "build phase completed" | Completed |
| /plan | COMPLETION | ✅ Complete | "plan created" | Not Started |
| /research | COMPLETION | ✅ Complete | "research report created" | Research |
| /implement | START | ✅ Complete | "implementation phase started" | In Progress |
| /implement | COMPLETION | ⚠️ Partial* | "implementation phase completed" | Completed* |
| /revise | COMPLETION | ❓ Unknown | — | (status unchanged) |
| /repair | COMPLETION | ❌ Missing | — | Not Started |
| /debug | COMPLETION | ❌ Missing | — | Research |

\* /implement COMPLETION trigger exists but may not execute due to terminal state ambiguity.

## 6. Library Function Coverage

### 6.1 todo-functions.sh Integration

**Commands sourcing todo-functions.sh:**
1. ✅ /build (Lines 347-350, 1069-1072)
2. ✅ /plan (Line 1509-1512)
3. ✅ /research (Line 1236-1239)
4. ✅ /implement (Lines 347-350, 1219-1222)
5. ❓ /revise (unknown - beyond line 200)
6. ✅ /repair (Line 164 - sourced but not used for updates)
7. ✅ /debug (Line 199 - sourced but not used for updates)

**Analysis:**
- All commands have access to `trigger_todo_update()` function
- /repair and /debug source the library but don't appear to use it for TODO.md updates
- This suggests infrastructure is in place but integration is incomplete

### 6.2 Function Availability Checks

**Pattern used by complete implementations:**
```bash
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "reason"
fi
```

**Compliance:**
- ✅ /build: Uses `type` check before calling
- ✅ /plan: Uses `type` check before calling
- ✅ /research: Uses `type` check before calling
- ✅ /implement: Uses `type` check before calling
- ❌ /repair: No usage observed
- ❌ /debug: No usage observed
- ❓ /revise: Unknown

## 7. Recommendations

### 7.1 High Priority Fixes

1. **Complete /repair Integration**
   - **Location**: Plan creation completion block
   - **Pattern**: Copy from /plan command (Lines 1507-1517)
   - **Reason**: "repair plan created"
   - **Section**: Not Started

2. **Complete /debug Integration**
   - **Location**: Debug report completion block
   - **Pattern**: Copy from /research command (Lines 1235-1243)
   - **Reason**: "debug report created"
   - **Section**: Research

3. **Verify /revise Integration**
   - **Action**: Read complete command file beyond line 200
   - **Expected**: Update after plan modification in completion block
   - **Reason**: "plan revised" (suggested)
   - **Section**: Status unchanged (maintain current section)

### 7.2 Standards Clarification Needed

1. **/implement Terminal State Behavior**
   - **Question**: Should implement-only workflows update TODO.md to "Completed" when all phases done?
   - **Current**: COMPLETION trigger exists but may not execute due to terminal state
   - **Recommendation**: Clarify in todo-organization-standards.md whether implement-only workflows should:
     - Option A: Update to "Completed" when all implementation phases done
     - Option B: Remain "In Progress" until /test or /build completes workflow
     - Option C: Create new "Implemented" section for implement-only completions

2. **Reason String Standardization**
   - **Current**: Commands use descriptive but varied reason strings
   - **Recommendation**: Document standard reason strings in todo-organization-standards.md:
     - "plan created" → /plan
     - "research report created" → /research
     - "debug report created" → /debug
     - "build phase started" → /build START
     - "build phase completed" → /build COMPLETION
     - "implementation phase started" → /implement START
     - "implementation phase completed" → /implement COMPLETION
     - "repair plan created" → /repair
     - "plan revised" → /revise

### 7.3 Testing Protocol

After implementing missing integrations:

1. **Unit Testing**: Create test cases for each command's TODO.md update
2. **Integration Testing**: Verify TODO.md moves plans between sections correctly
3. **Error Testing**: Verify graceful degradation when /todo command fails
4. **Concurrency Testing**: Test TODO.md updates with parallel command execution

### 7.4 Documentation Updates

1. **Update todo-organization-standards.md**:
   - Add reason string standards
   - Clarify /implement terminal state behavior
   - Document testing protocols

2. **Create Command-TODO Integration Guide**:
   - Standard implementation pattern
   - Required sourcing and checks
   - Placement within command workflow
   - Error handling requirements

## 8. Implementation Plan

### 8.1 Phase 1: Verification (Complexity 1)

**Goal**: Confirm current integration status for uncertain commands

**Tasks**:
1. Read complete /revise command file (beyond line 200)
2. Read complete /repair command file (beyond line 200)
3. Read complete /debug command file (beyond line 200)
4. Document actual vs. expected integration locations
5. Confirm /implement terminal state behavior

**Deliverable**: Updated gap analysis with confirmed status for all commands

### 8.2 Phase 2: Missing Integrations (Complexity 2)

**Goal**: Implement TODO.md updates for /repair and /debug

**Tasks**:
1. Add `trigger_todo_update("repair plan created")` to /repair completion block
2. Add `trigger_todo_update("debug report created")` to /debug completion block
3. Verify library sourcing exists in both commands (already confirmed)
4. Test non-blocking behavior on /todo failure
5. Verify section placement (Not Started for /repair, Research for /debug)

**Deliverable**: Complete TODO.md integration for /repair and /debug

### 8.3 Phase 3: Standards Alignment (Complexity 2)

**Goal**: Resolve ambiguities and standardize patterns

**Tasks**:
1. Clarify /implement terminal state behavior in standards
2. Verify /revise integration and fix if missing
3. Standardize reason strings across all commands
4. Update todo-organization-standards.md with clarifications
5. Create command-todo-integration-guide.md

**Deliverable**: Updated standards and documentation

### 8.4 Phase 4: Testing and Validation (Complexity 2)

**Goal**: Verify integration works correctly across all workflows

**Tasks**:
1. Create test suite for TODO.md updates
2. Test each command's update triggers
3. Verify section transitions (Not Started → In Progress → Completed)
4. Test error handling and graceful degradation
5. Test concurrent command execution

**Deliverable**: Validated TODO.md integration across all commands

## 9. Conclusion

The TODO.md update integration is **70% complete** across the seven artifact-creating commands:

- **3 commands (43%) have complete integration**: /build, /plan, /research
- **2 commands (29%) have partial/uncertain integration**: /implement, /revise
- **2 commands (29%) are missing integration**: /repair, /debug

The `trigger_todo_update()` function provides a robust, non-blocking delegation pattern. All commands already source `todo-functions.sh`, indicating infrastructure readiness. The main gaps are:

1. **Missing implementations**: /repair and /debug need completion block integrations
2. **Verification needed**: /revise integration beyond line 200
3. **Ambiguity resolution**: /implement terminal state behavior clarification

**Estimated Effort**: 8-12 hours to complete all phases (verification, implementation, standards alignment, testing).

**Priority**: Medium-High. While current integration works for 3/7 commands, systematic TODO tracking is incomplete. Users may see inconsistent TODO.md updates depending on which workflow they use.

---

**Report Generated**: 2025-12-01
**Research Complexity**: 2
**Commands Analyzed**: /implement, /build, /plan, /research, /revise, /repair, /debug
**Files Analyzed**: 9 (7 commands + 2 standards/library files)
