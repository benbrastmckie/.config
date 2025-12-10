# Commands Affected by Concurrent Execution Analysis

**Research Topic**: Commands affected by concurrent execution interference through shared state files

**Date**: 2025-12-10

**Status**: Complete

---

## Research Objective

Identify all commands in the `.claude/commands/` directory that use shared state files and are vulnerable to concurrent execution interference, similar to the issue observed with `/create-plan`.

## Methodology

1. List all commands in `.claude/commands/` directory
2. Analyze each command for state file usage patterns
3. Identify shared state files (plan_state_id.txt, workflow_*.sh, etc.)
4. Categorize commands by risk level
5. Document state file dependencies

## Commands Inventory

Total commands analyzed: 19

### Commands by State File Usage

Commands were categorized based on their usage of shared state files and susceptibility to concurrent execution interference.

## Detailed Analysis

### HIGH RISK: Commands Using Shared State ID Files

These commands all use persistent state ID files that enable state recovery across bash blocks. When two instances run concurrently in the same repository, they overwrite each other's state files, causing "Failed to restore WORKFLOW_ID" errors.

#### 1. /create-plan
- **State ID File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt`
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: CRITICAL
- **Evidence**: 13 references to plan_state_id.txt across multiple bash blocks
- **Interference Pattern**:
  - Block 1 writes WORKFLOW_ID to plan_state_id.txt
  - Blocks 2+ read WORKFLOW_ID from plan_state_id.txt
  - Concurrent execution overwrites plan_state_id.txt, breaking state restoration
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 2. /lean-plan
- **State ID File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt`
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: CRITICAL
- **Evidence**: 11 references to lean_plan_state_id.txt
- **Interference Pattern**: Same as /create-plan
- **Note**: Also has one reference to plan_state_id.txt (line 1077) - possible fallback or legacy code
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 3. /lean-implement
- **State ID File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_implement_state_id.txt`
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: CRITICAL
- **Evidence**: 6 references to lean_implement_state_id.txt
- **Interference Pattern**: Same as /create-plan
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 4. /implement
- **State ID File**: Not explicitly named (likely auto-generated or uses command name pattern)
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: HIGH
- **Evidence**: Uses state-persistence.sh and workflow-state-machine.sh
- **Interference Pattern**: Potential collision on workflow_${WORKFLOW_ID}.sh if WORKFLOW_IDs collide
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 5. /research
- **State ID File**: Not explicitly named
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: HIGH
- **Evidence**: Uses state-persistence.sh and workflow-state-machine.sh (4 sourcing references)
- **Interference Pattern**: Same as /implement
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 6. /debug
- **State ID File**: Not explicitly named
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: HIGH
- **Evidence**: Uses state-persistence.sh and workflow-state-machine.sh (8 sourcing references)
- **Interference Pattern**: Same as /implement
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 7. /repair
- **State ID File**: Not explicitly named
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: HIGH
- **Evidence**: Uses state-persistence.sh and workflow-state-machine.sh
- **Interference Pattern**: Same as /implement
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 8. /revise
- **State ID File**: Not explicitly named
- **Workflow State File**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Risk Level**: HIGH
- **Evidence**: Uses state-persistence.sh and workflow-state-machine.sh (8 sourcing references)
- **Interference Pattern**: Same as /implement
- **Dependencies**: state-persistence.sh, workflow-state-machine.sh

#### 9. /lean-build
- **State ID File**: None (no explicit state ID persistence pattern found)
- **Workflow State File**: Uses STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
- **Risk Level**: MEDIUM
- **Evidence**: Uses state-persistence.sh, creates workflow state with init_workflow_state
- **Interference Pattern**: Lower risk due to trap-based cleanup, but WORKFLOW_ID collision possible
- **Dependencies**: state-persistence.sh

### MEDIUM RISK: Commands Without Persistent State ID Files

#### 10. /expand
- **State Files**: None found
- **Risk Level**: LOW
- **Evidence**: No state-persistence.sh or workflow-state-machine.sh sourcing
- **Notes**: Orchestrator command, uses Edit for metadata updates only

#### 11. /collapse
- **State Files**: None found
- **Risk Level**: LOW
- **Evidence**: No state-persistence.sh or workflow-state-machine.sh sourcing
- **Notes**: Orchestrator command, uses Edit for metadata updates only

### LOW RISK: Commands Without State File Usage

Commands that don't use state persistence libraries or shared state files:

12. /convert-docs
13. /optimize-claude
14. /setup
15. /test
16. /errors
17. /lean-update
18. /todo

**Note**: These commands may still use temporary files but don't exhibit the shared state ID file pattern that causes concurrent execution interference.

## Root Cause Analysis

### Shared State File Pattern

All high-risk commands follow this pattern:

```bash
# Block 1: Initialize and persist state ID
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/[command]_state_id.txt"
WORKFLOW_ID="[command]_$(date +%s)"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Blocks 2+: Restore state ID
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/[command]_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"
```

### Interference Mechanism

When two instances of the same command run concurrently:

1. **Command A Block 1**: Writes `WORKFLOW_ID_A` to state_id.txt
2. **Command B Block 1**: Overwrites with `WORKFLOW_ID_B` to state_id.txt
3. **Command A Block 2**: Reads `WORKFLOW_ID_B` from state_id.txt (WRONG!)
4. **Command A Block 2**: Tries to source workflow_WORKFLOW_ID_B.sh (doesn't exist for Command A)
5. **Result**: "Failed to restore WORKFLOW_ID" error

### State File Locations

Per state-persistence.sh header (lines 10-24):

```
State files are ALWAYS created at:
  ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh
