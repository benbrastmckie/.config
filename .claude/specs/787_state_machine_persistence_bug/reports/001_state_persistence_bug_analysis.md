# State Machine Persistence Bug Analysis Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: State machine persistence bugs across orchestration commands
- **Report Type**: codebase analysis

## Executive Summary

Analysis of 6 orchestration commands (build.md, coordinate.md, plan.md, research.md, debug.md, revise.md) reveals that build.md Part 4 is the PRIMARY affected command with the missing `load_workflow_state()` bug. Other commands correctly implement the state restoration pattern before calling `sm_transition()` or `append_workflow_state()`. The bug in build.md Part 4 (lines 281-340) sources the libraries but fails to call `load_workflow_state()` before using `sm_transition()`, which causes CURRENT_STATE persistence failures.

## Findings

### Commands with State Machine Usage

All 6 commands using state-persistence.sh and workflow-state-machine.sh:
1. **build.md** - Full implementation workflow
2. **coordinate.md** - Multi-agent orchestration
3. **plan.md** - Research and plan workflow
4. **research.md** - Research-only workflow
5. **debug.md** - Debug-focused workflow
6. **revise.md** - Research and revise workflow

### Bug Pattern Analysis

The bug pattern identified in build.md Part 4:
```bash
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# MISSING: load_workflow_state "$WORKFLOW_ID" false

# Then later calls sm_transition which fails because CURRENT_STATE is not loaded
sm_transition "$STATE_IMPLEMENT"
```

### Affected Commands

#### 1. build.md - AFFECTED (PRIMARY BUG)

**Part 4 (lines 281-340)**: Sources libraries but MISSING `load_workflow_state()` call before `sm_transition "$STATE_IMPLEMENT"`

Location: `/home/benjamin/.config/.claude/commands/build.md:305-310`
```bash
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Transition to implement state with return code verification
if ! sm_transition "$STATE_IMPLEMENT" 2>&1; then
```

**MISSING between lines 307 and 309:**
```bash
# Load WORKFLOW_ID and workflow state
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
load_workflow_state "$WORKFLOW_ID" false
```

**Parts 5, 6, and 7 are CORRECT** - they all properly call `load_workflow_state()`:
- Part 5 (line 522): `load_workflow_state "$WORKFLOW_ID" false`
- Part 6 (line 651): `load_workflow_state "$WORKFLOW_ID" false`
- Part 6 additional (line 806): `load_workflow_state "$WORKFLOW_ID" false`
- Part 7 (line 897): `load_workflow_state "$WORKFLOW_ID" false`

#### 2. coordinate.md - NOT AFFECTED

Properly implements the pattern throughout:
- Phase 0.1 (line 240): `load_workflow_state "$WORKFLOW_ID"`
- Phase 0.2 (line 321): `load_workflow_state "$WORKFLOW_ID" false "CLASSIFICATION_JSON"`
- Research Phase (line 655): `load_workflow_state "$WORKFLOW_ID"`
- All subsequent phases follow the same correct pattern

#### 3. plan.md - NOT AFFECTED

Properly implements the pattern:
- Part 3a (line 242): `load_workflow_state "$WORKFLOW_ID" false`
- Part 4 (line 421): `load_workflow_state "$WORKFLOW_ID" false`
- Part 5 (line 545): `load_workflow_state "$WORKFLOW_ID" false`

#### 4. research.md - NOT AFFECTED

Properly implements the pattern:
- Part 3a (line 241): `load_workflow_state "$WORKFLOW_ID" false`
- Part 4 (line 411): `load_workflow_state "$WORKFLOW_ID" false`

#### 5. debug.md - PARTIALLY CORRECT (Minor Issues)

The command uses `$$.txt` pattern (process ID) for some state files which may not persist correctly:
- Part 2a (line 193): `load_workflow_state "$WORKFLOW_ID" false` - CORRECT
- Part 3 (lines 219-224): Sources libraries but uses legacy `$$` pattern, then calls `sm_transition "$STATE_RESEARCH"` WITHOUT explicit `load_workflow_state()` call BEFORE `sm_transition`

Location: `/home/benjamin/.config/.claude/commands/debug.md:216-224`
```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
```

