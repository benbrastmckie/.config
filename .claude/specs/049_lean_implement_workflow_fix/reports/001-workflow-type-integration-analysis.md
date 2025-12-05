# Workflow Type Integration Analysis: /lean-implement Command Fix

**Research Date**: 2025-12-04
**Research Complexity**: 3
**Researcher**: research-specialist
**Topic**: Fix /lean-implement command workflow_type incompatibility with workflow-state-machine.sh

---

## Executive Summary

The `/lean-implement` command uses `WORKFLOW_TYPE="lean-implement-hybrid"` which is not recognized by `workflow-state-machine.sh`. The state machine validates workflow types against a hardcoded enum and rejects the invalid type, causing command initialization to fail.

**Root Cause**: Mismatch between command-specific workflow type identifier and state machine's valid workflow type enum.

**Recommended Solution**: Use existing `implement-only` workflow type with `TERMINAL_STATE="$STATE_IMPLEMENT"` mapping. This aligns with the command's purpose (hybrid implementation without testing) and requires no state machine changes.

---

## 1. Error Analysis

### 1.1 Error Output

From `/home/benjamin/.config/.claude/output/lean-implement-output.md`:

```
ERROR: Invalid workflow_type: lean-implement-hybrid
  Valid types: research-only, research-and-plan, research-and-revise, full-implementation,
  debug-only, implement-only, test-and-debug
```

**Location**: Line 347 in output
**Context**: `sm_init()` validation during Block 1a (Setup & Phase Classification)
**Exit Code**: 1 (initialization failed)

### 1.2 Failure Point

File: `/home/benjamin/.config/.claude/commands/lean-implement.md`
Line: 245

```bash
WORKFLOW_TYPE="lean-implement-hybrid"
```

This custom workflow type is passed to `sm_init()` at line 281:

```bash
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
```

The state machine rejects it during validation (workflow-state-machine.sh:471-479).

---

## 2. Valid Workflow Types in workflow-state-machine.sh

### 2.1 Enumeration Definition

File: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
Lines: 471-479

```bash
case "$workflow_type" in
  research-only|research-and-plan|research-and-revise|full-implementation|debug-only|implement-only|test-and-debug)
    : # Valid
    ;;
  *)
    echo "ERROR: Invalid workflow_type: $workflow_type" >&2
    echo "  Valid types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only, implement-only, test-and-debug" >&2
    return 1
    ;;
esac
```

### 2.2 Terminal State Mapping