```

All workflow state files use this single directory (`.claude/tmp/`), making collision inevitable when:
- Same command runs twice concurrently
- Different commands share state ID file names
- WORKFLOW_IDs collide (low probability but possible)

## Impact Assessment

### Commands with CRITICAL Risk (State ID File Pattern)

1. **/create-plan** - Most vulnerable (13 references to plan_state_id.txt)
2. **/lean-plan** - Highly vulnerable (11 references)
3. **/lean-implement** - Highly vulnerable (6 references)

### Commands with HIGH Risk (Workflow State Pattern)

4. **/implement** - Moderate vulnerability (WORKFLOW_ID collision possible)
5. **/research** - Moderate vulnerability
6. **/debug** - Moderate vulnerability (8 state-persistence sourcings)
7. **/repair** - Moderate vulnerability
8. **/revise** - Moderate vulnerability (8 state-persistence sourcings)

### Commands with MEDIUM Risk

9. **/lean-build** - Lower risk (trap-based cleanup, no persistent state ID file)

### Commands with LOW Risk

10-18. Commands without state persistence (no concurrent execution risk)

## Recommendations

### Immediate Mitigations

1. **Document Limitation**: Add WARNING to command documentation about concurrent execution
2. **Lock Files**: Implement command-level lock files before state ID file creation
3. **PID-Based State IDs**: Include PID in state ID filename: `plan_state_id_$$.txt`

### Long-Term Solutions

1. **Per-Instance State Directories**: Create `.claude/tmp/workflow_${WORKFLOW_ID}/` directory per instance
2. **Session-Based State Management**: Use session IDs instead of command-specific state ID files
3. **Atomic State Operations**: Use flock or similar for atomic state file operations
4. **State Machine Refactoring**: Move from file-based to in-memory state with checkpoint files

## Appendix: State Persistence Library Analysis

From `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`:

- **Version**: 1.6.0
- **Pattern**: GitHub Actions-style state persistence ($GITHUB_OUTPUT, $GITHUB_STATE)
- **State File Path**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Critical Note** (lines 10-24): Commands MUST use ${CLAUDE_PROJECT_DIR}, not ${HOME}
- **Cleanup**: EXIT trap recommended for state file cleanup
- **Performance**: 70% improvement (50ms → 15ms) for CLAUDE_PROJECT_DIR detection via caching

### Key Functions

1. `init_workflow_state()` - Creates workflow state file (Block 1 only)
2. `load_workflow_state()` - Sources workflow state file (Blocks 2+)
3. `append_workflow_state()` - Appends state variables (GitHub Actions pattern)
4. `save_json_checkpoint()` - Atomic JSON checkpoint writes
5. `load_json_checkpoint()` - JSON checkpoint reads

### State Items Using File-Based Persistence (7 identified)

1. Supervisor metadata (P0)
2. Benchmark dataset (P0)
3. Implementation supervisor state (P0)
4. Testing supervisor state (P0)
5. Migration progress (P1)
6. Performance benchmarks (P1)
7. POC metrics (P1)

## Conclusion

**9 commands are vulnerable to concurrent execution interference** through shared state files. Three commands (/create-plan, /lean-plan, /lean-implement) exhibit CRITICAL risk due to persistent state ID file patterns. The remaining 6 commands have HIGH risk from potential WORKFLOW_ID collisions in shared workflow state files.

The root cause is the single shared directory (`.claude/tmp/`) for all workflow state files combined with command-specific state ID files that persist WORKFLOW_ID across bash blocks. When two instances run concurrently, the state ID file becomes a race condition, with the last writer winning and breaking state restoration for the first instance.