**MISSING `load_workflow_state()` before `sm_transition()`**

However, later parts ARE correct:
- Part 4 (line 380): `load_workflow_state "${WORKFLOW_ID:-$$}" false`
- Part 5 (line 510): `load_workflow_state "${WORKFLOW_ID:-$$}" false`
- Part 6 (line 621): `load_workflow_state "${WORKFLOW_ID:-$$}" false`

#### 6. revise.md - PARTIALLY CORRECT (Minor Issue)

**Part 3 Research Phase (lines 213-231)**: Sources libraries but MISSING `load_workflow_state()` before `sm_transition "$STATE_RESEARCH"`

Location: `/home/benjamin/.config/.claude/commands/revise.md:213-216`
```bash
set +H  # CRITICAL: Disable history expansion
# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
```

**MISSING between lines 213 and 216:**
```bash
# Load WORKFLOW_ID and workflow state
STATE_ID_FILE="${HOME}/.claude/tmp/revise_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
load_workflow_state "$WORKFLOW_ID" false
```

Later parts ARE correct:
- Part 4 (line 336): `load_workflow_state "$WORKFLOW_ID" false`
- Part 5 (line 481): `load_workflow_state "$WORKFLOW_ID" false`

### Summary of Bugs

| Command | Part | Line Numbers | Issue | Severity |
|---------|------|-------------|-------|----------|
| build.md | Part 4 | 305-310 | Missing load_workflow_state() before sm_transition($STATE_IMPLEMENT) | HIGH |
| debug.md | Part 3 | 216-224 | Missing load_workflow_state() before sm_transition($STATE_RESEARCH) | MEDIUM |
| revise.md | Part 3 | 213-216 | Missing load_workflow_state() before sm_transition($STATE_RESEARCH) | MEDIUM |

## Recommendations

### 1. Fix build.md Part 4 (HIGH PRIORITY)

Add state restoration between library sourcing and sm_transition at line 308:

```bash
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# Transition to implement state with return code verification
if ! sm_transition "$STATE_IMPLEMENT" 2>&1; then
```

### 2. Fix debug.md Part 3 (MEDIUM PRIORITY)

Add state restoration before sm_transition at line 216:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

# Load WORKFLOW_ID from file
STATE_ID_FILE="${HOME}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false
fi

# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
```

### 3. Fix revise.md Part 3 (MEDIUM PRIORITY)

Add state restoration before sm_transition at line 213:

```bash
set +H  # CRITICAL: Disable history expansion

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file
STATE_ID_FILE="${HOME}/.claude/tmp/revise_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
```

### 4. Establish Code Pattern Standard

Create a standard code pattern for all bash blocks that source state machine libraries:

```bash
# STANDARD STATE MACHINE BLOCK PATTERN
# 1. Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# 2. Load WORKFLOW_ID from command-specific state file
STATE_ID_FILE="${HOME}/.claude/tmp/${COMMAND_NAME}_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# 3. Load workflow state BEFORE any state operations
load_workflow_state "$WORKFLOW_ID" false

# 4. Now safe to call sm_transition, append_workflow_state, etc.
```

### 5. Add Automated Verification

Create a test script that validates all commands follow the state restoration pattern:
- Verify every bash block that sources state-persistence.sh also calls load_workflow_state() before sm_transition()
- Flag any violations during CI/CD

## References

### Files Analyzed

1. `/home/benjamin/.config/.claude/commands/build.md` - Lines 1-976
2. `/home/benjamin/.config/.claude/commands/coordinate.md` - Lines 1-1100+ (partial)
3. `/home/benjamin/.config/.claude/commands/plan.md` - Lines 1-596
4. `/home/benjamin/.config/.claude/commands/research.md` - Lines 1-454
5. `/home/benjamin/.config/.claude/commands/debug.md` - Lines 1-690
6. `/home/benjamin/.config/.claude/commands/revise.md` - Lines 1-527

### Related Libraries

1. `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State persistence functions
2. `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine implementation

### Existing Plan

- `/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/plans/001_state_machine_persistence_fix_plan.md`

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001_state_machine_persistence_fix_plan.md](../plans/001_state_machine_persistence_fix_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
- **Note**: Findings from this report integrated into revised plan