Lines: 530-556 in workflow-state-machine.sh

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"
    ;;
  implement-only)
    TERMINAL_STATE="$STATE_IMPLEMENT"
    ;;
  test-and-debug)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  *)
    echo "WARNING: Unknown workflow scope '$WORKFLOW_SCOPE', defaulting to full-implementation" >&2
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
esac
```

### 2.3 State Constants

Lines: 47-54 in workflow-state-machine.sh

```bash
readonly STATE_INITIALIZE="initialize"       # Phase 0: Setup, scope detection, path pre-calculation
readonly STATE_RESEARCH="research"           # Phase 1: Research topic via specialist agents
readonly STATE_PLAN="plan"                   # Phase 2: Create implementation plan
readonly STATE_IMPLEMENT="implement"         # Phase 3: Execute implementation
readonly STATE_TEST="test"                   # Phase 4: Run test suite
readonly STATE_DEBUG="debug"                 # Phase 5: Debug failures (conditional)
readonly STATE_DOCUMENT="document"           # Phase 6: Update documentation (conditional)
readonly STATE_COMPLETE="complete"           # Phase 7: Finalization, cleanup
```

---

## 3. /lean-implement Command Architecture

### 3.1 Command Purpose

File: `/home/benjamin/.config/.claude/commands/lean-implement.md`
Lines: 1-28

**Workflow Type**: `lean-implement-hybrid` (INVALID)
**Expected Input**: Plan file with mixed Lean/software phases
**Expected Output**: Completed implementation with proofs and code

The command provides hybrid implementation capabilities for plans containing:
- **Lean phases**: Theorem proving, proof verification, Mathlib integration
- **Software phases**: Test harness setup, documentation, tooling

### 3.2 Phase Classification Algorithm

Lines: 430-461 in lean-implement.md

**2-Tier Detection**:

1. **Tier 1 - Phase Metadata (Strongest Signal)**:
   - If `lean_file:` metadata exists → classify as "lean"

2. **Tier 2 - Keyword and Extension Analysis**:
   - **Lean indicators**: `.lean`, `theorem`, `lemma`, `sorry`, `tactic`, `mathlib`, `lean_`
   - **Software indicators**: `.ts`, `.js`, `.py`, `.sh`, `.md`, `implement`, `create`, `write tests`
   - **Default**: "software" for ambiguous phases

### 3.3 Coordinator Routing

Lines: 574-772 in lean-implement.md

Based on phase classification:
- **Phase type = "lean"** → Invoke `lean-coordinator` agent
- **Phase type = "software"** → Invoke `implementer-coordinator` agent

### 3.4 Terminal State Behavior

**Current (broken)**: Attempts to use `lean-implement-hybrid` → validation fails
**Expected**: Should reach `STATE_IMPLEMENT` as terminal state (implementation complete, no testing)

---

## 4. Solution Analysis

### 4.1 Option A: Add New Workflow Type to State Machine

**Changes Required**:

1. Update `workflow-state-machine.sh` line 472:
   ```bash
   research-only|research-and-plan|research-and-revise|full-implementation|debug-only|implement-only|test-and-debug|lean-implement-hybrid)
   ```

2. Add terminal state mapping at line 556:
   ```bash
   lean-implement-hybrid)
     TERMINAL_STATE="$STATE_IMPLEMENT"
     ;;
   ```

3. Update all checkpoint loaders (lines 612-640) to include mapping

**Pros**:
- Semantic clarity: workflow type explicitly describes hybrid routing
- Self-documenting: type name indicates Lean+software coordination

**Cons**:
- Requires state machine library modification (affects all commands)
- No functional difference from `implement-only` (same terminal state)
- Increases maintenance surface for no operational benefit
- Violates command infrastructure best practice: "Use existing types when semantically equivalent"

### 4.2 Option B: Use Existing `implement-only` Type

**Changes Required**:

1. Update `/home/benjamin/.config/.claude/commands/lean-implement.md` line 245:
   ```bash
   WORKFLOW_TYPE="implement-only"
   ```

2. Update documentation line 24 in lean-implement.md:
   ```markdown
   **Workflow Type**: implement-only
   ```

**Pros**:
- No state machine changes required
- Semantically correct: command implements plans without testing
- Consistent with existing infrastructure patterns
- Terminal state mapping already correct: `implement-only` → `STATE_IMPLEMENT`
- Follows established precedent (see `/implement` command)

**Cons**:
- Loses explicit "hybrid" designation in workflow type (retained in command name)

### 4.3 Comparison with /implement Command

File: `/home/benjamin/.config/.claude/commands/implement.md`
Line: 350

```bash
WORKFLOW_TYPE="implement-only"
```

From `/home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md`:

- **Purpose**: Write code AND tests (but do not execute tests)
- **Workflow Type**: implement-only
- **Terminal State**: IMPLEMENT (with option to continue to COMPLETE)

**Semantic Alignment**:
- `/implement`: Single coordinator (implementer-coordinator)
- `/lean-implement`: Dual coordinators (lean-coordinator + implementer-coordinator) with routing logic

Both commands:
- Execute implementation phases
- Do NOT run tests
- Terminal state: `STATE_IMPLEMENT`
- Should use `implement-only` workflow type

The hybrid routing is an **implementation detail**, not a workflow scope distinction.

---

## 5. State Machine Integration Requirements

### 5.1 State Transition Flow

**Standard implement-only workflow**:
```
initialize → implement → [TERMINAL]
```

**Valid transitions from IMPLEMENT** (lines 65 in workflow-state-machine.sh):
```bash
[implement]="test,complete"       # Can go to testing or complete (implement-only workflows)
```

For `implement-only` workflows:
- Terminal state: `STATE_IMPLEMENT`
- Workflow completes after implementation without transitioning to test/debug

### 5.2 Required sm_init() Call Pattern

From command-authoring.md and lean-implement.md lines 281-295:

```bash
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1a" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --arg plan "$PLAN_FILE" \
       '{workflow_type: $type, plan_file: $plan}')"
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi
```

**Parameters**:
1. `$PLAN_FILE` - Workflow description (plan path)
2. `$COMMAND_NAME` - "/lean-implement"
3. `$WORKFLOW_TYPE` - Must be valid enum value
4. `"1"` - Research complexity (hardcoded to 1, no research phase)
5. `"[]"` - Research topics JSON (empty, no research)

### 5.3 State Transition Requirements

Lines 298-311 in lean-implement.md:

```bash
# Transition to implement state
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting hybrid implementation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to IMPLEMENT failed" \
    "bash_block_1a" \
    "$(jq -n --arg state "IMPLEMENT" '{target_state: $state}')"
  echo "ERROR: State transition to IMPLEMENT failed" >&2
  exit 1
fi
```

**Valid transition**: `initialize → implement` (allowed by transition table line 62)

---

## 6. Documentation Standards Integration

### 6.1 Command Infrastructure Best Practices

From `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`:

**Subprocess Isolation Requirements**:
- State machine must be initialized in Block 1a
- Workflow type must be valid enum value
- Terminal state must be deterministic from workflow type

**State Persistence Patterns**:
- `WORKFLOW_SCOPE` exported and persisted to state file
- `TERMINAL_STATE` computed from workflow scope
- `CURRENT_STATE` tracks progression through state machine

### 6.2 Clean-Break Development Standard

From `/home/benjamin/.config/CLAUDE.md` lines 91-98:

> Internal tooling changes: ALWAYS use clean-break (no deprecation periods)

**Application**:
- If adding `lean-implement-hybrid` to state machine, NO backward compatibility needed
- If using `implement-only`, direct replacement with no migration path

### 6.3 Output Formatting Standards

From `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md`:

**Console Summary Format** (lines 1175-1242 in lean-implement.md):
```bash
echo "=== Hybrid Implementation Complete ==="
echo ""
echo "Summary: $SUMMARY_TEXT"
echo ""
echo "Phases:"
echo "$PHASES"
echo ""
echo "Artifacts:"
echo "$ARTIFACTS"
```

**No changes required** - output format independent of workflow type.

---

## 7. Recommended Solution: Use `implement-only`

### 7.1 Rationale

1. **Semantic Equivalence**: Both `/implement` and `/lean-implement` execute implementation without testing
2. **Infrastructure Alignment**: `implement-only` already maps to `STATE_IMPLEMENT` terminal state
3. **Minimal Change**: Single-line fix vs multi-file state machine update
4. **Best Practice Compliance**: Use existing types when functionally equivalent
5. **Maintenance Reduction**: No new enum value to propagate through checkpoint loaders

### 7.2 Implementation Plan

**File**: `/home/benjamin/.config/.claude/commands/lean-implement.md`

**Change 1** (Line 245):
```bash
# Before
WORKFLOW_TYPE="lean-implement-hybrid"

# After
WORKFLOW_TYPE="implement-only"
```

**Change 2** (Line 24, documentation):
```markdown
# Before
**Workflow Type**: lean-implement-hybrid

# After
**Workflow Type**: implement-only
```

**Validation**:
```bash
# Test initialization
/lean-implement <plan-file> --dry-run

# Expected output
Classification accepted: scope=implement-only, complexity=1, topics=0
State machine initialized: scope=implement-only, terminal=implement
```

### 7.3 Risk Assessment

**Risk Level**: LOW

**Rationale**:
- Single workflow type constant change
- No state machine modification
- No agent contract changes
- Routing logic independent of workflow type
- Documentation update non-breaking

**Testing Requirements**:
1. Verify `sm_init()` succeeds with `implement-only`
2. Verify state transition `initialize → implement` succeeds
3. Verify phase classification still routes correctly
4. Verify lean-coordinator invocation succeeds
5. Verify implementer-coordinator invocation succeeds
6. Verify completion summary emitted correctly

---

## 8. Alternative Solution: Add `lean-implement-hybrid` (Not Recommended)

### 8.1 Changes Required

**File 1**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Change 1** (Line 472):
```bash
# Before
research-only|research-and-plan|research-and-revise|full-implementation|debug-only|implement-only|test-and-debug)

# After
research-only|research-and-plan|research-and-revise|full-implementation|debug-only|implement-only|test-and-debug|lean-implement-hybrid)
```

**Change 2** (Line 556):
```bash
# Add after test-and-debug case
lean-implement-hybrid)
  TERMINAL_STATE="$STATE_IMPLEMENT"
  ;;
```

**Change 3** (Lines 612-640, three occurrences):
```bash
# Add to sm_load checkpoint mapping
case "$WORKFLOW_SCOPE" in
  research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
  research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
  full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
  debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
  implement-only) TERMINAL_STATE="$STATE_IMPLEMENT" ;;
  test-and-debug) TERMINAL_STATE="$STATE_COMPLETE" ;;
  lean-implement-hybrid) TERMINAL_STATE="$STATE_IMPLEMENT" ;;  # NEW
  *) TERMINAL_STATE="$STATE_COMPLETE" ;;
esac
```

**File 2**: `/home/benjamin/.config/.claude/docs/architecture/state-orchestration-states.md`

Add documentation for new workflow type (estimated 20 lines).

**File 3**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md`

Update workflow type reference (line ~24).

### 8.2 Why Not Recommended

1. **Functional Duplication**: `lean-implement-hybrid` → `STATE_IMPLEMENT` is identical to `implement-only` → `STATE_IMPLEMENT`
2. **Maintenance Burden**: All future state machine changes must account for new type
3. **Infrastructure Bloat**: Adds enum value with no operational difference
4. **Standards Violation**: Best practice is to use existing types when semantically equivalent
5. **Testing Overhead**: Requires state machine regression testing for new type

**Only justifiable if**: Future hybrid commands need different terminal states (e.g., `lean-implement-with-testing` → `STATE_COMPLETE`). No such requirement exists.

---

## 9. Impact Analysis

### 9.1 Affected Components (Recommended Solution)

**Modified Files**:
1. `/home/benjamin/.config/.claude/commands/lean-implement.md` (2 lines)

**Unaffected Components**:
- `workflow-state-machine.sh` (no changes)
- Agent contracts (lean-coordinator, implementer-coordinator)
- Phase classification logic
- Routing map construction
- Checkpoint persistence
- Error logging

### 9.2 Backward Compatibility

**None required** - `/lean-implement` is new command (no existing state files to migrate).

### 9.3 Testing Strategy

**Unit Tests**:
```bash
# Test 1: Verify sm_init accepts implement-only
sm_init "test plan" "/lean-implement" "implement-only" "1" "[]"
echo $?  # Expected: 0

# Test 2: Verify terminal state mapping
echo $TERMINAL_STATE  # Expected: implement
```

**Integration Tests**:
```bash
# Test 3: Full command execution
/lean-implement .claude/specs/049_lean_implement_workflow_fix/plans/test-hybrid-plan.md --dry-run

# Expected output:
# Classification accepted: scope=implement-only, complexity=1, topics=0
# State machine initialized: scope=implement-only, terminal=implement
```

**Regression Tests**:
```bash
# Test 4: Verify existing implement-only commands unaffected
/implement <plan-file> --dry-run

# Test 5: Verify debug-only still works
/debug <issue-description> --dry-run
```

---

## 10. Migration Path (Recommended Solution)

### 10.1 Implementation Steps

**Step 1**: Update lean-implement.md
```bash
# Edit line 245
sed -i 's/WORKFLOW_TYPE="lean-implement-hybrid"/WORKFLOW_TYPE="implement-only"/' \
  .claude/commands/lean-implement.md

# Edit line 24 (documentation)
sed -i 's/\*\*Workflow Type\*\*: lean-implement-hybrid/**Workflow Type**: implement-only/' \
  .claude/commands/lean-implement.md
```

**Step 2**: Verify changes
```bash
grep -n "WORKFLOW_TYPE\|Workflow Type" .claude/commands/lean-implement.md
# Expected:
#   24:**Workflow Type**: implement-only
#   245:WORKFLOW_TYPE="implement-only"
```

**Step 3**: Test initialization
```bash
/lean-implement <test-plan> --dry-run
```

**Step 4**: Full integration test
```bash
/lean-implement <test-plan>
# Verify completion summary emitted
# Verify phase markers updated
```

### 10.2 Rollback Plan

**If issues arise**:
```bash
# Revert line 245
sed -i 's/WORKFLOW_TYPE="implement-only"/WORKFLOW_TYPE="lean-implement-hybrid"/' \
  .claude/commands/lean-implement.md

# Revert line 24
sed -i 's/\*\*Workflow Type\*\*: implement-only/**Workflow Type**: lean-implement-hybrid/' \
  .claude/commands/lean-implement.md
```

**Then implement Alternative Solution** (add `lean-implement-hybrid` to state machine).

### 10.3 Success Criteria

1. `sm_init()` succeeds with `implement-only` workflow type
2. State transition `initialize → implement` succeeds
3. Phase classification routes Lean phases to lean-coordinator
4. Phase classification routes software phases to implementer-coordinator
5. Terminal state reached: `STATE_IMPLEMENT`
6. Completion summary displays correct metrics
7. No regression in existing commands (`/implement`, `/debug`, etc.)

---

## 11. Conclusion

The `/lean-implement` command failure is caused by using a custom workflow type (`lean-implement-hybrid`) not recognized by the state machine's validation enum. The recommended solution is to use the existing `implement-only` workflow type, which provides identical terminal state behavior (`STATE_IMPLEMENT`) and requires minimal changes.

**Key Findings**:
1. `implement-only` is semantically equivalent to the command's purpose
2. Hybrid routing logic is an implementation detail, not a workflow scope distinction
3. Adding a new workflow type provides no functional benefit
4. Best practice: Use existing infrastructure when semantically aligned

**Recommended Action**: Update `WORKFLOW_TYPE="implement-only"` in lean-implement.md (2-line change).

**Alternative (if explicit hybrid designation required)**: Add `lean-implement-hybrid` to state machine enum with `STATE_IMPLEMENT` terminal state mapping (8+ line change across 3 files).

---

## Appendices

### Appendix A: Error Log Entry

From centralized error logging:
```
timestamp: 2025-12-04T13:26:XX
command: /lean-implement
workflow_id: lean_implement_17XXXXXXX
error_type: state_error
error_message: State machine initialization failed
error_details: {"workflow_type": "lean-implement-hybrid", "plan_file": "/path/to/plan.md"}
bash_block: bash_block_1a
```

### Appendix B: State Machine Version

```bash
WORKFLOW_STATE_MACHINE_VERSION="2.0.0"
```

File: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
Last Modified: 2025-11-17

### Appendix C: Related Commands Using implement-only

1. `/implement` - Standard implementation-only workflow
   - File: `.claude/commands/implement.md`
   - Line 350: `WORKFLOW_TYPE="implement-only"`
   - Terminal State: `STATE_IMPLEMENT`

### Appendix D: Terminal State Constants

```bash
readonly STATE_INITIALIZE="initialize"       # Phase 0
readonly STATE_RESEARCH="research"           # Phase 1
readonly STATE_PLAN="plan"                   # Phase 2
readonly STATE_IMPLEMENT="implement"         # Phase 3 - TERMINAL for implement-only
readonly STATE_TEST="test"                   # Phase 4
readonly STATE_DEBUG="debug"                 # Phase 5 - TERMINAL for debug-only
readonly STATE_DOCUMENT="document"           # Phase 6
readonly STATE_COMPLETE="complete"           # Phase 7 - TERMINAL for full-implementation
```

### Appendix E: Command Frontmatter

From `/home/benjamin/.config/.claude/commands/lean-implement.md` lines 1-18:

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: [plan-file] [starting-phase] [--mode=auto|lean-only|software-only] [--max-iterations=N]
description: Hybrid implementation command for mixed Lean/software plans with intelligent phase routing
command-type: primary
subcommands:
  - auto: "Automatically detect phase type and route to appropriate coordinator (default)"
  - lean-only: "Execute only Lean phases (theorem proving)"
  - software-only: "Execute only software phases (implementation)"
dependent-agents:
  - lean-coordinator
  - implementer-coordinator
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - state-persistence.sh: ">=1.6.0"
  - workflow-state-machine.sh: ">=2.0.0"
documentation: See .claude/docs/guides/commands/lean-implement-command-guide.md for usage
---
```

**No frontmatter changes required** - workflow type is runtime variable, not metadata.

---

**End of Report**
